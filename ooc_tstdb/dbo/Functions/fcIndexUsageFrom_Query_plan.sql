CREATE Function [fcIndexUsageFrom_Query_plan] 
(
	@IndexName	varchar(200),
	@XML		xml
)

/*  ==========================================================================================
	09-03-2018	Jaap van Assenbergh
				Geef de gebruikte scans van een index
    ==========================================================================================
*/
   
RETURNS @Usages TABLE (Usage varchar(50)) 
AS
BEGIN

	DECLARE @varcharXML as varchar(MAX)
	DECLARE @lenXML int
	DECLARE @posObject int
	DECLARE @posRelop int
	DECLARE @revposRelop int
	DECLARE @attrSearch varchar(50)
	DECLARE @posAttributeBegin int
	DECLARE @U TABLE (Usage varchar(50)) 

	SET @varcharXML = CAST(@XML AS varchar(MAX))
	SET @varcharXML = REPLACE(@varcharXML, '''', '')

	SELECT @lenXML = LEN(@varcharXML)
	SELECT @posObject = CHARINDEX(@IndexName, @varcharXML, 1)
	
	WHILE @posObject > 0
	BEGIN
		SELECT @revposRelop = CHARINDEX(REVERSE('<Relop'), REVERSE(@varcharXML), @lenXML- @posObject)
		SET @posRelop = @lenXML - @revposRelop
		SET @attrSearch = 'LogicalOp="'
		SELECT @posAttributeBegin = CHARINDEX(@attrSearch, @varcharXML, @posRelop) + LEN(@attrSearch)

		INSERT INTO @U
		SELECT  SUBSTRING(@varcharXML,  @posAttributeBegin, CHARINDEX('"', @varcharXML, @posAttributeBegin)- @posAttributeBegin)

		SELECT @posObject = CHARINDEX(@IndexName, @varcharXML, @posObject + LEN(@IndexName))
	END

	INSERT INTO @Usages
	SELECT DISTINCT Usage FROM @U

RETURN

END