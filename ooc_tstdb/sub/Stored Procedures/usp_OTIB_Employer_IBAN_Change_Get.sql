
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_Get]
@IBANChangeID	int
AS
/*	==========================================================================================
	Purpose:	Get data of specific submitted IBAN change.

	19-11-2019	Sander van Houten	OTIBSUB-1718	Added CanAccept, CanReject, CanReturnToEmployer
                                        and ReturnToEmployerReason to resultset.
	02-05-2019	Sander van Houten	OTIBSUB-1043	Added user initials to status description.
	02-05-2019	Sander van Houten	OTIBSUB-1040	Added attachments.
	05-03-2019	Sander van Houten	OTIBSUB-817		Added fields StartDate and ChangeExecutedOn.
	19-11-2018	Sander van Houten	OTIBSUB-98		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			eic.IBANChangeID,
			emp.EmployerNumber,
			emp.EmployerName,
			emp.BusinessAddressStreet + ' ' + emp.BusinessAddressHousenumber	AS AddressLine1,
			emp.BusinessAddressZipcode + '  ' + emp.BusinessAddressCity			AS AddressLine2,
			usr.Fullname														AS ContactName,
			usr.FunctionDescription												AS ContactFunction,
			usr.Phone															AS ContactPhone,
			usr.Email															AS ContactEmail,
			eic.IBAN_Old														AS CurrentIBAN,
			eic.IBAN_New														AS NewIBAN,
			eic.Ascription,
			REPLACE(
				REPLACE(
						ics.SettingValue, '(1)', '(' + ISNULL(fui.SettingValue, '') + ')'
					   ),
					 '(2)', '(' + ISNULL(sui.SettingValue, '') + ')'
					)															AS ChangeStatusDescription,
			ics.SettingCode														AS ChangeStatusCode,
			eic.InternalMemo,
			eic.Creation_DateTime,
			eic.FirstCheck_UserID,
			fcu.Fullname														AS FirstCheck_UserName,
			eic.FirstCheck_DateTime,
			eic.SecondCheck_UserID,
			scu.Fullname														AS SecondCheck_UserName,
			eic.SecondCheck_DateTime,
			irr.SettingValue													AS RejectionReasonDescription,
			irr.SettingCode														AS RejectionReasonCode,
			eic.StartDate,
			eic.ChangeExecutedOn,
			(	SELECT	
					eica.AttachmentID
					FROM	sub.tblEmployer_IBAN_Change_Attachment eica
					WHERE	eica.IBANChangeID = eic.IBANChangeID
				FOR XML PATH('Attachment'), ROOT('Attachments')
			)                                                                   AS AttachmentXML,
            CAST(CASE eic.ChangeStatus
                    WHEN '0000' THEN 1
                    WHEN '0001' THEN 1
                    ELSE 0
                 END AS bit)                                                      AS CanAccept,
            CAST(CASE eic.ChangeStatus
                    WHEN '0000' THEN 1
                    WHEN '0001' THEN 1
                    ELSE 0
                 END AS bit)                                                      AS CanReject,
            CAST(CASE eic.ChangeStatus
                    WHEN '0000' THEN 1
                    WHEN '0001' THEN 1
                    ELSE 0
                 END AS bit)                                                      AS CanReturnToEmployer,
            eic.ReturnToEmployerReason
	FROM	sub.tblEmployer_IBAN_Change eic
	INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = eic.EmployerNumber
	INNER JOIN auth.tblUser usr	ON usr.UserID = eic.Creation_UserID
	LEFT JOIN auth.tblUser fcu	ON fcu.UserID = eic.FirstCheck_UserID
	LEFT JOIN auth.tblUser scu	ON scu.UserID = eic.SecondCheck_UserID
	LEFT JOIN sub.tblApplicationSetting fui	ON fui.SettingName = 'UserInitials'	AND	fui.SettingCode = eic.FirstCheck_UserID
	LEFT JOIN sub.tblApplicationSetting sui	ON sui.SettingName = 'UserInitials'	AND	sui.SettingCode = eic.SecondCheck_UserID
	LEFT JOIN sub.tblApplicationSetting ics	ON ics.SettingName = 'IBANChangeStatus'	AND	ics.SettingCode = eic.ChangeStatus
	LEFT JOIN sub.tblApplicationSetting irr	ON irr.SettingName = 'IBANRejectionReason' AND irr.SettingCode = eic.RejectionReason
	WHERE	eic.IBANChangeID = @IBANChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_IBAN_Change_Get =================================================	*/
