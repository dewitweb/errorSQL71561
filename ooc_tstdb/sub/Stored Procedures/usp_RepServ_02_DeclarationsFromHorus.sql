
CREATE proc [sub].[usp_RepServ_02_DeclarationsFromHorus]
@SearchString varchar(max)
as

/*	==========================================================================================
	Purpose:	Source for declaration list, imported from Horus, in SSRS.

	Parameters:
	@SearchString: free text, like a declaration number or an MN number.

	09-04-2019	Jaap van Assenebrgh		OTIBSUB-925		
	07-04-2019, H. Melissen				OTIBSUB-925		Initial version
	==========================================================================================	*/

/*	Testdata for input parameters. */
--DECLARE @SearchString varchar(max)

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	@SearchString	= ISNULL(@SearchString, '')

/*	Prepaire SearchString													*/
SELECT	@SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

--SELECT * FROM @SearchWord

SELECT	hor.DeclarationNumber						Declaratienummer_HRS, 
		hor.ParentDeclarationNumber					Declaratienummer_DS, 
		hor.EmployerNumber							[Werkgeversnummer],
		CONVERT(varchar(10), hor.StartDate, 120)	Startdatum, 
		CONVERT(varchar(10), hor.EndDate, 120)		Einddatum, 
		hor.DeclarationStatus						Status_HRS,
		CONVERT(varchar(10), his.logdate, 120)	[Datum geïmporteerd in DS] 
FROM	sub.tblDeclaration d
INNER JOIN hrs.tblDeclaration_OSR2019 hor 
	ON	hor.ParentDeclarationNumber = d.DeclarationID
INNER JOIN his.tblHistory his 
	ON  his.KeyID = d.DeclarationID 
	AND	his.TableName = 'sub.tblDeclaration' 
	AND	his.KeyID < 400000 
	AND	his.OldValue IS NULL 
	AND	his.NewValue IS NOT NULL
CROSS JOIN @SearchWord sw
WHERE
		'T' = 												-- DeclarationID DS
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, CAST(d.DeclarationID as varchar(6)), 1) > 0 
						THEN	'T'
				END
	OR
		'T' = 												-- DeclarationNumber Horus
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, CAST(hor.DeclarationNumber as varchar(6)), 1) > 0 
						THEN	'T'
				END
	OR		'T' = 											-- MN Number employer
				CASE
					WHEN		@SearchString = '' 
						THEN 'T'
					WHEN		CHARINDEX(sw.Word, d.EmployerNumber, 1) > 0 
						THEN	'T'
				END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
