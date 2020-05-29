CREATE PROCEDURE [sub].[uspEmployer_Imp]
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Import employer data from OTIBMNData database.

	20-01-2020	Sander van Houten	OTIBSUB-1839    Enlarged Housenumber fields 
                                        from 10 to 20 characters.
	28-10-2019	Sander van Houten	OTIBSUB-1446    Added insert into auth.tblUser_Role_SubsidyScheme.
	12-07-2019	Sander van Houten	OTIBSUB-1075	Added parameter @Gender in call to
										auth.uspUser_Upd.
	20-06-2019	Sander van Houten	OTIBSUB-1241	Added PaymentStop processing.
	20-06-2019	Sander van Houten	OTIBSUB-1196	Added TerminationReason.
	14-06-2019	Sander van Houten	OTIBSUB-1186	Added postal address data.
	12-02-2019	Jaap van Assenbergh	OTIBSUB-761		Werkgever kan niet inloggen in DS
	19-11-2018	Sander van Houten	OTIBSUB-98		Added Ascription.
	17-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET NOCOUNT ON

DECLARE	@StartTimeStamp	datetime = GETDATE(),
		@TimeStamp		datetime = GETDATE(),
		@GetDate		date = GETDATE()

DECLARE @Employer TABLE (
	EmployerNumber				varchar(6),
	EmployerName				varchar(100),
	Email						varchar(254),
	IBAN						varchar(34),
	Ascription					varchar(100),
	CoC							varchar(11),
	Phone						varchar(30),
	BusinessAddressStreet		varchar(100),
	BusinessAddressHousenumber	varchar(20),
	BusinessAddressZipcode		varchar(10),
	BusinessAddressCity			varchar(100),
	BusinessAddressCountrycode	varchar(2),
	PostalAddressStreet			varchar(100),
	PostalAddressHousenumber	varchar(20),
	PostalAddressZipcode		varchar(10),
	PostalAddressCity			varchar(100),
	PostalAddressCountrycode	varchar(2),
	StartDateMembership			date,
	EndDateMembership			date,
	TerminationReason			varchar(4),
	ImportAction				varchar(6) )

/*	Log start of import.	*/
INSERT INTO sub.tblImportLog
			([Log]
			,[TimeStamp]
			,Duration)
		VALUES
			('De import van MN werkgever data is gestart.'
			,@StartTimeStamp
			,0)

/*	Select all new employers	*/
SET @TimeStamp = GETDATE()

INSERT INTO @Employer 
	(
		EmployerNumber,
		EmployerName,
		Email,
		IBAN,
		Ascription,
		CoC,
		Phone,
		BusinessAddressStreet,
		BusinessAddressHousenumber,
		BusinessAddressZipcode,
		BusinessAddressCity,
		BusinessAddressCountrycode,
		PostalAddressStreet,
		PostalAddressHousenumber,
		PostalAddressZipcode,
		PostalAddressCity,
		PostalAddressCountrycode,
		StartDateMembership,
		EndDateMembership,
		TerminationReason,
		ImportAction 
	)
SELECT	crm.nummer,
		crm.naam,
		'',
		crm.iban,
		crm.naam,
		crm.kvkNummer,
		crm.telefoonnummer,
		crm.zaakAdresStraat,
		crm.zaakAdresHuisnummer,
		crm.zaakAdresPostcode,
		crm.zaakAdresPlaats,
		crm.zaakAdresLandcode,
		crm.correspondentieAdresStraat,
		crm.correspondentieAdresHuisnummer,
		crm.correspondentieAdresPostcode,
		crm.correspondentieAdresPlaats,
		crm.correspondentieAdresLandcode,
		crm.ingangsdatumLidmaatschap,
		crm.einddatumLidmaatschap,
		crm.redenBeeindiging,
		'insert'
FROM	crm.viewEmployer_MNData_MostRecent crm
LEFT JOIN sub.tblEmployer emp
ON		emp.EmployerNumber = crm.nummer
WHERE	emp.EmployerNumber IS NULL

