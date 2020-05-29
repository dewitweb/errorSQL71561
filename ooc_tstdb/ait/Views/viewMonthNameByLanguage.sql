CREATE VIEW [ait].[viewMonthNameByLanguage]
AS
SELECT	l.langid,
		l.languageName,
		l.alias,
		l.MonthNumber,
		l.MonthNameLong,
		s.MonthNameShort
FROM	ait.viewMonthNameLongByLanguage l
INNER JOIN	ait.viewMonthNameShortByLanguage s 
		ON	s.langid = l.langid 
		AND	s.MonthNumber = l.MonthNumber
