CREATE PROCEDURE [sub].[usp_RepServ_09_STIP_Commitment_GetStandardParameterValues]
AS
/*	==========================================================================================
	Purpose:	Get the standard parameter values for the STIP commitment reports.

    Notes:      This procedure is used in: 09 STIP Verplichtingen snapshot overzicht.rdl

	18-12-2019	Sander van Houten	OTIBSUB-17??    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	CONVERT(varchar(10), Creation_DateTime, 105) + ' ' 
        + CONVERT(varchar(12), Creation_DateTime, 114) + ' ('
        + Creation_UserName + ')'   AS Creation_DateTime_UserName
FROM    sub.tblRepServ_08_Snapshot

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_09_STIP_Commitment_GetStandardParameterValues ========================	*/
