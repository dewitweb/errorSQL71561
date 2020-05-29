CREATE PROCEDURE [sub].[uspEmployer_Subsidy_Overview] 
@EmployerNumber		varchar(8)
AS
/*	==========================================================================================
	Purpose:	Get an overview of all scholingsbudgets.

	16-08-2019	Sander van Houten		OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	29-05-2019	Jaap van Assenbergh		OTIBSUB-1132	Definition of 'Active BPV-s'.
	29-01-2019	Sander van Houten		OTIBSUB-599		Initial version.
	==========================================================================================	*/

DECLARE @ReferenceDate	date = '20190107'

SELECT	sub.WerkgeverNummer,
		sub.WerkgeverNaam,
		CASE sub.Moeder_dochterrelatie
			WHEN 0 THEN 'Nee'
			ELSE 'Ja (' + CAST(sub.Moeder_dochterrelatie AS varchar(10)) + ' dochter(s))'
		END		AS Moeder_dochterrelatie,
		sub.Aantal_actieve_werknemers,
		sub.Aantal_actieve_BPVers,
		'€ ' + REPLACE(CAST(CAST(sub.Scholingsbudget_2019 AS decimal(19,2))	AS varchar(20)), '.', ',')	AS Scholingsbudget_2019
FROM	(
			SELECT	emp.EmployerNumber			AS WerkgeverNummer,
					emp.EmployerName			AS WerkgeverNaam,
					(SELECT	COUNT(DISTINCT epa.EmployerNumberChild)
					 FROM	sub.tblEmployer_ParentChild epa
					 WHERE	epa.EmployerNumberParent = emp.EmployerNumber )			AS Moeder_dochterrelatie,
					COUNT(eme.EmployeeNumber)										AS Aantal_actieve_werknemers,
					SUM(CASE WHEN bpv_ja.EmployeeNumber IS NULL THEN 0 ELSE 1 END)	AS Aantal_actieve_BPVers,
					esu.Amount					AS Scholingsbudget_2019
			FROM	sub.tblEmployer_Subsidy esu
			INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = esu.EmployerNumber
			INNER JOIN sub.tblEmployer_Employee eme ON eme.EmployerNumber = esu.EmployerNumber
			--LEFT JOIN sub.tblEmployer_ParentChild epa ON epa.EmployerNumberParent = emp.EmployerNumber
			LEFT JOIN hrs.viewBPV bpv_ja 
				ON	bpv_ja.EmployeeNumber = eme.EmployeeNumber
				AND bpv_ja.StartDate <= @ReferenceDate
				AND	COALESCE(bpv_ja.EndDate, @ReferenceDate) >= @ReferenceDate
			WHERE	COALESCE(emp.EndDateMembership, @ReferenceDate) >= @ReferenceDate
			  AND	eme.StartDate <= @ReferenceDate
			  AND	COALESCE(eme.EndDate, @ReferenceDate) >= @ReferenceDate
			  AND	eme.EmployerNumber = @EmployerNumber
			GROUP BY 
					emp.EmployerNumber,
					emp.EmployerName,
					esu.Amount
		) sub

/*	== sub.uspEmployer_Subsidy_Overview ======================================================	*/
