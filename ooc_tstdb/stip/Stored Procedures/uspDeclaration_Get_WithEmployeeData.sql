
CREATE  PROCEDURE [stip].[uspDeclaration_Get_WithEmployeeData]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get declaration information with linked employees on bases of a DeclarationID.

	30-01-2020	Sander van Houten	OTIBSUB-1864	Provisional diplomadate does not need to be
                                        shown if the declaration is fully handled.
	27-01-2020	Sander van Houten	OTIBSUB-1852	Only take older StartDate from BPV if 
                                        it is the same course.
	17-12-2019	Sander van Houten	OTIBSUB-1781	Include BPV of related concerns.
	16-12-2019	Sander van Houten	OTIBSUB-1778	Don't show partitions of inactive or stopped 
                                        BPV's if the paidamount is NULL for that date.
	26-11-2019	Sander van Houten	OTIBSUB-1539	Don't show 'Voorlopige diplomadatum' when 
                                        ended without diploma and show Beëindiging STIP as a line
                                        when partitionstatus is 0024 (always just one record).
	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	25-10-2019	Jaap van Assenbergh	OTIBSUB-1647	Terugboekingen mogelijk maken per partitie
	22-10-2019	Sander van Houten	OTIBSUB-1634	Improved check on CanExtend, CanTerminate and
                                           ModifyUntil for ended declarations.
	13-09-2019	Sander van Houten	OTIBSUB-1567	Improved check on CanExtend.
	10-09-2019	Sander van Houten	OTIBSUB-1497	Added code for showing temporary diplomadate.
	09-09-2019	Jaap van Assenbergh	OTIBSUB-1548	Retour werkgever mag alleen als 
                                        er nog geen betaling is geweest.
	03-09-2019	Sander van Houten	OTIBSUB-1520	Added RequiresDiplomaUpload.
	20-08-2019	Sander van Houten	OTIBSUB-1496	Changed Diplomadatum into Diploma. 
	20-08-2019	Sander van Houten	OTIBSUB-1495	Show nominal duration with education. 
	16-08-2019	Sander van Houten	OTIBSUB-1176	Show BPV history from Horus. 
	08-08-2019	Sander van Houten	OTIBSUB-1453	New way of determining if a declaration 
										can be modified.
	05-08-2019	Sander van Houten	OTIBSUB-1129	Simplified CanReturnToEmployer field
										for performance.
	05-08-2019	Sander van Houten	OTIBSUB-1433	Added DateOfBirth to EmployeeName.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	CanDownloadSpecification when 
													Paymentrun_Declaration exists
	11-07-2019	Sander van Houten	OTIBSUB-1359	Added PartitionType 4 (Extension).
	08-07-2019	Sander van Houten	OTIBSUB-1319	Changed ModifyUntil terms.
	03-07-2019	Sander van Houten	OTIBSUB-1320	Changed CanReturnToEmployer terms.
	03-07-2019	Sander van Houten	OTIBSUB-1149	Changed CanExtend terms.
	27-06-2019	Sander van Houten	OTIBSUB-1148	Added info from stip.tblDeclaration_BPV.
	26-06-2019	Sander van Houten	OTIBSUB-1149	Added OriginalEndDate.
	18-06-2019	Sander van Houten	OTIBSUB-1147	Added STIP StartDate part.
	08-06-2019	Sander van Houten	OTIBSUB-1114	Added status 0023 for Accept and Reject.
	28-05-2019	Sander van Houten	OTIBSUB-1129	Corrected bit-columns.
	28-05-2019	Sander van Houten	OTIBSUB-998		Added EmployerNumber.
	20-05-2019	Sander van Houten	OTIBSUB-998		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 412378,
        @UserID			int = 7
--  */

/*  Max of ReversalPaymentID.   */
DECLARE	@MaxReversalPaymentID	int,
        @GetDate                datetime = GETDATE()

SELECT	@MaxReversalPaymentID = ReversalPaymentID
FROM	sub.tblDeclaration_ReversalPayment
WHERE	DeclarationID = @DeclarationID
  AND	PaymentRunID IS NULL

/*  Determine Role(s) of current user.  */
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

/*  Get status of active partition (OTIBSUB-1539).   */
DECLARE	@ActivePartitionStatus	varchar(4)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		

