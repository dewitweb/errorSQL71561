
CREATE PROCEDURE [osr].[uspDeclaration_AutomatedChecks_Declaration]
@DeclarationID	            int,
@ExecuteFirstPartitionCheck bit,
@StatusXML		            xml
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on all declaration with status "Ingediend" or 
				"Nieuwe opleiding afgehandeld".

	Notes:		The source document of the checks is 
				"04a 20180807 HM OTIB Subsidiesysteem deel 04a subsidieregeling OSR versie 1.6"
				OTIBSUB-296
				Declaraties voor de OSR kunnen ingediend worden voor alle werknemers,
				ongeacht hun leeftijd.	

	24-01-2020	Jaap van Assenbergh	OTIBSUB-1844	Declaratie 414034 nieuw instituut/cursus en status actief
	09-01-2020	Sander van Houten	OTIBSUB-1810	Added check on PartitionAmount and optional
                                        voucher(s).
	06-01-2020	Sander van Houten	OTIBSUB-1810	Added indication ExecuteFirstPartitionCheck.
	02-10-2019	Jaap van Assenbergh	OTIBSUB-1785	Goedkeuren nieuwe opleiding instituut 
													gaat niet meer direct controle in
	12-11-2019	Sander van Houten	OTIBSUB-1696	Removed check on IBAN.
	12-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	02-10-2019	Jaap van Assenbergh	OTIBSUB-1347	Opleiding in subsidiabel cluster is niet subsidiabel in DS
	25-09-2019	Sander van Houten	OTIBSUB-1592	Corrected joins with check on duplicates.
	12-07-2019	Sander van Houten	OTIBSUB-1349	Added filter on partition PaymentDate.
	03-07-2019	Sander van Houten	OTIBSUB-1314	Update DeclarationStatus after PartitionStatus.
	20-06-2019	Jaap van Assenbergh	OTIBSUB-1224	Declaratie Nieuw instituut/ opleiding 
													automatische controles uitvoeren na goedkeuring
													Skip checks on Courses when declarationStatus = 0022
													- Double
													- Costs
													- Is not Eligible
	19-06-2019	Sander van Houten	OTIBSUB-1194	No reject on duplicate when a copy is made.
	18-06-2019	Sander van Houten	OTIBSUB-1228	Also update declarations to status 0007.
													if declarationstatus = 0005 and partitionstatus = 0007.
	24-05-2019	Sander van Houten	OTIBSUB-940		Status 0021 for accepted declaration, but
													without current budget.
	07-05-2019	Sander van Houten	OTIBSUB-1046	Move vouchers to partition level.
	12-03-2019	Sander van Houten	Bij het bepalen of een declaratie dubbel is, 
									dient er niet gekeken te worden naar declaraties die 
									eerder aangemaakt zijn, anders kunnen declaraties 
									elkaar als dubbel kenmerken.
	22-02-2019	Jaap van Assenbergh	OTIBSUB-802		Verwerken Horus declaraties 2019 met 
													onbekende opleiding.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
													bij werknemer veranderen.
	06-02-2019	Jaap van Assenbergh	OTIBSUB-755		RejectionReason 0019 IBAN unknown.
	05-02-2019	Sander van Houten	OTIBSUB-744		Bug in check on duplicates.
	03-01-2019	Sander van Houten	OTIBSUB-578		Check declarationamount > courseamount 
													per employee.
	22-11-2018	Jaap van Assenbergh	Declaratie status 0005 met marge ingevoerd.
	29-11-2018	Sander van Houten	OTIBSUB-481		Automatische controle declaraties alleen uitvoeren 
													als scholingsbudget bedrijf berekend is.
	22-11-2018	Jaap van Assenbergh	OTIBSUB-472		Declaratie status 0001 wordt niet opgepakt als 
													de startdatum actueel wordt.
	27-09-2018	Sander van Houten	OTIBSUB-288		Updated definition of duplicate declaration.
	15-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @DeclarationID	int = 409544
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate			    date = GETDATE(),
		@EmployerNumber		    varchar(6),
        @FeesPaidUntill         date,
        @DeclarationStatusNew   varchar(20),
        @StatusReason	        varchar(max) = 'Automatische controle'

