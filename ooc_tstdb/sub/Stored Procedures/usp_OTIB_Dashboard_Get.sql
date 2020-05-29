CREATE PROCEDURE [sub].[usp_OTIB_Dashboard_Get]
@UserID	int
AS
/*	==========================================================================================
	Purpose:	Select different KPI's for the dashboard screen.

	14-01-2019	Sander van Houten		OTIBSUB-1827	Added KPI-17.
	10-12-2019	Jaap van Assenbergh		OTIBSUB-1552	Telling / lijst "Opleiding naar Etalage, 
											declaratie vanuit DS" controleren KPI* Stip toevoegen.
	26-08-2019	Sander van Houten		OTIBSUB-1263	Added KPI-13.
	02-07-2019	Sander van Houten		OTIBSUB-1305	Exclude status '0009' if subsidyscheme = 4
	23-05-2019	Sander van Houten		OTIBSUB-1072	Split up KPI's per subsidyscheme
											and add SubsidySchemeID to resultset. 
	13-05-2019	Sander van Houten		OTIBSUB-1073	Miscalculation of KpiID 3 <= instead of >=.. 
	13-05-2019	Sander van Houten		OTIBSUB-1071	Get KPI header text from database. 
	10-01-2019	Jaap van Assenbergh		OTIBSUB-819		Monitoring Opleiding naar Etalage.
	10-01-2019	Sander van Houten		OTIBSUB-640		Give back correct count of IBAN changes 
											to be checked.
	30-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/
DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE	@UserID	int = 4149
--*/

DECLARE @LastDayOfPreviousQuarter	date,
		@LastDayOfCurrentQuarter	date,
		@RC							int

/*	Determine quarter dates.	*/
SELECT 	@LastDayOfPreviousQuarter = DATEADD(dd, -1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()), 0)),
		@LastDayOfCurrentQuarter = DATEADD(dd, -1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) +1, 0))

/*	Fill temp table for user specific KPI's.	*/
DECLARE @tblIBANchanges TABLE 
	(
		IBANChangeID	int,
		EmployerName	varchar(100)
	)

INSERT INTO @tblIBANchanges (IBANChangeID, EmployerName)
EXECUTE @RC = [sub].[usp_OTIB_Employer_IBAN_Change_List] 
   @UserID

DECLARE @tblEMAILchanges TABLE 
	(
		EMAILChangeID	int,
		EmployerName	varchar(100)
	)

INSERT INTO @tblEMAILchanges (EMAILChangeID, EmployerName)
EXECUTE @RC = [auth].[usp_OTIB_User_Email_Change_List]
   @UserID

DECLARE @tblGracePeriodRequests TABLE 
	(
		GracePeriodID	int,
		EmployerName	varchar(100)
	)

INSERT INTO @tblGracePeriodRequests (GracePeriodID, EmployerName)
EXECUTE @RC = [sub].[usp_OTIB_Employer_Subsidy_GracePeriod_List]
   @UserID

/*	Select KPI-1 Number of declarations that need to be handled.	*/
SELECT	
		1																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0001'
		)
		 + ' ' + ssc.SubsidySchemeName										AS kpiDescription,
		COUNT(d.DeclarationID)												AS kpiCount,
		ssc.SubsidySchemeID
FROM	sub.tblSubsidyScheme ssc
LEFT JOIN sub.tblDeclaration d
		ON	d.SubsidySchemeID = ssc.SubsidySchemeID
LEFT JOIN sub.tblDeclaration_Partition dep
		ON	dep.DeclarationID = d.DeclarationID
		AND	dep.PartitionStatus IN ('0005', '0009')	--Afgekeurd door automatische controle + Goedgekeurd en nog niet uitbetaald.
LEFT JOIN sub.viewApplicationSetting_PartitionStatus asps 
		ON	asps.SettingCode = dep.PartitionStatus
WHERE	ssc.SubsidySchemeID <> 2
AND		ssc.ActiveFromDate <= GETDATE()
AND		(	-- OTIBSUB-1305
			asps.NotShownInProcessList = 0
		AND (	asps.SubsidySchemeID = d.SubsidySchemeID
			OR	asps.SubsidySchemeID IS NULL
			)
		)
GROUP BY 
		ssc.SubsidySchemeName,
		ssc.SubsidySchemeID

UNION ALL

/*	Select KPI-2 Number of declarations from last quarter 
	that need to be handled (before quarterly closing).		*/
