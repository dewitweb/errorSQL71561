CREATE PROCEDURE [hrs].[uspHorusContactPerson_Upd]
@Loginname				varchar(20),
@UserID_DS				int,
@Initials				varchar(15),
@Firstname				varchar(50),
@Infix					varchar(15),
@Surname				varchar(50),
@Email					varchar(50),
@Phone					varchar(15),
@Gender					varchar(1)
AS
/*	==========================================================================================
	Purpose:	Update or insert a contactperson record in Horus.

	Notes:		This procedure synchronizes Horus in the following steps.
				1. Check if the contactperson allready exists.
				-> Yes
					2. Update the data for the contactperson.
					3. (Re)link the contactperson as Medewerker personeelszaken.
				-> No
					2. Insert the new contactperson
					3. (Re)link the contactperson as Medewerker personeelszaken.

	19-12-2019	Sander van Houten		OTIBSUB-1762	Added BEGIN TRY routine.
	11-07-2019	Sander van Houten		OTIBSUB-1075	Update Horus.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @Loginname	varchar(20) = '085475',
		@UserID_DS	int = 48897,
		@Initials	varchar(15) = 'S',
		@Firstname	varchar(50) = 'Azimi',
		@Infix		varchar(15) = NULL,
		@Surname	varchar(50) = 'Opl.Bed Instwerk Brabant-Zeeland Bv',
		@Email		varchar(50) = 'd.drooij@otib.nl',
		@Phone		varchar(15) = '085-4890483',
		@Gender		varchar(1) = ''
--	*/

--	Declare variables.
DECLARE @SQL					varchar(max),
		@Result					varchar(8000),
		@FinalResult			varchar(50) = 'Goed',
		@cpn_id					varchar(10),
		@ErrorNumber			int,
		@ErrorLine				int,
		@ErrorMessage			varchar(200),
		@FunctionDescription	varchar(100) = 'Medewerker personeelszaken'

DECLARE @tblResult TABLE (Result xml)

