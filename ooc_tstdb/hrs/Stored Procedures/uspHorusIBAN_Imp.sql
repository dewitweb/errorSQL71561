CREATE PROCEDURE [hrs].[uspHorusIBAN_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all IBAN data from Horus.

	31-07-2019	Sander van Houten		OTIBSUB-1332		Remove IBAN rejection reason
											(if exists) and reprocess the declaration.
	13-12-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

/* Get all IBAN data from Horus.	*/
DECLARE @SQL	varchar(max)

SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_WERKGEVER_IBAN'

SET @SQL = 'SELECT WGR_NUMMER, BANKGIRONUMMER '
			+ 'FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'
	
IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- First empty hrs.tblIBAN.
DELETE FROM hrs.tblIBAN

-- The refill it.
INSERT INTO hrs.tblIBAN (EmployerNumber, IBAN)
EXEC(@SQL)


/*	Update sub.tblEmployer IBAN field.	*/
DECLARE @EmployerNumber varchar(6),
		@IBAN			varchar(34)

DECLARE cur_Employer CURSOR FOR 
	SELECT 
		emp.EmployerNumber,
		hrs.IBAN
FROM	sub.tblEmployer emp
INNER JOIN	hrs.tblIBAN hrs ON hrs.EmployerNumber = emp.EmployerNumber
WHERE	ISNULL(emp.IBAN, '') <> ISNULL(hrs.IBAN, '')
		
OPEN cur_Employer

FETCH NEXT FROM cur_Employer INTO @EmployerNumber, @IBAN

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Save old record
	SELECT	@XMLdel = (SELECT	* 
					   FROM		sub.tblEmployer 
					   WHERE	EmployerNumber = @EmployerNumber 
					   FOR XML PATH)

	-- Update exisiting record
	UPDATE	sub.tblEmployer
	SET		IBAN = @IBAN
	WHERE	EmployerNumber = @EmployerNumber

	-- Save new record
	SELECT	@XMLins = (SELECT	* 
					   FROM		sub.tblEmployer 
					   WHERE	EmployerNumber = @EmployerNumber 
					   FOR XML PATH)

	-- Log action in tblHistory
	EXEC his.uspHistory_Add
			'sub.tblEmployer',
			@EmployerNumber,
			1,	-- Admin
			@LogDate,
			@XMLdel,
			@XMLins

	FETCH NEXT FROM cur_Employer INTO @EmployerNumber, @IBAN
END

CLOSE cur_Employer
DEALLOCATE cur_Employer

-- Remove IBAN rejection reason.
SELECT	rej.DeclarationID, emp.EmployerNumber
INTO	#tblRejection
FROM	sub.tblDeclaration_Rejection rej
INNER JOIN sub.tblDeclaration d on d.DeclarationID = rej.DeclarationID
INNER JOIN sub.tblEmployer emp on emp.EmployerNumber = d.EmployerNumber
WHERE	rej.RejectionReason = '0019'
AND		COALESCE(emp.IBAN, '') <> ''


-- Reprocess declaration(s).
DECLARE @DeclarationID	int

DECLARE cur_Reprocess CURSOR FOR 
	SELECT	rej.DeclarationID
	FROM	#tblRejection rej
	LEFT JOIN sub.tblDeclaration_Rejection dre
	ON		dre.DeclarationID = rej.DeclarationID
	WHERE	dre.DeclarationID IS NULL
		
OPEN cur_Reprocess

FETCH NEXT FROM cur_Reprocess INTO @DeclarationID

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXEC [ait].[ResetDeclarationAutomaticCheck] @DeclarationID

	FETCH NEXT FROM cur_Reprocess INTO @DeclarationID
END

CLOSE cur_Reprocess
DEALLOCATE cur_Reprocess


EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusIBAN_Imp ==================================================================	*/