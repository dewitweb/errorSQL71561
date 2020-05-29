

CREATE FUNCTION [ait].[fcAnonimize](@string nvarchar(MAX),@key nvarchar(32) )
RETURNS nvarchar(MAX)
AS
/*	==========================================================================================
	Purpose: Part of the anonimize functionality for AVG.

	13-03-2019	Sander van Houten	Initial version.
	==========================================================================================	*/
BEGIN
	DECLARE	@position int,
			@pos int,
			@charReplace char(1),
			@char char(1),
			@translateLC nvarchar(50),
			@translateUC nvarchar(50),
			@translateDC nvarchar(10),
			@stringNew nvarchar(MAX),
			@shift int,
			@keylength int
 
	SELECT	@translateLC  = 'abcdefghijklmnopqrstuvwxyz',
			@translateUC  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
			@translateDC  = '1234567890',
			@keylength = LEN(@key),
  			@position = 1

	SELECT @string = sub.usfCreateSearchString(@string)

	WHILE @position <= LEN(@string)
	BEGIN 
		SELECT	@char = SUBSTRING(@string, @position, 1),
				@charReplace = @char,
				@shift = @position % @keylength,
				@shift = CONVERT(int,SUBSTRING(@key ,@shift, 1))

		IF [ait].[fcIsNumeric](@char) = '1' 
		BEGIN -- Numeric
			SET @pos = CHARINDEX(@char, @translateDC, 1)

			IF @pos > 0 
			BEGIN  
				SET @pos = 	@pos + @shift  

				IF @pos > 10
				BEGIN
					SET @pos = @pos - 10
				END

				SET @charReplace = SUBSTRING(@translateDC, @pos, 1) 
			END -- END DC	
		END -- END Numeric
		ELSE 
		BEGIN -- Not Numeric 
 			SET @pos = CHARINDEX(@char, @translateLC, 1) 

			IF @pos > 0 
			BEGIN -- Lower Case
				SET @pos = 	@pos + @shift  

				IF @pos > 26
				BEGIN
					SET @pos = @pos - 26
				END

				SET @charReplace = SUBSTRING(@translateLC, @pos, 1) 
			END -- END LC
			ELSE  
			BEGIN -- Upper Case
				SET @pos = CHARINDEX(@char, @translateUC, 1) 

				IF @pos > 0 
				BEGIN
					SET @pos = 	@pos + @shift 
					
					IF @pos > 26
					BEGIN
						SET @pos = @pos - 26
					END

					SET @charReplace = SUBSTRING(@translateUC, @pos, 1) 	  
				END -- END UC
			END -- END Not Numeric 
		END

		SET @position = @position + 1

		SET @stringNew = ISNULL(@stringNew,'') + @charReplace
	END

	RETURN ISNULL(@stringNew, '')
END 
/*	== ait.fcAnonimize========================================================================	*/
 
