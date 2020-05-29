CREATE PROCEDURE [his].[uspHistory_List] 
@KeyID		varchar(50) = NULL,
@TableName	varchar(50) = NULL
AS
/*	==========================================================================================
	Doel:	Get history data

	02-12-2019	Sander van Houten		OTIBSUB-1744	Added code for transfer of declaration
                                            to other employer.
	30-08-2019	Sander van Houten		OTIBSUB-1375	Added code for sub.tblJournalEntryCode
											(the download of the new specification version).
	11-07-2019	Sander van Houten		OTIBSUB-1354	Added TimeStamp and UserName to result
											at sub.tblEmployer_Subsidy.
	03-07-2019	Sander van Houten		OTIBSUB-1314	Added logging (triggeraction).
	28-06-2019	Sander van Houten		OTIBSUB-1271	Only return record not made by Admin
											if TableName is sub.tblEmployer_Subsidy.
	19-06-2019	Sander van Houten		OTIBSUB-1194	Added logging for CopyOf / CopyTo.
	06-05-2019	Sander van Houten		OTIBSUB-1045	Added logging for downloads.
	06-08-2018	Sander van Houten		Initial version.

	Note:	KeyID is the Primary key.
			Both are optional, where the TableName parameter (if filled) 
			 can contain an actual tablename or the text ALL.

			The combination NULL, NULL will deliver all the data from tblHistory.
			The combination <KeyID>, NULL will deliver all the data from tblHistory
			 regarding the specified keyid.
			The combination NULL, <TableName> will deliver all the data from tblHistory
			 regarding the specified tablename.
			The combination <KeyID>, <TableName> will deliver all the data from tblHistory
			 regarding the specified keyid and tablename.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Get resultset
SELECT 
	sub1.HistoryID,
	sub1.TableName,
	sub1.KeyID,
	sub1.UserID,
	ISNULL(sub1.Initials, '') AS Initials,
	sub1.Firstname,
	sub1.Infix,
	ISNULL(sub1.Surname, '') AS Surname,
		LTRIM(
			LTRIM(
				RTRIM(COALESCE(sub1.Firstname, sub1.Initials, '') 
						+ ' ' 
						+ COALESCE(sub1.Infix, '')
					 )
				 ) 
				+ ' ' + COALESCE(sub1.Surname, '')
			 ) AS UserName,
	sub1.LogDate,
	ISNULL(sub1.OldValue, '') AS OldValue,
	ISNULL(sub1.NewValue, '') AS NewValue,
	REPLACE(ISNULL(sub1.ActionDescription, ''), 'NULL', '') AS ActionDescription
FROM ( 
	SELECT 
		hist.HistoryID,
		hist.TableName,
		hist.KeyID,
		hist.UserID,
		usr.Initials,
		usr.Firstname,
		usr.Infix,
		usr.Surname,
		hist.LogDate,
		hist.OldValue,
		hist.NewValue,
		hist.OldValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)') oud,
		hist.NewValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)') nieuw,
		CASE hist.TableName
			WHEN 'sub.tblEmployer_Subsidy' THEN 
				CASE 
					WHEN hist.OldValue IS NOT NULL AND hist.OldValue.value('(/row/Amount)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Amount)[1]', 'varchar(max)') 
						THEN '<p>' + CONVERT(varchar(10), hist.LogDate, 105) + ': Het scholingsbudget <strong>' + hist.OldValue.value('(/row/SubsidyYear)[1]', 'varchar(4)') + '</strong> is gewijzigd van '
						+ '<strong>€&nbsp;' + REPLACE(CAST(CAST(hist.OldValue.value('(/row/Amount)[1]', 'varchar(max)') AS dec(19,2)) AS varchar(20)), '.', ',') + '</strong> naar '
						+ '<strong>€&nbsp;' + REPLACE(CAST(CAST(hist.NewValue.value('(/row/Amount)[1]', 'varchar(max)')  AS dec(19,2)) AS varchar(20)), '.', ',') + '</strong> '
						+ '(' + LTRIM(LTRIM(RTRIM(COALESCE(usr.Firstname, usr.Initials, '') + ' ' + COALESCE(usr.Infix, ''))) + ' ' + COALESCE(usr.Surname, ''))  + ')</p>'
						+ CASE WHEN hist.NewValue.value('(/row/ChangeReason)[1]', 'varchar(max)') IS NOT NULL THEN '<p>(' + hist.NewValue.value('(/row/ChangeReason)[1]', 'varchar(max)') + ')</p>' ELSE '' END
				END
			WHEN 'osr.tblDeclaration' THEN 
				CASE 
					WHEN hist.OldValue.value('(/row/Location)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Location)[1]', 'varchar(max)')
						THEN 'De locatie van declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is gewijzigd van "'
						+ hist.OldValue.value('(/row/Location)[1]', 'varchar(max)') + '" naar "'
						+ hist.NewValue.value('(/row/Location)[1]', 'varchar(max)') + '"'
					ELSE '...'
				END
			WHEN 'sub.tblDeclaration' THEN
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is ingediend'
								 + CASE WHEN hist.NewValue.value('(/row/CopyOf)[1]', 'varchar(max)') IS NULL
										THEN ''
										ELSE CHAR(10) + '(Dit is een kopie van declaratie ' + hist.NewValue.value('(/row/CopyOf)[1]', 'varchar(max)') + ')'
								   END
					WHEN '<triggeraction>1</triggeraction>' THEN REPLACE(hist.NewValue.value('(/row/triggeraction)[1]', 'varchar(max)'), '[DeclarationID]', hist.KeyID)
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is verwijderd'
							ELSE CASE 
									WHEN hist.OldValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)')
										THEN 'De status van declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is gewijzigd naar: "'
										+ (SELECT SettingValue FROM sub.tblApplicationSetting WHERE SettingName = 'DeclarationStatus' AND SettingCode = hist.NewValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)'))
										+ CASE WHEN hist.NewValue.value('(/row/DeclarationStatus)[1]', 'varchar(max)') IN ('0007', '0009', '0016', '0017', '0019') AND hist.NewValue.value('(/row/StatusReason)[1]', 'varchar(max)') IS NOT NULL 
											THEN ' (' + hist.NewValue.value('(/row/StatusReason)[1]', 'varchar(max)') + ')'
											ELSE '' 
										  END
										+ '"'
									WHEN ISNULL(hist.OldValue.value('(/row/InternalMemo)[1]', 'varchar(max)'), '') <> ISNULL(hist.NewValue.value('(/row/InternalMemo)[1]', 'varchar(max)'), '')
										THEN 'Het veld "Intern memo" van declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is gewijzigd'
									WHEN hist.NewValue.value('(/row/CopyTo)[1]', 'varchar(max)') IS NOT NULL
										THEN 'Kopie aangemaakt met nummer ' + hist.NewValue.value('(/row/CopyTo)[1]', 'varchar(max)')
									WHEN hist.OldValue.value('(/row/EmployerNumber)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/EmployerNumber)[1]', 'varchar(max)')
										THEN 'Declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is omgehangen van werkgever ' 
                                        + hist.OldValue.value('(/row/EmployerNumber)[1]', 'varchar(max)') + ' naar werkgever ' + hist.NewValue.value('(/row/EmployerNumber)[1]', 'varchar(max)') 
									WHEN ISNULL(hist.OldValue.value('(/row/DeclarationAmount)[1]', 'varchar(max)'), '0.00') <> hist.NewValue.value('(/row/DeclarationAmount)[1]', 'varchar(max)')
										THEN 'Het declaratie bedrag van declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)') + ' is gecorrigeerd van €' 
                                        + REPLACE(CAST(CAST(ISNULL(hist.OldValue.value('(/row/DeclarationAmount)[1]', 'varchar(max)'), '0.00') AS decimal(19,2)) AS varchar(21)), '.', ',') 
                                        + ' naar €' + REPLACE(CAST(CAST(hist.NewValue.value('(/row/DeclarationAmount)[1]', 'varchar(max)') AS decimal(19,2)) AS varchar(21)), '.', ',')
									ELSE '...'
								END
						 END
				END
			WHEN 'sub.tblDeclaration_Attachment' THEN
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Bijlage "' + hist.NewValue.value('(/row/OriginalFileName)[1]', 'varchar(max)') + '" is toegevoegd aan declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
					WHEN '<download>1</download>' THEN 'Bijlage "' + hist.NewValue.value('(/row/OriginalFileName)[1]', 'varchar(max)') + '" is gedownload.'
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Bijlage "' + hist.OldValue.value('(/row/OriginalFileName)[1]', 'varchar(max)') + '" is verwijderd bij declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
							ELSE '...'
						 END
				END
			WHEN 'sub.tblDeclaration_Employee' THEN 
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Werknemer ' + hist.NewValue.value('(/row/EmployeeNumber)[1]', 'varchar(max)') + ' is toegevoegd aan declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Werknemer ' + hist.OldValue.value('(/row/EmployeeNumber)[1]', 'varchar(max)') + ' is verwijderd bij declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
							ELSE '...'
						 END
				END
			WHEN 'sub.tblDeclaration_Partition' THEN 
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Partitie ' + hist.NewValue.value('(/row/PartitionYear)[1]', 'varchar(max)') + ' is aangemaakt bij declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Partitie ' + hist.OldValue.value('(/row/PartitionYear)[1]', 'varchar(max)') + ' is verwijderd bij declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
							ELSE '...'
						 END
				END
			WHEN 'sub.tblDeclaration_Specification' THEN
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Specificatie "' + hist.NewValue.value('(/row/SpecificationDate)[1]', 'varchar(10)') + '" is toegevoegd aan declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
					WHEN '<download>1</download>' THEN 'Bestand "' + hist.NewValue.value('(/row/FileName)[1]', 'varchar(max)') + '" is gedownload.'
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Specificatie "' + hist.OldValue.value('(/row/SpecificationDate)[1]', 'varchar(10)') + '" is verwijderd bij declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
							ELSE CASE WHEN hist.OldValue.value('(/row/SpecificationSequence)[1]', 'varchar(max)') = hist.NewValue.value('(/row/SpecificationSequence)[1]', 'varchar(max)')
									THEN 'Specificatie "' + hist.NewValue.value('(/row/SpecificationDate)[1]', 'varchar(10)') + '" is opnieuw gegenereerd.'
									ELSE '...'
								 END
						 END
				END
			WHEN 'sub.tblDeclaration_Unknown_Source' THEN 
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Onbekende opleiding " ' + hist.NewValue.value('(/row/CourseName)[1]', 'varchar(max)') + '" is ingevuld bij declaratie ' + hist.NewValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Onbekende opleiding "' + hist.OldValue.value('(/row/CourseName)[1]', 'varchar(max)') + '" is verwijderd bij declaratie ' + hist.OldValue.value('(/row/DeclarationID)[1]', 'varchar(max)')
							ELSE '...'
						 END
				END
			WHEN 'auth.tblUser' THEN
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'De gebruiker is aangemaakt'
					ELSE CASE
							WHEN hist.OldValue.value('(/row/Initials)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Initials)[1]', 'varchar(max)')
								THEN 'De initialen zijn gewijzigd van "' + hist.OldValue.value('(/row/Initials)[1]', 'varchar(max)') + '" naar "' 
								+ hist.NewValue.value('(/row/Initials)[1]', 'varchar(max)') + '"' + CHAR(10)
							ELSE ''
						 END +
						 CASE
							WHEN hist.OldValue.value('(/row/Fullname)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Fullname)[1]', 'varchar(max)')
								THEN 'De naam is gewijzigd van "' + hist.OldValue.value('(/row/Fullname)[1]', 'varchar(max)') + '" naar "' 
								+ hist.NewValue.value('(/row/Fullname)[1]', 'varchar(max)') + '"' + CHAR(10)
							ELSE ''
						 END +
						 CASE
							WHEN hist.OldValue.value('(/row/Email)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Email)[1]', 'varchar(max)')
								THEN 'Het e-mailadres is gewijzigd van "' + hist.OldValue.value('(/row/Email)[1]', 'varchar(max)') + '" naar "' 
								+ hist.NewValue.value('(/row/Email)[1]', 'varchar(max)') + '"' + CHAR(10)
							ELSE ''
						 END + 
						 CASE
							WHEN hist.OldValue.value('(/row/Phone)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/Phone)[1]', 'varchar(max)')
								THEN 'Het telefoonnummer is gewijzigd van "' + hist.OldValue.value('(/row/Phone)[1]', 'varchar(max)') + '" naar "' 
								+ hist.NewValue.value('(/row/Phone)[1]', 'varchar(max)') + '"' + CHAR(10)
							ELSE ''
						 END + 
						 CASE
							WHEN hist.OldValue.value('(/row/FunctionDescription)[1]', 'varchar(max)') <> hist.NewValue.value('(/row/FunctionDescription)[1]', 'varchar(max)')
								THEN 'De functie is gewijzigd van "' + hist.OldValue.value('(/row/FunctionDescription)[1]', 'varchar(max)') + '" naar "' 
								+ hist.NewValue.value('(/row/FunctionDescription)[1]', 'varchar(max)') + '"'
							ELSE ''
						 END
				END				
			WHEN 'sub.tblJournalEntryCode' THEN
				CASE COALESCE(CAST(hist.OldValue AS varchar(MAX)), '') 
					WHEN '' THEN 'Specificatie "' + hist.NewValue.value('(/row/Specification/JournalEntryCode/ProcessDate)[1]', 'varchar(10)') + '" is toegevoegd aan notanummer ' + hist.NewValue.value('(/row/JournalEntryCode)[1]', 'varchar(max)')
					WHEN '<download>1</download>' THEN 'Bestand "' + hist.NewValue.value('(/row/FileName)[1]', 'varchar(max)') + '" is gedownload.'
					ELSE CASE COALESCE(CAST(hist.NewValue AS varchar(MAX)), '') 
							WHEN '' THEN 'Specificatie "' + hist.OldValue.value('(/row/Specification/JournalEntryCode/ProcessDate)[1]', 'varchar(10)') + '" is verwijderd bij notanummer ' + hist.OldValue.value('(/row/JournalEntryCode)[1]', 'varchar(max)')
							ELSE CASE WHEN hist.OldValue.value('(/row/JournalEntryCode)[1]', 'varchar(max)') = hist.NewValue.value('(/row/JournalEntryCode)[1]', 'varchar(max)')
									THEN 'Nota specificatie "' + hist.NewValue.value('(/row/JournalEntryCode)[1]', 'varchar(10)') + '" is opnieuw gegenereerd.'
									ELSE '...'
								 END
						 END
				END
			ELSE 'Onbekend'
		END AS ActionDescription
	FROM his.tblHistory hist
	LEFT JOIN auth.tblUser usr ON usr.UserID = hist.UserID
	WHERE ( @KeyID IS NULL OR hist.KeyID = @KeyID )
	  AND ( @TableName IS NULL 
		OR (@TableName <> 'sub.tblEmployer_Subsidy'
			AND hist.TableName = @TableName)
		OR (@TableName = 'sub.tblEmployer_Subsidy' 
			AND hist.UserID <> 1)
		  )
	  AND ISNULL(CAST(hist.OldValue AS varchar(max)), '') <> ISNULL(CAST(hist.NewValue AS varchar(max)), '')
	  AND ( hist.TableName <> 'osr.tblDeclaration' 
		OR ( hist.TableName = 'osr.tblDeclaration'
			AND CAST(hist.OldValue AS varchar(max)) IS NOT NULL
			AND CAST(hist.NewValue AS varchar(max)) IS NOT NULL ) )
	  AND ( hist.TableName <> 'evc.tblDeclaration' 
		OR ( hist.TableName = 'evc.tblDeclaration'
			AND CAST(hist.OldValue AS varchar(max)) IS NOT NULL
			AND CAST(hist.NewValue AS varchar(max)) IS NOT NULL ) )
	) AS sub1
ORDER BY 
		sub1.LogDate DESC,
		sub1.HistoryID DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== his.usphistory_List -==================================================================	*/