/*  Determine diplomadate.  */
DECLARE @RC					int,
		@EmployerNumber		varchar(6),
		@EmployeeNumber		varchar(8),
		@EducationID		int,
		@StartDate			date,
		@EndDate			date,
		@NominalDuration	tinyint,
        @OriginalStartDate  date

DECLARE @tblDeclarationSorted	stip.uttUltimateDiplomaDate,
		@UltimateDiplomaDate	date

SELECT	@EmployerNumber = EmployerNumber,
		@EmployeeNumber = EmployeeNumber,
		@EducationID = EducationID,
		@StartDate = StartDate,
		@EndDate = EndDate,
		@NominalDuration = ISNULL(NominalDuration, 0),
        @OriginalStartDate = OriginalStartDate
FROM	stip.viewDeclaration
WHERE	DeclarationID = @DeclarationID

IF @NominalDuration = 0
BEGIN
	SET	@UltimateDiplomaDate = '19000101'
END
ELSE
BEGIN
	INSERT INTO @tblDeclarationSorted
		(
			UltimateDiplomaDate,
			RecordID,
			SubsidySchemeID,
			EmployerNumber,
			StartDate,
			EndDate,
			DeclarationID,
			ExtensionID,
			PauseYears,
			PauseMonths,
			PauseDays,
			PauseYearsAll,
			PauseMonthsAll,
			PauseDaysAll
		)
	EXECUTE @RC = [stip].[uspCalculateUltimateDiplomaDate]
		@DeclarationID,
		@EmployerNumber,
		@EmployeeNumber,
		@EducationID,
		@StartDate,
		@EndDate

	SELECT	TOP 1
			@UltimateDiplomaDate = UltimateDiplomaDate
	FROM	@tblDeclarationSorted
END

PRINT @UltimateDiplomaDate

/*	Select Resultset 1.	*/
SELECT
		sel.SubsidySchemeID,
		sel.SubsidySchemeName,
		sel.DeclarationDate,
		sel.DeclarationID,
		sel.JournalEntryCode,
		sel.EmployerNumber,
		sel.EmployeeNumber,
		sel.EmployeeName,
		sel.MentorID,
		sel.MentorName,
		sel.MentorEmail,
		sel.InstituteID,
		sel.InstituteName,
		sel.CourseID,
		sel.CourseName,
		sel.DeclarationStatus,
		sel.LastExtensionID,
		sel.StartDateExtension,
		sel.StartDate,
		sel.EndDate,
		sel.OriginalEndDate,
		sel.DeclarationAmount,
		sel.ApprovedAmount,
		sel.StatusReason,
		sel.InternalMemo,
		sel.TerminationDate,
		sel.TerminationReason,
		sel.[Partitions],
		sel.ReversalPaymentReason,
		CAST(CASE WHEN sel.ModifyUntil IS NOT NULL 
				THEN 1 
				ELSE 0 
			  END AS bit) CanModify,
		sel.ModifyUntil,
		sel.CanAccept,
		sel.CanDownloadSpecification,
		sel.CanExtend,
		sel.CanReject,
		sel.CanReturnToEmployer,
		sel.GetRejectionReason,
		sel.ShowStatusReason,
		sel.CanReverse,
		sel.CanSetToInvestigation,
		sel.CanTerminate,
		sel.StartDate_BPV,
		sel.EndDate_BPV,
		sel.Extension_BPV,
		sel.TerminationCode_BPV,
		sel.TerminationReason_BPV,
		sel.DiplomaUploadUntil
