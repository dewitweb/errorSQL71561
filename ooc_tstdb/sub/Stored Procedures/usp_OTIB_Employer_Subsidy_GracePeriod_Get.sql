
CREATE PROCEDURE [sub].[usp_OTIB_Employer_Subsidy_GracePeriod_Get] 
@GracePeriodID      int,
@GracePeriodToken   varchar(50) = NULL
AS
/*	==========================================================================================
	Purpose:	Get specific GracePeriod request with employer data.

	14-01-2020	Sander van Houten	OTIBSUB-1827      Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @GracePeriodID      int = NULL,
        @GracePeriodToken   varchar(50) = NULL
--  */

DECLARE @LogDate	datetime = GETDATE()

SELECT
        esg.GracePeriodID,
        emp.EmployerNumber,
        emp.EmployerName,
        emp.BusinessAddressStreet + ' ' + emp.BusinessAddressHousenumber	AS AddressLine1,
        emp.BusinessAddressZipcode + '  ' + emp.BusinessAddressCity			AS AddressLine2,
        usr.Fullname														AS ContactName,
        usr.FunctionDescription												AS ContactFunction,
        usr.Phone															AS ContactPhone,
        usr.Email															AS ContactEmail,
        CAST(esg.CreationDate AS date)                                      AS CreationDate,
        ssc.SubsidySchemeName + ' ' + CAST(ems.SubsidyYear AS varchar(4))   AS SubsidyPeriod,
        esg.EndDate                                                         AS NewEndDate,
        esg.GracePeriodReason                                               AS Reason,
        aps.SettingValue                                                    AS GracePeriodStatus
FROM	sub.tblEmployer_Subsidy_GracePeriod esg
INNER JOIN sub.tblEmployer_Subsidy ems ON ems.EmployerSubsidyID = esg.EmployerSubsidyID
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = ems.EmployerNumber
INNER JOIN auth.tblUser usr	ON usr.Loginname = emp.EmployerNumber
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = ems.SubsidySchemeID
INNER JOIN sub.tblApplicationSetting aps 
ON      aps.SettingName = 'GracePeriodStatus' 
AND     aps.SettingCode = esg.GracePeriodStatus
LEFT JOIN sub.tblEmployer_Subsidy_GracePeriod_Email esge
ON      esge.GracePeriodID = esg.GracePeriodID
AND     esge.Token = @GracePeriodToken
AND     esge.ValidUntil >= @LogDate
WHERE	esg.GracePeriodID = @GracePeriodID
AND     (   @GracePeriodToken IS NULL 
        OR  (
                esge.Token = @GracePeriodToken
            AND esg.GracePeriodStatus = '0001'
            )
        )

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_Subsidy_GracePeriod_Get =========================================	*/
