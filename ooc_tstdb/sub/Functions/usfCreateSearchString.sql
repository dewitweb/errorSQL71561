

/*	==========================================================================================
	24-07-2018:	J.v.Assenbergh
				Clean-up a string for searching
	==========================================================================================
*/
CREATE FUNCTION [sub].[usfCreateSearchString] 
(
	@SearchString nvarChar(MAX)
)
RETURNS nvarChar(MAX)
AS
BEGIN

	SET @SearchString = LTRIM(RTRIM(@SearchString))
	SET @SearchString = REPLACE(@SearchString, char(10),  ' ')  -- Replace Lf by space
	SET @SearchString = REPLACE(@SearchString, char(13),  ' ')  -- Replace Cr by space
	
	DECLARE @tblCharReplace TABLE (ReplaceThis nvarChar(6), WithThis nvarChar(1))
		
	INSERT INTO @tblCharReplace
	VALUES	( '<br>', ' '),
			( '<nbsp>', ' '),
			( '™', ' '),
			( '½', ' '),
			( '½', ' '),
			( 'ç', 'c'),
			( 'ë', 'e'),
			( 'é', 'e'),
			( 'è', 'e'),
			( 'ä', 'a'),
			( 'á', 'a'),
			( 'à', 'a'),
			( 'ö', 'o'),
			( 'ó', 'o'),
			( 'ò', 'o'),
			( 'ï', 'i'),
			( 'í', 'i'),
			( 'ì', 'i'),
			( 'ü', 'u'),
			( 'ú', 'u'),
			( 'ù', 'u'),
			( 'ÿ', 'y'),
			( 'ý', 'y')

	SELECT	@SearchString = REPLACE(@SearchString, ReplaceThis, ISNULL(WithThis, ' ')) 
	FROM	@tblCharReplace

    DECLARE @KeepValues as varchar(50)
    SET		@KeepValues = '%[^a-z 0-9]%'
    WHILE PatIndex(@KeepValues, @SearchString) > 0
        SET @SearchString = Stuff(@SearchString, PatIndex(@KeepValues, @SearchString), 1, ' ')

	WHILE CHARINDEX(CHAR(9), @SearchString) > 0							-- Tab replace
		SET @SearchString = REPLACE(@SearchString, CHAR(9),  N' ') 

	WHILE CHARINDEX(CHAR(10), @SearchString) > 0						-- CR replace
		SET @SearchString = REPLACE(@SearchString, CHAR(10),  N' ') 

	WHILE CHARINDEX(CHAR(13), @SearchString) > 0						-- LF replace
		SET @SearchString = REPLACE(@SearchString, CHAR(13),  N' ') 

	WHILE CHARINDEX(N'  ', @SearchString) > 0
		SET @SearchString = REPLACE(@SearchString, N'  ',  N' ')  
	
	SET		@SearchString = LTRIM(RTRIM(@SearchString))

	RETURN	@SearchString

END

