CREATE VIEW [evc].[viewDeclaration]
AS

SELECT	d.DeclarationID,
		YEAR(d.StartDate)			AS EVCYear, 
		d.EmployerNumber, 
		d.SubsidySchemeID,
		d.DeclarationDate,
		d.InstituteID,
		d.StartDate					AS IntakeDate,
		d.EndDate					AS CertificationDate,
		d.DeclarationAmount,
		d.ApprovedAmount,
		d.DeclarationStatus,
		d.StatusReason,
		d.InternalMemo,
		evcd.MentorCode,
		CASE WHEN ISNULL(evcd.MentorCode, '0000') = '0000' 
			THEN NULL 
			ELSE men.SettingValue
		END							AS Mentor,
		evcd.QualificationLevel,
		ql.SettingValue				AS QualificationLevelLevelName,
		CASE WHEN ISNULL(evcd.MentorCode, '0000') = '0000' 
			THEN 0 
			ELSE 1 
		END							AS IsEVC500,
		de.EmployeeNumber,
		dp.PartitionID,
		dp.PartitionStatus,
		dp.PartitionAmountCorrected	AS PartitionAmount,
		dp.PaymentDate,
		eme.FullName				AS Employee,
		eme.DateOfBirth
FROM	sub.tblDeclaration d
INNER JOIN	sub.tblDeclaration_Partition dp 
		ON	dp.DeclarationID = d.DeclarationID
INNER JOIN	sub.tblDeclaration_Employee de 
		ON	de.DeclarationID = d.DeclarationID
LEFT JOIN	sub.tblEmployee eme
		ON	eme.EmployeeNumber = de.EmployeeNumber
LEFT JOIN	evc.tblDeclaration evcd 
		ON	evcd.DeclarationID = d.DeclarationID
LEFT JOIN	evc.viewApplicationSetting_Mentor men 
		ON	men.SettingCode = evcd.MentorCode
LEFT JOIN	evc.viewApplicationSetting_QualificationLevel ql 
		ON	ql.SettingCode = evcd.QualificationLevel
WHERE	d.SubsidySchemeID = 3
