CREATE PROCEDURE [osr].[uspDeclaration_AutomatedChecks]
@StatusXML	xml = N''
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on all declaration with status "Ingediend" or 
				"Nieuwe opleiding afgehandeld"

	Notes:		The source document of the checks is 
				"04a 20180807 HM OTIB Subsidiesysteem deel 04a subsidieregeling OSR versie 1.6"
				OTIBSUB-296
				Declaraties voor de OSR kunnen ingediend worden voor alle werknemers,
				ongeacht hun leeftijd.	

	24-01-2020	Jaap van Assenbergh	OTIBSUB-1844	Declaratie 414034 nieuw instituut/cursus en status actief
	22-01-2020	Jaap van Assenbergh	OTIBSUB-1822	OSR Automated checks performance controleren.
	09-01-2020	Jaap van Assenbergh	OTIBSUB-1810	Added check on PartitionAmount and optional
                                        voucher(s).
	06-01-2020	Sander van Houten	OTIBSUB-1810	Added indication ExecuteFirstPartitionCheck.
	19-12-2019	Sander van Houten	OTIBSUB-1794	Only check partitions for current year
                                        if the InitialCalculation indicator if filled.
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-10-2019	Jaap van Assenbergh	OTIBSUB-1648	OSR AND STIP can also get reset for 
                                        automatic checks in the procedure
	08-07-2019	Sander van Houten	OTIBSUB-1338	Rewrote check on paymentarrear.
	24-05-2019	Sander van Houten	OTIBSUB-940		Status 0021 for accepted declaration, but
										without current budget.
	21-05-2019	Jaap van Assenbergh	OTIBSUB-1078	Routing tussen DS en Etalage wijzigen
	02-04-2019	Sander van Houten	OTIBSUB-851		Adjust PartitionAmountCorrected to 0 if rejected.
	06-03-2019	Jaap van Assenbergh	OTIBSUB-823		Declaraties met heffingsachtstand niet meenemen
										StatusXML toegevoegd. 
										Regulier 001, 002, 004. 
										Bij heffingsachterstand na inlezen MN data 0018
	22-02-2019	Jaap van Assenbergh	OTIBSUB-802		Verwerken Horus declaraties 2019 met onbekende opleiding
	05-02-2019	Jaap van Assenbergh	OTIBSUB-746		Declaratie met opleiding zonder cluster niet meenemen.
	03-01-2019	Sander van Houten	OTIBSUB-578		Controle declaratiebedrag > cursusbedrag per werknemer.
	22-11-2018	Jaap van Assenbergh	Declaratie status 0005 met marge ingevoerd.
	29-11-2018	Sander van Houten	OTIBSUB-481		Automatische controle declaraties alleen uitvoeren als 
										scholingsbudget bedrijf berekend is.
	22-11-2018	Jaap van Assenbergh	OTIBSUB-472		Declaratie status 0001 wordt niet opgepakt als 
										de startdatum actueel wordt.
	27-09-2018	Sander van Houten	OTIBSUB-288		Updated definition of duplcate declaration.
	15-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE	@StatusXML	xml = N''
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate			        date = GETDATE(),
		@DeclarationID		        int,
        @ExecuteFirstPartitionCheck bit
		
DECLARE @tblCheckedDeclarations TABLE 
	(
		DeclarationID	            int NOT NULL,
        ExecuteFirstPartitionCheck  bit NOT NULL
	)

DECLARE @tblRejectedDeclarations TABLE 
	(
		DeclarationID int NOT NULL,
		RejectionReason varchar(24) NOT NULL,
		RejectionXML xml NULL
	)

DECLARE @tblScholingBudgetInitialCalculations TABLE 
	(
		StartDate date NOT NULL,
		EndDate date NOT NULL
	)

/*  Initialize @StatusXML.  */
IF CAST(ISNULL(@StatusXML, N'') AS varchar(MAX)) = N'' 
	SET @StatusXML =	'<partitionstatussen>
							<partitionstatus>0001</partitionstatus>
							<partitionstatus>0002</partitionstatus>
						</partitionstatussen>'

/*	When there is an unknown source the declaration will be checked manualy by OTIB (OTIBSUB-1078). */
DECLARE @tblDeclaration0022 AS TABLE (DeclarationID int)

INSERT INTO @tblDeclaration0022
    (
        DeclarationID
    )
