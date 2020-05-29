
CREATE PROCEDURE [osr].[uspJournalEntryCode_Specification_Upd]
@JournalEntryCode		int,
@CurrentUserID			int = 1
AS
/*	==========================================================================================
	Purpose: 	Update osr.tblJournalEntryCode_Specification on basis of JournalEntryCode.

	21-02-2020	Jaap van Assenebrgh OTIBSUB-1904	Hot fix Specification
	20-02-2020	Jaap van Assenebrgh	OTIBSUB-1904	Werkgever 005580 nota/dashboard/status declaraties onjuist
													Bedrag dubbel opgelost.
	29-01-2020	Sander van Houten	OTIBSUB-1861	Only select the data from the correct
                                        PaymentRunID in cteDeclarationCommentary.
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	25-09-2019	Jaap van Assenebrgh	OTIBSUB-1590    Declaration without employee not on specification
	03-09-2019	Jaap van Assenbergh	OTIBSUB-1304    Afgekeurde declaraties op verzamelnota
	24-06-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* TestData.
DECLARE	@JournalEntryCode		int = 19205246,
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
		@Specification			xml,
		@RejectedDeclarationID  int

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

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
		PaymentRunID        int,
		RunDate             date,
		SubsidySchemeID     int,
		DeclarationID       int,
		DeclarationDate     date,
--		PartitionStatus     varchar(20),
		EmployerNumber      varchar(6), 
		DeclarationAmount   decimal(19,2), 
		CourseName          varchar(200),
		StartDate           date,
		INDEX CI_DeclarationAmount CLUSTERED (PaymentRunID, DeclarationID)

	)

DECLARE @PartitionEmployee AS TABLE
	(	
		PaymentRunID    int,
		DeclarationID   int, 
		PartitionID     int,
		IsReversal      bit, 
		EmployeeNumber  varchar(8),
		FromBudget      decimal(19,2),
		VoucherAmount   decimal(19,2),
		INDEX CI_PartitionEmployee CLUSTERED (PaymentRunID, DeclarationID, PartitionID)
	)

DECLARE	@Declaration_Rejection AS TABLE
    (
        DeclarationID       int NOT NULL,
        RejectionReason     varchar(24) NOT NULL,
        RejectionDateTime   smalldatetime NULL,
        RejectionXML        xml NULL,
        SortOrder           int,
		INDEX CI_PartitionEmployee CLUSTERED (DeclarationID)
    )


INSERT INTO @DeclarationAmount
	(
		PaymentRunID,
		RunDate,
		SubsidySchemeID,
		DeclarationID,
		DeclarationDate,
--		PartitionStatus,
		EmployerNumber,
		DeclarationAmount,
		CourseName,
		StartDate
	)
SELECT	DISTINCT
		prd.PaymentRunID,
		par.RunDate,
		par.SubsidySchemeID,
		prd.DeclarationID, 
		d.DeclarationDate, 
--		dep.PartitionStatus,
		d.EmployerNumber, 
		d.DeclarationAmount, 
		d.CourseName,
		d.StartDate
FROM	sub.tblPaymentRun_Declaration prd
INNER JOIN	sub.tblPaymentRun par 
		ON	par.PaymentRunID = prd.PaymentRunID
INNER JOIN	osr.viewDeclaration d 
		ON	d.DeclarationID = prd.DeclarationID 
--INNER JOIN	sub.tblDeclaration_Partition dep 
--		ON	dep.PartitionID = prd.PartitionID
WHERE	prd.JournalEntryCode = @JournalEntryCode

--SELECT * FROM @DeclarationAmount

INSERT INTO @PartitionEmployee
	(	
		PaymentRunID,
		DeclarationID,
		PartitionID,
		IsReversal, 
		EmployeeNumber,
		FromBudget,
		VoucherAmount
	)
SELECT	dea.PaymentRunID,
		dea.DeclarationID, 
		dea.PartitionID, 
		dea.IsReversal,
		dea.EmployeeNumber, 
		dea.FromBudget, 
		dea.VoucherAmount
FROM    @DeclarationAmount da
INNER JOIN	sub.viewDeclaration_Employee_Amount dea 
		ON	dea.PaymentRunID = da.PaymentRunID
		AND dea.DeclarationID = da.DeclarationID

UNION ALL

SELECT	prd.PaymentRunID,
		dp.DeclarationID, 
		dp.PartitionID, 
		CASE WHEN prd.ReversalPaymentID = 0 
			THEN 0 
			ELSE 1 
		END     AS IsReversal,
		NULL,
		CASE WHEN prd.ReversalPaymentID = 0 
			THEN dp.PartitionAmountCorrected	
			ELSE dp.PartitionAmountCorrected * -1
		END		AS FromBudget,  
		0		VoucherAmount
FROM	@DeclarationAmount da
INNER JOIN	sub.tblDeclaration_Partition dp 
		ON	dp.DeclarationID = da.DeclarationID
INNER JOIN	sub.tblPaymentRun_Declaration prd 
		ON	prd.PaymentRunID = da.PaymentRunID
		AND	prd.PartitionID = dp.PartitionID
LEFT JOIN	sub.tblDeclaration_Employee de 
		ON	de.DeclarationID = dp.DeclarationID
WHERE   de.DeclarationID IS NULL

--SELECT * FROM @PartitionEmployee

/*	Rejection reasons.  */
DECLARE crs_RejectedDeclaration CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	
		SELECT	da.DeclarationID
		FROM	@DeclarationAmount da
		INNER JOIN	sub.tblDeclaration_Partition dep 
				ON	dep.DeclarationID = da.DeclarationID
		WHERE	dep.PartitionStatus IN ('0007', '0017')

