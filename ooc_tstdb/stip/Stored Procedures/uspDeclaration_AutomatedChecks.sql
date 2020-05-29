
CREATE PROCEDURE [stip].[uspDeclaration_AutomatedChecks]
@StatusXML	xml = N''
AS
/*	==========================================================================================
	Purpose:	Perform automated checks on all declaration with status "Ingediend" or 
				"Nieuwe opleiding afgehandeld"

	Notes:		

	11-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-10-2019	Jaap van Assenbergh	OTIBSUB-1648	OSR AND STIP can also get reset 
                                        for automated checks in the procedure.
	20-08-2019	Sander van Houten	Do not handle declaration if there is no partition.
	09-05-2019	Sander van Houten	OTIBSUB-997		Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE	@StatusXML	xml = N''
--	*/

/*  Declare variables.  */
DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate			date = GETDATE(),
		@DeclarationID		int
		
DECLARE @tblCheckedDeclarations TABLE 
	(
		DeclarationID	int NOT NULL
	)

DECLARE @tblRejectedDeclarations TABLE 
	(
		DeclarationID int NOT NULL,
		RejectionReason varchar(24) NOT NULL,
		RejectionXML xml NULL
	)

/*  Initialize @StatusXML.  */
IF CAST(ISNULL(@StatusXML, N'') AS varchar(MAX)) = N'' 
	SET @StatusXML =	'<partitionstatussen>
							<partitionstatus>0001</partitionstatus>
							<partitionstatus>0002</partitionstatus>
						</partitionstatussen>'

/*	Select all partitions that have a partitionStatus 0001 and startdate less then today 
    or 0002 (Ingediend).	*/
INSERT INTO @tblCheckedDeclarations
	(	
		DeclarationID
	)
SELECT	DISTINCT
		d.DeclarationID
FROM	stip.viewDeclaration d
INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = d.DeclarationID
WHERE	d.StartDate <= @GetDate
AND		d.DeclarationID > 400002
AND		d.DeclarationAmount > 0.00
AND		dep.PartitionStatus IN 
		(
			SELECT	tabel.kolom.value('.', 'varchar(4)')  
			FROM	@StatusXML.nodes('partitionstatussen/partitionstatus') tabel(kolom)
		)
AND		dep.PaymentDate <= @GetDate

DECLARE cur_Declaration CURSOR FOR 
	SELECT 	DeclarationID
	FROM	@tblCheckedDeclarations
	ORDER BY 
            DeclarationID

OPEN cur_Declaration

FETCH FROM cur_Declaration INTO @DeclarationID

WHILE @@FETCH_STATUS = 0  
BEGIN
    /* Check on rejection reasons.  */
    EXEC stip.uspDeclaration_AutomatedChecks_Declaration @DeclarationID

	FETCH NEXT FROM cur_Declaration INTO @DeclarationID
END

CLOSE cur_Declaration
DEALLOCATE cur_Declaration

/*	== stip.uspDeclaration_AutomatedChecks ===================================================	*/
