
CREATE PROCEDURE [sub].[uspInstitute_Upd]
@InstituteID	int,
@InstituteName	varchar(255),
@Location varchar(24),
@EndDate date,
@HorusID varchar(6),
@IsEVC bit,
@IsEVCWV bit,
@IsEducationProvider bit,
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Add or Update sub.tblInstitute on the basis of known InstituteID (from Etalage).

	08-08-2018	Sander van Houten		Initial version (OTIBSUB-111).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @SubsidyschemeID int
DECLARE @SearchName varchar(255)

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)


--	Update SearchName

SELECT	@SearchName = sub.usfCreateSearchString(@InstituteName)

IF NOT EXISTS (SELECT 1 FROM sub.tblInstitute WHERE InstituteID = @InstituteID)
BEGIN
	-- Add new record
	INSERT INTO sub.tblInstitute
        (
			InstituteID,
            InstituteName,
			[Location],
			EndDate,
			HorusID,
			SearchName
		)
	VALUES
		(
			@InstituteID,
			@InstituteName,
			@Location,
			@EndDate,
			@HorusID,
			@SearchName
		)
	
	-- Save new record
	SELECT	@XMLdel = NULL,
			@XMLins = (SELECT * 
					   FROM sub.tblInstitute
					   WHERE InstituteID = @InstituteID
					   FOR XML PATH)
END
ELSE
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT * 
					   FROM sub.tblInstitute
					   WHERE InstituteID = @InstituteID
					   FOR XML PATH)

	-- Update existing record
	UPDATE	sub.tblInstitute
	SET
			InstituteName	= @InstituteName,
			[Location]		= @Location,
			EndDate			= @EndDate,
			HorusID			= @HorusID,
			SearchName		= @SearchName
	WHERE	InstituteID = @InstituteID

	-- Save new record
	SELECT	@XMLins = (SELECT * 
					   FROM sub.tblInstitute
					   WHERE InstituteID = @InstituteID
					   FOR XML PATH)
END

-- Log action in tblHistory
IF CAST(ISNULL(@XMLdel, '') as varchar(MAX)) <> CAST(ISNULL(@XMLins, '') as varchar(MAX))
BEGIN
	SET @KeyID = @InstituteID

	EXEC his.uspHistory_Add
			'sub.tblInstitute',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

END

/*  Update, add or delete EVC ================================================================	*/
SET @SubsidyschemeID = 3
EXECUTE sub.uspSubsidyScheme_Institute_Add_Del 
	@SubsidyschemeID,
	@InstituteID,
	@IsEVC,
	@CurrentUserID

/*  Update, add or delete EVC ================================================================	*/
SET @SubsidyschemeID = 5
EXECUTE sub.uspSubsidyScheme_Institute_Add_Del 
	@SubsidyschemeID,
	@InstituteID,
	@IsEVCWV,
	@CurrentUserID

IF	@IsEducationProvider = 1 -- Alleen toevoegen. Niet verwijderen als het instituut geen beroepsopleidingen meer heeft
BEGIN
	SET @SubsidyschemeID = 4
	EXECUTE sub.uspSubsidyScheme_Institute_Add_Del 
		@SubsidyschemeID,
		@InstituteID,
		@IsEducationProvider,
		@CurrentUserID
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspInstitute_Upd ==================================================================	*/
