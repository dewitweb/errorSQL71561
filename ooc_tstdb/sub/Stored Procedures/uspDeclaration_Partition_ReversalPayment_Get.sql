
CREATE PROCEDURE [sub].[uspDeclaration_Partition_ReversalPayment_Get]
@ReversalPaymentID int,
@DeclarationID	int,
@PartitionID	int
AS
/*	==========================================================================================
	Purpose:	Get declaration/partition information for reversal payments 
				on bases of a DeclarationID and PartitionID.

	28-10-2019	Sander van Houten		OTIBSUB-1649	Added stip.viewDeclaration and 
                                            some tables because of datamodel change.
	21-02-2019	Sander van Houten		OTIBSUB-792	    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	der.ReversalPaymentID,
		d.DeclarationID,
		dep.PartitionID,
		COALESCE(osrd.CourseID, stpd.EducationID)       AS CourseID,
		COALESCE(osrd.CourseName, stpd.EducationName)   AS CourseName,
		d.ApprovedAmount,
		der.ReversalPaymentReason,
		der.PaymentRunID
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep 
ON      dep.DeclarationID = d.DeclarationID
INNER JOIN sub.tblDeclaration_ReversalPayment der 
ON      der.DeclarationID = d.DeclarationID 
INNER JOIN sub.tblDeclaration_Partition_ReversalPayment dpr 
ON      dpr.ReversalPaymentID = der.ReversalPaymentID
AND     dpr.PartitionID = dep.PartitionID
LEFT JOIN osr.viewDeclaration osrd 
ON      osrd.DeclarationID = d.DeclarationID
LEFT JOIN stip.viewDeclaration stpd 
ON      stpd.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID
AND	    dep.PartitionID = @PartitionID
AND     der.ReversalPaymentID = @ReversalPaymentID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Partition_ReversalPayment_Get ======================================	*/
