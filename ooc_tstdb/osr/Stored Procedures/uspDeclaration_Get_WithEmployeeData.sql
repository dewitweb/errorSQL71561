
CREATE PROCEDURE [osr].[uspDeclaration_Get_WithEmployeeData]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get declaration information with linked employees on bases of a DeclarationID.

	28-01-2020	Sander van Houten	OTIBSUB-1853	Show just one line per partition even when 
                                        there are multiple vouchers.
	06-12-2019	Sander van Houten	OTIBSUB-1758	Do not show data from before 01-01-2019.
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	06-11-2019	Sander van Houten	OTIBSUB-1644    Added Partition TimeTable.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie.
	09-09-2019	Jaap van Assenbergh	OTIBSUB-1548	Retour werkgever mag alleen als 
                                        er nog geen betaling is geweest.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	Specificatie op declaratieniveau of 
										op verzamelnota.
	28-06-2019	Sander van Houten	Added selection on status 0022 (new course).
	10-05-2019	Jaap van Assenbergh	OTIBSUB-1068	Originele invoer door werkgever van 
										nieuw instituut en/of opleiding altijd tonen.
	06-05-2019	Jaap van Assenbergh	OTIBSUB-1030	Declaratie terugsturen naar werkgever 
										(retour werkgever).
	26-04-2019	Sander van Houten	OTIBSUB-943		Add options for declarations with status
										Question asked.
	19-04-2019	Sander van Houten	OTIBSUB-990		Declaration double reversal.
	12-04-2019	Jaap van Assenbergh	OTIBSUB-954		Alleen [Vergoed bedrag] 2019 tonen.	
	04-04-2019	Jaap van Assenbergh	OTIBSUB-918		JournalEntryCode toegevoegd.
	05-03-2019	Jaap van Assenbergh	OTIBSUB-816		Uitbreiden output met bedrag aan 
										waardebonnen.
	26-02-2019	Sander van Houten	OTIBSUB-806		Afgekeurde declaraties 
										moeten in onderzoek gezet kunnen worden.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	31-01-2019 Jaap van Assenbergh	OTIBSUB-662		CanSetToInvestigation en CanAcceptOrReject.
	25-01-2019 Jaap van Assenbergh	OTIBSUB-715		ModifyUntil toegevoegd.
	17-01-2019	Sander van Houten	OTIBSUB-678		Show CanDownloadSpecification 
										on bases of RoleID.
	10-12-2018	Sander van Houten	OTIBSUB-531		InstituteNameCount replaced by InstituteName.
	11-10-2018	Jaap van Assenbergh	OTIBSUB-346		LEFT JOINS on Cource and Institute.
	31-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 407561,
        @UserID			int = 1
--  */

/*  Max of ReversalPaymentID.   */
DECLARE	@MaxReversalPaymentID	int

SELECT	@MaxReversalPaymentID = ReversalPaymentID
FROM	sub.tblDeclaration_ReversalPayment
WHERE	DeclarationID = @DeclarationID
  AND	PaymentRunID IS NULL

/*  Determine Role(s) of current user.  */
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

/*  Get status of active partition (OTIBSUB-1539).   */
DECLARE	@ActivePartitionStatus	varchar(4)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		

/*	Select Resultset 1.	*/
SELECT
		sel.DeclarationID,
		sel.DeclarationNumber,
		sel.JournalEntryCode,
		sel.EmployerNumber,
		sel.EmployerName,
		sel.IBAN,
		sel.SubsidySchemeID,
		sel.SubsidySchemeName,
		sel.DeclarationDate,
		sel.InstituteID,
		sel.InstituteName,
		sel.CourseID,
		sel.CourseName,
		sel.DeclarationStatus,
		sel.[Location],
		sel.ElearningSubscription,
		sel.StartDate,
		sel.EndDate,
		sel.DeclarationAmount,
		sel.ApprovedAmount,
		sel.VoucherAmount,
		sel.StatusReason,
		sel.InternalMemo,
        sel.TimeTable,
		sel.CanDownloadSpecification,
		sel.CanReverse,
		sel.CanSetToInvestigation,
		sel.CanAccept,
		sel.CanReject,
		sel.CanReturnToEmployer,
		sel.GetRejectionReason,
		sel.ShowStatusReason,
		sel.ReversalPaymentReason,
		CAST(CASE WHEN sel.ModifyUntil IS NOT NULL 
					OR sel.DeclarationStatus = '0019' 
				THEN 1 
				ELSE 0 
			 END AS bit)    AS CanModify,
		sel.ModifyUntil	
