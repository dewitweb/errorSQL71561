

CREATE FUNCTION [sub].[usfGetDeclarationStatusByPartition]
(
	@DeclarationID		int,
	@PartitionID		int,
	@PartitionStatus	varchar(4)
)
RETURNS varchar(4)
AS
/*	==========================================================================
	Purpose:	Get the declarationstatus by a Declaration or 
				Partition

	Input	:	DeclarationID or partitionID.
				When DeclarationID without PartitionID get the last
				ParttionID before the partition of the next 
				paymentdate.
				When partitionID Without declarationID get the 
				DeclarationID of the partition.
			:	PartitionStatus
				When partitionstatus is filed: 
				Returns the declarationstatus when the partition 
				should have this (new) partitionstatus.
				When the partitionstatus is empty: 
				Get the partitionstatus of the partition

	25-11-2019	Sander van Houten   OTIBSUB-1539    Extra check on nominal duration.  
	04-11-2019	Jaap van Assenbergh OTIBSUB-1539    Initial version.
	==========================================================================	*/
BEGIN
	DECLARE @DeclarationStatus	varchar(4) = '0034'

	DECLARE	@Partitions table 
		(
			PartitionID				int,
			PartitionStatus			varchar(4),
			PaymentDate				date, 
			PartitionSequenceASC	int,
			PartitionSequenceDESC	int
		)

	IF ISNULL(@DeclarationID, 0) = 0
		SELECT	@DeclarationID = DeclarationID
 		FROM	sub.tblDeclaration_Partition
		WHERE	PartitionID = @PartitionID

	INSERT INTO @Partitions
	SELECT	dp.PartitionID, dp.PartitionStatus, PaymentDate,
			ROW_NUMBER() OVER
				(	PARTITION BY dp.DeclarationID 
					ORDER BY CASE WHEN dp.PartitionStatus = '0029' THEN 1 ELSE 0 END, dp.PartitionYear ASC , PaymentDate ASC
				) PartitionSequenceASC,
			ROW_NUMBER() OVER
				(	PARTITION BY dp.DeclarationID 
					ORDER BY CASE WHEN dp.PartitionStatus = '0029' THEN 1 ELSE 0 END, dp.PartitionYear DESC, PaymentDate DESC
				) PartitionSequenceDESC
	FROM	sub.tblDeclaration_Partition dp
	WHERE	dp.DeclarationID = @DeclarationID

	IF @@ROWCOUNT = 0
    BEGIN
        DECLARE @CurrentDeclarationStatus   varchar(20),
                @NominalDuration            int

        -- Check the nominal duration.
        SELECT  @CurrentDeclarationStatus = d.DeclarationStatus,
                @NominalDuration = edu.NominalDuration
        FROM    sub.tblDeclaration d
        LEFT JOIN stip.tblDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
        LEFT JOIN sub.tblEducation edu ON edu.EducationID = stpd.EducationID
        WHERE   d.DeclarationID = @DeclarationID

        IF @NominalDuration IS NULL
        BEGIN
		    SET @DeclarationStatus = '0027'
        END
        ELSE
		BEGIN
            SET @DeclarationStatus = @CurrentDeclarationStatus
        END
    END

	IF 
		(
			SELECT	COUNT(dep.PartitionID)
			FROM	stip.viewDeclaration decl
			INNER JOIN sub.tblDeclaration_Partition dep 
					ON	dep.DeclarationID = decl.DeclarationID
			WHERE	dep.DeclarationID = @DeclarationID
			AND		decl.SubsidySchemeID = 4
			AND		dep.PartitionStatus = '0024'
			AND		decl.TerminationReason = '0006'
		) > 0
	BEGIN
		SELECT	@DeclarationStatus = 
				(
					SELECT
							CASE 
								WHEN da.DeclarationID IS NULL 
								THEN '0030' 
								ELSE '0031' 
							END
					FROM	stip.viewDeclaration decl
					INNER JOIN sub.tblDeclaration_Partition dep 
							ON	dep.DeclarationID = decl.DeclarationID
					LEFT JOIN	sub.tblDeclaration_Attachment da 
							ON	da.DeclarationID = decl.DeclarationID
							AND	da.DocumentType = 'Certificate'
					WHERE	dep.DeclarationID = @DeclarationID
					AND		decl.SubsidySchemeID = 4
					AND		dep.PartitionStatus = '0024'
					AND		decl.TerminationReason = '0006'
				)
	END

	IF @DeclarationStatus = '0034'		--Declarationstatus depends on actual partition.
	BEGIN
		IF ISNULL(@PartitionID, 0) = 0
			SELECT	@PartitionID = sub.usfGetActivePartitionByDeclaration(@DeclarationID, GETDATE())

		IF ISNULL(@PartitionStatus, '') = '' 
			SELECT	@PartitionStatus = PartitionStatus 
			FROM	sub.tblDeclaration_Partition
			WHERE	PartitionID = @PartitionID

		IF @PartitionStatus IN 
			(
				'0001', 
				'0002'
			)
		BEGIN
									
			IF	(
					SELECT	PartitionID
					FROM	@Partitions 
					WHERE	PartitionSequenceASC = 1
				) = @PartitionID
				SET	@DeclarationStatus = @PartitionStatus
			ELSE
				SELECT	@DeclarationStatus = PartitionStatus
				FROM	@Partitions 
				WHERE	PartitionSequenceASC = 1
				AND		PartitionStatus IN ('0001', '0002')
		END
		ELSE IF @PartitionStatus IN 
			(
				'0012', 
				'0014', 
				'0017', 
				'0028', 
				'0029'
			)
		BEGIN
			IF	(
					SELECT	PartitionID
					FROM	@Partitions 
					WHERE	PartitionSequenceDESC = 1
				) = @PartitionID
				SET	@DeclarationStatus = '0035'
		END
		ELSE IF @PartitionStatus IN 
			(
				'0024'
			)
		BEGIN
			SELECT	@DeclarationStatus = 
					(
						SELECT
								CASE 
									WHEN da.DeclarationID IS NULL 
									THEN '0030' 
									ELSE '0031' 
								END
						FROM	stip.viewDeclaration decl
						INNER JOIN sub.tblDeclaration_Partition dep 
								ON	dep.DeclarationID = decl.DeclarationID
						LEFT JOIN	sub.tblDeclaration_Attachment da 
								ON	da.DeclarationID = decl.DeclarationID
								AND	da.DocumentType = 'Certificate'
						WHERE	dep.PartitionID = @PartitionID
						AND		decl.SubsidySchemeID = 4
						AND		dep.PartitionStatus = '0024'
						AND		decl.TerminationReason = '0006'

						UNION ALL

						SELECT	'0035'
						FROM	stip.viewDeclaration decl
						INNER JOIN sub.tblDeclaration_Partition dep 
								ON	dep.DeclarationID = decl.DeclarationID
						WHERE	dep.PartitionID = @PartitionID
						AND		decl.SubsidySchemeID = 4
						AND		dep.PartitionStatus = '0024'
						AND		decl.TerminationReason IN ('0005', '0007')
					)		
		END
		ELSE IF @PartitionStatus IN 
			(
				'0006',	
				'0019',
				'0022',
				'0023',
				'0025',
				'0030',
				'0031',
				'0032',
				'0033'
			)
		BEGIN
			SET @DeclarationStatus = @PartitionStatus
		END
	END

	RETURN @DeclarationStatus
END

/*	==	sub.usfGetDeclarationStatusByPartition ===============================	*/
