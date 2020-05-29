CREATE PROCEDURE [ait].[uspDatabaseIntegrityCheck] 
AS
/*	==========================================================================================
	Purpose:	Checks the database integrity.

	13-01-2020	Sander van Houten	OTIBSUB-1825	Removed check on auth.tblLoginFailed.
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	04-11-2019	Sander van Houten	OTIBSUB-1674	Added check on length of vouchernumber.
	17-06-2019	Sander van Houten	OTIBSUB-1217	Initial version.
	==========================================================================================	*/

DECLARE @tblError TABLE 
(
	DeclarationID		int,
	SubsidySchemeID		int,
	ErrorDescription	varchar(max)
)


/*	Check on existance osr.tblDeclaration record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen OSR record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN osr.tblDeclaration dosr ON dosr.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND		d.SubsidySchemeID = 1
AND		dosr.DeclarationID IS NULL


/*	Check on existance evc.tblDeclaration record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen EVC record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN evc.tblDeclaration devc ON devc.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND		d.SubsidySchemeID = 3
AND		devc.DeclarationID IS NULL


/*	Check on existance stip.tblDeclaration record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen STIP record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN stip.tblDeclaration dstp ON dstp.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND		d.SubsidySchemeID = 4
AND		dstp.DeclarationID IS NULL


/*	Check on existance sub.tblDeclaration_Partition record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen partitie record aanwezig'	
			+ CASE WHEN d.SubsidySchemeID = 4
				THEN CASE WHEN edu.NominalDuration IS NULL 
						THEN ' (nominale duur niet bekend).'
						ELSE ' (nominale duur wel bekend).'
					 END
				ELSE ''
			  END	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
LEFT JOIN stip.tblDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblEducation edu ON edu.EducationID = stpd.EducationID
WHERE	d.DeclarationID > 400000
AND		dep.PartitionID IS NULL
AND		d.SubsidySchemeID <> 4

/*	Check on existance sub.tblDeclaration_Attachment record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen bijlage record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN sub.tblDeclaration_Attachment dat ON dat.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND		dat.AttachmentID IS NULL
-- Tijdelijk ivm OTIBSUB-1805.
AND     d.DeclarationID NOT IN 
    (
        414005,
        414006,
        414007,
        414008,
        414199,
        414200,
        414286,
        414289,
        414326,
        414361,
        414362,
        414375,
        414378,
        414380,
        414383,
        414387,
        414398,
        414401,
        414402,
        414403,
        414406,
        414407,
        414421,
        414428,
        414429,
        414451,
        414452,
        414462,
        414463,
        414464,
        414465
    )

/*	Check on existance sub.tblDeclaration_Employee record (OSR).	
	Notes:	There is no need for this record if it is an E-learning course.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen werknemer record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
INNER JOIN osr.tblDeclaration dosr ON dosr.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND		dosr.ElearningSubscription = 0
AND		dem.EmployeeNumber IS NULL


/*	Check on existance sub.tblDeclaration_Employee record (EVC/STIP).   */
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen werknemer record aanwezig.'	AS ErrorDescription
FROM	sub.tblDeclaration d
LEFT JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID > 400000
AND     d.SubsidySchemeID IN (3, 4, 5)
AND		dem.EmployeeNumber IS NULL
-- Tijdelijk ivm OTIBSUB-1805.
AND     d.DeclarationID NOT IN 
    (
        414005,
        414006,
        414007,
        414008,
        414199,
        414200,
        414286,
        414289,
        414326,
        414361,
        414362,
        414375,
        414378,
        414380,
        414383,
        414387,
        414398,
        414401,
        414402,
        414403,
        414406,
        414407,
        414421,
        414428,
        414429,
        414451,
        414452,
        414462,
        414463,
        414464,
        414465
    )