DECLARE @PartitionID				int,
		@PartitionYear				varchar(20),
		@PartitionAmount			decimal(19,4),
		@PartitionAmountCorrected	decimal(19,4),
		@PaymentDate				date,
		@PartitionStatus			varchar(4),
		@DeclarationStatus			varchar(4)

DECLARE @DeclarationMargin	decimal(5,2)			

DECLARE @tblRejectedDeclarations TABLE 
    (
        DeclarationID int NOT NULL,
        RejectionReason varchar(24) NOT NULL,
        RejectionXML xml NULL 
    )

/*	Checks on declaration level.	*/
-- 01. Check on payment arrear.
--     If there is a payment arrear, no other checks need to be done!
SELECT  @EmployerNumber = d.EmployerNumber,
		@FeesPaidUntill = pa.FeesPaidUntill
FROM	sub.tblDeclaration d
INNER JOIN sub.tblPaymentArrear pa ON pa.EmployerNumber = d.EmployerNumber
WHERE	d.DeclarationID = @DeclarationID
AND	    DATEDIFF(DAY, pa.FeesPaidUntill, GETDATE()) > 30

IF @FeesPaidUntill IS NOT NULL  -- A payment arrear is present!
BEGIN
	-- Remove all rejection reasons.
    DELETE
    FROM	sub.tblDeclaration_Rejection
    WHERE	DeclarationID = @DeclarationID

	-- And insert a new rejection reason for a payment arrear.
	INSERT INTO sub.tblDeclaration_Rejection
		(
			DeclarationID,
			PartitionID,
			RejectionReason,
			RejectionDateTime,
			RejectionXML
		)
	SELECT	@DeclarationID,
			0           AS PartitionID,
			'0004'      AS RejectionReason,
			@GetDate    AS RejectionDateTime,
			(SELECT	
					(SELECT	@EmployerNumber		"@Number",
							@FeesPaidUntill		DocumentDate
						FOR XML PATH('Employer'), TYPE
					)
				FOR XML PATH('PaymentArrears'), ROOT('Rejection')
			)		    AS RejectionXML
