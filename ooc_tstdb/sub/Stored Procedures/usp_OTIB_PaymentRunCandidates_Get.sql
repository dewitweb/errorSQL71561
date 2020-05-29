
CREATE PROCEDURE [sub].[usp_OTIB_PaymentRunCandidates_Get]
@SubsidySchemeID	int,
@EndDate			date
AS
/*	==========================================================================================
	Purpose:	Get all approved declarations which have not been paid yet.

	07-02-2020	Sander van Houten	OTIBSUB-1890	Included payments with status 0021.

	07-01-2020	Sander van Houten	OTIBSUB-1814	Exclude employers with a paymentarrear.
	12-11-2019	Jaap van Assenbergh	OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	14-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	25-09-2019	Sander van Houten	OTIBSUB-1591	In case of an E-learning declaration
										an employee record is not mandatory.
										When there is no employee record and a declaration 
										is reversed, the whole amount will be reversed.
	06-08-2019	Sander van Houten	OTIBSUB-1442	Only select STIP diploma payments where 
										the diploma has been checked.
	24-06-2019	Sander van Houten	OTIBSUB-1251	Distinguish Diploma and Normal payments.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
 	16-04-2019	Sander van Houten	OTIBSUB-971		Split up paymentrun, e-mail sending 
										and export to Exact.
    24-10-2018	Jaap van Assenbergh	OTIBSUB-290		Exclude employers with actual paymentstop.
	10-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@SubsidySchemeID	int = 1,
		@EndDate			date = '20200207'
--	*/

/*  Insert @SubsidySchemeID into a table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID
INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*  Get partitions to be paid or reversed.   */
-- Normal payments and reversals.
;WITH cte_Reversal AS
	(
		SELECT	d.DeclarationID, 
				dp.PartitionID,
				COUNT(DISTINCT dem.EmployeeNumber)		AS NrOfEmployees,
				CASE @SubsidySchemeID
					WHEN 1 THEN COUNT(DISTINCT der.EmployeeNumber) 
					ELSE COUNT(DISTINCT dem.EmployeeNumber)
				END										AS NrOfReversals,
				SUM(ISNULL(dpv.DeclarationValue, 0))	AS TotalVoucherAmount
		FROM	sub.tblDeclaration d
		INNER JOIN sub.tblDeclaration_Partition dp
				ON	dp.DeclarationID = d.DeclarationID 
		INNER JOIN sub.tblDeclaration_ReversalPayment drp
				ON	drp.DeclarationID = dp.DeclarationID
		INNER JOIN sub.tblDeclaration_Partition_ReversalPayment dprp
				ON	dprp.ReversalPaymentID = drp.ReversalPaymentID
				AND dprp.PartitionID = dp.PartitionID
		LEFT JOIN sub.tblDeclaration_Employee dem
				ON	dem.DeclarationID = d.DeclarationID
		INNER JOIN sub.tblDeclaration_Employee_ReversalPayment der
				ON	der.PartitionID = dprp.PartitionID
				AND	der.ReversalPaymentID = dprp.ReversalPaymentID
		LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
				ON	dpv.DeclarationID = der.DeclarationID
				AND	dpv.PartitionID = der.PartitionID
				AND	dpv.EmployeeNumber = der.EmployeeNumber
		WHERE	d.SubsidySchemeID IN 
                (
                    SELECT	SubsidySchemeID 
                    FROM	@tblSubsidyScheme
                )
		  AND	dp.PartitionStatus = '0016'
		  AND	dp.PaymentDate <= @EndDate
		  AND	drp.PaymentRunID IS NULL
          AND   d.SubsidySchemeID <> 4
		GROUP BY
				d.DeclarationID,
				dp.PartitionID
	)
SELECT
		d.DeclarationID,
		CAST(d.DeclarationID AS varchar(6))												DeclarationNumber,
		d.EmployerNumber,
		e.EmployerName + ' (' + d.EmployerNumber + ')'									EmployerName,
		e.IBAN,
		d.SubsidySchemeID,
		s.SubsidySchemeName,
		d.DeclarationDate,
		d.InstituteID,
		COALESCE(osrd.CourseID, stpd.EducationID)										CourseID,
		COALESCE(osrd.CourseName, stpd.EducationName)									CourseName,
		dep.PartitionStatus                                                             DeclarationStatus,
		CAST(dep.PaymentDate AS date)													ReferenceDate,
		CASE WHEN stpd.TerminationReason = '0006'	
			AND	dep.PaymentDate = stpd.DiplomaDate
			THEN '0001'
			ELSE '0000'
		END																				PaymentType,
		osrd.[Location],
		osrd.ElearningSubscription,
		d.StartDate,
		d.EndDate,
		d.DeclarationAmount																DeclarationAmount,
		CASE WHEN ISNULL(drp.ReversalPaymentID, 0) = 0
			THEN dep.PartitionAmountCorrected + ISNULL(dpv.TotalVoucherAmount, 0)
			ELSE CASE WHEN rev.NrOfEmployees IS NULL
					THEN (dep.PartitionAmountCorrected + ISNULL(dpv.TotalVoucherAmount, 0)) * -1
					ELSE (((dep.PartitionAmountCorrected / rev.NrOfEmployees) * rev.NrOfReversals)
							+ ISNULL(rev.TotalVoucherAmount, 0)) * -1
				 END
		END																				ApprovedAmount,
		d.StatusReason,
		d.InternalMemo,
		0																				IsRejected,
		CASE WHEN dep.PaymentDate = stpd.DiplomaDate
			THEN CAST(1 AS bit)
			ELSE CAST(0 AS bit)
		END																				IsDiplomaDate,
        pa.FeesPaidUntill
