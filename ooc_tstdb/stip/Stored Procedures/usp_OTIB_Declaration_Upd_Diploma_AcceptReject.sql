
CREATE PROCEDURE [stip].[usp_OTIB_Declaration_Upd_Diploma_AcceptReject]
@DeclarationID	int,
@Accept			bit,
@Reason			varchar(max),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Accept or Reject an uploaded diploma (Stip) by an OTIB user.

	25-11-2019	Jaap van Assenbergh		On accept update amountCorrected of the ended (0024) 
										partition

	09-09-2019	Jaap van Assenbergh		OTIBSUB-1178	Initial version.
		1. Prepare the last payment (the diploma payment).
		2. The STIP process will be terminated on the date of the diploma.
		3. Reference dates after the diploma date will not be paid.
		4. Any payments from other reference dates made after the diploma date will be reclaimed.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @DeclarationStatus			varchar(4)
DECLARE @StatusXML					xml

DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,2),
		@PartitionAmountCorrected	decimal(19,2),
		@PartitionStatus			varchar(4),
		@PaymentDate				date,
		@CorrectionAmount			decimal(19,2),
		@VoucherAmount				decimal(19,2)

DECLARE @DiplomaDate				date

SET	@PartitionStatus = CASE @Accept WHEN 0 THEN '0007' ELSE '0009' END
SET @DeclarationStatus = CASE @Accept WHEN 0 THEN '0032' ELSE '0033' END

/* 1. Prepare the last payment (the diploma payment).*/
-- Fill variables.
SELECT  @PartitionID = PartitionID,
        @PartitionYear = PartitionYear,
        @PartitionAmount = PartitionAmount,
        @PartitionAmountCorrected = PartitionAmount
FROM	sub.tblDeclaration_Partition
WHERE	DeclarationID = @DeclarationID
AND		PartitionStatus = '0024'

IF	@Accept = 1						-- Unknown Source accepted.
BEGIN
	SELECT	@DiplomaDate = DiplomaDate
	FROM	stip.tblDeclaration
	WHERE	DeclarationID = @DeclarationID
END

-- Update record.
EXECUTE	sub.uspDeclaration_Partition_Upd
	@PartitionID,
	@DeclarationID,
	@PartitionYear,
	@PartitionAmount,
	@PartitionAmountCorrected,
	@DiplomaDate,
	@PartitionStatus,
	@CurrentUserID

/*	Finally update Declaration.	*/
EXEC sub.uspDeclaration_Upd_DeclarationStatus
		@DeclarationID,
		@DeclarationStatus,
		@Reason,
		@CurrentUserID
 
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Declaration_Upd_AcceptReject =============================================	*/