END
ELSE
BEGIN
	/* Check on other rejection reasons.	*/

    IF @ExecuteFirstPartitionCheck = 1
    BEGIN
        -- 02 Check for duplicate declarations.
        /*  REGELS
            De definitie van 'dubbele declaratie' is (n.a.v. overleg 13-09-2018):
                "De declaratie wordt ingediend voor dezelfde opleiding, startdatum, 
                einddatum en cursist als een eerdere declaratie."
        */
        INSERT INTO @tblRejectedDeclarations
                    (DeclarationID
                    ,RejectionReason
                    ,RejectionXML)
        SELECT	DISTINCT
                d.DeclarationID, 
                '0001'										AS RejectionReason,
                (
                    SELECT	
                        (
                            SELECT	DISTINCT
                                    s_dupder.EmployeeNumber		AS "@Number",
                                    s_dupdecl.DeclarationID		AS DeclarationID
                            FROM	osr.viewDeclaration s_decl
                            INNER JOIN sub.tblDeclaration_Employee s_dem
                            ON	    s_dem.DeclarationID = s_decl.DeclarationID
                            INNER JOIN osr.viewDeclaration s_dupdecl
                            ON	    s_dupdecl.EmployerNumber = s_decl.EmployerNumber
                            AND	    s_dupdecl.CourseID = s_decl.CourseID
                            AND     s_dupdecl.StartDate = s_decl.StartDate
                            AND     s_dupdecl.EndDate = s_decl.EndDate
                            INNER JOIN sub.tblDeclaration_Employee s_dupdem
                            ON	    s_dupdem.DeclarationID = s_dupdecl.DeclarationID
                            AND	    s_dupdem.EmployeeNumber = s_dem.EmployeeNumber
                            LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment s_der
                            ON	    s_der.DeclarationID = s_decl.DeclarationID
                            AND     s_der.EmployeeNumber = s_dem.EmployeeNumber
                            LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment s_dupder
                            ON	    s_dupder.DeclarationID = s_dupdecl.DeclarationID
                            AND     s_dupder.EmployeeNumber = s_dem.EmployeeNumber
                            LEFT JOIN his.tblHistory s_hst
                            ON	    s_hst.TableName = 'sub.tblDeclaration'
                            AND     s_hst.KeyID = CAST(s_decl.DeclarationID AS varchar(6))
                            AND     s_hst.OldValue IS NULL
                            AND     CAST(s_hst.NewValue AS varchar(max)) LIKE '%<CopyOf>%'
                            LEFT JOIN sub.tblDeclaration_Partition s_dupdep
                            ON	    s_dupdep.DeclarationID = s_decl.DeclarationID
                            AND     s_dupdep.PartitionStatus <> '0017'
                            WHERE	s_decl.DeclarationID = d.DeclarationID
                            AND	    s_dupdecl.DeclarationID < s_decl.DeclarationID
                            AND     s_der.ReversalPaymentID IS NULL
                            AND	    s_dupder.ReversalPaymentID IS NULL
                            AND	    s_hst.HistoryID IS NULL
                            AND		s_dupdep.PartitionID IS NULL
                        FOR XML PATH('Employee'), TYPE
                        )
                    FOR XML PATH('Double'), ROOT('Rejection')
                )											    AS RejectionXML
        FROM    osr.viewDeclaration d
        INNER JOIN sub.tblDeclaration_Employee dem
        ON	    dem.DeclarationID = d.DeclarationID
        INNER JOIN osr.viewDeclaration dupdecl
        ON	    dupdecl.EmployerNumber = d.EmployerNumber
        AND     dupdecl.CourseID = d.CourseID
        AND     dupdecl.CourseID = d.CourseID
        AND     dupdecl.StartDate = d.StartDate
        AND     dupdecl.EndDate = d.EndDate
        INNER JOIN sub.tblDeclaration_Employee dupdem
        ON	    dupdem.DeclarationID = dupdecl.DeclarationID
        AND     dupdem.EmployeeNumber = dem.EmployeeNumber
        LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der
        ON	    der.DeclarationID = d.DeclarationID
        AND     der.EmployeeNumber = dem.EmployeeNumber
        LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment dupder
        ON	    dupder.DeclarationID = dupdecl.DeclarationID
        AND     dupder.EmployeeNumber = dem.EmployeeNumber
        LEFT JOIN his.tblHistory hst
        ON	    hst.TableName = 'sub.tblDeclaration'
        AND     hst.KeyID = CAST(d.DeclarationID AS varchar(6))
        AND     hst.OldValue IS NULL
        AND     CAST(hst.NewValue AS varchar(max)) LIKE '%<CopyOf>%'
        LEFT JOIN sub.tblDeclaration_Partition dupdep
        ON	    dupdep.DeclarationID = d.DeclarationID
        AND     dupdep.PartitionStatus <> '0017'
        WHERE	d.DeclarationID = @DeclarationID
        AND		d.DeclarationStatus <> '0022'		-- Course unknown. New course for Etalage
        AND		dupdecl.DeclarationID < d.DeclarationID
        AND		der.ReversalPaymentID IS NULL
        AND		dupder.ReversalPaymentID IS NULL
        AND		hst.HistoryID IS NULL
        AND		dupdep.PartitionID IS NULL
        AND		d.DeclarationID >= 400000	-- OTIBSUB-802. Verwerken Horus declaraties 2019 met onbekende opleiding.
        GROUP BY 
                d.DeclarationID

        -- 03 Check for overdue declaration dates.
        /*  REGELS
            1.	Een declaratie mag tot drie maanden na het einde van een jaar voor dat jaar worden ingediend.

            NOTEN
            1.	De periode van drie maanden dient aanpasbaar te zijn.
                a.	Er is geen garantie dat deze periode tot in lengte van jaren drie maanden blijft.
            2.	Idee voor technische uitwerking: in de database bij elk kalenderjaar deze periode vastleggen.
                a.	Dat is de periode na het kalenderjaar waarin declaraties voor dat jaar nog mogen worden ingediend.
        */
        INSERT INTO @tblRejectedDeclarations
                    (DeclarationID
                    ,RejectionReason
                    ,RejectionXML)
        SELECT	d.DeclarationID, 
                '0002'										AS RejectionReason,
                (SELECT	
                        (SELECT	d.EmployerNumber			AS "@Number",
                                ems.EndDeclarationPeriod	AS [EndDeclarationPeriod]
                            FOR XML PATH('Employee'), TYPE
                        )
                    FOR XML PATH('Overdue'), ROOT('Rejection')
                )											AS RejectionXML
        FROM	sub.tblDeclaration d
        INNER JOIN sub.tblEmployer_Subsidy ems ON ems.EmployerNumber = d.EmployerNumber
        WHERE	d.DeclarationID = @DeclarationID
        AND		d.DeclarationDate > ems.EndDeclarationPeriod

        -- 04 Check on declarated amount vs course amount.
        /*	REGELS
            1.	Het gedeclareerde bedrag mag niet meer dan 15 % afwijken van de prijs voor de opleiding, 
                zoals die in Etalage staat.

            NOTEN
            1.	De marge in procenten dient aanpasbaar te zijn.
                a.	OTIB wil met de marge kunnen ‘spelen’ om te zien hoeveel declaraties 
                    door de automatische controle afgekeurd worden.
            2.	Idee voor technische uitwerking: in de database de marge vastleggen met een begin- en einddatum.
                a.	De begin- en einddatum geven de periode aan waarin de marge toegepast wordt.
                b.	Hiervoor wordt niet gekeken naar de declaratiedatum, maar naar ‘vandaag’ 
                    ofwel de datum waarop de declaratie door de automatische controle gecontroleerd wordt.
            3.	OTIBSUB-578: Controle declaratiebedrag > cursusbedrag per werknemer.
        */

        SELECT	TOP 1 
                @DeclarationMargin = aps.SettingValue
        FROM	sub.tblApplicationSetting aps
        LEFT JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
        WHERE	aps.SettingName = 'DeclarationMargin'
        ORDER BY 
                CASE 
                    WHEN apse.StartDate IS NOT NULL AND @GetDate BETWEEN apse.StartDate AND ISNULL(apse.EndDate, @GetDate) 
                        THEN 0 
                        ELSE 1 
                END,
                CASE
                    WHEN apse.StartDate IS NULL	
                        THEN 0 
                        ELSE 1 
                END

        INSERT INTO @tblRejectedDeclarations
                    (DeclarationID
                    ,RejectionReason
                    ,RejectionXML)
        SELECT	d.DeclarationID, 
                '0005'								AS RejectionReason,
                (SELECT	
                        (SELECT	d.EmployerNumber	AS "@Number",
                                crs.CourseCosts		AS [CourseCosts]
                            FOR XML PATH('Employee'), TYPE
                        )
                    FOR XML PATH('CourseCosts'), ROOT('Rejection')
                )									AS RejectionXML
        FROM	osr.viewDeclaration d
        INNER JOIN sub.tblCourse crs ON crs.CourseID = d.CourseID
        WHERE	d.DeclarationID = @DeclarationID
        AND		d.DeclarationStatus <> '0022'		-- Course unknown. New course for Etalage
        AND		d.DeclarationAmount > (1 + (@DeclarationMargin/100)) * (crs.CourseCosts * ( SELECT  COUNT(de.DeclarationID) 
                                                                                            FROM    sub.tblDeclaration_Employee de 
                                                                                            WHERE	de.DeclarationID = d.DeclarationID))
        AND		d.DeclarationID >= 400000			-- OTIBSUB-802. Verwerken Horus declaraties 2019 met onbekende opleiding
        AND		d.ElearningSubscription = 0
    END

    -- 05 Check if a course is in a cluster that will not be reimbursed.
    /*	REGELS
        1.	Opleidingen uit clusters BHV, EHBO en VCA worden niet vergoed.
    */
    INSERT INTO @tblRejectedDeclarations
                (DeclarationID
                ,RejectionReason
                ,RejectionXML)
    SELECT	d.DeclarationID, 
            '0018'								AS RejectionReason,
            (
                SELECT	'Opleiding [' + crs.courseName + '] wordt niet gesubsidieerd'				AS ExcludedCluster
                FOR XML PATH('Rejection')
            )									AS RejectionXML
    FROM	osr.viewDeclaration d
    INNER JOIN sub.tblCourse crs 
    ON	    crs.CourseID = d.CourseID
    LEFT JOIN sub.tblCourse_IsEligible cie 
    ON	    cie.CourseID = d.CourseID
    AND	    d.StartDate BETWEEN cie.FromDate AND ISNULL(cie.UntilDate, d.StartDate)	-- OTIBSUB 1347 Startdate is decisive
    WHERE	d.DeclarationID = @DeclarationID
    AND		d.DeclarationStatus <> '0022'		-- Course unknown. New course for Etalage
    AND		d.DeclarationID >= 400000			-- OTIBSUB-802. Verwerken Horus declaraties 2019 met onbekende opleiding
    AND		cie.CourseID IS NULL

    /* Create records for rejected declarations in sub.tblDeclaration_Rejection.	*/
    INSERT INTO sub.tblDeclaration_Rejection
        (
            DeclarationID,
            RejectionReason,
            RejectionDateTime,
            RejectionXML
        )
    SELECT	DeclarationID,
            RejectionReason,
            @LogDate AS [RejectionDateTime],
            RejectionXML
    FROM	@tblRejectedDeclarations
    ORDER BY	
            DeclarationID,
            RejectionReason
