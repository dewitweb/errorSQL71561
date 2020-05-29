CREATE PROCEDURE [sub].[uspDeclaration_Specification_Upd]
@DeclarationID			int,
@SpecificationSequence	int,
@PaymentRunID			int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update sub.tblDeclaration_Specification on basis of DeclarationID.

	15-11-2019	Jaap van Assenebrgh	OTIBSUB-1710	Ophalen redenen van uitval in de back-end signaleren
	25-10-2019	Jaap van Assenebrgh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	27-06-2019	Jaap van Assenbergh	OTIBSUB-1267	Notaspecificatie bij e-learning
	14-06-2019	Sander van Houten	OTIBSUB-1186	Postal-address favours Business-address.
	10-05-2019	Jaap van Assenbergh	OTIBSUB-1068	Originele invoer door werkgever van 
													nieuw instituut en/of opleiding altijd tonen.
	07-05-2019	Sander van Houten	OTIBSUB-1046	Move vouchers to partition level.
	06-05-2019	Jaap van Assenbergh	OTIBSUB-1030	Declaratie terugsturen naar werkgever 
													(retour werkgever).
	25-04-2019	Sander van Houten	OTIBSUB-1024	After regeneration of specification the
													paid amount on the specification is €0,00.
	24-04-2019	Sander van Houten	OTIBSUB-1017	No employee on declaration gives
													"Divide by zero" error (E-learning). 
	16-04-2019	Sander van Houten	OTIBSUB-965		Do not show specification 
													for rejected declarations. 
	15-04-2019	Sander van Houten	OTIBSUB-963		Ten onrechte bedrag waardebonnen getoond 
													in 'Totaal vergoed' bij afgekeurde declaraties.
	12-04-2019	Jaap van Assenbergh	OTIBSUB-954		Alleen [Vergoed bedrag] 2019 tonen.	
	05-03-2019	Jaap van Assenbergh	OTIBSUB-816		Uitbreiden output met bedrag aan waardebonnen.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
													bij werknemer veranderen.
	31-01-2019	Jaap van Assenbergh	OTIBSUB-662		CanSetToInvestigation en CanAcceptOrReject .
	29-01-2019	Sander van Houten	OTIBSUB-729		Do not show RejectionReason 
													if DeclarationStatus is not 0007 or 0017 .
	29-01-2019	Sander van Houten	OTIBSUB-728		Added CollectiveBalance to XML.
	17-01-2019	Sander van Houten	OTIBSUB-678		Show CanDownloadSpecification 
													on bases of RoleID.
	12-12-2018	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

/*	Testdata
DECLARE	@DeclarationID			int = 401409,
		@SpecificationSequence	int = 1,
		@PaymentRunID			int = 60008,
		@CurrentUserID			int = 1
--*/

DECLARE @Return					int = 1,
		@SpecificationDate		datetime,
		@Specification			xml = NULL,
		@IsNew					bit = 0,
		@SubsidySchemeID		int,
		@UserInitials			varchar(3),
		@DefaultUserInitials	varchar(3) = 'DRO',
		@SumPartitionAmount		decimal(19,4),
		@SumVoucherAmount		decimal(19,4),
		@AmountPerEmployee		decimal(19,4),
		@DeclarationStatus		varchar(4),
		@MaxPartitionYear		smallint

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/*	Get sequence by new specification	*/ 
IF ISNULL(@SpecificationSequence, 0) = 0
BEGIN
	SELECT	@SpecificationSequence = ISNULL(MAX(SpecificationSequence), 0) + 1
	FROM	sub.tblDeclaration_Specification
	WHERE	DeclarationID = @DeclarationID

	SET @IsNew = 1
END

DECLARE @DeclarationEmployeeCount	int,
		@ReversalEmployeeCount		int,
		@JournalEntryCode			int

SELECT	@SubsidySchemeID = SubsidySchemeID
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

SELECT	@DeclarationEmployeeCount = COUNT(EmployeeNumber) 
FROM	sub.tblDeclaration_Employee
WHERE	DeclarationID = @DeclarationID

SET		@DeclarationEmployeeCount = CASE WHEN ISNULL(@DeclarationEmployeeCount, 0) = 0 
										THEN 1 
										ELSE @DeclarationEmployeeCount
									END

