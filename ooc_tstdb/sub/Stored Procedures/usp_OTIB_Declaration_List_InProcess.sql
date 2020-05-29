CREATE PROCEDURE [sub].[usp_OTIB_Declaration_List_InProcess]
@SubsidySchemeID 	int,
@Employernumber		varchar(6)
AS
/*	==========================================================================================
	Purpose:	Select all declarations that are being handled specific for the dashboard.

	22-01-2020	Sander van Houten	OTIBSUB-1842	Added check on STIP status 0009.
                                        An e-mail reply must be given by the employer.
	12-12-2019	Sander van Houten	OTIBSUB-1760	Made an exeption for partitionstatus Ended (0024).
                                        This now results in Check Diploma status (0031) if
                                        the declarationstatus is 0031.
	27-11-2019	Sander van Houten	OTIBSUB-1730	Use a dummy partition if the declaration
                                        is an extension for an Opscholing BPV and the status
                                        is Controle op lopende BPV (0023).
	14-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	07-10-2019	Sander van Houten	OTIBSUB-1608	Employers with a paymentarrear do not
										need to be handled.
	26-08-2019	Sander van Houten	OTIBSUB-1263	Partitions are no longer mandatory.
	31-07-2019	Jaap van Assenbergh	OTIBSUB-1424	STIP declaraties goedkeuren/afkeuren niet mogelijk
	02-07-2019	Sander van Houten	OTIBSUB-1175	Added KpiID.
	02-07-2019	Sander van Houten	OTIBSUB-1305	Exclude status '0009' if subsidyscheme = 4
	14-06-2019	Sander van Houten	OTIBSUB-1147	Added STIP EndDate part.
	11-06-2019	Sander van Houten	OTIBSUB-1175	Added DeclarationStatusGroup.SettingCode 
										to resultset.
	03-06-2019	Sander van Houten	OTIBSUB-1134	Show STIP declarations.
	28-05-2019	Jaap van Assenbergh	OTIBSUB-1101	Reactie werkgever bij declaratie duidelijker 
										aangeven. IncomingEmail en IsRead toegevoegd.
	01-05-2019	Jaap van Assenbergh	OTIBSUB-1018	Aantallen bij Declaraties afhandelen 
										worden onjuist weergegeven
	13-12-2018	Sander van Houten	OTIBSUB-576		Foutief uitbetaald bedrag in 
										OTIB declaratie overzicht.
	30-11-2018	Jaap van Assenbergh	OTIBSUB-462		Toevoegen term EVC/EVC500 bij 
										afhandelen declaraties.
	30-10-2018	Jaap van Assenbergh	OTIBSUB-385		Overzichten - filter op subsidieregeling.
	24-09-2018	Jaap van Assenbergh	OTIBSUB-235		Declaraties die automatisch worden 
										afgekeurd hoeft OTIB niet altijd te zien.
	24-09-2018	Jaap van Assenbergh	OTIBSUB-272		Scherm "declaraties afhandelen" 
										groepering flexibeler maken.
	20-08-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@SubsidySchemeID	int = 4,
		@Employernumber		varchar(6) = NULL
--*/

