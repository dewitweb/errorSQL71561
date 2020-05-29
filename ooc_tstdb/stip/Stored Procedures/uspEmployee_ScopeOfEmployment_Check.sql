CREATE PROCEDURE [stip].[uspEmployee_ScopeOfEmployment_Check]
@EmployeeNumber	varchar(8),
@EmployerNumber	varchar(6),
@StartDate		date,
@EndDate		date
AS
/*	==========================================================================================
	Purpose:	Checks if a employee is eligible for a STIP declaration.

	Note:		

	17-12-2019	Sander van Houten		OTIBSUB-1783	Get most current scope of employment period.
                                            (Added DESC to sort)
	08-05-2019	Sander van Houten		OTIBSUB-1058	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@EmployeeNumber		varchar(8) = '07122722',
		@EmployerNumber		varchar(6) = '085475',
		@StartDate			date = '20190901',
		@EndDate			date = '20200601'
--	*/

DECLARE	@MinimumScopeOfEmployement	decimal (5,2),
		@MaximumScopeOfEmployement	decimal (5,2),
		@ResultCode					tinyint = 0,
		@StartDate_Employment		date,
		@EndDate_Employment			date,
		@StartDate_Scope			date,
		@EndDate_Scope				date,
		@ScopeOfEmployment			decimal(5,2)

DECLARE @tblEmployment TABLE 
	(
		EmployerNumber	varchar(6), 
		EmployeeNumber	varchar(8),
		MinStartDate	date,
		MaxEndDate		date
	)

SELECT	@MinimumScopeOfEmployement = CAST(SettingValue AS decimal(15,2))
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'STIP_ScopeOfEmployement'
AND		SettingCode = 'Minimum'

SELECT	@MaximumScopeOfEmployement = CAST(SettingValue AS decimal(15,2))
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'STIP_ScopeOfEmployement'
AND		SettingCode = 'Maximum'

-- First check if the startdate falls in an employment period.
;WITH cte_eme AS
(
SELECT	eme.EmployerNumber, 
		eme.EmployeeNumber,
		eme.StartDate,
		eme.EndDate,
		ISNULL(DATEDIFF(d, LAG(eme.EndDate) 
						OVER (PARTITION BY eme.EmployerNumber, eme.EmployeeNumber 
							  ORDER BY eme.StartDate, eme.EndDate
							 ), eme.StartDate
					   ), 1
			  ) AS DaysInbetween
FROM	sub.tblEmployer_Employee eme
WHERE	eme.EmployerNumber = @EmployerNumber
AND		eme.EmployeeNumber = @EmployeeNumber
UNION ALL
SELECT	eme.EmployerNumber, 
		eme.EmployeeNumber,
		eme.StartDate,
		eme.EndDate,
		ISNULL(DATEDIFF(d, LAG(eme.EndDate) 
						OVER (PARTITION BY eme.EmployerNumber, eme.EmployeeNumber 
							  ORDER BY eme.StartDate, eme.EndDate
							 ), eme.StartDate
					   ), 1
			  ) AS DaysInbetween
FROM	sub.tblEmployer_Employee eme
INNER JOIN sub.tblEmployer_ParentChild epc 
		ON	epc.EmployerNumberChild =  eme.EmployerNumber
		AND	epc.StartDate <= @StartDate 
		AND ISNULL(epc.EndDate, @EndDate) <= @EndDate
WHERE	epc.EmployerNumberParent = @EmployerNumber
AND		eme.EmployeeNumber = @EmployeeNumber
)
INSERT INTO @tblEmployment
	(
		EmployerNumber, 
		EmployeeNumber,
		MinStartDate,
		MaxEndDate
	)
SELECT	EmployerNumber, 
		EmployeeNumber,
		MIN(StartDate) AS MinStartDate,
		MAX(ISNULL(EndDate, '20990101')) AS MaxEndDate
FROM	cte_eme
GROUP BY 
		EmployerNumber, 
		EmployeeNumber,
		DaysInbetween

SELECT	@StartDate_Employment = MinStartDate,
		@EndDate_Employment = CASE MaxEndDate WHEN '20990101' THEN NULL ELSE MaxEndDate END
FROM	@tblEmployment
WHERE	@StartDate BETWEEN MinStartDate AND MaxEndDate

IF @@ROWCOUNT = 0
BEGIN
	SET @ResultCode = 1
END

-- If startdate falls in an employment periode then check if the enddate falls in that employment period.
IF @ResultCode = 0
BEGIN
	SELECT	@StartDate_Employment = MinStartDate,
			@EndDate_Employment = CASE MaxEndDate WHEN '20990101' THEN NULL ELSE MaxEndDate END
	FROM	@tblEmployment
	WHERE	@StartDate BETWEEN MinStartDate AND MaxEndDate
	AND		@EndDate BETWEEN MinStartDate AND MaxEndDate

	IF @@ROWCOUNT = 0
	BEGIN
		SET @ResultCode = 2
	END
END

IF @ResultCode = 0
-- If both dates match, get the scope of employment.
BEGIN
	SELECT	TOP 1
			@StartDate_Scope = soe.StartDate,
			@EndDate_Scope = soe.EndDate,
			@ScopeOfEmployment = soe.ScopeOfEmployment
	FROM	@tblEmployment emp
	INNER JOIN sub.tblEmployee_ScopeOfEmployment soe
	ON		soe.EmployeeNumber = emp.EmployeeNumber
	AND		soe.EmployerNumber = emp.EmployerNumber
	AND		@StartDate BETWEEN soe.StartDate AND COALESCE(soe.EndDate, @StartDate)
	ORDER BY 
			soe.StartDate DESC

	SET @ResultCode = 3
END

SELECT	@EmployeeNumber				AS EmployeeNumber,
		@EmployerNumber				AS EmployeNumber,
		@ResultCode					AS ResultCode,
		@StartDate_Employment		AS StartDate_Employment,
		@EndDate_Employment			AS EndDate_Employment,
		@StartDate_Scope			AS StartDate_Scope,
		@EndDate_Scope				AS EndDate_Scope,
		@ScopeOfEmployment			AS ScopeOfEmployment,
		@MinimumScopeOfEmployement	AS MinimumScopeOfEmployement,
		@MaximumScopeOfEmployement	AS MaximumScopeOfEmployement

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspEmployee_ScopeOfEmployment_Check ==============================================	*/
