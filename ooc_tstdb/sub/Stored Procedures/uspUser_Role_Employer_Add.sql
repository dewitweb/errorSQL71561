
CREATE PROCEDURE [sub].[uspUser_Role_Employer_Add]
@UserID				int,
@EmployerNumber		varchar(6),
@RequestSend		datetime,
@RequestApproved	datetime,
@RequestDenied		datetime,
@RoleID				int
AS
/*	==========================================================================================
	Purpose:	Connect a user to an employer in a specific role.

	Note:		For testing purposes!

	05-11-2018	Sander van Houten	Initial version
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

-- Insert new record in auth.tblUser_Role
INSERT INTO sub.tblUser_Role_Employer
           (UserID
           ,EmployerNumber
           ,RequestSend
           ,RequestApproved
           ,RequestDenied
           ,RoleID)
     VALUES
           (
			@UserID,
			@EmployerNumber,
			@RequestSend,
			@RequestApproved,
			@RequestDenied,
			@RoleID
		   )

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspUser_Role_Employer_Add =========================================================	*/
