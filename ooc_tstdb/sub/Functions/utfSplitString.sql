
CREATE Function [sub].[utfSplitString] (@Str nVarChar(4000), @Separator Char(1))
/* p = CTE Level
   a = Startpositie
   b = Positie seperator gevonden

   24-07-2018	Jaap van Assenbergh
*/
   
RETURNS TABLE AS RETURN
(WITH Tokens(p, a, b) AS
	(SELECT 1, 1, CHARINDEX(@Separator, @Str)
	  UNION ALL
     SELECT p + 1, b + 1, CHARINDEX(@Separator, @Str, b + 1)
       FROM Tokens
      WHERE b > 0 )
   
	SELECT p-1 zeroBasedOccurance,
		   LTRIM(RTRIM(SUBSTRING(@Str, a,	CASE 
											WHEN b > 0 THEN b-a		/* Lengte SubString = Seperator gevonden - StartPositie */
											ELSE 4000 END))) AS s		/* Seperator niet meer gevonden Lengte SubString = maximale lengte */
		   --SUBSTRING(@Str, a,	CASE 
					--			WHEN b > 0 THEN b-a		/* Lengte SubString = Seperator gevonden - StartPositie */
					--			ELSE 4000 END) AS s		/* Seperator niet meer gevonden Lengte SubString = maximale lengte */
	FROM Tokens)