SELECT	
		2																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0002'
		)
		 + ' ' + ssc.SubsidySchemeName										AS kpiDescription,
		COUNT(d.DeclarationID)												AS kpiCount,
		ssc.SubsidySchemeID
FROM	sub.tblSubsidyScheme ssc
LEFT JOIN sub.tblDeclaration d
		ON	ssc.SubsidySchemeID = d.SubsidySchemeID
		AND	d.DeclarationDate <= @LastDayOfPreviousQuarter
		AND	d.StartDate <= @LastDayOfCurrentQuarter
LEFT JOIN sub.tblDeclaration_Partition dep
		ON	dep.DeclarationID = d.DeclarationID
		AND	dep.PartitionStatus IN ('0005', '0009')	--Afgekeurd door automatische controle + Goedgekeurd en nog niet uitbetaald.
LEFT JOIN sub.viewApplicationSetting_PartitionStatus asps 
		ON	asps.SettingCode = dep.PartitionStatus
WHERE	ssc.SubsidySchemeID <> 2
AND		ssc.ActiveFromDate <= GETDATE()
AND		(	-- OTIBSUB-1305
			asps.NotShownInProcessList = 0
		AND (	asps.SubsidySchemeID = d.SubsidySchemeID
			OR	asps.SubsidySchemeID IS NULL)
			)
GROUP BY 
		ssc.SubsidySchemeName,
		ssc.SubsidySchemeID

UNION ALL

/*	Select KPI-3 Number of declarations that have been manually set to Investigation
	and/or a question has been send to the employer and where there has been no action for the last 7 days.		*/
SELECT	
		3																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0003'
		)																	AS kpiDescription,
		COUNT(1)															AS kpiCount,
		NULL																AS SubsidySchemeID
		
FROM	sub.tblDeclaration_Partition dep
WHERE	dep.PartitionStatus IN ('0006', '0008')	--Vraag gesteld / In onderzoek
AND		dep.DeclarationID IN 
		(
			SELECT	hist.KeyID
			FROM  	his.tblHistory hist
			WHERE	hist.TableName = 'sub.tblDeclaration'
			AND		hist.LogDate <= CAST(DATEADD(d, -7, GETDATE()) AS date)
		)

UNION ALL

/*	Select KPI-4 Number of IBAN changes that need to be approved.		*/
SELECT	
		4																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0004'
		)																	AS kpiDescription,
		COUNT(1)															AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	@tblIBANchanges ic

UNION ALL

/*	Select KPI-5 Number of new employer entries that need to be approved.		*/
SELECT	
		5																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0005'
		)																	AS kpiDescription,
		COUNT(1)															AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	sub.tblEmployer emp
LEFT JOIN	sub.tblEmployer_Subsidy ems
		ON	ems.EmployerNumber = emp.EmployerNumber
WHERE	ems.StartDate IS NULL

UNION ALL

/*	Select KPI-6 Number of schoolbudget merges that need to be approved.		*/
SELECT	DISTINCT
		6																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0006'
		)																	AS kpiDescription,
		0																	AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	sub.tblEmployer emp
INNER JOIN	sub.tblEmployer_Subsidy ems
		ON	ems.EmployerNumber = emp.EmployerNumber

UNION ALL

/*	Select KPI-7 Number of requests for extra employer accounts (concernrelations)		*/
SELECT	DISTINCT
		7																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0007'
		)																	AS kpiDescription,
		0																	AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	sub.tblUser_Role_Employer

UNION ALL

