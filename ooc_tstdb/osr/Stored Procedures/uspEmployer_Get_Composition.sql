CREATE PROCEDURE [osr].[uspEmployer_Get_Composition]
@EmployerNumber		varchar(6)
AS
/*	==========================================================================================
	Purpose:	Get scholingbudget composition on dashboard of employer.

	22-01-2020	Sander van Houten	OTIBSUB-1841    Exclude employees with active STIP 
                                        declaration (see OTIBSUB-1806 also).
	06-01-2020	Sander van Houten	OTIBSUB-1808    Budget amount needs to be extracted from
                                        sub.tblApplicationSetting_Extended 
                                        not from sub.tblApplicationSetting.
	17-09-2019	Sander van Houten	OTIBSUB-1575	Corrected code for counting daughter companies.
	04-09-2019	Sander van Houten	OTIBSUB-1533	Only count an employer once.
	22-08-2019	Sander van Houten	OTIBSUB-1475	Do not show budget if no budget has been registered.
	16-08-2019	Sander van Houten	OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	24-06-2019	Sander van Houten	OTIBSUB-1249	Show altered scholingbudget data.
	20-06-2019	Sander van Houten	OTIBSUB-1196	Added FeesPaidUntil and MembershipDates.
	29-05-2019	Jaap van Assenbergh	OTIBSUB-1132	Definition of 'Active BPV's'
	01-03-2019	Jaap van Assenbergh	OTIBSUB-790		Initial version.
				
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata
DECLARE @EmployerNumber	varchar(6)	= '075689'
--*/

DECLARE @SubsidySchemeID			int		= 1,
		@GetDate					date	= GETDATE(),
		@SubsidyAmountPerEmployee	decimal(19,4),
		@ReferenceDate				date,
		@StartDate					date,
		@EndDate					date,
		@EmployeeCount				int,
		@EmployeeBPV				int,
		@EmployerCount				tinyint,
		@EmployeeCountChild			int,
		@EmployeeBPVChild			int,
		@EmployerCountChild			tinyint,
		@SubsidyAmountPerEmployer	decimal(19,4),
		@CurrentSubsidyAmount		decimal(19,4),
		@LastChangeDateSubsidy		date

SELECT	@SubsidyAmountPerEmployee = apse.SettingValue,
		@ReferenceDate = apse.ReferenceDate	,
		@StartDate = StartDate,
		@EndDate = EndDate
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse 
ON		apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	SettingName = 'SubsidyAmountPerEmployee'
AND		@GetDate BETWEEN apse.StartDate AND apse.EndDate
AND		apse.SubsidySchemeID = @SubsidySchemeID

SELECT	@SubsidyAmountPerEmployer = apse.SettingValue
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse 
ON		apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	SettingName = 'SubsidyAmountPerEmployer'
AND		@GetDate BETWEEN apse.StartDate AND apse.EndDate
AND		apse.SubsidySchemeID = @SubsidySchemeID

--	Get data from employer with employee(s) before or on the referencedate.
SELECT	@EmployerCount = COUNT(DISTINCT eme.EmployerNumber),
		@EmployeeCount = COUNT(eme.EmployeeNumber),
		@EmployeeBPV = SUM(CASE WHEN bpv.EmployeeNumber IS NULL
                                 AND stip.EmployeeNumber IS NULL
                            THEN 0 
                            ELSE 1 
                           END
                          ) 
FROM	sub.tblEmployer_Employee eme
LEFT JOIN hrs.viewBPV bpv
ON		bpv.EmployeeNumber = eme.EmployeeNumber
AND		bpv.EmployerNumber = eme.EmployerNumber
AND		@ReferenceDate BETWEEN bpv.StartDate AND COALESCE(bpv.EndDate, @Getdate)
LEFT JOIN stip.viewDeclaration stip
ON	    stip.EmployerNumber = eme.EmployerNumber 
AND     stip.EmployeeNumber = eme.EmployeeNumber
AND		@ReferenceDate BETWEEN stip.StartDate AND COALESCE(stip.EndDate, @Getdate)
WHERE	eme.EmployerNumber = @EmployerNumber
AND		@ReferenceDate BETWEEN eme.StartDate AND COALESCE(eme.EndDate, @Getdate)

IF @EmployerCount = 0
BEGIN
	--	Get data from employer with employee(s) after the referencedate.
	SELECT	@EmployerCount = @EmployerCount + COUNT(DISTINCT eme.EmployerNumber)
	FROM	sub.tblEmployer_Employee eme
	WHERE	eme.EmployerNumber = @EmployerNumber	
	AND		eme.StartDate > @ReferenceDate 
	AND		eme.StartDate <= @Getdate
END 

--	Get data from daughter companies.
SELECT	@EmployerCountChild = COUNT(DISTINCT epc.EmployerNumberChild)
FROM	sub.tblEmployer_ParentChild epc
INNER JOIN sub.tblEmployer_Employee eme
ON		eme.EmployerNumber = epc.EmployerNumberChild
WHERE	epc.EmployerNumberParent = @EmployerNumber	
AND		@GetDate BETWEEN epc.StartDate AND COALESCE(epc.EndDate, @GetDate)
AND		(
			@ReferenceDate BETWEEN eme.StartDate AND COALESCE(eme.EndDate, @Getdate)
	OR		(
				eme.StartDate > @ReferenceDate 
		AND		eme.StartDate <= @Getdate
			)
		)