IF @SubsidySchemeID = 1
BEGIN
	SELECT	@ReversalEmployeeCount = COUNT(DISTINCT der.EmployeeNumber)
	FROM	sub.tblDeclaration d 
	INNER JOIN sub.tblDeclaration_Partition dp
		ON	dp.DeclarationID = d.DeclarationID 
	INNER JOIN sub.tblPaymentRun_Declaration pd
		ON	pd.PartitionID = dp.PartitionID
	INNER JOIN sub.tblDeclaration_Employee_ReversalPayment der
		ON	der.DeclarationID = d.DeclarationID
		AND	der.ReversalPaymentID = pd.ReversalPaymentID
	WHERE	d.DeclarationID = @DeclarationID
	AND		dp.PartitionStatus NOT IN ('0007', '0017')
	AND		pd.PaymentRunID = @PaymentRunID
	AND		pd.ReversalPaymentID <> 0
END
ELSE
BEGIN
	SELECT	@ReversalEmployeeCount = @DeclarationEmployeeCount
	FROM	sub.tblDeclaration d 
	INNER JOIN sub.tblDeclaration_Partition dp
		ON	dp.DeclarationID = d.DeclarationID 
	INNER JOIN sub.tblPaymentRun_Declaration pd
		ON	pd.PartitionID = dp.PartitionID
	INNER JOIN sub.tblDeclaration_Employee_ReversalPayment der
		ON	der.DeclarationID = d.DeclarationID
		AND	der.ReversalPaymentID = pd.ReversalPaymentID
	WHERE	d.DeclarationID = @DeclarationID
	AND		dp.PartitionStatus NOT IN ('0007', '0017')
	AND		pd.PaymentRunID = @PaymentRunID
	AND		pd.ReversalPaymentID <> 0
END

SELECT	@SumPartitionAmount = ISNULL(CASE WHEN ISNULL(@ReversalEmployeeCount, 0) = 0 
											THEN SUM(dp.PartitionAmountCorrected)
											ELSE SUM(((dp.PartitionAmountCorrected * -1) 
														/ @DeclarationEmployeeCount
													 ) 
														* @ReversalEmployeeCount
													)
									 END, 0)
FROM	sub.tblDeclaration d 
INNER JOIN sub.tblDeclaration_Partition dp
	ON	dp.DeclarationID = d.DeclarationID 
INNER JOIN sub.tblPaymentRun_Declaration pd
	ON	pd.PartitionID = dp.PartitionID
WHERE	d.DeclarationID = @DeclarationID
AND		dp.PartitionStatus NOT IN ('0007', '0017')
AND		pd.PaymentRunID = @PaymentRunID

SELECT	@JournalEntryCode = pd.JournalEntryCode,
		@DeclarationStatus = d.DeclarationStatus,
		@MaxPartitionYear = MAX(dep.PartitionYear)
FROM	sub.tblPaymentRun_Declaration pd
INNER JOIN sub.tblDeclaration d ON d.DeclarationID = pd.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep ON dep.PartitionID = pd.PartitionID
WHERE	pd.DeclarationID = @DeclarationID
AND		pd.PaymentRunID = @PaymentRunID
GROUP BY 
		pd.JournalEntryCode,
		d.DeclarationStatus

SELECT	@SumVoucherAmount = SUM(ISNULL(t1.TotalVoucherAmount, 0))
FROM	(
			SELECT	SUM(dpv.DeclarationValue)	AS TotalVoucherAmount
			FROM	sub.tblPaymentRun_Declaration pd
			INNER JOIN sub.tblDeclaration_Partition dp
				ON	dp.DeclarationID = pd.DeclarationID 
			   AND	dp.PartitionID = pd.PartitionID
			INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
				ON	dpv.DeclarationID = pd.DeclarationID
			   AND	dpv.PartitionID = pd.PartitionID
			WHERE	pd.PaymentRunID = @PaymentRunID
			AND		pd.DeclarationID = @DeclarationID
			AND		dp.PartitionStatus NOT IN ('0007', '0017')
			AND		COALESCE(pd.ReversalPaymentID, 0) = 0

			UNION 

			SELECT	SUM(dpv.DeclarationValue * -1)	AS TotalVoucherAmount
			FROM	sub.tblPaymentRun_Declaration pd
			INNER JOIN sub.tblDeclaration_Partition dp
				ON	dp.DeclarationID = pd.DeclarationID 
			   AND	dp.PartitionID = pd.PartitionID
			INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
				ON	dpv.DeclarationID = pd.DeclarationID
			   AND	dpv.PartitionID = pd.PartitionID
			INNER JOIN sub.tblDeclaration_Employee_ReversalPayment der
				ON	der.DeclarationID = dpv.DeclarationID
				AND der.EmployeeNumber = dpv.EmployeeNumber
				AND	der.ReversalPaymentID = pd.ReversalPaymentID
			WHERE	pd.PaymentRunID = @PaymentRunID
			AND		pd.DeclarationID = @DeclarationID
			AND		COALESCE(pd.ReversalPaymentID, 0) <> 0
			AND		dp.PartitionStatus NOT IN ('0007', '0017')
	) t1

