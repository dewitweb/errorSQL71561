
CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_Upd]
@IBANChangeID		int,
@EmployerNumber		varchar(6),
@IBAN_New			varchar(34),
@Ascription			varchar(100),
@StartDate			date,
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_IBAN_Change on the basis of IBANChangeID.

	19-11-2019	Sander van Houten	OTIBSUB-1718    Added update of ChangeStatus.
	05-03-2019	Sander van Houten	OTIBSUB-817     Added field StartDate.
	05-03-2019	Sander van Houten	OTIBSUB-700     Added field IBAN_Old.
	19-11-2018	Sander van Houten	OTIBSUB-98      Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@IBANChangeID		int = 1,
		@EmployerNumber		varchar(6) = '123456',
		@IBAN_new			varchar(34) = 'NL28RABO0103456789',
		@Ascription			varchar(100) = 'Test bedrijf 1',
		@StartDate			date = '20190305',
		@CurrentUserID		int = 1
*/

DECLARE	@LogDate datetime = GETDATE()

IF (ISNULL(@IBANChangeID, 0) = 0)
BEGIN
	-- Add new record
	INSERT INTO sub.tblEmployer_IBAN_Change
           (EmployerNumber
		   ,IBAN_Old
           ,IBAN_New
           ,Ascription
           ,ChangeStatus
		   ,Creation_UserID
		   ,Creation_DateTime
		   ,StartDate)
	SELECT
			@EmployerNumber,
			emp.IBAN AS IBAN_Old,
			@IBAN_new,
			@Ascription,
			'0000',	-- New
			@CurrentUserID,
			@LogDate,
			@StartDate
	FROM	sub.tblEmployer emp
	WHERE	emp.EmployerNumber = @EmployerNumber

	-- Save new IBANChangeID
	SET	@IBANChangeID = SCOPE_IDENTITY()

END
ELSE
BEGIN
	-- Update existing record
	UPDATE	sub.tblEmployer_IBAN_Change
	SET
			IBAN_New	    = @IBAN_New,
			Ascription	    = @Ascription,
			StartDate	    = @StartDate,
            ChangeStatus    = '0000'
	WHERE	IBANChangeID = @IBANChangeID
END

SELECT	IBANChangeID = @IBANChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_Upd ============================================	*/
