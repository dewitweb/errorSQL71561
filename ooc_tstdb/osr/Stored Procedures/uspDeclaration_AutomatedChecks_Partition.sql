
CREATE PROCEDURE [osr].[uspDeclaration_AutomatedChecks_Partition]
@PartitionID int
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
	12-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-10-2019	Sander van Houten	OTIBSUB-1633	If there is a paymentarrear 
										directly remove all other rejection reasons.
	16-09-2019	Sander van Houten	OTIBSUB-1572	If there is a paymentarrear 
										reject the declaration temporarily.
	11-09-2019	Sander van Houten	OTIBSUB-1554	The code couldn't handle more than 1 voucher 
										being used, this is corrected.
	30-08-2019	Sander van Houten	OTIBSUB-1213	Status 0021 for rejected declaration, 
										where the only reason is -> no current budget.
	12-07-2019	Sander van Houten	OTIBSUB-1349	There can be more than 1 rejection on 0004.
	04-07-2019	Sander van Houten	OTIBSUB-1323	Only write a new log record if there 
										is a change in status (this is not the case if 
										an employer still has a paymentarrear.
	24-05-2019	Sander van Houten	OTIBSUB-940		Status 0021 for accepted declaration, but
										without current budget.
	15-04-2019	Jaap van Assenbergh	OTIBSUB-1025	Declaratie op goedgekeurd. 
										Had op tijdelijke afkeur moeten staan
	02-04-2019	Sander van Houten	OTIBSUB-851		Adjust PartitionAmountCorrected to 0 if rejected.
	06-03-2019	Jaap van Assenbergh	OTIBSUB-823		Declaraties met heffingsachtstand tijdelijk afkeuren
	27-02-2019	Jaap van Assenbergh	OTIBSUB-814		ORS: bij onvoldoende scholingsbudget een 
										declaratie goedkeuren met een lager bedrag
	03-01-2019	Sander van Houten	OTIBSUB-578		Controle declaratiebedrag > cursusbedrag per werknemer.
	22-11-2018	Jaap van Assenbergh	Declaratie status 0005 met marge ingevoerd.
	29-11-2018	Sander van Houten	OTIBSUB-481		Automatische controle declaraties alleen uitvoeren als 
										scholingsbudget bedrijf berekend is.
	22-11-2018	Jaap van Assenbergh	OTIBSUB-472		Declaratie status 0001 wordt niet opgepakt als 
										de startdatum actueel wordt.
	27-09-2018	Sander van Houten	OTIBSUB-288		Updated definition of duplicate declaration.
	15-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @PartitionID	int = 9927
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

SET @KeyID = CAST(@PartitionID AS varchar(18))

DECLARE @DeclarationID				int,
		@Accepted					bit = 1,
        @PartitionStatus			varchar(4),
		@CorrectionAmount			decimal(19,2),
		@PreviousPartitionStatus	varchar(4)

DECLARE @tblRejectedDeclarations TABLE
(
	DeclarationID int NOT NULL,
	RejectionReason varchar(24) NOT NULL,
	RejectionXML xml NULL
)

SELECT	@DeclarationID = DeclarationID
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = @PartitionID

/*  First check on nul partition  */
INSERT INTO @tblRejectedDeclarations
            (DeclarationID
            ,RejectionReason
            ,RejectionXML)
SELECT	decl.DeclarationID										DeclarationID, 
        '0021'													RejectionReason,
        (SELECT	decl.EmployerNumber EmployerNumber,
                (SELECT	
                        PartitionYear	PartitionYear,
                        PartitionAmount PartitionAmount
                    FOR XML PATH('Partition'), TYPE
                )
        FOR XML PATH('TransferredAmount'), ROOT('Rejection')
        )														RejectionXML
FROM	sub.tblDeclaration decl
INNER JOIN	sub.tblDeclaration_Partition dp 
        ON	dp.DeclarationID = decl.DeclarationID
LEFT JOIN	sub.tblDeclaration_Partition_Voucher dpv
        ON	dp.DeclarationID = decl.DeclarationID
		AND	dpv.PartitionID = dp.PartitionID
WHERE	dp.PartitionID = @PartitionID
AND		dp.PartitionAmount= 0 
AND		ISNULL(DeclarationValue, 0) = 0

/*  Check on other rejection reasons if there is no rejection based on a payment arrear. */
IF NOT EXISTS (	
				SELECT 	1
				FROM 	sub.tblDeclaration_Rejection
				WHERE 	DeclarationID = @DeclarationID
                AND     RejectionReason = '0004'
			  )
BEGIN
    /*	Check on balance.
    REGELS
    1.	De declarant mag per jaar niet meer declareren dan het scholingsbudget. Op = op.
    2.	Declaraties voor subsidieregelingen voor bedrijven waarvoor het scholingsbudget op is, 
        mogen door OTIB niet handmatig worden goedgekeurd.
    3.	Bij overschrijding van het saldo het uit te keren bedrag aanpassen aan het saldo. OTIBSUB_814 
    4.	Indien er geen waardebonnen gebruikt worden en het scholingsbudget daadwerkelijk 0 is, 
        dient de declaratie alsnog goedgekeurd te worden
        (als er geen andere redenen zijn voor afkeur), 
        maar dient de status wel op "Scholingsbudget volledig benut" (0021) te komen.

    NOTEN
    1.	Er zijn voorbeelden bekend waarbij meer uitgekeerd is dan het scholingsbudget. 
        Dit werd als een handmatige boeking in het systeem ingevoerd.
    2.	In het nieuwe subsidiesysteem kunnen deze situaties als volgt worden afgehandeld:
        a.	Het scholingsbudget van de werkgever wordt verhoogd.
        b.	De werkgever dient een declaratie in.
        c.	OTIB keurt deze goed en betaalt deze uit.	
    */
    SELECT	@CorrectionAmount = CAST(sub.usfGetPartitionAmountCorrected(@PartitionID, 0) AS decimal(19,2))

    INSERT INTO @tblRejectedDeclarations
                (DeclarationID
                ,RejectionReason
                ,RejectionXML)
    SELECT	decl.DeclarationID										DeclarationID, 
            '0003'													RejectionReason,
            (SELECT	decl.EmployerNumber EmployerNumber,
                    (SELECT	
                            PartitionYear	PartitionYear,
                            CASE WHEN @CorrectionAmount < 0.00
                                THEN 0.00
                                ELSE @CorrectionAmount
                            END										Balance
                        FOR XML PATH('Partition'), TYPE
                    )
            FOR XML PATH('Balance'), ROOT('Rejection')
            )														RejectionXML
    FROM	sub.tblDeclaration decl
    INNER JOIN sub.tblDeclaration_Partition dp 
            ON dp.DeclarationID = decl.DeclarationID
    WHERE	dp.PartitionID = @PartitionID
    AND		dp.PartitionAmount > @CorrectionAmount

    IF @@ROWCOUNT <> 0	-- Overschrijding budget.
    BEGIN
        SELECT	@CorrectionAmount = rej.RejectionXML.value('(/Rejection/Balance/Partition/Balance)[1]', 'decimal(19,2)')
        FROM	@tblRejectedDeclarations rej

        -- Remove the rejection if there is no amount to be payed (OTIBSUB-1213).
        IF @CorrectionAmount = 0.00
        BEGIN
            DELETE FROM @tblRejectedDeclarations
        END
    END

    --/* Create records for rejected declarations in sub.tblDeclaration_Rejection */
    --INSERT INTO sub.tblDeclaration_Rejection
    --    (
    --        DeclarationID,
    --        PartitionID,
    --        RejectionReason,
    --        RejectionDateTime,
    --        RejectionXML
    --    )
    --SELECT	DeclarationID,
    --        @PartitionID,
    --        RejectionReason,
    --        @LogDate AS [RejectionDateTime],
    --        RejectionXML
    --FROM	@tblRejectedDeclarations
    --WHERE	RejectionReason <> '0003'
    --ORDER BY	
    --        DeclarationID,
    --        RejectionReason
END

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
        @PartitionID,
        RejectionReason,
        @LogDate AS [RejectionDateTime],
        RejectionXML
FROM	@tblRejectedDeclarations
WHERE	RejectionReason <> '0003'
ORDER BY	
        DeclarationID,
        RejectionReason

/*	--	End of rejectionreasons session ------------------------------------------------------	*/

/*  If the partition has no Ammount and not a voucher then set partition status to 0036. (Transferred amount to other partitions)    */
IF EXISTS (	
			SELECT 	1
			FROM 	sub.tblDeclaration_Rejection
			WHERE 	DeclarationID = @DeclarationID
			AND		PartitionID = @PartitionID
			AND     RejectionReason = '0021'
			)
BEGIN
	/* Update partition status. */
	SET @PartitionStatus = '0036'

	-- Save old record
	SELECT	@XMLdel = ( SELECT * 
						FROM   sub.tblDeclaration_Partition
						WHERE  PartitionID = @PartitionID
						FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblDeclaration_Partition
	SET		PartitionStatus = @PartitionStatus
	WHERE	PartitionID	= @PartitionID

	-- Save new record
	SELECT	@XMLins = ( SELECT * 
						FROM   sub.tblDeclaration_Partition
						WHERE  PartitionID = @PartitionID
						FOR XML PATH)

	-- Log action in tblHistory
	IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
	BEGIN

		-- First check on last log on partition.
		SELECT	@PreviousPartitionStatus = x.r.value('PartitionStatus[1]', 'varchar(4)')
		FROM	his.tblHistory
		CROSS APPLY NewValue.nodes('row') AS x(r)
		WHERE	HistoryID IN (
								SELECT	MAX(HistoryID)	AS MaxHistoryID
								FROM	his.tblHistory
								WHERE	TableName = 'sub.tblDeclaration_Partition'
								AND		KeyID = @KeyID
							)

		-- Only write a new log record if there is a change in status
		-- (this is not the case if an employer still has a paymentarrear).
		IF @PartitionStatus <> @PreviousPartitionStatus
		BEGIN
			EXEC his.uspHistory_Add
					'sub.tblDeclaration_Partition',
					@KeyID,
					1,	--1=Admin
					@LogDate,
					@XMLdel,
					@XMLins
		END
	END
END

IF ISNULL(@PartitionStatus, '') = ''			-- There is no PartitionStatus set by previous check
/*  If there is a payment arrear, then set partition status to 0018.    */
IF EXISTS (	
            SELECT 	1
            FROM 	sub.tblDeclaration_Rejection
            WHERE 	DeclarationID = @DeclarationID
            AND     RejectionReason = '0004'
          )
BEGIN
    /* Update partition status. */
    SET @PartitionStatus = '0018'

    -- Save old record
    SELECT	@XMLdel = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)

    -- Update existing record
    UPDATE	sub.tblDeclaration_Partition
    SET		PartitionStatus = @PartitionStatus,
            PartitionAmountCorrected = 0.00
    WHERE	PartitionID	= @PartitionID

    -- Save new record
    SELECT	@XMLins = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)

    -- Log action in tblHistory
    IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
    BEGIN

        -- First check on last log on partition.
        SELECT	@PreviousPartitionStatus = x.r.value('PartitionStatus[1]', 'varchar(4)')
        FROM	his.tblHistory
        CROSS APPLY NewValue.nodes('row') AS x(r)
        WHERE	HistoryID IN (
                                SELECT	MAX(HistoryID)	AS MaxHistoryID
                                FROM	his.tblHistory
                                WHERE	TableName = 'sub.tblDeclaration_Partition'
                                AND		KeyID = @KeyID
                            )

        -- Only write a new log record if there is a change in status
        -- (this is not the case if an employer still has a paymentarrear).
        IF @PartitionStatus <> @PreviousPartitionStatus
        BEGIN
            EXEC his.uspHistory_Add
                    'sub.tblDeclaration_Partition',
                    @KeyID,
                    1,	--1=Admin
                    @LogDate,
                    @XMLdel,
                    @XMLins
        END
    END
