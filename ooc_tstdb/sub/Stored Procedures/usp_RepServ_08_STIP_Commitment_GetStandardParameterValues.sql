CREATE  PROCEDURE [sub].[usp_RepServ_08_STIP_Commitment_GetStandardParameterValues]
AS
/*	==========================================================================================
	Purpose:	Get the standard parameter values for the STIP commitment reports.

    Notes:      This procedure is used in: 08 STIP Verplichtingen overzicht inclusief voorspelling.rdl

	14-11-2019	Sander van Houten	OTIBSUB-1690    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	CAST('20190801' AS date)    AS Startdate,
        -- CASE WHEN MONTH(GETDATE()) < 8
        --     THEN CAST(YEAR(GETDATE()) - 1 AS varchar(4)) + '0801'
        --     ELSE CAST(YEAR(GETDATE()) AS varchar(4)) + '0801'
        -- END                         AS StartDate,
        CAST('20991231' AS date)     AS EndDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_08_STIP_Commitment_GetStandardParameterValues ========================	*/
