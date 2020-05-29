
CREATE PROCEDURE [sub].[uspWriteXMLFile]
AS
/*	==========================================================================================
	Purpose:	Get all executed PaymentRuns optionaly within a certain time period.

	10-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SET NOCOUNT ON

DECLARE @header NVARCHAR(MAX) = '<?xml version="1.0" encoding="utf-8"?>',
		@xml NVARCHAR(MAX) = '<master><slave>me</slave><slave>you</slave></master>',
		@output xml

SET @output = CAST( @xml AS xml )

SELECT @output

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspWriteXMLFile ===================================================================	*/