OPEN crs_RejectedDeclaration

FETCH FROM crs_RejectedDeclaration INTO @RejectedDeclarationID

WHILE @@FETCH_STATUS = 0   
BEGIN
	INSERT INTO @Declaration_Rejection
	EXEC sub.uspDeclaration_Rejection_List @RejectedDeclarationID, @CurrentUserID

	FETCH NEXT FROM crs_RejectedDeclaration	INTO @RejectedDeclarationID
END

CLOSE crs_RejectedDeclaration   
DEALLOCATE crs_RejectedDeclaration

/*	Remove RejectionReasons not shown on specification. */
DELETE 
FROM	@Declaration_Rejection
WHERE	RejectionReason IN
		(
			SELECT	SettingCode
			FROM	sub.viewApplicationSetting_RejectionReason
			WHERE	NotShownOnSpecification = 1
		)

SELECT	
		@IBAN = prd.IBAN,
		@Ascription = prd.Ascription,
		@SpecificationScheme = 'Nota specificatie ' + subs.SubsidySchemeName,
		@OurReference = '/' + ISNULL(@UserInitials, @DefaultUserInitials) + '/' + d.EmployerNumber,
		@EmployerNumber = d.EmployerNumber,
		@ProcessDate = d.RunDate
FROM	@DeclarationAmount d
INNER JOIN	sub.tblPaymentRun_Declaration prd 
		ON	prd.DeclarationID = d.DeclarationID
INNER JOIN	sub.tblSubsidyScheme subs 
		ON	subs.SubsidySchemeID = d.SubsidySchemeID

;WITH cteTotalDeclarationAmount AS
	(
		SELECT	PaymentRunID,
				DeclarationID, 
				PartitionID, 
				SUM(FromBudget)		FromBudget, 
				SUM(VoucherAmount)	VoucherAmount
		FROM	@PartitionEmployee
		GROUP BY 
				PaymentRunID,
				DeclarationID, 
				PartitionID
	)
,
cteTotalPaymentrunAmount AS
	(
		SELECT	pee.PaymentRunID,
				pee.DeclarationID, 
				SUM(pee.FromBudget)		AS FromBudget, 
				SUM(pee.VoucherAmount)	AS VoucherAmount
		FROM	@PartitionEmployee pee
		INNER JOIN	sub.tblPaymentRun_Declaration prd 
				ON	prd.PaymentRunID = pee.PaymentRunID
				AND	prd.DeclarationID = pee.DeclarationID
				AND prd.PartitionID = pee.PartitionID
		INNER JOIN	sub.tblPaymentRun payr 
				ON	payr.PaymentRunID = prd.PaymentRunID 
		WHERE	prd.JournalEntryCode = @JournalEntryCode
		GROUP BY 
				pee.PaymentRunID,
				pee.DeclarationID
	)
