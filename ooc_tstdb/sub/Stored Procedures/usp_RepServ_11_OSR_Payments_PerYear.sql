CREATE PROCEDURE [sub].[usp_RepServ_11_OSR_Payments_PerYear] 
@SubsidyYear    varchar(4)
AS
/*	==========================================================================================
	Purpose:	Details of the payments done by OTIB for the OSR scheme in a specific year.


	06-12-2019	Sander van Houten	OTIBSUB-1636    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @SubsidyYear    varchar(4) = '2020'
--  */

;WITH cte_ParentChild 
AS
(
    SELECT  EmployerNumberParent    AS EmployerNumber,
            YEAR(StartDate)         AS StartYear,
            YEAR(EndDate)           AS EndYear,
            COUNT(1)                AS NumberOfChilds
    FROM    sub.tblEmployer_ParentChild
    --where EmployerNumberParent = '001243'
    GROUP BY 
            EmployerNumberParent,
            YEAR(StartDate),
            YEAR(EndDate)
)
SELECT  sub3.PartitionYear,
        sub3.EmployerNumber,
        sub3.EmployerName,
        sub3.VoucherCount,
        sub3.VoucherAmount,
        SUM(ISNULL(cte.NumberOfChilds, 0))  AS NumberOfChilds,
        CASE WHEN sub3.SumPartitionAmount = 0.00
            THEN 0.00
            ELSE CASE WHEN sub3.SumPartitionAmount < esu.SubsidyAmountPerEmployer + (SUM(ISNULL(cte.NumberOfChilds, 0)) * esu.SubsidyAmountPerEmployer)
                    THEN sub3.SumPartitionAmount
                    ELSE esu.SubsidyAmountPerEmployer + (SUM(ISNULL(cte.NumberOfChilds, 0)) * esu.SubsidyAmountPerEmployer)
                END
        END                                 AS CompanyRightTotalAmount,
        CASE WHEN sub3.SumPartitionAmount = 0.00
            THEN 0.00
            ELSE CASE WHEN sub3.SumPartitionAmount < esu.SubsidyAmountPerEmployer + (SUM(ISNULL(cte.NumberOfChilds, 0)) * esu.SubsidyAmountPerEmployer)
                    THEN 0.00
                    ELSE sub3.SumPartitionAmount - (esu.SubsidyAmountPerEmployer + (SUM(ISNULL(cte.NumberOfChilds, 0)) * esu.SubsidyAmountPerEmployer))
                END
        END                                 AS IndividualRightTotalAmount,
        sub3.SumPartitionAmount,
        sub3.EmployeeCount
FROM (
        SELECT  sub2.PartitionYear,
                sub2.EmployerNumber,
                emp.EmployerName,
                SUM(sub2.VoucherCount)      AS VoucherCount,
                SUM(sub2.VoucherAmount)     AS VoucherAmount,
                SUM(sub2.PartitionAmount)   AS SumPartitionAmount,
                SUM(sub2.VoucherAmount) + SUM(sub2.PartitionAmount)
                                            AS TotalAmountPaid,
                SUM(sub2.EmployeeCount)     AS EmployeeCount
        FROM (
                SELECT	sub1.PartitionYear,
                        sub1.EmployerNumber,
                        sub1.PartitionAmount,
                        sub1.VoucherAmount,
                        sub1.PartitionID,
                        sub1.DeclarationID,
                        sub1.EmployeeCount,
                        SUM(sub1.WithVoucher)   AS VoucherCount
                FROM (
                        SELECT	dep.PartitionYear,
                                CASE WHEN epa.EmployerNumberParent IS NULL
                                    THEN d.EmployerNumber
                                    ELSE epa.EmployerNumberParent
                                END                                     AS EmployerNumber, 
                                d.EmployerNumber                        AS EmployerNumberChild,
                                pad.PartitionAmount,
                                pad.VoucherAmount,
                                CASE WHEN dpv.DeclarationValue IS NULL
                                    THEN 0
                                    ELSE 1
                                END                                     AS WithVoucher,
                                dpv.VoucherNumber,
                                dep.PartitionStatus,
                                pad.PartitionAmount+pad.VoucherAmount   AS total,
                                dep.PartitionID,
                                dep.DeclarationID,
                                (   
                                    SELECT  COUNT(1)
                                    FROM    sub.tblDeclaration_Employee dem 
                                    WHERE   dem.DeclarationID = dep.DeclarationID
                                )                                       AS EmployeeCount
                        FROM	sub.tblPaymentRun par
                        INNER JOIN sub.tblPaymentRun_Declaration pad ON pad.PaymentRunID = par.PaymentRunID
                        INNER JOIN sub.tblDeclaration d ON d.DeclarationID = pad.DeclarationID
                        INNER JOIN sub.tblDeclaration_Partition dep ON dep.PartitionID = pad.PartitionID
                        LEFT JOIN sub.tblDeclaration_Partition_Voucher dpv
                        ON      dpv.DeclarationID = pad.DeclarationID
                        AND     dpv.PartitionID = pad.PartitionID
                        LEFT JOIN sub.tblEmployer_ParentChild epa 
                        ON      epa.EmployerNumberChild = d.EmployerNumber
                        AND     CAST(LEFT(dep.PartitionYear, 4) AS int) BETWEEN YEAR(epa.StartDate) AND COALESCE(YEAR(epa.EndDate), CAST(dep.PartitionYear AS int))
                        WHERE   par.SubsidySchemeID = 1     -- OSR
                        AND     dep.PartitionYear = @SubsidyYear
                        AND     dep.PartitionStatus IN ('0010', '0012', '0014')
                        AND     pad.PartitionAmount + pad.VoucherAmount <> 0.00
                        --AND     d.EmployerNumber = '001243'
                    ) AS sub1
                GROUP BY
                        sub1.PartitionYear,
                        sub1.EmployerNumber,
                        sub1.PartitionAmount,
                        sub1.VoucherAmount,
                        sub1.PartitionID,
                        sub1.DeclarationID,
                        sub1.EmployeeCount
            ) AS sub2
        INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = sub2.EmployerNumber
        GROUP BY 
                sub2.PartitionYear,
                sub2.EmployerNumber,
                emp.EmployerName
    ) AS sub3
INNER JOIN sub.tblEmployer_Subsidy esu 
ON      esu.EmployerNumber = sub3.EmployerNumber
AND     esu.SubsidyYear = sub3.PartitionYear
LEFT JOIN cte_ParentChild cte
ON      cte.EmployerNumber = sub3.EmployerNumber
AND     CAST(sub3.PartitionYear AS int) BETWEEN cte.StartYear AND COALESCE(cte.EndYear, CAST(sub3.PartitionYear AS int))
WHERE   sub3.TotalAmountPaid <> 0.00
GROUP BY
        sub3.PartitionYear,
        sub3.EmployerNumber,
        sub3.EmployerName,
        sub3.VoucherCount,
        sub3.VoucherAmount,
        sub3.SumPartitionAmount,
        sub3.EmployeeCount,
        esu.SubsidyAmountPerEmployer
ORDER BY 
        NumberOfChilds DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_11_OSR_Payments_PerYear ==============================================	*/
