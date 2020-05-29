
CREATE PROCEDURE [evcwv].[uspParticipant_Update]
@ParticipantID		int,
@EmployerNumber	varchar(6),
@EmployeeNumber	varchar(8),
@Initials		varchar(10),
@Amidst			varchar(20),
@Surname		varchar(100),
@DateOfBirth	date,
@FunctionCode	varchar(4),
@CurrentUserID	int = 1
AS
/*	==========================================================================================
	Purpose: 	Update evcwv.tblParticipant on basis of ParticipantID.

	15-10-2019	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @CRMID int
DECLARE @Gender varchar(1)
DECLARE @Phone varchar(20)
DECLARE @Email varchar(254)

DECLARE @Participant table (ParticipantID int)

IF ISNULL(@ParticipantID, 0) <> 0
	SELECT	@Gender = Gender,
			@Phone = Phone,
			@Email = Email
	FROM	evcwv.tblParticipant
	WHERE	ParticipantID = @ParticipantID

INSERT INTO @Participant (ParticipantID)
EXECUTE evcwv.uspParticipant_Upd
   @ParticipantID
  ,@EmployerNumber
  ,@EmployeeNumber
  ,@CRMID
  ,@Initials
  ,@Amidst
  ,@Surname
  ,@Gender
  ,@Phone
  ,@Email
  ,@DateOfBirth
  ,@FunctionCode
  ,@CurrentUserID

SELECT	ParticipantID
FROM	@Participant

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== evcwv.uspParticipant_Upd ==================================================================	*/