SELECT	@UserInitials = SettingValue
FROM 	sub.tblApplicationSetting aps 
WHERE	aps.SettingCode = CAST(@CurrentUserID as varchar(10)) 
AND		aps.SettingName = 'UserInitials'

;WITH cteEmployeeCount AS
(
	SELECT	DeclarationID,
			COUNT(1)	AS EmployeeCount
	FROM	sub.tblDeclaration_Employee
	WHERE	DeclarationID = @DeclarationID
	GROUP BY 
			DeclarationID
)
SELECT	@AmountPerEmployee = SUM(PartitionAmountCorrected) / ISNULL(cte.EmployeeCount, 1)
FROM	sub.tblDeclaration_Partition dep
INNER JOIN sub.tblPaymentRun_Declaration prd on prd.PartitionID = dep.PartitionID
INNER JOIN cteEmployeeCount cte ON cte.DeclarationID = dep.DeclarationID
WHERE	dep.DeclarationID = @DeclarationID
AND		dep.PartitionStatus IN ('0010', '0012', '0014', '0016')
AND		prd.PaymentRunID = @PaymentRunID
GROUP BY 
		dep.DeclarationID,
		cte.EmployeeCount

DECLARE @Partition AS TABLE
	(
		DeclarationID				int,
		IBAN						varchar(18),
		ProcessDate					datetime,
		Ascription					varchar(100)
	)

INSERT INTO @Partition (DeclarationID, IBAN, ProcessDate, Ascription)
SELECT	DISTINCT prd.DeclarationID, prd.IBAN, par.RunDate, prd.Ascription
FROM	sub.tblPaymentRun_Declaration prd
INNER JOIN sub.tblPaymentRun par ON par.PaymentRunID = prd.PaymentRunID
WHERE	prd.DeclarationID = @DeclarationID 
  AND	prd.PaymentRunID = @PaymentRunID

SELECT	TOP 1 @SpecificationDate = ProcessDate
FROM	@Partition	

DECLARE	@Declaration_Rejection AS table
		(
			DeclarationID int NOT NULL,
			RejectionReason varchar(24) NOT NULL,
			RejectionDateTime smalldatetime NULL,
			RejectionXML xml NULL,
			SortOrder int
		)

INSERT INTO @Declaration_Rejection
EXEC	sub.uspDeclaration_Rejection_List @DeclarationID, @CurrentUserID

