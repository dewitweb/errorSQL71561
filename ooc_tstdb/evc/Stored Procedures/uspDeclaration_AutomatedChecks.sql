CREATE PROCEDURE [evc].[uspDeclaration_AutomatedChecks]
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on all declaration with status "Ingediend" or 
				"Nieuwe opleiding afgehandeld"

	Notes:		The source document of the checks is 
				"04b 20181027 HM OTIB Subsidiesysteem deel 04b subsidieregeling EVC versie 1.5"

	21-01-2020	Sander van Houten	OTIBSUB-1838	Corrected check on membership.
	12-11-2019	Sander van Houten	OTIBSUB-1696	Removed check on IBAN.
	07-11-2019	Jaap van Assenbergh	OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	24-10-2019	Sander van Houten	OTIBSUB-1633	If there is a paymentarrear 
                                        directly remove all other rejection reasons.
	16-09-2019	Sander van Houten	OTIBSUB-1572	If there is a paymentarrear 
										reject the declaration temporarily.
	16-08-2019	Sander van Houten	OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	12-07-2019	Jaap van Assenbergh	OTIBSUB-1361	Verhoging EVC500 tegemoetkoming
	19-06-2019	Sander van Houten	OTIBSUB-1229	Also check if employee has employment
										with daughter companies. 
	29-05-2019	Jaap van Assenbergh	OTIBSUB-1132	Definitie van 'Actieve BPV's'
	21-05-2019	Jaap van Assenbergh	OTIBSUB-1078	Routing tussen DS en Etalage wijzigen
	19-04-2019	Jaap van Assenbergh	OTIBSUB-850		Bedrag uitbetaling in de toekomst niet tonen.
	02-04-2019	Sander van Houten	OTIBSUB-851		Adjust PartitionAmountCorrected to 0 
										if rejected.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	06-02-2019	Jaap van Assenbergh	OTIBSUB-755		RejectionReason 0019 IBAN unknown
	30-01-2019	Sander van Houten	OTIBSUB-674		Automatically correct the partition amount 
										if declaration amount is higher then the limit.
	22-11-2018	Jaap van Assenbergh	OTIBSUB-472		Declaratie status 0001 wordt niet opgepakt 
										als de startdatum actueel wordt.
	08-11-2018	Jaap van Assenbergh	Initial version.

	==========================================================================================	*/

DECLARE @Count int = 0

DECLARE @XMLdel				xml,
		@XMLins				xml,
		@LogDate			datetime = GETDATE(),
		@DeclarationID		int,
		@Accepted			bit,
		@CorrectionAmount	decimal(19,2)

DECLARE @SubsidySchemeName	varchar(50) = 'EVC'
DECLARE @SubsidySchemeID	int
DECLARE @GetDate			date = GETDATE()
DECLARE @EmployerNumber		varchar(6)
DECLARE @EVCYear			varchar(4)

SELECT	@SubsidySchemeID = SubsidySchemeID
FROM	sub.tblSubsidyScheme
WHERE	SubsidySchemeName= @SubsidySchemeName

DECLARE @tblCheckedDeclarations TABLE (
	DeclarationID		int NOT NULL INDEX IC_chdDeclarationID Clustered,
	PartitionID			int NOT NULL,
	Accepted			bit NOT NULL,
	CorrectionAmount	decimal(19,2) NOT NULL )

DECLARE @tblRejectedDeclarations TABLE (
	DeclarationID	int NOT NULL INDEX IC_rdDeclarationID Clustered,
	PartitionID		int NOT NULL,
	RejectionReason varchar(24) NOT NULL,
	RejectionXML	xml NULL )

--DECLARE @startDate datetime2 
--SET @startDate = SysDateTime()
--DECLARE @nowDate datetime2 
--SET @nowDate = SysDateTime()

--PRINT '-Starttijd: ' + CAST(@startDate as varchar(20))

/*	Select all declarations that have a DeclarationStatus 
	0001 and startdate less then today, 0002 (Ingediend)  */
INSERT INTO @tblCheckedDeclarations
	(
		DeclarationID,
		PartitionID,
		Accepted,
		CorrectionAmount
	)
SELECT	decl.DeclarationID,
		dep.PartitionID,
		1,	-- Accepted until selected for a rejection reason
		0.00
FROM	evc.viewDeclaration decl
INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
WHERE	decl.PartitionStatus IN ('0001', '0002')
AND		IntakeDate <= @GetDate
AND		decl.SubsidySchemeID = @SubsidySchemeID
AND		ISNULL(decl.InstituteID, 0) > 0

--PRINT '-SQL statement: ' + CAST(DATEDIFF(millisecond, @nowDate, SysDateTime()) as varchar(20)) + ' Ms'
--SET @nowDate = SysDateTime()

