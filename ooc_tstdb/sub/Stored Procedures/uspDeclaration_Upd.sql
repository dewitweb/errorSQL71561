CREATE PROCEDURE [sub].[uspDeclaration_Upd]
@DeclarationID				int,
@EmployerNumber				varchar(6),
@SubsidySchemeID			int,
@DeclarationDate			datetime,
@InstituteID				int,
@StartDate					date,
@EndDate					date,
@DeclarationAmount			decimal(9,4),
@Partition					xml,
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblDeclaration on the basis of DeclarationID.

	17-01-2020	Sander van Houten	OTIBSUB-1835	Corrected JOIN at cur_Partition_del.
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	31-08-2019	Sander van Houten	Small change in code for partition status 0001.
	08-07-2019	Sander van Houten	OTIBSUB-1342	Initialize StatusReason if a declaration
										is updated through this procedure. 
	04-07-2019	Sander van Houten	OTIBSUB-1323	Only write a new log record if there 
										is a change in status (this is not the case if 
										an employer still has a paymentarrear.
	17-06-2019	Sander van Houten	OTIBSUB-1215	Remove voucher before partition.
	08-05-2018	Jaap van Assenbergh	OTIBSUB-1030	Declaratie terugsturen naar werkgever 
										(retour werkgever).
	02-04-2019	Sander van Houten	Only update partitions that have been changed (performance).
	07-11-2018	Jaap van Assenbergh	OTIBSUB-416		Parameters verwijderen uit subDeclaration_Upd
										- DeclarationStatus
										- StatusReason
										- InternalMemo
	04-10-2018	Sander van Houten	OTIBSUB-313		Added PartitionAmountCorrected 
										and PartitionStatus.
	10-09-2018	Jaap van Assenbergh	OTIBSUB-213		Declaratie partitions worden niet opgeslagen
	13-08-2018	Sander van Houten	OTIBSUB-?		Added parameter Partition.
	13-08-2018	Sander van Houten	OTIBSUB-107		Added parameter NewCourse.
	09-08-2018	Sander van Houten	OTIBSUB-107		Added parameters InstituteName and CourseName
										and optional call of sub.uspDeclaration_Unknown_Source_Upd.
	02-08-2018	Sander van Houten	CurrentUserID added.
	01-08-2018	Sander van Houten	OTIBSUB-66		StatusReason added.
	19-07-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE
	@DeclarationID				int				= NULL,
	@EmployerNumber				varchar(6)		= '002671',
	@SubsidySchemeID			int				= 1,
	@DeclarationDate			datetime		= '2018-09-10 14:54:52.863',
	@InstituteID				int				= 1786,
	@CourseID					int				= 9912,
	@StartDate					date			= '2018-10-01',
	@EndDate					date			= '2019-03-03',
	@DeclarationAmount			decimal(9,4)	= 1500.0000,
	@ApprovedAmount				decimal(9,4)	= 0,
	@NewCourse					bit				= 0,
	@InstituteName				varchar(100)	= NULL,
	@Partition					xml				= convert(xml,N'<Partitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><Partition><PartitionID>1</PartitionID><PartitionYear>2018</PartitionYear><PartitionAmount>599</PartitionAmount></Partition><Partition><PartitionID>2</PartitionID><PartitionYear>2019</PartitionYear><PartitionAmount>901</PartitionAmount></Partition></Partitions>'),
	@CurrentUserID				int = 3
*/

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate date = GETDATE()

DECLARE @DeclarationStatus varchar(4)

-- Correct parameters
IF @InstituteID = 0
	SET @InstituteID = NULL

IF ISNULL(@DeclarationID, 0) = 0
BEGIN
	-- Add new record
	INSERT INTO sub.tblDeclaration
		(
			EmployerNumber,
			SubsidySchemeID,
			DeclarationDate,
			InstituteID,
			DeclarationStatus,
			StartDate,
			EndDate,
			DeclarationAmount
		)
	VALUES
		(
			@EmployerNumber,
			@SubsidySchemeID,
			@DeclarationDate,
			@InstituteID,
			CASE 
				WHEN @StartDate > @LogDate THEN '0001'
				ELSE '0002'
			END,
			@StartDate,
			@EndDate,
			@DeclarationAmount
		)
	
	-- Save new DeclarationID
	SET	@DeclarationID = SCOPE_IDENTITY()

	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM sub.tblDeclaration 
					   WHERE DeclarationID = @DeclarationID 
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblDeclaration 
					   WHERE DeclarationID = @DeclarationID 
					   FOR XML PATH)

	-- Update existing record.
    -- If an update is done on a declaration that was returned to the employer,
    -- the status is initialized.
	UPDATE	sub.tblDeclaration
	SET
			EmployerNumber			= @EmployerNumber,
			SubsidySchemeID			= @SubsidySchemeID,
			DeclarationDate			= @DeclarationDate,
			InstituteID				= @InstituteID,
			DeclarationStatus		= CASE	WHEN DeclarationStatus IN ('0002', '0019') AND @StartDate > @LogDate 
												THEN '0001' 
											WHEN DeclarationStatus = '0019'  -- AND @StartDate <= @LogDate
												THEN '0002' 
											ELSE DeclarationStatus
									  END,
			StatusReason			= NULL,
			StartDate				= @StartDate,
			EndDate					= @EndDate,
			DeclarationAmount		= @DeclarationAmount
	WHERE	DeclarationID = @DeclarationID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblDeclaration 
					   WHERE DeclarationID = @DeclarationID 
					   FOR XML PATH)