IF @SubsidySchemeID = 1 AND @MaxPartitionYear >= 2019
BEGIN
	/*	Declare table variable for output of sub.uspDeclaration_Get */
	DECLARE @DeclarationOSR AS TABLE
		(
			DeclarationID				int,
			DeclarationNumber			varchar(12),
			EmployerNumber				varchar(6),
			EmployerName				varchar(100),
			IBAN						varchar(18),
			SubsidySchemeID				int,
			SubsidySchemeName			varchar(50),
			DeclarationDate				datetime,
			InstituteID					int,
			CourseID					int,
			CourseName					varchar(200),
			DeclarationStatus			varchar(4),
			[Location]					varchar(100),
			ElearningSubscription		bit,
			StartDate					date,
			EndDate						date,
			DeclarationAmount			decimal(19, 2),
			ApprovedAmount				decimal(19, 2),
			StatusReason				varchar(max),
			InternalMemo				varchar(max),
			[Partitions]				xml,
			CanReverse					bit,
			CanSetToInvestigation		bit,
			CanAccept					bit,
			CanReject					bit,
			CanReturnToEmployer			bit,
			GetRejectionReason			bit
		)

	/*	Fill table variable	*/
	INSERT INTO @DeclarationOSR
	EXEC osr.uspDeclaration_Get_WithEmployerData 
		@DeclarationID,
		@CurrentUserID

	/*	SET language to Dutch for date representation on specification	*/
	SET LANGUAGE DUTCH

	/*	Get resultset for specification in XML format
		Not applicable to rejected declarations.	*/

	IF @DeclarationStatus <> '0017'
	BEGIN
		IF	(	SELECT	COUNT(drp.DeclarationID)
				FROM	sub.tblDeclaration_ReversalPayment drp
				WHERE	drp.DeclarationID = @DeclarationID
				AND		drp.PaymentRunID = @PaymentRunID ) = 0
		BEGIN
			SELECT @Specification = 
					(	SELECT	
								--	Postal-address favours Business-address.
								(
									SELECT	emp.EmployerName,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressStreet, 
															emp.BusinessAddressHousenumber,
															'',1,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressStreet, 
															emp.PostalAddressHousenumber,
															'',1,0)
											END AS 													Addressline1,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressZipcode, 
															emp.BusinessAddressCity,
															'',2,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressZipcode, 
															emp.PostalAddressCity,
															'',2,0)	
											END AS 													Addressline2,
											''	AS 													Addressline3
									FROM	sub.tblEmployer emp
									WHERE	emp.EmployerNumber = d.EmployerNumber
									FOR XML PATH('PostalAddress'), TYPE
								),

								--	Header
								'Nota specificatie ' + d.SubsidySchemeName													SpecificationScheme,
								'/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + d.EmployerNumber					OurReference,
								CAST(DAY(par.ProcessDate) AS varchar(2)) + ' ' 
								+ CAST(DATENAME(M, par.ProcessDate) AS varchar(10)) + ' ' 
								+ CAST(YEAR(par.ProcessDate) AS varchar(4))													ProcessDate,
								d.CourseName +
									CASE 
										WHEN d.ElearningSubscription = 1 
											THEN ' (E-Learning)' 
										ELSE  																				
											''
										END																					CourseName,
								d.EmployerNumber																			EmployerNumber,
								d.DeclarationNumber																			DeclarationNumber,
								d.ElearningSubscription																		ElearningSubscription,			 														
								CASE WHEN @JournalEntryCode IS NULL
									THEN ''
									ELSE CONVERT(varchar(10), @JournalEntryCode)
								END																							SpecificationNumber,
								CONVERT(varchar(20), d.DeclarationDate, 105)												DeclarationDate,
								CONVERT(varchar(20), d.StartDate, 105)														StartDate,
								CONVERT(varchar(20), d.EndDate, 105)														EndDate,
								d.DeclarationAmount																			DeclarationAmount,
								CASE WHEN d.DeclarationStatus IN ('0007', '0017') THEN 1 ELSE 0 END							IsRejected,
								(
									SELECT 	RejectionReason											"@id",
											RejectionXML											RejectionXML
									FROM	@Declaration_Rejection dr
									FOR XML PATH('RejectionReason'), TYPE
								)																							RejectionReasons, 
								(
									SELECT	CASE WHEN
												(
													SELECT	COUNT(odep.DeclarationID)
													FROM	sub.tblDeclaration_Partition odep		-- Other Declaration_Partition
													WHERE	odep.DeclarationID = d.DeclarationID
												) = 1 
												THEN 0 
												ELSE 1 
											END AS PartialPayment,
											dep.PartitionYear													PayedPartitionYear,
											CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
												THEN 0 
												ELSE dep.PartitionAmountCorrected
											END																	PayedPartitionAmount,
											CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
												THEN 0 
												ELSE dep.PartitionAmountCorrected
											END																	CollectiveBalance
									FROM	sub.tblDeclaration_Partition dep
									INNER JOIN sub.tblPaymentRun_Declaration prd ON prd.PartitionID = dep.PartitionID
									WHERE	dep.DeclarationID = d.DeclarationID
									AND		prd.PaymentRunID = @PaymentRunID
									FOR XML PATH('PayedPartition'), TYPE
								) AS																						PayedPartitions,
								@SumVoucherAmount																			SumVoucherAmount,

								--	Declaration overview
								(
									SELECT	emp.FullName													EmployeeName,
											CONVERT(varchar(10), emp.DateOfBirth, 105) 						DateOfBirth,
											emp.EmployeeNumber												EmployeeNumber,
											(
												SELECT	emv.VoucherNumber									Number,
														SUM(dpv.DeclarationValue)							AmountUsed,
														emv.EventName										EventName
												FROM	sub.tblPaymentRun_Declaration prd 
												INNER JOIN sub.tblDeclaration_Partition_Voucher dpv 
												ON		dpv.DeclarationID = prd.DeclarationID
												AND		dpv.PartitionID = prd.PartitionID
												AND		dpv.EmployeeNumber = emp.EmployeeNumber
												INNER JOIN sub.tblEmployee_Voucher emv								 
												ON		emv.EmployeeNumber = dpv.EmployeeNumber
												AND		emv.VoucherNumber = dpv.VoucherNumber
												WHERE	prd.PaymentRunID = @PaymentRunID
												AND		prd.DeclarationID = d.DeclarationID
												GROUP BY 
														emv.VoucherNumber,
														emv.EventName
												FOR XML PATH('Voucher'), TYPE
											) AS																			Vouchers,
											(
												SELECT	ISNULL(SumAmountUsed, 0)							SumAmountUsed,
														CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
														THEN 0
														ELSE @AmountPerEmployee
														END	 												FromBudget
												FROM
														(	
															SELECT	SUM(dpv.DeclarationValue)	SumAmountUsed
															FROM	sub.tblPaymentRun_Declaration prd 
															INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
															ON		dpv.DeclarationID = prd.DeclarationID
															AND		dpv.PartitionID = prd.PartitionID
															AND		dpv.EmployeeNumber = emp.EmployeeNumber
															INNER JOIN sub.tblEmployee_Voucher emv 
															ON		emv.EmployeeNumber = dpv.EmployeeNumber
															AND		emv.VoucherNumber = dpv.VoucherNumber		
															WHERE	dpv.DeclarationID = d.DeclarationID
															AND		dpv.EmployeeNumber = emp.EmployeeNumber
														) SumAmountUsedPerEmployee
												FOR XML PATH('Subdivide'), TYPE
											) AS																			VouchersUsage
									FROM	sub.tblDeclaration_Employee dem
									INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
									WHERE	dem.DeclarationID = d.DeclarationID
									FOR XML PATH('Employee'), TYPE
								)																							Employees,
								par.IBAN																					IBAN,
								par.Ascription																				Ascription
						FROM	@DeclarationOSR d
						INNER JOIN sub.viewApplicationSetting_DeclarationStatus ds 
							ON ds.SettingCode = d.DeclarationStatus
						INNER JOIN @Partition par 
							ON par.DeclarationID = d.DeclarationID
						FOR XML PATH('Declaration'), ROOT('Specification')
					)
		END
		ELSE		-- Terugboeking
		BEGIN
			SELECT @Specification = 
					(	SELECT	
								--	Postal-address favours Business-address.
								(
									SELECT	emp.EmployerName,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressStreet, 
															emp.BusinessAddressHousenumber,
															'',1,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressStreet, 
															emp.PostalAddressHousenumber,
															'',1,0)	
											END AS 													Addressline1,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressZipcode, 
															emp.BusinessAddressCity,
															'',2,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressZipcode, 
															emp.PostalAddressCity,
															'',2,0)	
											END AS 													Addressline2,
											''	AS 													Addressline3
									FROM	sub.tblEmployer emp
									WHERE	emp.EmployerNumber = d.EmployerNumber
									FOR XML PATH('PostalAddress'), TYPE
								),

								--	Header
								'Nota specificatie ' + d.SubsidySchemeName													SpecificationScheme,
								'/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + d.EmployerNumber					OurReference,
								CAST(DAY(par.ProcessDate) AS varchar(2)) + ' ' 
								+ CAST(DATENAME(M, par.ProcessDate) AS varchar(10)) + ' ' 
								+ CAST(YEAR(par.ProcessDate) AS varchar(4))													ProcessDate,
								d.CourseName																				CourseName,
								d.EmployerNumber																			EmployerNumber,
								d.DeclarationNumber					 														DeclarationNumber,
								CASE WHEN @JournalEntryCode IS NULL
									THEN ''
									ELSE CONVERT(varchar(10), @JournalEntryCode)
								END																							SpecificationNumber,
								CONVERT(varchar(20), d.DeclarationDate, 105)												DeclarationDate,
								CONVERT(varchar(20), d.StartDate, 105)														StartDate,
								CONVERT(varchar(20), d.EndDate, 105)														EndDate,
								@SumPartitionAmount	+ @SumVoucherAmount														ReversalAmount,
								--	Declaration overview
								(
									SELECT	emp.FullName																	EmployeeName,
											CONVERT(varchar(10), emp.DateOfBirth, 105) 										DateOfBirth,
											emp.EmployeeNumber																EmployeeNumber,
											(
												SELECT	emv.VoucherNumber									Number,
														SUM(dpv.DeclarationValue) * -1						AmountUsed,
														emv.EventName										EventName
												FROM	sub.tblPaymentRun_Declaration prd 
												INNER JOIN sub.tblDeclaration_Partition_Voucher dpv 
												ON		dpv.DeclarationID = prd.DeclarationID
												AND		dpv.PartitionID = prd.PartitionID
												AND		dpv.EmployeeNumber = emp.EmployeeNumber
												INNER JOIN sub.tblEmployee_Voucher emv								 
												ON		emv.EmployeeNumber = dpv.EmployeeNumber
												AND		emv.VoucherNumber = dpv.VoucherNumber
												WHERE	prd.PaymentRunID = @PaymentRunID
												AND		prd.DeclarationID = d.DeclarationID
												GROUP BY 
														emv.VoucherNumber,
														emv.EventName
												FOR XML PATH('Voucher'), TYPE
											)																				Vouchers,
											(
												SELECT	ISNULL(SumAmountUsed, 0) * -1						SumAmountUsed,
														CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
														THEN 0
														ELSE @AmountPerEmployee * -1
														END	 												FromBudget
												FROM
														(	
															SELECT	SUM(dpv.DeclarationValue)	SumAmountUsed
															FROM	sub.tblPaymentRun_Declaration prd 
															INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
															ON		dpv.DeclarationID = prd.DeclarationID
															AND		dpv.PartitionID = prd.PartitionID
															AND		dpv.EmployeeNumber = emp.EmployeeNumber
															INNER JOIN sub.tblEmployee_Voucher emv 
															ON		emv.EmployeeNumber = dpv.EmployeeNumber
															AND		emv.VoucherNumber = dpv.VoucherNumber		
															WHERE	dpv.DeclarationID = d.DeclarationID
															AND		dpv.EmployeeNumber = emp.EmployeeNumber
														) SumAmountUsedPerEmployee
												FOR XML PATH('Subdivide'), TYPE
											) AS VouchersUsage
									FROM	sub.tblDeclaration_Employee dem
									INNER JOIN sub.tblEmployee emp 
									ON		emp.EmployeeNumber = dem.EmployeeNumber
									INNER JOIN sub.viewReversalPayment_Declaration_Employee rpde
									ON		rpde.DeclarationID = d.DeclarationID
									AND		rpde.EmployeeNumber = dem.EmployeeNumber
									AND		rpde.PaymentRunID = @PaymentRunID
									WHERE	dem.DeclarationID = d.DeclarationID
									FOR XML PATH('Employee'), TYPE
								)																							Employees,
								par.IBAN																					IBAN
						FROM	@DeclarationOSR d
						INNER JOIN sub.viewApplicationSetting_DeclarationStatus ds ON ds.SettingCode = d.DeclarationStatus
						INNER JOIN @Partition par ON par.DeclarationID = d.DeclarationID
						INNER JOIN sub.tblDeclaration_ReversalPayment drp 
						ON		drp.DeclarationID = d.DeclarationID
						AND		drp.PaymentRunID = @PaymentRunID
						FOR XML PATH('Declaration'), ROOT('Specification')
					)
		END
	END
