CREATE PROCEDURE [sub].[uspEducation_NominalDuration_History_Process]
AS
/*	==========================================================================================
	Purpose:	Process a nominal duration change for an education.

	Notes:		The running declarations that are linked to this education need to be checked
				and the referencedate(s) (partitions) may need to be corrected.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	02-09-2019	Sander van Houten	OTIBSUB-1262	Added sending e-mail 
										when nominal duration is changed.
	23-08-2019	Sander van Houten	OTIBSUB-1263	Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 25
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

DECLARE @LogDate				datetime = GETDATE(),
		@EducationID			int,
		@EducationName			varchar(200),
		@NominalDuration_Old	tinyint,
		@NominalDuration_New	tinyint,
		@DateCreated			datetime

DECLARE @DeclarationID			int,
		@EmployerNumber			varchar(6),
		@EmployeeNumber			varchar(8),
		@DeclarationDate		date,
		@InstituteID			int,
		@StartDate				date,
		@EndDate				date,
		@BPV_StartDate			date,
		@BPV_EndDate			date,
		@BPV_Extension			bit,
		@BPV_TerminationReason	varchar(20),
		@InstituteName			varchar(100),
		@CurrentUserID			int = 1,
		@MailBanner				varchar(100)
		

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

DECLARE cur_ND CURSOR 
	LOCAL    
	STATIC
	READ_ONLY
	FORWARD_ONLY
	FOR 
	SELECT	EducationID,
			COALESCE(NominalDuration_Old, 0),
			NominalDuration_New,
			DateCreated
	FROM	sub.tblEducation_NominalDuration_History
	WHERE	DateProcessed IS NULL
	ORDER BY 
			DateCreated

/* Process all changes.	*/
OPEN cur_ND

FETCH NEXT FROM cur_ND INTO @EducationID, @NominalDuration_Old, @NominalDuration_New, @DateCreated

WHILE @@FETCH_STATUS = 0  
BEGIN
	IF @NominalDuration_Old = 0
	BEGIN	-- Select running declarations for this education.
		DECLARE cur_Declaration CURSOR 
			LOCAL    
			STATIC
			READ_ONLY
			FORWARD_ONLY
			FOR 
			SELECT	DeclarationID
			FROM	stip.tblDeclaration
			WHERE	EducationID = @EducationID

		OPEN cur_Declaration

		FETCH NEXT FROM cur_Declaration INTO @DeclarationID

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SELECT	@EmployerNumber = d.EmployerNumber,
					@EmployeeNumber = dem.EmployeeNumber,
					@DeclarationDate = d.DeclarationDate,
					@InstituteID = d.InstituteID,
					@StartDate = d.StartDate,
					@EndDate = d.EndDate, 
					@BPV_StartDate = NULL, 
					@BPV_EndDate = NULL, 
					@BPV_Extension = NULL, 
					@BPV_TerminationReason = NULL, 
					@InstituteName = i.InstituteName
			FROM	sub.tblDeclaration d
			INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
			LEFT JOIN sub.tblInstitute i ON i.InstituteID = d.InstituteID
			WHERE	d.DeclarationID = @DeclarationID

			IF @EmployeeNumber IS NOT NULL
			BEGIN
				EXECUTE [stip].[uspDeclaration_Update]
					@DeclarationID,
					@EmployerNumber,
					@EmployeeNumber,
					@DeclarationDate,
					@InstituteID,
					@EducationID,
					@StartDate,
					@EndDate,
					@BPV_StartDate,
					@BPV_EndDate,
					@BPV_Extension,
					@BPV_TerminationReason,
					@InstituteName,
					@CurrentUserID
			END

			FETCH NEXT FROM cur_Declaration INTO @DeclarationID
		END

		CLOSE cur_Declaration
		DEALLOCATE cur_Declaration
	END
	ELSE
	BEGIN	-- Send an e-mail to OTIB.
		-- Get education name.
		SELECT	@EducationName = EducationName
		FROM	sub.tblEducation
		WHERE	EducationID = @EducationID

		-- Create e-mail.
		SET @SubjectAddition = @EducationName

		SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @Recipients = 'support@otib.nl'
		SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
		SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

		SET @EmailBody = REPLACE(@EmailBody, '<%Loginname%>', ISNULL(@EducationName, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%NominalDuration_Old%>', ISNULL(CAST(@NominalDuration_Old AS varchar(2)), ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%NominalDuration_New%>', ISNULL(CAST(@NominalDuration_New AS varchar(2)), ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

		--SET @EmailHeaders = '<headers>'
		--					+ '<header key="subject" value="Gewijzigde nominale duur bij opleiding ' + @EducationName + '" />'
		--					+ '<header key="to" value="support@otib.nl" />'
		--					+ '</headers>'

		--SET @EmailBody = '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste Support Desk,' +
		--				 '<br><br>' +
		--				 'De nominale duur bij opleiding ' + @EducationName + ' in Etalage is gewijzigd van ' + 
		--				 CAST(@NominalDuration_Old AS varchar(2)) + ' jaar in ' + CAST(@NominalDuration_New AS varchar(2)) + ' jaar.<br>' +
		--				 'Voor deze opleiding lopen momenteel de volgende STIP-aanvragen:<br>' + 
		--				 '<table cellspacing="0" cellpadding="0" border="0" width="100">'

		-- Get running declarations.
		DECLARE cur_Declaration CURSOR 
			LOCAL    
			STATIC
			READ_ONLY
			FORWARD_ONLY
			FOR 
			SELECT	DeclarationID
			FROM	stip.tblDeclaration
			WHERE	EducationID = @EducationID
			AND		TerminationDate IS NULL

		OPEN cur_Declaration

		FETCH NEXT FROM cur_Declaration INTO @DeclarationID

		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @EmailBody = @EmailBody +
				'<tr><td width="100">' + CAST(@DeclarationID AS varchar(18)) + '</td></tr>'

			FETCH NEXT FROM cur_Declaration INTO @DeclarationID
		END

		CLOSE cur_Declaration
		DEALLOCATE cur_Declaration

		SET @EmailBody = @EmailBody + '</table></p>'

		INSERT INTO eml.tblEmail 
			(
				EmailHeaders, 
				EmailBody, 
				CreationDate, 
				SentDate
			) 
		VALUES 
			(
				@EmailHeader, 
				@EmailBody,
				@LogDate,
				NULL
			)
	END

	-- Set record to processed.
	UPDATE	sub.tblEducation_NominalDuration_History
	SET		DateProcessed = GETDATE()
	WHERE	EducationID = @EducationID
	AND		DateCreated = @DateCreated

	FETCH NEXT FROM cur_ND INTO @EducationID, @NominalDuration_Old, @NominalDuration_New, @DateCreated
END

CLOSE cur_ND
DEALLOCATE cur_ND

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEducation_NominalDuration_History_Process ======================================	*/	

