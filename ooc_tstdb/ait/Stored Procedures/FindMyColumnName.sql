

CREATE PROCEDURE [ait].[FindMyColumnName]
    @DataToFind NVARCHAR(4000)
AS
SET NOCOUNT ON

SELECT [Object], [Column], 'SELECT * FROM ' + [Object] + ' WHERE ' + [Column] + ' = ' SQL_Select
FROM 
		(
			SELECT	s.Name + '.' + o.Name as [Object], 
					c.Name as [Column]
			FROM	sys.columns c
			INNER JOIN sys.objects o ON o.object_id = c.object_id
			INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
			WHERE CHARINDEX(@DataToFind, c.name, 1) <> 0
		) cFind
ORDER BY 1

