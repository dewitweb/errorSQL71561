
CREATE PROCEDURE [ait].[uspCreateGetUSP] 
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

DECLARE @Columns AS TABLE (ColumnName varchar(256), TypeName varchar(20), ColumnLength int, Column_ID int, LengthName int)
DECLARE @UspName varchar(100)
DECLARE @PK varchar(100) 
DECLARE @varPK varchar(100) 
DECLARE @UserName varchar(100) 
DECLARE @MaxLength int
DECLARE @LastColumn int

DECLARE @Tabs int

DECLARE @Lines as TABLE (Row int IDENTITY(1,1), Line varchar(MAX))

DECLARE @Users as TABLE (SUSER varChar(100), UserName varchar(MAX))
INSERT INTO @Users VALUES ('AmbitionITJaap', 'Jaap van Assenbergh')
INSERT INTO @Users VALUES ('AmbitionITSander', 'Sander van Houten')
INSERT INTO @Users VALUES ('AMBITIONIT-004\Jaap', 'Jaap van Assenbergh')

INSERT INTO @Columns
SELECT ColumnName, TypeName, ColumnLength, Column_ID, LengthName
FROM	(
			SELECT C.Name as ColumnName, T.Name As TypeName, 
			CASE	WHEN t.name = 'nvarchar' 
						THEN C.max_length/2 
					ELSE 
						CASE	WHEN t.name = 'varchar' 
									THEN C.max_length 
								END 
							END AS ColumnLength, 
			C.Column_ID, LEN(C.Name) AS LengthName
			FROM	sys.tables Tab
			INNER JOIN sys.schemas S ON S.schema_id = Tab.schema_id
			INNER JOIN sys.Columns C ON C.object_id = Tab.object_id
			INNER JOIN sys.types T ON T.user_type_id = C.user_type_id
			WHERE OBJECT_NAME(C.Object_ID) = @TableName
			AND s.name = @SchemaName
		) a
ORDER BY Column_ID

SELECT @MaxLength = MAX(LengthName) FROM @Columns
SELECT @PK = ColumnName From @Columns WHERE Column_ID = 1
SELECT @varPK = '@' + ColumnName From @Columns WHERE Column_ID = 1
SELECT @LastColumn = MAX(Column_ID) FROM @Columns

SELECT @Tabs = @MaxLength/4
IF @MaxLength % 4 <> 0
	SET @Tabs = @Tabs + 1

--INSERT INTO @Lines VALUES ('USE [' + DB_NAME() + ']')
--INSERT INTO @Lines VALUES ('GO')
--INSERT INTO @Lines VALUES ('')


SET @UspName = 'usp'+ SUBSTRING(@TableName, 4, LEN(@TableName)) + '_Get'

INSERT INTO @Lines VALUES ('IF OBJECT_ID(''' + @SchemaName + '.' + @UspName + ''', ''P'') IS NOT NULL')
INSERT INTO @Lines VALUES ('DROP PROCEDURE ' + @SchemaName + '.' + @UspName) 
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('CREATE PROCEDURE ' + @SchemaName + '.' + @UspName)

INSERT INTO @Lines (Line)
SELECT	'@' + ColumnName + char(9) + TypeName + 
		CASE	WHEN ColumnLength IS NOT NULL 
					THEN '(' +	CASE	WHEN ColumnLength = 0 
											THEN 'MAX' 
										ELSE CAST(ColumnLength as varchar(20)) 
								END + ')' 
								ELSE 
									'' 
								END
		--CASE	WHEN Column_ID <> @LastColumn
		--			THEN ','
		--		ELSE '' 
		--		END
FROM	@Columns
WHERE Column_ID = 1
ORDER BY Column_ID

INSERT INTO @Lines VALUES ('AS')
INSERT INTO @Lines VALUES ('/*	==========================================================================================')
INSERT INTO @Lines VALUES (CHAR(9) + 'Purpose: ' + CHAR(9) + 'Get data from ' + @SchemaName + '.' + @TableName + ' on basis of ' + @PK + '.')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (CHAR(9) + CONVERT( varchar(10), GETDATE(), 105) + CHAR(9) 
							+ (SELECT UserName FROM @Users WHERE SUSER = SUSER_SNAME()) + CHAR(9) + 'Inital version.')
INSERT INTO @Lines VALUES (CHAR(9) + '==========================================================================================' + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('DECLARE @ExecutedProcedureID int = 0')
INSERT INTO @Lines VALUES ('EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('SELECT')

INSERT INTO @Lines (Line)
SELECT	REPLICATE(CHAR(9), 2) + ColumnName +
		CASE	WHEN Column_ID <> @LastColumn
					THEN ','
				ELSE ''
				END
FROM	@Columns
ORDER BY Column_ID

INSERT INTO @Lines VALUES ('FROM' + CHAR(9) + @SchemaName + '.' + @TableName)
INSERT INTO @Lines VALUES ('WHERE' + CHAR(9) + @PK + ' = @' + @PK)

INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('/*	== ' + @UspName + ' ' + REPLICATE('=', 86 - LEN(@UspName))  + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')

SELECT Line 
FROM @Lines
ORDER BY Row
