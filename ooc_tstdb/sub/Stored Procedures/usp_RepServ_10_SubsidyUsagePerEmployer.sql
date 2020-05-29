CREATE PROCEDURE [sub].[usp_RepServ_10_SubsidyUsagePerEmployer]
@EmployerNumber varchar(6)
AS
/*	==========================================================================================
	Purpose:	Details of the usage of subsidy budgets per scheme per employer.


	20-12-2019	H. Melissen			OTIBDS-339		The result set of stored procedure sub.uspEmployer_Get_Summary has been changed (OTIBSUB-1725).
													Two columns added to @tblOSRSummary (EndDeclarationPeriod and ShowEndDeclarationPeriod).
	14-11-2019	Sander van Houten	OTIBSUB-1698    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata. */
--DECLARE @EmployerNumber varchar(6) = '071975'

-- Get OSR Summary data.
DECLARE @SubsidySchemeID int = 1

DECLARE @tblOSRSummary AS TABLE 
    (
        EmployerNumber      varchar(6),
        SubsidySchemeName   varchar(50),
        SubsidyYear         varchar(10),
        DeclarationYear     varchar(10),
        Credit              decimal(19, 4),
        Reimbursed          decimal(19, 4),
        InTreatment         decimal(19, 4),
        Saldo               numeric(19, 4),
        Used                numeric(19, 4),
        StartDate           date,
        EndDate             date,
		EndDeclarationPeriod date,
		ShowEndDeclarationPeriod bit,
        FeesPaidUntill      date,
        StartDateMembership date,
        EndDateMembership   date,
        ShowMembershipDates bit
    )

INSERT INTO @tblOSRSummary
    (
        SubsidySchemeName,
        SubsidyYear,
        DeclarationYear,
        Credit,
        Reimbursed,
        InTreatment,
        Saldo,
        StartDate,
        EndDate,
        EndDeclarationPeriod,
        ShowEndDeclarationPeriod,
        FeesPaidUntill,
        StartDateMembership,
        EndDateMembership,
        ShowMembershipDates
    )
EXECUTE [sub].[uspEmployer_Get_Summary] 
    @EmployerNumber,
    @SubsidySchemeID

UPDATE  @tblOSRSummary
SET     EmployerNumber = @EmployerNumber,
        Used = Credit - Saldo


-- Get last declaration date per subsidyscheme.
DECLARE @tblDeclarationData AS TABLE 
    (
        EmployerNumber      varchar(6),
        SubsidySchemeName   varchar(100),
        LastDeclarationDate date
    )

INSERT INTO @tblDeclarationData
    (
        EmployerNumber,
        SubsidySchemeName,
        LastDeclarationDate
    )
SELECT  @EmployerNumber,
        ssc.SubsidySchemeName,
        MAX(d.DeclarationDate)  AS LastDeclarationDate
FROM    sub.tblSubsidyScheme ssc
LEFT JOIN sub.tblDeclaration d
ON      ssc.SubsidySchemeID = d.SubsidySchemeID
AND     d.EmployerNumber = @EmployerNumber
GROUP BY
        ssc.SubsidySchemeName


-- Get event data.
DECLARE @tblEventData AS TABLE 
    (
        EmployerNumber  varchar(6),
        NrOfEmployees   int,
        EventName       varchar(100)
    )

INSERT INTO @tblEventData
    (
        EmployerNumber,
        NrOfEmployees,
        EventName
    )
SELECT  eme.EmployerNumber,
        COUNT(1)    AS NrOfEmployees,
        evo.EventName
FROM    sub.tblEmployer_Employee eme
INNER JOIN sub.tblEmployee_Voucher evo
ON      evo.EmployeeNumber = eme.EmployeeNumber
WHERE   ( eme.EmployerNumber = @EmployerNumber
    OR    eme.EmployerNumber IN (
                                    SELECT  epc.EmployerNumberChild
                                    FROM    sub.tblEmployer_ParentChild epc
                                    WHERE   epc.EmployerNumberParent = @EmployerNumber
                                )
        )
AND     evo.GrantDate >= CAST(DATEADD(MONTH, -12, GETDATE()) AS date)
GROUP BY
        eme.EmployerNumber,
        evo.EventName


-- Get resultset
SELECT  emp.EmployerNumber,
        emp.EmployerName,
        dda.SubsidySchemeName,
        dda.LastDeclarationDate,
        osrs.SubsidyYear,
        osrs.DeclarationYear,
        osrs.Credit,
        osrs.Reimbursed,
        osrs.InTreatment,
        osrs.Saldo,
        osrs.Used,
        evd.EventName,
        evd.NrOfEmployees
FROM    sub.tblEmployer emp
LEFT JOIN @tblDeclarationData dda
ON      dda.EmployerNumber = emp.EmployerNumber
LEFT JOIN @tblOSRSummary osrs
ON      osrs.EmployerNumber = emp.EmployerNumber
LEFT JOIN @tblEventData evd
ON      evd.EmployerNumber = emp.EmployerNumber
WHERE   emp.EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_10_SubsidyUsagePerEmployer ===========================================	*/
