

CREATE FUNCTION [sub].[usfConvertIntToRoman](@i INT)  
RETURNS VARCHAR(100)  
AS  
BEGIN  
RETURN	REPLICATE('M', @i / 1000)  
		+ REPLACE(
					REPLACE(
							REPLACE(	REPLICATE('C', @i%1000 / 100),  
										REPLICATE('C', 9), 'CM'),  
										REPLICATE('C', 5), 'D'),  
										REPLICATE('C', 4), 'CD')  
		+ REPLACE(
					REPLACE(
							REPLACE(	REPLICATE('X', @i%100 / 10),  
										REPLICATE('X', 9), 'XC'),  
										REPLICATE('X', 5), 'L'),  
										REPLICATE('X', 4), 'XL')  
		+ REPLACE(
					REPLACE(
							REPLACE(  
										REPLICATE('I', @i%10),  
										REPLICATE('I', 9), 'IX'),  
										REPLICATE('I', 5), 'V'),  
										REPLICATE('I', 4), 'IV')  
  
END  
