
CREATE PROCEDURE [ait].[uspAnonimizer]
@key nvarchar(32)
AS
/*	==========================================================================================
	Purpose: Part of the anonimize functionality for AVG.

	13-03-2019	Jaap van Assenbergh	Triggerproof version
				1.	Delete disabled triggers
				2.	Disable all triggers
				3.	Anominize database
				4	Enable all triggers.
	13-03-2019	Sander van Houten	Initial version.
	==========================================================================================	*/
DECLARE @tableName nvarchar(100), 
		@tableNameLast nvarchar(100), 
		@columnName Nvarchar(100),
		@qry nvarchar(3000),
		@template nvarchar(3000)

DECLARE	@schemaName nvarchar(100),
		@triggerName nvarchar(100)
		

DECLARE @CommitCounter int = 0

/*	To Anominize the database the triggers must be disabled.
	Therefore the command DISABLE TRIGGER ALL will be used.
	At the end of the procedure command ENABLE TRIGGER ALL will be used.
	To forestall that disabled triggers in de backup will get enabled after the anominze first 
	delete disabled triggers.																	*/

DECLARE crs_DisabledTrigger CURSOR FOR
	SELECT	s.name, t.name --, o.name
	FROM	sys.triggers t
	INNER JOIN sys.objects o ON o.object_id= t.parent_id
	INNER JOIN sys.schemas s on o.schema_id = s.schema_id
	WHERE	is_disabled = 1
OPEN crs_DisabledTrigger
FETCH NEXT FROM crs_DisabledTrigger INTO @schemaName, @triggerName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @triggerName = @schemaName + '.' + @triggerName
	PRINT @triggerName

	IF OBJECT_ID(@triggerName, 'TR') IS NOT NULL  
	BEGIN
	    SET @qry = 'DROP TRIGGER '+ @triggerName
		EXEC sp_executesql @qry
	END
	FETCH NEXT FROM crs_DisabledTrigger INTO @schemaName, @triggerName
END

CLOSE crs_DisabledTrigger
DEALLOCATE crs_DisabledTrigger

EXEC sp_MSforeachtable @command1="ALTER TABLE ? DISABLE TRIGGER ALL"

SET @template = '@columnName = [ait].[fcAnonimize](@columnName, @key)'

DECLARE crs_Table CURSOR FOR
SELECT  TableName, ColumnName
FROM	ait.tblAnonimizer 
ORDER BY TableName

OPEN crs_Table

FETCH NEXT FROM crs_Table INTO @tableName, @columnName

IF @@FETCH_STATUS <> 0 GOTO uspAnonimizer_EXIT

SET @tableNameLast = @tableName

SET @qry = 'UPDATE ' + @tableName + ' SET ' + REPLACE(REPLACE(@template, '@columnName', @columnName), '@key', @key) + ' '

BEGIN TRANSACTION

WHILE @@FETCH_STATUS = 0
BEGIN
	FETCH NEXT FROM crs_Table INTO @tableName, @columnName
	IF @@FETCH_STATUS = 0 
		BEGIN

		IF @tableNameLast = @tableName
			BEGIN
				SET @qry = @qry + ', ' + REPLACE(REPLACE(@template, '@columnName', @columnName), '@key', @key) + ' '
			END
		ELSE 
			BEGIN
--				SET @qry = @qry + @WHERE		------
				PRINT @qry
				EXEC sp_executesql @qry 

				COMMIT TRANSACTION
				BEGIN TRANSACTION

				SET @tableNameLast = @tableName

				SET @qry = 'UPDATE ' + @tableName + ' SET ' + REPLACE(REPLACE(@template, '@columnName', @columnName), '@key', @key) + ' '
			END
		END
END

PRINT @qry
--SET @qry = @qry + @WHERE						------
EXEC sp_executesql @qry
COMMIT TRANSACTION


CLOSE crs_Table
DEALLOCATE crs_Table

uspAnonimizer_EXIT:

EXEC sp_MSforeachtable @command1="ALTER TABLE ? ENABLE TRIGGER ALL"

/*	== ait.uspAnonimizer======================================================================	*/