END
/*	--	End of rejectionreasons session ------------------------------------------------------	*/

/*  Zijn er bij verwerking van unknownsource declaraties partities die op 0022 staan met een paymentdate in de toekomst? 
	Dan deze op 0001 zetten. */

UPDATE	sub.tblDeclaration_Partition
SET		PartitionStatus = '0001'
WHERE	DeclarationID = @DeclarationID
AND		PartitionStatus = '0022'
AND		PaymentDate > @GetDate

-- Check partitions.
DECLARE cur_Partitions CURSOR FOR 
	SELECT	dep.PartitionID
	FROM	sub.tblDeclaration d
	INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
    LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv ON	dpv.PartitionID = dep.PartitionID
	WHERE	d.DeclarationID = @DeclarationID
	AND		dep.PaymentDate <= @GetDate
	AND		dep.PartitionStatus IN 
	(
		SELECT	tabel.kolom.value('.', 'varchar(4)')  
		FROM	@StatusXML.nodes('partitionstatussen/partitionstatus') tabel(kolom)
	)
-- OTIBSUB-1844	AND		ISNULL(dep.PartitionAmount, 0) + ISNULL(dpv.DeclarationValue, 0) <> 0
			
OPEN cur_Partitions

FETCH NEXT FROM cur_Partitions INTO @PartitionID

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXEC osr.uspDeclaration_AutomatedChecks_Partition @PartitionID

	FETCH NEXT FROM cur_Partitions INTO @PartitionID
