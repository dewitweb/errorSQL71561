CREATE PROCEDURE [sub].[uspEncryptedSetting_Get]
@SettingName	varchar(50),
@SettingCode	varchar(24),
@CurrentDate	date
AS
/*	==========================================================================================
	Purpose:	Get specific data from sub.tblEncryptedSetting.

	27-08-2019	Sander van Houten		OTIBSUB-1293		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @SettingName	varchar(50) = 'HorusAutoLogin',
		@SettingCode	varchar(24) = 'SecretKey',
		@CurrentDate	datetime = NULL
-- */

-- Correct variable.
IF @CurrentDate IS NULL
BEGIN
	SET @CurrentDate = CAST(GETDATE() AS date)
END

-- First, open the symmetric key with which to decrypt the data.  
OPEN SYMMETRIC KEY SSN_Key_01  
   DECRYPTION BY CERTIFICATE EncryptedSetting001;  

-- Then, return the data.
SELECT
		EncryptedSettingID,
		SettingName,
		SettingCode,
		CONVERT(varchar(128), DecryptByKey([SettingValue])) SettingValue,
		SettingDescription,
		StartDate,
		EndDate,
		SortOrder
FROM	sub.tblEncryptedSetting
WHERE	SettingName = @SettingName
AND		SettingCode = @SettingCode
AND		StartDate <= @CurrentDate
AND		COALESCE(EndDate, @CurrentDate) >= @CurrentDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEncryptedSetting_Get ===========================================================	*/
