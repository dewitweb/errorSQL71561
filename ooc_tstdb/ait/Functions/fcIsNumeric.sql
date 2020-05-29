 
CREATE FUNCTION [ait].[fcIsNumeric](@in nchar(1))
RETURNS bit
AS
/*	==========================================================================================
	Purpose: Part of the anonimize functionality for AVG.

	13-03-2013	Sander van Houten	Initial version.
	==========================================================================================	*/
BEGIN
	DECLARE @out bit

	IF (@in IN ('0','1','2','3','4','5','6','7','8','9'))
		SET @out = 1
	ELSE
		SET @out = 0

	RETURN @out
END
/*	== ait.fcIsNumeric========================================================================	*/

