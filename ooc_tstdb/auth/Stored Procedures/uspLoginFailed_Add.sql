
CREATE PROCEDURE [auth].[uspLoginFailed_Add]
@LoginName		varchar(50),
@FailureReason	tinyint,
@ExtraInfo		varchar(max)
AS
/*	==========================================================================================
	Purpose:	Log the fact that an unsuccesful login attempt was done.

	29-01-2019	Sander van Houten	Added ExtraInfo parameter (OTIBSUB-608).
	10-12-2018	Sander van Houten	Initial version (OTIBSUB-549).
	==========================================================================================	*/

-- Insert new record in auth.tblLoginFailed
INSERT INTO auth.tblLoginFailed
	(
		Loginname,
		LoginDateTime,
		FailureReason,
		ExtraInfo
	)
VALUES
	(
		@LoginName,
		GETDATE(),
		@FailureReason,
		@ExtraInfo
	)

/*	== auth.uspLoginFailed_Add ===============================================================	*/
