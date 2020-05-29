
CREATE PROCEDURE [sub].[uspDeclaration_List]
@SearchString		varchar(max),
@SubsidySchemeID 	sub.uttSubsidySchemeID READONLY,
@EmployerNumber		varchar(6),
@DeclarationStatus	varchar(4),
@RejectionReason	varchar(4),
@UserID				int
AS
/*	==========================================================================================
	Purpose:	List all data of searched for declaration.

	09-01-2020	Sander van Houten	    OTIBSUB-1819	Diploma can only be uploaded until 
                                            1 year after enddate of STIP.
	11-12-2019	Sander van Houten	    OTIBSUB-1764	Changed determining ModifyUntil for OSR/EVC.
	15-11-2019	Sander van Houten	    OTIBSUB-1714	Error message when @SearchString contains
                                            a space. Altered (SELECT COUNT(Word) FROM @SearchWord)
                                            into (SELECT COUNT(1) FROM @SearchWord).
	22-10-2019	Sander van Houten		OTIBSUB-1634	Improved check on ModifyUntil 
                                            for ended declarations.
	14-10-2019	Sander van Houten		OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	17-09-2019	Jaap van Assenbergh		OTIBSUB-1562	Performance probleem op usp_OTIB_Declaration_List
	03-09-2019	Sander van Houten		OTIBSUB-1520	Added RequiresDiplomaUpload and DiplomaUploadUntil.
	05-08-2019	Sander van Houten		OTIBSUB-1435	Temporarily do not show the declarationamount.
	16-07-2019	Jaap van Assenbergh		OTIBSUB-1373	Specificatie op declaratieniveau of 
											op verzamelnota.
	08-08-2019	Sander van Houten		OTIBSUB-1319	Changed ModifyUntil terms for STIP.
	18-06-2019	Sander van Houten		OTIBSUB-1147	Added STIP StartDate part.
	14-06-2019	Sander van Houten		OTIBSUB-1147	Added STIP EndDate part.
	13-06-2019	Sander van Houten		OTIBSUB-1197	Added search option on JournalEntryCode.
	28-05-2019	Sander van Houten		OTIBSUB-999		Added STIP parts.
	27-03-2019	Sander van Houten		OTIBSUB-884		Declarations were shown double.
	17-01-2019	Sander van Houten		OTIBSUB-678		Show CanDownloadSpecification 
											on bases of RoleID.
	30-11-2018	Jaap van Assenbergh		OTIBSUB-462		Toevoegen term EVC/EVC500 
											bij afhandelen declaraties.
	09-11-2018	Sander van Houten		OTIBSUB-426		Changed check for ModifyUntil.
	30-10-2018	Jaap van Assenbergh		OTIBSUB-385		Overzichten - filter op subsidieregeling
											Multiple subsidy schemes possible. 
											Userdefined Table Type
	10-10-2018	Sander van Houten		OTIBSUB-335		When CourseName is NULL then return 
											the CourseName entered by employer.
	27-08-2018	Sander van Houten		OTIBSUB-164		Added ModifyUntil.
	19-07-2018	Jaap van Assenbergh		Ophalen lijst uit sub.tblDeclaration om af te handelen.
	26-07-2018	Jaap van Assenbergh		Status wordt opgehaald in de front-end.

	Notes:
	26-07-2018	Jaap van Assenbergh
				Deze lijst wordt op twee verschillende manieren gebruikt.
				1.	Door een declarant. Dan is altijd een Employernummer bekend. Hierop zou 
					een index moeten liggen.
				2.	Door OTIB. Dan worden declaraties altijd op basis van status(sen) opgehaald. 
					Hierop zou een index moeten liggen.

				Door het gecombineerde gebruik wordt de volgende uitvraging gedaan:
				@EmployerNumber =	
							CASE
								WHEN		@EmployerNumber = ''
									THEN	@EmployerNumber
									ELSE	EmployerNumber
							END
							
				Ongeacht deze oplossing of ISNULL of een OR. Het probleem is overal hetzelfde.
								
				Hierdoor kan niet binair worden gezocht op een index.
				Optie is om de select eventueel te splitsen
				Een met 
				- EmployerNumber = @EmployerNumber
				- StatusID = StatusID
				Hierdoor kan dan de index gbinair worden benaderd.
				Voor als nog duurt deze selectie ongeveer 0,60 tot 0,150 sec op 75.000 records.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@SearchString		varchar(max) = '405392',
		@SubsidySchemeID	sub.uttSubsidySchemeID,
		@EmployerNumber		varchar(6) = '132530',
		@DeclarationStatus	varchar(4) = null,
		@RejectionReason	int = null,
		@userID				int = 51922

INSERT INTO @SubsidySchemeID (SubsidySchemeID) VALUES (1), (3), (4)
--*/

