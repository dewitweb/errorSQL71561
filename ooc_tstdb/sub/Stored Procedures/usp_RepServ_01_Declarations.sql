CREATE PROCEDURE [sub].[usp_RepServ_01_Declarations]
@SubsidyScheme      int,
@DeclarationStatus  varchar(24),
@StartDate          date,
@EndDate            date,
@SearchString       varchar(max)
AS

/*	Source for declaration list in SSRS.

	Parameters:
	@SubsidyScheme: subsidiy scheme (1, 2, 3); source sub.usp_RepServ_01_ParameterList_SubsidyScheme
	@DeclarationStatus: status code (0001 etc.); source sub.usp_RepServ_01_ParameterList_DeclarationStatus
	@StartDate: date
	@EndDate: datue
	@SearchString: free text, like an MN number

	15-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	11-06-2019	Sander van Houten	OTIBSUB-1107	Added EmployerNumber as parameter
										in call to sub.usp_OTIB_Declaration_List.
	15-03-2019, H. Melissen			Initial version (no Jira ticket yet)
*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @SubsidyScheme      int = 0, 
        @DeclarationStatus  varchar(24) = '0000', 
        @StartDate          date = DATEADD(m, -3, GETDATE()), 
        @EndDate            date = GETDATE(), 
        @SearchString       varchar(max) = 'lo'
 */

/*	Variables. */
DECLARE @SubsidySchemeID    [sub].[uttSubsidySchemeID], 
        @SortBy             varchar(50) = 'DeclarationID', 
        @SortDescending     bit = 0, 
        @PageNumber         int = 1, 
        @RowspPage          int = 100000

DECLARE @TotalDeclarations      varchar(100), 
        @TotalDeclarationAmount varchar(100), 
        @TotalApprovedAmount    varchar(100), 
        @EmployerNumber         varchar(6) = NULL

/*	Set the search string. */
SET @SearchString = LTRIM(RTRIM(ISNULL(@SearchString, '')))

/*	Select the subsidy scheme(s). */
IF (@SubsidyScheme = 0)	--All
BEGIN
	INSERT INTO @SubsidySchemeID 
        (
            SubsidySchemeID
        )
    SELECT  SubsidySchemeID
    FROM    sub.tblSubsidyScheme
    WHERE   SubsidySchemeID <> 2    --BPV
END
ELSE					--A single selected subsidy scheme
BEGIN
	INSERT INTO @SubsidySchemeID VALUES(@SubsidyScheme)

    /*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
    IF @SubsidyScheme = 3
    BEGIN
        INSERT INTO @SubsidySchemeID (SubsidySchemeID) VALUES (5)
    END
END

/*	Get the declarations.
	Used parameters:
	- subsidy scheme(s),
	- search string. */
DECLARE @Declarations TABLE (SubsidySchemeID int, SubsidySchemeName varchar(50), DeclarationID int, EmployerNumber varchar(6), EmployerName varchar(100),
							 DeclarationDate datetime, CourseID int, CourseName varchar(200), DeclarationStatus varchar(24), StartDate date,
							 DeclarationAmount decimal (19, 4), ApprovedAmount decimal (19, 4), CanModify bit, ModifyUntil datetime,
							 SelectedForReport bit, DeclarationStatusText varchar(100), TotalPaidAmount decimal (19, 4))
INSERT INTO @Declarations (SubsidySchemeID, SubsidySchemeName, DeclarationID, EmployerNumber, EmployerName,
						   DeclarationDate, CourseID, CourseName, DeclarationStatus, StartDate,
						   DeclarationAmount, ApprovedAmount, CanModify, ModifyUntil)
EXEC [sub].[usp_OTIB_Declaration_List] @SubsidySchemeID, @EmployerNumber, @SearchString, @SortBy, @SortDescending, @PageNumber, @RowspPage

