

CREATE FUNCTION [sub].[usfGetPartitionAmountCorrected]
/*	*********************************************************************************************
	Purpose:	Recalculates the amount that is left for a partition.

	12-11-2019	Jaap van Assenbergh		OTIBSUB-1700	PartitionAmountCorrected is leeg bij 
														Controle Lopende BPV
	24-10-2019	Sander van Houten		OTIBSUB-1618	Added code for EVC-WV.
	29-08-2019	Sander van Houten		OTUBSUB-1505	Having an Employer_Subsidy record is not mandatory.
	03-05-2019	Sander van Houten		OTUBSUB-1046	Move voucher use to partition level.
	18-04-2019	Jaap van Assenbergh		Alleen bij de eerste partitie de voucherbedragen meetellen.
	03-04-2019	Sander van Houten		Initial version.
	********************************************************************************************* */
(
	@PartitionID			int,
	@WithTotalVoucherAmount	bit = 0
)
RETURNS decimal(19,4)
AS
BEGIN
	DECLARE @PartitionAmountCorrected	decimal(19,4)
	DECLARE @SubsidySchemeID			int

	SELECT	@SubsidySchemeID = d.SubsidySchemeID, 
			@PartitionAmountCorrected = PartitionAmount							-- Initial PartitionAmountCorrected = PartitionAmount
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN sub.tblDeclaration d ON d.DeclarationID = dep.DeclarationID
	WHERE	dep.PartitionID = @PartitionID

	IF @SubsidySchemeID = 1	-- OSR
	BEGIN
		SELECT	@PartitionAmountCorrected = CASE WHEN ISNULL(eba.BalanceAmount, 0.00) < dep.PartitionAmount
													THEN ISNULL(eba.BalanceAmount, 0.00)
													ELSE dep.PartitionAmount 
											END 
											+ CASE WHEN @WithTotalVoucherAmount = 1 
												THEN ISNULL(sub2.TotalVoucherAmount, 0.00)
												ELSE 0.00
											  END
		FROM	sub.tblDeclaration_Partition dep
		INNER JOIN sub.tblDeclaration decl 
		ON		decl.DeclarationID = dep.DeclarationID
		LEFT JOIN sub.tblEmployer_Subsidy ems 
		ON		ems.EmployerNumber = decl.EmployerNumber
		AND		ems.SubsidyYear = dep.PartitionYear			
		LEFT JOIN sub.viewEmployerBalance eba
		ON		eba.SubsidySchemeID = ems.SubsidySchemeID
		AND		eba.EmployerNumber = decl.EmployerNumber
		AND		eba.SubsidyYear = ems.SubsidyYear
		LEFT JOIN (
					SELECT	dpv.DeclarationID,
							SUM(dpv.DeclarationValue)	AS TotalVoucherAmount
					FROM	sub.tblDeclaration_Partition_Voucher dpv
					LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
					ON		der.EmployeeNumber = dpv.EmployeeNumber
					AND		der.PartitionID = dpv.PartitionID
					WHERE	dpv.PartitionID = @PartitionID
					AND		der.ReversalPaymentID IS NULL
					GROUP BY
							dpv.DeclarationID
				  ) sub2
		ON		sub2.DeclarationID = decl.DeclarationID
		WHERE	dep.PartitionID = @PartitionID
	END

	IF @SubsidySchemeID = 3	-- EVC
	BEGIN
		SELECT	@PartitionAmountCorrected = CASE WHEN d.Declarationamount > CAST(aps.SettingValue AS money)
												THEN CAST(aps.SettingValue AS money)
												ELSE d.DeclarationAmount
											END
		FROM	sub.tblDeclaration_Partition dep
		INNER JOIN evc.viewDeclaration d ON d.DeclarationID = dep.DeclarationID
		CROSS JOIN sub.tblApplicationSetting aps 
		WHERE	dep.PartitionID = @PartitionID
		AND		aps.SettingName = 'SubsidyAmountPerType' 
		AND		SettingCode = CASE WHEN d.IsEVC500 = 1 
								THEN 'EVC500' 
								ELSE 'EVC' 
							  END
	END

	IF @SubsidySchemeID = 5	-- EVC-WV
	BEGIN
		SELECT	@PartitionAmountCorrected = CASE WHEN d.Declarationamount > CAST(aps.SettingValue AS money)
												THEN CAST(aps.SettingValue AS money)
												ELSE d.DeclarationAmount
											END
		FROM	sub.tblDeclaration_Partition dep
		INNER JOIN evcwv.viewDeclaration d ON d.DeclarationID = dep.DeclarationID
		CROSS JOIN sub.tblApplicationSetting aps 
		WHERE	dep.PartitionID = @PartitionID
		AND		aps.SettingName = 'SubsidyAmountPerType' 
		AND		SettingCode = CASE WHEN d.IsEVC500 = 1 
								THEN 'EVC500' 
								ELSE 'EVC' 
							  END
	END

	RETURN @PartitionAmountCorrected
END
