

CREATE PROCEDURE [sub].[uspSubsidyScheme_List]
AS
/*	==========================================================================================
	18-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblSubsidyScheme
				- Indicators IsActive and IsVisible. 
				- When Active then Always Visible
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	DECLARE @GetDate date = GETDATE()

	SELECT
			SubsidySchemeID,
			SubsidySchemeName,
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
						CASE 
							WHEN VisibleFromDate IS NULL
							THEN
								CASE 
									WHEN ActiveFromDate <= @GetDate
									THEN 1
								ELSE 0
								END
							ELSE CASE WHEN VisibleFromDate <= @GetDate
								THEN 1 
								ELSE 0 
							END 
						END 
						AS bit
					)
			IsVisible 

	FROM	sub.tblSubsidyScheme
	ORDER BY SortOrder

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspSubsidyScheme_List ==============================================================	*/
