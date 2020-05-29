
CREATE proc [sub].[usp_RepServ_04_OSRYearInfo]
AS

/*	==========================================================================================
	Purpose:	List with Company size

	07-06-2019	H. Melissen			Columns EmployeeAmount and EmployerAmount, CAST AS decimal(6,2)
	05-06-2019	Jaap van Assenbergh	
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

;WITH cteSubsidyAmountPerEmployee AS
	(
		SELECT	aps.SettingCode, aps.SettingValue, apse.StartDate, DATEPART(YEAR, apse.StartDate) StartYear, apse.EndDate, DATEPART(YEAR, apse.EndDate) EndYear, apse.ReferenceDate
		FROM	sub.tblApplicationSetting aps
		INNER JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
		WHERE	aps.SettingName = 'SubsidyAmountPerEmployee'
		AND		aps.SettingCode = 'OSR'
	),
cteSubsidyAmountPerEmployer AS
	(
		SELECT	aps.SettingCode, aps.SettingValue, apse.StartDate, apse.EndDate
		FROM	sub.tblApplicationSetting aps
		INNER JOIN sub.tblApplicationSetting_Extended apse ON apse.ApplicationSettingID = aps.ApplicationSettingID
		WHERE	aps.SettingName = 'SubsidyAmountPerEmployer'
		AND		aps.SettingCode = 'OSR'
	)

SELECT	apee.SettingCode + ' ' + CAST(apee.StartYear AS varchar(4)) + CASE WHEN apee.EndYear <> apee.StartYear THEN ' - ' + CAST(apee.EndYear AS varchar(4)) ELSE '' END SubsidyYear, 
		apee.ReferenceDate, 
		CAST(apee.SettingValue AS decimal(6,2)) AS EmployeeAmount, 
		CAST(aper.SettingValue AS decimal(6,2)) AS EmployerAmount
FROM	cteSubsidyAmountPerEmployee apee
INNER JOIN cteSubsidyAmountPerEmployer aper ON apee.SettingCode = aper.SettingCode AND apee.StartDate = aper.StartDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== usp_RepServ_04_OSRYearInfo ========================================================	*/
