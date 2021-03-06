﻿CREATE VIEW dbo.[viewMonthNameShortByLanguage]
AS
    WITH N1 AS 
		(
			SELECT	N 
			FROM	(VALUES(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) n (N)),
					Numbers (Number) AS 
					(
						SELECT ROW_NUMBER() OVER(ORDER BY N1.N) 
						FROM	N1 AS N1 
						CROSS JOIN N1 AS N2
					)

SELECT  l.langid,
		languageName = l.name,
		l.alias,
		MonthNumber = ROW_NUMBER() OVER(PARTITION BY l.[langid] ORDER BY nMonthName.Number),
		[MonthNameShort] = SUBSTRING(l.shortmonths, nMonthName.Number, CHARINDEX(',', l.shortmonths + ',', nMonthName.Number) - nMonthName.Number)
FROM    master.sys.[syslanguages] AS l
INNER JOIN Numbers AS nMonthName
    ON (SUBSTRING(l.shortmonths, nMonthName.Number -1, 1) = ',' OR nMonthName.Number = 1)
--AND [langid] = 7
