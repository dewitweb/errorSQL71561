
CREATE FUNCTION [sub].[usfGetEndDeclarationPeriod]
	(
		@EmployerSubsidyID	int
	)
/*	*********************************************************************************************
	Purpose:	Recalculates the amount that is left for a partition.

    13-01-2020	Sander van Houten	OTIBSUB-1827    Include optional record(s) in 
                                        sub.tblEmployer_Subsidy_GracePeriod for determining the
                                        EndDeclarationPeriod.
    24-07-2018	Jaap van Assenbergh	Ophalen Start periode, eind periode en einde declaratie periode.
	********************************************************************************************* */
RETURNS date
AS
BEGIN
	DECLARE @EndDeclarationPeriod date

    ;WITH cte_GracePeriod AS
    (
        SELECT  @EmployerSubsidyID  AS EmployerSubsidyID,
                MAX(EndDate)        AS GracePeriod_EndDate
        FROM    sub.tblEmployer_Subsidy_GracePeriod
        WHERE   EmployerSubsidyID = @EmployerSubsidyID
        AND     GracePeriodStatus = '0002'
    )
	SELECT  @EndDeclarationPeriod = CASE WHEN ISNULL(gp.GracePeriod_EndDate, '2000-01-01') <
                                              CAST(sub.usfDateAdd(ssc.SubmitInterval, ssc.SubmitIncrement, ems.EndDate) AS date)
                                        THEN CAST(sub.usfDateAdd(ssc.SubmitInterval, ssc.SubmitIncrement, ems.EndDate) AS date)
                                        ELSE gp.GracePeriod_EndDate
                                    END
	FROM	sub.tblEmployer_Subsidy ems
	INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = ems.SubsidySchemeID
    LEFT JOIN cte_GracePeriod gp ON gp.EmployerSubsidyID = ems.EmployerSubsidyID
	WHERE	ems.EmployerSubsidyID = @EmployerSubsidyID

	RETURN @EndDeclarationPeriod
END
