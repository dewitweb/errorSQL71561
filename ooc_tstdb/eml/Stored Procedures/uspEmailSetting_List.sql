
CREATE PROCEDURE [eml].[uspEmailSetting_List]
	@SettingName	varchar(50),
	@SettingCode	varchar(24)
AS
/*	==========================================================================================
	Purpose:	List all records of eml.tblEmailSetting.

	08-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SET	@SettingName	= ISNULL(@SettingName, '')
	SET	@SettingCode	= ISNULL(@SettingCode, '')

	SELECT
			a.SettingName,
			a.SettingCode,
			a.SettingValue,
			a.SettingDescription
	FROM	eml.tblEmailSetting a
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
	ORDER BY a.SettingName, a.SettingCode

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmailSetting_List =========================================================	*/
