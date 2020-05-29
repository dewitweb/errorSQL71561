CREATE PROCEDURE [ait].[uspCopyOSRDeclaration_AddVoucher] 
@DeclarationID	int,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Copies the data from a declaration without use of a voucher
				and creates a new one with the use of a voucher.

	18-06-2019	Sander van Houten		OTIBSUB-1194	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Check statements.	*/
SELECT	* 
FROM	sub.tblDeclaration 
WHERE	DeclarationID = @DeclarationID

SELECT	* 
FROM	sub.tblDeclaration_Partition 
WHERE	DeclarationID = @DeclarationID

SELECT	dem.DeclarationID, evo.*
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
INNER JOIN sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = dem.EmployeeNumber
WHERE	d.DeclarationID = @DeclarationID
AND		d.StartDate BETWEEN evo.GrantDate and evo.ValidityDate
AND		evo.AmountBalance <> 0.00

DECLARE @VoucherBalance	decimal(19,2)

SELECT	@VoucherBalance = evo.AmountBalance
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
INNER JOIN sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = dem.EmployeeNumber
WHERE	d.DeclarationID = @DeclarationID
AND		d.StartDate BETWEEN evo.GrantDate and evo.ValidityDate
AND		evo.AmountBalance <> 0.00

IF ISNULL(@VoucherBalance, 0.00) = 0.00
BEGIN
	PRINT 'RETURN 0'
	RETURN 0
END


/*	Copy sub.tblDeclaration.	*/
INSERT INTO [sub].[tblDeclaration]
           ([EmployerNumber]
           ,[SubsidySchemeID]
           ,[DeclarationDate]
           ,[InstituteID]
           ,[StartDate]
           ,[EndDate]
           ,[DeclarationAmount]
           ,[ApprovedAmount]
           ,[DeclarationStatus]
           ,[StatusReason]
           ,[InternalMemo])
SELECT		d.[EmployerNumber]
           ,d.[SubsidySchemeID]
           ,d.[DeclarationDate]
           ,d.[InstituteID]
           ,d.[StartDate]
           ,d.[EndDate]
           ,d.[DeclarationAmount]
           ,d.[ApprovedAmount]
           ,'0002'
           ,NULL
		   ,CAST(d.[DeclarationID] AS varchar(6))
FROM	sub.tblDeclaration d 
WHERE	d.DeclarationID = @DeclarationID

INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	hst.TableName,
        CAST(dnew.DeclarationID AS varchar(6)),
        hst.UserID,
        hst.LogDate,
        hst.OldValue,
        REPLACE(
			REPLACE(
				CAST(hst.NewValue AS varchar(MAX))
					, '<DeclarationID>' + CAST(d.DeclarationID AS varchar(6))
					, '<DeclarationID>' + CAST(dnew.DeclarationID AS varchar(6))
				   )
				, '</row>'
				, '<CopyOf>' + CAST(d.DeclarationID AS varchar(6)) + '</CopyOf></row>'
			   )
FROM	sub.tblDeclaration d 
INNER JOIN his.tblHistory hst ON hst.KeyID = CAST(d.DeclarationID AS varchar(6))
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID
AND		hst.TableName = 'sub.tblDeclaration'
AND		hst.OldValue IS NULL 


/*	Copy osr.tblDeclaration.	*/
INSERT INTO [osr].[tblDeclaration]
           ([DeclarationID]
           ,[CourseID]
           ,[Location]
           ,[ElearningSubscription])
SELECT		dnew.[DeclarationID]
           ,dosr.[CourseID]
           ,dosr.[Location]
           ,dosr.[ElearningSubscription]
FROM	sub.tblDeclaration d 
INNER JOIN  osr.tblDeclaration dosr ON dosr.DeclarationID = d.DeclarationID
INNER JOIN  sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID

INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	hst.TableName,
        CAST(dnew.DeclarationID AS varchar(6)),
        hst.UserID,
        hst.LogDate,
        hst.OldValue,
        REPLACE(
			REPLACE(
				CAST(hst.NewValue AS varchar(MAX))
					, '<DeclarationID>' + CAST(d.DeclarationID AS varchar(6))
					, '<DeclarationID>' + CAST(dnew.DeclarationID AS varchar(6))
				   )
				, '</row>'
				, '<CopyOf>' + CAST(d.DeclarationID AS varchar(6)) + '</CopyOf></row>'
			   )

FROM	sub.tblDeclaration d 
INNER JOIN his.tblHistory hst ON hst.KeyID = CAST(d.DeclarationID AS varchar(6))
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID
AND		hst.TableName = 'osr.tblDeclaration'
AND		hst.OldValue IS NULL 


