CREATE PROCEDURE [sub].[usp_CONNECT_CheckOnSync]
AS
/*	==========================================================================================
	Purpose:	Checks if an sync action should be executed of all institutes and courses.
	
	Note:		If TRUE is returned a sync action can be started which select all institutes 
				and courses from the Etalage database and updates/inserts the data into 
				the Subsidiesysteem database.

	30-10-2018	Sander van Houten			Initial version.
	==========================================================================================	*/

DECLARE	@ExecuteSync		bit = 0,
		@SyncNextDateTime	datetime

SELECT	@ExecuteSync = 1,
		@SyncNextDateTime = CAST(SettingValue AS datetime)
FROM	sub.tblApplicationSetting
WHERE   SettingName = 'ConnectSyncNext'
AND		CAST(SettingValue AS datetime) <= GETDATE()
AND		DB_Name() = 'OTIBDS'

IF @ExecuteSync = 1
BEGIN
	DECLARE @ExecutedProcedureID int = 0
	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	DECLARE	@Argument1	varchar(10),
			@Argument2	tinyint

	SELECT	@Argument1 = SettingCode,
			@Argument2 = CAST(SettingValue AS tinyint)
	FROM    sub.tblApplicationSetting
	WHERE	SettingName = 'ConnectSyncInterval'

	UPDATE  sub.tblApplicationSetting
	SET		SettingValue = CASE @Argument1
								WHEN 'HOUR(S)' THEN CONVERT(varchar(20), DATEADD(HOUR, @Argument2, @SyncNextDateTime), 120)
								WHEN 'DAY(S)' THEN CONVERT(varchar(20), DATEADD(DAY, @Argument2, @SyncNextDateTime), 120)
								WHEN 'WEEK(S)' THEN CONVERT(varchar(20), DATEADD(WEEK, @Argument2, @SyncNextDateTime), 120)
								WHEN 'MONTH(S)' THEN CONVERT(varchar(20), DATEADD(MONTH, @Argument2, @SyncNextDateTime), 120)
								WHEN 'QUARTER(S)' THEN CONVERT(varchar(20), DATEADD(QUARTER, @Argument2, @SyncNextDateTime), 120)
								WHEN 'YEAR(S)' THEN CONVERT(varchar(20), DATEADD(YEAR, @Argument2, @SyncNextDateTime), 120)
								ELSE CONVERT(varchar(20), DATEADD(DAY, @Argument2, @SyncNextDateTime), 120)
							  END
	WHERE   SettingName = 'ConnectSyncNext'
	  AND	CAST(SettingValue AS datetime) <= GETDATE()

	EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
END

SELECT	@ExecuteSync AS ExecuteSync

/*	== sub.usp_CONNECT_CheckOnSync ===========================================================	*/