/*	Check on existance sub.tblDeclaration_Specification record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen specificatie record aanwezig voor betalingsrun ' 
			+ CAST(pad.PaymentRunID AS varchar(6)) + '.'	AS ErrorDescription
FROM	sub.tblPaymentRun_Declaration pad 
INNER JOIN sub.tblDeclaration d
ON		d.DeclarationID = pad.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep
ON		dep.PartitionID = pad.PartitionID
LEFT JOIN sub.tblDeclaration_Specification dsp
ON		dsp.PaymentRunID = pad.PaymentRunID
AND		dsp.DeclarationID = pad.DeclarationID
WHERE	pad.DeclarationID > 400000
AND		pad.PaymentRunID < 60026	-- From this paymentrun on the specifications are made per JournalEntryCode.
AND		dep.PartitionStatus <> '0017'
AND		dsp.SpecificationSequence IS NULL

/*	Check on existance sub.tblJournalEntryCode record.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Geen specificatie record aanwezig voor betalingsrun ' 
			+ CAST(pad.PaymentRunID AS varchar(6))
			+ ' (Notanummer ' + CAST(pad.JournalEntryCode AS varchar(8))
			+ ').'	AS ErrorDescription
FROM	sub.tblPaymentRun_Declaration pad 
INNER JOIN sub.tblDeclaration d
ON		d.DeclarationID = pad.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep
ON		dep.PartitionID = pad.PartitionID
LEFT JOIN sub.tblJournalEntryCode jec
ON		jec.PaymentRunID = pad.PaymentRunID
AND		jec.JournalEntryCode = pad.JournalEntryCode
WHERE	pad.DeclarationID > 400000
AND		pad.PaymentRunID >= 60026	-- From this paymentrun on the specifications are made per JournalEntryCode.
AND		dep.PartitionStatus <> '0017'
AND		jec.JournalEntryCode IS NULL

/*	Check on non-filled specifications for declarations that have been in a paymentrun (1).	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Een lege specificatie aanwezig voor betalingsrun ' 
		    + CAST(dsp.PaymentRunID AS varchar(6)) + '.'	AS ErrorDescription
FROM	sub.tblDeclaration_Specification dsp
INNER JOIN sub.tblDeclaration d 
ON      d.DeclarationID = dsp.DeclarationID
INNER JOIN sub.tblPaymentRun_Declaration pad 
ON      pad.PaymentRunID = dsp.PaymentRunID
AND     pad.DeclarationID = dsp.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep
ON      dep.PartitionID = pad.PartitionID
WHERE	dsp.PaymentRunID > 60000
AND		dsp.PaymentRunID < 60026	-- From this paymentrun on the specifications are made per JournalEntryCode.
AND		dep.PartitionStatus IN ('0010', '0012', '0014')
AND		dsp.Specification IS NULL
AND		( dsp.SumPartitionAmount <> 0.00 OR dsp.SumVoucherAmount <> 0.00 )

/*	Check on non-filled specifications for declarations that have been in a paymentrun (2).	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID,
		d.SubsidySchemeID,
		'Een lege specificatie aanwezig voor betalingsrun ' 
			+ CAST(pad.PaymentRunID AS varchar(6))
			+ ' (Notanummer ' + CAST(pad.JournalEntryCode AS varchar(8))
			+ ').'	AS ErrorDescription
FROM	sub.tblPaymentRun_Declaration pad
INNER JOIN sub.tblJournalEntryCode jec 
ON		jec.PaymentRunID = pad.PaymentRunID
AND		jec.JournalEntryCode = pad.JournalEntryCode
INNER JOIN sub.tblDeclaration d
ON		d.DeclarationID = pad.DeclarationID
INNER JOIN sub.tblDeclaration_Partition dep
ON      dep.PartitionID = pad.PartitionID
WHERE	pad.PaymentRunID > 60000
AND		pad.PaymentRunID >= 60026	-- From this paymentrun on the specifications are made per JournalEntryCode.
AND		dep.PartitionStatus IN ('0010', '0012', '0014')
AND		jec.Specification IS NULL

/*	Check on presents of InstituteName.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	NULL	AS DeclarationID,
		NULL	AS SubsidySchemeID,
		'Geen gevulde naam bij instituut ' 
			+ CAST(InstituteID AS varchar(6)) + '.'	AS ErrorDescription
FROM	sub.tblInstitute
WHERE	COALESCE(InstituteName, '') = ''


/*	Check on approved declarations with 0 euro payment.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	d.DeclarationID, 
		d.SubsidySchemeID, 
		'Declaratie is goedgekeurd, maar betaald 0 euro uit.'
FROM	sub.tblDeclaration_Partition dep
INNER JOIN sub.tblDeclaration d
		ON	d.DeclarationID = dep.DeclarationID
LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv 
		ON	dpv.DeclarationID = dep.DeclarationID 
		AND	dpv.PartitionID = dep.PartitionID
WHERE	dep.PartitionAmount <> 0.00 
AND		dep.PartitionAmountCorrected = 0.00
AND		dep.PartitionStatus IN ('0009', '0010', '0016')
AND		dpv.VoucherNumber IS NULL

/*	Check on vouchers imported from Horus with a number containing more than 3 characters.	*/
INSERT INTO @tblError
	(
		DeclarationID,
		SubsidySchemeID,
		ErrorDescription
	)
