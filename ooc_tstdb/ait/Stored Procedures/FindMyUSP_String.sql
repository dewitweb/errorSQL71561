

CREATE PROCEDURE [ait].[FindMyUSP_String]
    @DataToFind NVARCHAR(4000)
AS
SET NOCOUNT ON

SELECT s.Name [Schema], OBJECT_NAME(m.OBJECT_ID) AS [Object], @DataToFind AS ZoekOp , m.[definition] 
FROM sys.sql_modules m
INNER JOIN sys.Objects o ON o.object_id = m.object_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE CHARINDEX(@DataToFind, [definition], 1) <> 0
ORDER BY 1, 2

