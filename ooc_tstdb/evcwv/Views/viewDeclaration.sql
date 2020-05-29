CREATE VIEW [evcwv].[viewDeclaration]
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
		evcwvd.MentorCode,
		CASE WHEN ISNULL(evcwvd.MentorCode, '0000') = '0000' 
			THEN NULL 
			ELSE men.SettingValue
		END							AS Mentor,
		evcwvd.ParticipantID,
		evcwvd.OutflowPossibility,
		CASE WHEN ISNULL(evcwvd.MentorCode, '0000') = '0000' 
			THEN 0 
			ELSE 1 
		END							AS IsEVC500,
		par.EmployeeNumber,
		dp.PartitionID,
		dp.PartitionStatus,
		dp.PartitionAmountCorrected	AS PartitionAmount,
		dp.PaymentDate,
		CASE 
			WHEN ISNULL(par.EmployeeNumber, 0 ) = 0 
			THEN par.FullName
			ELSE eme.FullName
		END	AS ParticipantName,
		eme.DateOfBirth
FROM	sub.tblDeclaration d
INNER JOIN	evcwv.tblDeclaration evcwvd 
		ON	evcwvd.DeclarationID = d.DeclarationID
INNER JOIN	sub.tblDeclaration_Partition dp 
		ON	dp.DeclarationID = d.DeclarationID
INNER JOIN	evcwv.tblParticipant par 
		ON	par.ParticipantID = evcwvd.ParticipantID
LEFT JOIN	sub.tblEmployee eme 
		ON	eme.EmployeeNumber = par.EmployeeNumber
LEFT JOIN	evcwv.viewApplicationSetting_Mentor men 
		ON	men.SettingCode = evcwvd.MentorCode
WHERE	d.SubsidySchemeID = 5
