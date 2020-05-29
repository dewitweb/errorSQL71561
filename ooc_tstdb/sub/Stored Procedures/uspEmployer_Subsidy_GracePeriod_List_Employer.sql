
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_GracePeriod_List_Employer]
@EmployerNumber varchar(6)
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblEmployer_Subsidy_GracePeriod for 1 specific employer.

	03-02-2020	Sander van Houten	OTIBSUB-1874    Added data of HandledBy user.
	20-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		esgp.GracePeriodID,
		esgp.EmployerSubsidyID,
		esgp.EndDate,
		esgp.CreationUserID,
		esgp.CreationDate,
		esgp.GracePeriodReason,
		CASE WHEN usr2.UserID IS NULL
            THEN COALESCE(fui.SettingValue, usr1.Fullname)
            ELSE COALESCE(fui.SettingValue, usr1.Fullname)
                    + ' / '
                    + COALESCE(sui.SettingValue, usr2.Fullname)
                    + ' ('
                    + CONVERT(varchar(10), esgp.HandledDate, 105)
                    + ')'
        END   AS HandledBy,
		esgp.HandledDate,
		esgp.GracePeriodStatus,
        ems.SubsidySchemeID,
        ems.SubsidyYear
FROM    sub.tblEmployer_Subsidy ems
INNER JOIN sub.tblEmployer_Subsidy_GracePeriod esgp ON esgp.EmployerSubsidyID = ems.EmployerSubsidyID
INNER JOIN auth.tblUser usr1 ON usr1.UserID = esgp.CreationUserID
LEFT JOIN sub.tblApplicationSetting fui	ON fui.SettingName = 'UserInitials'	AND	fui.SettingCode = usr1.UserID
LEFT JOIN auth.tblUser usr2 ON usr2.UserID = esgp.HandledByUserID
LEFT JOIN sub.tblApplicationSetting sui	ON sui.SettingName = 'UserInitials'	AND	sui.SettingCode = usr2.UserID
WHERE   ems.EmployerNumber = @EmployerNumber
ORDER BY 
        esgp.EmployerSubsidyID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_GracePeriod_List_Employer =====================================	*/