/*	Log inserts.	*/
INSERT INTO sub.tblImportLog
           ([Log]
		   ,[TimeStamp]
		   ,Duration)
     VALUES
           ('Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' nieuwe werkgever records geselecteerd.'
           ,GETDATE()
           ,DATEDIFF(ss, @TimeStamp, GETDATE()))

/*	Select all existing employers that are updated in CRM	*/
SET @TimeStamp = GETDATE()

INSERT INTO @Employer 
	(
		EmployerNumber,
		EmployerName,
		Email,
		IBAN,
		Ascription,
		CoC,
		Phone,
		BusinessAddressStreet,
		BusinessAddressHousenumber,
		BusinessAddressZipcode,
		BusinessAddressCity,
		BusinessAddressCountrycode,
		PostalAddressStreet,
		PostalAddressHousenumber,
		PostalAddressZipcode,
		PostalAddressCity,
		PostalAddressCountrycode,
		StartDateMembership,
		EndDateMembership,
		TerminationReason,
		ImportAction 
	)
SELECT	crm.nummer,
		crm.naam,
		emp.Email,
		emp.iban,
		emp.Ascription,
		crm.kvkNummer,
		crm.telefoonnummer,
		crm.zaakAdresStraat,
		crm.zaakAdresHuisnummer,
		crm.zaakAdresPostcode,
		crm.zaakAdresPlaats,
		crm.zaakAdresLandcode,
		crm.correspondentieAdresStraat,
		crm.correspondentieAdresHuisnummer,
		crm.correspondentieAdresPostcode,
		crm.correspondentieAdresPlaats,
		crm.correspondentieAdresLandcode,
		crm.ingangsdatumLidmaatschap,
		crm.einddatumLidmaatschap,
		crm.redenBeeindiging,
		'update'
FROM	crm.viewEmployer_MNData_MostRecent crm
INNER JOIN sub.tblEmployer emp
ON		emp.EmployerNumber = crm.nummer
WHERE	COALESCE(emp.EmployerName, '') <> COALESCE(crm.naam, '')
   OR	COALESCE(emp.CoC, '') <> COALESCE(crm.kvkNummer, '')
   OR	COALESCE(emp.Phone, '') <> COALESCE(crm.telefoonnummer, '')
   OR	COALESCE(emp.BusinessAddressStreet, '') <> COALESCE(crm.zaakAdresStraat, '')
   OR	COALESCE(emp.BusinessAddressHousenumber, '') <> COALESCE(crm.zaakAdresHuisnummer, '')
   OR	COALESCE(emp.BusinessAddressZipcode, '') <> COALESCE(crm.zaakAdresPostcode, '')
   OR	COALESCE(emp.BusinessAddressCity, '') <> COALESCE(crm.zaakAdresPlaats, '')
   OR	COALESCE(emp.BusinessAddressCountrycode, '') <> COALESCE(crm.zaakAdresLandcode, '')
   OR	COALESCE(emp.PostalAddressStreet, '') <> COALESCE(crm.correspondentieAdresStraat, '')
   OR	COALESCE(emp.PostalAddressHousenumber, '') <> COALESCE(crm.correspondentieAdresHuisnummer, '')
   OR	COALESCE(emp.PostalAddressZipcode, '') <> COALESCE(crm.correspondentieAdresPostcode, '')
   OR	COALESCE(emp.PostalAddressCity, '') <> COALESCE(crm.correspondentieAdresPlaats, '')
   OR	COALESCE(emp.PostalAddressCountrycode, '') <> COALESCE(crm.correspondentieAdresLandcode, '')
   OR	COALESCE(emp.StartDateMembership, '19000101') <> COALESCE(crm.ingangsdatumLidmaatschap, '19000101')
   OR	COALESCE(emp.EndDateMembership, '19000101') <> COALESCE(crm.einddatumLidmaatschap, '19000101')
   OR	COALESCE(emp.TerminationReason, '') <> COALESCE(crm.redenBeeindiging, '')