IF @@ROWCOUNT > 0
BEGIN

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	/*	
		Werknemer heeft op datum certificaat een actieve BPV	Zie ‘Combinatie van regelingen’ in deeldocument 02.
		Werknemer heeft op intakedatum een actieve BPV	Zie ‘Combinatie van regelingen’ in deeldocument 02.
		
		0007. De declaratie moet binnen een jaar na de certificaatdatum worden ingediend.
		0008. Instituut is vervallen	
		0009. Overschrijding bedrag EVC500(€1250)/EVC(€500). 
		0010. Werkgever geen lid op datum certificaat	
		0011. Werknemer niet in dienst bij werkgever op datum certificaat	
		0012. Op intakedatum in loondienst.

		0013. Het maximum van 20% van werknemers is overschreden EVC
			of
			 Max aantal overschreden EVC 500 (25 bij < 50 en 50 bij > 50)		

		0014. EVC wordt maar eens in de 5 jaar gesubsidieerd	
		0015. Maximum van 500 EVC500 trajecten overschreden	
		0016. Werknemer heeft op intakedatum een actieve BPV
		0017. Werknemer heeft op datum certificaat een actieve BPV
		0019

	*/

	/*	Check on payment arrears.
	REGELS
	1.	De declarant mag geen betalingsachterstand hebben.

	NOTEN
	1.	De declarant heeft daadwerkelijk een betalingsachterstand óf 
		er is nog geen update van MN ontvangen waarin de betalingsachterstand is ingelopen.	
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID,
			chd.PartitionID,
			'0004'									RejectionReason,
			(SELECT	
					(SELECT	decl.EmployerNumber		"@Number",
							pa.FeesPaidUntill		DocumentDate
						FOR XML PATH('Employer'), TYPE
					)
				FOR XML PATH('PaymentArrears'), ROOT('Rejection')
			)									AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN	sub.tblDeclaration_Partition dep ON dep.DeclarationID = chd.DeclarationID
	INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = dep.DeclarationID
	INNER JOIN sub.tblPaymentArrear pa ON pa.EmployerNumber = decl.EmployerNumber
	AND		DATEDIFF(d, pa.FeesPaidUntill, GETDATE()) > 30

	/*	0007 Check on Declaration within a year after certification
	REGELS
	De definitie is:
	De declaratie moet binnen een jaar na de certificaatdatum worden ingediend.
	*/

	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0007'											AS RejectionReason,
			(
				SELECT	
						CAST(decl.DeclarationDate AS date)	AS DeclarationDate,
						decl.Certificationdate				AS CertificationDate
				FOR XML PATH('Overdue'), ROOT ('Rejection')
			)
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE	decl.DeclarationDate > DATEADD(YEAR, 1, decl.Certificationdate)

	/*	0008 Check on Institute for EVC	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0008'											AS RejectionReason,
			(SELECT	
					(
						SELECT	decl.InstituteID			AS "@Number"
						FOR XML PATH('Intitute'), TYPE
					)
			 FOR XML PATH('Expired'), ROOT('Rejection')
			)												AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN sub.tblDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	LEFT JOIN sub.tblSubsidyScheme_Institute ssi
			ON ssi.InstituteID = decl.InstituteID
			AND	ssi.SubsidySchemeID = @SubsidySchemeID
	WHERE ssi.InstituteID IS NULL 

	/*	0009 Check on Limit per SubsidiyType for EVC	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID,
			chd.PartitionID,
			'0009'													AS RejectionReason,
			(SELECT	
					(
						SELECT	sapt.SettingCode					AS SubsidyType,
								sapt.SubsidyAmount					AS SubsidyAmount,
								decl.DeclarationAmount				AS DeclarationAmount
						FROM	sub.viewApplicationSetting_SubsidyAmountPerType sapt
						WHERE	sapt.SettingCode = CASE WHEN decl.IsEVC500 = 1 THEN 'EVC500' ELSE 'EVC' END
						AND		decl.IntakeDate BETWEEN ISNULL(sapt.StartDate, decl.IntakeDate) AND ISNULL(sapt.EndDate, decl.IntakeDate)
					 FOR XML PATH('Limit'), TYPE
					)
					--(	SELECT	SettingCode							AS SubsidyType,
					--			CAST(SettingValue as Money)			AS SubsidyAmount,
					--			decl.DeclarationAmount				AS DeclarationAmount
					--	FROM	sub.tblApplicationSetting aps 
					--	WHERE	aps.SettingName = 'SubsidyAmountPerType' 
					--	AND		SettingCode = CASE WHEN decl.IsEVC500 = 1 THEN 'EVC500' ELSE 'EVC' END
					-- FOR XML PATH('Limit'), TYPE
					--)
			 FOR XML PATH('Rejection')
			)														AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE decl.DeclarationAmount >
		(
			SELECT	sapt.SubsidyAmount
			FROM	sub.viewApplicationSetting_SubsidyAmountPerType sapt
			WHERE	sapt.SettingCode = CASE WHEN decl.IsEVC500 = 1 THEN 'EVC500' ELSE 'EVC' END
			AND		decl.IntakeDate BETWEEN ISNULL(sapt.StartDate, decl.IntakeDate) AND ISNULL(sapt.EndDate, decl.IntakeDate)
		)

	/*	0010 Check on Employee is member	
	REGELS
	De definitie is:
	Werkgever geen lid op datum certificaat
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0010'										AS RejectionReason,
			(
				SELECT	emr.[EndDateMembership]			AS EndDateMembership
				FOR XML PATH('Rejection'), TYPE
			)											AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	INNER JOIN sub.tblEmployer emr
			ON emr.EmployerNumber = decl.EmployerNumber
	WHERE	decl.CertificationDate NOT BETWEEN emr.StartDateMembership AND ISNULL(emr.EndDateMembership, decl.CertificationDate)

	/*	0011 Check on Employer in wage labor on Certification date
	REGELS
	De definitie is:
	Werkgever moet in loondienst zijn op de certificatiedatum
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0011'											AS RejectionReason,
			(
				SELECT	decl.CertificationDate				AS CertificationDate,
						(
							SELECT	TOP 1 ee.StartDate, ee.EndDate
							FROM	sub.tblEmployer_Employee ee
							WHERE	ee.EmployerNumber = decl.EmployerNumber
							AND		ee.EmployeeNumber = decl.EmployeeNumber
							AND		ee.EndDate < decl.CertificationDate
							ORDER BY ee.Enddate DESC
							FOR XML PATH('Contract'), TYPE
						)
				FOR XML PATH('Rejection'), TYPE
			)												AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE NOT EXISTS	
			(
				SELECT	ee.EmployeeNumber
				FROM	sub.tblEmployer_Employee ee
				WHERE	ee.EmployerNumber = decl.EmployerNumber
				AND		ee.EmployeeNumber = decl.EmployeeNumber
				AND		decl.CertificationDate BETWEEN ee.StartDate AND COALESCE(ee.EndDate, '2099-01-01')
			)
	AND	 NOT EXISTS		-- OTIBSUB-1229
			(
				SELECT	ee.EmployeeNumber
				FROM	sub.tblEmployer_ParentChild epa
				INNER JOIN sub.tblEmployer_Employee ee ON ee.EmployerNumber = epa.EmployerNumberChild
				WHERE	epa.EmployerNumberParent = decl.EmployerNumber
				AND		ee.EmployeeNumber = decl.EmployeeNumber
				AND		decl.CertificationDate BETWEEN epa.StartDate AND COALESCE(epa.EndDate, '2099-01-01')
				AND		decl.CertificationDate BETWEEN ee.StartDate AND COALESCE(ee.EndDate, '2099-01-01')
			)

	/*	0012 Check on Employer in wage labor on Intake date
	REGELS
	De definitie is:
	Werknemer moet in loondienst zijn op de intakedatum
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0012'											AS RejectionReason,
			(
				SELECT	decl.IntakeDate						AS IntakeDate,
						(							
							SELECT	TOP 1 ee.StartDate, ee.EndDate
							FROM	sub.tblEmployer_Employee ee
							WHERE	ee.EmployerNumber = decl.EmployerNumber
							AND		ee.EmployeeNumber = decl.EmployeeNumber
							AND		ee.StartDate > decl.IntakeDate
							ORDER BY ee.StartDate 		
							FOR XML PATH('Contract'), TYPE
						)
				FOR XML PATH('Rejection'), TYPE
			)												AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE NOT EXISTS	
			(
				SELECT	ee.EmployeeNumber
				FROM	sub.tblEmployer_Employee ee
				WHERE	ee.EmployerNumber = decl.EmployerNumber
				AND		ee.EmployeeNumber = decl.EmployeeNumber
				AND		decl.IntakeDate BETWEEN ee.StartDate AND COALESCE(ee.EndDate, '2099-01-01')
			)
	AND	 NOT EXISTS		-- OTIBSUB-1229	
			(
				SELECT	ee.EmployeeNumber
				FROM	sub.tblEmployer_ParentChild epa
				INNER JOIN sub.tblEmployer_Employee ee ON ee.EmployerNumber = epa.EmployerNumberChild
				WHERE	epa.EmployerNumberParent = decl.EmployerNumber
				AND		ee.EmployeeNumber = decl.EmployeeNumber
				AND		decl.IntakeDate BETWEEN epa.StartDate AND COALESCE(epa.EndDate, '2099-01-01')
				AND		decl.IntakeDate BETWEEN ee.StartDate AND COALESCE(ee.EndDate, '2099-01-01')
			)

	/*	First rejections without counts of declarations 
		0013 and 0015 are with count of declarations	*/

	/* 0014 Check for declarations in set period.
	REGELS
	De definitie is:
	"De declaratie wordt ingediend voor dezelfde werknemer, ongeacht werkgever, binnen 5 jaar na de vorige EVC."
	EmployeeNumber zou kunnen komen te vervallen. Eén declaratie in EVC is één medewerker.
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0014'											AS RejectionReason,
			(SELECT	
					(
						SELECT	DISTINCT s_dupdecl.EmployeeNumber	AS "@Number",
								'OTIB-DS'					AS SourceSystem,
								s_dupdecl.DeclarationID		AS DeclarationID,
								s_dupdecl.IntakeDate		AS IntakeDate	
						 FROM	evc.viewDeclaration s_decl
						 INNER JOIN evc.viewDeclaration s_dupdecl
								ON	s_dupdecl.DeclarationID = dupdecl.DeclarationID

						 FOR XML PATH('Employee'), TYPE
					)
			 FOR XML PATH('SetPeriod'), ROOT('Rejection')
			)										AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON	decl.DeclarationID = chd.DeclarationID
	INNER JOIN evc.viewDeclaration dupdecl
			ON	dupdecl.EmployeeNumber = decl.EmployeeNumber
			AND	DATEADD(YEAR, 5, dupdecl.IntakeDate) > decl.IntakeDate
	LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
			ON	der.DeclarationID = decl.DeclarationID
	WHERE	dupdecl.DeclarationID <> decl.DeclarationID
--	  AND	dupdecl.DeclarationStatus NOT IN ('0007', '0017')
	AND		dupdecl.DeclarationID IN													-- OTUBSUB-1539
					(
						SELECT	dep.DeclarationID 
						FROM	sub.tblDeclaration_Partition dep 
						WHERE	PartitionStatus NOT IN ('0007', '0017')
						AND		dep.DeclarationID  = dupdecl.DeclarationID
					)
	  AND	der.ReversalPaymentID IS NULL
	GROUP BY decl.DeclarationID, chd.PartitionID, dupdecl.DeclarationID
	UNION ALL												-- Uit Horus
	SELECT	chd.DeclarationID,
			chd.PartitionID,
			'0014'											AS RejectionReason,
			(
				SELECT	
						(
							SELECT	s_evc.EmployeeNumber		AS "@Number",
									'Horus'						AS SourceSystem,
									s_evc.DeclarationNumber		AS DeclarationID,
									s_evc.IntakeDate			AS IntakeDate	
							FROM	hrs.tblEVC s_evc 
							WHERE	s_evc.DeclarationNumber = evc.DeclarationNumber
							FOR XML PATH('Employee'), TYPE
						)
				 FOR XML PATH('SetPeroid'), ROOT('Rejection')
			)										AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
				ON	decl.DeclarationID = chd.DeclarationID
	INNER JOIN hrs.tblEVC evc 
				ON evc.EmployeeNumber = decl.EmployeeNumber
				AND	DATEADD(YEAR, 5, evc.IntakeDate) > decl.IntakeDate
				AND	evc.DeclarationStatus = 'UB'

	/*	0016. Werknemer heeft op intakedatum een actieve BPV
	REGELS
	De definitie is:
	Werknemer heeft op intakedatum een actieve BPV
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0016'											AS RejectionReason,
			(
				SELECT	decl.IntakeDate						AS IntakeDate,
						(
							SELECT	TOP 1 
									bpv.StartDate, 
									bpv.EndDate
							FROM	hrs.viewBPV bpv
							WHERE	bpv.EmployeeNumber = decl.EmployeeNumber
							AND		decl.IntakeDate BETWEEN bpv.StartDate AND COALESCE(bpv.EndDate, decl.IntakeDate)
							ORDER BY bpv.Enddate DESC
							FOR XML PATH('BPV'), TYPE
						)
				FOR XML PATH('Rejection'), TYPE
			)												AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE EXISTS	
			(
				SELECT	bpv.EmployeeNumber
				FROM	hrs.viewBPV bpv
				WHERE	bpv.EmployeeNumber = decl.EmployeeNumber
				AND		(
							(
								bpv.EndDate IS NOT NULL 
							AND	decl.IntakeDate BETWEEN bpv.StartDate AND bpv.EndDate
							)
							OR	(	bpv.EndDate IS NULL 
								AND	bpv.StartDate <= decl.IntakeDate
								)						
						)
			)

	/*	0017. Werknemer heeft op CertificationDate een actieve BPV
	REGELS
	De definitie is:
	Werknemer heeft op CertificationDate een actieve BPV
	*/
	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
	SELECT	decl.DeclarationID, 
			chd.PartitionID,
			'0017'											AS RejectionReason,
			(
				SELECT	decl.CertificationDate				AS CertificationDate,
						(
							SELECT	TOP 1 
									bpv.StartDate, 
									bpv.EndDate
							FROM	hrs.viewBPV bpv
							WHERE	bpv.EmployeeNumber = decl.EmployeeNumber
							AND		decl.CertificationDate BETWEEN bpv.StartDate AND COALESCE(bpv.EndDate, decl.CertificationDate)
							ORDER BY bpv.Enddate DESC
							FOR XML PATH('BPV'), TYPE
						)
				FOR XML PATH('Rejection'), TYPE
			)												AS RejectionXML
	FROM	@tblCheckedDeclarations chd
	INNER JOIN evc.viewDeclaration decl
			ON decl.DeclarationID = chd.DeclarationID
	WHERE EXISTS	
			(
				SELECT	bpv.EmployeeNumber
				FROM	hrs.viewBPV bpv
				WHERE	bpv.EmployeeNumber = decl.EmployeeNumber
				AND		(
							(
								bpv.EndDate IS NOT NULL 
							AND	decl.CertificationDate BETWEEN bpv.StartDate AND bpv.EndDate
							)
							OR	(	bpv.EndDate IS NULL 
								AND	bpv.StartDate <= decl.CertificationDate
								)						
						)
			)

	/*	0013 Check for percentage > 20 for EVC declarations only.
	REGELS
	De definitie is:
	"Er mag geen declaratie worden ingediend indien er meer dan 20% van de werknemenrs al een EVC declaratie in dat jaar heeft per werkgever.
	*/
	DECLARE @EVCPercentageLimit	int = 20
	
	DECLARE cur_EVC CURSOR FOR 
		SELECT	cd.DeclarationID, EmployerNumber, YEAR(decl.IntakeDate)					-- ‘Uitbetalen in jaar’ gaat uit van de intake datum OTIBSUB-469
		FROM	@tblCheckedDeclarations cd
		INNER JOIN evc.viewDeclaration decl ON decl.DeclarationID = cd.DeclarationID
		WHERE	IsEVC500 = 0
		ORDER BY DeclarationID															-- Wie het eerst komt, wie het eerst maalt OTIBSUB-469
	
	OPEN cur_EVC

	FETCH NEXT FROM cur_EVC INTO @DeclarationID, @EmployerNumber, @EVCYear

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @Count += 1
		;WITH cte_CountEmployeesByEmployer AS
		(
			SELECT	ed.EmployerNumber, COUNT(ed.EmployeeNumber) CountEmployee, CountEmployeeByEmployer
			FROM	evc.viewDeclaration ed
			INNER JOIN
					(
						SELECT	ee.EmployerNumber, COUNT(ee.EmployerNumber) CountEmployeeByEmployer
						FROM	sub.tblEmployer_Employee ee
						WHERE	ee.StartDate <= @EVCYear + '-12-31' 
						AND		ISNULL(ee.EndDate, @EVCYear + '-12-31') >=  @EVCYear + '-01-01'
						AND		ee.EmployerNumber = @EmployerNumber
						GROUP BY ee.EmployerNumber
					) a ON a.EmployerNumber = ed.EmployerNumber
			WHERE 	YEAR(IntakeDate) = @EVCYear							-- ‘Uitbetalen in jaar’ gaat uit van de intake datum OTIBSUB-469
			AND		IsEVC500 = 0
			--AND		ed.DeclarationStatus NOT IN ('0007', '0017')			
			AND		ed.DeclarationID IN													-- OTUBSUB-1539
					(
						SELECT	dep.DeclarationID 
						FROM	sub.tblDeclaration_Partition dep 
						WHERE	PartitionStatus NOT IN ('0007', '0017')
						AND		dep.DeclarationID  = ed.DeclarationID
					)
			AND		ed.DeclarationID NOT IN 
					(
						SELECT	rd.DeclarationID						-- Indien de eeste wordt afgekeurd deze niet meetellen bij de volgende. OTIBSUB-469
						FROM	@tblRejectedDeclarations rd
					)
			AND		ed.DeclarationID NOT IN								-- Bij meerdre declaraties de oudste eigen en nieuwere declkartie niet meetellen
					(
						SELECT	cd.DeclarationID
						FROM	@tblCheckedDeclarations cd
						WHERE	cd.DeclarationID >= @DeclarationID
					)
			GROUP BY ed.EmployerNumber, CountEmployeeByEmployer
		)

	INSERT INTO @tblRejectedDeclarations
			(	DeclarationID,
				PartitionID,
				RejectionReason,
				RejectionXML
			)
		SELECT	decl.DeclarationID,
				decl.PartitionID,
				'0013'											AS RejectionReason,
				(
					SELECT	(100/cnt.CountEmployeeByEmployer) * cnt.CountEmployee		AS [Percentage],
							@EVCPercentageLimit											AS Limit
					FOR XML PATH('Rejection'), TYPE
				)												AS RejectionXML
		FROM	evc.viewDeclaration decl
		INNER JOIN cte_CountEmployeesByEmployer cnt 
				ON cnt.EmployerNumber = decl.EmployerNumber 
				AND (100/cnt.CountEmployeeByEmployer) * cnt.CountEmployee > @EVCPercentageLimit
		WHERE	decl.DeclarationID = @DeclarationID

		FETCH NEXT FROM cur_EVC INTO @DeclarationID, @EmployerNumber, @EVCYear
	END

	CLOSE cur_EVC
	DEALLOCATE cur_EVC

	/*	Check for EVC500 declarations limit in one year.
	Noot. Deze controle als laatste uitvoeren i.v.m. mogelijke goedkeuringen binnnen één check.
	REGELS
	De definitie is:
	"De declaratie wordt ingediend voor dezelfde werknemer, ongeacht werkgever, binnen 5 jaar na de vorige EVC."
	*/
	DECLARE @EVC500Limit	int = 500
	DECLARE @Declarated		int

  	DECLARE @EVCEmployeesLimit			int = 50
  	DECLARE @EVCEmployeesLimitLower		int = 25
  	DECLARE @EVCEmployeesLimitHigher	int = 50

	DECLARE cur_EVC500 CURSOR FOR 
		SELECT	cd.DeclarationID, EmployerNumber, YEAR(decl.IntakeDate)					-- ‘Uitbetalen in jaar’ gaat uit van de intake datum OTIBSUB-469
		FROM	@tblCheckedDeclarations cd
		INNER JOIN evc.viewDeclaration decl ON decl.DeclarationID = cd.DeclarationID
		WHERE	IsEVC500 = 1
		ORDER BY DeclarationID															-- Wie het eerst komt, wie het eerst maalt OTIBSUB-469
	
	OPEN cur_EVC500

	FETCH NEXT FROM cur_EVC500 INTO @DeclarationID, @EmployerNumber, @EVCYear

	SET @Count = 0

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @Count += 1

		-- Max of 25 by less then 50 employees and 50 by more than 50 employees
		;WITH cte_CountEmployeesByEmployer AS
			(
				SELECT	ed.EmployerNumber, COUNT(ed.EmployeeNumber) CountEmployee, CountEmployeeByEmployer
				FROM	evc.viewDeclaration ed
				INNER JOIN
						(
							SELECT	ee.EmployerNumber, COUNT(ee.EmployerNumber) CountEmployeeByEmployer
							FROM	sub.tblEmployer_Employee ee
							WHERE	ee.StartDate <= @EVCYear + '-12-31' 
							AND		ISNULL(ee.EndDate, @EVCYear + '-12-31') >=  @EVCYear + '-01-01'
							AND		ee.EmployerNumber = @EmployerNumber
							GROUP BY ee.EmployerNumber
						) a ON a.EmployerNumber = ed.EmployerNumber
				WHERE 	YEAR(IntakeDate) = @EVCYear								-- ‘Uitbetalen in jaar’ gaat uit van de intake datum OTIBSUB-469
				AND		IsEVC500 = 1
				--AND		ed.DeclarationStatus NOT IN ('0007', '0017')			
				AND		ed.DeclarationID IN													-- OTUBSUB-1539
					(
						SELECT	dep.DeclarationID 
						FROM	sub.tblDeclaration_Partition dep 
						WHERE	PartitionStatus NOT IN ('0007', '0017')
						AND		dep.DeclarationID  = ed.DeclarationID
					)				
				AND		ed.DeclarationID NOT IN 
						(
							SELECT	rd.DeclarationID							-- Indien de eeste wordt afgekeurd deze niet meetellen bij de volgende. OTIBSUB-469
							FROM	@tblRejectedDeclarations rd
						)
				AND		ed.DeclarationID NOT IN									-- Bij meerdre declaraties de oudste eigen en nieuwere declkartie niet meetellen
						(
							SELECT	cd.DeclarationID
							FROM	@tblCheckedDeclarations cd
							WHERE	cd.DeclarationID >= @DeclarationID
						)

				GROUP BY ed.EmployerNumber, CountEmployeeByEmployer
			)

		INSERT INTO @tblRejectedDeclarations
				(	DeclarationID,
					PartitionID,
					RejectionReason,
					RejectionXML
				)
		SELECT	decl.DeclarationID,
				decl.PartitionID,
				'0013'											AS RejectionReason,
				(
					SELECT	CASE WHEN cnt.CountEmployeeByEmployer > @EVCEmployeesLimit THEN @EVCEmployeesLimitHigher ELSE @EVCEmployeesLimitLower END AS [Limit],
							cnt.CountEmployee AS CountOfEmployee
					FOR XML PATH('Rejection'), TYPE
				)												AS RejectionXML
		FROM	evc.viewDeclaration decl
		INNER JOIN cte_CountEmployeesByEmployer cnt 
				ON cnt.EmployerNumber = decl.EmployerNumber 
				AND cnt.CountEmployee >= CASE WHEN cnt.CountEmployeeByEmployer > @EVCEmployeesLimit THEN @EVCEmployeesLimitHigher ELSE @EVCEmployeesLimitLower END
		WHERE	decl.DeclarationID = @DeclarationID

		/*	0015 Check for maximum of 500 EVC 500 in a Year 
			First all other checks. This check must be the last step.
		*/ 
		-- Maximal 500 declarations a year
		SELECT @Declarated = SUM(Declarated) FROM 
				(
					SELECT	COUNT(1) Declarated
					FROM	evc.viewDeclaration  decl
					WHERE	SubsidySchemeID = @SubsidySchemeID
					--	DeclarationStatus IN ('0009', '0010', '0011', '0012', '0013', '0014', '0015')
					AND		decl.DeclarationID IN															-- OTUBSUB-1539
							(
								SELECT	DeclarationID 
								FROM	sub.tblDeclaration_Partition 
								WHERE	PartitionStatus IN ('0009', '0010', '0011', '0012', '0013', '0014', '0015')
							)
					AND		decl.IsEVC500 = 1
					AND		decl.EVCYear = @EVCYear
					UNION ALL
					SELECT	COUNT(1)
					FROM	evc.viewDeclaration  decl
					INNER JOIN @tblCheckedDeclarations chd ON chd.DeclarationID = decl.DeclarationID
					WHERE	decl.IsEVC500 = 1
					AND		decl.EVCYear = @EVCYear
					AND		decl.DeclarationID NOT IN 
							(
								SELECT	rd.DeclarationID
								FROM	@tblRejectedDeclarations rd
							)
					AND		decl.DeclarationID NOT IN									-- Bij meerdere declaraties de oudste eigen en nieuwere declaratie niet meetellen
							(
								SELECT	cd.DeclarationID
								FROM	@tblCheckedDeclarations cd
								WHERE	cd.DeclarationID >= @DeclarationID
							)
				) EVC500

		--SET @Declarated = 501

		INSERT INTO @tblRejectedDeclarations
				(	DeclarationID,
					PartitionID,
					RejectionReason,
					RejectionXML
				)
		SELECT	chd.DeclarationID, 
				chd.PartitionID,
				'0015'										AS RejectionReason,
				(SELECT	
						(
							SELECT	CAST(@EVC500Limit as varchar(4)) + '+'
							FOR XML PATH('EVC500Limit'), TYPE
						)
				 FOR XML PATH ('Rejection')
				)											AS RejectionXML
		FROM	@tblCheckedDeclarations chd
		WHERE	chd.DeclarationID = @DeclarationID
		AND		@Declarated > @EVC500Limit

		FETCH NEXT FROM cur_EVC500 INTO @DeclarationID, @EmployerNumber, @EVCYear
	END

	CLOSE cur_EVC500
	DEALLOCATE cur_EVC500

	/* Update records in @tblCheckedDeclarations */
	UPDATE	chk
	SET		chk.Accepted = 0
	FROM	@tblCheckedDeclarations chk
	INNER JOIN	@tblRejectedDeclarations rej	
			ON	rej.DeclarationID = chk.DeclarationID
	WHERE	rej.RejectionReason <> '0009'

	UPDATE	chk
	SET		chk.CorrectionAmount = rej.RejectionXML.value('(/Rejection/Limit/SubsidyAmount)[1]', 'decimal(19,2)')
	FROM	@tblCheckedDeclarations chk
	INNER JOIN	@tblRejectedDeclarations rej	
			ON	rej.DeclarationID = chk.DeclarationID
	WHERE	rej.RejectionReason = '0009'

	/* Create records for rejected declarations in sub.tblDeclaration_Rejection */
	INSERT INTO sub.tblDeclaration_Rejection
		(
			DeclarationID,
			PartitionID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
		)
	SELECT	DeclarationID,
			PartitionID,
			RejectionReason,
			@LogDate AS [RejectionDateTime],
			RejectionXML
	FROM	@tblRejectedDeclarations
	WHERE	RejectionReason <> '0009'
	ORDER BY	DeclarationID,
				RejectionReason

	/* Update DeclarationStatus of checked declarations*/
	DECLARE	@DeclarationStatus	varchar(4)
			
	DECLARE @RC							int,
			@PartitionID				int,
			@PartitionYear				varchar(20),
			@PartitionAmount			decimal(19,4),
			@PartitionAmountCorrected	decimal(19,4),
			@PaymentDate				date,
			@PartitionStatus			varchar(4)

	DECLARE cur_Checked CURSOR FOR 
		SELECT 
				DeclarationID,
				PartitionID,
				Accepted,
				CorrectionAmount
		FROM	@tblCheckedDeclarations
		
	OPEN cur_Checked

	FETCH FROM cur_Checked 
	INTO @DeclarationID, @PartitionID, @Accepted, @CorrectionAmount

	SET @Count = 0

	WHILE @@FETCH_STATUS = 0  
	BEGIN

		SET @Count += 1
		-- Save old record
		SELECT	@XMLdel = (SELECT * 
							FROM   sub.tblDeclaration 
							WHERE  DeclarationID = @DeclarationID
							FOR XML PATH)

		-- Update existing record.
		IF @Accepted = 0
		BEGIN
			IF (														-- Is there a reason for rejection 0004 present? 
					SELECT	COUNT(1)									-- For all subsidyschema's (OSR, EVC en STIP) Change it here, change it there.
					FROM	sub.tblDeclaration_Rejection				-- Change it here, change it there.
					WHERE	DeclarationID = @DeclarationID
					AND		PartitionID = @PartitionID
					AND		RejectionReason = '0004'
				) > 0
			BEGIN													
