
CREATE PROCEDURE [auth].[usp_OTIB_User_Email_Change_AcceptReject]
@UserEmailChangeID	int,
@Accept			    bit,
@Reason			    varchar(MAX),
@CurrentUserID	    int = 1
AS
/*	==========================================================================================
	Purpose:	Accept or Reject a request for an e-mail change by an OTIB user.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	19-12-2019	Sander van Houten	OTIBSUB-1791	Added saving of result from Horus update.
	18-12-2019	Sander van Houten	OTIBSUB-1791	Added MN-number and EmployerName 
                                        to e-mail body text.
	16-12-2019	Sander van Houten	OTIBSUB-1762	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @UserEmailChangeID	int = 20,
        @Accept			    bit = 1,
        @Reason			    varchar(MAX) = NULL,
        @CurrentUserID	    int = 20800
--  */
DECLARE @Creation_DateTime  datetime = GETDATE()

DECLARE @TemplateID int = 1

DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) =''

/*  Update the record in auth.tblUser_Email_Change. */
UPDATE  auth.tblUser_Email_Change
SET     Validation_UserID = @CurrentUserID,
        Validation_DateTime = GETDATE(),
        Validation_Result = CASE @Accept
                                WHEN 0 THEN 'Afgekeurd'
                                WHEN 1 THEN 'Goedgekeurd'
                            END,
        Validation_Reason = @Reason
WHERE   UserEmailChangeID = @UserEmailChangeID

/*  Further actions if accepted.    */
IF @Accept = 1
BEGIN
    -- Declare variables.
    DECLARE @MailBanner	    varchar(100),
            @Recipients     varchar(MAX),
            @Email          varchar(50),
            @Loginname	    varchar(20),
            @UserID_DS	    int,
            @Initials	    varchar(15),
            @Firstname	    varchar(50),
            @Infix		    varchar(15),
            @Surname	    varchar(50),
            @Phone		    varchar(15),
            @Gender		    varchar(1),
            @EmployerName   varchar(MAX),
            @RC             int

    -- Update the e-mailadress in the user record.
    UPDATE  usr
    SET     usr.Email = uec.Email_New,
            @Email = uec.Email_New,
            @Loginname = usr.Loginname,
            @UserID_DS = usr.UserID,
            @Initials = usr.Initials,
            @Firstname = usr.Firstname,
            @Infix = usr.Infix,
            @Surname = usr.Surname,
            @Phone = usr.Phone,
            @Gender = usr.Gender,
            @EmployerName = emp.EmployerName
    FROM    auth.tblUser_Email_Change uec
    INNER JOIN auth.tblUser usr ON usr.UserID = uec.UserID
    INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = usr.Loginname
    WHERE   uec.UserEmailChangeID = @UserEmailChangeID

    -- For test purposes only!
    -- SELECT  uec.Email_New,
    --         usr.Loginname,
    --         usr.UserID,
    --         usr.Initials,
    --         usr.Firstname,
    --         usr.Infix,
    --         usr.Surname,
    --         usr.Phone,
    --         usr.Gender,
    --         emp.EmployerName
    -- FROM    auth.tblUser_Email_Change uec
    -- INNER JOIN auth.tblUser usr ON usr.UserID = uec.UserID
    -- INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = usr.Loginname
    -- WHERE   uec.UserEmailChangeID = 20

    -- Update Horus (OTIBSB-1075).
    EXECUTE @RC = [hrs].[uspHorusContactPerson_Upd] 
        @Loginname,
        @UserID_DS,
        @Initials,
        @Firstname,
        @Infix,
        @Surname,
        @Email,
        @Phone,
        @Gender

    -- Save result from Horus in table.
    UPDATE  auth.tblUser_Email_Change
    SET     Horus_Result = CASE @RC WHEN 0 THEN 'Goed' ELSE 'Fout' END
    WHERE   UserEmailChangeID = @UserEmailChangeID

    -- Get MailBanner location.
	SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
	FROM	sub.tblApplicationSetting aps
	LEFT JOIN sub.tblApplicationSetting_Extended apse 
		ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
		AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
	WHERE	aps.SettingName = 'BaseURL'
	AND		aps.SettingCode = 'AssetsMailBanner'

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	SET @EmailBody = REPLACE(@EmailBody, '<%Loginname%>', ISNULL(@Loginname, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%EmployerName%>', ISNULL(@EmployerName, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%Email%>', ISNULL(@Email, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

    -- Send an e-mail to the employer.
    --INSERT INTO eml.tblEmail
    --    (
    --        EmailHeaders,
    --        EmailBody,
    --        CreationDate
    --    )
    --VALUES
    --    (
    --        '<headers>'
    --            + '<header key="subject" value="OTIB Online: Nieuw e-mailadres" />'
    --            + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
    --            + '</headers>',
    --        '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'
    --            + 'Geachte mevrouw, heer,<br>'
    --            + '<br>'
    --            + 'Wij hebben uw aanvraag voor het wijzigen of registreren van uw e-mailadres goedgekeurd voor '
    --            + @Loginname + ' ' + @EmployerName + '.<br>'
    --            + 'Het bij ons geregistreerde e-mailadres is: ' + @Email + '.<br>'
    --            + 'We hopen u hiermee voldoende te hebben geïnformeerd.<br>'
    --            + '<br>' 
    --            + '<br>' 
    --            + 'Met vriendelijke groet,<br>'
    --            + 'OTIB<br>'
    --            + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
    --            + 'T 0800 885 58 85<br>'
    --            + '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
    --            + '</p>',
    --        GETDATE()
    --    )

   INSERT INTO eml.tblEmail
        (
            EmailHeaders,
            EmailBody,
            CreationDate
        )
    VALUES
        (
			@EmailHeader,
			@EmailBody,
			@Creation_DateTime
		)
END

RETURN 0

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.usp_OTIB_User_Email_Change_AcceptReject =============================================	*/