SELECT	@SearchString		= ISNULL(@SearchString, ''),
		@EmployerNumber		= ISNULL(@EmployerNumber, ''),		
		@DeclarationStatus	= ISNULL(@DeclarationStatus, ''),
		@RejectionReason	= ISNULL(@RejectionReason, '')

/*	Prepaire SearchString.	*/
SELECT @SearchString = sub.usfCreateSearchString (@SearchString)

DECLARE @SearchWord TABLE (Word nvarchar(max) NOT NULL)

INSERT INTO @SearchWord (Word)
SELECT s FROM sub.utfSplitString(@SearchString, ' ')

-- Determine Role(s) of current user.
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

/*  Make @SubsidySchemeID modifiable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID
INSERT INTO @tblSubsidyScheme 
    (
        SubsidySchemeID
    ) 
SELECT  SubsidySchemeID 
FROM    @SubsidySchemeID

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

/*	Select Declaration data.	*/
SELECT 
		sel.SubsidySchemeID,
		sel.SubsidySchemeName,
		sel.DeclarationID,
		sel.EmployerNumber,
		sel.DeclarationDate,
		sel.InstituteID,
		sel.CourseID,
		sel.CourseName,
		sel.DeclarationStatus,
		sel.[Location],
		sel.ElearningSubscription,
		sel.StartDate,
		sel.EndDate,
		CASE WHEN sel.SubsidySchemeID = 4
			THEN CASE WHEN @OTIB_User = 1
					THEN sel.DeclarationAmount
					ELSE 0.00
				 END
			ELSE sel.DeclarationAmount
		END									AS DeclarationAmount,
		sel.ApprovedAmount,
		sel.StatusReason,
		sel.InternalMemo,
		CAST( CASE WHEN sel.ModifyUntil IS NOT NULL OR sel.DeclarationStatus = '0019'
					THEN 1 
					ELSE 0 
			   END AS bit
			)								AS CanModify,
		sel.ModifyUntil,
		sel.CanDownloadSpecification,
		sel.DiplomaUploadUntil
