CREATE PROCEDURE [sub].[usp_OTIB_PaymentRun_Declarations_List]
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Get all declarations that were included in a specific PaymentRun.

	07-02-2020	Sander van Houten	OTIBSUB-1890	Corrected some countings.
	19-11-2019	Sander van Houten	OTIBSUB-1684	Added SubsidySchemeName to resultset.
	09-09-2019	Sander van Houten	OTIBSUB-989		Altered amount fields.
	03-09-2019	Sander van Houten	OTIBSUB-1480	Get amounts from sub.tblPaymentRun_Declaration
										instead of sub.viewPaymentRun_Declaration.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	Specificatie op declaratieniveau of op verzamelnota
	07-03-2019	Jaap van Assenbergh	Course from osr.viewDeclaration
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	09-01-2019	Sander van Houten	OTIBSUB-230		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata
DECLARE	@PaymentRunID	int = 52481
--*/

-- Get all declarations for overview.
SELECT	pad.PaymentRunID,
        ssc.SubsidySchemeName,
		pad.declarationID,
		emp.EmployerName,
		CASE d.SubsidySchemeID
			WHEN 1 THEN LEFT(osrd.CourseName, 50)									
			WHEN 2 THEN LEFT(stpd.EducationName, 50)					
			ELSE NULL				
		END															AS CourseName,
		CONVERT(varchar(10), d.DeclarationDate, 105)				AS DeclarationDate,
		CAST(ISNULL(pad.PartitionAmount, 0.00) 
			+ ISNULL(pad.VoucherAmount, 0.00) AS decimal(19,2))		AS PaidAmount
FROM	sub.tblPaymentRun_Declaration pad
INNER JOIN sub.tblDeclaration d ON d.DeclarationID = pad.DeclarationID
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = d.EmployerNumber
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = d.SubsidySchemeID
LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
WHERE	pad.PaymentRunID = @PaymentRunID

-- Get summary for ActionPanel.
;WITH cte_Declarations AS (
	SELECT	pad.PaymentRunID,
			dep.DeclarationID,
			CASE dep.PartitionStatus 
				WHEN '0017' THEN 1
				ELSE 0
			END											AS Rejected,
			CASE dep.PartitionStatus 
				WHEN '0017' THEN 0
				WHEN '0028' THEN 0
				ELSE CASE pad.ReversalPaymentID
						WHEN 0 THEN 1
						ELSE 0
					 END
			END											AS Paid,
			CASE pad.ReversalPaymentID
				WHEN 0 THEN 0
				ELSE 1
			END											AS Reversed,
			0											AS ExtraPayments,
			d.EmployerNumber,
			CASE WHEN pad.ReversalPaymentID = 0
                THEN CASE dep.PartitionStatus 
                        WHEN '0017' THEN 0.00
                        ELSE ISNULL(pad.PartitionAmount, 0.00) 
					         + ISNULL(pad.VoucherAmount, 0.00)
                     END
				ELSE 0.00
			END											AS AmountDebit,
			CASE WHEN pad.ReversalPaymentID = 0
				THEN 0.00
				ELSE ISNULL(pad.PartitionAmount, 0.00) 
					 + ISNULL(pad.VoucherAmount, 0.00)
			END											AS AmountCredit
	FROM	sub.tblPaymentRun_Declaration pad
	INNER JOIN sub.tblDeclaration_Partition dep 
	ON		dep.PartitionID = pad.PartitionID
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID = dep.DeclarationID
	WHERE	pad.PaymentRunID = @PaymentRunID
)
SELECT	PaymentRunID,
		SUM(Rejected)											TotalRejected,
		SUM(Paid)												TotalPaid,
		SUM(Reversed)											TotalReversed,
		COUNT(DeclarationID)							        TotalProcessed,
		SUM(ExtraPayments)										TotalExtraPayments,
		COUNT(DISTINCT EmployerNumber)							TotalCreditors,
		CAST(SUM(AmountDebit) AS decimal(19,2))					TotalAmountDebit,
		CAST(SUM(AmountCredit) AS decimal(19,2))				TotalAmountCredit,
		CAST(SUM(AmountDebit + AmountCredit) AS decimal(19,2))	TotalAmount
FROM	cte_Declarations
GROUP BY
		PaymentRunID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_PaymentRun_Declarations_List =============================================	*/
