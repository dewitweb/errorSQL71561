CREATE VIEW [sub].[viewInstitute]
AS

SELECT	ins.InstituteID,
		ins.InstituteName,
		ins.[Location],
		ins.EndDate,
		ins.HorusID,
		ins.SearchName,
		CASE WHEN evc.InstituteID IS NULL THEN 0 ELSE 1 END IsEVC,
		CASE WHEN evcwv.InstituteID IS NULL THEN 0 ELSE 1 END IsEVCWV
FROM	sub.tblInstitute ins
LEFT JOIN sub.tblSubsidyScheme_Institute evc
		ON	evc.InstituteID = ins.InstituteID 
		AND	evc.SubsidySchemeID = 3
LEFT JOIN sub.tblSubsidyScheme_Institute evcWV 
		ON	evcwv.InstituteID = ins.InstituteID 
		AND	evcwv.SubsidySchemeID = 5
