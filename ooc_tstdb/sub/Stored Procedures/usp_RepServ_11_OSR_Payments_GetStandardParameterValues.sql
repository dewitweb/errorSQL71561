CREATE PROCEDURE [sub].[usp_RepServ_11_OSR_Payments_GetStandardParameterValues]
AS
/*	==========================================================================================
	Purpose:	Get the standard parameter values for the OSR payments reports.

    Notes:      This procedure is used in: 11 OSR Benutting werkgevers.rdl

	06-12-2019	Sander van Houten	OTIBSUB-1636    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	DISTINCT 
        CAST(LEFT(ReferenceDate, 4) AS varchar(4))  AS SubsidyYear
FROM    sub.viewApplicationSetting_SubsidyAmountPerEmployer
WHERE   SettingCode = 'OSR'

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_08_STIP_Commitment_GetStandardParameterValues ========================	*/
