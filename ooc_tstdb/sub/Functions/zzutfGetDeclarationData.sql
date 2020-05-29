

CREATE Function [sub].[zzutfGetDeclarationData] (@DeclarationID int)
/*
   24-07-2018	Jaap van Assenbergh
				Ophalen Start periode, eind periode en einde declaratie periode
*/
   
RETURNS TABLE AS RETURN

SELECT	DeclarationDate, 
		StartPeriod, 
		EndPeriod,
		DATEADD(day, -1, CAST(sub.usfDateAdd(SubmitInterval, SubmitIncrement, EndPeriod) as date)) EndDeclarationPeriod
FROM
		(
			SELECT	DeclarationDate, 
					StartPeriod, 
					DATEADD(day, -1, CAST(sub.usfDateAdd(Interval, Increment, StartPeriod) as date)) EndPeriod,
					SubmitInterval, SubmitIncrement
			FROM
					(
						SELECT	d.DeclarationDate, 
								CAST(DATEADD(yy, DATEDIFF(yy, 0, d.DeclarationDate), 0)  as date) StartPeriod,
								ss.Interval, 
								ss.Increment,
								ss.SubmitInterval, 
								ss.SubmitIncrement
						FROM sub.tblDeclaration d
						INNER JOIN sub.tblSubsidyScheme ss ON ss.Subsidyschemeid = d.Subsidyschemeid
						WHERE d.DeclarationID = @DeclarationID
					) s
		) e

