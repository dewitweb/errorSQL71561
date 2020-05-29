
Create PROCEDURE [sub].[uspSubsidyScheme_SubsidyYear_List]
AS
/*	==========================================================================================
	14-06-2019	Jaap van Assenbergh
				Ophalen lijst uit sub.tblSubsidyScheme/SubsidyYear
				- Indicators IsActive and IsVisible. 
				- When Active then Always Visible
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	DECLARE @GetDate date = GETDATE()

	SELECT
			ss.SubsidySchemeID,
			ss.SubsidySchemeName,
			CASE 
				WHEN YEAR(apse.StartDate) = YEAR(apse.EndDate) 
					THEN CAST(YEAR(apse.StartDate) as char(4))
				ELSE CAST(YEAR(apse.StartDate) as char(4)) + '/' + CAST(YEAR(apse.EndDate) as char(4))
			END as SubsidyYear,
				CAST(
						CASE WHEN ActiveFromDate <= @GetDate
							THEN 1 
							ELSE 0 
						END 
						AS bit
					)
			IsActive,
			ActiveFromDate,
				CAST(
						CASE WHEN VisibleFromDate <= @GetDate 
							THEN 1 
							ELSE CASE WHEN ActiveFromDate <= @GetDate
								THEN 1 
								ELSE 0 
							END 
						END 
						AS bit
					)
			IsVisible 

	FROM	sub.tblSubsidyScheme ss
	INNER JOIN sub.tblApplicationSetting_Extended apse 
			ON	apse.SubsidySchemeID = ss.SubsidySchemeID
	INNER JOIN sub.tblApplicationSetting aps 
			ON	aps.ApplicationSettingID = apse.ApplicationSettingID 
			AND aps.SettingName = 'SubsidyAmountPerEmployer'
	ORDER BY ss.SortOrder

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspSubsidyScheme_List ==============================================================	*/
