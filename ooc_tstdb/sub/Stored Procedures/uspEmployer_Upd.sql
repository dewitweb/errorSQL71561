
CREATE PROCEDURE [sub].[uspEmployer_Upd]
@EmployerNumber				varchar(6),
@EmployerName				varchar(100),
@Email						varchar(254),
@IBAN						varchar(34),
@Ascription					varchar(100),
@CoC						varchar(11),
@Phone						varchar(30),
@BusinessAddressStreet		varchar(100),
@BusinessAddressHousenumber	varchar(10),
@BusinessAddressZipcode		varchar(10),
@BusinessAddressCity		varchar(100),
@BusinessAddressCountrycode	varchar(2),
@PostalAddressStreet		varchar(100),
@PostalAddressHousenumber	varchar(10),
@PostalAddressZipcode		varchar(10),
@PostalAddressCity			varchar(100),
@PostalAddressCountrycode	varchar(2),
@StartDateMembership		date,
@EndDateMembership			date,
@TerminationReason			varchar(4),
@CurrentUserID				int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer on the basis of EmployerNumber.

	20-06-2019	Sander van Houten		OTIBSUB-1196	Added TerminationReason.
	14-06-2019	Sander van Houten		OTIBSUB-1186	Added postal address data.
	19-11-2018	Sander van Houten		OTIBSUB-98		Added Ascription.
	02-08-2018	Sander van Houten		CurrentUserID added.
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

IF (SELECT	COUNT(EmployerNumber)
	FROM	sub.tblEmployer
	WHERE	EmployerNumber = @EmployerNumber) = 0
BEGIN
	INSERT INTO sub.tblEmployer
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
			TerminationReason
		)
	VALUES
		(
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
			@TerminationReason
		)
END
ELSE
BEGIN
	-- Update exisiting record
	UPDATE	sub.tblEmployer
	SET
			EmployerName				= @EmployerName,
			Email						= @Email,
			IBAN						= @IBAN,
			Ascription					= @Ascription,
			CoC							= @CoC,
			Phone						= @Phone,
			BusinessAddressStreet		= @BusinessAddressStreet,
			BusinessAddressHousenumber	= @BusinessAddressHousenumber,
			BusinessAddressZipcode		= @BusinessAddressZipcode,
			BusinessAddressCity			= @BusinessAddressCity,
			BusinessAddressCountrycode	= @BusinessAddressCountrycode,
			PostalAddressStreet			= @PostalAddressStreet,
			PostalAddressHousenumber	= @PostalAddressHousenumber,
			PostalAddressZipcode		= @PostalAddressZipcode,
			PostalAddressCity			= @PostalAddressCity,
			PostalAddressCountrycode	= @PostalAddressCountrycode,
			StartDateMembership			= @StartDateMembership,
			EndDateMembership			= @EndDateMembership,
			TerminationReason			= @TerminationReason
	WHERE	EmployerNumber = @EmployerNumber
END

-- Update searchname
IF @@ROWCOUNT > 0
BEGIN
	UPDATE	sub.tblEmployer 
	SET		SearchName = sub.usfCreateSearchString(EmployerName)
	WHERE	EmployerNumber = @EmployerNumber
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Upd ===================================================================	*/