/*	Select KPI-8 Number courses from DS waiting for information from Etalage (dhrs.DeclarationID IS NULL)	*/
SELECT	
		8																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0008'
		)																	AS kpiDescription,
		SUM(CountPerSchema)													AS kpiCount,
		NULL																AS SubsidySchemeID
		FROM	(
					SELECT SUM(CASE WHEN dhrs.DeclarationID IS NULL THEN 1 ELSE 0 END) CountPerSchema
					FROM	sub.tblDeclaration decl
					LEFT JOIN	hrs.tblDeclaration_HorusNr_OTIBDSID dhrs 
							ON	dhrs.DeclarationID = decl.DeclarationID
					INNER JOIN	sub.tblDeclaration_Unknown_Source dus 
							ON	dus.DeclarationID = decl.DeclarationID
					WHERE	dus.CourseID IS NULL
					AND		dus.SentToSourceSystemDate IS NOT NULL
					AND		decl.DeclarationStatus NOT IN ('0001')
					AND		decl.SubsidySchemeID IN (1)
					UNION ALL
					SELECT SUM(CASE WHEN dhrs.DeclarationID IS NULL THEN 1 ELSE 0 END)
					FROM	sub.tblDeclaration decl
					LEFT JOIN	hrs.tblDeclaration_HorusNr_OTIBDSID dhrs 
							ON	dhrs.DeclarationID = decl.DeclarationID
					INNER JOIN	sub.tblDeclaration_Unknown_Source dus 
							ON	dus.DeclarationID = decl.DeclarationID
					WHERE	dus.InstituteID IS NULL
					AND		dus.SentToSourceSystemDate IS NOT NULL
					AND		decl.DeclarationStatus NOT IN ('0001')
					AND		decl.SubsidySchemeID = 4
				) PerSchema

UNION ALL

/*	Select KPI-9 Number courses from Horus waiting for information from Etalage	(dhrs.DeclarationID IS NOT NULL) */
SELECT	
		9																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0009'
		)																	AS kpiDescription,
		SUM(CASE WHEN dhrs.DeclarationID IS NOT NULL THEN 1 ELSE 0 END)		AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	sub.tblDeclaration decl
LEFT JOIN	hrs.tblDeclaration_HorusNr_OTIBDSID dhrs 
		ON	dhrs.DeclarationID = decl.DeclarationID
INNER JOIN	sub.tblDeclaration_Unknown_Source dus 
		ON	dus.DeclarationID = decl.DeclarationID
WHERE	dus.CourseID IS NULL
AND		dus.SentToSourceSystemDate IS NOT NULL
AND		decl.DeclarationStatus NOT IN ('0001')

UNION ALL

/*	Select KPI-10 Number courses with unknown source. Accept or reject manual by OTIB */
SELECT	
		10																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0010'
		)																	AS kpiDescription,
		SUM(CASE WHEN decl.DeclarationID IS NOT NULL THEN 1 ELSE 0 END)		AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	sub.tblDeclaration decl
INNER JOIN	sub.tblDeclaration_Unknown_Source dus 
		ON	dus.DeclarationID = decl.DeclarationID
WHERE	decl.DeclarationStatus IN ('0022')

UNION ALL

/*	Select KPI-11 Number STIP declarations in DS with overlap on BPV in Horus. 
	Manual action by OTIB.	*/
SELECT	
		11																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0011'
		)																	AS kpiDescription,
		SUM(CASE WHEN decl.DeclarationStatus IN ('0023') THEN 1 ELSE 0 END)	AS kpiCount,
		4																	AS SubsidySchemeID
FROM	sub.tblDeclaration decl

UNION ALL

/*	Select KPI-12 Number BPV declarations in Horus with overlap on STIP in DS. 
	Manual action by OTIB.	*/
SELECT	
		12																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0012'
		)																	AS kpiDescription,
		SUM(CASE WHEN decl.DeclarationStatus IN ('0025') THEN 1 ELSE 0 END)	AS kpiCount,
		4																	AS SubsidySchemeID
FROM	sub.tblDeclaration decl

UNION ALL

/*	Select KPI-13 Number STIP declarations where the nominal duration of the education is unknown. 
	Manual action by OTIB.	*/
SELECT	
		13																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0013'
		)																	AS kpiDescription,
		SUM(CASE WHEN decl.DeclarationStatus IN ('0027') THEN 1 ELSE 0 END)	AS kpiCount,
		4																	AS SubsidySchemeID
FROM	sub.tblDeclaration decl

UNION ALL

/*	Select KPI-16 Number of E-mail changes that need to be approved.		*/
SELECT	
		16																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0016'
		)																	AS kpiDescription,
		COUNT(1)															AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	@tblEMAILchanges ec

UNION ALL

/*	Select KPI-17 Number of GracePeriod requests that need to be handled.		*/
SELECT	
		17																	AS kpiID,
		(
			SELECT	DISTINCT 
					SettingValue 
			FROM	sub.viewApplicationSetting_OTIB_Dashboard_KPI_Header
			WHERE	SettingCode = '0017'
		)																	AS kpiDescription,
		COUNT(1)															AS kpiCount,
		NULL																AS SubsidySchemeID
FROM	@tblGracePeriodRequests gpr

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Dashboard_Get ============================================================	*/
