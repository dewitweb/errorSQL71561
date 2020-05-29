CREATE PROCEDURE [sub].[usp_OTIB_Declaration_List]
@SubsidySchemeID 	sub.uttSubsidySchemeID READONLY,
@EmployerNumber		varchar(6),
@SearchString		varchar(max),
@SortBy				varchar(50)	= 'DeclarationID',
@SortDescending		bit	= 0,
@PageNumber			int,
@RowspPage			int
AS
/*	==========================================================================================
	Purpose:	List all data of searched for declaration for OTIB users.

	15-11-2019	Sander van Houten	    OTIBSUB-1714	Error message when @SearchString contains
                                            a space. Altered (SELECT COUNT(Word) FROM @SearchWord)
                                            into (SELECT COUNT(1) FROM @SearchWord).
	15-10-2019	Sander van Houten	    OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	16-09-2019	Jaap van Assenbergh		OTIBSUB-1562	Performance probleem op usp_OTIB_Declaration_List
	16-08-2019	Sander van Houten		OTIBSUB-1435	Showing the declarationamount again.
	05-08-2019	Sander van Houten		OTIBSUB-1435	Temporarily do not show the declarationamount.
	14-06-2019	Sander van Houten		OTIBSUB-1147	Added STIP parts.
	11-06-2019	Sander van Houten		OTIBSUB-1107	Added EmployerNumber as parameter.
	12-04-2019	Jaap van Assenbergh		OTIBSUB-954		Alleen [Vergoed bedrag] 2019 tonen.
	06-04-2019	Jaap van Assenbergh		OTIBSUB-931		Boekstuknummer zoeken
	12-12-2018	Sander van Houten		OTIBSUB-576		Foutief uitbetaald bedrag in 
											OTIB declaratie overzicht.
	11-12-2018	Jaap van Assenbergh		OTIBSUB-557		Declaratieoverzicht kolom MN nummer toevoegen.
	30-11-2018	Jaap van Assenbergh		OTIBSUB-462		Toevoegen term EVC/EVC500 
											bij afhandelen declaraties.
	21-11-2018	Jaap van Assenbergh		OTIBSUB-419		Update declaration only when 
											startdate > Now AND status 0001.
	30-10-2018	Jaap van Assenbergh		OTIBSUB-385 Overzichten - filter op subsidieregeling
											Multiple subsidy schemes possible
											Userdefined Table Type.
	05-10-2018	Sander van Houten		OTIBSUB-306		Sortering voor bedragen aangepast.
	25-09-2018	Jaap van Assenbergh		Sortering toegevoegd.
	04-09-2018	Jaap van Assenbergh		Eerste foute versie.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	@SearchString	= ISNULL(@SearchString, '')

/*	Prepaire SearchString.													*/
SELECT	@SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

/*  Insert @SubsidySchemeID into a modifiable table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID

INSERT INTO @tblSubsidyScheme 
    (
        SubsidySchemeID
    ) 
SELECT  SubsidySchemeID 
FROM    @SubsidySchemeID
ORDER BY 
        SubsidySchemeID

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*	Select Declarations.													*/
SELECT 
		SubsidySchemeID,
		SubsidySchemeName,
		DeclarationID,
		EmployerNumber,
		EmployerName,
		DeclarationDate,
		CourseID,
		CourseName,
		DeclarationStatus,
		StartDate,
		DeclarationAmount,
		ApprovedAmount,
		CAST(CASE WHEN ModifyUntil IS NOT NULL OR DeclarationStatus = '0019' 
				THEN 1 
				ELSE 0 
			 END AS bit)	AS CanModify,
		ModifyUntil