FROM
		(
			SELECT
					d.SubsidySchemeID,
					s.SubsidySchemeName,
					d.DeclarationDate,
					d.DeclarationID,
					d.EmployerNumber,
					pad.JournalEntryCode,
					emp.EmployeeNumber,
					emp.FullName																		EmployeeName,
					d.LastMentorID																		MentorID,
					d.LastMentorFullName																MentorName,
					men.Email																			MentorEmail,
					di.InstituteID,
					di.InstituteName,
					d.EducationID																		CourseID,
					d.EducationName + CASE WHEN @OTIB_User = 1
										THEN CASE WHEN d.NominalDuration IS NULL 
												THEN ' (N=?)'
												ELSE ' (N=' + CAST(d.NominalDuration AS varchar(2)) + ')'
											 END
										ELSE ''
									  END																CourseName,
					d.DeclarationStatus,
					d.LastExtensionID,
					d.StartDate																			StartDateExtension,
					d.OriginalStartDate																	StartDate,
					d.EndDate,
					d.OriginalEndDate,
					d.DeclarationAmount,
					ISNULL(dtp.TotalPaidAmount, 0.00)													ApprovedAmount,
					d.StatusReason,
					d.InternalMemo,
					d.TerminationDate,
					d.TerminationReason,
					(
						CASE WHEN @OTIB_User = 1
							THEN 
						(
							SELECT	
									sub.PartitionType,
									sub.PartitionDate,
									sub.PartitionDescription,
									sub.PartitionAmount,
									sub.PartitionStatus,
									sub.SpecificationSequence,
									sub.PartitionActions
							FROM	(
										SELECT  1														PartitionType,
												CASE WHEN CAST(dbpv.StartDate_BPV AS date) < CAST(d.OriginalStartDate AS date)
                                                      AND dbpv.CourseID = d.EducationID
													THEN CAST(dbpv.StartDate_BPV AS date)
													ELSE CAST(d.OriginalStartDate AS date)
												END														PartitionDate,
												'Startdatum'											PartitionDescription,
												NULL													PartitionAmount,
												NULL													PartitionStatus,
												NULL													SpecificationSequence,
												NULL													PartitionActions

										UNION ALL

										SELECT	sub2.PartitionType,
												sub2.PartitionDate,
												CASE sub2.PartitionDescription
													WHEN 'Diploma' THEN sub2.PartitionDescription
													WHEN 'Voorlopige diplomadatum' THEN sub2.PartitionDescription
													ELSE sub2.PartitionDescription 
														+ CAST(ROW_NUMBER() OVER (PARTITION BY sub2.PartitionDescription 
                                                                                      ORDER BY sub2.PartitionDate) AS varchar(2))
												END														PartitionDescription,
												sub2.PartitionAmount,
												sub2.PartitionStatus,
												sub2.SpecificationSequence,
												sub2.PartitionActions
										FROM	(   -- STIP.
													SELECT	2														PartitionType,
															CAST(dep.PaymentDate AS date)							PartitionDate,
															CASE WHEN CAST(dep.PaymentDate AS date) = d.DiplomaDate
																THEN 'Diploma'
																ELSE 'Peildatum '
															END														PartitionDescription,
															REPLACE(
																CAST(
																	CAST(CASE WHEN PartitionStatus = '0029'
																			THEN 0 
																			ELSE dep.PartitionAmount END
																		AS decimal(19,2))
																AS varchar(20)), '.', ',')
																													PartitionAmount,
															dep.PartitionStatus,
															CAST(CASE WHEN dsp.Specification IS NULL AND jec.Specification IS NULL					
																	THEN 0
																	ELSE CASE WHEN @OTIB_User = 1
																			THEN COALESCE(dsp.SpecificationSequence, 1)
																			ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0017') 
																					THEN COALESCE(dsp.SpecificationSequence, 1)
																					ELSE 0
																				 END
																			END
																	END AS bit)										SpecificationSequence,
															(
                                                                SELECT sub3.*
                                                                FROM    (
                                                                            SELECT	
                                                                                    3										PartitionType,
                                                                                    CAST(ema.SentDate AS date)				PartitionDate,
                                                                                    CASE sep.LetterType
                                                                                        WHEN 1 THEN 'Eerste'
                                                                                        WHEN 2 THEN 'Tweede'
                                                                                        WHEN 3 THEN 'Derde'
                                                                                        ELSE ''
                                                                                    END + ' e-mail verstuurd'				PartitionDescription
                                                                            FROM	stip.tblEmail_Partition sep
                                                                            INNER JOIN eml.tblEmail ema ON ema.EmailID = sep.EmailID
                                                                            WHERE	sep.PartitionID = dep.PartitionID

                                                                            UNION ALL

                                                                            SELECT	
                                                                                    3										PartitionType,
                                                                                    CAST(sep.ReplyDate AS date)				PartitionDate,
                                                                                    'Antwoord ontvangen op ' + 
                                                                                    CASE sep.LetterType
                                                                                        WHEN 1 THEN 'eerste'
                                                                                        WHEN 2 THEN 'tweede'
                                                                                        WHEN 3 THEN 'derde'
                                                                                        ELSE ''
                                                                                    END + ' e-mail: ' + 
                                                                                    aps.SettingDescription		            PartitionDescription
                                                                            FROM	stip.tblEmail_Partition sep
                                                                            INNER JOIN eml.tblEmail ema 
                                                                            ON      ema.EmailID = sep.EmailID
                                                                            INNER JOIN sub.tblApplicationSetting aps
                                                                            ON      aps.SettingName = 'TerminationCode'
                                                                            AND     aps.SettingCode = sep.ReplyCode
                                                                            WHERE	sep.PartitionID = dep.PartitionID
                                                                            AND     sep.ReplyCode IS NOT NULL
                                                                        ) sub3
                                                                ORDER BY
                                                                        sub3.PartitionDate
																FOR XML PATH('PartitionAction'), TYPE
															)													PartitionActions
													FROM	sub.tblDeclaration_Partition dep
													LEFT JOIN sub.tblPaymentRun_Declaration pad
													ON		pad.PartitionID = dep.PartitionID
													LEFT JOIN sub.tblDeclaration_Specification dsp
													ON		dsp.DeclarationID = pad.DeclarationID
													AND		dsp.PaymentRunID = pad.PaymentRunID
													LEFT JOIN sub.tblJournalEntryCode jec
													ON		jec.JournalEntryCode = pad.JournalEntryCode
													WHERE	dep.DeclarationID = d.DeclarationID
                                                    AND     ( dep.PartitionStatus <> '0024'
                                                            OR  (   dep.PartitionStatus = '0024'
                                                                AND d.DeclarationStatus IN ('0030', '0031')
                                                                )
                                                            )

													UNION ALL

                                                    -- BPV.
													SELECT	DISTINCT
                                                            2														PartitionType,
															CASE WHEN dtg.ReferenceDate < d.OriginalStartDate
																THEN CAST(dtg.ReferenceDate AS date)
																ELSE CAST(dtg.PaymentDate AS date)
															END														PartitionDate,
															CASE WHEN dtg.LastPayment = 'J' AND COALESCE(dtg.AmountPaid, 0.00) <> 0.00
																THEN 'Diploma'
																ELSE 'Peildatum '
															END														PartitionDescription,
															REPLACE(CAST(CAST(dtg.PaymentAmount AS decimal(19,2)) AS varchar(20)), '.', ',')
																													PartitionAmount,
															CASE WHEN dtg.PaymentDate IS NULL
                                                                THEN '0001'
                                                                ELSE CASE WHEN dtg.AmountPaid IS NULL
                                                                        THEN '0002'
                                                                        ELSE '0012'
                                                                     END
															END														PartitionStatus,
															NULL													SpecificationSequence,
															NULL													PartitionActions
													FROM	hrs.viewBPV bpv1 
													INNER JOIN hrs.viewBPV_DTG dtg
													ON		dtg.DSR_ID = bpv1.DSR_ID
                                                    LEFT JOIN sub.tblEmployer_ParentChild epc1 
                                                    ON      epc1.EmployerNumberParent = bpv1.EmployerNumber
                                                    LEFT JOIN sub.tblEmployer_ParentChild epc2 
                                                    ON      epc2.EmployerNumberChild = bpv1.EmployerNumber
													WHERE	bpv1.EmployeeNumber = dem.EmployeeNumber
													AND		bpv1.CourseID = d.EducationID
													AND		(
																(   dtg.ReferenceDate < d.OriginalStartDate
                                                                AND (   COALESCE(dtg.AmountPaid, 0.00) <> 0.00
                                                                    OR  bpv1.StatusCode IN (1, 2)
                                                                    )
                                                                )
															OR	(
																	COALESCE(dtg.PaymentDate, d.OriginalStartDate) < d.OriginalStartDate
																AND	COALESCE(dtg.AmountPaid, 0.00) <> 0.00
																)
															)
                                                    AND		( bpv1.EmployerNumber = d.EmployerNumber
                                                        OR	  ( epc1.EmployerNumberChild = d.EmployerNumber 
                                                            AND epc1.startdate <= @GetDate
                                                            AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
                                                              )
                                                        OR	  ( epc2.EmployerNumberParent = d.EmployerNumber
                                                            AND epc2.startdate <= @GetDate
                                                            AND COALESCE(epc1.enddate, @GetDate+1) > @GetDate
                                                              )
                                                            )

													UNION ALL

                                                    -- Provisional diploma date.
													SELECT	DISTINCT
															2														PartitionType,
															CAST(@UltimateDiplomaDate AS date)						PartitionDate,
															'Voorlopige diplomadatum'								PartitionDescription,
															NULL													PartitionAmount,
															NULL,
															NULL													SpecificationSequence,
															NULL													PartitionActions
													FROM	sub.tblDeclaration decl
													LEFT JOIN stip.tblDeclaration stpd
													ON		stpd.DeclarationID = decl.DeclarationID
													AND 	stpd.TerminationReason IN ('0004', '0005')
													LEFT JOIN sub.tblDeclaration_Partition dep
													ON		dep.DeclarationID = decl.DeclarationID
													AND		(
																dep.PaymentDate = d.DiplomaDate
															OR	dep.PaymentDate = @UltimateDiplomaDate
															)
													WHERE	decl.DeclarationID = d.DeclarationID
                                                    AND     decl.DeclarationStatus <> '0035'    --Afgehandeld
													AND		stpd.DeclarationID IS NULL
													AND		dep.PartitionID IS NULL
													AND		@NominalDuration > 0
												) AS sub2

										UNION ALL

										SELECT  4														PartitionType,
												CAST(dex.StartDate AS date)								PartitionDate,
												'Verlenging STIP'										PartitionDescription,
												NULL													PartitionAmount,
												NULL													PartitionStatus,
												NULL													SpecificationSequence,
												NULL													PartitionActions
										FROM	sub.tblDeclaration_Extension dex
										WHERE	dex.DeclarationID = d.DeclarationID
									
										UNION ALL

										SELECT  DISTINCT 
												4														PartitionType,
												CAST(d.OriginalStartDate AS date)						PartitionDate,
												CASE WHEN ISNULL(bpv2.TypeBPV, '') = ''
													THEN 'Verlenging BPV'
													ELSE
														'Verlenging ' + bpv2.TypeBPV + ' BPV'
												END														PartitionDescription,
												NULL													PartitionAmount,
												NULL													PartitionStatus,
												NULL													SpecificationSequence,
												NULL													PartitionActions
										FROM	hrs.viewBPV bpv2
										WHERE	bpv2.EmployeeNumber = bpv.EmployeeNumber
										AND		bpv2.EmployerNumber = bpv.EmployerNumber
										AND		bpv2.CourseID = bpv.CourseID

										UNION ALL

										SELECT  4														PartitionType,
												CAST(d.OriginalStartDate AS date)						PartitionDate,
												'Geen nominale duur bekend bij de opleiding'			PartitionDescription,
												NULL													PartitionAmount,
												NULL													PartitionStatus,
												NULL													SpecificationSequence,
												NULL													PartitionActions
										FROM	stip.viewDeclaration decl
										WHERE	decl.DeclarationID = d.DeclarationID
										AND		COALESCE(d.NominalDuration, 0) = 0
										AND		@OTIB_User = 1

										UNION ALL

										SELECT  DISTINCT 
												4														PartitionType,
												CAST(dep.PaymentDate AS date)						    PartitionDate,
												'Beëindiging STIP'  									PartitionDescription,
												NULL													PartitionAmount,
												NULL													PartitionStatus,
												NULL													JournalEntryCode,
												NULL													PartitionActions
										FROM	stip.tblDeclaration stpd
                                        INNER JOIN sub.tblDeclaration_Partition dep 
                                        ON      dep.DeclarationID = stpd.DeclarationID
										WHERE	stpd.DeclarationID = d.DeclarationID
                                        AND     stpd.DiplomaDate IS NULL
                                        AND     dep.PartitionStatus = '0024'    -- Ended

									) AS sub
							ORDER BY 
									sub.PartitionDate,
									sub.PartitionType
							FOR XML PATH('Partition'), ROOT('Partitions')
						)
					ELSE
						(
							SELECT NULL
							FOR XML PATH('Partitions')
						)
					END
					)																					[Partitions],
					rev.ReversalPaymentReason															ReversalPaymentReason,
					CAST(CASE WHEN pad.DeclarationID IS NOT NULL 
                            THEN 1
                            ELSE 0
						 END	AS bit)																		CanDownloadSpecification,
					CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0 AND @ActivePartitionStatus <> '0016'
							THEN 0
							ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0014', '0016') 
									THEN 1 
									ELSE 0 
								 END
						 END AS bit)																	CanReverse,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009') 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanSetToInvestigation,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022', '0023') 
							THEN 1
							ELSE 0
						  END AS bit)																	CanAccept,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022', '0023') 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanReject,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022')
								AND dtp.DeclarationID IS NULL 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanReturnToEmployer,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')
							THEN 1 
							ELSE 0 
						 END AS bit)																	GetRejectionReason,
					CAST(CASE WHEN @ActivePartitionStatus IN ('0012', '0013', '0014', '0015')
							THEN 1 
							ELSE 0 
						 END AS bit)																	ShowStatusReason,
					-- An extension can only be entered if the STIP has not already been ended
					-- and then only in the last 6 months of the last STIP period.
					CAST(CASE WHEN @ActivePartitionStatus <> '0017'
                               AND d.TerminationDate IS NULL
							   AND GETDATE() >= DATEADD(MM, -6, d.EndDate) 
							THEN 1 
							ELSE 0 
						 END AS bit)																	CanExtend,
					CAST(CASE WHEN ISNULL(@ActivePartitionStatus, '0001') <> '0017'
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
					aps.SettingDescription																TerminationReason_BPV,
					CASE WHEN d.TerminationReason = '0006' AND dat.AttachmentID IS NULL	-- Beëindigd met diploma.
						THEN CASE WHEN DATEADD(MONTH, 6, d.TerminationDate) >= GETDATE() 
								THEN DATEADD(MONTH, 6, d.TerminationDate)
								ELSE NULL
							 END	
						ELSE NULL
					END																					DiplomaUploadUntil
			FROM	stip.viewDeclaration d
			INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
			INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = d.DeclarationID
			INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
			INNER JOIN sub.viewDeclaration_Institute di ON di.DeclarationID = d.DeclarationID
			LEFT JOIN sub.tblMentor men ON men.MentorID = d.LastMentorID
			LEFT JOIN sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = d.DeclarationID
			LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
			LEFT JOIN sub.tblDeclaration_ReversalPayment rev ON rev.ReversalPaymentID = @MaxReversalPaymentID
			LEFT JOIN sub.viewDeclaration_TotalPaidAmount_2019 dtp ON dtp.DeclarationID = d.DeclarationID
			LEFT JOIN stip.tblDeclaration_BPV dbpv ON dbpv.DeclarationID = d.DeclarationID
			LEFT JOIN hrs.viewBPV bpv 
			ON 		bpv.EmployeeNumber = d.EmployeeNumber
			AND 	bpv.CourseID = d.EducationID
			AND 	bpv.StartDate = dbpv.StartDate_BPV
			LEFT JOIN sub.tblApplicationSetting aps
			ON	    aps.SettingName = 'TerminationCode'
			AND	    aps.SettingCode = dbpv.TerminationReason
			LEFT JOIN sub.tblDeclaration_Attachment dat
			ON	    dat.DeclarationID = d.DeclarationID
			AND     dat.DocumentType = 'Certificate'
			WHERE	d.DeclarationID = @DeclarationID
		) sel

-- Result set 2: All linked employees.
SELECT	emp.EmployeeNumber, 
		emp.FullName + ' (' + CONVERT(varchar(10), emp.DateOfBirth, 105) + ')'	AS EmployeeName,
		der.ReversalPaymentID,
		'Meegenomen in de betalingsrun van ' + CONVERT(varchar(10), par.RunDate, 105) AS PaymentRun
FROM sub.tblDeclaration_Employee dee
INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der 
		ON	der.DeclarationID = dee.DeclarationID
		AND	der.EmployeeNumber = dee.EmployeeNumber
LEFT JOIN sub.tblDeclaration_ReversalPayment drp 
		ON	drp.DeclarationID = der.DeclarationID
		AND	drp.ReversalPaymentID = der.ReversalPaymentID
LEFT JOIN sub.tblDeclaration_Partition_ReversalPayment dprp 
		ON	dprp.PartitionID = der.PartitionID
		AND	dprp.ReversalPaymentID = der.ReversalPaymentID
LEFT JOIN  sub.tblPaymentRun par ON	par.PaymentRunID = drp.PaymentRunID
WHERE	dee.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== stip.uspDeclaration_Get_WithEmployeeData ==============================================	*/