SELECT	DeclarationID 
FROM	sub.tblDeclaration
WHERE	DeclarationStatus IN ('0001', '0002')
AND		StartDate <= GETDATE()
AND		SubsidySchemeID = 1		-- OSR
AND		DeclarationID IN 
		(
			SELECT	DeclarationID 
			FROM	sub.tblDeclaration_Unknown_Source
			WHERE	SentToSourceSystemDate IS NULL
			AND		DeclarationAcceptedDate IS NULL
		)
AND		DeclarationID >= 400000

UPDATE	d
SET		d.DeclarationStatus = '0022'
FROM	@tblDeclaration0022 d0022 
INNER JOIN sub.tblDeclaration d
ON      d.DeclarationID = d0022. DeclarationID

UPDATE	dep
SET		dep.PartitionStatus = '0022'
FROM	@tblDeclaration0022 d0022
INNER JOIN sub.tblDeclaration_Partition dep 
ON      d0022.DeclarationID = dep. DeclarationID
WHERE	dep.PartitionStatus IN ('0001', '0002')

/*  Get all registered referencedates.  */
INSERT INTO @tblScholingBudgetInitialCalculations
	(
		StartDate,
		EndDate
	)
SELECT	apse.StartDate, 
		apse.EndDate
FROM	sub.tblApplicationSetting aps
INNER JOIN sub.tblApplicationSetting_Extended apse 
ON	    apse.ApplicationSettingID = aps.ApplicationSettingID
WHERE	aps.SettingName = 'SubsidyAmountPerEmployer'
AND		aps.SettingCode = 'OSR'
AND		apse.InitialCalculation IS NOT NULL

/*	Select all declarations that have a DeclarationStatus 0001 and startdate less then today
    or 0002 (Ingediend)	and the employer has a calculated subsidy budget.	*/
INSERT INTO @tblCheckedDeclarations
	(	
		DeclarationID,
        ExecuteFirstPartitionCheck
	)
SELECT  
        sub1.DeclarationID,
        MAX(sub1.ExecuteFirstPartitionCheck)
