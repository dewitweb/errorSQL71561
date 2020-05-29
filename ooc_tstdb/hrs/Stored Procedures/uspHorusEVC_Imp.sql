CREATE PROCEDURE [hrs].[uspHorusEVC_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all EVC data from Horus.

	13-12-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Get all BPV data from Horus.	*/
DECLARE @SQL	varchar(max)

SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_EVC'

SET @SQL = 'SELECT WNR_NUMMER, DATUM_INTAKEGESPREK, DATUM_CERTIFICAAT, CONTROLEDATUM, '
			+ 'DECLARATIENR, STATUS, STATUSOMSCHRIJVING '
			+ ' FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'

IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- First empty hrs.tblIBAN.
DELETE FROM hrs.tblEVC

-- The refill it.
INSERT INTO hrs.tblEVC
    (
		EmployeeNumber,
		IntakeDate,
		CertificationDate,
		CheckDate,
		DeclarationNumber,
		DeclarationStatus,
		StatusDescription
	)
EXEC(@SQL)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusEVC_Imp ===================================================================	*/
