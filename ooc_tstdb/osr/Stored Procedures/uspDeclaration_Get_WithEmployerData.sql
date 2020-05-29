
CREATE PROCEDURE [osr].[uspDeclaration_Get_WithEmployerData]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	LET OP:		Deze usp wordt ook aangeroepen in uspDeclaration_Specification_Upd.
				Indien nieuwe velden in de result set dan ook de tabelvariabele aanpassen in 
				uspDeclaration_Specification_Upd!

	Purpose:	Get declaration information on bases of a DeclarationID.
	Note		11-10-2018	Jaap van Assenbergh
				The procedure is also executed by other procedures. Adding columns must also 
				be done in the table variables in the other procedures.

	09-09-2019	Jaap van Assenbergh	OTIBSUB-1710	Ophalen redenen van uitval in de back-end 
													signaleren
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	09-09-2019	Jaap van Assenbergh	OTIBSUB-1548	Retour werkgever mag alleen als 
													er nog geen betaling is geweest
	05-08-2019	Sander van Houten	OTIBSUB-1129	Removed CanDownloadSpecification field
													for performance.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	Specificatie op declaratieniveau of 
													op verzamelnota.
	24-05-2019	Jaap van Assenbergh	OTIBSUB-1078	Routing tussen DS en Etalage wijzigen
	07-05-2019	Sander van Houten	OTIBSUB-1046	Move vouchers to partition level.
	06-05-2019	Jaap van Assenbergh	OTIBSUB-1030	Declaratie terugsturen naar werkgever 
													(retour werkgever)
	26-04-2019	Sander van Houten	OTIBSUB-943		Add options for declarations with status
													Question asked.
	24-04-2019	Jaap van Assenbergh	OTIBSUB-1013	Performance verbetering Betalingsrun
	19-04-2019	Sander van Houten	OTIBSUB-990		Declaration double reversal.
	15-04-2019	Sander van Houten	OTIBSUB-933		Bij 'Uitbetaling' géén bedrag tonen 
										indien declaratie in onderzoek of afgekeurd door 
										automatische controle.
	03-04-2019	Sander van Houten	OTIBSUB-851		Recalculate PartitionAmountCorrected.
	19-03-2019	Sander van Houten	OTIBSUB-848		DeclarationAmount and PaidAmount show 0,00.
	26-02-2019	Sander van Houten	OTIBSUB-806		Afgekeurde declaraties moeten 
										In onderzoek gezet kunnen worden.
	31-01-2019	Jaap van Assenbergh	OTIBSUB-662		CanSetToInvestigation en CanAcceptOrReject.
	17-01-2019	Sander van Houten	OTIBSUB-678		Show CanDownloadSpecification 
										on bases of RoleID.
	19-11-2018	Sander van Houten	OTIBSUB-453		Added conditional fill of StatusReason.
	10-10-2018	Jaap van Assenbergh	OTIBSUB-321/323 Added CanDownloadSpecification and CanReverse.
	24-09-2018	Sander van Houten	OTIBSUB-295		Was uspDeclaration_Get.
	10-09-2018	Jaap van Assenbergh	InstituteNameCount and CourseNamePrice.
	19-07-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 406102,
        @UserID			int = 1
--  */

/* Determine Role(s) of current user.   */
DECLARE @OTIB_User          bit = 0,
        @SubsidySchemeID    int,
        @EmployerNumber     varchar(6)

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

SELECT	@SubsidySchemeID = SubsidySchemeID, 
        @EmployerNumber = EmployerNumber
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

/* Get status of active partition (OTIBSUB-1539).   */
DECLARE	@ActivePartitionStatus	varchar(4)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		