END

IF ISNULL(@PartitionStatus, '') = ''			-- There is still no PartitionStatus
BEGIN
	-- If there is another rejection reason found, then set the partition status accordingly
	IF EXISTS (	
				SELECT 	1
				FROM 	sub.tblDeclaration_Rejection
				WHERE 	DeclarationID = @DeclarationID
				AND		(
							PartitionID = @PartitionID
						OR
							ISNULL(PartitionID, 0) = 0
						)
				AND     RejectionReason <> '0004'
				)
	BEGIN
		SET @Accepted = 0
	END

	-- Update existing record
	IF @Accepted = 0
	BEGIN
		IF	(	
				SELECT	COUNT(1)
				FROM	sub.tblDeclaration_Partition dep
				INNER JOIN sub.tblDeclaration_Rejection dr 
				ON		dr.DeclarationID = dep.DeclarationID 
				AND		dr.PartitionID = dep.PartitionID
				INNER JOIN sub.viewApplicationSetting_RejectionReason asrr 
				ON		asrr.SettingCode = dr.RejectionReason
				WHERE	dep.PartitionID = @PartitionID
				AND	    asrr.NotShownInProcessList = 1
			) > 0
			SET	@PartitionStatus = '0007'
		ELSE
			SET @PartitionStatus = '0005'
	END
	ELSE
	BEGIN
		IF	(	
				SELECT	@CorrectionAmount + SUM(ISNULL(dpv.DeclarationValue, 0.00))
				FROM	sub.tblDeclaration_Partition dep
				LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv 
				ON		dpv.DeclarationID = dep.DeclarationID 
				AND		dpv.PartitionID = dep.PartitionID
				WHERE	dep.PartitionID = @PartitionID
				GROUP BY
						dep.PartitionID
			) = 0.00
			SET @PartitionStatus = '0021'
		ELSE
			SET @PartitionStatus = '0009'
	END

	-- Save old record
	SELECT	@XMLdel = ( SELECT * 
						FROM   sub.tblDeclaration_Partition
						WHERE  PartitionID = @PartitionID
						FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblDeclaration_Partition
	SET		PartitionStatus = @PartitionStatus,
			PartitionAmountCorrected = CASE @Accepted
										WHEN 0 THEN 0.00
										ELSE CASE WHEN @CorrectionAmount < 0.00
												THEN 0.00
												ELSE CASE WHEN @CorrectionAmount < PartitionAmount
														THEN @CorrectionAmount
														ELSE PartitionAmount
														END
												END
										END		
	WHERE	PartitionID	= @PartitionID

	-- Save new record
	SELECT	@XMLins = ( SELECT * 
						FROM   sub.tblDeclaration_Partition
						WHERE  PartitionID = @PartitionID
						FOR XML PATH)

	-- Log action in tblHistory
	IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
	BEGIN
		EXEC his.uspHistory_Add
				'sub.tblDeclaration_Partition',
				@KeyID,
				1,
				@LogDate,
				@XMLdel,
				@XMLins
	END
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== osr.uspDeclaration_AutomatedChecks_Partition ==========================================	*/
