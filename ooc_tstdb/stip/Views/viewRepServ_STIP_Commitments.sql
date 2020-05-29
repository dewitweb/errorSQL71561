CREATE VIEW [stip].[viewRepServ_STIP_Commitments]
AS

SELECT	TOP 1000000000
        LEFT(dep.PartitionYear, 4)              AS PartitionYear,
		RIGHT(dep.PartitionYear, 2)             AS PartitionMonth,
        d.EmployerNumber,
        d.EmployeeNumber,
		d.DeclarationID,
        d.DeclarationDate,
        d.StartDate,
        COALESCE(d.TerminationDate, d.EndDate)  AS EndDate,
        d.EducationName,
        d.EducationLevel,
		CAST(dep.PaymentDate AS date)           AS PaymentDate,
		dep.PartitionStatus,
		dep.PartitionAmount                     AS AmountSubmitted,
        CASE WHEN dep.PartitionStatus IN ('0010', '0012', '0014')
            THEN CASE WHEN dpr.ReversalPaymentID IS NULL
                    THEN dep.PartitionAmount
                    ELSE 0.00
                 END
            ELSE 0.00
        END                                     AS AmountPaid,
        CASE dep.PartitionStatus
            WHEN '0001' THEN CAST(aex.SettingValue AS decimal(19,2)) / 2    -- Planned
            WHEN '0007' THEN 0.00                   -- Rejected
            WHEN '0017' THEN 0.00                   -- Rejected
            WHEN '0024' THEN CASE WHEN dep.PartitionAmount = 0.00   -- Terminated
                                THEN CASE WHEN aex.SettingValue IS NULL
                                        THEN 0.00
                                        ELSE CASE WHEN bpv.TypeBPV = 'Opscholing'
                                                THEN CAST(aex.SettingValue AS decimal(19,2))
                                                ELSE CAST(aex.SettingValue AS decimal(19,2)) / 2
                                             END
                                     END
                                ELSE dep.PartitionAmount
                             END
            WHEN '0029' THEN 0.00                   -- Overdue
            WHEN '0032' THEN 0.00                   -- Diploma rejected
            ELSE dep.PartitionAmount
        END                                     AS AmountToBePaid
FROM	stip.viewDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Partition_ReversalPayment dpr ON dpr.PartitionID = dep.PartitionID
LEFT JOIN stip.tblDeclaration_BPV bpv ON bpv.DeclarationID = d.DeclarationID
INNER JOIN sub.tblApplicationSetting aps
ON  	aps.SettingName = 'SubsidyAmountPerType'
AND		aps.SettingCode = CASE WHEN ISNULL(bpv.TypeBPV, 'Instroom') = 'Opscholing'
                            THEN 'BPV'
                            ELSE 'STIP'
                          END
INNER JOIN	sub.tblApplicationSetting_Extended aex 
ON	    aex.ApplicationSettingID = aps.ApplicationSettingID
WHERE   (d.TerminationDate IS NULL
    OR   (   d.DiplomaDate IS NULL
            AND DATEADD(MONTH, -18, d.TerminationDate) <= CAST(GETDATE() AS date)
         )
    OR   (   d.DiplomaDate = dep.PaymentDate
            AND DATEADD(MONTH, -12, dep.PaymentDate) <= CAST(GETDATE() AS date)
         )
        )
AND     d.DeclarationStatus <> '0035'
ORDER BY
		d.EmployerNumber, 
		d.EmployeeNumber,
		PartitionYear,
        PartitionMonth
