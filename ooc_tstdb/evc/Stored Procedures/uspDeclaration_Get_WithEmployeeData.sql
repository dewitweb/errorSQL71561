
CREATE PROCEDURE [evc].[uspDeclaration_Get_WithEmployeeData]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get declaration information with linked employees on bases of a DeclarationID.
	
	08-11-2019	Jaap van Assenebrgh		OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	25-10-2019	Jaap van Assenebrgh		OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	09-09-2019	Jaap van Assenbergh		OTIBSUB-1548	Retour werkgever mag alleen als er nog geen betaling is geweest
	16-07-2019	Jaap van Assenbergh		OTIBSUB-1373	Specificatie op declaratieniveau of 
											op verzamelnota.
	10-05-2019	Jaap van Assenbergh		OTIBSUB-1068	Originele invoer door werkgever 
											van nieuw instituut en/of opleiding altijd tonen.
	06-05-2019	Jaap van Assenbergh		OTIBSUB-1030	Declaratie terugsturen naar werkgever 
														(retour werkgever)
	26-04-2019	Sander van Houten		OTIBSUB-943		Add options for declarations with status
											Question asked.
	19-04-2019	Sander van Houten		OTIBSUB-990		Declaration double reversal.
	04-04-2019	Jaap van Assenbergh		OTIBSUB-918		JournalEntryCode toegevoegd.
	26-02-2019	Sander van Houten		OTIBSUB-806		Afgekeurde declaraties moeten 
											In onderzoek gezet kunnen worden.
	21-02-2019	Sander van Houten		OTIBSUB-792		Manier van vastlegging terugboeking 
											bij werknemer veranderen.
	31-01-2019	Jaap van Assenbergh		OTIBSUB-662		CanSetToInvestigation en CanAcceptOrReject.
	25-01-2019	Jaap van Assenbergh		OTIBSUB-715		ModifyUntil toegevoegd.
	17-01-2019	Sander van Houten		OTIBSUB-678		Show CanDownloadSpecification 
											on bases of RoleID.
	13-12-2018	Sander van Houten		OTIBSUB-576		Foutief uitbetaald bedrag in 
											OTIB declaratie overzicht.										
	30-11-2018	Jaap van Assenbergh		OTIBSUB-462		Toevoegen term EVC/EVC500 bij afhandelen 
											declaraties.
	02-11-2018	Sander van Houten		OTIBSUB-382		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Max of ReversalPaymentID.
DECLARE	@MaxReversalPaymentID	int
DECLARE	@ActivePartitionStatus	varchar(4)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		-- OTIBSUB_1539

SELECT	@MaxReversalPaymentID = ReversalPaymentID
FROM	sub.tblDeclaration_ReversalPayment
WHERE	DeclarationID = @DeclarationID
AND		PaymentRunID IS NULL

-- Determine Role(s) of current user.
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

-- Result set 1.
SELECT
		DeclarationID,
		DeclarationNumber,
		JournalEntryCode,
		EmployerNumber,
		EmployerName,
		IBAN,
		SubsidySchemeID,
		SubsidySchemeName,
		DeclarationDate,
		InstituteID,
		InstituteName,
		DeclarationStatus,
		IntakeDate,
		CertificationDate,
		DeclarationAmount,
		ApprovedAmount,
		StatusReason,
		InternalMemo,
		MentorCode,
		QualificationLevel,
		CanDownloadSpecification,
		CanReverse,
		CanSetToInvestigation,
		CanAccept,
		CanReject,
		CanReturnToEmployer,
		GetRejectionReason,
		ShowStatusReason,
		ReversalPaymentReason,
		CAST(	CASE	WHEN ModifyUntil IS NOT NULL 
							OR @ActivePartitionStatus = '0019'										-- OTIBSUB_1539
						THEN 1 
						ELSE 0 
				END 
				as bit) CanModify,
		ModifyUntil
