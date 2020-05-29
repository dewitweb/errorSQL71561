
CREATE PROCEDURE [sub].[usp_OTIB_Employer_Subsidy_Get_ForGracePeriod] 
@EmployerSubsidyID  int
AS
/*	==========================================================================================
	Purpose:	Get specific EmployerSubsidy data for the request of a new GracePeriod.

	14-01-2020	Sander van Houten	OTIBSUB-1827      Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE @EmployerSubsidyID  int = 1
--  */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
        ssc.SubsidySchemeName + ' ' + CAST(ems.SubsidyYear AS varchar(4))   AS SubsidyPeriod,
        emp.EmployerName,
        emp.EmployerNumber,
        ems.EndDeclarationPeriod                                            AS CurrentEndDate
FROM	sub.tblEmployer_Subsidy ems
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = ems.SubsidySchemeID
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = ems.EmployerNumber
WHERE	ems.EmployerSubsidyID = @EmployerSubsidyID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_Subsidy_Get_ForGracePeriod ======================================	*/
