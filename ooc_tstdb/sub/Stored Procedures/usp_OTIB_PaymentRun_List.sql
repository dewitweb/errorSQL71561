CREATE PROCEDURE [sub].[usp_OTIB_PaymentRun_List]
@SubsidySchemeID 	sub.uttSubsidySchemeID READONLY
AS
/*	==========================================================================================
	Purpose:	Create an overview of all executed paymentruns.

	Note:		Used in Betalingsrunhistorie.

	07-02-2020	Sander van Houten		OTIBSUB-1890	Excluded rejected payments from TotalAmount.
	16-10-2019	Sander van Houten		OTIBSUB-1626	Added parameter @SubsidySchemeID
                                            for filtering on subsidy schemes.
	21-02-2019	Jaap van Assenebrgh		OTIBSUB-803     Punt 4
	09-01-2019	Sander van Houten		OTIBSUB-230     Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @SubsidySchemeID 	sub.uttSubsidySchemeID 
INSERT INTO @SubsidySchemeID (SubsidySchemeID) VALUES (1)
--  */

/*  Insert @SubsidySchemeID into a modifiable table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID

INSERT INTO @tblSubsidyScheme 
    (
        SubsidySchemeID
    ) 
SELECT  SubsidySchemeID 
FROM    @SubsidySchemeID
ORDER BY 
        SubsidySchemeID

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END

SELECT	sub1.PaymentRunID,
		sub1.Fullname,
		sub1.RunDate,
		sub1.EndDate, 
		sub1.SubsidySchemeName,
		COUNT(DISTINCT sub1.declarationID)  AS DeclarationCount,
        SUM(sub1.TotalAmount)               AS TotalAmount
FROM (
        SELECT	par.PaymentRunID,
                usr.Fullname,
                par.RunDate,
                par.EndDate, 
                ssc.SubsidySchemeName,
                pad.declarationID,
                CAST(CASE WHEN ISNULL(dep.PartitionStatus, '0017') = '0017'
                        THEN 0.00
                        ELSE ISNULL(pad.PartitionAmount, 0.00) + ISNULL(pad.VoucherAmount, 0.00)
                     END    AS decimal(19,2))   AS TotalAmount
        FROM	sub.tblPaymentRun par
        INNER JOIN auth.tblUser usr ON usr.UserID = par.UserID
        INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = par.SubsidySchemeID
        LEFT JOIN sub.tblPaymentRun_Declaration pad ON pad.PaymentRunID = par.PaymentRunID
        LEFT JOIN sub.tblDeclaration_Partition dep ON dep.PartitionID = pad.PartitionID
        WHERE	par.SubsidySchemeID IN 
                                    (
                                        SELECT	SubsidySchemeID 
                                        FROM	@tblSubsidyScheme
                                    )
     ) sub1
GROUP BY
		sub1.PaymentRunID,
		sub1.Fullname,
		sub1.RunDate,
		sub1.EndDate,
		sub1.SubsidySchemeName
ORDER BY
		sub1.PaymentRunID DESC,
		sub1.Fullname,
		sub1.RunDate,
		sub1.SubsidySchemeName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_PaymentRun_List ==========================================================	*/