FROM (
        -- DS declarations with a known course.
		SELECT	
		        d.DeclarationID,
		        CASE WHEN dep_frst.FirstPartition IS NULL
		            THEN 0
		            ELSE 1
		        END  AS ExecuteFirstPartitionCheck
		FROM	osr.viewDeclaration d
		INNER JOIN	sub.tblEmployer_Subsidy ems
				ON	ems.EmployerNumber = d.EmployerNumber
				AND	ems.SubsidySchemeID = d.SubsidySchemeID
				AND	d.StartDate BETWEEN ems.StartDate AND ems.EndDate
		INNER JOIN	sub.tblCourse crs
				ON	crs.CourseID = d.CourseID
		INNER JOIN	sub.tblDeclaration_Partition dep 
				ON	dep.DeclarationID = d.DeclarationID
		LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv 
				ON	dpv.DeclarationID = d.DeclarationID
				AND	dpv.PartitionID = dep.PartitionID
		LEFT JOIN	sub.viewDeclaration_FirstPartition dep_frst
				ON	dep_frst.FirstPartition = dep.DeclarationID
				AND	dep_frst.FirstPartition = dep.PartitionID
		INNER  JOIN @tblScholingBudgetInitialCalculations sbic
				ON 	dep.PaymentDate BETWEEN sbic.StartDate AND sbic.EndDate
		WHERE	d.DeclarationID > 400002
		AND     d.StartDate <= @GetDate
		AND		COALESCE(d.InstituteID, 0) > 0
		AND		COALESCE(crs.ClusterNumber, '') <> ''
		AND		dep.PaymentDate <= @GetDate
		AND		dep.PartitionStatus IN 
		        (
		            SELECT	tabel.kolom.value('.', 'varchar(4)')  
		            FROM	@StatusXML.nodes('partitionstatussen/partitionstatus') tabel(kolom)
		        )
-- OTIBSUB-1844		AND		ISNULL(dep.PartitionAmount, 0) + ISNULL(dpv.DeclarationValue, 0) <> 0
		AND		d.SubsidySchemeID = 1				-- OTIBSUB-1822
		AND		d.DeclarationStatus <> '0035'		-- OTIBSUB-1822

		UNION ALL
		
		-- DS declarations with an unknown course that have been accepted by OTIB.
		SELECT	
		        d.DeclarationID,
		        CASE WHEN dep_frst.FirstPartition IS NULL
		            THEN 0
		            ELSE 1
		        END  AS ExecuteFirstPartitionCheck
		FROM	osr.viewDeclaration d
		INNER JOIN sub.tblEmployer_Subsidy ems
				ON	ems.EmployerNumber = d.EmployerNumber
				AND	ems.SubsidySchemeID = d.SubsidySchemeID
				AND	d.StartDate BETWEEN ems.StartDate AND ems.EndDate
		INNER JOIN sub.tblDeclaration_Unknown_Source dus
				ON	dus.DeclarationID = d.DeclarationID
		INNER JOIN sub.tblDeclaration_Partition dep 
				ON	dep.DeclarationID = d.DeclarationID
		LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv 
				ON	dpv.DeclarationID = d.DeclarationID
				AND	dpv.PartitionID = dep.PartitionID
		LEFT JOIN sub.viewDeclaration_FirstPartition dep_frst
				ON	dep_frst.FirstPartition = dep.DeclarationID
				AND	dep_frst.FirstPartition = dep.PartitionID
		INNER  JOIN @tblScholingBudgetInitialCalculations sbic
				ON 	dep.PaymentDate BETWEEN sbic.StartDate AND sbic.EndDate
		WHERE	d.DeclarationID > 400002
		AND		d.StartDate <= @GetDate
		AND		dep.PaymentDate <= @GetDate
		AND		dus.DeclarationAcceptedDate IS NOT NULL
		AND 	dep.PartitionStatus IN 
		        (
		            SELECT	tabel.kolom.value('.', 'varchar(4)')  
		            FROM	@StatusXML.nodes('partitionstatussen/partitionstatus') tabel(kolom)
		        )
-- OTIBSUB-1844		AND		ISNULL(dep.PartitionAmount, 0) + ISNULL(dpv.DeclarationValue, 0) <> 0
		AND		d.SubsidySchemeID = 1				-- OTIBSUB-1822
		AND		d.DeclarationStatus <> '0035'		-- OTIBSUB-1822
		
		UNION ALL
		
		-- Horus declarations with or without Course
		SELECT	
		        d.DeclarationID,
		        0
		FROM	osr.viewDeclaration d
		INNER JOIN	sub.tblEmployer_Subsidy ems
				ON	ems.EmployerNumber = d.EmployerNumber
				AND	@GetDate BETWEEN ems.StartDate AND ems.EndDate
		INNER JOIN	sub.tblDeclaration_Partition dep 
				ON	dep.DeclarationID = d.DeclarationID
		LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv 
				ON	dpv.DeclarationID = d.DeclarationID
				AND	dpv.PartitionID = dep.PartitionID
		INNER  JOIN @tblScholingBudgetInitialCalculations sbic
				ON 	dep.PaymentDate BETWEEN sbic.StartDate AND sbic.EndDate
		WHERE	d.DeclarationID < 400000
		AND     d.StartDate <= @GetDate
		AND		dep.PaymentDate <= @GetDate
		AND		dep.PartitionStatus IN 
		        (
		            SELECT	tabel.kolom.value('.', 'varchar(4)')  
		            FROM	@StatusXML.nodes('partitionstatussen/partitionstatus') tabel(kolom)
		        )
-- OTIBSUB-1844		AND		ISNULL(dep.PartitionAmount, 0) + ISNULL(dpv.DeclarationValue, 0) <> 0
		AND		d.SubsidySchemeID = 1				-- OTIBSUB-1822
		AND		d.DeclarationStatus <> '0035'		-- OTIBSUB-1822

     ) sub1
GROUP BY sub1.DeclarationID

DECLARE cur_Declaration CURSOR FOR 
	SELECT 	
            DeclarationID,
            ExecuteFirstPartitionCheck
	FROM	@tblCheckedDeclarations
	ORDER BY 
            DeclarationID

OPEN cur_Declaration

FETCH FROM cur_Declaration INTO @DeclarationID, @ExecuteFirstPartitionCheck

WHILE @@FETCH_STATUS = 0  
BEGIN
    /* Check on rejection reasons.  */
	EXECUTE osr.uspDeclaration_AutomatedChecks_Declaration @DeclarationID, @ExecuteFirstPartitionCheck, @StatusXML

	FETCH NEXT FROM cur_Declaration INTO @DeclarationID, @ExecuteFirstPartitionCheck
END

CLOSE cur_Declaration
DEALLOCATE cur_Declaration

/*	== osr.uspDeclaration_AutomatedChecks ====================================================	*/
