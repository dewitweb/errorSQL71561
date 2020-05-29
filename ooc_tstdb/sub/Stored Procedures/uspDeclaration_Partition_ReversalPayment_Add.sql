
CREATE PROCEDURE [sub].[uspDeclaration_Partition_ReversalPayment_Add]
@ReversalPaymentID  int,
@PartitionID		int,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Link a partition to a reversal payment.
				
	28-10-2019	Sander van Houten		OTIBSUB-1649	Initial version.
	==========================================================================================  */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

INSERT INTO sub.tblDeclaration_Partition_ReversalPayment
    (
        ReversalPaymentID,
        PartitionID
    )
VALUES
    (
        @ReversalPaymentID,
        @PartitionID
    )

-- Save new record
SELECT	@XMLdel = NULL,
        @XMLins = (SELECT	* 
                    FROM	sub.tblDeclaration_Partition_ReversalPayment
                    WHERE	ReversalPaymentID = @ReversalPaymentID
                    AND	    PartitionID = @PartitionID
                    FOR XML PATH)

-- Log action in tblHistory
SET @KeyID = @ReversalPaymentID

EXEC his.uspHistory_Add
        'sub.tblDeclaration_Partition_ReversalPayment',
        @KeyID,
        @CurrentUserID,
        @LogDate,
        @XMLdel,
        @XMLins

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_ReversalPayment_Add ======================================	*/
