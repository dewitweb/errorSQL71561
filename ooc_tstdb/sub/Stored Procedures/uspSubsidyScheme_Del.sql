
CREATE PROCEDURE [sub].[uspSubsidyScheme_Del]
@SubsidySchemeID	int,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Remove tblSubsidyScheme record.

	03-08-2018	Sander van Houten		CurrentUserID added.
	18-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

-- Save old record
SELECT	@XMLdel = (SELECT	* 
				   FROM		sub.tblSubsidyScheme
				   WHERE	SubsidySchemeID = @SubsidySchemeID
				   FOR XML PATH),
		@XMLins = NULL

-- Delete record
DELETE
FROM	sub.tblSubsidyScheme
WHERE	SubsidySchemeID = @SubsidySchemeID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @SubsidySchemeID

	EXEC his.uspHistory_Add
			'sub.tblSubsidyScheme',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspSubsidyScheme_Del ===============================================================	*/
