



CREATE    FUNCTION [sub].[usfConcatStrings]
/* *********************************************************************************************
	06-11-2018 Jaap van Assenbergh

	FUNCTIE *************************************************************************************
	ConCat
	INVOER **************************************************************************************
	- @String1
	- @String2
	- @Scheidingsteken
	- @SpatiesVoor
	- @SpatiesNa
	UITVOER *************************************************************************************
	- String
	********************************************************************************************* */
(
	@String1 nVarChar (500),
	@String2 nVarChar (500),
	@Scheidingsteken nvarchar (10),
	@SpatiesVoor int = 0,
	@SpatiesNa int = 1
)
RETURNS nVarChar (1000)
AS
BEGIN
	DECLARE @ConCat nVarChar (1000)

	IF LTRIM(ISNULL(@String1,''))= '' AND LTRIM(ISNULL(@String2,''))= ''
		SET	@ConCat = ''
	ELSE
	BEGIN
		IF LTRIM(ISNULL(@String1,''))= ''
			SET	@ConCat = RTRIM(ISNULL(@String2,''))
		ELSE IF LTRIM(ISNULL(@String2,''))= ''
			SET	@ConCat = RTRIM(ISNULL(@String1,''))
		ELSE
			SET	@ConCat = RTRIM(ISNULL(@String1,'')) + SPACE(@SpatiesVoor) + @Scheidingsteken + SPACE(@SpatiesNa) + RTRIM(ISNULL(@String2,''))
	END
	RETURN @ConCat
END



