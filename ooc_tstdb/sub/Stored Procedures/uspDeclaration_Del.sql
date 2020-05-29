CREATE PROCEDURE [sub].[uspDeclaration_Del]
@DeclarationID	int,
@CurrentUserID	int = 1
AS

/*	==========================================================================================
	Purpose:	Remove declaration record.

	01-09-2018	Jaap van Assenbergh		OTIBSUB-1511	Declarations that have status 0019 ipv 0008
	06-09-2019	Sander van Houten		OTIBSUB-1511	Declarations that have status 0008
											(Returned to employer) can be deleted also.
	18-06-2019	Sander van Houten		OTIBSUB-1219	Added delete of Declaration_Unkown_Source.
	13-09-2018	Sander van Houten		OTIBSUB-249		Toevoegen checks in usp bij verwijderen.
	11-09-2018	Jaap van Assenbergh		Add cursors for logging delete on child records.
	02-08-2018	Sander van Houten		CurrentUserID added.
	19-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @Return		int = 1	-- Initial returncode is error

DECLARE @SubsidiySchemeID int

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE	@PaymentRunID		int,
		@EmployeeNumber		varchar(8),
		@PartitionID		int,
		@AttachmentID		uniqueidentifier,
		@RejectionReason	varchar(24),
		@EmailID			int,
		@InvestigationDate	datetime

/*	User can only delete own declarations that have not been processed yet (OTIBSUB-249).	
	or have been returned to employer (OTIBSUB-1511)*/
IF NOT EXISTS
	(
		SELECT	1
		FROM	sub.tblDeclaration decl
		INNER JOIN sub.tblUser_Role_Employer ure
		ON ure.EmployerNumber = decl.EmployerNumber
		WHERE	decl.DeclarationID = @DeclarationID
		  AND	decl.DeclarationStatus IN ('0001', '0002', '0019', '0023')
		  AND	ure.UserID = @CurrentUserID
	)
BEGIN
	GOTO usp_Exit
END

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Save old record
SELECT	@XMLdel = (SELECT * 
				   FROM sub.tblDeclaration 
			       WHERE DeclarationID = @DeclarationID 
				   FOR XML PATH),
		@XMLins = NULL

/*	Table tblPaymentRun_Declaration does have ref.int but can not have records. 
	Only declarations in the first step (in future) can be deleted. 
	Paid declarations can't be deleted.											*/
/*	DELETE FROM sub.tblPaymentRun_Declaration WHERE DeclarationID = @DeclarationID	*/

/*	DELETE FROM sub.tblDeclaration_Employee WHERE DeclarationID = @DeclarationID	*/
DECLARE crs_Employee CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	EmployeeNumber
		FROM	sub.tblDeclaration_Employee
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Employee
	FETCH FROM crs_Employee
	INTO @EmployeeNumber
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Employee_Delete @DeclarationID, @EmployeeNumber, @CurrentUserID

	FETCH NEXT FROM crs_Employee
	INTO @EmployeeNumber
END
CLOSE crs_Employee
DEALLOCATE crs_Employee

/* Delete Rejections */
DECLARE crs_Rejection CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	PartitionID, RejectionReason
		FROM	sub.tblDeclaration_Rejection
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Rejection
	FETCH FROM crs_Rejection
	INTO @PartitionID, @RejectionReason
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Rejection_Del @DeclarationID, @PartitionID, @RejectionReason, @CurrentUserID

	FETCH NEXT FROM crs_Rejection
	INTO @PartitionID, @RejectionReason
END
CLOSE crs_Rejection
DEALLOCATE crs_Rejection

/* Delete Emails */
DECLARE crs_Email CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	EmailID
		FROM	sub.tblDeclaration_Email
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Email
	FETCH FROM crs_Email
	INTO @EmailID
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Email_Del @EmailID, @CurrentUserID

	FETCH NEXT FROM crs_Email
	INTO @EmailID
END
CLOSE crs_Email
DEALLOCATE crs_Email

/* Delete Investigations */
DECLARE crs_Investigation CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	InvestigationDate
		FROM	sub.tblDeclaration_Investigation
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Investigation
	FETCH FROM crs_Investigation
	INTO @InvestigationDate

WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Investigation_Del @DeclarationID, @InvestigationDate, @CurrentUserID

	FETCH NEXT FROM crs_Investigation
	INTO @InvestigationDate
END
CLOSE crs_Investigation
DEALLOCATE crs_Investigation

/*	DELETE FROM sub.tblDeclaration_Partition WHERE DeclarationID = @DeclarationID	*/
DECLARE crs_Partition CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	PartitionID
		FROM	sub.tblDeclaration_Partition
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Partition
	FETCH FROM crs_Partition
	INTO @PartitionID
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Partition_Del @PartitionID, @CurrentUserID

	FETCH NEXT FROM crs_Partition
	INTO @PartitionID
END
CLOSE crs_Partition
DEALLOCATE crs_Partition

/*	DELETE FROM sub.tblDeclaration_Attachment WHERE DeclarationID = @DeclarationID	*/
DECLARE crs_Attachment CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	AttachmentID
		FROM	sub.tblDeclaration_Attachment
		WHERE	DeclarationID = @DeclarationID
	OPEN crs_Attachment
	FETCH FROM crs_Attachment
	INTO @AttachmentID
WHILE @@FETCH_STATUS = 0   
BEGIN

	EXECUTE sub.uspDeclaration_Attachment_Del @DeclarationID, @AttachmentID, @CurrentUserID

	FETCH NEXT FROM crs_Attachment
	INTO @AttachmentID
END
CLOSE crs_Attachment   
DEALLOCATE crs_Attachment

/*	Table tblDeclaration_Rejection does have ref.int but can not have records. 
	Only declarations in the first step (in future) can be deleted. 
	Rejected declarations can't be deleted.											*/
/*	DELETE FROM sub.tblDeclaration_Rejection WHERE DeclarationID = @DeclarationID	*/

/*	DELETE FROM sub.tblDeclaration_Unkown_Source WHERE DeclarationID = @DeclarationID	*/
EXECUTE sub.uspDeclaration_Unknown_Source_Del @DeclarationID, @CurrentUserID

-- Delete record
SELECT	@SubsidiySchemeID = SubsidySchemeID
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

IF @SubsidiySchemeID = 1 
	EXECUTE osr.uspDeclaration_Del @DeclarationID, @CurrentUserID
--IF @SubsidiySchemeID = 2
--	EXECUTE bpv.uspDeclaration_Del @DeclarationID, @CurrentUserID
IF @SubsidiySchemeID = 3
	EXECUTE evc.uspDeclaration_Del @DeclarationID, @CurrentUserID
IF @SubsidiySchemeID = 4
	EXECUTE stip.uspDeclaration_Delete @DeclarationID, @CurrentUserID
IF @SubsidiySchemeID = 5
	EXECUTE evcwv.uspDeclaration_Del @DeclarationID, @CurrentUserID

DELETE
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

-- Log action in tblHistory
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

usp_Exit:
RETURN @Return

/*	== sub.uspDeclaration_Del =================================================================	*/