/*  Insert @SubsidySchemeID into a table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID
INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

--	Select declarations
;WITH cteDeclarations AS 
(
	SELECT	
			d.SubsidySchemeID,
			s.SubsidySchemeName + 
			CASE WHEN evcd.IsEVC500 = 1 OR evcwvd.IsEVC500 = 1
				THEN '-500' 
				ELSE ''
			END                                             AS SubsidySchemeName,
			d.DeclarationID,
			CAST(d.DeclarationID AS varchar(6))				AS DeclarationNumber,
			d.EmployerNumber,
			d.DeclarationDate,
			d.InstituteID,
			COALESCE(osrd.CourseID, stpd.EducationID)		AS CourseID,
			COALESCE(osrd.CourseName, stpd.EducationName)	AS CourseName,
			CASE dep.PartitionStatus 
                WHEN '0024' THEN '0031'
                ELSE dep.PartitionStatus
            END                                             AS DeclarationStatus,
			osrd.[Location],
			osrd.ElearningSubscription,
			d.StartDate,
			(	
                SELECT	MAX(ISNULL(t2.EndDate, t1.EndDate))
				FROM	sub.tblDeclaration t1
				LEFT JOIN sub.tblDeclaration_Extension t2 ON t2.DeclarationID = t1.DeclarationID
				WHERE	t1.DeclarationID = d.DeclarationID
				GROUP BY 
						t1.DeclarationID
			)	AS EndDate,
			d.DeclarationAmount,
			ISNULL(dtp.TotalPaidAmount, 0.00)				AS ApprovedAmount,
			d.StatusReason,
			d.InternalMemo
	FROM	sub.tblDeclaration d
	INNER JOIN sub.tblDeclaration_Partition dep 
	ON	    dep.DeclarationID = d.DeclarationID
	INNER JOIN sub.tblSubsidyScheme s 
	ON	    s.SubsidySchemeID = d.SubsidySchemeID
	LEFT JOIN osr.viewDeclaration osrd 
	ON	    osrd.DeclarationID = d.DeclarationID
	LEFT JOIN evc.viewDeclaration evcd 
	ON	    evcd.DeclarationID = d.DeclarationID
	LEFT JOIN evcwv.viewDeclaration evcwvd 
	ON	    evcwvd.DeclarationID = d.DeclarationID
	LEFT JOIN stip.viewDeclaration stpd 
	ON	    stpd.DeclarationID = d.DeclarationID
	LEFT JOIN sub.viewDeclaration_TotalPaidAmount dtp 
	ON	    dtp.DeclarationID = d.DeclarationID
	LEFT JOIN sub.viewApplicationSetting_PartitionStatus asps 
	ON	    asps.SettingCode = dep.PartitionStatus
	LEFT JOIN sub.tblDeclaration_Rejection rej 
	ON	    rej.DeclarationID = d.DeclarationID AND rej.RejectionReason = '0004'
    LEFT JOIN stip.tblEmail_Partition epa
    ON      epa.PartitionID = dep.PartitionID
    AND     epa.ReplyCode = '0000'
	WHERE	d.SubsidySchemeID IN 
								(
									SELECT	SubsidySchemeID 
									FROM	@tblSubsidyScheme
								)
	AND		(
				@Employernumber IS NULL 
			OR	d.EmployerNumber = @Employernumber
			)
	AND		(
                (	-- OTIBSUB-1305
				    asps.NotShownInProcessList = 0
                AND (asps.SubsidySchemeID = d.SubsidySchemeID
                OR	 asps.SubsidySchemeID IS NULL)
                )
            OR  d.DeclarationStatus = '0031'
            )
	AND		rej.DeclarationID IS NULL
    AND     (   stpd.DeclarationStatus IS NULL
            OR  (   stpd.DeclarationStatus IS NOT NULL
            AND     dep.PartitionStatus <> '0009'
                )
            OR  (   stpd.DeclarationStatus IS NOT NULL
            AND     dep.PartitionStatus = '0009'
            AND     epa.EmailID IS NOT NULL
                )
            )
            
    UNION ALL

    /*  This part is only for STIP declarations without a partition
        as a result of being a extension for an Opscholing BPV.   */
	SELECT	
			d.SubsidySchemeID,
			s.SubsidySchemeName,
			d.DeclarationID,
			CAST(d.DeclarationID AS varchar(6))				AS DeclarationNumber,
			d.EmployerNumber,
			d.DeclarationDate,
			d.InstituteID,
			stpd.EducationID		                        AS CourseID,
			stpd.EducationName	                            AS CourseName,
			'0023'								            AS DeclarationStatus,
			NULL,
			NULL,
			d.StartDate,
			(	
                SELECT	MAX(ISNULL(t2.EndDate, t1.EndDate))
				FROM	sub.tblDeclaration t1
				LEFT JOIN sub.tblDeclaration_Extension t2 ON t2.DeclarationID = t1.DeclarationID
				WHERE	t1.DeclarationID = d.DeclarationID
				GROUP BY 
						t1.DeclarationID
			)	AS EndDate,
			d.DeclarationAmount,
			ISNULL(dtp.TotalPaidAmount, 0.00)				AS ApprovedAmount,
			d.StatusReason,
			d.InternalMemo
	FROM	sub.tblDeclaration d
	LEFT JOIN sub.tblDeclaration_Partition dep
    ON	    dep.DeclarationID = d.DeclarationID
	INNER JOIN sub.tblSubsidyScheme s 
	ON	    s.SubsidySchemeID = d.SubsidySchemeID
	INNER JOIN stip.viewDeclaration stpd 
	ON	    stpd.DeclarationID = d.DeclarationID
	LEFT JOIN sub.viewDeclaration_TotalPaidAmount dtp 
	ON	    dtp.DeclarationID = d.DeclarationID
	LEFT JOIN sub.viewApplicationSetting_PartitionStatus asps 
	ON	    asps.SettingCode = '0023'
	WHERE	d.SubsidySchemeID = 4
    AND     d.SubsidySchemeID IN 
								(
									SELECT	SubsidySchemeID 
									FROM	@tblSubsidyScheme
								)
    AND     d.DeclarationStatus = '0023'
	AND		(
				@Employernumber IS NULL 
			OR	d.EmployerNumber = @Employernumber
			)
    AND     dep.PartitionID IS NULL
	AND		(
                (	-- OTIBSUB-1305
				    asps.NotShownInProcessList = 0
                AND (asps.SubsidySchemeID = d.SubsidySchemeID
                OR	 asps.SubsidySchemeID IS NULL)
                )
            OR  d.DeclarationStatus = '0031'
            )
),
cteEmail AS
(
	SELECT	DISTINCT 
			DeclarationID, 
			maxEmailID, 
			CAST(CASE WHEN deu.EmailID IS NULL 
					THEN 0 
					ELSE 1 
				 END AS bit
				)	AS IsRead
	FROM
			(
				SELECT	de.DeclarationID, 
						MAX(de.EmailID)	AS maxEmailID
				FROM	sub.tblDeclaration_Email de 
				WHERE	de.Direction = 'in'
				AND		de.DeclarationID NOT IN
						(
							SELECT	ode.DeclarationID
							FROM	sub.tblDeclaration_Email ode
							WHERE	ode.Direction = 'OUT'
							AND		ode.EmailID > de.emailID
						)
				GROUP BY 
						de.DeclarationID
			) m
	LEFT JOIN sub.tblDeclaration_Email_User deu ON deu.EmailID = m.maxEmailID
)

