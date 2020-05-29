CREATE PROCEDURE [sub].[uspEmployer_Employee_Imp_Rebuild_Index]
AS
/*	==========================================================================================
	Purpose:	Import link between employer and employee from OTIBMNData database.

	20-09-2019	Jaap van Assenbergh	OTIBSUB-1584 Rebuild index after import
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @AlterCommand			varchar(MAX)
DECLARE @SchemaName				varchar(100)
DECLARE @TableName				varchar(100)
DECLARE @IndexName				varchar(100)
DECLARE @Fragmentation_Percent	dec(5,2)
DECLARE @Page_Count				int

DECLARE crs_Index CURSOR    
	LOCAL    
	FAST_FORWARD    
	READ_ONLY    
	FOR
		SELECT dbschemas.[name] 'Schema',
		dbtables.[name] 'Table',
		dbindexes.[name] 'Index',
		indexstats.avg_fragmentation_in_percent Fragmentation_Percent,
		indexstats.page_count Page_Count
		FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) indexstats
		INNER JOIN sys.tables dbtables 
			ON	dbtables.[object_id] = indexstats.[object_id]
		INNER JOIN sys.schemas dbschemas 
			ON	dbtables.[schema_id] = dbschemas.[schema_id]
		INNER JOIN sys.indexes dbindexes 
			ON	dbindexes.[object_id] = indexstats.[object_id]
			AND	indexstats.index_id = dbindexes.index_id
		WHERE	dbschemas.[name] = 'sub'
		AND		dbtables.[name] IN ('tblEmployer_Employee', 'tblEmployee_ScopeOfEmployment', 'tblEmployee')
		AND	indexstats.avg_fragmentation_in_percent > 30
	OPEN crs_Index
	FETCH FROM crs_Index
	INTO	@SchemaName,
			@TableName,
			@IndexName,
			@Fragmentation_Percent,
			@Page_Count

WHILE @@FETCH_STATUS = 0   
BEGIN

	SET @AlterCommand = ''

	SET @AlterCommand = 'ALTER INDEX ' + QUOTENAME(@IndexName) 
						+ ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) 
						+ ' REBUILD'

	EXECUTE (@AlterCommand)

	--SELECT @AlterCommand

	FETCH NEXT FROM crs_Index
	INTO	@SchemaName,
			@TableName,
			@IndexName,
			@Fragmentation_Percent,
			@Page_Count

END
CLOSE crs_Index   
DEALLOCATE crs_Index

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.uspEmployer_Employee_Imp_Rebuild_Index ===========================================	*/

