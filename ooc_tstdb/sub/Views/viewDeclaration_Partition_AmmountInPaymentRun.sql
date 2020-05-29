
CREATE VIEW [sub].[viewDeclaration_Partition_AmmountInPaymentRun]
AS
/*	==========================================================================================
	Purpose:	Select total amounts for current paymentrun per partition.

	13-02-2020	Sander van Houten	OTIBSUB-1890    Corrected selection for reversals.
	==========================================================================================	*/

SELECT	PartitionID, 
		DeclarationID, 
		PartitionStatus, 
		PartitionAmountCorrected,
		VoucherValue,
		PaymentDate
FROM	(
			SELECT	dep.PartitionID, 
					dep.DeclarationID, 
					dep.PartitionStatus, 
					dep.PartitionAmountCorrected,
					SUM(ISNULL(depv.DeclarationValue, 0)) VoucherValue,
					dep.PaymentDate
			FROM	sub.tblDeclaration_Partition dep
			LEFT JOIN sub.tblDeclaration_Partition_Voucher depv ON depv.PartitionID = dep.PartitionID
			WHERE dep.PartitionStatus IN ('0007', '0009', '0021')
			GROUP BY 
				    dep.PartitionID, 
					dep.DeclarationID, 
					dep.PartitionStatus, 
					dep.PartitionAmountCorrected,
					dep.PaymentDate

			UNION ALL

			SELECT	dep.PartitionID, 
					dep.DeclarationID, 
					dep.PartitionStatus, 
					dep.PartitionAmountCorrected,
					SUM(ISNULL(depv.DeclarationValue, 0)) VoucherValue,
					dep.PaymentDate
			FROM	sub.tblDeclaration decl
			INNER JOIN	sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblDeclaration_Partition_Voucher depv ON depv.PartitionID = dep.PartitionID
			WHERE	decl.DeclarationStatus = '0031'
			AND		dep.PartitionStatus = '0024'
			GROUP BY 
				    dep.PartitionID, 
					dep.DeclarationID, 
					dep.PartitionStatus, 
					dep.PartitionAmountCorrected,
					dep.PaymentDate

			UNION ALL

			SELECT	PartitionID, 
					DeclarationID, 
					PartitionStatus, 
					PartitionAmountCorrected * COUNT(ReversalEmployee.EmployeeNumber),
					VoucherValue,
					PaymentDate		
			FROM	(
						SELECT	dep.PartitionID, 
								dep.DeclarationID, 
								dep.PartitionStatus, 
								dep.PartitionAmountCorrected
								/	(
										SELECT	COUNT(1)
										FROM	sub.tblDeclaration_Employee dee
										WHERE 	dee.DeclarationID = dep.DeclarationID
									) * -1      AS PartitionAmountCorrected,
								der.EmployeeNumber,
								ISNULL	(
											(
												SELECT	SUM(ISNULL(depv.DeclarationValue, 0))
												FROM	sub.tblDeclaration_Partition_Voucher depv 
												WHERE	depv.PartitionID = dep.PartitionID
												AND		der.EmployeeNumber = depv.EmployeeNumber
											) * -1
										, 0)    AS VoucherValue,
								dep.PaymentDate
						FROM	sub.tblDeclaration_Partition dep
						INNER JOIN	sub.tblDeclaration_Employee_ReversalPayment der 
                        ON	    der.PartitionID = dep.PartitionID
                        AND	    der.ReversalPaymentID IS NOT NULL
						WHERE	dep.PartitionStatus = '0016'
                        AND     der.ReversalPaymentID NOT IN (  
                                                                SELECT  DISTINCT ReversalPaymentID
                                                                FROM    sub.tblPaymentRun_Declaration pad
                                                                WHERE   pad.PartitionID = dep.PartitionID
                                                             )
					) ReversalEmployee
				GROUP BY
					PartitionID, 
					DeclarationID, 
					PartitionStatus, 
					PartitionAmountCorrected,
					VoucherValue,
					PaymentDate		
		)	Partitions

/*	== sub.viewDeclaration_Partition_AmmountInPaymentRun =====================================	*/