SELECT	vou.VoucherNumber, 
		1, 
		'Waardeboncode bestaat uit meer dan 6 karakters.'
FROM	hrs.tblVoucher vou
WHERE	LEN(vou.VoucherNumber) > 6

/*  Check on system failure logs.   */
/*  Removed check (OTIBSUB-1825).   */
-- INSERT INTO @tblError
-- 	(
-- 		DeclarationID,
-- 		SubsidySchemeID,
-- 		ErrorDescription
-- 	)
-- SELECT  0,
--         0,
--         'Systeemfout -> Laatste log: ' 
--             + CONVERT(varchar(10), MAX(LoginDateTime), 105) + ' ' + CONVERT(varchar(10), MAX(LoginDateTime), 108)
--             + ', Aantal logs: ' + CAST(COUNT(1) AS varchar(6))
--             + ', Melding: ' + ExtraInfo
-- FROM    auth.tblLoginFailed
-- WHERE   FailureReason = 3
-- AND     LoginDateTime > DATEADD(D, -1, CAST(GETDATE() AS date))
-- GROUP BY 
--         ExtraInfo

/*	Remove error because of known issues we will not fix.	*/
-- See OTIBSUB-1216/1219.
DELETE 
FROM	@tblError
WHERE	DeclarationID IN (403045,403674)

--select * from @tblError

/*	Send an e-mail to support@ambitionit.nl if errors are present.	*/
IF (SELECT COUNT(1) FROM @tblError) > 0
BEGIN
	DECLARE @DeclarationNumber	varchar(6),
			@SubsidySchemeName	varchar(4),
			@ErrorDescription	varchar(max),
			@EmailHeaders		xml,
			@EmailBody			varchar(max)

	DECLARE cur_Error CURSOR FOR 
		SELECT 
			CAST(DeclarationID AS varchar(6)),
			CASE SubsidySchemeID
				WHEN 1 THEN 'OSR'
				WHEN 2 THEN 'BPV'
				WHEN 3 THEN 'EVC'
				WHEN 4 THEN 'STIP'
				WHEN 5 THEN 'EVC-WV'
				ELSE 'Algemeen'
			END,
			ErrorDescription
		FROM @tblError
	
	SET @EmailHeaders = N'<headers>
						<header key="subject" value="Foutmeldingen bij integriteitscheck OTIB-DS PRD" />
						<header key="to" value="support@ambitionit.nl" />
						</headers>'

	SET @EmailBody = '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste afdeling Support,' +
					 '<br><br>' +
					 'De volgende integriteitsproblemen zijn geconstateerd:' + 
					 '<br><br>' +
					 '<table cellspacing="0" cellpadding="0" border="0" width="700">' +
					 '<tr><td width="80">Declaratie</td><td width="70">Regeling</td><td width="550">Foutomschrijving</td></tr>'

	OPEN cur_Error

	FETCH NEXT FROM cur_Error INTO @DeclarationNumber, @SubsidySchemeName, @ErrorDescription

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @EmailBody = @EmailBody +
			'<tr><td width="80">' + @DeclarationNumber + '</td>' +
			'<td width="70">' + @SubsidySchemeName + '</td>' +
			'<td width="550">' + @ErrorDescription + '</td></tr>'

		FETCH NEXT FROM cur_Error INTO @DeclarationNumber, @SubsidySchemeName, @ErrorDescription
	END

	CLOSE cur_Error
	DEALLOCATE cur_Error

	SET @EmailBody = @EmailBody + '</table></p>'

	INSERT INTO eml.tblEmail (EmailHeaders, EmailBody) VALUES (@EmailHeaders, @EmailBody)
END
/*	== ait.uspDatabaseIntegrityCheck =========================================================	*/
