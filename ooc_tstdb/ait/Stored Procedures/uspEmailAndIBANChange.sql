
CREATE PROCEDURE [ait].[uspEmailAndIBANChange] 
AS
/*	==========================================================================================
	Purpose:	Detect IBAN change after E-mail change

	20-12-2019	Jaap van Assenbergh	OTIBSUB-1796	Signalering van IBAN-wijziging na e-mailwijziging
	==========================================================================================	*/

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 30
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX),
		@Result				varchar(MAX),
		@Email				varchar(50) = 'support@ambitionit.nl'

DECLARE @IBAN_Change AS table
	(
		IBANChangeID		int,
		EmployerNumber		varchar(6),
		EmployerName		varchar(100),
		IBAN_Old			varchar(34),
		IBAN_New			varchar(34),
		Change_Date			date,
		ChangeStatusCode	varchar(4),
		ChangeStatus		varchar(100),
		FirstCheck_Date		date,
		SecondCheck_Date	date
	)

DECLARE @Email_Change AS table
	(
		UserEmailChangeID	int,
		EmployerNumber		varchar(6),
		UserID				int,
		FullName			varchar(117),
		LoginName			varchar(50),
		Email_Old			varchar(50),
		Email_New			varchar(50),
		Change_Date			date,
		Validation_Date		date,
		Validation_Result	varchar(11)
	)

INSERT INTO @IBAN_Change
SELECT	eic.IBANChangeID,
		eic.EmployerNumber, 
		emr.EmployerName, 
		eic.IBAN_Old, 
		eic.IBAN_New,
		eic.Creation_DateTime,
		eic.ChangeStatus,
		(
			SELECT	SettingValue 
			FROM	sub.tblApplicationSetting  aps
			WHERE	SettingName = 'IBANChangeStatus'
			AND		aps.SettingCode = eic.ChangeStatus
		),
		eic.FirstCheck_DateTime,
		eic.SecondCheck_DateTime
FROM	sub.tblEmployer_IBAN_Change eic
INNER JOIN sub.tblEmployer emr
	ON	emr.EmployerNumber = eic.EmployerNumber AND emr.EmployerNumber = '000007'
--WHERE	eic.Creation_DateTime >= DATEADD(DAY, - 7, GETDATE())
WHERE	eic.IBANChangeID NOT IN 
		(
			SELECT	IBANChangeID
			FROM	ait.tblEmailAndIBANChange
			WHERE	DetectionDate >= eic.Creation_DateTime
		)

INSERT INTO @Email_Change
SELECT	uec.UserEmailChangeID,
		ure.EmployerNumber,
		usr.Userid, 
		usr.Fullname, 
		usr.LoginName, 
		uec.Email_Old,
		uec.Email_New,
		uec.Creation_DateTime, 
		uec.Validation_DateTime,
		Validation_Result
FROM	auth.tblUser_Email_Change uec
INNER JOIN sub.tblUser_Role_Employer ure
	ON	ure.UserID = uec.UserID
INNER JOIN auth.tblUser usr
	ON usr.UserID = uec.UserID
WHERE	uec.UserEmailChangeID NOT IN 
		(
			SELECT	IBANChangeID
			FROM	ait.tblEmailAndIBANChange
			WHERE	DetectionDate >= uec.Creation_DateTime
		)

INSERT INTO ait.tblEmailAndIBANChange(IBANChangeID, UserEmailChangeID, DetectionDate)
SELECT	IBANChangeID, UserEmailChangeID, @Creation_DateTime
FROM	@IBAN_Change i
		INNER JOIN @Email_Change e 
	ON	e.EmployerNumber = i.EmployerNumber

SET @Result =
	CAST ( 
			(
				SELECT	td = i.EmployerNumber, '',
						td = i.EmployerName, '',
						td = i.IBAN_Old, '',
						td = i.IBAN_New, '',
						td = CONVERT(nvarchar(10), i.Change_Date, 105), '',
						td = i.ChangeStatus, '',
						td = CASE 
								WHEN i.ChangeStatusCode IN ('0000', '0005') THEN ''
								WHEN i.ChangeStatusCode IN ('0001', '0002') THEN CONVERT(nvarchar(10), FirstCheck_Date, 105)
								WHEN i.ChangeStatusCode IN ('0003', '0004') THEN CONVERT(nvarchar(10), SecondCheck_Date, 105)
						END, '',
						td = CONVERT(nvarchar(10), e.Change_Date, 105), '',
						td = e.FullName, '',
						td = CONVERT(nvarchar(10), e.Validation_Date, 105), '',
						td = e.Validation_Result, ''
				FROM	@IBAN_Change i
				INNER JOIN @Email_Change e 
					ON	e.EmployerNumber = i.EmployerNumber
				FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) )

--  Send an e-mail.
IF ISNULL(@Result, '') <> ''
BEGIN
	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', @Recipients)
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', @SubjectAddition)

	SET @EmailBody = REPLACE(@EmailBody, '<%CreationDate%>', CONVERT(varchar(10), @Creation_DateTime, 105))
	SET @EmailBody = REPLACE(@EmailBody, '<%Result%>', @Result)

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
/*	== ait.uspEmailAndIBANChange ===========================================================+=	*/