/*	Copy sub.tblDeclaration_Partition.	*/
INSERT INTO [sub].[tblDeclaration_Partition]
           ([DeclarationID]
           ,[PartitionYear]
           ,[PartitionAmount]
           ,[PartitionAmountCorrected]
           ,[PaymentDate]
           ,[PartitionStatus])
SELECT		dnew.[DeclarationID]
           ,dep.[PartitionYear]
           ,dep.[PartitionAmount]
           ,0.00
           ,dep.[PaymentDate]
           ,'0002'
FROM	sub.tblDeclaration d 
INNER JOIN  sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
INNER JOIN  sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID

-- History records gets inserted after the update!


/*	Copy sub.tblDeclaration_Employee.	*/
INSERT INTO [sub].[tblDeclaration_Employee]
           ([DeclarationID]
           ,[EmployeeNumber])
SELECT		dnew.[DeclarationID]
           ,dem.[EmployeeNumber]
FROM	sub.tblDeclaration d 
INNER JOIN  sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
INNER JOIN  sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID

INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	hst.TableName,
        CAST(dnew.DeclarationID AS varchar(6)),
        hst.UserID,
        hst.LogDate,
        hst.OldValue,
        REPLACE(
			REPLACE(
				CAST(hst.NewValue AS varchar(MAX))
					, '<DeclarationID>' + CAST(d.DeclarationID AS varchar(6))
					, '<DeclarationID>' + CAST(dnew.DeclarationID AS varchar(6))
				   )
				, '</row>'
				, '<CopyOf>' + CAST(d.DeclarationID AS varchar(6)) + '</CopyOf></row>'
			   )
FROM	sub.tblDeclaration d 
INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
INNER JOIN his.tblHistory hst ON hst.KeyID = CAST(d.DeclarationID AS varchar(6)) + '|' + dem.EmployeeNumber
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID
AND		hst.TableName = 'sub.tblDeclaration_Employee'
AND		hst.OldValue IS NULL 


/*	Copy sub.tblDeclaration_Attachment.	*/
INSERT INTO [sub].[tblDeclaration_Attachment]
           ([DeclarationID]
           ,[AttachmentID]
           ,[UploadDateTime]
           ,[OriginalFileName]
           ,[DocumentType]
           ,[ExtensionID])
SELECT	dnew.DeclarationID,
		dat.AttachmentID,
		dat.UploadDateTime,
		dat.OriginalFileName,
		dat.DocumentType,
		dat.ExtensionID
FROM	sub.tblDeclaration d 
INNER JOIN  sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
INNER JOIN  sub.tblDeclaration_Attachment dat ON dat.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID

INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	hst.TableName,
        CAST(dnew.DeclarationID AS varchar(6)) + '|' + CAST(dat.AttachmentID AS varchar(36)),
        hst.UserID,
        hst.LogDate,
        hst.OldValue,
        REPLACE(
			REPLACE(
				CAST(hst.NewValue AS varchar(MAX))
					, '<DeclarationID>' + CAST(d.DeclarationID AS varchar(6))
					, '<DeclarationID>' + CAST(dnew.DeclarationID AS varchar(6))
				   )
				, '</row>'
				, '<CopyOf>' + CAST(d.DeclarationID AS varchar(6)) + '</CopyOf></row>'
			   )
FROM	sub.tblDeclaration d 
INNER JOIN sub.tblDeclaration_Attachment dat ON dat.DeclarationID = d.DeclarationID
INNER JOIN his.tblHistory hst ON hst.KeyID = CAST(d.DeclarationID AS varchar(6)) + '|' + CAST(dat.AttachmentID AS varchar(36))
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID
AND		hst.TableName = 'sub.tblDeclaration_Attachment'
AND		hst.OldValue IS NULL 


/*	Add sub.tblDeclaration_Partition_Voucher.	*/
DECLARE @RC					int,
		@NewDeclarationID	int,
		@PartitionID		int,
		@EmployeeNumber		varchar(8),
		@VoucherNumber		varchar(3),
		@DeclarationValue	decimal(19,4)

SELECT	@NewDeclarationID = dnew.[DeclarationID],
		@PartitionID = dep.[PartitionID],
        @EmployeeNumber = evo.[EmployeeNumber],
        @VoucherNumber = evo.[VoucherNumber],
        @DeclarationValue = CASE WHEN dep.PartitionAmount > evo.VoucherValue
								THEN evo.VoucherValue
								ELSE dep.PartitionAmount
							END
FROM	sub.tblDeclaration dnew 
INNER JOIN  sub.tblDeclaration_Partition dep ON dep.DeclarationID = dnew.DeclarationID
INNER JOIN  sub.tblDeclaration_Employee dem ON dem.DeclarationID = dnew.DeclarationID
INNER JOIN  sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = dem.EmployeeNumber
WHERE	dnew.InternalMemo = CAST(@DeclarationID AS varchar(6))
AND		dnew.StartDate BETWEEN evo.GrantDate and evo.ValidityDate
AND		evo.AmountBalance <> 0.00

