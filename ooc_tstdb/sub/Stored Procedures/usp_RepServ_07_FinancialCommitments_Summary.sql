
CREATE PROCEDURE [sub].[usp_RepServ_07_FinancialCommitments_Summary]
@SubsidySchemeID	int,
@SubsidyYear		varchar(20)
AS
/*	==========================================================================================
	Purpose:	Summary of the financial commitements in a given subsidy year for the OSR.

	Parameters:	@Year: The subsidy year.

	15-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	27-09-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* TestData
DECLARE @SubsidySchemeID	int = 1,
        @SubsidyYear		varchar(20) = '2019'
--  */

/*  Insert @SubsidySchemeID into a modifiable table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID

INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*	Return numbers to report. */
SELECT	SUM(CASE WHEN NumberOfEmployee = 0 THEN 0 ELSE 1 END)   AS CompaniesWithEmployeesAtReferenceDate,
		SUM(NumberOfEmployee)                                   AS EmployeesAtReferenceDate,
		SUM(NumberOfEmployee_WithoutSubsidy)                    AS EmployeesAtReferenceDate_WithoutSubsidy,
		SUM(CASE WHEN NumberOfEmployee = 0 THEN 1 ELSE 0 END)   AS CompaniesWithEmployeesNotOnReferenceDate
FROM	sub.tblEmployer_Subsidy
WHERE	SubsidySchemeID IN 
                            (
                                SELECT	SubsidySchemeID 
                                FROM	@tblSubsidyScheme
                            )

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_07_FinancialCommitments_Summary ======================================	*/
