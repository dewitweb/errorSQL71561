
CREATE PROCEDURE [hrs].[uspDeclaration_Upd]
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

	07-11-2018 Jaap van Assenbergh	OTIBSUB-416 Parameters verwijderen uit subDeclaration_Upd
									- DeclarationStatus
									- StatusReason
									- InternalMemo
	04-10-2018	Sander van Houten	Added PartitionAmountCorrected 
									and PartitionStatus (OTIBSUB-313).
	10-09-2018	Jaap van Assenbergh	OTIBSUB-213 Declaratie partitions worden niet opgeslagen
	13-08-2018	Sander van Houten	Added parameter Partition (OTIBSUB-?).
	13-08-2018	Sander van Houten	Added parameter NewCourse (OTIBSUB-107).
	09-08-2018	Sander van Houten	Added parameters InstituteName and CourseName
									and optional call of sub.uspDeclaration_Unknown_Source_Upd
									(OTIBSUB-107).
	02-08-2018	Sander van Houten	CurrentUserID added.
	01-08-2018	Sander van Houten	StatusReason added (OTIBSUB-66).
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

DECLARE @XMLdel	xml,
		@XMLins	xml,
		@LogDate datetime = GETDATE()

DECLARE @GetDate date = GETDATE()

DECLARE @DeclarationStatus varchar(4)

-- Correct parameters
IF @InstituteID = 0
	SET @InstituteID = NULL

IF NOT EXISTS (SELECT 1 FROM sub.tblDeclaration WHERE DeclarationID = @DeclarationID)
BEGIN
	-- Add new record
	SET IDENTITY_INSERT sub.tblDeclaration ON

	INSERT INTO sub.tblDeclaration
		(
			DeclarationID,
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
			@DeclarationID,
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

	SET IDENTITY_INSERT sub.tblDeclaration OFF

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

	-- Update exisiting record
	UPDATE	sub.tblDeclaration
	SET
			EmployerNumber			= @EmployerNumber,
			SubsidySchemeID			= @SubsidySchemeID,
			DeclarationDate			= @DeclarationDate,
			InstituteID				= @InstituteID,
			DeclarationStatus		= CASE WHEN DeclarationStatus = '0002' AND @StartDate > @LogDate 
										   THEN '0001' 
										   ELSE DeclarationStatus
									  END,
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
IF @@ROWCOUNT > 0
BEGIN
	SELECT	@DeclarationStatus = DeclarationStatus 
	FROM	sub.tblDeclaration 
	WHERE	DeclarationID = @DeclarationID

	EXEC his.uspHistory_Add
			'sub.tblDeclaration',
			@DeclarationID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

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
				@PartitionStatus			varchar(4)

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
				CASE ISNULL(CAST(x.r.query('PaymentDate/text()') AS varchar(30)), '')
					WHEN '' THEN NULL
					ELSE CAST(CAST(x.r.query('PaymentDate/text()') AS varchar(30)) AS date)	
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
		SET		PartitionStatus = CASE 
									WHEN @DeclarationStatus = '0011' THEN '0010'
									WHEN @DeclarationStatus = '0013' THEN '0012'
									WHEN @DeclarationStatus = '0015' THEN '0014'
									ELSE @DeclarationStatus
								  END
		WHERE	PartitionStatus = ''

		-- and delete absolete records from tblDeclaration_Partition.
		DECLARE cur_Partition_del CURSOR FOR 
			SELECT 
					dep.PartitionID
			FROM	sub.tblDeclaration_Partition dep
			LEFT JOIN @tblPartition par
			ON		par.DeclarationID = @DeclarationID
			AND		par.PartitionYear = @PartitionYear
			WHERE	dep.DeclarationID = @DeclarationID
			  AND	par.DeclarationID IS NULL
		
		OPEN cur_Partition_del

		FETCH NEXT FROM cur_Partition_del INTO @PartitionID

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			EXEC sub.uspDeclaration_Partition_Del
						@PartitionID,
						@CurrentUserID

			FETCH NEXT FROM cur_Partition_del INTO @PartitionID
		END

		CLOSE cur_Partition_del
		DEALLOCATE cur_Partition_del

		-- and then insert new or update existing records in tblDeclaration_Partition.
		DECLARE cur_Partition_upd CURSOR FOR 
			SELECT 
				PartitionID,
				PartitionYear,
				PartitionAmount,
				PartitionAmountCorrected,
				PaymentDate,
				PartitionStatus
			FROM @tblPartition
		
		OPEN cur_Partition_upd

		FETCH NEXT FROM cur_Partition_upd INTO @PartitionID, @PartitionYear, @PartitionAmount, @PartitionAmountCorrected, @PaymentDate, @PartitionStatus

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			EXEC hrs.uspDeclaration_Partition_Upd
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

/*	== hrs.uspDeclaration_Upd =================================================================	*/
