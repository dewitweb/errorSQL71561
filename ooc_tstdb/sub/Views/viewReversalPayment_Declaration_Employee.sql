CREATE VIEW [sub].[viewReversalPayment_Declaration_Employee]
AS

SELECT	drp.ReversalPaymentID, 
		drp.DeclarationID,
		dprp.PartitionID,
		drp.PaymentRunID,
		der.EmployeeNumber
FROM	sub.tblDeclaration_ReversalPayment drp
INNER JOIN sub.tblDeclaration_Partition_ReversalPayment dprp
		ON	dprp.ReversalPaymentID = drp.ReversalPaymentID
INNER JOIN sub.tblDeclaration_Employee_ReversalPayment der
		ON der.ReversalPaymentID = drp.ReversalPaymentID 