END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '') AS varchar(MAX))
BEGIN
	DECLARE @PreviousDeclarationStatus	varchar(4)

	SELECT	@DeclarationStatus = DeclarationStatus 
	FROM	sub.tblDeclaration 
	WHERE	DeclarationID = @DeclarationID

	SET @KeyID = CAST(@DeclarationID AS varchar(18))

	-- First check on last log on declaration.
	SELECT	@PreviousDeclarationStatus = x.r.value('DeclarationStatus[1]', 'varchar(4)')
	FROM	his.tblHistory
	CROSS APPLY NewValue.nodes('row') AS x(r)
	WHERE	HistoryID IN (
							SELECT	MAX(HistoryID)	AS MaxHistoryID
							FROM	his.tblHistory
							WHERE	TableName = 'sub.tblDeclaration'
							AND		KeyID = @KeyID
						 )

	-- Only write a new log record if there is a change in status
	-- (this is not the case if an employer still has a paymentarrear).
	IF @XMLdel IS NULL
	OR @DeclarationStatus <> @PreviousDeclarationStatus
	BEGIN
		EXEC his.uspHistory_Add
				'sub.tblDeclaration',
				@KeyID,
				@CurrentUserID,
				@LogDate,
				@XMLdel,
				@XMLins
	END

	IF @Partition IS NOT NULL
	BEGIN
		-- Add record(s) to sub.tblDeclaration_Partition.
		DECLARE @tblPartition TABLE 
			(
				PartitionID					int,
				DeclarationID				int,
				PartitionYear				varchar(20),
				PartitionAmount				decimal(19,4),
				PartitionAmountCorrected	decimal(19,4),
				PaymentDate					date,
				PartitionStatus				varchar(4)
			)

		DECLARE @PartitionID				int,
				@PartitionYear				varchar(20),
				@PartitionAmount			decimal(19,4),
				@PartitionAmountCorrected	decimal(19,4),
				@PaymentDate				date,
				@PartitionStatus			varchar(4),
				@EmployeeNumber				varchar(8),
				@VoucherNumber				varchar(3)

		-- Then add refill table variable with new data
		INSERT INTO @tblPartition
			(
				PartitionID,
				DeclarationID,
				PartitionYear,
				PartitionAmount,
				PartitionAmountCorrected,
				PaymentDate,
				PartitionStatus
			)
		SELECT	CAST(x.r.query('PartitionID/text()') AS varchar(18))							AS PartitionID,
				@DeclarationID																	AS DeclarationID,
				CAST(x.r.query('PartitionYear/text()') AS varchar(20))							AS PartitionYear,
				CAST(CAST(x.r.query('PartitionAmount/text()') AS varchar(23)) AS decimal(19,4))	AS PartitionAmount,
				CASE ISNULL(CAST(x.r.query('PartitionAmountCorrected/text()') AS varchar(23)), '')
					WHEN '' THEN CAST(CAST(x.r.query('PartitionAmount/text()') AS varchar(23)) AS decimal(19,4))
					ELSE CAST(CAST(x.r.query('PartitionAmountCorrected/text()') AS varchar(23)) AS decimal(19,4))	
				END																				AS PartitionAmountCorrected,
				CASE ISNULL(CAST(x.r.query('PaymentDate/text()') AS varchar(10)), '')
					WHEN '' THEN NULL
					ELSE CAST(CAST(x.r.query('PaymentDate/text()') AS varchar(10)) AS date)	
				END																				AS PaymentDate,
				ISNULL(CAST(x.r.query('PartitionStatus/text()') AS varchar(4)), '')				AS PartitionStatus
		FROM @Partition.nodes('/Partitions/Partition') AS x(r)

		-- Set the first PaymentDate
		UPDATE	@tblPartition
		SET		PaymentDate = CASE WHEN @DeclarationDate > @StartDate
								THEN @DeclarationDate
								ELSE @StartDate
							  END
		WHERE	PaymentDate IS NULL
		  AND	CAST(LEFT(PartitionYear, 4) as int) = YEAR(@StartDate)

		-- Set the following PaymentDates to the first day of the PartitionYear.
		UPDATE	@tblPartition
		SET		PaymentDate =	CASE 
									WHEN CAST(LEFT(PartitionYear, 4) + '0101' AS date) >= @GetDate 
										THEN CAST(LEFT(PartitionYear, 4) + '0101' AS date) 
									ELSE 
										@GetDate 
								END
		WHERE	PaymentDate IS NULL

		-- Set the PartitionStatus (if necesarry).
		UPDATE	@tblPartition
		SET		PartitionStatus = CASE WHEN PaymentDate > @GetDate 
                                    THEN '0001'
                                    ELSE '0002'
                                  END
		WHERE	PartitionStatus IN ( '', '0019' )

		-- and delete absolete records from tblDeclaration_Partition.
		DECLARE cur_Partition_del CURSOR FOR 
			SELECT 
					dep.PartitionID,
					dpv.EmployeeNumber,
					dpv.VoucherNumber
			FROM	sub.tblDeclaration_Partition dep
			LEFT JOIN @tblPartition par
			ON		par.DeclarationID = dep.DeclarationID
			AND		par.PartitionYear = dep.PartitionYear
			LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
			ON		dpv.DeclarationID = dep.DeclarationID
			AND		dpv.PartitionID = dep.PartitionID
			WHERE	dep.DeclarationID = @DeclarationID
			  AND	par.DeclarationID IS NULL
		
		OPEN cur_Partition_del

		FETCH NEXT FROM cur_Partition_del INTO @PartitionID, @EmployeeNumber, @VoucherNumber

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			IF @VoucherNumber IS NOT NULL
			BEGIN
				EXEC sub.uspDeclaration_Partition_Voucher_Delete
							@DeclarationID,
							@EmployeeNumber,
							@VoucherNumber,
							@CurrentUserID,
							@PartitionID
			END

			EXEC sub.uspDeclaration_Partition_Del
						@PartitionID,
						@CurrentUserID

			FETCH NEXT FROM cur_Partition_del INTO @PartitionID, @EmployeeNumber, @VoucherNumber
		END

		CLOSE cur_Partition_del
		DEALLOCATE cur_Partition_del

		-- and then insert new or update existing records in tblDeclaration_Partition.
		DECLARE cur_Partition_upd CURSOR FOR 
			SELECT 
					t1.PartitionID,
					t1.PartitionYear,
					t1.PartitionAmount,
					t1.PartitionAmountCorrected,
					t1.PaymentDate,
					t1.PartitionStatus
			FROM @tblPartition t1
			INNER JOIN sub.tblDeclaration_Partition t2 ON t2.PartitionID = t1.PartitionID
			WHERE	t1.PartitionYear <> t2.PartitionYear
			   OR 	t1.PartitionAmount <> t2.PartitionAmount
			   OR 	t1.PartitionAmountCorrected <> t2.PartitionAmountCorrected
			   OR 	t1.PaymentDate <> t2.PaymentDate
			   OR 	t1.PartitionStatus <> t2.PartitionStatus

			UNION

			SELECT 
					t1.PartitionID,
					t1.PartitionYear,
					t1.PartitionAmount,
					t1.PartitionAmountCorrected,
					t1.PaymentDate,
					t1.PartitionStatus
			FROM @tblPartition t1
			LEFT JOIN sub.tblDeclaration_Partition t2 ON t2.PartitionID = t1.PartitionID
			WHERE	t2.DeclarationID IS NULL

		OPEN cur_Partition_upd

		FETCH NEXT FROM cur_Partition_upd INTO @PartitionID, @PartitionYear, @PartitionAmount, @PartitionAmountCorrected, @PaymentDate, @PartitionStatus

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			EXEC sub.uspDeclaration_Partition_Upd
						@PartitionID,
						@DeclarationID,
						@PartitionYear,
						@PartitionAmount,
						@PartitionAmountCorrected,
						@PaymentDate,
						@PartitionStatus,
						@CurrentUserID

			FETCH NEXT FROM cur_Partition_upd INTO @PartitionID, @PartitionYear, @PartitionAmount, @PartitionAmountCorrected, @PaymentDate, @PartitionStatus
		END

		CLOSE cur_Partition_upd
		DEALLOCATE cur_Partition_upd
	END	
END

-- SET @NewDeclarationID = @DeclarationID
SELECT DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN 0

/*	== sub.uspDeclaration_Upd =================================================================	*/
