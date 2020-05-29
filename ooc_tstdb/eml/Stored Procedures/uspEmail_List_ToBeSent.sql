CREATE PROCEDURE [eml].[uspEmail_List_ToBeSent]
AS
/*	==========================================================================================
	Purpose:	List all data of searched for declaration.

	05-09-2019	Sander van Houten		AII-18		Added WHERE-clause on RetryCount.
	05-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	emailID
FROM	eml.tblEmail
WHERE	SentDate IS NULL
AND		RetryCount < (	SELECT	CAST(SettingValue AS int)
						FROM	eml.tblEmailSetting
						WHERE	SettingName = 'MaxRetries'
					 )

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmail_List_ToBeSent ============================================================	*/