,
cteDeclarationCommentary
 AS
	(
		SELECT	ROW_NUMBER () OVER(PARTITION BY DeclarationID ORDER BY IsLastFromBudget DESC, NoBudget DESC)	RowNumber,					-- OTIBSUB 1904 fix
				DeclarationID,															-- OTIBSUB 1904 fix
				IsLastFromBudget,														-- OTIBSUB 1904 fix
				NoBudget																-- OTIBSUB 1904 fix
		FROM	(																		-- OTIBSUB 1904 fix
					SELECT	DISTINCT prd.DeclarationID,
						CAST(
							CASE WHEN
								(
									SELECT	COUNT(dp.PartitionID)
									FROM	sub.tblDeclaration_Partition dp
									WHERE	prd.PartitionID = dp.PartitionID
									AND		dp.PartitionStatus IN ('0010', '0012', '0014')
									AND		dp.PartitionAmountCorrected > 0 
									AND		dp.PartitionAmountCorrected <> dp.PartitionAmount
								) > 0 THEN 1 ELSE 0 END AS bit) IsLastFromBudget,
						CAST(
							CASE WHEN
								(
									SELECT	COUNT(dp.PartitionID)
									FROM	sub.tblDeclaration_Partition dp
									WHERE	prd.PartitionID = dp.PartitionID
									AND		dp.PartitionStatus = '0028'
									AND		dp.PartitionAmountCorrected = 0
								) > 0 THEN 1 ELSE 0 END AS bit) NoBudget

					FROM	sub.tblPaymentRun_Declaration prd
					INNER JOIN @DeclarationAmount da
					ON	    da.PaymentRunID = prd.PaymentRunID
					AND	    da.DeclarationID = prd.DeclarationID
				)	OTIBSUB_1904														-- OTIBSUB 1904 fix
	)
