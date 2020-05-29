



CREATE FUNCTION [sub].[usfGetPaymentLedger] 
	(
		@StartDate			date,
		@SubsidySchemeName	varchar(50),
		@TypeOfDebit		varchar(10),
		@ErtCode			varchar(10),
		@CssCode			varchar(10)
	)
/*	==========================================================================================
	Purpose:	Get the ledger for payment.

	23-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

RETURNS varchar(10)
AS
BEGIN
	DECLARE @Ledger varchar(10)

	IF @TypeOfDebit <> 'ERT'
	BEGIN
		/* First set the ledgernumber with the standard OSR number for the given ledger year.	*/
		SELECT	@Ledger = led.LedgerNumber
		FROM	sub.tblLedger led
		WHERE 	led.SubsidySchemeName = @SubsidySchemeName
		  AND	led.SubsidySchemeType = @SubsidySchemeName
		  AND	led.LedgerYear = YEAR(@StartDate)

		/* Workaround for ledger ESPAAR.	*/
		IF @TypeOfDebit = 'SPS' AND @ErtCode = 'ESPAAR'
		BEGIN
			SELECT	@Ledger = led.LedgerNumber
			FROM	sub.tblLedgerExtraRights led
			WHERE 	led.RightCode = @ErtCode
		END

		/* Use a different ledgernumber for durable types of debit.	*/
		IF @TypeOfDebit IN ('DZM', 'SFK')
		BEGIN
			SELECT	@Ledger = led.LedgerNumber
			FROM	sub.tblLedger led
			WHERE 	led.SubsidySchemeName = @TypeOfDebit
			  AND	led.SubsidySchemeType = @TypeOfDebit
			  AND	led.LedgerYear = YEAR(@StartDate)
		END

		/* For extra compensations the ledgernumber needs to taken from the table sub.tblLedgerExtraRights.	*/
		IF @TypeOfDebit = 'TGK'
		BEGIN
			SELECT	@Ledger = led.LedgerNumber
			FROM	sub.tblLedgerExtraRights led
			WHERE 	led.RightCode = @cssCode
		END
	END

	ELSE

	/* For extra rights the ledgernumber needs to taken from the table sub.tblLedgerExtraRights.	*/
	BEGIN
		SELECT	@Ledger = led.LedgerNumber
		FROM	sub.tblLedgerExtraRights led
		WHERE 	led.RightCode = @ErtCode
	END

	RETURN @Ledger
END
/*	== sub.usfGetPaymentLedger ===============================================================	*/