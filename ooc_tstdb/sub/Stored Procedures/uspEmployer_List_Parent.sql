CREATE PROCEDURE [sub].[uspEmployer_List_Parent]
@EmployerNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose: 	List parent companies for an employernumber.

	30-09-2019	Sander van Houten		OTIBSUB-100		Added the active requests, 
											RequestID and RecordID.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	TestData.
DECLARE	@EmployerNumber varchar(6) = '000007'
--	*/

SELECT	sub1.*
FROM (
		SELECT	0													AS RequestID,
				emp.EmployerNumber,
				emp.EmployerName + ' (' + emp.EmployerNumber + ')'	AS EmployerName,
				epa.StartDate,
				epa.EndDate,
				epa.RecordID,
				CAST(0 AS bit)										AS CanModify,
				aps.SettingValue									AS StatusDescription
		FROM	sub.tblEmployer_ParentChild epa
		INNER JOIN sub.tblEmployer emp 
		ON		emp.EmployerNumber = epa.EmployerNumberParent
		INNER JOIN sub.tblApplicationSetting aps 
		ON		aps.SettingName = 'RequestStatus' 
		AND		aps.SettingCode = '0003'	-- Approved by OTIB / Definite
		WHERE	epa.EmployerNumberChild = @EmployerNumber

		UNION ALL 

		SELECT	epa.RequestID,
				epa.EmployerNumberChild								AS EmployerNumber,
				CASE WHEN emp.EmployerNumber IS NULL 
					THEN epa.EmployerNameParent + ' (' + epa.EmployerNumberParent + ')'	
					ELSE emp.EmployerName + ' (' + emp.EmployerNumber + ')'	
				END													AS EmployerName,
				epa.StartDate,
				epa.EndDate,
				0													AS RecordID,
				CASE epa.RequestStatus
					WHEN '0002' THEN CAST(0 AS bit)
					ELSE CAST(1 AS bit)
				END													AS CanModify,
				aps.SettingValue									AS StatusDescription
		FROM	sub.tblEmployer_ParentChild_Request epa
		INNER JOIN sub.tblApplicationSetting aps 
		ON		aps.SettingName = 'RequestStatus' 
		AND		aps.SettingCode = epa.RequestStatus
		LEFT JOIN sub.tblEmployer emp 
		ON		emp.EmployerNumber = epa.EmployerNumberParent
		WHERE	epa.EmployerNumberChild = @EmployerNumber
		AND		epa.RequestStatus NOT IN ('0003')	-- Approved by OTIB / Definite
	) sub1
ORDER BY 
		sub1.EmployerName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_List_Parent ===========================================================	*/
