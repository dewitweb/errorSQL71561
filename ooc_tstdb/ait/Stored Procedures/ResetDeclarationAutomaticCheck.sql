CREATE  PROCEDURE [ait].[ResetDeclarationAutomaticCheck] 
@DeclarationID int
AS
/*	==========================================================================================
	Purpose:	Update status only.

	14-10-2019	Sander van Houten		Added logging.
	==========================================================================================	*/

/*  Testdata.
DECLARE @DeclarationID  int = 406438 
--  */

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/*  Partition(s) first. */
DECLARE @PartitionID    int

SELECT  TOP 1
        @PartitionID = PartitionID
FROM    sub.tblDeclaration_Partition 
WHERE	DeclarationID = @DeclarationID
AND     PartitionYear >= 2019
ORDER BY 
        PartitionYear

-- Save old record
SELECT	@XMLdel = (	SELECT	* 
					FROM	sub.tblDeclaration_Partition 
					WHERE	PartitionID = @PartitionID
                    AND     PartitionYear >= 2019
					FOR XML PATH)

-- Update existing record
UPDATE sub.tblDeclaration_Partition
SET		PartitionStatus = CASE WHEN PaymentDate <= @LogDate
                            THEN '0002'
                            ELSE '0001'
                          END,
		PartitionAmountCorrected = 0.00
WHERE	PartitionID = @PartitionID
  AND   PartitionYear >= 2019

-- Save new record
SELECT	@XMLins = (	SELECT	* 
					FROM	sub.tblDeclaration_Partition 
					WHERE	PartitionID = @PartitionID
                    AND     PartitionYear >= 2019
					FOR XML PATH)

-- Log action in tblHistory.
SET @KeyID = CAST(@PartitionID AS varchar(18))

EXEC his.uspHistory_Add
        'sub.tblDeclaration_Partition',
        @KeyID,
        1,
        @LogDate,
        @XMLdel,
        @XMLins

/*  Then the declaration.   */
-- Save old record
SELECT	@XMLdel = (	SELECT	* 
					FROM	sub.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH)

-- Update existing record
UPDATE	sub.tblDeclaration
SET		DeclarationStatus = '0002',
		StatusReason = NULL
WHERE	DeclarationID = @DeclarationID

-- Save new record
SELECT	@XMLins = (	SELECT	* 
					FROM	sub.tblDeclaration
					WHERE	DeclarationID = @DeclarationID
					FOR XML PATH)

-- Log action in tblHistory.
SET @KeyID = CAST(@DeclarationID AS varchar(18))

EXEC his.uspHistory_Add
        'sub.tblDeclaration',
        @KeyID,
        1,
        @LogDate,
        @XMLdel,
        @XMLins

/*  The rejections. */
DELETE	der
FROM	sub.tblDeclaration_Rejection der
LEFT JOIN sub.tblDeclaration_Partition dep on dep.PartitionID = der.PartitionID
WHERE	der.DeclarationID = @DeclarationID
AND		(	der.PartitionID = 0
	OR		dep.PartitionYear >= 2019
		)

/*  And the specifications. */
DELETE	dsp
FROM	sub.tblDeclaration_Specification dsp
WHERE	dsp.DeclarationID = @DeclarationID
AND		dsp.PaymentRunID >= 60000

/*	== ait.ResetDeclarationAutomaticCheck ====================================================	*/
