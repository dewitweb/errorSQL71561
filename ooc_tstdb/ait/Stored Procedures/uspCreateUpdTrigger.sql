CREATE PROCEDURE [ait].[uspCreateUpdTrigger] 
	@SchemaName varchar(10),
	@TableName varchar(100),
	@Collect as bit = 0
AS
/*	==========================================================================================
	04-05-2017	Jaap van Assenbergh
				Genereren van een standaard update trigger tbv history
	18-07-2018	Jaap van Assenbergh
				SchemaName toegevoegd
	==========================================================================================
*/

IF @SchemaName IS NULL SET @SchemaName = 'dbo'

DECLARE @TrgName		varchar(100)
DECLARE @PK				varchar(100) 
DECLARE @UserName		varchar(100) 
DECLARE @MaxLength		int
DECLARE @LastColumn		int
DECLARE @LastModifiedBy	varchar(100) 

DECLARE @Lines as TABLE (Row int IDENTITY(1,1), Line varchar(MAX))

DECLARE @Users as TABLE (SUSER varChar(100), UserName varchar(MAX))
INSERT INTO @Users VALUES ('AmbitionITJaap', 'Jaap van Assenbergh')
INSERT INTO @Users VALUES ('AmbitionITSander', 'Sander van Houten')
INSERT INTO @Users VALUES ('Jaap_Amb_Lap\Jaap', 'Jaap van Assenbergh')

SELECT	@PK = ccu.COLUMN_NAME
FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS ccu
ON		tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
WHERE	tc.TABLE_NAME = @TableName
AND		tc.CONSTRAINT_TYPE = 'PRIMARY KEY'

SET		@TrgName = 'trg'+ SUBSTRING(@TableName, 4, LEN(@TableName)) + '__Upd'

SELECT	@LastModifiedBy = Name
FROM	SYS.Columns
WHERE	OBJECT_Name(object_id) = @TableName
AND		Name LIKE '%LastModifiedUserID'

INSERT INTO @Lines VALUES ('USE [' + DB_NAME() + ']')
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')

INSERT INTO @Lines VALUES ('IF OBJECT_ID(''' + @SchemaName + @TrgName + ''', ''TR'') IS NOT NULL')
INSERT INTO @Lines VALUES ('DROP TRIGGER ' + @SchemaName + @TrgName) 
INSERT INTO @Lines VALUES ('GO')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('CREATE TRIGGER ' + @SchemaName + @TrgName)
INSERT INTO @Lines VALUES ('ON ' + @SchemaName + @TableName)
INSERT INTO @Lines VALUES ('FOR INSERT, UPDATE, DELETE')
INSERT INTO @Lines VALUES ('AS')
INSERT INTO @Lines VALUES ('/*	==========================================================================================')
INSERT INTO @Lines VALUES (CHAR(9) + 'Purpose: ' + CHAR(9) + 'Trigger on ' + @TableName + ' for logging mutations.')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (CHAR(9) + CONVERT( varchar(10), GETDATE(), 105) + CHAR(9) 
							+ (SELECT UserName FROM @Users WHERE SUSER = SUSER_SNAME()) + CHAR(9) + 'Inital version.')
INSERT INTO @Lines VALUES (CHAR(9) + '==========================================================================================' + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('DECLARE	@hisID' + CHAR(9) + 'int')
INSERT INTO @Lines VALUES ('DECLARE @XMLins' + CHAR(9) + 'xml')
INSERT INTO @Lines VALUES ('DECLARE @XMLdel' + CHAR(9) + 'xml')
INSERT INTO @Lines VALUES ('DECLARE	@UserID' + CHAR(9) + 'int')
INSERT INTO @Lines VALUES ('DECLARE @varIns' + CHAR(9) + 'varchar(max)')
INSERT INTO @Lines VALUES ('DECLARE @varDel' + CHAR(9) + 'varchar(max)')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('DECLARE @RemoveField' + CHAR(9) + 'varchar (50)')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('SET	@XMLins = (SELECT * FROM inserted FOR xml Path(''row''), ROOT(''rows''))')
INSERT INTO @Lines VALUES ('SET	@XMLdel = (SELECT * FROM deleted FOR xml Path(''row''), ROOT(''rows''))')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('SET	@varIns = ISNULL(CAST(@XMLins AS VARCHAR(MAX)),'''')')
INSERT INTO @Lines VALUES ('SET	@varDel = ISNULL(CAST(@XMLdel AS VARCHAR(MAX)),'''')')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('/* Last Modified date verwijderen */')
INSERT INTO @Lines VALUES ('SET @RemoveField = ''LastModifiedDate''')
INSERT INTO @Lines VALUES ('SELECT @varIns = dbo.udf_RemoveFieldFromXML(@varIns, @RemoveField)')
INSERT INTO @Lines VALUES ('SELECT @varDel = dbo.udf_RemoveFieldFromXML(@varDel, @RemoveField)')
INSERT INTO @Lines VALUES ('') 
INSERT INTO @Lines VALUES ('SET @RemoveField = ''LastModifiedUserId''')
INSERT INTO @Lines VALUES ('SELECT @varIns = dbo.udf_RemoveFieldFromXML(@varIns, @RemoveField)')
INSERT INTO @Lines VALUES ('SELECT @varDel = dbo.udf_RemoveFieldFromXML(@varDel, @RemoveField)')
INSERT INTO @Lines VALUES ('') 
INSERT INTO @Lines VALUES ('IF @varDel <> @varIns')
INSERT INTO @Lines VALUES ('BEGIN')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'SELECT @UserID = UserID ')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'FROM')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + '(')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'SELECT ')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'UserID = I.value(''' + @LastModifiedBy +'[1]'', ''int'')')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'FROM @XMLins.nodes(''/row'') AS T(I)')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + ') ins')
INSERT INTO @Lines VALUES ('') 
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'INSERT INTO his.tblHistory')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + '(hisTable, hisPKID, hisUserID, hisActionID, hisOldValue, hisNewValue)')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'SELECT' + CHAR(9) + '''' + @TableName + ''' hisTableName,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'ISNULL(insertedID, deletedID) hisPKID,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@UserID,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'CASE WHEN insertedID IS NULL THEN 0 ELSE 1 END +')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'CASE WHEN deletedID IS NULL THEN 0 ELSE 2 END as hisActieID,')

INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '(')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'SELECT	tabel.kolom.query(''.'')')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'FROM	@XMLDel.nodes(''rows/row'') tabel(kolom)')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'WHERE	tabel.kolom.value(''' + @PK + '[1]'',''int'') = deletedID')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + ') hisOldValue,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '(')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'SELECT	tabel.kolom.query(''.'')')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'FROM	@XMLIns.nodes(''rows/row'') tabel(kolom)')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'WHERE	tabel.kolom.value(''' + @PK + '[1]'',''int'') = insertedID')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + ') hisNewValue')

--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@XMLdel hisOldValue,')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + '@XMLins hisNewValue')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'FROM')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + '(')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + 'SELECT' + CHAR(9) + 'i.' + @PK + ' insertedID,')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + 'd.' + @PK + ' deletedID')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + 'FROM	inserted i')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + 'FULL OUTER JOIN deleted d ON i.' + @PK + ' = d.' + @PK)
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + ') O')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'SET @hisID = SCOPE_IDENTITY()')
INSERT INTO @Lines VALUES ('') 
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'IF @hisID IS NOT NULL')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'BEGIN')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + 'IF 	@XMLins IS NULL')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'SELECT @UserID = UserID					-- Dit is niet de user die het record heeft verwijderd.')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 3) + 'FROM')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + '(')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 5) + 'SELECT ')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 6) + 'UserID = D.value(''' + @LastModifiedBy +'[1]'', ''int'')')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 5) + 'FROM @XMLdel.nodes(''/row'') AS T(D)')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 4) + ') del')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 2) + 'ELSE')
--INSERT INTO @Lines VALUES (REPLICATE(CHAR(9), 1) + 'END')
INSERT INTO @Lines VALUES ('END')
INSERT INTO @Lines VALUES ('')
INSERT INTO @Lines VALUES ('/*	== ' + @TrgName + ' ' + REPLICATE('=', 86 - LEN(@TrgName))  + CHAR(9) +'*/')
INSERT INTO @Lines VALUES ('GO') 
INSERT INTO @Lines VALUES ('')

IF @Collect = 1
	INSERT INTO ##Lines
	SELECT Line 
	FROM @Lines
	ORDER BY Row
ELSE
	SELECT Line 
	FROM @Lines
	ORDER BY Row