--				SET		@DeclarationStatus = '0018'						-- Tijdelijke afkeur
				SET		@PartitionStatus = '0018'						-- OTUBSUB-1539

                DELETE
                FROM    sub.tblDeclaration_Rejection
                WHERE	DeclarationID = @DeclarationID
                AND		PartitionID = @PartitionID
                AND		RejectionReason <> '0004'
			END
			ELSE
			BEGIN
				IF	(	SELECT	COUNT(1)
						FROM	sub.tblDeclaration d 
						INNER JOIN	sub.tblDeclaration_Rejection dr 
								ON	dr.DeclarationID = d.DeclarationID
						INNER JOIN	sub.viewApplicationSetting_RejectionReason asrr 
								ON	asrr.SettingCode = dr.RejectionReason
						WHERE	d.DeclarationID = @DeclarationID
						AND		asrr.NotShownInProcessList = 1
					) > 0
					--SET	@DeclarationStatus = '0007'
					SET	@PartitionStatus = '0007'
				ELSE
					--SET @DeclarationStatus = '0005'
					SET	@PartitionStatus = '0005'
			END
		END
		ELSE
		BEGIN
			--SET @DeclarationStatus = '0009'
			SET @PartitionStatus = '0009'
		END

		SELECT	@PartitionYear = PartitionYear,
				@PartitionAmount = PartitionAmount,
				@PartitionAmountCorrected =	CASE @Accepted
												WHEN 0 THEN 0.00
												ELSE CASE @CorrectionAmount 
														WHEN 0.00 THEN PartitionAmount --PartitionAmountCorrected
														ELSE @CorrectionAmount
														END
											END,
				@PaymentDate = PaymentDate
		--		@PartitionStatus = @DeclarationStatus
		FROM	sub.tblDeclaration_Partition
		WHERE	PartitionID = @PartitionID

		EXECUTE @RC = [sub].[uspDeclaration_Partition_Upd] 
				@PartitionID,
				@DeclarationID,
				@PartitionYear,
				@PartitionAmount,
				@PartitionAmountCorrected,
				@PaymentDate,
				@PartitionStatus,
				1	--1=Admin

		/*	Finally update Declaration.	*/
		SELECT @DeclarationStatus = sub.usfGetDeclarationStatusByPartition(@DeclarationID, @PartitionID, @PartitionStatus)

		EXEC sub.uspDeclaration_Upd_DeclarationStatus
			@DeclarationID,
			@DeclarationStatus,
			NULL,
			1		

		FETCH NEXT FROM cur_Checked 
		INTO @DeclarationID, @PartitionID, @Accepted, @CorrectionAmount
	END

	CLOSE cur_Checked
	DEALLOCATE cur_Checked

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

END

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evc.uspDeclaration_AutomatedChecks ====================================================	*/
