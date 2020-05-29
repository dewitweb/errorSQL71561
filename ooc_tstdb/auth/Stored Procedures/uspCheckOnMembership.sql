CREATE PROCEDURE [auth].[uspCheckOnMembership]
AS
/*	==========================================================================================
	Purpose:	Check on membership of employer for determining a user account-being active
				or not.

	Note:		This procedure should be executed on a daily basis.

	21-01-2020	Sander van Houten		OTIBSUB-1838	Added check on maximum of 6 months
                                            after EndDateMembership for STIP.
	05-06-2019	Sander van Houten		OTIBSUB-1157	Added loging.
	04-03-2019	Jaap van Assenbergh		OTIBSUB-808		Werkgever kan niet inloggen in DS
	28-01-2018	Sander van Houten		OTIBSUB-676		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @GetDate		                date = GETDATE(),
		@RC				                int,
		@CurrentUserID	                tinyint = 1,
		@UserID			                int

/*	Refresh employer data from Horus.	*/
EXEC @RC = [hrs].[uspHorusEmployers_Imp]

/*	Validate user-account.	*/
DECLARE cur_UserValidation CURSOR FOR 
	SELECT	uva.UserID
	FROM	sub.tblEmployer emp
	INNER JOIN auth.tblUser usr ON emp.EmployerNumber = usr.Loginname
	INNER JOIN hrs.tblWGR wgr ON wgr.EmployerNumber = emp.EmployerNumber
	INNER JOIN auth.tblUserValidation uva ON uva.UserID = usr.UserID
	WHERE	emp.StartDateMembership <= @GetDate
	  AND	COALESCE(emp.EndDateMembership, '20990101') > @GetDate
	  AND	wgr.SignedAgreementRecieved = 'J'
	  AND	uva.AgreementCheck = 0
		
OPEN cur_UserValidation

FETCH NEXT FROM cur_UserValidation INTO @UserID

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	uva
	SET		uva.AgreementCheck = 1,
			uva.ContactDetailsCheck = 1,
			uva.EmailCheck = 1
	FROM	auth.tblUserValidation uva
	WHERE	uva.UserID = @UserID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	auth.tblUserValidation
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Log action in his.tblHistory.
	SET @KeyID = @UserID

	EXEC his.uspHistory_Add
			'auth.tblUserValidation',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	FETCH NEXT FROM cur_UserValidation INTO @UserID
END

CLOSE cur_UserValidation
DEALLOCATE cur_UserValidation

/* Activate user-account.	*/
DECLARE cur_UserActivation CURSOR FOR 
	SELECT	usr.UserID
	FROM	sub.tblEmployer emp
	INNER JOIN auth.tblUser usr ON emp.EmployerNumber = usr.Loginname
	WHERE	emp.StartDateMembership <= @GetDate
	  AND	COALESCE(emp.EndDateMembership, '20990101') > @GetDate
	  AND	usr.Active = 0

OPEN cur_UserActivation

FETCH NEXT FROM cur_UserActivation INTO @UserID

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	auth.tblUser
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	usr
	SET		usr.Active = 1
	FROM	auth.tblUser usr 
	WHERE	usr.UserID = @UserID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	auth.tblUser
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Log action in his.tblHistory.
	SET @KeyID = @UserID

	EXEC his.uspHistory_Add
			'auth.tblUser',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	FETCH NEXT FROM cur_UserActivation INTO @UserID
END

CLOSE cur_UserActivation
DEALLOCATE cur_UserActivation

/* De-activate user-account.	*/
DECLARE cur_UserDeActivation CURSOR FOR 
	SELECT	usr.UserID
	FROM	sub.tblEmployer emp
	INNER JOIN auth.tblUser usr ON emp.EmployerNumber = usr.Loginname
	LEFT JOIN  (SELECT	EmployerNumber,
						MAX(EndDeclarationPeriod)	AS MaxEndDeclarationPeriod
				FROM	sub.tblEmployer_Subsidy
				GROUP BY EmployerNumber
				) AS esu	ON esu.EmployerNumber = emp.EmployerNumber
	WHERE	( emp.StartDateMembership > @GetDate
		OR	  ( emp.EndDateMembership <= @GetDate
		    AND COALESCE(esu.MaxEndDeclarationPeriod, @GetDate) <= @GetDate
            AND COALESCE(DATEADD(MONTH, 6, emp.EndDateMembership), @GetDate) <= @GetDate
			  )
			)
		AND	usr.Active = 1

OPEN cur_UserDeActivation

FETCH NEXT FROM cur_UserDeActivation INTO @UserID

WHILE @@FETCH_STATUS = 0  
BEGIN
	-- Save old record.
	SELECT	@XMLdel = (	SELECT 	*
						FROM	auth.tblUser
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Update existing record.
	UPDATE	usr
	SET		usr.Active = 0
	FROM	auth.tblUser usr 
	WHERE	usr.UserID = @UserID

	-- Save new record.
	SELECT	@XMLins = (	SELECT 	*
						FROM	auth.tblUser
						WHERE	UserID = @CurrentUserID
						FOR XML PATH )

	-- Log action in his.tblHistory.
	SET @KeyID = @UserID

	EXEC his.uspHistory_Add
			'auth.tblUser',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins

	FETCH NEXT FROM cur_UserDeActivation INTO @UserID
END

CLOSE cur_UserDeActivation
DEALLOCATE cur_UserDeActivation

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspCheckOnMembership =============================================================	*/
