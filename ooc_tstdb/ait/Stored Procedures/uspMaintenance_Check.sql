

CREATE PROCEDURE [ait].[uspMaintenance_Check]
AS
/*	==========================================================================================
	Purpose: 	Check if there is maintenance planned in the future.

	08-05-2019	Sander van Houten	OTIBSUB-964		Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @ResultOfCheck			bit = 0,
		@FirstMaintenanceDate	datetime,
		@Duration				smallint

SELECT	TOP 1
		@ResultOfCheck = 1,
		@FirstMaintenanceDate = StartDate,
		@Duration = Duration
FROM	ait.tblMaintenance
WHERE	DATEADD(ss, Duration, StartDate) >= GETDATE()
ORDER BY StartDate

SELECT	@ResultOfCheck			AS MaintenancePlanned,
		@FirstMaintenanceDate	AS FirstMaintenanceDate,
		@Duration				AS Duration

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== ait.uspMaintenance_Check ==============================================================	*/