--	Get data from daughter companies with employer(s) after the referencedate.
SELECT	@EmployeeCountChild = COUNT(eme.EmployeeNumber),
		@EmployeeBPVChild = SUM(CASE WHEN bpv.EmployeeNumber IS NULL
                                      AND stip.EmployeeNumber IS NULL
                                    THEN 0 
                                    ELSE 1 
                                END
                               ) 
FROM	sub.tblEmployer_ParentChild epc
INNER JOIN sub.tblEmployer_Employee eme
ON		eme.EmployerNumber = epc.EmployerNumberChild
LEFT JOIN hrs.viewBPV bpv 
ON		bpv.EmployeeNumber = eme.EmployeeNumber
AND		bpv.EmployerNumber = eme.EmployerNumber
AND		@ReferenceDate BETWEEN bpv.StartDate AND COALESCE(bpv.EndDate, @Getdate)
LEFT JOIN stip.viewDeclaration stip
ON	    stip.EmployerNumber = eme.EmployerNumber 
AND     stip.EmployeeNumber = eme.EmployeeNumber
AND		@ReferenceDate BETWEEN stip.StartDate AND COALESCE(stip.EndDate, @Getdate)
WHERE	epc.EmployerNumberParent = @EmployerNumber	
AND		@GetDate BETWEEN epc.StartDate AND COALESCE(epc.EndDate, @GetDate)
AND		@ReferenceDate BETWEEN eme.StartDate AND COALESCE(eme.EndDate, @Getdate)

SET	@EmployerCount = @EmployerCount + ISNULL(@EmployerCountChild, 0)

--	Get current subsidy amount.
SELECT	@CurrentSubsidyAmount = Amount
FROM	sub.tblEmployer_Subsidy
WHERE	EmployerNumber = @EmployerNumber
AND		@GetDate BETWEEN StartDate AND EndDate

--	Get information on changed subsidy amount by an OTIB user.
SELECT	@LastChangeDateSubsidy = MAX(LogDate)
FROM	his.tblHistory
WHERE	TableName = 'sub.tblEmployer_Subsidy'
AND		KeyID = @EmployerNumber + '|' + CAST(@SubsidySchemeID AS varchar(2)) + '|' + CONVERT(varchar(10), @StartDate, 105)
AND		UserID <> 1

SELECT  SubsidyAmountPerEmployee,
		ReferenceDate,
		EmployeeCount,
		EmployeeBPV,
		TotalAmountOfEmployees,
		TotalEmployees,
		CASE WHEN @EmployerCount = 0
			THEN 0
			ELSE SubsidyAmountPerEmployer
		END																		SubsidyAmountPerEmployer,
		SubsidyYear,
		CASE WHEN EmployeeCount = 0 AND @EmployerCount = 0
			THEN 0
			ELSE TotalSubsidy
		END																		TotalSubsidy,
		@CurrentSubsidyAmount													TotalSubsidyAmountByOTIB,
		@LastChangeDateSubsidy													LastChangeDateSubsidy,
		CASE WHEN @EmployerCount = 0
			THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END																		ShowBudget
FROM	(
			SELECT  @SubsidyAmountPerEmployee									SubsidyAmountPerEmployee,
					@ReferenceDate												ReferenceDate,
					ISNULL(@EmployeeCount, 0) + ISNULL(@EmployeeCountChild, 0)	EmployeeCount,
					ISNULL(@EmployeeBPV, 0) + ISNULL(@EmployeeBPVChild, 0)		EmployeeBPV,
					totae.TotalAmountOfEmployees,
					totae.TotalEmployees,
					@SubsidyAmountPerEmployer * @EmployerCount					SubsidyAmountPerEmployer,
					CAST(YEAR(@StartDate) AS varchar(4)) + 
						CASE WHEN YEAR(@StartDate) = YEAR(@EndDate) 
							THEN '' 
							ELSE '/' + CAST(YEAR(@EndDate) AS varchar(4))
						END														SubsidyYear,
					totae.TotalSubsidy
			FROM	(
						SELECT
								TotalEmployees,
								TotalEmployees * @SubsidyAmountPerEmployee		TotalAmountOfEmployees,
								TotalEmployees * @SubsidyAmountPerEmployee 
								+ @SubsidyAmountPerEmployer	* @EmployerCount	TotalSubsidy
						FROM	(
									SELECT	ISNULL(@EmployeeCount, 0) 
											+ ISNULL(@EmployeeCountChild, 0) 
											- ISNULL(@EmployeeBPV, 0) 
											- ISNULL(@EmployeeBPVChild, 0)		TotalEmployees
								) tote
					) totae
		) osr

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspEmployer_Get_Composition =======================================================	*/
