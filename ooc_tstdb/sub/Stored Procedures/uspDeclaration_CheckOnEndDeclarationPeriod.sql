CREATE PROCEDURE [sub].[uspDeclaration_CheckOnEndDeclarationPeriod]
@SubsidySchemeID    int,
@EmployerNumber	    varchar(6),
@StartDate		    date
AS
/*	==========================================================================================
	Purpose:	Checks if a declaration can still be submitted according to the EndDeclarationPeriod.

    Notes:      The standard EndDeclarationPeriod (calculated on the bases of the data in
                sub.tblSubsidyScheme) can be overruled by a graceperiod requested by the employer.

	03-02-2020	Sander van Houten		OTIBSUB-1873	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @SubsidySchemeID    int = 1,
        @EmployerNumber	    varchar(6) = '000007',
        @StartDate		    date = '20191201'
--	*/

DECLARE @Getdate    date = GETDATE()

-- Do the check and give back the result.
IF @SubsidySchemeID = 1
BEGIN
    SELECT  CASE WHEN EndDeclarationPeriod < @Getdate
                THEN CAST(0 AS bit)
                ELSE CAST(1 AS bit)
            END             AS CanSubmitDeclaration,
            EndDeclarationPeriod
    FROM    sub.tblEmployer_Subsidy
    WHERE   SubsidySchemeID = @SubsidySchemeID
    AND     EmployerNumber = @EmployerNumber
    AND     SubsidyYear = YEAR(@StartDate)
END
ELSE
BEGIN
    SELECT  CAST(1 AS bit)              AS CanSubmitDeclaration,
            CAST('20991231' AS date)    AS EndDeclarationPeriod
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_CheckOnEndDeclarationPeriod ========================================	*/
