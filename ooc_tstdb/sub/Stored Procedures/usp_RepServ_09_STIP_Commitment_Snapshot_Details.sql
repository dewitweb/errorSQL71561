CREATE PROCEDURE [sub].[usp_RepServ_09_STIP_Commitment_Snapshot_Details]
@SnapshotID                 int = 0,
@Creation_DateTime_UserName varchar(128) = ''
AS
/*	==========================================================================================
	Purpose:	Details of a snapshot of the STIP financial commitments.

    Notes:      This procedure gets all data from a specific snapshot,
                taken of the commitments of declarations that were active on a specific date.


                This procedure is used in: 09 STIP Verplichtingen snapshot overzicht.rdl

	18-12-2019	Sander van Houten	OTIBSUB-17??    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @SnapshotID                 int = 0,
        @Creation_DateTime_UserName varchar(128) = '17-12-2019 16:11:06:757 (SQLSERVERKA\AmbitionIT)'
--  */

SELECT	PartitionYear,
        PartitionMonth,
        EmployerNumber,
        EmployeeNumber,
        DeclarationID,
        PaymentDate,
        AmountToBePaid,
        EducationLevel
FROM    sub.tblRepServ_08_Snapshot sn
INNER JOIN sub.tblRepServ_08_Snapshot_Details snd ON snd.SnapshotID = sn.SnapshotID
WHERE   sn.SnapshotID = @SnapshotID
OR      (
            sn.Creation_DateTime = CAST(SUBSTRING(@Creation_DateTime_UserName, 7, 4) 
                                      + SUBSTRING(@Creation_DateTime_UserName, 4, 2)
                                      + SUBSTRING(@Creation_DateTime_UserName, 1, 2)
                                      + SUBSTRING(@Creation_DateTime_UserName, 11, 13) AS datetime)
        AND sn.Creation_UserName = REPLACE(SUBSTRING(@Creation_DateTime_UserName, 26, 100), ')', '')
        )

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_09_STIP_Commitment_Snapshot_Details ===================================	*/
