CREATE VIEW dbo.[viewMonthNameByLanguage]
AS
SELECT	k.langid,
		k.languageName,
		k.alias,
		k.MonthNumber,
		k.MonthNameLong,
		s.MonthNameShort
FROM	dbo.viewMonthNameLongByLanguage k
INNER JOIN	dbo.viewMonthNameShortByLanguage s 
		ON	s.langid = k.langid 
		AND	s.MonthNumber = k.MonthNumber
