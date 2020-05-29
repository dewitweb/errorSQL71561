CREATE PROCEDURE [ait].[FindMyUSP_InJob]
    @DataToFind NVARCHAR(4000)
AS

SELECT	sJOB.name JobName, sJOB.Enabled,
		sJSTP.step_name StepName, sJSTP.step_id StepNumber,
		CASE 
			WHEN last_run_date = 0 
				THEN NULL
			ELSE CONVERT(varchar(20), CAST(CAST(last_run_date as varchar(8)) as date), 105)
			END LastRun
FROM	msdb.dbo.sysjobs AS sJOB
INNER JOIN	msdb.dbo.sysjobsteps AS sJSTP
        ON	sJSTP.job_id = sJOB.job_id
WHERE	CHARINDEX(@DataToFind, sJSTP.Command, 1) <> 0
ORDER BY 1, 2

