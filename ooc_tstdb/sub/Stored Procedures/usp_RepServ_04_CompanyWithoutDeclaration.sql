CREATE PROCEDURE [sub].[usp_RepServ_04_CompanyWithoutDeclaration]
@CompanySize varchar(4) = '0000'
AS

/*	==========================================================================================
	Purpose:	List with Companies without declarations

	16-08-2019	Sander van Houten		OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	07-06-2019	H. Melissen				New: Parameter @CompanySize with default value
										New: Table variable for filtering on parameter @CompanySize
	05-06-2019	Jaap van Assenbergh	
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata. */
--DECLARE @CompanySize varchar(4) = '0004'

/*	Variables. */
DECLARE @Companies TABLE (EmployerNumber varchar(6), EmployerName varchar(100), CompanySizeCode varchar(4), CompanySizeCategory varchar(100), 
						  StartYear int, NrOfEmployees int, CountBPV int, Amount decimal(18,2))

;WITH cteReferenceDate AS
(
	SELECT	SettingCode, YEAR(StartDate) StartYear, ReferenceDate
	FROM [OTIBDS].[sub].[tblApplicationSetting] aps
	INNER JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
	WHERE SettingName = 'SubsidyAmountPerEmployee'
),
cteCountEmployee AS
	(
		SELECT	EmployerNumber, 
				NrOfEmployees,
				CASE 
					WHEN NrOfEmployees < 10 THEN '0001'
					WHEN NrOfEmployees BETWEEN 10 AND 24 THEN '0002'
					WHEN NrOfEmployees BETWEEN 25 AND 100 THEN '0003'
					WHEN NrOfEmployees > 100 THEN '0004' 
				END CompanySize,
				--SettingCode,
				StartYear
		FROM	(
					SELECT	emr.EmployerNumber, 
							COUNT(1)			NrOfEmployees,
							ref.SettingCode,
							ref.StartYear
					FROM	sub.tblEmployer emr
					INNER JOIN sub.tblEmployer_Employee eme ON eme.EmployerNumber = emr.EmployerNumber
					CROSS JOIN cteReferenceDate ref
					WHERE	COALESCE(emr.EndDateMembership, ref.ReferenceDate) >= ref.ReferenceDate
					AND		eme.StartDate <= ref.ReferenceDate
					AND		COALESCE(eme.EndDate, ref.ReferenceDate) >= ref.ReferenceDate
					GROUP BY emr.EmployerNumber, ref.SettingCode, ref.StartYear
			) s
	)
,cteCountBPV AS
	(
		SELECT	bpv.EmployerNumber,
				COUNT(bpv.EmployeeNumber) CountBPV,
				YEAR(ref.ReferenceDate) StartYear 
		FROM	hrs.viewBPV bpv
		CROSS JOIN cteReferenceDate ref
		WHERE	bpv.StartDate <= ref.ReferenceDate
		AND		COALESCE(bpv.EndDate, ref.ReferenceDate) >= ref.ReferenceDate
		GROUP BY bpv.EmployerNumber, YEAR(ref.ReferenceDate)
	)

INSERT INTO @Companies (EmployerNumber, EmployerName, CompanySizeCode, CompanySizeCategory, 
						StartYear, NrOfEmployees, CountBPV, Amount)
SELECT	emr.EmployerNumber, emr.EmployerName, aps.SettingCode AS CompanySizeCode, aps.SettingValue AS CompanySizeCategory, ce.StartYear, ce.NrOfEmployees, ISNULL(CountBPV, 0) CountBPV, emrs.Amount
FROM	sub.tblEmployer emr
LEFT JOIN cteCountEmployee ce ON ce.EmployerNumber = emr.EmployerNumber
LEFT JOIN cteCountBPV cbpv ON cbpv.EmployerNumber = emr.EmployerNumber AND  cbpv.StartYear = ce.StartYear
LEFT JOIN sub.tblApplicationSetting aps ON aps.SettingCode = ce.CompanySize AND SettingName = 'CompanySize'
INNER JOIN sub.tblEmployer_Subsidy emrs ON emrs.EmployerNumber = emr.EmployerNumber
AND		emr.EmployerNumber NOT IN 
		(
			SELECT	decl.EmployerNumber
			FROM	sub.tblDeclaration decl
		)

SELECT EmployerNumber, EmployerName, CompanySizeCategory, StartYear, NrOfEmployees, CountBPV, Amount
FROM @Companies
WHERE CompanySizeCode = CASE WHEN @CompanySize = '0000' THEN CompanySizeCode
						ELSE @CompanySize END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_RepServ_04_CompanyWithoutDeclaration ==========================================	*/