,
-- >>> OTIBSUB 1904
cteDeclaration
AS
(
	SELECT	DISTINCT 
			decl.DeclarationID										decl_DeclarationID,
			CASE WHEN dep.PartitionStatus IN ('0007', '0017') 
				THEN 1 
				ELSE 0 
			END														IsRejected,
								
			decl.DeclarationDate									decl_DeclarationDate,
			decl.CourseName											decl_CourseName,
			decl.StartDate											decl_StartDate,
			decl.DeclarationAmount									decl_DeclarationAmount,
			tpa.FromBudget + tpa.Voucheramount						tpa_PaidAmount,
			tpa.FromBudget											tpa_BudgetAmount,
			tpa.Voucheramount										tpa_Voucheramount,
			dc.IsLastFromBudget										dc_IsLastFromBudget,
			dc.NoBudget												dc_NoBudget
    FROM	@DeclarationAmount decl
	INNER JOIN	sub.tblDeclaration_Partition dep 
			ON	dep.DeclarationID = decl.DeclarationID
    INNER JOIN	sub.tblSubsidyScheme subs 
			ON	subs.SubsidySchemeID = decl.SubsidySchemeID
    INNER JOIN	cteTotalPaymentrunAmount tpa
			ON	tpa.DeclarationID = decl.DeclarationID
			AND	tpa.PaymentRunID = decl.PaymentRunID
    INNER JOIN	cteDeclarationCommentary dc 
			ON	dc.DeclarationID = decl.DeclarationID
			AND	dc.RowNumber = 1
)
-- <<< OTIBSUB 1904
-- >>> OTIBSUB 1904

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
					(	
						SELECT	SUM(tda.FromBudget + tda.Voucheramount)
						FROM	cteTotalDeclarationAmount tda
						INNER JOIN cteTotalPaymentrunAmount tpa
						ON	    tpa.PaymentRunID = tda.PaymentRunID
						AND	    tpa.DeclarationID = tda.DeclarationID

					)																	TotalAmount,
					(
						SELECT
								decl_DeclarationID										"@Number",
								IsRejected												IsRejected,
								(
									SELECT 	RejectionReason								"@id",
											RejectionXML								RejectionXML
									FROM	@Declaration_Rejection dr
									WHERE	dr.DeclarationID = decl_DeclarationID
									FOR XML PATH('RejectionReason'), TYPE
								)														RejectionReasons, 
								decl_DeclarationDate									DeclarationDate,
								decl_CourseName											CourseName,
								decl_StartDate											StartDate,
								decl_DeclarationAmount									DeclarationAmount,
								tpa_PaidAmount											PaidAmount,
								tpa_BudgetAmount										BudgetAmount,
								tpa_Voucheramount										Voucheramount,
								(
									SELECT	pa.EmployeeNumber							"@Number",
											emp.FullName								EmployeeName,
											emp.DateOfBirth							 	DateOfBirth,
											SUM(pa.FromBudget)							FromBudget,
											SUM(pa.VoucherAmount)						Voucher
									FROM	@PartitionEmployee pa
									INNER JOIN sub.tblEmployee emp 
									ON      emp.EmployeeNumber = pa.EmployeeNumber 
									INNER JOIN sub.tblJournalEntryCode jec 
                                    ON      jec.PaymentRunID = pa.PaymentRunID
									WHERE	pa.DeclarationID = decl_DeclarationID
									AND		jec.JournalEntryCode = @JournalEntryCode 
									GROUP BY 
                                            pa.PartitionID,
											pa.EmployeeNumber,
											emp.FullName,
											emp.DateOfBirth	
									FOR XML PATH('Employee'), ROOT ('Employees'), TYPE
								),
								dc_IsLastFromBudget									IsLastFromBudget,
								dc_NoBudget											NoBudget
                        FROM	cteDeclaration decl						
						ORDER BY 
                                decl_DeclarationID
                        FOR XML PATH('Declaration'), ROOT ('Declarations'), TYPE
                    ) 
			FOR XML PATH('JournalEntryCode')
		)
		-- <<< OTIBSUB 1904

		-- >>> OTIBSUB 1904
						--SELECT
						--		decl.DeclarationID										"@Number",
						--		CASE WHEN dep.PartitionStatus IN ('0007', '0017') 
						--			THEN 1 
						--			ELSE 0 
						--		END
						--																IsRejected,
						--		CAST(
						--		(
						--			SELECT 	RejectionReason								"@id",
						--					RejectionXML								RejectionXML
						--			FROM	@Declaration_Rejection dr
						--			WHERE	dr.DeclarationID = decl.DeclarationID
						--			FOR XML PATH('RejectionReason'), TYPE
						--		)
						--		AS varchar(max))										RejectionReasons, 
						--		decl.DeclarationDate									DeclarationDate,
						--		decl.CourseName											CourseName,
						--		decl.StartDate											StartDate,
						--		decl.DeclarationAmount									DeclarationAmount,
						--		tpa.FromBudget + tpa.Voucheramount						PaidAmount,
						--		tpa.FromBudget											BudgetAmount,
						--		tpa.Voucheramount										Voucheramount,
						--		CAST(
						--		(
						--			SELECT	pa.EmployeeNumber							"@Number",
						--					emp.FullName								EmployeeName,
						--					emp.DateOfBirth							 	DateOfBirth,
						--					SUM(pa.FromBudget)							FromBudget,
						--					SUM(pa.VoucherAmount)						Voucher
						--			FROM	@PartitionEmployee pa
						--			INNER JOIN sub.tblEmployee emp 
						--			ON      emp.EmployeeNumber = pa.EmployeeNumber 
						--			INNER JOIN sub.tblJournalEntryCode jec 
      --                              ON      jec.PaymentRunID = pa.PaymentRunID
						--			WHERE	pa.DeclarationID = decl.DeclarationID
						--			AND		jec.JournalEntryCode = @JournalEntryCode 
						--			GROUP BY 
      --                                      pa.PartitionID,
						--					pa.EmployeeNumber,
						--					emp.FullName,
						--					emp.DateOfBirth	
						--			FOR XML PATH('Employee'), ROOT ('Employees'), TYPE
						--		)
						--		AS nvarchar(MAX)),
						--		dc.IsLastFromBudget,
						--		dc.NoBudget
      --                  FROM	@DeclarationAmount decl
						--INNER JOIN	sub.tblDeclaration_Partition dep 
						--		ON	dep.DeclarationID = decl.DeclarationID
      --                  INNER JOIN	sub.tblSubsidyScheme subs 
						--		ON	subs.SubsidySchemeID = decl.SubsidySchemeID
      --                  INNER JOIN	cteTotalPaymentrunAmount tpa
						--		ON	tpa.DeclarationID = decl.DeclarationID
						--		AND	tpa.PaymentRunID = decl.PaymentRunID
      --                  INNER JOIN	cteDeclarationCommentary dc 
						--		ON	dc.DeclarationID = decl.DeclarationID
      --                  ORDER BY 
      --                          decl.DeclarationID
 --                       FOR XML PATH('Declaration'), ROOT ('Declarations'), TYPE
 --                   ) 
--			FOR XML PATH('JournalEntryCode')
--		)
		-- <<< OTIBSUB 1904

--SELECT @Specification

UPDATE	sub.tblJournalEntryCode 
SET		Specification = @Specification
WHERE	JournalEntryCode = @JournalEntryCode

SELECT	@XMLdel = NULL,
		@XMLins = (	SELECT 	*
					FROM	sub.tblJournalEntryCode 
					WHERE	JournalEntryCode = @JournalEntryCode
					FOR XML PATH
				  )

IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(@XMLins AS varchar(MAX))
BEGIN
	SET @KeyID = @JournalEntryCode

	EXEC his.uspHistory_Add
			'sub.tblJournalEntryCode',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspJournalEntryCode_Specification_Upd =================================================	*/
