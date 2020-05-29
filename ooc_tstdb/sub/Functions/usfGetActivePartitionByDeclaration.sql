
CREATE FUNCTION [sub].[usfGetActivePartitionByDeclaration]
/*	==============================================================
	Purpose:	Get the active partition by a Declaration

	Input	:	DeclarationID
				Date

	07-11-2019	Jaap van Assenbergh
	==============================================================	*/
(
	@DeclarationID		int,
	@Date				date
)
RETURNS INT
AS
BEGIN
	DECLARE @PartitionID	int

	DECLARE	@Partitions table 
		(
			PartitionID				int,
			PartitionStatus			varchar(4),
			PaymentDate				date, 
			PartitionSequenceASC	int,
			PartitionSequenceDESC	int
		)

	INSERT INTO @Partitions
	SELECT	dp.PartitionID, dp.PartitionStatus, PaymentDate,
			ROW_NUMBER() OVER
				(	PARTITION BY dp.DeclarationID 
					ORDER BY CASE WHEN dp.PartitionStatus = '0029' THEN 1 ELSE 0 END, dp.PartitionYear ASC , PaymentDate ASC
				) PartitionSequenceASC,
			ROW_NUMBER() OVER
				(	PARTITION BY dp.DeclarationID 
					ORDER BY CASE WHEN dp.PartitionStatus = '0029' THEN 1 ELSE 0 END, dp.PartitionYear ASC, PaymentDate DESC
				) PartitionSequenceDESC
	FROM	sub.tblDeclaration_Partition dp
	WHERE	dp.DeclarationID = @DeclarationID

	/*		Declaratie indediend/ingepland				*/ 
	SELECT	@PartitionID = PartitionID
	FROM	@Partitions
	WHERE	PartitionSequenceASC = 1
	AND		PaymentDate >= @Date

	IF @@ROWCOUNT = 0							/* Selecteer partitie voor de eerst volgende */
	BEGIN
		SELECT	@PartitionID = PartitionID
		FROM	@Partitions
		WHERE	PartitionSequenceASC = 
				(
					SELECT	MIN(PartitionSequenceASC) - 1
					FROM	@Partitions
					WHERE	PaymentDate > @Date	
				)

		IF @@ROWCOUNT = 0							/* Selecteer de laatse partitie				*/
			SELECT	@PartitionID = PartitionID
			FROM	@Partitions
			WHERE	PartitionSequenceDESC = 1
	END

	RETURN @PartitionID
END

/*	==	sub.usfGetActivePartitionByDeclaration ===================	*/