/*	Log updates.	*/
INSERT INTO sub.tblImportLog
           ([Log]
		   ,[TimeStamp]
		   ,Duration)
     VALUES
           ('Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' te wijzigen werkgever records geselecteerd.'
           ,GETDATE()
           ,DATEDIFF(ss, @TimeStamp, GETDATE()))

IF (SELECT COUNT(1) FROM @Employer) > 0
BEGIN
	/*	Use standard procedure to process changes	*/
	DECLARE @EmployerNumber				varchar(6),
			@EmployerName				varchar(100),
			@Email						varchar(254),
			@IBAN						varchar(34),
			@Ascription					varchar(100),
			@CoC						varchar(11),
			@Phone						varchar(30),
			@BusinessAddressStreet		varchar(100),
			@BusinessAddressHousenumber	varchar(20),
			@BusinessAddressZipcode		varchar(10),
			@BusinessAddressCity		varchar(100),
			@BusinessAddressCountrycode	varchar(2),
			@PostalAddressStreet		varchar(100),
			@PostalAddressHousenumber	varchar(20),
			@PostalAddressZipcode		varchar(10),
			@PostalAddressCity			varchar(100),
			@PostalAddressCountrycode	varchar(2),
			@StartDateMembership		date,
			@EndDateMembership			date,
			@TerminationReason			varchar(4),
			@ImportAction				varchar(6),
			@RC							int

	DECLARE	@UserID						int,
			@RoleID						int,
			@Initials					varchar(15),
			@Firstname					varchar(50),
			@Infix						varchar(15),
			@Surname					varchar(50),
			@Loginname					varchar(50),
			@PasswordHash				nvarchar(62),
			@PasswordChangeCode			nvarchar(62),
			@PasswordMustChange			bit,
			@PasswordExpirationDate		date,
			@PasswordFailedAttempts		tinyint,
			@IsLockedOut				datetime,
			@Active						bit,
			@FunctionDescription		varchar(100),
			@Gender						varchar(1) = ''

	DECLARE @PaymentStopID int,
			@StartDate date,
			@StartReason varchar(254),
			@EndDate date,
			@EndReason varchar(100),
			@PaymentstopType varchar(4)

	DECLARE cur_Employer CURSOR FOR 
		SELECT 
			EmployerNumber,
			EmployerName,
			Email,
			IBAN,
			Ascription,
			CoC,
			Phone,
			BusinessAddressStreet,
			BusinessAddressHousenumber,
			BusinessAddressZipcode,
			BusinessAddressCity,
			BusinessAddressCountrycode,
			PostalAddressStreet,
			PostalAddressHousenumber,
			PostalAddressZipcode,
			PostalAddressCity,
			PostalAddressCountrycode,
			StartDateMembership,
			EndDateMembership,
			TerminationReason,
			ImportAction
		FROM @Employer
		ORDER BY	ImportAction DESC, 
					EmployerNumber ASC
		
	OPEN cur_Employer

	FETCH NEXT FROM cur_Employer INTO @EmployerNumber, @EmployerName, @Email, @IBAN, @Ascription, @CoC, @Phone, @BusinessAddressStreet, 
										@BusinessAddressHousenumber, @BusinessAddressZipcode, @BusinessAddressCity, @BusinessAddressCountrycode, 
										@PostalAddressStreet, @PostalAddressHousenumber, @PostalAddressZipcode, @PostalAddressCity, 
										@PostalAddressCountrycode, @StartDateMembership, @EndDateMembership, @TerminationReason, @ImportAction

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		/* Call standard procedure	*/
		EXECUTE @RC = [sub].[uspEmployer_Upd] 
			@EmployerNumber,
			@EmployerName,
			@Email,
			@IBAN,
			@Ascription,
			@CoC,
			@Phone,
			@BusinessAddressStreet,
			@BusinessAddressHousenumber,
			@BusinessAddressZipcode,
			@BusinessAddressCity,
			@BusinessAddressCountrycode,
			@PostalAddressStreet,
			@PostalAddressHousenumber,
			@PostalAddressZipcode,
			@PostalAddressCity,
			@PostalAddressCountrycode,
			@StartDateMembership,
			@EndDateMembership,
			@TerminationReason,
		  	@CurrentUserID

		/* Insert new user record if new employer.	*/
		IF @ImportAction = 'Insert'
		BEGIN
			SELECT	@Surname = @EmployerName,
					@Loginname = @EmployerNumber,
					@PasswordHash = 'Leeg',
					@PasswordMustChange = 0,
					@Active = CASE WHEN @StartDateMembership <= @GetDate AND COALESCE(@EndDateMembership, '20990101') > @GetDate
									THEN 1
									ELSE 0
							  END,
					@UserID = 0,
					@RoleID = 3

			-- Insert new user record.
			EXECUTE @RC = [auth].[uspUser_Upd] 
			   @UserID
			  ,@Initials
			  ,@Firstname
			  ,@Infix
			  ,@Surname
			  ,@Email
			  ,@Phone
			  ,@Loginname
			  ,@PasswordHash
			  ,@PasswordChangeCode
			  ,@PasswordMustChange
			  ,@PasswordExpirationDate
			  ,@PasswordFailedAttempts
			  ,@IsLockedOut
			  ,@Active
			  ,@FunctionDescription
			  ,@Gender
			  ,@CurrentUserID

			SELECT @UserID = UserID FROM auth.tblUser WHERE Loginname = @Loginname

			-- Link standard roles to new user.
			EXECUTE @RC = [auth].[uspUser_Role_Add] 
			   @UserID
			  ,@RoleID
			  ,@CurrentUserID

			SET @RoleID = 1

			EXECUTE @RC = [auth].[uspUser_Role_Add] 
			   @UserID
			  ,@RoleID
			  ,@CurrentUserID

            -- Link all relevant subsidyschemes to user_role.
            INSERT INTO auth.tblUser_Role_SubsidyScheme 
                (
                    UserID, 
                    RoleID, 
                    SubsidySchemeID
                )
            SELECT  @UserID, 
                    @RoleID, 
                    ssc.SubsidySchemeID
            FROM  	sub.tblSubsidyScheme ssc 
            WHERE   ssc.SubsidySchemeID <> 2    --BPV

            -- Create new user validation record.
			DECLARE @ContactDetailsCheck bit = 0,
					@AgreementCheck bit = 0,
					@EmailCheck bit = 0,
					@EmailValidationToken varchar(50) = NULL,
					@EmailValidationDateTime datetime = NULL

			EXECUTE @RC = [auth].[uspUserValidation_Upd] 
				@UserID
				,@ContactDetailsCheck
				,@AgreementCheck
				,@EmailCheck
				,@EmailValidationToken
				,@EmailValidationDateTime
				,@CurrentUserID

			-- Link new employer to new user.
			DECLARE @RequestSend datetime = GETDATE(),
					@RequestApproved datetime = GETDATE(),
					@RequestDenied datetime = NULL

			EXECUTE @RC = [sub].[uspUser_Role_Employer_Add] 
			   @UserID
			  ,@EmployerNumber
			  ,@RequestSend
			  ,@RequestApproved
			  ,@RequestDenied
			  ,@RoleID

			--	PaymentStop needs to be started.
			IF @TerminationReason= 'FAIL'
			BEGIN
				SELECT	@PaymentStopID = 0,
						@StartDate = @EndDateMembership,
						@StartReason = 'Faillissement aangegeven door MN',
						@EndDate = NULL,
						@EndReason = NULL,
						@PaymentstopType = '0001'

				EXECUTE @RC = [sub].[uspEmployer_PaymentStop_Upd] 
				   @PaymentStopID
				  ,@EmployerNumber
				  ,@StartDate
				  ,@StartReason
				  ,@EndDate
				  ,@EndReason
				  ,@PaymentstopType
				  ,@CurrentUserID
			END
		
		END

		ELSE

		BEGIN
			--	Initialize @PaymentStopID.
			SET @PaymentStopID = 0

			--	Check if a paymentstop is present.	*/
			SELECT	@PaymentStopID = PaymentStopID,
					@StartDate = @StartDate,
					@StartReason = @StartReason,
					@EndDate = EndDate,
					@EndReason = EndReason,
					@PaymentstopType = PaymentstopType
			FROM	sub.tblEmployer_PaymentStop 
			WHERE	EmployerNumber = @EmployerNumber 
			AND		EndDate IS NULL

			--	PaymentStop needs to be ended.
			IF @PaymentStopID <> 0 AND @EndDate IS NULL AND ISNULL(@TerminationReason, '') <> 'FAIL'
			BEGIN
				SELECT	@EndDate = CAST(GETDATE() AS date),
						@EndReason = 'Faillissement beëindiging aangeven door MN'

				EXECUTE @RC = [sub].[uspEmployer_PaymentStop_Upd] 
				   @PaymentStopID
				  ,@EmployerNumber
				  ,@StartDate
				  ,@StartReason
				  ,@EndDate
				  ,@EndReason
				  ,@PaymentstopType
				  ,@CurrentUserID
			END

			--	PaymentStop needs to be started.
			IF @PaymentStopID = 0 AND @TerminationReason = 'FAIL'
			BEGIN
				SELECT	@PaymentStopID = 0,
						@StartDate = @EndDateMembership,
						@StartReason = 'Faillissement aangegeven door MN',
						@EndDate = NULL,
						@EndReason = NULL,
						@PaymentstopType = '0001'

				EXECUTE @RC = [sub].[uspEmployer_PaymentStop_Upd] 
				   @PaymentStopID
				  ,@EmployerNumber
				  ,@StartDate
				  ,@StartReason
				  ,@EndDate
				  ,@EndReason
				  ,@PaymentstopType
				  ,@CurrentUserID
			END

			--	PaymentStop needs to be started (again).
			IF @PaymentStopID <> 0 AND @EndDate IS NOT NULL AND @TerminationReason = 'FAIL'
			BEGIN
				SELECT	@PaymentStopID = 0,
						@StartDate = @EndDateMembership,
						@StartReason = 'Faillissement aangegeven door MN',
						@EndDate = NULL,
						@EndReason = NULL,
						@PaymentstopType = '0001'

				EXECUTE @RC = [sub].[uspEmployer_PaymentStop_Upd] 
				   @PaymentStopID
				  ,@EmployerNumber
				  ,@StartDate
				  ,@StartReason
				  ,@EndDate
				  ,@EndReason
				  ,@PaymentstopType
				  ,@CurrentUserID
			END
		END

		FETCH NEXT FROM cur_Employer INTO @EmployerNumber, @EmployerName, @Email, @IBAN, @Ascription, @CoC, @Phone, @BusinessAddressStreet, 
											@BusinessAddressHousenumber, @BusinessAddressZipcode, @BusinessAddressCity, @BusinessAddressCountrycode, 
											@PostalAddressStreet, @PostalAddressHousenumber, @PostalAddressZipcode, @PostalAddressCity, 
											@PostalAddressCountrycode, @StartDateMembership, @EndDateMembership, @TerminationReason, @ImportAction
	END

	CLOSE cur_Employer
	DEALLOCATE cur_Employer
END

/*	Update IBAN numbers from Horus.	*/
SET @TimeStamp = GETDATE()

--EXEC @RC = hrs.uspHorusIBAN_Imp

/*	Log updates.	*/
INSERT INTO sub.tblImportLog
           ([Log]
		   ,[TimeStamp]
		   ,Duration)
     VALUES
           ('Bijwerken IBAN gegevens vanuit Horus uitgevoerd.'
           ,GETDATE()
           ,DATEDIFF(ss, @TimeStamp, GETDATE()))

/*	Log end of import.	*/
INSERT INTO sub.tblImportLog
			([Log]
			,[TimeStamp]
			,Duration)
		VALUES
			('De import van MN werkgever data is geëindigd.'
			,GETDATE()
			,DATEDIFF(ss, @StartTimeStamp, GETDATE()))

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Imp ===================================================================	*/
