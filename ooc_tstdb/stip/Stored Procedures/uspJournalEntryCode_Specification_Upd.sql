
CREATE PROCEDURE [stip].[uspJournalEntryCode_Specification_Upd]
@JournalEntryCode		int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update stip.tblJournalEntryCode_Specification on basis of JournalEntryCode.

	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	09-07-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

/* TestData.
DECLARE	@JournalEntryCode		int = 19300001,
		@CurrentUserID			int = 1
--	*/

DECLARE @UserInitials			varchar(3),
		@DefaultUserInitials	varchar(3) = 'DRO',
		@IBAN					varchar(34),
		@Ascription				varchar(100),
		@SpecificationScheme	varchar(100),
		@OurReference			varchar(100),
		@HeaderInfo				varchar(20),
		@HeaderPhone			varchar(20),
		@HeaderEMail			varchar(50),
		@EmployerNumber			varchar(6),
		@ProcessDate			date,
		@MaxPartitionYear		smallint,
		@TotalAmount			decimal(19,2),
		@Specification			xml,
		@RejectedDeclarationID  int

/*	SET language to Dutch for date representation on specification	*/
SET LANGUAGE DUTCH

SELECT	@UserInitials = aps.SettingValue
FROM 	sub.tblApplicationSetting aps 
WHERE	aps.SettingCode = CAST(@CurrentUserID AS varchar(10)) 
AND		aps.SettingName = 'UserInitials'

SELECT	@HeaderInfo = aps.SettingValue
FROM 	sub.tblApplicationSetting aps 
WHERE	aps.SettingName = 'SpecificationHeader'
AND		aps.SettingCode = 'Info'

SELECT	@HeaderPhone = aps.SettingValue
FROM 	sub.tblApplicationSetting aps 
WHERE	aps.SettingName = 'SpecificationHeader'
AND		aps.SettingCode = 'Telefoon'

SELECT	@HeaderEMail = aps.SettingValue
FROM 	sub.tblApplicationSetting aps 
WHERE	aps.SettingName = 'SpecificationHeader'
AND		aps.SettingCode = 'E-Mail'

DECLARE @DeclarationAmount AS TABLE
	(
		PaymentRunID int,
		RunDate daTe,
		SubsidySchemeID int,
		DeclarationID int, 
		DeclarationDate Date, 
		PartitionStatus varchar(20),
		EmployerNumber varchar(6), 
		DeclarationAmount dec (19,2), 
		EmployeeNumber varchar(8),
		Employee varchar(133),
		DateOfBirth date,
		EducationName varchar(213),
		StartDate date,
		TerminationReason varchar(4),
		TerminationDate date,
		DiplomaDate date,
		TotalAmount dec (19,2),
		IsReversal bit
)

DECLARE	@Declaration_Rejection AS table
		(
			DeclarationID int NOT NULL,
			RejectionReason varchar(24) NOT NULL,
			RejectionDateTime smalldatetime NULL,
			RejectionXML xml NULL,
			SortOrder int
		)

INSERT INTO @DeclarationAmount
SELECT	PerPartition.PaymentRunID,
		PerPartition.RunDate,
		PerPartition.SubsidySchemeID,
		PerPartition.DeclarationID, 
		PerPartition.DeclarationDate, 
		PerPartition.PartitionStatus,
		PerPartition.EmployerNumber, 
		PerPartition.PartitionStatus, 
		PerPartition.EmployeeNumber,
		PerPartition.Employee,
		PerPartition.DateOfBirth,
		PerPartition.EducationName,
		PerPartition.StartDate,
		PerPartition.TerminationReason,
		PerPartition.TerminationDate,
		PerPartition.DiplomaDate,
		SUM(PerPartition.PartitionAmountCorrected)  AS TotalAmount,
		PerPartition.IsReversal
FROM	(
			SELECT	prd.PaymentRunID,
					payr.RunDate,
					payr.SubsidySchemeID,
					prd.DeclarationID, 
					decl.DeclarationDate, 
					dpar.PartitionStatus,
					decl.EmployerNumber, 
					decl.DeclarationAmount, 
					decl.EmployeeNumber,
					decl.Employee,
					decl.DateOfBirth,
					decl.EducationName,
					decl.StartDate,
					decl.TerminationReason,
					decl.TerminationDate,
					decl.DiplomaDate,
					dpar.PartitionAmountCorrected,
					CAST(CASE WHEN drp.ReversalPaymentID IS NULL THEN 0 ELSE 1 END AS bit) IsReversal
			FROM	sub.tblPaymentRun_Declaration prd
			INNER JOIN sub.tblPaymentRun payr ON payr.PaymentRunID = prd.PaymentRunID
			INNER JOIN stip.viewDeclaration_Partition dpar 
					ON	dpar.DeclarationID = prd.DeclarationID 
					AND	dpar.PartitionID = prd.PartitionID
			INNER JOIN stip.viewDeclaration decl 
					ON	decl.DeclarationID = prd.DeclarationID 
			LEFT JOIN sub.tblDeclaration_ReversalPayment drp 
					ON	drp.ReversalPaymentID = prd.ReversalPaymentID
			WHERE	prd.JournalEntryCode = @JournalEntryCode
		)	PerPartition
GROUP BY 
		PerPartition.PaymentRunID,
		PerPartition.RunDate,
		PerPartition.SubsidySchemeID,
		PerPartition.DeclarationID, 
		PerPartition.DeclarationDate, 
		PerPartition.PartitionStatus,
		PerPartition.EmployerNumber, 
		PerPartition.DeclarationAmount, 
		PerPartition.EmployeeNumber,
		PerPartition.Employee,
		PerPartition.DateOfBirth,
		PerPartition.EducationName,
		PerPartition.StartDate,
		PerPartition.TerminationReason,
		PerPartition.TerminationDate,
		PerPartition.DiplomaDate,
		PerPartition.IsReversal

