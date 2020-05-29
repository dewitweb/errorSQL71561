CREATE FUNCTION [sub].[usfGetEmployerBalanceAmount_Year]
/*	*********************************************************************************************
	Purpose:	Calculates the balance amount of a specific employer for a specific year.

    Notes:      Can be used for ad-hoc queries

	28-01-2020	Sander van Houten	OTIBSUB-1856    Initial version.
	********************************************************************************************* */
(
	@EmployerNumber varchar(6),
    @SubsidyYear    varchar(4)
)
RETURNS decimal(19,2)
AS
BEGIN
	DECLARE @BalanceAmount	    decimal(19,2),
            @SubsidySchemeID	int = 1

    ;WITH cteES AS
        (
            SELECT	EmployerNumber,
                    SubsidySchemeID, 
                    StartDate, 
                    EndDate, 
                    EndDeclarationPeriod, 
                    Amount, 
                    YEAR(StartDate)	AS StartYear, 
                    YEAR(EndDate)	AS EndYear,
                    SubsidyYear
            FROM	sub.tblEmployer_Subsidy
            WHERE	EmployerNumber = @EmployerNumber
            AND		SubsidyYear = @SubsidyYear
        )
    ,
    cte_EmployerData AS
        (
            SELECT	ISNULL(par.FeesPaidUntill, CAST(GETDATE() AS date))	AS FeesPaidUntill,
                    emp.StartDateMembership,
                    emp.EndDateMembership,
                    emp.TerminationReason
            FROM	sub.tblEmployer emp
            LEFT JOIN sub.tblPaymentArrear par ON par.EmployerNumber = emp.EmployerNumber
            WHERE	emp.EmployerNumber = @EmployerNumber
        )

    SELECT	@BalanceAmount = CASE WHEN ROUND((groupby.Credit - groupby.Reimbursed - groupby.InTreatment), 2) < 0.00
                                THEN 0.00
                                ELSE ROUND((groupby.Credit - groupby.Reimbursed - groupby.InTreatment), 2)
                             END
            --ROUND(groupby.Reimbursed, 2)			AS Reimbursed,
    FROM
            (
                SELECT	selection.SubsidySchemeName, 
                        selection.SubsidyYear, 
                        selection.SubsidyYear       AS DeclarationYear, 
                        selection.Credit,
                        SUM(selection.Reimbursed)   AS Reimbursed,
                        SUM(selection.InTreatment)  AS InTreatment,
                        selection.StartDate, 
                        selection.EndDate,
                        selection.EndDeclarationPeriod
                FROM
                        (
                            SELECT	ss.SubsidySchemeName, 
                                    es.SubsidyYear, 
                                    es.Amount		AS Credit, 
                                    CASE 
                                        WHEN dtpa.SumPartitionAmount IS NOT NULL
                                            THEN dtpa.SumPartitionAmount
                                            ELSE 0.00
                                        END			AS Reimbursed,
                                    CASE 
                                        WHEN dp.PartitionStatus = '0009'
                                            THEN dp.PartitionAmountCorrected
                                        WHEN dp.PartitionStatus IN ('0010', '0012', '0014', '0016', '0028')
                                            THEN 0.00
                                        ELSE ISNULL(dp.PartitionAmount, 0.00)
                                        END			AS InTreatment,
                                    es.StartDate, 
                                    es.EndDate,
                                    es.EndDeclarationPeriod
                            FROM 	cteES es 
                            INNER JOIN	sub.tblSubsidyScheme ss 
                                ON	ss.SubsidySchemeID = es.SubsidySchemeID
                            LEFT JOIN sub.tblDeclaration d 
                                ON	d.EmployerNumber = es.EmployerNumber
                                AND	d.SubsidySchemeID = es.SubsidySchemeID 
                            LEFT JOIN sub.tblDeclaration_Partition dp 
                                ON	dp.DeclarationID = d.DeclarationID
                                AND	dp.PartitionYear = es.SubsidyYear
                                AND dp.PartitionStatus NOT IN ('0001', '0007', '0017')
                            LEFT JOIN sub.viewDeclaration_TotalPaidAmount_PerYear dtpa
                                ON	dtpa.DeclarationID = d.DeclarationID
                                AND	dtpa.SubsidySchemeID = es.SubsidySchemeID
                                AND dtpa.PartitionYear = es.SubsidyYear
                                AND dtpa.EmployerNumber = es.EmployerNumber
                            WHERE	es.EmployerNumber = @EmployerNumber
                            AND		@SubsidySchemeID =	CASE WHEN		@SubsidySchemeID = 0
                                                                THEN	@SubsidySchemeID
                                                                ELSE	es.SubsidySchemeID
                                                        END
                            AND     es.EndDeclarationPeriod >= CAST(GETDATE() AS date)
                        ) selection
                GROUP BY
                        selection.SubsidySchemeName, 
                        selection.SubsidyYear, 
                        selection.Credit, 
                        selection.StartDate, 
                        selection.EndDate,
                        selection.EndDeclarationPeriod
            ) groupby
    CROSS JOIN cte_EmployerData eda

	RETURN @BalanceAmount
END