SELECT 
		cd.SubsidySchemeID,
		cd.SubsidySchemeName,
		cd.DeclarationID,
		cd.DeclarationNumber,
		cd.EmployerNumber,
		cd.DeclarationDate,
		cd.InstituteID,
		cd.CourseID,
		cd.CourseName,
		cd.DeclarationStatus,
		cd.[Location],
		cd.ElearningSubscription,
		cd.StartDate,
		cd.EndDate,
		cd.DeclarationAmount,
		cd.ApprovedAmount,
		cd.StatusReason,
		cd.InternalMemo,
		CAST(CASE WHEN e.maxEmailID IS NULL THEN 0 ELSE 1 END AS bit)	AS IncomingEmail,
		CAST(ISNULL(e.IsRead, 0) AS bit)								AS IsRead,
		dsg.SettingCode,
		dsg.SettingValue,
		dsg.SortOrder,
		MAX(CAST(kpi.SettingCode AS int))								AS KpiID
FROM	cteDeclarations cd
INNER JOIN sub.viewApplicationSetting_DeclarationStatusGroup dsg
ON	    dsg.DeclarationStatus = cd.DeclarationStatus
LEFT JOIN sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header kpi
ON	    kpi.SettingCode_DeclarationStatusGroup = dsg.SettingCode
LEFT JOIN cteEmail e 
ON	    e.DeclarationID = cd.DeclarationID
GROUP BY 
		cd.SubsidySchemeID,
		cd.SubsidySchemeName,
		cd.DeclarationID,
		cd.DeclarationNumber,
		cd.EmployerNumber,
		cd.DeclarationDate,
		cd.InstituteID,
		cd.CourseID,
		cd.CourseName,
		cd.DeclarationStatus,
		cd.[Location],
		cd.ElearningSubscription,
		cd.StartDate,
		cd.EndDate,
		cd.DeclarationAmount,
		cd.ApprovedAmount,
		cd.StatusReason,
		cd.InternalMemo,
		CAST(CASE WHEN e.maxEmailID IS NULL THEN 0 ELSE 1 END AS bit),
		CAST(ISNULL(e.IsRead, 0) AS bit),
		dsg.SettingCode,
		dsg.SettingValue,
		dsg.SortOrder
ORDER BY 
		dsg.SortOrder,
		cd.DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID
/*	== sub.usp_OTIB_Declaration_List_InProcess ===============================================	*/