/*	Select Declaration data.	*/
;WITH cteEmployerBalance AS
(
SELECT	DISTINCT
		ems.SubsidySchemeID,
		ems.EmployerNumber,
		ems.SubsidyYear,
		CASE WHEN ems.Amount - ISNULL(sub1.TotalApprovedAmount, 0.00) < 0
			THEN 0.00
			ELSE ems.Amount - ISNULL(sub1.TotalApprovedAmount, 0.00)
		END		AS BalanceAmount
FROM	sub.tblEmployer_Subsidy ems 
LEFT JOIN (
				SELECT	decl.SubsidySchemeID,
						decl.EmployerNumber,
						dep.PartitionYear,
						SUM(ISNULL(dep.PartitionAmountCorrected, 0.00))	AS TotalApprovedAmount
				FROM	sub.tblDeclaration decl 
				LEFT JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
				WHERE	dep.PartitionStatus IN ('0009', '0010', '0012', '0014')
				GROUP BY 
						decl.SubsidySchemeID,
						decl.EmployerNumber,
						dep.PartitionYear
			) sub1
	ON		sub1.SubsidySchemeID = ems.SubsidySchemeID
	AND		sub1.EmployerNumber = ems.EmployerNumber
	AND		sub1.PartitionYear = ems.SubsidyYear
WHERE	ems.SubsidySchemeID = @SubsidySchemeID
AND		ems.EmployerNumber = @EmployerNumber
),
cteVoucherAmount AS
(
	SELECT	DeclarationID,
			PartitionID,
			SUM(ISNULL(DeclarationValue, 0))	AS TotalVoucherAmount
	FROM	sub.tblDeclaration_Partition_Voucher
	WHERE	DeclarationID = @DeclarationID
	GROUP BY 
			DeclarationID,
			PartitionID
)
SELECT	DISTINCT
		d.DeclarationID,
		REPLICATE('0', 6 - LEN(d.DeclarationID)) + CAST(d.DeclarationID AS varchar(6))		DeclarationNumber,
		d.EmployerNumber,
		e.EmployerName,
		e.IBAN,
		d.SubsidySchemeID,
		s.SubsidySchemeName,
		d.DeclarationDate,
		d.InstituteID,
		d.CourseID,
		d.CourseName																		CourseName,
		d.DeclarationStatus,
		d.[Location],
		d.ElearningSubscription,
		d.StartDate,
		d.EndDate,
		CAST(d.DeclarationAmount AS decimal(19,2))											DeclarationAmount,
		CAST(ISNULL(d.ApprovedAmount, 0) AS decimal(19,2))									ApprovedAmount,
		CASE DeclarationStatus 
			WHEN '0008' THEN i.InvestigationMemo
			ELSE d.StatusReason
		END																					StatusReason,
		d.InternalMemo,
		(
			SELECT 
					sub1.PartitionYear,
					sub1.SubsidyAmount,
					sub1.PartitionAmount,
					CASE sub1.PartitionStatus
						WHEN '0005' THEN NULL
						WHEN '0007' THEN NULL
						WHEN '0008' THEN NULL
						ELSE sub1.PartitionAmountCorrected
					END	AS PartitionAmountCorrected
			FROM	(
						SELECT	
								dep.PartitionID,
								dep.PartitionYear,
								dep.PartitionStatus,
								eba.BalanceAmount															SubsidyAmount,
								CAST(dep.PartitionAmount + 
									 ISNULL(vam.TotalVoucherAmount, 0.00) AS decimal(19,2))					PartitionAmount,
								CAST(CASE dep.PartitionStatus
										WHEN '0005' THEN 0.00
										WHEN '0007' THEN 0.00
										WHEN '0008' THEN 0.00
										ELSE dep.PartitionAmountCorrected + ISNULL(vam.TotalVoucherAmount, 0.00)
									 END	AS decimal(19,2))												PartitionAmountCorrected,
								CAST(dep.PartitionAmountCorrected + 
									 ISNULL(vam.TotalVoucherAmount, 0.00) AS decimal(19,2))					PartitionAmountCorrectedWhenAccepted,
								ISNULL(vam.TotalVoucherAmount, 0.00)										TotalVoucherAmount
						FROM	sub.tblDeclaration_Partition dep
						LEFT JOIN cteEmployerBalance eba ON	eba.SubsidyYear = dep.PartitionYear
						LEFT JOIN cteVoucherAmount vam ON vam.DeclarationID = dep.DeclarationID 
													  AND vam.PartitionID = dep.PartitionID
						WHERE	dep.DeclarationID = d.DeclarationID
				) AS sub1
			FOR XML PATH('Partition'), ROOT('Partitions')
		)																					[Partitions],
		CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0 
                   AND @ActivePartitionStatus <> '0016'
				THEN 0
				ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0016')
						THEN 1 
						ELSE 0 
					 END
			 END AS bit)																					CanReverse,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009', '0022')
				THEN 1 
				ELSE 0 
			 END AS bit)																					CanSetToInvestigation,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')
				THEN 1
				ELSE 0
			 END AS bit)																					CanAccept,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')
				THEN 1 
				ELSE 0 
			 END AS bit)																					CanReject,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022')
				   AND dtp.DeclarationID IS NULL  
				THEN 1 
				ELSE 0 
			 END AS bit)																					CanReturnToEmployer,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')
				THEN 1 
				ELSE 0 
			 END AS bit)																					GetRejectionReason

FROM	osr.viewDeclaration d
INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
INNER JOIN sub.tblEmployer e ON e.EmployerNumber = d.EmployerNumber
LEFT JOIN sub.tblCourse c ON c.CourseID = d.CourseID
LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
LEFT JOIN (	SELECT DeclarationID, MAX(InvestigationDate) AS MaxInvestigationDate 
			FROM sub.tblDeclaration_Investigation
			GROUP BY DeclarationID
		  ) iMax ON iMax.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Investigation i ON i.DeclarationID = iMax.DeclarationID 
											AND i.InvestigationDate = iMax.MaxInvestigationDate
LEFT JOIN sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Specification dsp ON dsp.DeclarationID = d.DeclarationID
LEFT JOIN sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_Get_WithEmployerData ===============================================	*/
