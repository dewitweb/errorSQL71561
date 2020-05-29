
CREATE PROCEDURE [sub].[uspApplicationSetting_List]
@SettingName	varchar(50),
@SettingCode	varchar(24),
@RoleID			int
AS
/*	==========================================================================================
	Purpose:	Get list of settings from tblApplicationSettings with or without filter. 

	24-01-2019	Sander van Houten		Added specific code for setting IBANRejectionReason
										(OTIBSUB-698).
	18-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET	@SettingName	= ISNULL(@SettingName, '')
SET	@SettingCode	= ISNULL(@SettingCode, '')
SET	@RoleID			= ISNULL(@RoleID, 0)

SELECT
		a.SettingName,
		a.SettingCode,
		COALESCE(ar.SettingValue, a.SettingValue) SettingValue,
		a.SettingDescription,
		a.SortOrder
FROM	sub.tblApplicationSetting a
LEFT JOIN	sub.tblApplicationSetting_Role ar 
ON		ar.SettingName = a.SettingName
AND		ar.SettingCode = a.SettingCode
AND		ar.RoleID = @RoleID
WHERE	@SettingName =	
		CASE
			WHEN		@SettingName = ''
				THEN	@SettingName
				ELSE	a.SettingName
		END
AND		@SettingCode =	
		CASE
			WHEN		@SettingCode = ''
				THEN	@SettingCode
				ELSE	a.SettingCode
		END
AND		1 = CASE WHEN a.SettingName = 'IBANRejectionReason' AND LEFT(a.SettingDescription, 6) <> 'Actief'
				THEN 0
				ELSE 1
			END
		
ORDER BY a.SortOrder, a.SettingName, a.SettingCode

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspApplicationSetting_List =========================================================	*/