FROM
(
		SELECT 
				SubsidySchemeID,
				SubsidySchemeName, 
				DeclarationID,
				EmployerNumber,
				EmployerName,
				DeclarationDate,
				CourseID,
				CourseName,
				DeclarationStatus,
				StartDate,
				DeclarationAmount,
				ApprovedAmount,
				CASE WHEN StartDate > CAST(GETDATE() AS date) AND DeclarationStatus = '0001' 
					THEN StartDate 
					ELSE NULL 
				END		AS ModifyUntil,
				CASE WHEN @SortDescending = 0 
					THEN CAST(SortBy AS varchar(max)) 
					ELSE NULL 
				END	AS SortByAsc,
				CASE WHEN @SortDescending = 1 
					THEN CAST(SortBy AS varchar(max)) 
					ELSE NULL 
				END	AS SortByDesc
		FROM
				(
					SELECT	DISTINCT Word,
							d.SubsidySchemeID,
							s.SubsidySchemeName + 
							CASE WHEN evcd.IsEVC500 = 1 OR evcwvd.IsEVC500 = 1
								THEN '-500' 
								ELSE ''
							END													AS SubsidySchemeName,
							d.DeclarationID,
							d.EmployerNumber,
							er.EmployerName,
							d.DeclarationDate,
							COALESCE(osrd.CourseID, stpd.EducationID)			AS CourseID,
							COALESCE(osrd.CourseName, stpd.EducationName)		AS CourseName,
							d.DeclarationStatus,
							ISNULL(stpd.DeclarationAmount, d.DeclarationAmount)	AS DeclarationAmount,
							ISNULL(dtp.TotalPaidAmount, 0.00)					AS ApprovedAmount,
							d.StartDate,
							CASE 
								WHEN @SortBy = 'DeclarationDate'	THEN CONVERT(varchar(max), d.DeclarationDate, 112)
								WHEN @SortBy = 'SubsidySchemeName'	THEN s.SubsidySchemeName 
								WHEN @SortBy = 'DeclarationID'		THEN CAST(d.DeclarationID AS varchar(6))
								WHEN @SortBy = 'EmployerNumber'		THEN d.EmployerNumber 
								WHEN @SortBy = 'EmployerName'		THEN er.EmployerName 
								WHEN @SortBy = 'CourseName'			THEN LTRIM(RTRIM(osrd.CourseName))
								WHEN @SortBy = 'DeclarationAmount'	THEN CAST(REPLICATE('0', 20 - LEN(d.DeclarationAmount)) + CAST(d.DeclarationAmount AS varchar(20)) AS varchar(max))
								WHEN @SortBy = 'ApprovedAmount'		THEN CAST(REPLICATE('0', 20 - LEN(d.ApprovedAmount)) + CAST(d.ApprovedAmount AS varchar(20)) AS varchar(max))
								WHEN @SortBy = 'StartDate'			THEN CONVERT(varchar(max), d.StartDate, 112)
								ELSE CAST(d.DeclarationID AS varchar(6))
							END													AS SortBy
					FROM	sub.tblDeclaration d
					INNER JOIN sub.tblDeclaration_Search decls ON decls.DeclarationID = d.DeclarationID
					INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
					INNER JOIN sub.tblEmployer er ON er.EmployerNumber = d.EmployerNumber
					LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
					LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = d.DeclarationID
					LEFT JOIN evcwv.viewDeclaration evcwvd ON evcwvd.DeclarationID = d.DeclarationID
					LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = d.DeclarationID
					LEFT JOIN sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
					CROSS JOIN @SearchWord sw
					WHERE	d.SubsidySchemeID IN 
							(
								SELECT	SubsidySchemeID 
								FROM	@tblSubsidyScheme
							)
					AND		d.EmployerNumber = COALESCE(@EmployerNumber, d.EmployerNumber)
					AND		'T' =	CASE	WHEN	@SearchString = '' THEN 'T'
											WHEN	CHARINDEX(sw.Word, decls.SearchField, 1) > 0 THEN	'T'
									END
					AND		'T' =	CASE	WHEN @SearchString = '' 
												THEN	CASE	WHEN d.declarationStatus <> '0035' 
															THEN 'T' 
														END
											ELSE 'T'
									END
				) Search
				GROUP BY	DeclarationID,
							EmployerNumber,
							EmployerName,
							SubsidySchemeID,
							SubsidySchemeName,
							DeclarationDate,
							CourseID,
							CourseName,
							DeclarationStatus,
							StartDate,
							DeclarationAmount,
							ApprovedAmount,
							SortBy
				HAVING COUNT(DeclarationID) >= (SELECT COUNT(1) FROM @SearchWord) 
		)  OrderBy
		ORDER BY	
                ROW_NUMBER() OVER (ORDER BY SortByAsc ASC, SortByDesc DESC)
		OFFSET ((@PageNumber - 1) * @RowspPage) ROWS
		FETCH NEXT @RowspPage ROWS ONLY;

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Declaration_List =========================================================	*/
