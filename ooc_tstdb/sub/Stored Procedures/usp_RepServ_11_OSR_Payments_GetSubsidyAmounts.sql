CREATE PROCEDURE [sub].[usp_RepServ_11_OSR_Payments_GetSubsidyAmounts]
@SubsidyYear    varchar(4)
AS
/*	==========================================================================================
	Purpose:	Get the standard subsidy amounts for employers and employees for a specific year.

    Notes:      This procedure is used in: 11 OSR Benutting werkgevers.rdl

	06-12-2019	Sander van Houten	OTIBSUB-1636    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Declare variables.
DECLARE @AmountPerEmployer decimal(18,2),
        @AmountPerEmployee decimal(18,2)

-- Get the amounts.
SELECT	@AmountPerEmployer = CAST(SettingValue AS decimal(18,2))
FROM    sub.viewApplicationSetting_SubsidyAmountPerEmployer
WHERE   SettingCode = 'OSR'
AND     LEFT(ReferenceDate, 4) = @SubsidyYear

SELECT	@AmountPerEmployee = CAST(SettingValue AS decimal(18,2))
FROM    sub.viewApplicationSetting_SubsidyAmountPerEmployee
WHERE   SettingCode = 'OSR'
AND     LEFT(ReferenceDate, 4) = @SubsidyYear

-- Give back the result.
SELECT  @AmountPerEmployer  AS AmountPerEmployer,
        @AmountPerEmployee  AS AmountPerEmployee

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	==	sub.usp_RepServ_11_OSR_Payments_GetSubsidyAmounts ================================	*/
