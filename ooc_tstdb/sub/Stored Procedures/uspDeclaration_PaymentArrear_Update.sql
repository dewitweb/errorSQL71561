CREATE PROCEDURE [sub].[uspDeclaration_PaymentArrear_Update]
AS
/*	==========================================================================================
	Purpose:	Update declaration with paymentarrear.
				If paymentarear has ended set declaration ready for Automatic checks

	22-01-2020	Jaap van Assenbergh	OTIBSUB-1817	Rejectionreason verwijderen en historie
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-10-2019	Jaap van Assenbergh	OTIBSUB-1648	OSR AND STIP can also get reset for 
                                        Automatic checks in the procedure.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel			xml,
		@XMLins			xml,
		@LogDate		datetime = GETDATE(),
		@KeyID			varchar(50)

DECLARE @PartitionID	int

DECLARE crs_Partition CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR	
		SELECT	DISTINCT
				dep.PartitionID
		FROM	sub.tblDeclaration_Partition dep
		INNER JOIN	sub.tblDeclaration decl 
				ON	decl.DeclarationID = dep.DeclarationID
		INNER JOIN	sub.tblPaymentArrear pa 
				ON	pa.EmployerNumber = decl.EmployerNumber
		WHERE	dep.PartitionStatus = '0018'
		AND		DATEDIFF(D, pa.FeesPaidUntill, GETDATE()) < 30
	OPEN crs_Partition
	FETCH FROM crs_Partition
	INTO @PartitionID

WHILE @@FETCH_STATUS = 0   
BEGIN

    SELECT	@XMLdel = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)
	UPDATE	dep
	SET		dep.PartitionStatus = CASE WHEN dep.PaymentDate > CAST(GETDATE() AS date)
										THEN '0001'
										ELSE '0002'
								  END
	FROM	sub.tblDeclaration_Partition dep
	WHERE	PartitionID = @PartitionID

    SELECT	@XMLins = ( SELECT * 
                        FROM   sub.tblDeclaration_Partition
                        WHERE  PartitionID = @PartitionID
                        FOR XML PATH)

	SET @KeyID = CAST(@PartitionID AS varchar(18))
	            EXEC his.uspHistory_Add
                    'sub.tblDeclaration_Partition',
                    @KeyID,
                    1,	--1=Admin
                    @LogDate,
                    @XMLdel,
                    @XMLins

	UPDATE	decl
	SET		DeclarationStatus = sub.usfGetDeclarationStatusByPartition(decl.DeclarationID, NULL, NULL),
			StatusReason = NULL
	FROM	sub.tblDeclaration decl
	INNER JOIN	sub.tblDeclaration_Partition dep 
			ON	dep.DeclarationID = decl.DeclarationID
	WHERE	PartitionID = @PartitionID

	DELETE	dr
	FROM sub.tblDeclaration_Rejection dr
	INNER JOIN	sub.tblDeclaration_Partition dep 
			ON	dep.DeclarationID = dr.DeclarationID
	WHERE	dep.PartitionID = @PartitionID

	FETCH NEXT FROM crs_Partition
	INTO @PartitionID
END
CLOSE crs_Partition
DEALLOCATE crs_Partition

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_PaymentArrear_Update ===============================================	*/