EXECUTE @RC = [sub].[uspDeclaration_Partition_Voucher_Update] 
   @NewDeclarationID
  ,@EmployeeNumber
  ,@VoucherNumber
  ,@DeclarationValue
  ,@CurrentUserID
  ,@PartitionID


/*	Update sub.tblDeclaration_Partition.	*/
UPDATE	dep
SET		dep.PartitionAmount = dep.PartitionAmount - dpv.DeclarationValue
FROM	sub.tblDeclaration dnew 
INNER JOIN  sub.tblDeclaration_Partition dep ON dep.DeclarationID = dnew.DeclarationID
INNER JOIN  sub.tblDeclaration_Employee dem ON dem.DeclarationID = dnew.DeclarationID
INNER JOIN  sub.tblEmployee_Voucher evo ON evo.EmployeeNumber = dem.EmployeeNumber
INNER JOIN  sub.tblDeclaration_Partition_Voucher dpv 
ON		dpv.DeclarationID = dnew.DeclarationID 
AND		dpv.EmployeeNumber = evo.EmployeeNumber
AND		dpv.VoucherNumber = evo.VoucherNumber
WHERE	dnew.InternalMemo = CAST(@DeclarationID AS varchar(6))
AND		dnew.StartDate BETWEEN evo.GrantDate and evo.ValidityDate

INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	hst.TableName,
        CAST(depnew.PartitionID AS varchar(18)),
        hst.UserID,
        hst.LogDate,
        hst.OldValue,
        REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								CAST(hst.NewValue AS varchar(MAX))
									, '<PartitionID>' + CAST(dep.PartitionID AS varchar(18))
									, '<PartitionID>' + CAST(depnew.PartitionID AS varchar(18))
								   )
								, '<DeclarationID>' + CAST(dep.DeclarationID AS varchar(6))
								, '<DeclarationID>' + CAST(depnew.DeclarationID AS varchar(6))
							   )
							, '<PartitionAmount>' + CAST(dep.PartitionAmount AS varchar(20))
							, '<PartitionAmount>' + CAST(depnew.PartitionAmount AS varchar(20))
						   )
						, '<PartitionAmountCorrected>' + CAST(dep.PartitionAmountCorrected AS varchar(20))
						, '<PartitionAmountCorrected>' + CAST(depnew.PartitionAmountCorrected AS varchar(20))
					   )
					, '<PartitionStatus>' + CAST(dep.PartitionStatus AS varchar(4))
					, '<PartitionStatus>' + CAST(depnew.PartitionStatus AS varchar(4))
				   )
				, '</row>'
				, '<CopyOf>' + CAST(d.DeclarationID AS varchar(6)) + '</CopyOf></row>'
			   )
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
INNER JOIN his.tblHistory hst ON hst.KeyID = CAST(dep.PartitionID AS varchar(18))
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
INNER JOIN sub.tblDeclaration_Partition depnew 
ON		depnew.DeclarationID = dnew.DeclarationID
AND		depnew.PartitionYear = dep.PartitionYear
WHERE	d.DeclarationID = @DeclarationID
AND		hst.TableName = 'sub.tblDeclaration_Partition'
AND		hst.OldValue IS NULL


/*	Add History CopyTo record to original declaration.	*/
INSERT INTO his.tblHistory
	(
		TableName,
        KeyID,
        UserID,
        LogDate,
        OldValue,
        NewValue
	)
SELECT	'sub.tblDeclaration',
        CAST(d.DeclarationID AS varchar(6)),
        1,
        GETDATE(),
        '<row><DeclarationID>' + CAST(d.DeclarationID AS varchar(6)) + '</DeclarationID></row>',
        '<row><DeclarationID>' + CAST(d.DeclarationID AS varchar(6)) + '</DeclarationID><CopyTo>' + CAST(dnew.DeclarationID AS varchar(6)) + '</CopyTo></row>'
FROM	sub.tblDeclaration d 
INNER JOIN sub.tblDeclaration dnew ON dnew.InternalMemo = CAST(d.DeclarationID AS varchar(6))
WHERE	d.DeclarationID = @DeclarationID


/*	Clear InternalMemo field.	*/
UPDATE	sub.tblDeclaration 
SET		InternalMemo = NULL
WHERE	InternalMemo = CAST(@DeclarationID AS varchar(6))


/*	Uitvoeren automatische controle.	*/
--EXEC [osr].[uspDeclaration_AutomatedChecks] ''

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspCopyOSRDeclaration_AddVoucher ==================================================	*/