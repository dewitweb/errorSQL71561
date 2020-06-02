CREATE VIEW dbo.[viewMonthNameLongByLanguage]
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

SELECT [langid]
      ,[dateformat]
      ,[datefirst]
      ,[upgrade]
      ,[name]
      ,[alias]
      ,[months]
      ,[shortmonths]
      ,[days]
      ,[lcid]
      ,[msglangid]
  FROM master.sys.[syslanguages]