/*	Rejection reasons											*/
DECLARE crs_RejectedDeclaration CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	SELECT	da.DeclarationID
		FROM	@DeclarationAmount da
		WHERE	da.PartitionStatus IN ('0007', '0017')

	OPEN crs_RejectedDeclaration
	FETCH FROM crs_RejectedDeclaration
	INTO @RejectedDeclarationID
WHILE @@FETCH_STATUS = 0   
BEGIN
	INSERT INTO @Declaration_Rejection
	EXEC	sub.uspDeclaration_Rejection_List @RejectedDeclarationID, @CurrentUserID

	FETCH NEXT FROM crs_RejectedDeclaration
	INTO @RejectedDeclarationID
END
CLOSE crs_RejectedDeclaration   
DEALLOCATE crs_RejectedDeclaration

/*	Remove RejectionReasons not shown on specification		*/
DELETE 
FROM	@Declaration_Rejection
WHERE	RejectionReason IN
		(
			SELECT	SettingCode
			FROM	sub.viewApplicationSetting_RejectionReason
			WHERE	NotShownOnSpecification = 1
		)


SELECT	@IBAN = prd.IBAN,
		@Ascription = prd.Ascription,
		@SpecificationScheme = 'Nota specificatie ' + subs.SubsidySchemeName,
		@OurReference = '/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + decl.EmployerNumber,
		@EmployerNumber = decl.EmployerNumber,
		@ProcessDate = decl.RunDate,
		@TotalAmount = decl.TotalAmount
FROM	@DeclarationAmount decl
INNER JOIN sub.tblPaymentRun_Declaration prd ON prd.DeclarationID = decl.DeclarationID
INNER JOIN sub.tblSubsidyScheme subs ON subs.SubsidySchemeID = decl.SubsidySchemeID

SELECT @Specification = 
		(
			SELECT	@JournalEntryCode													AS "@Number",
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
						WHERE	emp.EmployerNumber = @EmployerNumber
						FOR XML PATH('PostalAddress'), TYPE
					),
					@IBAN																IBAN,
					@Ascription															Ascription,
					@SpecificationScheme												SpecificationScheme,
					@OurReference														OurReference,
					CAST(GETDATE() AS date)												PrintDate,
					@EmployerNumber														EmployerNumber,
					@ProcessDate														ProcessDate,
					@TotalAmount														TotalAmount,
					@JournalEntryCode													JournalEntryCode,
					(
						SELECT
								decl.DeclarationID										AS "@Number",
								decl.IsReversal											IsReversal,
								CASE 
									WHEN decl.PartitionStatus IN ('0007', '0017') 
									THEN 1 
									ELSE 0 
								END														IsRejected,
								(
									SELECT 	RejectionReason								"@id",
											RejectionXML								RejectionXML
									FROM	@Declaration_Rejection dr
									WHERE	dr.DeclarationID = decl.DeclarationID
									FOR XML PATH('RejectionReason'), TYPE
								)														RejectionReasons, 
								decl.DeclarationDate									DeclarationDate,
								decl.EmployeeNumber										EmployeeNumber,
								decl.Employee											Employee,
								decl.DateOfBirth										DateOfBirth,
								decl.EducationName										EducationName,
								decl.StartDate											StartDate,
								decl.DeclarationAmount									DeclarationAmount,
								CASE WHEN decl.IsReversal = 0 
									THEN decl.TotalAmount
									ELSE decl.TotalAmount * -1
								END														PaidAmount,
								CASE WHEN ISNULL(decl.TerminationReason, '') = '' 
									THEN NULL
									ELSE 'BPV beëindigd per ' + CONVERT(varchar(10), decl.Terminationdate, 105) + '</br>' +
										 'Reden beëindiging: ' + aps.SettingDescription									
								END														TerminationReason,
								(
									SELECT
											dp.Title									Title,
											CAST(dp.PaymentDate AS date)				PaymentDate,
											dp.PartitionAmountCorrected					Amount
									FROM	stip.viewDeclaration_Partition dp
									INNER JOIN sub.tblPaymentRun_Declaration prd
											ON	prd.PartitionID = dp.PartitionID
											AND prd.PaymentRunID = decl.PaymentRunID
									WHERE	dp.DeclarationID = decl.DeclarationID
									FOR XML PATH('Partition'), ROOT ('Partitions'), TYPE
								)
							FROM	@DeclarationAmount decl
							INNER JOIN sub.tblPaymentRun_Declaration prd ON prd.DeclarationID = decl.DeclarationID
							INNER JOIN sub.tblSubsidyScheme subs ON	subs.SubsidySchemeID = decl.SubsidySchemeID
							LEFT JOIN 
								(
									SELECT	SettingDescription, SettingCode
									FROM	sub.tblApplicationSetting
									WHERE	SettingName = 'TerminationCode'							
								) aps ON aps.SettingCode = 'TerminationReason'
							ORDER BY decl.IsReversal, decl.DeclarationID
							FOR XML PATH('Declaration'), ROOT ('Declarations'), TYPE
							) 
			FOR XML PATH('JournalEntryCode')
		)

UPDATE	sub.tblJournalEntryCode 
SET		Specification = @Specification
WHERE	JournalEntryCode = @JournalEntryCode

/*	== stip.uspJournalEntryCode_Specification_Upd ================================================	*/
