
CREATE PROCEDURE [ait].[uspCreate_USP] 
	@SchemaName varchar(10),
	@TableName varchar(100)
AS
/*	==========================================================================================
	04-05-2016	Jaap van Assenbergh
				Genereren van een standaard usp's
	18-07-2018	Jaap van Assenbergh
				SchemaName toegevoegd
	==========================================================================================
*/

IF @SchemaName IS NULL SET @SchemaName = 'dbo'

DECLARE @Lines as TABLE (Row int IDENTITY(1,1), Line varchar(MAX))

INSERT INTO @Lines EXECUTE [ait].uspCreateDelUSP @SchemaName, @TableName
INSERT INTO @Lines EXECUTE [ait].uspCreateGetUSP @SchemaName, @TableName
INSERT INTO @Lines EXECUTE [ait].uspCreateListUSP @SchemaName, @TableName
INSERT INTO @Lines EXECUTE [ait].uspCreateUpdUSP @SchemaName, @TableName

SELECT Line 
FROM @Lines
ORDER BY Row
