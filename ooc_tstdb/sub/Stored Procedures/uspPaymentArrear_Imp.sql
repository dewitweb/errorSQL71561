CREATE PROCEDURE [sub].[uspPaymentArrear_Imp]
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose:	Import payment arrear data from OTIBMNData database.

	Note:		In Dutch this is Betalingsachterstand.

	23-07-2019	Jaap van Assenebrgh	OTIBSUB-1385
				Import dienstverbanden en betalingsachterstanden veroorzaakt een grote transaction log file

	17-10-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@StartTimeStamp	datetime = GETDATE(),
		@TimeStamp		datetime = GETDATE()

DECLARE @PaymentArrear AS Table 
		(
			EmployerNumber varchar(6) INDEX IX_PaymentArrear_EmployerNumber CLUSTERED,
			FeesPaidUntill date
		)

INSERT INTO @PaymentArrear
           (EmployerNumber
           ,FeesPaidUntill)
SELECT	par.debiteurnummer,
		par.docdatum
FROM	crm.viewPaymentArrear_MNData par
INNER JOIN	sub.tblEmployer emp
		ON	emp.EmployerNumber = par.debiteurnummer

/*	Log start of import.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'De import van MN betalingsachterstand data is gestart.',
		@StartTimeStamp,
		0
	)

/*	Delete all existing paymentarrears.	*/
SET @TimeStamp = GETDATE()

DELETE 
FROM	sub.tblPaymentArrear 
WHERE	EmployerNumber NOT IN	
		(
			SELECT	pa.EmployerNumber
			FROM	@PaymentArrear pa
			WHERE	pa.EmployerNumber = EmployerNumber
		)

/*	Log deletes.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' betalingsachterstand records verwijderd.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Insert all new paymentarrears	*/
SET @TimeStamp = GETDATE()

INSERT INTO sub.tblPaymentArrear
           (EmployerNumber
           ,FeesPaidUntill)
SELECT	par.EmployerNumber,
		par.FeesPaidUntill
FROM	@PaymentArrear par
WHERE	par.EmployerNumber NOT IN  
		(
			SELECT	pa.EmployerNumber
			FROM	sub.tblPaymentArrear pa
		)

/*	Log inserts.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' nieuwe betalingsachterstand records aangemaakt.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

UPDATE	par
SET		par.FeesPaidUntill = pa.FeesPaidUntill
FROM	sub.tblPaymentArrear par
INNER JOIN @PaymentArrear pa ON pa.EmployerNumber = par.EmployerNumber
WHERE	par.FeesPaidUntill <> pa.FeesPaidUntill

/*	Log updates	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'Er zijn ' + CAST(@@ROWCOUNT AS varchar(10)) + ' betalingsachterstand records bijgewerkt.',
		GETDATE(),
		DATEDIFF(ss, @TimeStamp, GETDATE())
	)

/*	Log end of import.	*/
INSERT INTO sub.tblImportLog
	(
		[Log],
		[TimeStamp],
		Duration
	)
VALUES
	(
		'De import van MN betalingsachterstand data is geëindigd.',
		GETDATE(),
		DATEDIFF(ss, @StartTimeStamp, GETDATE())
	)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentArrear_Imp ==============================================================	*/
