
CREATE PROCEDURE [auth].[uspLoginFailed_List]
AS
/*	==========================================================================================
	Purpose:	Get all data from auth.tblLoginFailed.

	29-01-2019	Sander van Houten	Added ExtraInfo parameter (OTIBSUB-608).
	10-12-2018	Sander van Houten	Initial version (OTIBSUB-549).
	==========================================================================================	*/

	SELECT
			lof.Loginname,
			CONVERT(varchar(10), lof.LoginDateTime, 105) + ' ' 
			+ CONVERT(varchar(12), lof.LoginDateTime, 108)	AS LoginDateTime,
			aps.SettingValue								AS FailureReason,
			lof.ExtraInfo
	FROM	auth.tblLoginFailed lof
	LEFT JOIN sub.tblApplicationSetting aps
	ON		aps.SettingName = 'LoginFailureReason'
	AND		aps.SettingCode = lof.FailureReason

/*	== auth.uspLoginFailed_List ===================================================	*/
