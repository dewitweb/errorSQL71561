CREATE PROCEDURE [sub].[usp_OTIB_Employer_ParentChild_Request_Get_WithEmployerData]
@RequestID	int
AS
/*	==========================================================================================
	Purpose:	Get specific Employer_ParentChild_Request record.

	27-09-2019	Sander van Houten		OTIBSUB-100		Added EmployerNameParent.
	18-09-2019	Sander van Houten		OTIBSUB-100		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		epcr.RequestID,
		ep.EmployerNumber														AS EmployerNumberParent,
		ISNULL(ep.EmployerName, '') + ' (' + epcr.EmployerNumberParent + ')'	AS ParentName,
		epcr.EmployerNameParent + CASE WHEN ep.EmployerNumber IS NULL
									THEN ' (' + epcr.EmployerNumberParent + ')'
									ELSE ''			
								  END											AS SpecifiedParentName,
		COALESCE(ep.PostalAddressStreet, ep.BusinessAddressStreet, '') 
			+ ' '
			+ CASE WHEN ep.PostalAddressStreet IS NOT NULL
				THEN CAST(ISNULL(ep.PostalAddressHousenumber, '') AS varchar(10))
				ELSE CAST(ISNULL(ep.BusinessAddressHousenumber, '')	AS varchar(10))
			  END																AS ParentAddressRow1,
		CASE WHEN ep.PostalAddressStreet IS NOT NULL
				THEN CAST(ISNULL(ep.PostalAddressZipcode, '') AS varchar(10))
						+ ' '
						+ CAST(ISNULL(ep.PostalAddressCity, '') AS varchar(100))
				ELSE CAST(ISNULL(ep.BusinessAddressZipcode, '') AS varchar(10))
						+ ' '
						+ CAST(ISNULL(ep.BusinessAddressCity, '') AS varchar(100))
			  END																AS ParentAddressRow2,
		usp.Fullname															AS ParentContact,
		usp.FunctionDescription													AS ParentContactFunction,
		usp.Phone																AS ParentContactPhone,
		usp.Email																AS ParentContactEmail,
		ISNULL(ec.EmployerName, '') + ' (' + epcr.EmployerNumberChild + ')'		AS ChildName,
		COALESCE(ec.PostalAddressStreet, ec.BusinessAddressStreet, '') 
			+ ' '
			+ CASE WHEN ec.PostalAddressStreet IS NOT NULL
				THEN CAST(ISNULL(ec.PostalAddressHousenumber, '') AS varchar(10))
				ELSE CAST(ISNULL(ec.BusinessAddressHousenumber, '') AS varchar(10))
			  END																AS ChildAddressRow1,
		CASE WHEN ec.PostalAddressStreet IS NOT NULL
				THEN CAST(ISNULL(ec.PostalAddressZipcode, '') AS varchar(10))
						+ ' '
						+ CAST(ISNULL(ec.PostalAddressCity, '') AS varchar(100))
				ELSE CAST(ISNULL(ec.BusinessAddressZipcode, '') AS varchar(10))
						+ ' '
						+ CAST(ISNULL(ec.BusinessAddressCity, '') AS varchar(100))
			  END																AS ChildAddressRow2,
		usc.Fullname															AS ChildContact,
		usc.FunctionDescription													AS ChildContactFunction,
		usp.Phone																AS ChildContactPhone,
		usp.Email																AS ChildContactEmail,
		epcr.StartDate,
		epcr.EndDate,
		epcr.Creation_DateTime,
		epcr.RequestStatus,
		aps.SettingValue														AS StatusDescription,
		epcr.RequestProcessedOn
FROM	sub.tblEmployer_ParentChild_Request epcr
LEFT JOIN sub.tblEmployer ep ON ep.EmployerNumber = epcr.EmployerNumberParent
LEFT JOIN auth.tblUser usp ON usp.Loginname = ep.EmployerNumber
LEFT JOIN sub.tblEmployer ec ON ec.EmployerNumber = epcr.EmployerNumberChild
LEFT JOIN auth.tblUser usc ON usc.Loginname = ec.EmployerNumber
INNER JOIN sub.tblApplicationSetting aps ON aps.SettingCode = epcr.RequestStatus AND aps.SettingName = 'RequestStatus'
WHERE	epcr.RequestID = @RequestID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_ParentChild_Request_Get_WithEmployerData ========================	*/
