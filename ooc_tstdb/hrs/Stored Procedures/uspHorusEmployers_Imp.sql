CREATE PROCEDURE [hrs].[uspHorusEmployers_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all Employers DVD data from Horus.

	19-03-2019 Sander van Houten		Added e-mail and ContactPerson data 
										for correct e-mail sending.
	28-01-2019 Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Get all Employers DVD data from Horus.	*/
DECLARE @SQL	varchar(max)

SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_WERKGEVER_OTIBDS'

SET @SQL = 'SELECT * '
			+ 'FROM OPENQUERY(HORUS_P, ''' + REPLACE(@SQL, '''', '''''') + ''')'
	
IF DB_NAME() = 'OTIBDS_Acceptatie'
	SET @SQL = REPLACE(@SQL, 'HORUS_P', 'HORUS_A')
	
-- First empty hrs.tblWGR.
DELETE FROM hrs.tblWGR

-- Then refill it.
INSERT INTO hrs.tblWGR 
	(
		EmployerNumber, 
		IBAN, 
		SignedAgreementRecieved, 
		Email, 
		Email_ContactPerson, 
		Name_ContactPerson, 
		Gender_ContactPerson
	)
EXEC(@SQL)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusEmployers_Imp =============================================================	*/