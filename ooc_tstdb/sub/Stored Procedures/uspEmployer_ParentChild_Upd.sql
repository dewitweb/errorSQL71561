CREATE PROCEDURE sub.uspEmployer_ParentChild_Upd
@EmployerNumberParent	varchar(8),
@EmployerNumberChild	varchar(8),
@StartDate				date,
@EndDate				date,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Insert new or update existing record in sub.tblEmployer_ParentChild.

	16-04-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

IF NOT EXISTS (	SELECT	1 
				FROM	sub.tblEmployer_ParentChild
				WHERE	EmployerNumberParent = @EmployerNumberParent
				  AND	EmployerNumberChild = @EmployerNumberChild
			  )
BEGIN
	-- Add new record
	INSERT INTO sub.tblEmployer_ParentChild
		(
			EmployerNumberParent,
			EmployerNumberChild,
			StartDate,
			EndDate
		)
	VALUES
		(
			@EmployerNumberParent,
			@EmployerNumberChild,
			@StartDate,
			@EndDate
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_ParentChild
						WHERE	EmployerNumberParent = @EmployerNumberParent
						  AND	EmployerNumberChild = @EmployerNumberChild
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblEmployer_ParentChild
						WHERE	EmployerNumberParent = @EmployerNumberParent
						  AND	EmployerNumberChild = @EmployerNumberChild
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblEmployer_ParentChild
	SET
			EmployerNumberParent	= @EmployerNumberParent,
			EmployerNumberChild		= @EmployerNumberChild,
			StartDate				= @StartDate,
			EndDate					= @EndDate
	WHERE	EmployerNumberParent = @EmployerNumberParent
	  AND	EmployerNumberChild = @EmployerNumberChild

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_ParentChild
						WHERE	EmployerNumberParent = @EmployerNumberParent
						  AND	EmployerNumberChild = @EmployerNumberChild
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	SET @KeyID = @EmployerNumberParent + '|' + @EmployerNumberChild

	EXEC his.uspHistory_Add
			'sub.tblEmployer_ParentChild',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_ParentChild_Upd =======================================================	*/
