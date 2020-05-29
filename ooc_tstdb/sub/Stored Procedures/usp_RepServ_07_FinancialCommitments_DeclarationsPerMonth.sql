
CREATE PROCEDURE [sub].[usp_RepServ_07_FinancialCommitments_DeclarationsPerMonth]
@SubsidySchemeID	int,
@SubsidyYear		varchar(20)
AS
/*	==========================================================================================
	Purpose:	List of declarations per month that are to be paid for the OSR.

	Parameters:	@Year: The subsidy year.

	15-10-2019	Sander van Houten	OTIBSUB-1618	If EVC is selected then also select EVC-WV.
	27-09-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @SubsidySchemeID	int = 1,
        @SubsidyYear		varchar(20) = '2019'
--  */

/*  Insert @SubsidySchemeID into a modifiable table variable.   */
DECLARE @tblSubsidyScheme   sub.uttSubsidySchemeID

INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (@SubsidySchemeID)

/*  If EVC is selected then also select EVC-WV (OTIBSUB-1618).  */
IF EXISTS ( SELECT  1
            FROM    @tblSubsidyScheme
            WHERE   SubsidySchemeID = 3)
BEGIN
    INSERT INTO @tblSubsidyScheme (SubsidySchemeID) VALUES (5)
END


SELECT	sub2.DeclarationYear,
		sub2.DeclarationMonth,
        sub2.DeclarationMonthName,
		SUM(PartitionAmount)			                                                                                    AS Submitted,
		SUM(CASE WHEN sub2.PartitionStatus IN ('0010', '0011', '0012') THEN sub2.PartitionAmountCorrected ELSE 0.00 END)	AS Payed,	
		SUM(CASE WHEN sub2.PartitionStatus IN ('0009') THEN sub2.PartitionAmountCorrected ELSE 0.00 END)	                AS ToBePayed	
FROM
		(
			SELECT	YEAR(sub1.DeclarationDate)                                                                  AS DeclarationYear, 
					MONTH(sub1.DeclarationDate)                                                                 AS DeclarationMonth,
                    Upper(LEFT(mnl.MonthNameLong, 1)) + RIGHT(mnl.MonthNameLong, LEN(mnl.MonthNameLong) - 1)    AS DeclarationMonthName,
					sub1.PartitionAmount,
					sub1.PartitionAmountCorrected,
					sub1.PartitionStatus 
			FROM
					(
						SELECT	CASE WHEN decl.DeclarationDate > dp.PaymentDate 
									THEN decl.DeclarationDate 
									ELSE dp.PaymentDate 
								END                 AS DeclarationDate, 
								dp.PartitionAmount,
								dp.PartitionAmountCorrected,
								dp.PartitionStatus
						FROM	sub.tblDeclaration decl
						INNER JOIN sub.tblDeclaration_Partition dp 
                        ON      dp.DeclarationID = decl.DeclarationID
						WHERE	decl.SubsidySchemeID IN 
                                                        (
                                                            SELECT	SubsidySchemeID 
                                                            FROM	@tblSubsidyScheme
                                                        )
						AND		dp.PartitionYear = @SubsidyYear
						AND		dp.PartitionStatus NOT IN ('0001', '0002', '0007', '0017')
					) sub1
			INNER JOIN ait.viewMonthNameLongByLanguage mnl 
					ON	mnl.MonthNumber = MONTH(sub1.DeclarationDate)
					AND	mnl.langid = 7
			) sub2
GROUP BY 
        sub2.DeclarationYear,
		sub2.DeclarationMonth,
        sub2.DeclarationMonthName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_07_FinancialCommitments_DeclarationsPerMonth =====================	*/
