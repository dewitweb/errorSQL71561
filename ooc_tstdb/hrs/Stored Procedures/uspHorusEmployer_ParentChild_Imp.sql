CREATE PROCEDURE [hrs].[uspHorusEmployer_ParentChild_Imp]
AS
/*	==========================================================================================
	Purpose:	Import all Employer ParentChild data from Horus.

	13-12-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Get all BPV data from Horus.	*/
DECLARE @SQL	varchar(max)

SET @SQL = 'SELECT * FROM OLCOWNER.HRS_VW_MOEDER_DOCHTER_RELATIES'

SET @SQL = 'SELECT [MN-nummer Moeder], [MN-nummer Dochter], BEGIN_DATUM, EIND_DATUM '
			+ ' FROM OPENQUERY(HORUS_A, ''' + REPLACE(@SQL, '''', '''''') + ''')'

IF DB_NAME() = 'OTIBDS'
	SET @SQL = REPLACE(@SQL, 'HORUS_A', 'HORUS_P')
	
-- First empty sub.tblEmployer_ParentChild.
DELETE FROM sub.tblEmployer_ParentChild

-- The refill it.
INSERT INTO sub.tblEmployer_ParentChild
    (
		[EmployerNumberParent],
		[EmployerNumberChild],
		[StartDate],
		[EndDate]
	)
EXEC(@SQL)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.uspHorusEmployer_ParentChild_Imp ==================================================	*/
