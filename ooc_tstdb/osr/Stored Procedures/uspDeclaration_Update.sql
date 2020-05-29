
CREATE PROCEDURE [osr].[uspDeclaration_Update]
@DeclarationID				int,
@EmployerNumber				varchar(6),
@DeclarationDate			datetime,
@InstituteID				int,
@CourseID					int,
@Location					varchar(100),
@ElearningSubscription		bit,
@StartDate					date,
@EndDate					date,
@DeclarationAmount			decimal(9,4),
@InstituteName				varchar(100),
@CourseName					varchar(100),
@Partition					xml,
@CurrentUserID				int = 1
AS

/*	==========================================================================================
	Purpose: 	Update osr.tblDeclaration on basis of DeclarationID.

	30-09-2019	Sander van Houten		OTIBSUB-1598	Added transaction.
	12-02-2019	Sander van Houten		CourseID and InstituteID can't be 0 because of FK-constraint.
	07-11-2018	Jaap van Assenbergh		OTIBSUB-416		Parameters verwijderen uit subDeclaration_Upd
											- DeclarationStatus
											- StatusReason
											- InternalMemo
	02-11-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @SubsidySchemeID int = 1

DECLARE @Declaration TABLE (DeclarationID int)

BEGIN TRY
BEGIN TRANSACTION
	INSERT INTO @Declaration
	EXEC sub.uspDeclaration_upd
		@DeclarationID,
		@EmployerNumber,
		@SubsidySchemeID,
		@DeclarationDate,
		@InstituteID,
		@StartDate,
		@EndDate,
		@DeclarationAmount,
		@Partition,
		@CurrentUserID

	SELECT	@DeclarationID = DeclarationID 
	FROM	@Declaration

	-- Add record to sub.tblDeclaration_Unkown_Source for further investigation by OTIB user.
	IF ISNULL(@CourseID, 0) = 0
	BEGIN
		IF @InstituteID = 0
			SET @InstituteID = NULL

		IF @CourseID = 0
			SET @CourseID = NULL

		EXEC osr.uspDeclaration_Unknown_Source_Upd
				@DeclarationID,
				@InstituteID,
				@InstituteName,
				@CourseID,
				@CourseName,
				NULL,	--SendToSourceSystemDate
				NULL,	--ReceivedFromSourceSystemDate
				@CurrentUserID
	END
	ELSE
	BEGIN
		-- Save old record
		SELECT	@XMLdel = (SELECT * 
						   FROM   sub.tblDeclaration_Unknown_Source 
						   WHERE  DeclarationID = @DeclarationID
						   FOR XML PATH)
	
		DELETE 
		FROM	sub.tblDeclaration_Unknown_Source 
		WHERE	DeclarationID = @DeclarationID

		EXEC his.uspHistory_Add
			'sub.tblDeclaration_Unknown_Source',
			@DeclarationID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
	END

	BEGIN
		EXEC osr.uspDeclaration_Upd @DeclarationID, @CourseID, @Location, @ElearningSubscription
	END

	COMMIT TRANSACTION
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION

	--		RAISERROR ('%s',16, 1, @variable_containing_error)
END CATCH

SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== osr.uspDeclaration_Update ==============================================================	*/