FROM	sub.tblDeclaration d
INNER JOIN	sub.tblSubsidyScheme s
		ON	s.SubsidySchemeID = d.SubsidySchemeID
INNER JOIN	sub.tblEmployer e
		ON	e.EmployerNumber = d.EmployerNumber
INNER JOIN	sub.tblDeclaration_Partition dep 
		ON	dep.DeclarationID = d.DeclarationID
LEFT JOIN	sub.tblEmployer_PaymentStop eps
		ON	eps.EmployerNumber = d.EmployerNumber
		AND	eps.StartDate <= @EndDate
		AND	COALESCE(eps.EndDate, @EndDate) >= @EndDate
		AND	eps.PaymentstopType = '0001'
LEFT JOIN   sub.tblPaymentArrear pa
        ON  pa.EmployerNumber = d.EmployerNumber
        AND	DATEDIFF(DAY, pa.FeesPaidUntill, GETDATE()) > 30
LEFT JOIN	osr.viewDeclaration osrd 
		ON	osrd.DeclarationID = d.DeclarationID
LEFT JOIN	sub.viewDeclaration_Partition_TotalVoucherAmount dpv
		ON	dpv.DeclarationID = d.DeclarationID
		AND	dpv.PartitionID =  dep.PartitionID
LEFT JOIN	sub.tblDeclaration_ReversalPayment drp
		ON	drp.DeclarationID = d.DeclarationID
		AND	drp.PaymentRunID IS NULL
LEFT JOIN	sub.tblDeclaration_Partition_ReversalPayment dprp
		ON	dprp.PartitionID = dep.PartitionID
		AND	dprp.ReversalPaymentID = drp.ReversalPaymentID
LEFT JOIN	cte_Reversal rev
		ON	rev.PartitionID = dep.PartitionID
LEFT JOIN	stip.viewDeclaration stpd 
		ON	stpd.DeclarationID = d.DeclarationID
WHERE	d.SubsidySchemeID IN 
                            (
                                SELECT	SubsidySchemeID 
                                FROM	@tblSubsidyScheme
                            )
AND		eps.PaymentStopID IS NULL
AND     (   pa.FeesPaidUntill IS NULL
        OR  (   pa.FeesPaidUntill IS NOT NULL
            AND ISNULL(drp.ReversalPaymentID, 0) <> 0
            )
        )
AND		dep.PartitionStatus IN ('0009', '0016', '0021')
AND		dep.PaymentDate <= @EndDate
--AND		(	d.SubsidySchemeID <> 4
--	OR		(	d.SubsidySchemeID = 4
--		AND		(	COALESCE(stpd.DiplomaDate, '19000101') <> dep.PaymentDate
--				OR	(	stpd.DiplomaDate = dep.PaymentDate
--					AND	stpd.DiplomaCheckedByUserID IS NOT NULL
--					)
--				)
--			)
--		)
AND     d.SubsidySchemeID <> 4



UNION 

-- Rejected payments.
SELECT
		d.DeclarationID,
		CAST(d.DeclarationID AS varchar(6))												DeclarationNumber,
		d.EmployerNumber,
		e.EmployerName + ' (' + d.EmployerNumber + ')'									EmployerName,
		e.IBAN,
		d.SubsidySchemeID,
		s.SubsidySchemeName,
		d.DeclarationDate,
		d.InstituteID,
		COALESCE(osrd.CourseID, stpd.EducationID)										CourseID,
		COALESCE(osrd.CourseName, stpd.EducationName)									CourseName,
		dep.PartitionStatus                                                             DeclarationStatus,
		CAST(dep.PaymentDate AS date)													ReferenceDate,
		CASE WHEN stpd.TerminationReason = '0006'	
			AND	dep.PaymentDate = stpd.DiplomaDate
			THEN '0001'
			ELSE '0000'
		END																				PaymentType,
		osrd.[Location],
		osrd.ElearningSubscription,
		d.StartDate,
		d.EndDate,
		dep.PartitionAmount																DeclarationAmount,
		0.00																			ApprovedAmount,
		d.StatusReason,
		d.InternalMemo,
		1																				IsRejected,
		CASE WHEN dep.PaymentDate = stpd.DiplomaDate
			THEN CAST(1 AS bit)
			ELSE CAST(0 AS bit)
		END																				IsDiplomaDate,
        NULL AS FeesPaidUntill
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep
ON		dep.DeclarationID = d.DeclarationID
INNER JOIN sub.tblEmployer e
ON		e.EmployerNumber = d.EmployerNumber
INNER JOIN sub.tblSubsidyScheme s 
ON		s.SubsidySchemeID = d.SubsidySchemeID
LEFT JOIN osr.viewDeclaration osrd 
ON		osrd.DeclarationID = d.DeclarationID
LEFT JOIN stip.viewDeclaration stpd 
ON		stpd.DeclarationID = d.DeclarationID
WHERE	d.SubsidySchemeID IN 
                            (
                                SELECT	SubsidySchemeID 
                                FROM	@tblSubsidyScheme
							)
AND		dep.PaymentDate <= @EndDate
AND		dep.PartitionStatus = '0007'
AND     d.SubsidySchemeID <> 4
ORDER BY 
		d.DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_PaymentRunCandidates_=====================================================	*/
