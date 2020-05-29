
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_GraceApplyPeriod_Get]
@SubsidySchemeID	int,
@EmployerNumber     varchar(6)
AS
/*	==========================================================================================
	Purpose: 	Get the start and enddate of the period that a graceperiod can be requested.

	22-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @ReferenceDate  date = CAST(CAST(YEAR(Getdate()) AS varchar(4)) + '0101' AS date),
        @MonthsBefore   int,
        @MonthsAfter    int

SELECT  @MonthsBefore = CAST(SettingValue AS int) * -1
FROM    sub.tblApplicationSetting
WHERE   SettingName = 'GraceApplyPeriod'
AND     SettingCode = 'Before'

SELECT  @MonthsAfter = CAST(SettingValue AS int)
FROM    sub.tblApplicationSetting
WHERE   SettingName = 'GraceApplyPeriod'
AND     SettingCode = 'After'

SELECT
		ems.EmployerSubsidyID,
        ems.SubsidySchemeID,
        ems.EmployerNumber,
		DATEADD(MONTH, @MonthsBefore, DATEADD(MONTH, ssc.SubmitIncrement, @ReferenceDate)) AS StartDate,
		DATEADD(MONTH, @MonthsAfter, DATEADD(MONTH, ssc.SubmitIncrement, @ReferenceDate)) AS EndDate
FROM	sub.tblEmployer_Subsidy ems
INNER JOIN sub.tblSubsidyScheme ssc
ON      ssc.SubsidySchemeID = ems.SubsidySchemeID
WHERE	ems.EmployerNumber = @EmployerNumber
AND     ems.StartDate = DATEADD(YEAR, -1, @ReferenceDate)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_Get ===============================================	*/