FROM
		(
			SELECT 
					Search.SubsidySchemeID,
					Search.SubsidySchemeName,
					Search.DeclarationID,
					Search.EmployerNumber,
					Search.DeclarationDate,
					Search.InstituteID,
					Search.CourseID,
					Search.CourseName,
					Search.DeclarationStatus,
					Search.[Location],
					Search.ElearningSubscription,
					Search.StartDate,
					Search.EndDate,
					Search.DeclarationAmount,
					Search.ApprovedAmount,
					Search.StatusReason,
					Search.InternalMemo,
					Search.ModifyUntil,
					CAST(MAX(Search.CanDownloadSpecification) AS bit)	AS CanDownloadSpecification,
					Search.DiplomaUploadUntil
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
								d.DeclarationDate,
								d.InstituteID,
								COALESCE(osrd.CourseID, stpd.EducationID)			AS CourseID,
								COALESCE(osrd.CourseName, stpd.EducationName)		AS CourseName,
								d.DeclarationStatus,
								osrd.[Location],
								osrd.ElearningSubscription,
								ISNULL(stpd.StartDate, d.StartDate)					AS StartDate,
								ISNULL(stpd.EndDate, d.EndDate)						AS EndDate,
								ISNULL(stpd.DeclarationAmount, d.DeclarationAmount)	AS DeclarationAmount,
								d.ApprovedAmount,
								d.StatusReason,
								d.InternalMemo,
								CASE WHEN pad.PaymentRunID <= 
											(
												SELECT	SettingCode
												FROM	sub.tblApplicationSetting
												WHERE	SettingName = 'LastPaymentRunWithDeclarationSpecification'
											)
										THEN
											CASE WHEN dsp.Specification IS NULL -- Specification is created but not filled with specificationdata 
													THEN 0                      -- OTIBSUB-813 Horus specificaties niet downloaden/tonen
                                                 ELSE CASE WHEN @OTIB_User = 1
                                                            THEN 1
                                                           ELSE CASE WHEN d.DeclarationStatus IN ('0012', '0013', '0014', '0015', '0017') 
                                                                        THEN 1 
                                                                     ELSE 0 
                                                                END
                                                      END
											END
									  ELSE CASE WHEN pad.DeclarationID IS NOT NULL 
                                                    THEN 1
                                                ELSE 0
                                           END
								END																		AS CanDownloadSpecification,
                                CASE WHEN d.SubsidySchemeID = 4
                                        THEN CASE WHEN dbpv.DeclarationID IS NOT NULL
                                                    THEN CASE WHEN d.DeclarationStatus = '0019'	-- Terug naar werkgever.
                                                                THEN CASE WHEN DATEADD(MM, 6, d.StartDate) > CAST(GETDATE() AS date)
                                                                            THEN DATEADD(MM, 6, d.StartDate)
                                                                            ELSE CAST(GETDATE() AS date)
                                                                        END
                                                                ELSE NULL
                                                            END
                                                  ELSE CASE WHEN stpd.TerminationDate IS NOT NULL
                                                                THEN NULL
                                                            ELSE CASE WHEN stpd.LastExtensionID IS NULL 
                                                                        THEN CASE WHEN (SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                                                                        FROM	sub.tblDeclaration_partition dep
                                                                                        WHERE	dep.DeclarationID = d.DeclarationID
                                                                                        ) <= CAST(GETDATE() AS date)
                                                                                    THEN NULL
                                                                                    WHEN (SELECT	COUNT(1)
                                                                                        FROM	sub.tblDeclaration_partition dep
                                                                                        WHERE	dep.DeclarationID = d.DeclarationID
                                                                                        ) = 0
                                                                                    THEN CASE WHEN DATEADD(MM, 6, d.StartDate) > CAST(GETDATE() AS date)
                                                                                                THEN DATEADD(MM, 6, d.StartDate)
                                                                                                ELSE CAST(GETDATE() AS date)
                                                                                            END
                                                                                    ELSE (  SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                                                                            FROM	sub.tblDeclaration_partition dep
                                                                                            WHERE	dep.DeclarationID = d.DeclarationID
                                                                                            )
                                                                                END
                                                                      ELSE CASE WHEN (  SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                                                                        FROM	sub.tblDeclaration_Extension dex
                                                                                        INNER JOIN sub.tblDeclaration_Partition dep
                                                                                        ON		dep.DeclarationID = dex.DeclarationID
                                                                                        WHERE	dex.ExtensionID = stpd.LastExtensionID
                                                                                        AND		dep.PaymentDate >= dex.StartDate
                                                                                     ) <= CAST(GETDATE() AS date)
                                                                                    THEN NULL 
                                                                                ELSE (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                                                                        FROM	sub.tblDeclaration_Extension dex
                                                                                        INNER JOIN sub.tblDeclaration_Partition dep
                                                                                        ON		dep.DeclarationID = dex.DeclarationID
                                                                                        WHERE	dex.ExtensionID = stpd.LastExtensionID
                                                                                        AND		dep.PaymentDate >= dex.StartDate
                                                                                     )
                                                                           END
                                                                 END
                                                       END
                                             END
                                     ELSE CASE WHEN d.StartDate > CAST(GETDATE() AS date) AND d.DeclarationStatus = '0001' 
                                                THEN d.StartDate
                                               ELSE NULL 
                                          END
                                END													                    AS ModifyUntil,
                                CASE WHEN stpd.TerminationReason = '0006' AND dat.AttachmentID IS NULL	-- Beëindigd met diploma.
                                    THEN CASE WHEN DATEADD(MONTH, 6, stpd.TerminationDate) < DATEADD(YEAR, 1, d.EndDate) 
                                            THEN CASE WHEN DATEADD(MONTH, 6, stpd.TerminationDate) >= GETDATE() 
                                                    THEN DATEADD(MONTH, 6, stpd.TerminationDate)
                                                    ELSE NULL
                                                 END
                                            ELSE CASE WHEN DATEADD(YEAR, 1, d.EndDate) >= GETDATE() 
                                                    THEN DATEADD(YEAR, 1, d.EndDate)
                                                    ELSE NULL
                                                 END
                                         END
                                    ELSE NULL
                                END													                    AS DiplomaUploadUntil
						FROM	sub.tblDeclaration d
						INNER JOIN sub.tblDeclaration_Search decls 
								ON	decls.DeclarationID = d.DeclarationID
						INNER JOIN sub.tblSubsidyScheme s 
								ON	s.SubsidySchemeID = d.SubsidySchemeID
						LEFT JOIN osr.viewDeclaration osrd 
								ON	osrd.DeclarationID = d.DeclarationID
						LEFT JOIN evc.viewDeclaration evcd 
								ON	evcd.DeclarationID = d.DeclarationID
						LEFT JOIN evcwv.viewDeclaration evcwvd
								ON	evcwvd.DeclarationID = d.DeclarationID
						LEFT JOIN stip.viewDeclaration stpd 
								ON	stpd.DeclarationID = d.DeclarationID
						LEFT JOIN sub.tblDeclaration_Rejection dr
								ON	dr.DeclarationID = d.DeclarationID
						LEFT JOIN sub.tblDeclaration_Specification dsp 
								ON	dsp.DeclarationID = d.DeclarationID
						LEFT JOIN sub.tblPaymentRun_Declaration pad 
								ON	pad.DeclarationID = d.DeclarationID
						LEFT JOIN stip.tblDeclaration_BPV dbpv
								ON	dbpv.DeclarationID = d.DeclarationID
						LEFT JOIN sub.tblDeclaration_Attachment dat
								ON	dat.DeclarationID = d.DeclarationID
								AND dat.DocumentType = 'Certificate'
						CROSS JOIN @SearchWord sw
						WHERE	d.SubsidySchemeID IN 
								(
									SELECT	SubsidySchemeID 
									FROM	@tblSubsidyScheme
								)
						AND		@EmployerNumber = CASE WHEN	@EmployerNumber = ''
													THEN @EmployerNumber
													ELSE d.EmployerNumber
												  END
						AND		@DeclarationStatus = CASE WHEN @DeclarationStatus = ''
														THEN @DeclarationStatus
														ELSE d.DeclarationStatus
													 END
						AND		@RejectionReason =	CASE WHEN @RejectionReason = ''
														THEN @RejectionReason
														ELSE dr.RejectionReason
													END
						AND		'T' = CASE	WHEN	@SearchString = '' THEN 'T'
											WHEN	CHARINDEX(sw.Word, decls.SearchField, 1) > 0 THEN	'T'
										END

					) Search
					GROUP BY	
							Search.DeclarationID,
							Search.EmployerNumber,
							Search.SubsidySchemeID,
							Search.SubsidySchemeName,
							Search.DeclarationDate,
							Search.InstituteID,
							Search.CourseID,
							Search.CourseName,
							Search.DeclarationStatus,
							Search.[Location],
							Search.ElearningSubscription,
							Search.StartDate,
							Search.EndDate,
							Search.DeclarationAmount,
							Search.ApprovedAmount,
							Search.StatusReason,
							Search.InternalMemo,
							Search.ModifyUntil,
							Search.DiplomaUploadUntil
					HAVING	COUNT(Search.DeclarationID) >= (SELECT COUNT(1) FROM @SearchWord) 
				) sel
		ORDER BY	
				sel.DeclarationDate DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_List ================================================================	*/