FROM
		(
			SELECT  DISTINCT
					d.DeclarationID,
					CAST(d.DeclarationID AS varchar(6))													DeclarationNumber,
					pad.JournalEntryCode,
					d.EmployerNumber,
					e.EmployerName,
					e.IBAN,
					d.SubsidySchemeID,
					s.SubsidySchemeName,
					d.DeclarationDate,
					d.InstituteID,
					di.InstituteName																	InstituteName,
					d.CourseID,
					d.CourseName																		CourseName,
					d.DeclarationStatus,
					d.[Location],
					d.ElearningSubscription,
					d.StartDate,
					d.EndDate,
					d.DeclarationAmount,
					ISNULL(dtp.TotalPaidAmount, 0.00)	                                                ApprovedAmount,
					CAST(ISNULL(dtva.TotalVoucherAmount, 0) AS decimal(19,2))							VoucherAmount,
					d.StatusReason,
					d.InternalMemo,
					(
						-- CASE WHEN @OTIB_User = 1
						-- 	THEN 
						-- (
							SELECT	
									sub.EventType,
                                    sub.EventStyle,
									sub.EventDate,
                                    sub.JournalEntryCode,
                                    sub.PaymentRunID,
                                    sub.TotalAmount,
									sub.EventDescription,
									sub.BudgetAmount,
                                    sub.VoucherDescription,
                                    sub.VoucherAmount,
									sub.EventStatus,
									sub.SpecificationSequence
							FROM	(
                                        -- Paid partitions.
                                        SELECT	1														EventType,
                                                CASE WHEN dep.PartitionStatus IN ('0017') THEN 'Red'
                                                     ELSE 'Green'
                                                END                                                     EventStyle,
                                                CAST(par.RunDate AS date)							    EventDate,
                                                ISNULL(pad.JournalEntryCode, '')                        JournalEntryCode,
                                                ISNULL(pad.PaymentRunID, '')                            PaymentRunID,
                                                CASE WHEN dep.PartitionStatus IN ('0017') 
                                                    THEN REPLACE(CAST(CAST(dep.PartitionAmount + 
                                                                                ISNULL(dpv.DeclarationValue, 0.00)
                                                                            AS decimal(19,2))
                                                                        AS varchar(20))
                                                                    , '.', ',')                                    
                                                    ELSE REPLACE(CAST(CAST(pad.PartitionAmount + pad.VoucherAmount
                                                                            AS decimal(19,2))
                                                                        AS varchar(20))
                                                                    , '.', ',')                                    
                                                END                                                     TotalAmount,
                                                CASE WHEN dlp.DeclarationID IS NOT NULL
                                                    THEN 'Scholingsbudget ' + CAST(dep.PartitionYear AS varchar(4))
                                                    ELSE 'Deelbetaling ' + CAST(dep.PartitionYear AS varchar(4))
                                                END														EventDescription,
                                                REPLACE(CAST(CAST(pad.PartitionAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        BudgetAmount,
                                                'Waardebonnen'										    VoucherDescription,
                                                REPLACE(CAST(CAST(pad.VoucherAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        VoucherAmount,
                                                dep.PartitionStatus                                     EventStatus,
                                                CASE WHEN pad.JournalEntryCode IS NOT NULL AND jec.Specification IS NOT NULL
                                                    THEN 0
                                                    ELSE CASE WHEN dsp.Specification IS NOT NULL AND dsp.Specification IS NOT NULL
                                                            THEN dsp.SpecificationSequence
                                                            ELSE 0
                                                         END
                                                END                                                     SpecificationSequence
                                        FROM	sub.tblDeclaration_Partition dep
                                        INNER JOIN sub.tblPaymentRun_Declaration pad
                                        ON		pad.PartitionID = dep.PartitionID
                                        INNER JOIN sub.tblPaymentRun par
                                        ON		par.PaymentRunID = pad.PaymentRunID
                                        LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
                                        ON      dpv.DeclarationID = dep.DeclarationID
                                        AND     dpv.PartitionID = dep.PartitionID
                                        LEFT JOIN sub.viewDeclaration_LastPartition dlp
                                        ON      dlp.LastPartition = dep.PartitionID
                                        LEFT JOIN sub.tblDeclaration_Specification dsp
                                        ON      dsp.DeclarationID = pad.DeclarationID
                                        AND     dsp.PaymentRunID = pad.PaymentRunID
                                        LEFT JOIN sub.tblJournalEntryCode jec
                                        ON      jec.JournalEntryCode = pad.JournalEntryCode
                                        WHERE	dep.DeclarationID = d.DeclarationID
                                        AND     pad.ReversalPaymentID = 0
                                        AND     par.RunDate >= '20190101'

                                        UNION ALL

                                        -- Reversed partitions.
                                        SELECT	1														EventType,
                                                'Blue'                                                  EventStyle,
                                                CAST(par.RunDate AS date)							    EventDate,
                                                ISNULL(pad.JournalEntryCode, '')                        JournalEntryCode,
                                                ISNULL(pad.PaymentRunID, '')                            PaymentRunID,
                                                REPLACE(CAST(CAST(pad.PartitionAmount + pad.VoucherAmount
                                                                  AS decimal(19,2))
                                                             AS varchar(20))
                                                        , '.', ',')                                     TotalAmount,
                                                CASE WHEN d.DeclarationStatus = '0035'
                                                       OR dlp.LastPartition IS NOT NULL
                                                    THEN 'Scholingsbudget ' + CAST(dep.PartitionYear AS varchar(4))
                                                    ELSE 'Deelbetaling ' + CAST(dep.PartitionYear AS varchar(4))
                                                END														EventDescription,
                                                REPLACE(CAST(CAST(pad.PartitionAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        BudgetAmount,
                                                'Waardebonnen'										    VoucherDescription,
                                                REPLACE(CAST(CAST(pad.VoucherAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        VoucherAmount,
                                                dep.PartitionStatus                                     EventStatus,
                                                CASE WHEN pad.JournalEntryCode IS NOT NULL AND jec.Specification IS NOT NULL
                                                    THEN 0
                                                    ELSE CASE WHEN dsp.Specification IS NOT NULL AND dsp.Specification IS NOT NULL
                                                            THEN dsp.SpecificationSequence
                                                            ELSE 0
                                                         END
                                                END                                                     SpecificationSequence
                                        FROM	sub.tblDeclaration_Partition dep
                                        INNER JOIN sub.tblPaymentRun_Declaration pad
                                        ON		pad.PartitionID = dep.PartitionID
                                        INNER JOIN sub.tblPaymentRun par
                                        ON		par.PaymentRunID = pad.PaymentRunID
                                        LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
                                        ON      dpv.DeclarationID = dep.DeclarationID
                                        AND     dpv.PartitionID = dep.PartitionID
                                        LEFT JOIN sub.tblDeclaration_Specification dsp
                                        ON      dsp.DeclarationID = pad.DeclarationID
                                        AND     dsp.PaymentRunID = pad.PaymentRunID
                                        LEFT JOIN sub.tblJournalEntryCode jec
                                        ON      jec.JournalEntryCode = pad.JournalEntryCode
                                        LEFT JOIN sub.viewDeclaration_LastPartition dlp
                                        ON      dlp.LastPartition = dep.PartitionID
                                        WHERE	dep.DeclarationID = d.DeclarationID
                                        AND     pad.ReversalPaymentID <> 0
                                        AND     par.RunDate >= '20190101'

                                        UNION ALL

                                        -- Other partitions.
                                        SELECT	1														EventType,
                                                'Grey'                                                  EventStyle,
                                                CAST(dep.PaymentDate AS date)							EventDate,
                                                ISNULL(pad.JournalEntryCode, '')                        JournalEntryCode,
                                                ISNULL(pad.PaymentRunID, '')                            PaymentRunID,
                                                REPLACE(CAST(CAST(dep.PartitionAmount + 
                                                                    ISNULL(dpv.SumDeclarationValue, 0.00)
                                                                  AS decimal(19,2))
                                                             AS varchar(20))
                                                        , '.', ',')                                     TotalAmount,
                                                CASE WHEN d.DeclarationStatus IN ('0017', '0035') 
                                                       OR dlp.LastPartition IS NOT NULL
                                                    THEN 'Scholingsbudget ' + CAST(dep.PartitionYear AS varchar(4))
                                                    ELSE 'Deelbetaling ' + CAST(dep.PartitionYear AS varchar(4))
                                                END														EventDescription,
                                                REPLACE(CAST(CAST(dep.PartitionAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        BudgetAmount,
                                                'Waardebonnen'										    VoucherDescription,
                                                REPLACE(CAST(CAST(ISNULL(dpv.SumDeclarationValue, 0.00) AS decimal(19,2)) AS varchar(20)), '.', ',')
                                                                                                        VoucherAmount,
                                                dep.PartitionStatus                                     EventStatus,
                                                0							                            SpecificationSequence
                                        FROM	sub.tblDeclaration_Partition dep
                                        LEFT JOIN sub.tblPaymentRun_Declaration pad
                                        ON		pad.PartitionID = dep.PartitionID
                                        LEFT JOIN ( SELECT  PartitionID, SUM(DeclarationValue) AS SumDeclarationValue 
                                                    FROM    sub.tblDeclaration_Partition_Voucher 
                                                    WHERE   DeclarationID = @DeclarationID 
                                                    GROUP BY 
                                                            PartitionID) dpv
                                        ON      dpv.PartitionID = dep.PartitionID
                                        LEFT JOIN sub.viewDeclaration_LastPartition dlp
                                        ON      dlp.LastPartition = dep.PartitionID
                                        WHERE	dep.DeclarationID = d.DeclarationID
                                        AND     pad.PaymentRunID IS NULL
                                        AND     dep.PaymentDate >= '20190101'

									) AS sub
							ORDER BY 
									sub.EventDate,
									sub.EventType
							FOR XML PATH('Event'), ROOT('TimeTable')
					-- 	)
					-- ELSE
					-- 	(
					-- 		SELECT NULL
					-- 		FOR XML PATH('Partitions')
					-- 	)
					-- END
				    )																					TimeTable,
					CAST(CASE WHEN pad.PaymentRunID <= 
									(
										SELECT	SettingCode
										FROM	sub.tblApplicationSetting
										WHERE	SettingName = 'LastPaymentRunWithDeclarationSpecification'
									)
                            THEN CASE WHEN ( SELECT	MIN(CAST(dsp.Specification AS varchar(MAX)))	-- Specifications are created but non is filled with specificationdata
                                             FROM	sub.tblDeclaration_Specification dsp			-- OTIBSUB-813 Horus specificaties niet downloaden/tonen
                                             WHERE	dsp.DeclarationID = d.DeclarationID) IS NULL	
                                    THEN 0
                                    ELSE CASE WHEN @OTIB_User = 1
                                            THEN 1
                                            ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0017') 
                                                    THEN 1 
                                                    ELSE 0 
                                                 END
                                         END
                                 END
							ELSE
								CASE WHEN pad.DeclarationID IS NOT NULL 
                                    THEN 1
                                    ELSE 0
								END
							END AS bit)																	CanDownloadSpecification,
					CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0 
                               AND @ActivePartitionStatus <> '0016'
							THEN 0
							ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0016') 
									THEN 1 
									ELSE 0 
								 END
						 END AS bit)																	CanReverse,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009', '0022') 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanSetToInvestigation,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanAccept,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanReject,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022')
							   AND dtp.DeclarationID IS NULL  
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanReturnToEmployer,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')
							THEN 1 
							ELSE 0 
						 END AS bit)																	GetRejectionReason,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0012', '0013', '0014', '0015')
							THEN 1 
							ELSE 0 
						 END AS bit)																	ShowStatusReason,
					rev.ReversalPaymentReason															ReversalPaymentReason,
					CASE WHEN d.StartDate > CAST(GETDATE() AS date) 
                          AND @ActivePartitionStatus = '0001' 
						THEN d.StartDate 
						ELSE NULL 
					END																					ModifyUntil
			FROM	osr.viewDeclaration d
			INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
			INNER JOIN sub.tblEmployer e ON	e.EmployerNumber = d.EmployerNumber
			INNER JOIN  sub.viewDeclaration_Institute di ON	di.DeclarationID = d.DeclarationID
			LEFT JOIN  sub.viewDeclaration_TotalVoucherAmount dtva ON dtva.DeclarationID = d.DeclarationID
			LEFT JOIN  sub.tblPaymentRun_Declaration pad ON	pad.DeclarationID = d.DeclarationID
			LEFT JOIN  sub.tblDeclaration_Unknown_Source dus ON	dus.DeclarationID = d.DeclarationID
			LEFT JOIN  sub.tblDeclaration_ReversalPayment rev ON rev.ReversalPaymentID = @MaxReversalPaymentID
			LEFT JOIN  sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
			WHERE	d.DeclarationID = @DeclarationID
		) sel
ORDER BY 
		sel.CanDownloadSpecification DESC

-- Result set 2: All linked employees.
SELECT	emp.EmployeeNumber, 
		emp.FullName AS EmployeeName,
		der.ReversalPaymentID,
		'Meegenomen in de betalingsrun van ' + CONVERT(varchar(10), par.RunDate, 105) AS PaymentRun
FROM sub.tblDeclaration_Employee dee
INNER JOIN sub.tblEmployee emp 
ON      emp.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der 
ON	    der.DeclarationID = dee.DeclarationID
AND	    der.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN sub.tblDeclaration_ReversalPayment drp 
ON	    drp.DeclarationID = der.DeclarationID
AND	    drp.ReversalPaymentID = der.ReversalPaymentID
LEFT JOIN sub.tblDeclaration_Partition_ReversalPayment dprp 
ON	    dprp.PartitionID = der.PartitionID
AND	    dprp.ReversalPaymentID = der.ReversalPaymentID
LEFT JOIN sub.tblPaymentRun par 
ON	    par.PaymentRunID = drp.PaymentRunID
WHERE	dee.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_Get_WithEmployeeData ===============================================	*/
