
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_History_List]
AS
/*	==========================================================================================
	Purpose:	Get data of specific submitted IBAN change.

	26-11-2019	Sander van Houten	OTIBSUB-1736	Added ReturnToEmployerReason
                                        to InternalMemo if exists.
	02-05-2019	Sander van Houten	OTIBSUB-1043	Added user initials to status description.
	05-03-2019	Sander van Houten	OTIBSUB-700		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		eic.IBANChangeID,
		LTRIM(ISNULL(STUFF((SELECT ', ' + sub.SettingValue
							FROM	(SELECT	CASE chk.SettingCode
												WHEN CAST(eic.FirstCheck_UserID AS varchar(10)) THEN 1
												ELSE 2
											END	AS SortOrder,
											chk.SettingValue
									 FROM sub.tblApplicationSetting chk
									 WHERE	chk.SettingName = 'UserInitials'
									   AND	( chk.SettingCode = CAST(eic.FirstCheck_UserID AS varchar(10))
										OR	  chk.SettingCode = CAST(eic.SecondCheck_UserID AS varchar(10))
											)) AS sub
							ORDER BY sub.SortOrder
							FOR XML PATH('')), 1, 1, ''), ''))				AS CheckedBy,
		CAST(eic.Creation_DateTime AS date)									AS CreationDate,
		emp.EmployerName,
		usr.Fullname														AS RequestedBy_UserName,
		eic.IBAN_New														AS NewIBAN,
		eic.IBAN_Old														AS OldIBAN,
		REPLACE(
			REPLACE(
					ics.SettingValue, '(1)', '(' + ISNULL(fui.SettingValue, '') + ')'
					),
					'(2)', '(' + ISNULL(sui.SettingValue, '') + ')'
				)															AS ChangeStatusDescription,
		CASE WHEN eic.ReturnToEmployerReason IS NULL
            THEN eic.InternalMemo
            ELSE eic.ReturnToEmployerReason + ' ' + ISNULL(eic.InternalMemo, '')
        END                                                                 AS InternalMemo,
		irr.SettingValue													AS RejectionReasonDescription,
		eic.StartDate,
		eic.ChangeExecutedOn
FROM	sub.tblEmployer_IBAN_Change eic
INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = eic.EmployerNumber
INNER JOIN auth.tblUser usr	ON usr.UserID = eic.Creation_UserID
LEFT JOIN sub.tblApplicationSetting fui	ON fui.SettingName = 'UserInitials'	AND	fui.SettingCode = eic.FirstCheck_UserID
LEFT JOIN sub.tblApplicationSetting sui	ON sui.SettingName = 'UserInitials'	AND	sui.SettingCode = eic.SecondCheck_UserID
LEFT JOIN sub.tblApplicationSetting ics	ON ics.SettingName = 'IBANChangeStatus'	AND	ics.SettingCode = eic.ChangeStatus
LEFT JOIN sub.tblApplicationSetting irr	ON irr.SettingName = 'IBANRejectionReason' AND irr.SettingCode = eic.RejectionReason
ORDER BY
		eic.Creation_DateTime DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_IBAN_Change_History_List ========================================	*/