END 

IF @SubsidySchemeID = 3
BEGIN
	DECLARE @DeclarationEVC AS TABLE
	(
		DeclarationID				int,
		DeclarationNumber			varchar(12),
		EmployerNumber				varchar(6),
		EmployerName				varchar(100),
		IBAN						varchar(18),
		SubsidySchemeID				int,
		SubsidySchemeName			varchar(50),
		DeclarationDate				datetime,
		InstituteID					int,
		DeclarationStatus			varchar(4),
		IntakeDate					date,
		CertificationDate			date,
		DeclarationAmount			decimal(19, 2),
		ApprovedAmount				decimal(19, 2),
		StatusReason				varchar(max),
		InternalMemo				varchar(max),
		[Partitions]				xml,
		CanReverse					bit,
		CanSetToInvestigation		bit,
		CanAccept					bit,
		CanReject					bit,
		CanReturnToEmployer			bit,
		GetRejectionReason			bit
	)

	/*	Fill table variable	*/
	INSERT INTO @DeclarationEVC
	EXEC	evc.uspDeclaration_Get_WithEmployerData
			@DeclarationID = @DeclarationID,
			@UserID = @CurrentUserID

		/*	SET language to Dutch for date representation on specification	*/
	SET LANGUAGE DUTCH

	/*	Get resultset for specification in XML format	*/
	IF @DeclarationStatus <> '0017'
	BEGIN
		IF	(	SELECT	COUNT(drp.DeclarationID)
				FROM	sub.tblDeclaration_ReversalPayment drp
				WHERE	drp.DeclarationID = @DeclarationID
				AND		drp.PaymentRunID = @PaymentRunID ) = 0
		BEGIN
			SET @Specification = 
					(	SELECT	
								--	Postal-address favours Business-address.
								(
									SELECT	emp.EmployerName,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressStreet, 
															emp.BusinessAddressHousenumber,
															'',1,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressStreet, 
															emp.PostalAddressHousenumber,
															'',1,0)	
											END AS 											Addressline1,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressZipcode, 
															emp.BusinessAddressCity,
															'',2,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressZipcode, 
															emp.PostalAddressCity,
															'',2,0)	
											END AS											Addressline2,
											'' AS											Addressline3
									FROM	sub.tblEmployer emp
									WHERE	emp.EmployerNumber = d.EmployerNumber
									FOR XML PATH('PostalAddress'), TYPE
								),

								--	Header
								'Nota specificatie ' + d.SubsidySchemeName													SpecificationScheme,
								'/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + d.EmployerNumber					OurReference,
								CAST(DAY(GETDATE()) AS varchar(2)) + ' ' 
								+ CAST(DATENAME(M, GETDATE()) AS varchar(10)) + ' ' 
								+ CAST(YEAR(GETDATE()) AS varchar(4))														ProcessDate,
								d.EmployerNumber,
								d.DeclarationNumber					 														DeclarationNumber,
								CASE WHEN @JournalEntryCode IS NULL
									THEN ''
									ELSE CONVERT(varchar(10), @JournalEntryCode)
								END																							SpecificationNumber,
								CONVERT(varchar(20), d.DeclarationDate, 105)												DeclarationDate,
								CONVERT(varchar(20), d.IntakeDate, 105)														IntakeDate,
								CONVERT(varchar(20), d.CertificationDate, 105)												CertificationDate,
								evcd.Employee																				EmployeeName,
								evcd.EmployeeNumber																			EmployeeNumber,
								evcd.DateOfBirth																			DateOfBirth,
								evcd.Mentor																					Mentor,
								di.InstituteName																			Institute,
								evcd.QualificationLevelLevelName															QualificationLevelLevel,
								d.DeclarationAmount																			DeclarationAmount,
								CASE WHEN d.DeclarationStatus IN ('0007', '0017') THEN 1 ELSE 0 END							IsRejected,
								(
									SELECT	dr.RejectionReason											"@id",
											dr.RejectionXML												RejectionXML							
									FROM	@Declaration_Rejection dr
									WHERE	dr.DeclarationID = d.DeclarationID
										AND	d.DeclarationStatus IN ('0007', '0017')
									FOR XML PATH('RejectionReason'), TYPE
								) AS																						RejectionReasons,
								(
									SELECT	dep.PartitionYear										PayedPartitionYear,
												CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
													THEN 0 
													ELSE dep.PartitionAmountCorrected
												END													PayedPartitionAmount,
												CASE WHEN d.DeclarationStatus IN ('0007', '0017') 
													THEN 0 
													ELSE dep.PartitionAmountCorrected
												END													CollectiveBalance
									FROM	sub.tblDeclaration_Partition dep
									INNER JOIN sub.tblPaymentRun_Declaration prd ON prd.PartitionID = dep.PartitionID
									WHERE	dep.DeclarationID = d.DeclarationID
									AND		prd.PaymentRunID = @PaymentRunID
									FOR XML PATH('PayedPartition'), TYPE
								) AS																						PayedPartitions,
								par.IBAN,
								par.Ascription																				Ascription 
						FROM	@DeclarationEVC d
						INNER JOIN sub.viewApplicationSetting_DeclarationStatus ds ON ds.SettingCode = d.DeclarationStatus
						INNER JOIN  sub.viewDeclaration_Institute di 
								ON	di.DeclarationID = d.DeclarationID
						LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = d.DeclarationID
						LEFT JOIN  @Partition par ON par.DeclarationID = d.DeclarationID
						FOR XML PATH('Declaration'), ROOT('Specification')
					)
		END
		ELSE		-- Terugboeking
		BEGIN
			SET @Specification = 
					(	SELECT	
								--	Postal-address favours Business-address.
								(
									SELECT	emp.EmployerName,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressStreet, 
															emp.BusinessAddressHousenumber,
															'',1,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressStreet, 
															emp.PostalAddressHousenumber,
															'',1,0)	
											END AS 											Addressline1,
											CASE WHEN emp.PostalAddressStreet IS NULL
												THEN sub.usfConcatStrings
														(	emp.BusinessAddressZipcode, 
															emp.BusinessAddressCity,
															'',2,0)	
												ELSE sub.usfConcatStrings
														(	emp.PostalAddressZipcode, 
															emp.PostalAddressCity,
															'',2,0)	
											END AS											Addressline2,
											'' AS											Addressline3
									FROM	sub.tblEmployer emp
									WHERE	emp.EmployerNumber = d.EmployerNumber
									FOR XML PATH('PostalAddress'), TYPE
								),

								--	Header
								'Nota specificatie ' + d.SubsidySchemeName													SpecificationScheme,
								'/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + d.EmployerNumber					OurReference,
								CAST(DAY(GETDATE()) AS varchar(2)) + ' ' 
								+ CAST(DATENAME(M, GETDATE()) AS varchar(10)) + ' ' 
								+ CAST(YEAR(GETDATE()) AS varchar(4))														ProcessDate,
								d.EmployerNumber,
								d.DeclarationNumber					 														DeclarationNumber,
								CASE WHEN @JournalEntryCode IS NULL
									THEN ''
									ELSE CONVERT(varchar(10), @JournalEntryCode)
								END																							SpecificationNumber,
								CONVERT(varchar(20), d.DeclarationDate, 105)												DeclarationDate,
								CONVERT(varchar(20), d.IntakeDate, 105)														IntakeDate,
								CONVERT(varchar(20), d.CertificationDate, 105)												CertificationDate,
								evcd.Employee																				EmployeeName,
								evcd.EmployeeNumber																			EmployeeNumber,
								evcd.DateOfBirth																			DateOfBirth,
								evcd.Mentor																					Mentor,
								di.InstituteName																			Institute,
								evcd.QualificationLevelLevelName															QualificationLevelLevel,
								@SumPartitionAmount	+ @SumVoucherAmount														ReversalAmount,
								par.IBAN,
								par.Ascription																				Ascription 
						FROM	@DeclarationEVC d
						INNER JOIN sub.viewApplicationSetting_DeclarationStatus ds ON ds.SettingCode = d.DeclarationStatus
						INNER JOIN  sub.viewDeclaration_Institute di 
								ON	di.DeclarationID = d.DeclarationID
						INNER JOIN sub.tblDeclaration_ReversalPayment drp 
						ON		drp.DeclarationID = d.DeclarationID
						AND		drp.PaymentRunID = @PaymentRunID
						LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = d.DeclarationID
						LEFT JOIN  @Partition par ON par.DeclarationID = d.DeclarationID
						FOR XML PATH('Declaration'), ROOT('Specification')
					)
		END
	END
