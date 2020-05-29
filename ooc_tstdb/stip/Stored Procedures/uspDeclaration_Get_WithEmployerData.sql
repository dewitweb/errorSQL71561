
CREATE PROCEDURE [stip].[uspDeclaration_Get_WithEmployerData]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	LET OP:		Deze usp wordt ook aangeroepen in uspDeclaration_Specification_Upd.
				Indien nieuwe velden in de result set dan ook de tabelvariabele aanpassen in 
				uspDeclaration_Specification_Upd!

	Purpose:	Get declaration information on bases of a DeclarationID.
	Note		Jaap van Assenbergh
				The procedure is also executed by other procedures. Adding columns must also 
				be done in the table variables in the other procedures.

	28-01-2020	Jaap van Assenbergh	OTIBSUB-1178	Betalingen na diplomadatum niet uitkeren en wel terugvorderen
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	22-10-2019	Sander van Houten	OTIBSUB-1634	Improved check on CanExtend, CanTerminate 
                                        and ModifyUntil for ended declarations.
	13-09-2019	Sander van Houten	OTIBSUB-1567	Improved check on CanExtend.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	CanDownloadSpecification when 
                                        Paymentrun_Declaration exists.
	09-09-2019	Jaap van Assenbergh	OTIBSUB-1548	Retour werkgever mag alleen als 
                                        er nog geen betaling is geweest.
	08-07-2019	Sander van Houten	OTIBSUB-1319	Changed ModifyUntil terms.
	03-07-2019	Sander van Houten	OTIBSUB-1320	Changed CanReturnToEmployer terms.
	03-07-2019	Sander van Houten	OTIBSUB-1149	Changed CanExtend terms.
	26-06-2019	Sander van Houten	OTIBSUB-1149	Added OriginalEndDate.
	18-06-2019	Sander van Houten	OTIBSUB-1147	Added STIP StartDate part.
	13-06-2019	Sander van Houten	OTIBSUB-1148	Added info from stip.tblDeclaration_BPV.
	20-05-2019	Sander van Houten	OTIBSUB-998		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 406102,
        @UserID			int = 1
--  */

/* Determine Role(s) of current user.   */
DECLARE @OTIB_User                  bit = 0,
        @SubsidySchemeID            int,
        @EmployerNumber             varchar(6),
        @MaxReversalPaymentID	    int,
        @CurrentDeclarationStatus   varchar(20)

SELECT	@MaxReversalPaymentID = ReversalPaymentID
FROM	sub.tblDeclaration_ReversalPayment
WHERE	DeclarationID = @DeclarationID
AND	    PaymentRunID IS NULL

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

SELECT	@SubsidySchemeID = SubsidySchemeID, 
        @EmployerNumber = EmployerNumber,
        @CurrentDeclarationStatus = DeclarationStatus
FROM	sub.tblDeclaration
WHERE	DeclarationID = @DeclarationID

/* Get status of active partition (OTIBSUB-1539).   */
DECLARE	@ActivePartitionStatus	varchar(20)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		

IF @ActivePartitionStatus IS NULL
BEGIN
    SET @ActivePartitionStatus = @CurrentDeclarationStatus
END