/*	Update 'selected for report'. */
UPDATE  @Declarations
SET     SelectedForReport = 1
WHERE   DeclarationStatus = CASE WHEN @DeclarationStatus = '0000' 
                                THEN DeclarationStatus
                                ELSE @DeclarationStatus 
                            END
  AND   DeclarationDate BETWEEN @StartDate AND @EndDate

/*	Update the declaration status text. */
UPDATE  @Declarations
SET     DeclarationStatusText = SettingValue
FROM    sub.tblApplicationSetting
WHERE   SelectedForReport = 1
  AND   DeclarationStatus = SettingCode 

/*	Update the total paid amount. */
;WITH Payments AS
	(SELECT	d.TotalPaidAmount,
			Paid.TotalPaidAmount AS CalculatedTotalPaidAmount
	FROM @Declarations d
	OUTER APPLY (SELECT TotalPaidAmount
				 FROM   sub.viewDeclaration_TotalPaidAmount v
				 WHERE  d.DeclarationID = v.DeclarationID) Paid
	WHERE SelectedForReport = 1
	)
UPDATE  Payments
SET     TotalPaidAmount = CalculatedTotalPaidAmount

/*	Calculate the totals. */
SELECT	@TotalDeclarations = 'Totaal ' + CAST(COUNT(SubsidySchemeID) AS varchar(7))
							+ ', OSR ' + CAST(SUM(CASE WHEN SubsidySchemeID = 1 THEN 1 ELSE 0 END) AS varchar(7))
							+ ', EVC ' + CAST(SUM(CASE WHEN SubsidySchemeID = 3 THEN 1 ELSE 0 END) AS varchar(7)),
		@TotalDeclarationAmount = 'Totaal € ' + FORMAT(SUM(DeclarationAmount), 'N', 'nl-NL')
							+ ', OSR € ' + FORMAT(SUM(CASE WHEN SubsidySchemeID = 1 THEN DeclarationAmount ELSE 0 END), 'N', 'nl-NL')
							+ ', EVC € ' + FORMAT(SUM(CASE WHEN SubsidySchemeID = 3 THEN DeclarationAmount ELSE 0 END), 'N', 'nl-NL'),
		@TotalApprovedAmount = 'Totaal € ' + FORMAT(SUM(ApprovedAmount), 'N', 'nl-NL')
							+ ', OSR € ' + FORMAT(SUM(CASE WHEN SubsidySchemeID = 1 THEN ApprovedAmount ELSE 0 END), 'N', 'nl-NL')
							+ ', EVC € ' + FORMAT(SUM(CASE WHEN SubsidySchemeID = 3 THEN ApprovedAmount ELSE 0 END), 'N', 'nl-NL')
FROM    @Declarations
WHERE   SelectedForReport = 1

/*	Create the return set.
	Used parameters:
	- declaration status,
	- start date
	- end date. */
SELECT	SubsidySchemeID                                                         AS SubsidySchemeID,
		SubsidySchemeName + ' ' + CAST(DeclarationID AS varchar(10))            AS DeclarationNumber,
		CAST(DeclarationDate AS date)                                           AS DeclarationDate,
		EmployerName + ' (' + ISNULL(EmployerNumber, 'geen MN-nummer') + ')'    AS Employer,
		CourseName                                                              AS CourseName,
		DeclarationAmount                                                       AS DeclarationAmount,
		ApprovedAmount                                                          AS ApprovedAmount,
		TotalPaidAmount                                                         AS TotalPaidAmount,
		DeclarationStatusText                                                   AS DeclarationStatusText,
		@TotalDeclarations                                                      AS TotalDeclarations,
		@TotalDeclarationAmount                                                 AS TotalDeclarationAmount,
		@TotalApprovedAmount                                                    AS TotalApprovedAmount,
		DATEPART(ww, DeclarationDate)                                           AS WeekNumber
FROM    @Declarations
WHERE   SelectedForReport = 1
ORDER BY 
        SubsidySchemeID, 
        DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== usp_RepServ_01_Declarations ===========++==============================================	*/
