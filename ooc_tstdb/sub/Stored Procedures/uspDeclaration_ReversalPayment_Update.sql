
CREATE PROCEDURE [sub].[uspDeclaration_ReversalPayment_Update]
@DeclarationID				int,
@tblEmployee 				sub.uttEmployee READONLY,
@ReversalPaymentReason		varchar(max),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update or Add declaration information for reversal payments 
				on bases of a ReversalPaymentID or a DeclarationID.
				
    Note:       This procedure is executed by the frontend application.

	28-10-2019	Sander van Houten		OTUBSUB-1649	Reverse only the apropriate partition(s).
	21-02-2019	Sander van Houten		OTIBSUB-792	    Manier van vastlegging terugboeking 
										    bij werknemer veranderen.
	14-11-2018	Sander van Houten		Initial version.
	==========================================================================================  */

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @tblReversalPayment TABLE (ReversalPaymentID int)

DECLARE @RC					int,
		@ReversalPaymentID	int = NULL,
        @PartitionID	    int,
        @PaymentRunID       int = NULL,
        @tblEmployeeSOE	    sub.uttEmployee -- ScopeOfEmployment

/* Create or update Declaration_ReversalPayment record. */
INSERT INTO @tblReversalPayment (ReversalPaymentID)
EXEC @RC = [sub].[uspDeclaration_ReversalPayment_Upd] 
    @ReversalPaymentID,
    @DeclarationID,
    @ReversalPaymentReason,
    @PaymentRunID,
    @CurrentUserID

SELECT	TOP 1 
        @ReversalPaymentID = ReversalPaymentID 
FROM	@tblReversalPayment

/* Find out if there is only 1 partition to reverse.    */
DECLARE @OnePartition   bit = 0

IF  (   SELECT  COUNT(DISTINCT PartitionID)
        FROM	sub.tblPaymentRun_Declaration
        WHERE	DeclarationID = @DeclarationID
        AND	    ReversalPaymentID = 0
    ) = 1
BEGIN
    SET @OnePartition = 1
END

/* Get all partitions from tblDeclaration_Partition.	*/
DECLARE cur_reversals CURSOR FOR
        SELECT  pad.PartitionID
        FROM	sub.tblPaymentRun_Declaration pad
        WHERE	pad.DeclarationID = @DeclarationID
        AND	    pad.ReversalPaymentID = 0

OPEN cur_reversals

FETCH NEXT FROM cur_reversals INTO @PartitionID

WHILE @@FETCH_STATUS = 0  
BEGIN
    -- If more then 1 partition is being reversed, check the employees.
    IF @OnePartition = 1
    BEGIN
        INSERT INTO @tblEmployeeSOE
            (
                EmployeeNumber,
                ReversalPaymentID
            )
        SELECT  EmployeeNumber,
                ReversalPaymentID
        FROM    @tblEmployee
    END
    ELSE
    BEGIN
        INSERT INTO @tblEmployeeSOE
            (
                EmployeeNumber,
                ReversalPaymentID
            )
        SELECT  emp.EmployeeNumber,
                emp.ReversalPaymentID
        FROM    sub.tblDeclaration d
        INNER JOIN sub.tblDeclaration_Partition dep
        ON      dep.DeclarationID = d.DeclarationID
        INNER JOIN sub.tblDeclaration_Employee dem
        ON      dem.DeclarationID = d.DeclarationID
        INNER JOIN @tblEmployee emp 
        ON      emp.EmployeeNumber = dem.EmployeeNumber
        INNER JOIN sub.tblEmployee_ScopeOfEmployment soe
        ON      soe.EmployeeNumber = emp.EmployeeNumber
        AND     soe.EmployerNumber = d.EmployerNumber
        WHERE   d.DeclarationID = @DeclarationID
        AND     dep.PartitionID = @PartitionID
        AND     dep.PaymentDate BETWEEN soe.StartDate AND COALESCE(soe.EndDate, dep.PaymentDate)
    END

    -- Create or update reversal records.
    EXECUTE @RC = [sub].[uspDeclaration_Partition_ReversalPayment_Update] 
        @ReversalPaymentID,
        @DeclarationID,
        @PartitionID,
        @tblEmployeeSOE,
        @ReversalPaymentReason,
        @CurrentUserID

    -- Initialize table variable.
    DELETE FROM @tblEmployeeSOE

	FETCH NEXT FROM cur_reversals INTO @PartitionID
END

CLOSE cur_reversals
DEALLOCATE cur_reversals

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* == sub.uspDeclaration_ReversalPayment_Update ==============================================	*/
