CREATE PROCEDURE [ait].[uspProcessErrorLog]
AS
/*	==========================================================================================
	Purpose:	Create an e-mail record for ErrorLogs that have the indication that an e-mail
				should be send.

	Notes:		

	31-07-2019	Sander van Houten		OTIBSUB-1096	Initial version.
	==========================================================================================	*/

DECLARE @LogDate		datetime = GETDATE(),
		@Environment	varchar(3)

-- Get environment description (short).
SELECT	@Environment = SettingValue
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'Environment'
AND		SettingCode = '0000'
		
-- Insert record into eml.tblEmail.
INSERT INTO eml.tblEmail
	(
		EmailHeaders,
		EmailBody,
		CreationDate
	)
SELECT	'<headers>' + 
		'<header key="subject" value="Foutmelding via ait.tblErrorLog OTIB-DS ' + @Environment + '" />' + 
		'<header key="to" value="support@ambitionit.nl" />' + 
		'</headers>',
		'<style type="text/css">p {font-family: arial;font-size: 14.5px;}</style><p>Beste afdeling Support,' +
		'<br><br>' +
		'De volgende fout is opgetreden:<br>' +
		'<table cellspacing="0" cellpadding="0" border="0" width="800">' +
		'<tr><td width="160">Datum-tijd</td><td width="640">: ' + CONVERT(varchar(25), err.ErrorDate, 120) + '</td></tr>' +
		'<tr><td width="160">Foutnummer</td><td width="640">: ' + CONVERT(varchar(10), err.ErrorNumber) + '</td></tr>' +
		'<tr><td width="160">Procedurenaam</td><td width="640">: ' + err.ErrorProcedure + '</td></tr>' +
		'<tr><td width="160">Regelnummer</td><td width="640">: ' + CAST(err.ErrorLine AS varchar(10)) + '</td></tr>' +
		'<tr><td width="160" valign="top">Foutmelding</td><td width="640">: ' + err.ErrorMessage + '</td></tr>' +
		'</table></p>',
		@LogDate
FROM	ait.tblErrorLog err
WHERE	err.ErrorDate <= @LogDate
AND		err.SendEmail = 1
AND		err.EmailSent IS NULL

-- Register the fact that the error is processed.
UPDATE	ait.tblErrorLog
SET		EmailSent = @LogDate
WHERE	ErrorDate <= @LogDate
AND		SendEmail = 1
AND		EmailSent IS NULL

/*	== ait.uspProcessErrorLog ===============================================================	*/
