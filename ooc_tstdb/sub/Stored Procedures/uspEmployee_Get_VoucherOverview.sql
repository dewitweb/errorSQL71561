
CREATE PROCEDURE [sub].[uspEmployee_Get_VoucherOverview]
@EmployerNumber		varchar(6),
@EmployeeNumber		varchar(8)
AS
/*	==========================================================================================
	Purpose:	List all voucherdata for employee at an employer.

	13-01-2020	Jaap van Assenebrgh	OTIBSUB-1786	Voucher wordt niet getoond bij werknemer
	09-09-2019	Sander van Houten	OTIBSUB-1500	Added ValidyDate to resultset.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	15-11-2018	Sander van Houten	Removed DoNotCash field and added Reversal field.
	13-11-2018	Sander van Houten	Altered tblVoucher_Employee to tblEmployee_Voucher.
	30-10-2018	Jaap van Assenbergh	OTIBSUB-385		Overzichten - filter op subsidieregeling
										and deleted parameter @SubsidySchemeID.
	11-09-2018	Jaap van Assenbergh	OTIBSUB-243		Added Date ModifyUntil.
	27-08-2018	Sander van Houten	OTIBSUB-48		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @RC int

EXECUTE @RC = [sub].[uspEmployee_SyncHorusVoucher] 
   @EmployeeNumber

SELECT	
		sel.EmployeeNumber,
		sel.EmployerNumber,
		sel.VoucherNumber,
		sel.GrantDate,
		sel.ValidityDate,
		sel.EventCity,
		sel.EventName,
		sel.VoucherValue,
		sel.DeclarationValue,
		sel.DeclarationValueInprocess,
		sel.DeclarationValuePaid,
		sel.DeclarationValueCredit,
		CAST( CASE WHEN sel.ModifyUntil IS NOT NULL 
					 OR sel.DeclarationStatus = '0019' 
				THEN 1 
				ELSE 0 
			  END AS bit)   AS CanModify,
		sel.ModifyUntil
FROM	
		(
			SELECT	DISTINCT
					eme.EmployeeNumber,
					eme.EmployerNumber,
					emv.VoucherNumber,
					emv.GrantDate,
					emv.ValidityDate,
					emv.EventCity											AS EventCity,
					emv.EventName											AS EventName,
					emv.VoucherValue,
					CAST(ISNULL(emv.AmountBalance, 0) AS decimal(19,2))		AS DeclarationValue,
					0.00													AS DeclarationValueInprocess,
					0.00													AS DeclarationValuePaid,
					0.00													AS DeclarationValueCredit,
					CASE WHEN decl.StartDate >= CAST(GETDATE() AS date) 
                          AND decl.DeclarationStatus = '0001' 
						THEN decl.StartDate 
						ELSE NULL 
					END		                                                AS ModifyUntil,
					decl.DeclarationStatus
			FROM	sub.tblEmployer_Employee eme 
			INNER JOIN	sub.tblEmployee_Voucher emv
					ON	emv.EmployeeNumber = eme.EmployeeNumber
			LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv
					ON	dpv.EmployeeNumber = emv.EmployeeNumber
					AND	dpv.VoucherNumber = emv.VoucherNumber
			LEFT JOIN	sub.tblDeclaration_Employee dem
					ON	dem.DeclarationID = dpv.DeclarationID
					AND	dem.EmployeeNumber = dpv.EmployeeNumber
			LEFT JOIN	sub.tblDeclaration_Employee_ReversalPayment der
					ON	der.DeclarationID = dpv.DeclarationID
					AND	der.EmployeeNumber = dpv.EmployeeNumber
			LEFT JOIN	sub.tblDeclaration decl 
					ON	decl.DeclarationID = dpv.DeclarationID
			WHERE	eme.EmployerNumber IN
					(
						SELECT @EmployerNumber
						UNION 
						SELECT	EmployerNumberChild
						FROM	sub.tblEmployer_ParentChild
						WHERE	EmployerNumberParent = @EmployerNumber
					)
			AND	    emv.EmployeeNumber = @EmployeeNumber
			AND	    der.ReversalPaymentID IS NULL
			AND	    emv.Active = 1
		) sel

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Get_VoucherOverview ===================================================	*/
