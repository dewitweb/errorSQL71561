
CREATE PROCEDURE [stip].[uspDeclaration_AutomatedChecks_Partition]
@PartitionID    int
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on a partitions of a stip declaration.

	12-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-10-2019	Sander van Houten	OTIBSUB-1633	If there is a paymentarrear 
										directly remove all other rejection reasons.
	16-09-2019	Sander van Houten	OTIBSUB-1572	If there is a paymentarrear 
										reject the declaration temporarily.
	05-09-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @PartitionID	int = 11709
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @DeclarationID		int,
		@Accepted			bit = 1,
        @PartitionStatus    varchar(20)

DECLARE @tblRejectedDeclarations TABLE
(
	DeclarationID int NOT NULL,
	RejectionReason varchar(24) NOT NULL,
	RejectionXML xml NULL
)

/*  Get current DeclarationID.  */
SELECT	@DeclarationID = DeclarationID
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = @PartitionID

/*  Check on other rejection reasons if there is no rejection based on a payment arrear. */
IF NOT EXISTS (	
				SELECT 	1
				FROM 	sub.tblDeclaration_Rejection
				WHERE 	DeclarationID = @DeclarationID
                AND     RejectionReason = '0004'
			  )
BEGIN
    -- Insert code here.

    /*  Create records for rejected partitions in sub.tblDeclaration_Rejection */
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
    ORDER BY	
            DeclarationID,
            RejectionReason
END
/*	--	End of rejectionreasons session ------------------------------------------------------	*/

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
        DECLARE @PreviousPartitionStatus	varchar(4)

        SET @KeyID = CAST(@PartitionID AS varchar(18))

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
ELSE
BEGIN
    -- If there is another rejection reason found, then set the partition status accordingly
    IF EXISTS (	
                SELECT 	1
                FROM 	sub.tblDeclaration_Rejection
                WHERE 	DeclarationID = @DeclarationID
                AND     RejectionReason <> '0004'
            )
    BEGIN
        SET @Accepted = 0
    END

    -- Update existing record
    IF @Accepted = 0
    BEGIN
        IF	(	SELECT	COUNT(1)
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
		IF	(													-- Has the declaration been terminated? 
				SELECT	PartitionID
				FROM	sub.tblDeclaration_Partition
				WHERE	DeclarationID = @DeclarationID
				AND		PartitionStatus = '0024'
			) = 0
            SET @PartitionStatus = '0037'		-- No. Goto email sending
		ELSE
			SET @PartitionStatus = '0009'		-- Yes. Goto paymentrun
    END

    -- Save old record
    SELECT	@XMLdel = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)

    -- Update existing record
    UPDATE	sub.tblDeclaration_Partition
    SET		PartitionStatus = @PartitionStatus,
            PartitionAmountCorrected = PartitionAmount
    WHERE	PartitionID	= @PartitionID

    -- Save new record
    SELECT	@XMLins = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_AutomatedChecks_Partition =========================================	*/
