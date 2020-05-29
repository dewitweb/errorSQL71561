﻿CREATE PROCEDURE [ait].[uspCreateUpdUSP]
@SchemaName varchar(10),
@TableName varchar(100)
AS
/*	==========================================================================================
	04-05-2016	Jaap van Assenbergh
				Genereren van een standaard update usp
	18-07-2018	Jaap van Assenbergh
				SchemaName toegevoegd
	==========================================================================================
*/

IF @SchemaName IS NULL SET @SchemaName = 'dbo'

DECLARE @Columns AS TABLE 
		(
			ColumnName varchar(256), 
			TypeName varchar(20), 
			ColumnLength int, 
			Column_ID int, 
			LengthName int,
			LengthMax int,
			Scale int
		)
DECLARE @UspName varchar(100)
DECLARE @PK varchar(100) 
DECLARE @UserName varchar(100) 
DECLARE @MaxLengthName int
DECLARE @LastColumn int

DECLARE @VarTabs int
DECLARE @Tabs int

DECLARE @Lines as TABLE (Row int IDENTITY(1,1), Line varchar(MAX))

DECLARE @Users as TABLE (SUSER varChar(100), UserName varchar(MAX))
INSERT INTO @Users VALUES ('AmbitionITJaap', 'Jaap van Assenbergh')
INSERT INTO @Users VALUES ('AmbitionITSander', 'Sander van Houten')
INSERT INTO @Users VALUES ('AMBITIONIT-004\Jaap', 'Jaap van Assenbergh')

INSERT INTO @Columns
SELECT ColumnName, TypeName, ColumnLength, Column_ID, LengthName, max_length, scale
FROM	(
			SELECT C.Name as ColumnName, T.Name As TypeName, 
			CASE	WHEN t.name like 'n%char' 
						THEN C.max_length/2 
					ELSE 
						CASE	WHEN t.name = 'varchar' OR t.name Like '%binary'
									THEN C.max_length 
								END 
							END AS ColumnLength, 
			C.Column_ID, LEN(C.Name) AS LengthName,
			C.max_length, C.scale
			FROM	sys.tables Tab
			INNER JOIN sys.schemas S ON S.schema_id = Tab.schema_id
			INNER JOIN sys.Columns C ON C.object_id = Tab.object_id
			INNER JOIN sys.types T ON T.user_type_id = C.user_type_id
			WHERE OBJECT_NAME(C.Object_ID) = @TableName
			AND s.name = @SchemaName
		) a
ORDER BY Column_ID

SELECT @MaxLengthName = MAX(LengthName) FROM @Columns
SELECT @PK = ColumnName From @Columns WHERE Column_ID = 1
SELECT @LastColumn = MAX(Column_ID) FROM @Columns

SELECT @VarTabs = (@MaxLengthName+1)/4
IF @MaxLengthName+1 % 4 <> 0
	SET @VarTabs = @VarTabs + 1

SELECT @Tabs = @MaxLengthName/4
IF @MaxLengthName % 4 <> 0
	SET @Tabs = @Tabs + 1

--INSERT INTO @Lines VALUES ('USE [' + DB_NAME() + ']')
--INSERT INTO @Lines VALUES ('GO')
--INSERT INTO @Lines VALUES ('')

SET @UspName = 'usp'+ SUBSTRING(@TableName, 4, LEN(@TableName)) + '_Upd'

