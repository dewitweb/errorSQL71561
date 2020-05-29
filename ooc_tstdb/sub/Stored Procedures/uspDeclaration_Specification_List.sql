

CREATE PROCEDURE [sub].[uspDeclaration_Specification_List]
@DeclarationID int
AS
/*	==========================================================================================
	Purpose: 	Get list from sub.tblDeclaration_Specification.

	08-08-2019	Sander van Houten		OTIBSUB-1447/1431	Corrected code for Summary specification.
	17-12-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @LastPaymentRunWithDeclarationSpecification int

-- First get Last PaymentRun with declaration specification.
SELECT	@LastPaymentRunWithDeclarationSpecification = SettingValue
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'LastPaymentRunWithDeclarationSpecification'

-- Then get final result.
SELECT
		decl.DeclarationID,
		dsp.SpecificationSequence,
		dsp.SpecificationDate,
		NULL JournalEntryCode
FROM	sub.tblDeclaration decl
INNER JOIN	sub.tblDeclaration_Specification dsp ON dsp.DeclarationID = decl.DeclarationID
WHERE	decl.DeclarationID = @DeclarationID
AND		dsp.PaymentRunID <= @LastPaymentRunWithDeclarationSpecification
AND		dsp.Specification IS NOT NULL

UNION ALL

SELECT
		decl.DeclarationID,
		1							SpecificationSequence,
		par.RunDate					SpecificationDate,
		JournalEntryCode
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblPaymentRun_Declaration prd ON	prd.DeclarationID = decl.DeclarationID
INNER JOIN sub.tblPaymentRun par ON par.PaymentRunID = prd.PaymentRunID
WHERE	decl.DeclarationID = @DeclarationID
AND		prd.PaymentRunID > @LastPaymentRunWithDeclarationSpecification

ORDER BY 
		SpecificationDate, 
		SpecificationSequence

/*	== sub.uspDeclaration_Specification_List =================================================	*/