IF	LEN(@Loginname) = 6
AND	ISNUMERIC(@Loginname) = 1
AND EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN TRY
	-- Check if Contact allready exists in Horus.
	SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_ZOEK_CONTACTPERSOON('
				+ '''' + @Loginname + ''', '
				+ '''' + ISNULL(@Initials, '') + ''','
				+ '''' + ISNULL(@Infix, '') + ''','
				+ '''' + @Surname + ''','
				+ '''' + ISNULL(@Gender, '') + ''''
				+ '); END;'

	PRINT @SQL

	IF DB_NAME() = 'OTIBDS'
		EXEC(@SQL, @Result OUTPUT) AT HORUS_P
	ELSE
		EXEC(@SQL, @Result OUTPUT) AT HORUS_A

	PRINT @Result

	-- Save result.
	INSERT INTO @tblResult (Result) VALUES (@Result)

	SELECT	@FinalResult = x.r.value('resultaat[1]', 'varchar(4)'),
			@cpn_id = x.r.value('cpn_id[1]', 'int')
	FROM @tblResult
	CROSS APPLY Result.nodes('hrs_pck_otibds.wgr_zoek_contactpersoon') AS x(r)

	PRINT @FinalResult

	IF @FinalResult = 'Goed'
	BEGIN	-- If Contact allready exists the change values.
		SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_WIJZIG_CONTACTPERSOON('
				+ '''' + CAST(@cpn_id AS varchar(10)) + ''', '
				+ '''' + ISNULL(@Initials, '') + ''','
				+ '''' + ISNULL(@Firstname, '') + ''','
				+ '''' + ISNULL(@Infix, '') + ''','
				+ '''' + @Surname + ''','
				+ '''' + ISNULL(@Gender, '') + ''','
				+ '''' + ISNULL(@Phone, '') + ''','
				+ '''' + @Email + ''''
				+ '); END;'

		PRINT @SQL

		IF DB_NAME() = 'OTIBDS'
			EXEC(@SQL, @Result OUTPUT) AT HORUS_P
		ELSE
			EXEC(@SQL, @Result OUTPUT) AT HORUS_A

		PRINT @Result

		-- Save result.
		DELETE FROM @tblResult

		INSERT INTO @tblResult (Result) VALUES (@Result)

		SELECT	@FinalResult = x.r.value('resultaat[1]', 'varchar(4)')
		FROM	@tblResult
		CROSS APPLY Result.nodes('hrs_pck_otibds.wgr_wijzig_contactpersoon') AS x(r)

		PRINT @FinalResult

		IF @FinalResult <> 'Goed'
		BEGIN
			SELECT	@ErrorNumber = 1,
					@ErrorLine = 100,
					@ErrorMessage = 'Wijzigen contactpersoon met UserID ' + 
									CAST(@UserID_DS AS varchar(18)) + 
									' is niet succesvol verlopen in Horus.'
		END
	END
	ELSE
	BEGIN	-- If Contact does not exists add a record.
		SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_TOEVOEGEN_CONTACTPERSOON('
				+ '''' + @Loginname + ''', '
				+ '''' + ISNULL(@Initials, '') + ''','
				+ '''' + ISNULL(@Firstname, '') + ''','
				+ '''' + ISNULL(@Infix, '') + ''','
				+ '''' + @Surname + ''','
				+ '''' + ISNULL(@Gender, '') + ''','
				+ '''' + ISNULL(@Phone, '') + ''','
				+ '''' + @Email + ''''
				+ '); END;'

		PRINT @SQL

		IF DB_NAME() = 'OTIBDS'
			EXEC(@SQL, @Result OUTPUT) AT HORUS_P
		ELSE
			EXEC(@SQL, @Result OUTPUT) AT HORUS_A

		-- Save result.
		DELETE FROM @tblResult

		INSERT INTO @tblResult (Result) VALUES (@Result)

		SELECT	@FinalResult = x.r.value('resultaat[1]', 'varchar(4)'),
				@cpn_id = x.r.value('cpn_id[1]', 'int')
		FROM	@tblResult
		CROSS APPLY Result.nodes('hrs_pck_otibds.wgr_toevoegen_contactpersoon') AS x(r)

		PRINT @FinalResult

		IF @FinalResult <> 'Goed'
		BEGIN
			SELECT	@ErrorNumber = 2,
					@ErrorLine = 145,
					@ErrorMessage = 'Toevoegen contactpersoon met UserID ' + 
									CAST(@UserID_DS AS varchar(18)) + 
									' is niet succesvol verlopen in Horus.'
		END
	END

	-- Link contact as Medewerker personeelszaken to employer.
	SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_CONTACTPERSOON_PROJECT('
			+ '''' + @cpn_id + ''', '
			+ '''' + @FunctionDescription + ''''
			+ '); END;'

	PRINT @SQL

	IF DB_NAME() = 'OTIBDS'
		EXEC(@SQL, @Result OUTPUT) AT HORUS_P
	ELSE
		EXEC(@SQL, @Result OUTPUT) AT HORUS_A

	-- Save result.
	DELETE FROM @tblResult

	PRINT @Result

	INSERT INTO @tblResult (Result) VALUES (@Result)

	SELECT	@FinalResult = x.r.value('resultaat[1]', 'varchar(4)')
	FROM	@tblResult
	CROSS APPLY Result.nodes('hrs_pck_otibds.wgr_wijzig_contactpersoon') AS x(r)

	IF @FinalResult <> 'Goed'
	BEGIN
		SELECT	@ErrorNumber = 3,
				@ErrorLine = 175,
				@ErrorMessage = 'Koppelen contactpersoon met UserID ' + 
								CAST(@UserID_DS AS varchar(18)) + 
								' als Medewerker personeelszaken' +
								' is niet succesvol verlopen in Horus.'
	END
END TRY
BEGIN CATCH
	SET @FinalResult = 'Fout'
END CATCH

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF @FinalResult = 'Goed'
	RETURN 0
ELSE
BEGIN
	INSERT INTO [ait].[tblErrorLog]
		(
			ErrorDate,
			ErrorNumber,
			ErrorSeverity,
			ErrorState,
			ErrorProcedure,
			ErrorLine,
			ErrorMessage,
			SendEmail,
			EmailSent
		)
	SELECT  GETDATE()						AS ErrorDate,
			@ErrorNumber					AS ErrorNumber,
			1								AS ErrorSeverity,
			1								AS ErrorState,
			'hrs.uspHorusContactPerson_Upd'	AS ErrorProcedure,
			@ErrorLine						AS ErrorLine,
			@ErrorMessage					AS ErrorMessage,
			1								AS SendEmail,
			NULL							AS EmailSent
	FROM	sys.procedures sp
	INNER JOIN sys.schemas sch ON sch.schema_id = sp.schema_id
	WHERE	sp.object_id = @@PROCID

	RETURN 1
END

/*	== hrs.uspHorusContactPerson_Upd =========================================================	*/