INSERT INTO @Lines VALUES ('IF OBJECT_ID(''' + @SchemaName + '.' + @UspName + ''', ''P'') IS NOT NULL')
INSERT INTO @Lines VALUES ('DROP PROCEDURE ' + @SchemaName + '.' + @UspName) 
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('CREATE PROCEDURE ' + @SchemaName + '.' + @UspName)

INSERT INTO @Lines (Line)
SELECT	'@' + ColumnName + REPLICATE(char(9), (@VarTabs - ((LengthName + 1)/4))) + TypeName + 
		CASE	
			WHEN ColumnLength IS NOT NULL 
				THEN '(' +	CASE	WHEN ColumnLength <= 0 THEN 'MAX' 
									ELSE CAST(ColumnLength as varchar(20)) 
							END + ')' 
				ELSE 
					CASE	WHEN TypeName = 'decimal' THEN '(' +	CAST(LengthMax as varchar(10)) + ', ' + CAST(Scale as varchar(10)) + ')' 
							ELSE ''
					END
		END + ','
FROM	@Columns
ORDER BY Column_ID

INSERT INTO @Lines VALUES ('@CurrentUserID' + CHAR(9) + 'int = 1')

INSERT INTO @Lines VALUES ('AS')
INSERT INTO @Lines VALUES ('/*	==========================================================================================')
INSERT INTO @Lines VALUES (CHAR(9) + 'Purpose: ' + CHAR(9) + 'Update ' + @SchemaName + '.' + @TableName + ' on basis of ' + @PK + '.')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (CHAR(9) + CONVERT( varchar(10), GETDATE(), 105) + CHAR(9) 
							+ (SELECT UserName FROM @Users WHERE SUSER = SUSER_SNAME()) + CHAR(9) + 'Initial version.')
INSERT INTO @Lines VALUES (CHAR(9) + '==========================================================================================' + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('DECLARE @ExecutedProcedureID int = 0')
INSERT INTO @Lines VALUES ('EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('DECLARE @Return' + REPLICATE(CHAR(9), 2) + 'int = 1')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('DECLARE @XMLdel' + REPLICATE(CHAR(9), 2) + 'xml,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + '@XMLins' + REPLICATE(CHAR(9), 2) + 'xml,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + '@LogDate' + CHAR(9) + 'datetime = GETDATE(),')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + '@KeyID' + REPLICATE(CHAR(9), 2) + 'varchar(50)')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('IF ISNULL(@' + @PK + ', 0) = 0')
INSERT INTO @Lines VALUES ('BEGIN')
INSERT INTO @Lines VALUES (CHAR(9) + '-- Add new record')
INSERT INTO @Lines VALUES (CHAR(9) + 'INSERT INTO ' + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2)  + '(')

INSERT INTO @Lines (Line)
SELECT	REPLICATE(CHAR(9), 3) + ColumnName +
		CASE	WHEN Column_ID <> @LastColumn 
					THEN ','
				ELSE '' 
				END
FROM	@Columns
WHERE ColumnName <> @PK
ORDER BY Column_ID

INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2)  + ')')

INSERT INTO @Lines VALUES (CHAR(9) + 'VALUES')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2)  + '(')

INSERT INTO @Lines
SELECT	REPLICATE(CHAR(9), 3) + '@' + ColumnName +
		CASE	WHEN Column_ID <> @LastColumn 
					THEN ','
				ELSE '' 
				END
FROM	@Columns
WHERE ColumnName <> @PK
ORDER BY Column_ID

INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2)  + ')')

INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (CHAR(9)  + 'SET	@' + @PK + ' = SCOPE_IDENTITY()')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES (CHAR(9) + '-- Save new record.')
INSERT INTO @Lines VALUES (CHAR(9) + 'SELECT' + CHAR(9) + '@XMLdel = NULL,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@XMLins = (' + CHAR(9) + 'SELECT ' + CHAR(9) + '*')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FROM' + CHAR(9) + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'WHERE'+ CHAR(9) + @PK + ' = @' + @PK)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FOR XML PATH )')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('END')
INSERT INTO @Lines VALUES ('ELSE')
INSERT INTO @Lines VALUES ('BEGIN')

INSERT INTO @Lines VALUES (CHAR(9) + '-- Save old record.')
INSERT INTO @Lines VALUES (CHAR(9) + 'SELECT' + CHAR(9) + '@XMLdel = (' + CHAR(9) + 'SELECT ' + CHAR(9) + '*')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FROM' + CHAR(9) + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'WHERE'+ CHAR(9) + @PK + ' = @' + @PK)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FOR XML PATH )')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES (CHAR(9) + '-- Update existing record.')
INSERT INTO @Lines VALUES (CHAR(9) + 'UPDATE' + char(9) + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES (CHAR(9) + 'SET')
INSERT INTO @Lines (Line)
SELECT	REPLICATE(CHAR(9), 3) + ColumnName + REPLICATE(char(9), (@Tabs - ((LengthName)/4))) + '= ' + '@' + ColumnName +
		CASE	WHEN Column_ID <> @LastColumn 
					THEN ','
				ELSE '' 
				END
FROM	@Columns
WHERE ColumnName <> @PK
ORDER BY Column_ID

INSERT INTO @Lines VALUES (CHAR(9) + 'WHERE' + char(9) + @PK + ' = @' + @PK)
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES (CHAR(9) + '-- Save new record.')
INSERT INTO @Lines VALUES (CHAR(9) + 'SELECT' + CHAR(9) + '@XMLins = (' + CHAR(9) + 'SELECT ' + CHAR(9) + '*')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FROM' + CHAR(9) + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'WHERE'+ CHAR(9) + @PK + ' = @' + @PK)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'FOR XML PATH )')

INSERT INTO @Lines VALUES ('END')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('-- Log action in his.tblHistory.')
INSERT INTO @Lines VALUES ('IF CAST(ISNULL(@XMLdel, '''') AS varchar(MAX)) <> CAST(ISNULL(@XMLins, '''') AS varchar(MAX))')
INSERT INTO @Lines VALUES ('BEGIN')
INSERT INTO @Lines VALUES (CHAR(9) + 'SET @KeyID = @' + @PK)
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (CHAR(9) + 'EXEC his.uspHistory_Add')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '''' + @SchemaName + '.' + @TableName + ''',')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@KeyID,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@CurrentUserID,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@LogDate,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@XMLdel,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@XMLins')
INSERT INTO @Lines VALUES ('END')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('SELECT ' + @PK + ' = @' + @PK)
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID')
INSERT INTO @Lines VALUES ('')

--INSERT INTO @Lines VALUES ('SET @Return = 0')
--INSERT INTO @Lines VALUES ('')

--INSERT INTO @Lines VALUES ('RETURN @Return')
--INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('/*	== ' + @SchemaName + '.' + @UspName + ' ' + REPLICATE('=', 86 - LEN(@SchemaName + '.' + @UspName))  + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')

SELECT Line 
FROM @Lines
ORDER BY Row
