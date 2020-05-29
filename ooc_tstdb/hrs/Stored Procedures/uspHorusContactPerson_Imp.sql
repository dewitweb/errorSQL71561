CREATE PROCEDURE [hrs].[uspHorusContactPerson_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all ContactPerson data from Horus.

	24-06-2019	Sander van Houten		Added firstname.
	13-12-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Get all ContactPerson data from Horus.	*/
DECLARE @SQL	varchar(max)

SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_CONTACTPERSONEN WHERE NAAM IS NOT NULL'

SET @SQL = 'SELECT WGR_NUMMER, WGR_NAAM, ISNULL(VOORLETTERS, '''') AS VOORLETTERS, '
			+ 'ISNULL(ROEPNAAM, '''') AS VOORNAAM, ISNULL(TUSSENVOEGSEL, '''') AS TUSSENVOEGSEL,'
			+ ' NAAM, GESLACHT, IND_BRIEF, ISNULL(TELEFOON, '''') AS TELEFOON, '
			+ 'ISNULL(MOBIEL_NUMMER, '''') AS MOBIEL_NUMMER, ISNULL(CPN_EMAIL_ADRES, '''') AS CPN_EMAIL_ADRES, '
			+ ''''' AS REGELING, ''2018-12-13'' AS START_DATUM, ''2018-12-13'' AS EIND_DATUM, '
			+ 'ISNULL(OMSCHRIJVING, '''') AS OMSCHRIJVING, SOORTCONTACT '
			+ 'FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'

IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- First empty hrs.tblContactPerson.
DELETE FROM hrs.tblContactPerson

-- The refill it.
INSERT INTO hrs.tblContactPerson
	(
		EmployerNumber,
        EmployerName,
        ContactInitials,
		ContactFirstname,
        ContactAmidst,
        ContactSurname,
        Gender,
        IndicationLetter,
        Phone,
        MobilePhone,
        Email,
        SubsidySchemeName,
        StartDate,
        EndDate,
        FunctionDescription,
        ContactType
	)
EXEC(@SQL)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusContactPerson_Imp =========================================================	*/