END 

IF @IsNew = 1
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration_Specification
		(
			DeclarationID,
			SpecificationSequence,
			SpecificationDate,
			PaymentRunID,
			Specification,
			SumPartitionAmount,
			SumVoucherAmount
		)
	VALUES
		(
			@DeclarationID,
			@SpecificationSequence,
			@SpecificationDate,
			@PaymentRunID,
			CASE @DeclarationStatus WHEN '0017' THEN NULL ELSE @Specification END,
			ISNULL(@SumPartitionAmount, 0),
			ISNULL(@SumVoucherAmount, 0)
		)

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblDeclaration_Specification
						WHERE	DeclarationID = @DeclarationID
						AND		SpecificationSequence = @SpecificationSequence
						FOR XML PATH )

END
ELSE
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	sub.tblDeclaration_Specification
						WHERE	DeclarationID = @DeclarationID
						AND		SpecificationSequence = @SpecificationSequence
						FOR XML PATH )

	-- Update existing record.
	UPDATE	sub.tblDeclaration_Specification
	SET
			PaymentRunID			= @PaymentRunID,
			Specification			= CASE @DeclarationStatus WHEN '0017' THEN NULL ELSE @Specification END,
			SpecificationDate		= @SpecificationDate,
			SumPartitionAmount		= ISNULL(@SumPartitionAmount, 0),
			SumVoucherAmount		= ISNULL(@SumVoucherAmount, 0)
	WHERE	DeclarationID = @DeclarationID
	AND		SpecificationSequence = @SpecificationSequence

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	sub.tblDeclaration_Specification
						WHERE	DeclarationID = @DeclarationID
						AND		SpecificationSequence = @SpecificationSequence
						FOR XML PATH )
END

-- Log action in his.tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@DeclarationID AS varchar) + '|' + CAST(@SpecificationSequence AS varchar)

	EXEC his.uspHistory_Add
			'sub.tblDeclaration_Specification',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SET @Return = 0

RETURN @Return

/*	== sub.uspDeclaration_Specification_Upd ==================================================	*/
