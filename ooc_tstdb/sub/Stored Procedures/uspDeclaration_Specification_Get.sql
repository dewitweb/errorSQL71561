
CREATE PROCEDURE [sub].[uspDeclaration_Specification_Get]
@DeclarationID	int,
@SpecificationSequence int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblDeclaration_Specification on basis of DeclarationID.

	11-02-2019	Jaap van Assenbergh	Employernumber toegevoegd
	17-12-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

SELECT
		ds.DeclarationID,
		decl.EmployerNumber,
		ds.SpecificationSequence,
		ds.SpecificationDate,
		ds.PaymentRunID,
		ds.Specification,
		ds.SumPartitionAmount,
		ds.SumVoucherAmount,
		decl.SubsidySchemeID
FROM	sub.tblDeclaration decl
INNER JOIN	sub.tblDeclaration_Specification ds ON ds.DeclarationID = decl.DeclarationID
INNER JOIN sub.tblPaymentRun pr ON pr.PaymentRunID = ds.PaymentRunID
WHERE	decl.DeclarationID = @DeclarationID
AND		SpecificationSequence = @SpecificationSequence

/*	== uspDeclaration_Specification_Get ======================================================	*/