FROM
		(
			SELECT
					d.DeclarationID,
					CAST(d.DeclarationID AS varchar(6))													DeclarationNumber,
					pad.JournalEntryCode,
					d.EmployerNumber,
					e.EmployerName,
					e.IBAN,
					d.SubsidySchemeID,
					s.SubsidySchemeName +
						CASE WHEN d.IsEVC500 = 1 
								THEN '-500' 
								ELSE ''
								END SubsidySchemeName,
					d.DeclarationDate,
					d.InstituteID,
					di.InstituteName																	InstituteName,
					d.DeclarationStatus,
					d.IntakeDate,
					d.CertificationDate,
					d.DeclarationAmount,
					ISNULL(dtp.TotalPaidAmount, 0.00)													ApprovedAmount,
					d.StatusReason,
					d.InternalMemo,
					d.MentorCode,
					d.QualificationLevel,
					CAST(CASE	WHEN pad.PaymentRunID <= 
									(
										SELECT	SettingCode
										FROM	sub.tblApplicationSetting
										WHERE	SettingName = 'LastPaymentRunWithDeclarationSpecification'
									)
								THEN
									CASE WHEN dsp.Specification IS NULL					-- Specification is created but not filled with specificationdata 
																								-- OTIBSUB-813 Horus specificaties niet downloaden/tonen
											THEN 0
											ELSE CASE WHEN @OTIB_User = 1
													THEN 1
													ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0013', '0014', '0015', '0017') -- OTIBSUB_1539
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
						END	AS bit)																CanDownloadSpecification,
					CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0
							THEN 0
							ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0013', '0014', '0015')	-- OTIBSUB_1539 
									THEN 1 
									ELSE 0 
								 END
						 END AS bit)																	CanReverse,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009') 			-- OTIBSUB_1539
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanSetToInvestigation,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')					-- OTIBSUB_1539 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanAccept,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')					-- OTIBSUB_1539 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanReject,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022')	-- OTIBSUB_1539
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
					CASE WHEN IntakeDate > CAST(GETDATE() AS date) AND DeclarationStatus = '0001'		-- OTIBSUB_1539 Blijft DeclaratieStatus
						THEN IntakeDate 
						ELSE NULL 
					END																					ModifyUntil
			FROM	evc.viewDeclaration d
			INNER JOIN	sub.tblSubsidyScheme s 
					ON	s.SubsidySchemeID = d.SubsidySchemeID
			INNER JOIN	sub.tblEmployer e 
					ON	e.EmployerNumber = d.EmployerNumber
			INNER JOIN  sub.viewDeclaration_Institute di 
					ON	di.DeclarationID = d.DeclarationID
			LEFT JOIN	sub.tblDeclaration_Unknown_Source dus 
					ON	dus.DeclarationID = d.DeclarationID
			LEFT JOIN	sub.tblDeclaration_ReversalPayment rev 
					ON	rev.ReversalPaymentID = @MaxReversalPaymentID
			LEFT JOIN	sub.tblPaymentRun_Declaration pad 
					ON	pad.DeclarationID = d.DeclarationID
			LEFT JOIN	sub.tblDeclaration_Specification dsp 
					ON	dsp.DeclarationID = d.DeclarationID
			LEFT JOIN	sub.viewDeclaration_TotalPaidAmount dtp 
					ON	dtp.DeclarationID = d.DeclarationID
			WHERE	d.DeclarationID = @DeclarationID
		) sel

-- Result set 2; All linked employees
SELECT	emp.EmployeeNumber, 
		emp.FullName AS EmployeeName,
		der.ReversalPaymentID,
		'Meegenomen in de betalingsrun van ' + CONVERT(varchar(10), par.RunDate, 105) AS PaymentRun
FROM sub.tblDeclaration_Employee dee
INNER JOIN	sub.tblEmployee emp 
		ON	emp.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN	sub.tblDeclaration_Employee_ReversalPayment der 
		ON	der.DeclarationID = dee.DeclarationID
		AND	der.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN	sub.tblDeclaration_ReversalPayment drp 
		ON	drp.DeclarationID = der.DeclarationID
		AND	drp.ReversalPaymentID = der.ReversalPaymentID
LEFT JOIN	sub.tblDeclaration_Partition_ReversalPayment dprp 
		ON	dprp.ReversalPaymentID = der.ReversalPaymentID
		AND	dprp.PartitionID = der.PartitionID
LEFT JOIN	sub.tblPaymentRun par 
		ON	par.PaymentRunID = drp.PaymentRunID
WHERE	dee.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evc.uspDeclaration_Get_WithEmployeeData ===============================================	*/
