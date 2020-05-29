
CREATE PROCEDURE [sub].[uspDeclaration_Specification_Export]
@DeclarationID			int,
@SpecificationSequence	int,
@CurrentUserID			int
AS
/*	==========================================================================================
	Purpose: 	Get data from sub.tblDeclaration_Specification on basis of DeclarationID
				for download purposes.

	06-05-2019	Sander van Houten		OTIBSUB-1045	Initial version.
	==========================================================================================	*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(100)

/*	Log the download action.	*/
SET @KeyID = CAST(@DeclarationID AS varchar(18)) + '|' + CAST(@SpecificationSequence AS varchar(18))

SELECT	@XMLdel = CAST('<download>1</download>' AS xml),
		@XMLins = CAST('<row><FileName>Declaratie specificatie ID_' + CAST(@DeclarationID AS varchar(6)) + '</FileName></row>' AS xml)

EXEC his.uspHistory_Add
		'sub.tblDeclaration_Specification',
		@KeyID,
		@CurrentUserID,
		@LogDate,
		@XMLdel,
		@XMLins

/*	Give back result.	*/
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
