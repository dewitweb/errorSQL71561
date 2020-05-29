
CREATE PROCEDURE [sub].[uspEmployer_Get_Summary]
@EmployerNumber		varchar(6),
@SubsidySchemeID	int 
AS
/*	==========================================================================================
	Purpose:	Get summary for an employer.

	27-11-2019	Jaap van Assenbergh	OTIBSUB-1738	Saldo scholingsbudget weergave dashboard onjuist
	25-11-2019	Sander van Houten	OTIBSUB-1725	Added EndDeclarationPeriod and 
                                        ShowEndDeclarationPeriod to the resultset.
	08-11-2019	Sander van Houten	OTIBSUB-1539	Removed comment line.
	30-07-2019	Sander van Houten	OTIBSUB-1417	Added join on viewDeclaration_TotalPaidAmount_PerYear.
	20-06-2019	Sander van Houten	OTIBSUB-1196	Added FeesPaidUntil and MembershipDates.
	15-05-2019	Sander van Houten	OTIBSUB-1086	Fixed display of balance when there
										are no declarations yet.
	14-05-2019	Sander van Houten	OTIBSUB-1083	Fixed grouping for Reimbursed and 
										InTreatment cases.
	03-05-2019	Sander van Houten	OTIBSUB-1046	Move voucher use to partition level.
	01-03-2018	Jaap van Assenbergh	OTIBSUB-790		Weergave scholingsbudget op dashboard werkgever			
										ROUND((Credit - Reimbursed), 2) Saldo	toegevoegd.
	03-09-2018	Jaap van Assenbergh	OTIBSUB-493		Waardebonnen bij eerste betaling 
										geheel meenemen.
	03-09-2018	Jaap van Assenbergh	OTIBSUB-201		Alle periodes terug geven waarvan 
										de einddatum van de declaratieperiode <= vandaag. 
	30-07-2018	Jaap van Assenbergh	Ophalen lijst met actuele openstaande saldo's
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @EmployerNumber		varchar(6) = '122160',
		@SubsidySchemeID	int = 1
--	*/

SET	@SubsidySchemeID = ISNULL(@SubsidySchemeID, 0)

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
		AND		EndDeclarationPeriod >= CAST(GETDATE() as date)
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

SELECT	groupby.SubsidySchemeName,
		groupby.SubsidyYear,
		groupby.SubsidyYear						AS DeclarationYear, 
		ROUND(groupby.Credit, 2)				AS Credit,
		ROUND(groupby.Reimbursed, 2)			AS Reimbursed,
		ROUND(groupby.InTreatment, 2)			AS InTreatment,
		CASE WHEN ROUND((groupby.Credit - groupby.Reimbursed - groupby.InTreatment), 2) < 0.00
			THEN 0.00
			ELSE ROUND((groupby.Credit - groupby.Reimbursed - groupby.InTreatment), 2)
		END		                                AS Saldo,
		groupby.StartDate, 
		groupby.EndDate,
        groupby.EndDeclarationPeriod,
        CASE WHEN YEAR(GETDATE()) >= YEAR(groupby.EndDeclarationPeriod)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
        END                                     AS ShowEndDeclarationPeriod,
		eda.FeesPaidUntill,
		eda.StartDateMembership,
		eda.EndDateMembership,
		CASE eda.TerminationReason
			WHEN 'FAIL' THEN CAST(1 AS bit)
			ELSE CAST(0 AS bit)
		END								AS ShowMembershipDates
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
ORDER BY
        groupby.SubsidyYear
        
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Get_Summary ===========================================================	*/
