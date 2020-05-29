 CREATE PROCEDURE [his].[uspHistory_Add]
	@TableName		varchar(50),
	@KeyID			varchar(50),
	@UserID			int,
	@LogDate		datetime,
	@OldValue		xml,
	@NewValue		xml
AS
/*	==========================================================================================
	Doel:	Historie toevoegen aan database

	01-08-2018	Sander van Houten	Initiële versie
	==========================================================================================	*/

INSERT INTO his.tblHistory
	(
		TableName,
		KeyID,
		UserID,
		LogDate,
		OldValue,
		NewValue
	)
VALUES
	(
		@TableName,
		@KeyID,
		@UserID,
		@LogDate,
		@OldValue,
		@NewValue
	)

/*	== his.uspHistory_Add ====================================================================	*/


