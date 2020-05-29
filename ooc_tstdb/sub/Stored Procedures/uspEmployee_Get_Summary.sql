CREATE PROCEDURE [sub].[uspEmployee_Get_Summary]
@EmployeeNumber		varchar(8),
@UserID				int
AS
/*	==========================================================================================
	Purpose:	List all declarationdata for employee.

	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	22-10-2019	Sander van Houten	OTIBSUB-1634	Improved check on ModifyUntil 
                                           for ended declarations.
	15-08-2019	Sander van Houten	OTIBSUB-1472	Removed links to specification in 
										determining value for CanDownloadSpecification while
										this sometimes caused multiple records per declaration.
	08-08-2019	Sander van Houten	OTIBSUB-1454	Altered ModifyUntil and added CanModify.
	08-08-2019	Sander van Houten	OTIBSUB-1437	Solved duplicate records issue.
	16-07-2019	Jaap van Assenbergh	OTIBSUB-1373	Specificatie op declaratieniveau 
										of op verzamelnota.
	21-02-2019	Sander van Houten	OTIBSUB-792		Manier van vastlegging terugboeking 
										bij werknemer veranderen.
	17-01-2019	Sander van Houten	OTIBSUB-678		Show CanDownloadSpecification on 
										bases of RoleID.
	21-11-2018	Jaap van Assenbergh	OTIBSUB-419		Update declaration only when 
										startdate > Now AND status 0001.
	30-10-2018	Jaap van Assenbergh	OTIBSUB-385		Deleted parameter @SubsidySchemeID and
										Added field SubsidySchemeID on recordset.
	11-09-2018	Jaap van Assenbergh	OTIBSUB-243		Added Date ModifyUntil
	27-08-2018	Sander van Houten	OTIBSUB-48		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Determine Role(s) of current user.
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

-- Select declaration data
SELECT	sel.DeclarationID,
		sel.SubsidySchemeID,
		sel.DeclarationDate,
		sel.CourseName,
		sel.DeclarationAmount,
		sel.ApprovedAmount,
		sel.DeclarationStatus,
		CAST(CASE WHEN sel.ModifyUntil IS NOT NULL 
					OR sel.DeclarationStatus = '0019'
				THEN 1 
				ELSE 0 
			 END AS bit) CanModify,
		sel.ModifyUntil,
		sel.CanDownloadSpecification
FROM
		(
			SELECT	DISTINCT
					decl.DeclarationID,
					decl.SubsidySchemeID,
					decl.DeclarationDate,
					COALESCE(osrd.CourseName, stpd.EducationName, '')							AS CourseName,
					decl.DeclarationAmount,
					decl.ApprovedAmount,
					decl.DeclarationStatus,
					CASE decl.SubsidySchemeID
						WHEN 1 THEN CASE WHEN osrd.StartDate > CAST(GETDATE() AS date) 
										  AND osrd.DeclarationStatus = '0001' 
										THEN osrd.StartDate 
										ELSE NULL 
									END
						WHEN 3 THEN CASE WHEN evcd.IntakeDate > CAST(GETDATE() AS date) 
										  AND evcd.DeclarationStatus = '0001' 
										THEN evcd.IntakeDate 
										ELSE NULL 
									END
						WHEN 4 THEN CASE WHEN dbpv.DeclarationID IS NOT NULL
										THEN CASE WHEN stpd.DeclarationStatus = '0019'	-- Terug naar werkgever.
												THEN CASE WHEN DATEADD(DD, -1, DATEADD(MM, 6, stpd.StartDate)) > CAST(GETDATE() AS date)
														THEN DATEADD(DD, -1, DATEADD(MM, 6, stpd.StartDate))
														ELSE CAST(GETDATE() AS date)
													 END
												ELSE NULL
											 END
										ELSE CASE WHEN stpd.TerminationDate IS NOT NULL
												THEN NULL
												ELSE CASE WHEN stpd.LastExtensionID IS NULL 
													   THEN CASE WHEN (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
																		FROM	sub.tblDeclaration_partition dep
																		WHERE	dep.DeclarationID = stpd.DeclarationID
																	  ) <= CAST(GETDATE() AS date)
																 THEN NULL
																 WHEN (	SELECT	COUNT(1)
																		FROM	sub.tblDeclaration_partition dep
																		WHERE	dep.DeclarationID = stpd.DeclarationID
																	  ) = 0
																 THEN CASE WHEN DATEADD(MM, 6, stpd.StartDate) > CAST(GETDATE() AS date)
																			THEN DATEADD(MM, 6, stpd.StartDate)
																			ELSE CAST(GETDATE() AS date)
																		 END
																 ELSE (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
																		FROM	sub.tblDeclaration_partition dep
																		WHERE	dep.DeclarationID = stpd.DeclarationID
																	  )
															END
														ELSE CASE WHEN (SELECT	CAST(MIN(dep.PaymentDate) AS date)
																		FROM	sub.tblDeclaration_Extension dex
																		INNER JOIN sub.tblDeclaration_Partition dep
																		ON		dep.DeclarationID = dex.DeclarationID
																		WHERE	dex.ExtensionID = stpd.LastExtensionID
																		AND		dep.PaymentDate >= dex.StartDate
																		) <= CAST(GETDATE() AS date)
																THEN NULL 
																ELSE (	SELECT	CAST(MIN(dep.PaymentDate) AS date)
																		FROM	sub.tblDeclaration_Extension dex
																		INNER JOIN sub.tblDeclaration_Partition dep
																		ON		dep.DeclarationID = dex.DeclarationID
																		WHERE	dex.ExtensionID = stpd.LastExtensionID
																		AND		dep.PaymentDate >= dex.StartDate
																	)
															 END
													 END
											 END
									END
						WHEN 5 THEN CASE WHEN evcwvd.IntakeDate > CAST(GETDATE() AS date) 
										  AND evcwvd.DeclarationStatus = '0001' 
										THEN evcwvd.IntakeDate 
										ELSE NULL 
									END
					END																			AS ModifyUntil,
					CAST(0 AS bit)																AS CanDownloadSpecification
			FROM	sub.tblDeclaration_Employee dem
			INNER JOIN sub.tblDeclaration decl ON decl.DeclarationID = dem.DeclarationID
			LEFT JOIN evc.viewDeclaration evcd ON evcd.DeclarationID = decl.DeclarationID
			LEFT JOIN evcwv.viewDeclaration evcwvd ON evcwvd.DeclarationID = decl.DeclarationID
			LEFT JOIN osr.viewDeclaration osrd ON osrd.DeclarationID = decl.DeclarationID
			LEFT JOIN stip.viewDeclaration stpd ON stpd.DeclarationID = decl.DeclarationID
			LEFT JOIN stip.tblDeclaration_BPV dbpv ON dbpv.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblDeclaration_Specification dsp ON dsp.DeclarationID = decl.DeclarationID
			LEFT JOIN sub.tblDeclaration_Employee_ReversalPayment der 
			ON		der.DeclarationID = decl.DeclarationID
			AND		der.EmployeeNumber = dem.EmployeeNumber
			WHERE	dem.EmployeeNumber = @EmployeeNumber
			  AND	der.ReversalPaymentID IS NULL
			  AND	(
						@OTIB_User = 1
					OR
						EXISTS (SELECT	1
								FROM	sub.tblUser_Role_Employer ure 
								WHERE	ure.EmployerNumber = decl.EmployerNumber
							   )
					)
			) sel
ORDER BY sel.DeclarationDate DESC

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Get_Summary ===========================================================	*/
