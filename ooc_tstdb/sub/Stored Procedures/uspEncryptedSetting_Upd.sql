CREATE PROCEDURE [sub].[uspEncryptedSetting_Upd]
@EncryptedSettingID		int,
@SettingName			varchar(50),
@SettingCode			varchar(24),
@ApplicationID			int,
@SettingValue			varbinary(128),
@SettingDescription		varchar(max),
@StartDate				date,
@EndDate				date,
@SortOrder				tinyint,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblApplicationPage on basis of PageID.

	27-08-2019	Sander van Houten		OTIBSUB-1293		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @EncryptedSettingID		int = 0,
		@SettingName			varchar(50) = 'HorusAutoLogin',
		@SettingCode			varchar(24) = 'SecretKey',
		@ApplicationID			int = 1,
		@SettingValue			varbinary(128) = NULL,
		@SettingDescription		varchar(max) = 'Dit is de versleutelde inlogcode voor deze periode',
		@StartDate				date = '2019-09-01',
		@EndDate				date = NULL,
		@SortOrder				tinyint = 1,
		@CurrentUserID			int = 1
-- */
DECLARE @Return					int = 1

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Open the symmetric key with which to encrypt the data.  
OPEN SYMMETRIC KEY SSN_Key_01  
   DECRYPTION BY CERTIFICATE EncryptedSetting001;  

IF ISNULL(@EncryptedSettingID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblEncryptedSetting
		(
			SettingName,
			SettingCode,
			ApplicationID,
			SettingValue,
			SettingDescription,
			StartDate,
			EndDate,
			SortOrder
		)
     VALUES
        (
			@SettingName,
			@SettingCode,
			@ApplicationID,
			-- Encrypt the value in @SettingValue with symmetric key SSN_Key_01.
			-- Save the result in column SettingValue.  
			EncryptByKey(Key_GUID('SSN_Key_01'), @SettingValue),
			@SettingDescription,
			@StartDate,
			@EndDate,
			@SortOrder
		)

	SET	@EncryptedSettingID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEncryptedSetting
						WHERE	EncryptedSettingID = @EncryptedSettingID
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEncryptedSetting
						WHERE	EncryptedSettingID = @EncryptedSettingID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEncryptedSetting
	SET		SettingName = @SettingName,
			SettingCode = @SettingCode,
			ApplicationID = @ApplicationID,
			-- Encrypt the value in @SettingValue with symmetric key SSN_Key_01.
			-- Save the result in column SettingValue.  
			SettingValue = EncryptByKey(Key_GUID('SSN_Key_01'), @SettingValue),
			SettingDescription = @SettingDescription,
			StartDate = @StartDate,
			EndDate = @EndDate,
			SortOrder = @SortOrder
	WHERE	EncryptedSettingID = @EncryptedSettingID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEncryptedSetting
						WHERE	EncryptedSettingID = @EncryptedSettingID
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EncryptedSettingID

	EXEC his.uspHistory_Add
			'sub.tblEncryptedSetting',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT EncryptedSettingID = @EncryptedSettingID

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== sub.uspEncryptedSetting_Upd ===========================================================	*/
