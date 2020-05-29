
CREATE    FUNCTION [sub].[usfFormatNumericString]
/*	*********************************************************************************************
	12-12-2018 Jaap van Assenbergh
	********************************************************************************************* */
(
	@Amount	decimal(19,4)
)
RETURNS varchar(25)
AS
BEGIN
	DECLARE @BeforeDec char(20)
	DECLARE @AfterDec char(4)
	DECLARE @Pos int = 4

	SELECT @BeforeDec = SUBSTRING(REVERSE(CAST(@Amount as varchar(20))), 6, 20)
	SELECT @AfterDec = LEFT(RIGHT(CAST(@Amount as varchar(20)), 4), 2)

	WHILE	SUBSTRING(@BeforeDec, @Pos, 1) <> ' '
	BEGIN
		SET @BeforeDec = LEFT(@BeforeDec, @Pos - 1) + '.' + SUBSTRING(@BeforeDec, @Pos, 20)
		SET @Pos = @Pos + 4
	END
	
	RETURN RTRIM(LTRIM(REVERSE(@BeforeDec) + ',' + @AfterDec))

END
