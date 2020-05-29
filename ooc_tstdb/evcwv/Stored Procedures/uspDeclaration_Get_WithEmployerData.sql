﻿
CREATE PROCEDURE [evcwv].[uspDeclaration_Get_WithEmployerData] 
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get declaration information on bases of a DeclarationID.

	08-11-2019	Jaap van Assenebrgh		OTIBSUB-1539	Declaratieniveau naar Partitieniveau brengen
	14-10-2019	Sander van Houten		OTIBSUB-1618	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata
DECLARE @DeclarationID	int = 181206,
		@UserID			int = 1
--*/

DECLARE	@ActivePartitionStatus	varchar(4)

SELECT	@ActivePartitionStatus = PartitionStatus
FROM	sub.tblDeclaration_Partition
WHERE	PartitionID = sub.usfGetActivePartitionByDeclaration (@DeclarationID, GETDATE())		-- OTIBSUB_1539

-- Determine Role(s) of current user.
DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

/*	Select Declaration data.	*/
SELECT
		d.DeclarationID,
		CAST(d.DeclarationID AS varchar(6))		                                            DeclarationNumber,
		d.EmployerNumber,
		e.EmployerName,
		e.IBAN,
		d.SubsidySchemeID,
		s.SubsidySchemeName +
			CASE WHEN d.IsEVC500 = 1 
					THEN '-500' 
					ELSE ''
					END SubsidySchemeName,
		d.DeclarationDate,
		d.InstituteID,
		d.DeclarationStatus,
		d.IntakeDate,
		d.CertificationDate,
		CAST(d.DeclarationAmount AS decimal(19,2))											DeclarationAmount,
		CAST(d.ApprovedAmount AS decimal(19,2))												ApprovedAmount,
		CASE @ActivePartitionStatus															-- OTIBSUB_1539 
			WHEN '0008' THEN i.InvestigationMemo
			ELSE d.StatusReason
		END																					StatusReason,
		d.InternalMemo,
		(
			SELECT 
					sub.PartitionYear,
					sub.SubsidyAmount,
					sub.PartitionAmount,
					sub.PartitionAmountCorrected
			FROM	(
						SELECT	
								dep.PartitionYear											PartitionYear,
								CAST(ems.Amount AS decimal(19,2))							SubsidyAmount,
								CAST(dep.PartitionAmount AS decimal(19,2))					PartitionAmount,
								CASE dep.PartitionStatus
									WHEN '0005' THEN NULL
									WHEN '0007' THEN NULL
									WHEN '0008' THEN NULL
									ELSE dep.PartitionAmountCorrected
								END															PartitionAmountCorrected
						FROM	sub.tblDeclaration_Partition dep
						LEFT JOIN sub.tblEmployer_Subsidy ems
							ON	ems.EmployerNumber = d.EmployerNumber
							AND ems.SubsidySchemeID = d.SubsidySchemeID
							AND CAST(YEAR(ems.StartDate) as varchar(4)) = dep.PartitionYear
						WHERE	dep.DeclarationID = d.DeclarationID
				) AS sub
			FOR XML PATH('Partition'), ROOT('Partitions')
		)																					[Partitions],
		CAST(CASE WHEN ISNULL(dtp.TotalPaidAmount, 0) = 0
				THEN 0
				ELSE CASE WHEN @ActivePartitionStatus IN ('0012', '0013', '0014', '0015')	-- OTIBSUB_1539
						THEN 1 
						ELSE 0 
					 END
			 END AS bit)																	CanReverse,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0007', '0009', '0022')	-- OTIBSUB_1539
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanSetToInvestigation,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')			-- OTIBSUB_1539
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanAccept,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0022')			-- OTIBSUB_1539
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanReject,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008', '0009', '0022')	-- OTIBSUB_1539
					AND dtp.DeclarationID IS NULL  
				THEN 1 
				ELSE 0 
			 END AS bit)																	CanReturnToEmployer,
		CAST(CASE WHEN @ActivePartitionStatus IN ('0005', '0006', '0008')
				THEN 1 
				ELSE 0 
			 END AS bit)																	GetRejectionReason

FROM	evcwv.viewDeclaration d
INNER JOIN sub.tblSubsidyScheme s ON s.SubsidySchemeID = d.SubsidySchemeID
INNER JOIN sub.tblEmployer e ON e.EmployerNumber = d.EmployerNumber
LEFT JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
LEFT JOIN (	SELECT DeclarationID, MAX(InvestigationDate) AS MaxInvestigationDate 
			FROM sub.tblDeclaration_Investigation
			GROUP BY DeclarationID
		  ) iMax ON iMax.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Investigation i ON i.DeclarationID = iMax.DeclarationID AND i.InvestigationDate = iMax.MaxInvestigationDate
LEFT JOIN  sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblDeclaration_Specification dsp ON dsp.DeclarationID = d.DeclarationID
LEFT JOIN  sub.viewDeclaration_TotalPaidAmount dtp on dtp.DeclarationID = d.DeclarationID
WHERE	d.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evcwv.uspDeclaration_Get_WithEmployerData =============================================	*/