END

CLOSE cur_Partitions
DEALLOCATE cur_Partitions

-- Get the current status of the declaration.
SELECT  @DeclarationStatus = DeclarationStatus
FROM    sub.tblDeclaration
WHERE   DeclarationID = @DeclarationID

-- Get the new status by checking the active partition status.
SELECT  @DeclarationStatusNew = sub.usfGetDeclarationStatusByPartition(@DeclarationID, NULL, NULL)

-- Update the declaration status if it has changed.
IF @DeclarationStatusNew <> @DeclarationStatus
BEGIN
    EXEC sub.uspDeclaration_Upd_DeclarationStatus
        @DeclarationID,
        @DeclarationStatusNew,
        @StatusReason,
        1      
END

-- Update Horus (if one or more partitions are rejected).
DECLARE @EmployeeNumber	varchar(8),
		@VoucherNumber	varchar(3),
		@GrantDate		date,
		@ValidityDate	date,
		@VoucherValue	decimal(19,4),
		@AmountUsed		decimal(19,4),
		@ERT_Code		varchar(3),
		@EventName		varchar(100),
		@EventCity		varchar(100),
		@Active			bit

DECLARE cur_Vouchers CURSOR FOR 
	SELECT 
			dpv.PartitionID,
			dpv.EmployeeNumber,
			dpv.VoucherNumber
	FROM	sub.tblDeclaration_Partition dep
	INNER JOIN sub.tblDeclaration_Partition_Voucher dpv ON dpv.PartitionID = dep.PartitionID
	WHERE	dep.DeclarationID = @DeclarationID
	AND		dep.PartitionStatus = '0007'
		
