
CREATE PROCEDURE [sub].[usp_OTIB_Employer_Subsidy_GracePeriod_Add]
@EmployerSubsidyID  int,
@EndDate            date,
@GracePeriodReason  varchar(max),
@tblEmailToken		sub.uttGracePeriod_EmailToken READONLY,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Insert a request for a grace period into sub.tblEmployer_Subsidy_GracePeriod.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@EmployerSubsidyID  int = 1,
        @EndDate            date = '20200322',
        @GracePeriodReason  varchar(max) = 'Test',
        @tblEmailToken		sub.uttGracePeriod_EmailToken,
        @CurrentUserID		int = 1

INSERT INTO @tblEmailToken (UserID, Token) 
VALUES  (7, 'jgfieuhncvdnfvkndfegvjoerv'),
        (234567, 'kejhfvcoioervnnvdfhdvefjji')
--*/

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID int = 6
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
        @LinkURL            varchar(250)

DECLARE @GracePeriodID  int

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

	-- Add new record
	INSERT INTO sub.tblEmployer_Subsidy_GracePeriod
		(
			EmployerSubsidyID,
            EndDate,
            CreationUserID,
            CreationDate,
            GracePeriodReason,
            GracePeriodStatus
		)
	VALUES
		(
			@EmployerSubsidyID,
            @EndDate,
            @CurrentUserID,
            @LogDate,
            @GracePeriodReason,
            '0001'
		)

	SET	@GracePeriodID = SCOPE_IDENTITY()

	-- Save new record.
	SELECT	@XMLdel = NULL,
			@XMLins = (	SELECT 	*
						FROM	sub.tblEmployer_Subsidy_GracePeriod
						WHERE	GracePeriodID = @GracePeriodID
						FOR XML PATH )


-- Log action in tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@GracePeriodID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_Subsidy_GracePeriod',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

-- Insert and send e-mail(s).
IF (SELECT COUNT(1) FROM @tblEmailToken) > 0
BEGIN
    -- Declare variables.
    DECLARE @MailBanner	        varchar(100),
            @Recipients         varchar(max),
            @Email              varchar(50),
            @UserID_DS	        int,
            @Username	        varchar(100),
            @EmployerName       varchar(max),
            @EmployerNumber     varchar(6),
            @EmailToken         varchar(50),
            @EmailID            int

    DECLARE cur_Email CURSOR FOR
    SELECT  UserID,
            Token
    FROM 	@tblEmailToken
    WHERE   UserID <> @CurrentUserID
    
    -- Get MailBanner location.
	SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
	FROM	sub.tblApplicationSetting aps
	LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	    apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	    GETDATE() BETWEEN apse.StartDate AND apse.EndDate
	WHERE	aps.SettingName = 'BaseURL'
	AND		aps.SettingCode = 'AssetsMailBanner'

    -- Set employer variables.
    SELECT  @EmployerName = emp.EmployerName,
            @EmployerNumber = emp.EmployerNumber
    FROM    sub.tblEmployer_Subsidy ems
    INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = ems.EmployerNumber
    WHERE   ems.EmployerSubsidyID = @EmployerSubsidyID

    OPEN cur_Email
    
    FETCH NEXT FROM cur_Email INTO @UserID_DS, @EmailToken
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Initialize variables.
        SET @Recipients = ''
        SET @EmailHeader = ''
        SET @EmailBody = ''
        
        -- Get the e-mailadress and recipient name.
        SELECT  @Email = usr.Email,
                @Username = usr.Fullname
        FROM    auth.tblUser usr
        WHERE   usr.UserID = @UserID_DS

        SELECT 	@LinkURL = CASE 
                            WHEN DB_NAME() = 'OTIBDS' THEN 'https://www.otib-online.nl/werkgevers-uitstelperiode-afhandelen'
                            WHEN DB_NAME() = 'OTIBDSTest' THEN 'http://ui.subsidiesysteem.local/werkgevers-uitstelperiode-afhandelen'
                            WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'https://acceptatie.otib-online.nl/werkgevers-uitstelperiode-afhandelen'
                           END

        -- Send the e-mail.
        SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
        SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

        SET @Recipients = REPLACE(@Email, '&' , '&amp;')
        SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', @Recipients)
		SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', @SubjectAddition)

        SET @EmailBody = REPLACE(@EmailBody, '<%Username%>', @Username)
        SET @EmailBody = REPLACE(@EmailBody, '<%EmployerName%>', @EmployerName)
        SET @EmailBody = REPLACE(@EmailBody, '<%EmployerNumber%>', @EmployerNumber)
        SET @EmailBody = REPLACE(@EmailBody, '<%NewEndDate%>', CONVERT(varchar(10), @EndDate, 105))
        SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', @LinkURL)
        SET @EmailBody = REPLACE(@EmailBody, '<%GracePeriodID%>', CAST(@GracePeriodID AS varchar(18)))
        SET @EmailBody = REPLACE(@EmailBody, '<%Token%>', @EmailToken)
		SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', @MailBanner)

        INSERT INTO [eml].[tblEmail]
                (
                    [EmailHeaders],
                    [EmailBody],
                    [CreationDate]
                )
            VALUES
                (
                    @EmailHeader,
                    @EmailBody,
                    @Creation_DateTime
                )
        
	    SET	@EmailID = SCOPE_IDENTITY()

        -- Insert record into sub.tblEmployer_Subsidy_GracePeriod_Email.
        INSERT INTO sub.tblEmployer_Subsidy_GracePeriod_Email
            (
                GracePeriodID,
                EmailID,
                Token,
                UserID,
                ValidUntil
            )
        SELECT 
                @GracePeriodID,
                @EmailID,
                @EmailToken,
                @UserID_DS,
                DATEADD(HH, CAST(aps.SettingValue AS int), @LogDate)
        FROM    sub.tblApplicationSetting aps
        WHERE   aps.SettingName = 'GracePeriodEmail'
        AND     aps.SettingCode = 'ValidHours'

    FETCH NEXT FROM cur_Email INTO @UserID_DS, @EmailToken
    END
    
    CLOSE cur_Email
    DEALLOCATE cur_Email
END

-- Return GracePeriodID.
SELECT	GracePeriodID = @GracePeriodID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_Subsidy_GracePeriod_Add =================================	*/