/*	Select Declaration data.	*/
SELECT	DISTINCT
		d.DeclarationID,
		d.DeclarationID																		DeclarationNumber,
		d.EmployerNumber,
		e.EmployerName,
		e.IBAN,
		d.SubsidySchemeID,
		s.SubsidySchemeName,
		d.DeclarationDate,
		di.InstituteID,
		di.InstituteName,
		d.EducationID,
		d.EducationName,
		CAST(d.DeclarationAmount AS decimal(19,2))											DeclarationAmount,
		ISNULL(dtp.TotalPaidAmount, 0.00)													ApprovedAmount,
		d.DeclarationStatus,
		d.DiplomaDate,
		d.TerminationDate,
		d.TerminationReason,
		d.StartDate,
		d.EndDate,
		d.OriginalEndDate,
		men.MentorID,
		men.Phone																			MentorPhone,
		men.Email																			MentorEmail,
		CAST(ISNULL(dtp.TotalPaidAmount, 0) AS decimal(19,2))								ApprovedAmount,
		CASE DeclarationStatus 
			WHEN '0008' THEN inv.InvestigationMemo
			ELSE d.StatusReason
		END																					StatusReason,
		d.InternalMemo,
		(
			SELECT	
					sub.PartitionDate,
					sub.PartitionDescription,
					sub.PartitionAmount,
					sub.PartitionStatus,
					sub.SpecificationSequence,
					sub.PartitionActions
			FROM	(
						SELECT  1														PartitionType,
								CAST(d.OriginalStartDate AS date)						PartitionDate,
								'Startdatum'											PartitionDescription,
								NULL													PartitionAmount,
								NULL													PartitionStatus,
								NULL													SpecificationSequence,
								NULL													PartitionActions

						UNION ALL

						SELECT	2														PartitionType,
								CAST(dep.PaymentDate AS date)							PartitionDate,
								CASE WHEN CAST(dep.PaymentDate AS date) = d.DiplomaDate
									THEN 'Diplomadatum'
									ELSE 'Peildatum ' + CAST(ROW_NUMBER() OVER (ORDER BY dep.PaymentDate) AS varchar(2))
								END														PartitionDescription,
								REPLACE(CAST(CAST(dep.PartitionAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
																						PartitionAmount,
								dep.PartitionStatus,
								CAST(CASE WHEN dsp.Specification IS NULL AND jec.Specification IS NULL
										THEN 0
										ELSE CASE WHEN @OTIB_User = 1
												THEN COALESCE(dsp.SpecificationSequence, 1)
												ELSE CASE WHEN dep.PartitionStatus IN ('0012', '0014', '0017') 
														THEN COALESCE(dsp.SpecificationSequence, 1)
														ELSE 0
													 END
											 END
									 END AS bit)										SpecificationSequence,
								(
									SELECT	
											3										PartitionType,
											CAST(ema.SentDate AS date)				PartitionDate,
											CASE ROW_NUMBER() OVER (ORDER BY ema.SentDate)
												WHEN 1 THEN 'Eerste'
												WHEN 2 THEN 'Tweede'
												WHEN 3 THEN 'Derde'
												ELSE ''
											END + ' e-mail verstuurd'				PartitionDescription
									FROM	stip.tblEmail_Partition sep
									INNER JOIN eml.tblEmail ema
									ON		ema.EmailID = sep.EmailID
									WHERE	sep.PartitionID = dep.PartitionID
									FOR XML PATH('PartitionAction'), TYPE
								)													PartitionActions
						FROM	sub.tblDeclaration_Partition dep
						LEFT JOIN sub.tblPaymentRun_Declaration pad
						ON	    pad.PartitionID = dep.PartitionID
						LEFT JOIN sub.tblJournalEntryCode jec
						ON      jec.JournalEntryCode = pad.JournalEntryCode
						LEFT JOIN sub.tblDeclaration_Specification dsp
						ON	    dsp.DeclarationID = pad.DeclarationID
						AND	    dsp.PaymentRunID = jec.PaymentRunID
						LEFT JOIN stip.tblEmail_Partition sep
						ON	    sep.PartitionID = dep.PartitionID
						LEFT JOIN eml.tblEmail ema
						ON	    ema.EmailID = sep.EmailID
						WHERE	dep.DeclarationID = d.DeclarationID
					) AS sub
			ORDER BY 
					sub.PartitionDate,
					sub.PartitionType

			FOR XML PATH('Partition'), ROOT('Partitions')
		)																					[Partitions],
		CAST(CASE WHEN pad.DeclarationID IS NOT NULL 
					THEN 1
					ELSE 0
			END	AS bit)																		CanDownloadSpecification,
		CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0 
                   AND @ActivePartitionStatus <> '0016'
				THEN 0
				ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0016')
						THEN 1 
						ELSE 0 
					 END
			 END AS bit)																	CanReverse,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009', '0022', '0024')
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanSetToInvestigation,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022', '0023', '0024')
                THEN 1
				ELSE 0
			  END	AS bit)																	CanAccept,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022', '0023', '0024')
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanReject,
        CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022', '0024')
				   AND dtp.DeclarationID IS NULL 
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanReturnToEmployer,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')
				THEN 1 
				ELSE 0 
			 END AS bit)																	GetRejectionReason,
		-- An extension can only be entered if the STIP has not already been ended
		-- and then only in the last 6 months of the last STIP period.
		CAST(CASE WHEN NOT EXISTS (
                                    SELECT  1 
                                    FROM    sub.tblDeclaration_Partition dep 
                                    WHERE   dep.DeclarationID = d.DeclarationID 
                                    AND     dep.PartitionStatus = '0017'
                                  )
                   AND d.TerminationDate IS NULL
				   AND GETDATE() >= DATEADD(MM, -6, d.EndDate) 
				THEN 1 
				ELSE 0 
				END AS bit)																	CanExtend,
		CAST(CASE WHEN NOT EXISTS (
                                    SELECT  1 
                                    FROM    sub.tblDeclaration_Partition dep 
                                    WHERE   dep.DeclarationID = d.DeclarationID 
                                    AND     dep.PartitionStatus = '0017'
                                  )
                   AND d.TerminationDate IS NULL
				THEN 1 
				ELSE 0 
				END AS bit)																	CanTerminate,
        CASE WHEN dbpv.DeclarationID IS NOT NULL
            THEN CASE WHEN d.DeclarationStatus = '0019'	-- Terug naar werkgever.
                    THEN CASE WHEN DATEADD(MM, 6, d.StartDate) > CAST(GETDATE() AS date)
                            THEN DATEADD(MM, 6, d.StartDate)
                            ELSE CAST(GETDATE() AS date)
                            END
                    ELSE NULL
                    END
            ELSE CASE WHEN d.TerminationDate IS NOT NULL
                    THEN NULL
                    ELSE CASE WHEN d.LastExtensionID IS NULL 
                            THEN CASE WHEN (SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                            FROM	sub.tblDeclaration_partition dep
                                            WHERE	dep.DeclarationID = d.DeclarationID
                                            ) <= CAST(GETDATE() AS date)
                                    THEN NULL
                                    WHEN (	SELECT	COUNT(1)
                                            FROM	sub.tblDeclaration_partition dep
                                            WHERE	dep.DeclarationID = d.DeclarationID
                                        ) = 0
                                    THEN CASE WHEN DATEADD(MM, 6, d.StartDate) > CAST(GETDATE() AS date)
                                            THEN DATEADD(MM, 6, d.StartDate)
                                            ELSE CAST(GETDATE() AS date)
                                            END
                                    ELSE (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                            FROM	sub.tblDeclaration_partition dep
                                            WHERE	dep.DeclarationID = d.DeclarationID
                                            )
                                END
                            ELSE CASE WHEN (SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                            FROM	sub.tblDeclaration_Extension dex
                                            INNER JOIN sub.tblDeclaration_Partition dep
                                            ON		dep.DeclarationID = dex.DeclarationID
                                            WHERE	dex.ExtensionID = d.LastExtensionID
                                            AND		dep.PaymentDate >= dex.StartDate
                                            ) <= CAST(GETDATE() AS date)
                                    THEN NULL 
                                    ELSE (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
                                            FROM	sub.tblDeclaration_Extension dex
                                            INNER JOIN sub.tblDeclaration_Partition dep
                                            ON		dep.DeclarationID = dex.DeclarationID
                                            WHERE	dex.ExtensionID = d.LastExtensionID
                                            AND		dep.PaymentDate >= dex.StartDate
                                        )
                                    END
                            END
                    END
        END																					ModifyUntil,
		dbpv.StartDate_BPV,
		dbpv.EndDate_BPV,
		dbpv.Extension																		Extension_BPV,
		dbpv.TerminationReason																TerminationCode_BPV,
		aps.SettingDescription																TerminationReason_BPV
		FROM	stip.viewDeclaration d
		INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
		INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
		INNER JOIN sub.tblEmployer e ON e.EmployerNumber = d.EmployerNumber
		INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
		INNER JOIN  sub.viewDeclaration_Institute di ON di.DeclarationID = d.DeclarationID
		LEFT JOIN sub.tblMentor men ON men.MentorID = d.LastMentorID
		LEFT JOIN  sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = d.DeclarationID
		LEFT JOIN  sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
		LEFT JOIN  sub.tblDeclaration_ReversalPayment rev ON rev.ReversalPaymentID = @MaxReversalPaymentID
		LEFT JOIN  sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
		LEFT JOIN 
			(	
				SELECT	DeclarationID, MAX(InvestigationDate) AS MaxInvestigationDate 
				FROM	sub.tblDeclaration_Investigation
				GROUP BY DeclarationID
			) iMax ON iMax.DeclarationID = d.DeclarationID
		LEFT JOIN sub.tblDeclaration_Investigation inv 
		ON	    inv.DeclarationID = iMax.DeclarationID 
		AND     inv.InvestigationDate = iMax.MaxInvestigationDate
		LEFT JOIN stip.tblDeclaration_BPV dbpv ON dbpv.DeclarationID = d.DeclarationID
		LEFT JOIN sub.tblApplicationSetting aps
		ON	    aps.SettingName = 'TerminationCode'
		AND	    aps.SettingCode = dbpv.TerminationReason
WHERE	d.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Get_WithEmployerData ==============================================	*/