OPEN cur_Vouchers

FETCH NEXT FROM cur_Vouchers INTO @PartitionID, @EmployeeNumber, @VoucherNumber

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Update the voucher used amount.
	SELECT	@GrantDate = emv.GrantDate,
			@ValidityDate = emv.ValidityDate,
			@VoucherValue = emv.VoucherValue,
			@AmountUsed = emv.AmountUsed - dpv.DeclarationValue,
			@ERT_Code = emv.ERT_Code,
			@EventName = emv.EventName,
			@EventCity = emv.EventCity,
			@Active = emv.Active
	FROM	sub.tblDeclaration_Partition_Voucher dpv
	INNER JOIN sub.tblEmployee_Voucher emv
	ON		emv.EmployeeNumber = dpv.EmployeeNumber
	AND		emv.VoucherNumber = dpv.VoucherNumber
	WHERE	dpv.DeclarationID = @DeclarationID
	AND		dpv.PartitionID = @PartitionID
	AND		dpv.EmployeeNumber = @EmployeeNumber
	AND		dpv.VoucherNumber = @VoucherNumber

	EXEC sub.uspEmployee_Voucher_Upd 
		@EmployeeNumber,
		@VoucherNumber,
		@GrantDate,
		@ValidityDate,
		@VoucherValue,
		@AmountUsed,
		@ERT_Code,
		@EventName,
		@EventCity,
		@Active,
		1	--1=Admin

	FETCH NEXT FROM cur_Vouchers INTO @PartitionID, @EmployeeNumber, @VoucherNumber
END

CLOSE cur_Vouchers
DEALLOCATE cur_Vouchers

-- Update Horus.
INSERT INTO hrs.tblVoucher_Used
	(
		EmployeeNumber,
		EmployerNumber,
		ERT_Code,
		GrantDate,
		DeclarationID,
		VoucherNumber,
		AmountUsed,
		VoucherStatus
	)
SELECT	
		dem.EmployeeNumber,
		d.EmployerNumber,
		emv.ERT_Code,
		emv.GrantDate,
		d.DeclarationID,
		dpv.VoucherNumber,
		SUM(dpv.DeclarationValue)   AS AmountUsed,
		'0007'	                    AS VoucherStatus
FROM	sub.tblDeclaration d
INNER JOIN	sub.tblDeclaration_Partition dep
ON		dep.DeclarationID = d.DeclarationID
INNER JOIN	sub.tblDeclaration_Employee dem 
ON		dem.DeclarationID = d.DeclarationID
INNER JOIN sub.tblDeclaration_Partition_Voucher dpv
ON		dpv.DeclarationID = dem.DeclarationID
AND		dpv.EmployeeNumber = dem.EmployeeNumber
INNER JOIN sub.tblEmployee_Voucher emv
ON		emv.EmployeeNumber = dpv.EmployeeNumber
AND		emv.VoucherNumber = dpv.VoucherNumber
WHERE	dem.DeclarationID = @DeclarationID
AND		dep.PartitionStatus = '0007'
GROUP BY 
   		dem.EmployeeNumber,
		d.EmployerNumber,
		emv.ERT_Code,
		emv.GrantDate,
		d.DeclarationID,
		dpv.VoucherNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_AutomatedChecks_Declaration ====================================	*/
