CREATE PROCEDURE [sub].[usp_CONNECT_Institute_Upd]
@tblInstitute	sub.uttInstitute READONLY
AS
/*	==========================================================================================
	Purpose:	update institutes with current institute data from Etalage.

	22-10-2018	Sander van Houten		Initial version.

	14-10-2019	Jaap van Assenbergh		OTIBSUB-1619
										Import EVC-WV instituten uit Etalage	
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @InstituteID					int, 
		@InstituteName					varchar(255),
		@Location						varchar(24),
		@EndDate						date,
		@HorusID						varchar(6),
		@IsEVC							bit,
		@IsEVCWV						bit,
		@CurrentUserID					int = 1,
		@RC								int


	SELECT	imp.InstituteID,
			imp.InstituteName,
			imp.[Location],
			imp.EndDate,
			imp.HorusID,
			imp.IsEVC,
			imp.IsEVCWV,
			COALESCE(sub.InstituteName, ''), COALESCE(imp.InstituteName, ''),
			COALESCE(sub.[Location], ''), COALESCE(imp.[Location], ''),	 
			COALESCE(CAST(sub.EndDate as varchar(10)), ''), COALESCE(CAST(imp.EndDate as varchar(10)), ''),
			COALESCE(sub.HorusID, 0), COALESCE(imp.HorusID, 0),
			COALESCE(sub.IsEVC, 0), COALESCE(imp.IsEVC, 0),
			COALESCE(sub.IsEVCWV, 0), COALESCE(imp.IsEVCWV, 0),	

CASE WHEN COALESCE(sub.InstituteName, '')= COALESCE(imp.InstituteName, '') THEN 0 ELSE 1 END InsName,
CASE WHEN COALESCE(sub.[Location], '') = COALESCE(imp.[Location], '') THEN 0 ELSE 1 END Loc,	 
CASE WHEN COALESCE(CAST(sub.EndDate as varchar(10)), '') = COALESCE(CAST(imp.EndDate as varchar(10)), '') THEN 0 ELSE 1 END Dat,
CASE WHEN COALESCE(sub.HorusID, 0) = COALESCE(imp.HorusID, 0) THEN 0 ELSE 1 END,
CASE WHEN COALESCE(sub.IsEVC, 0) = COALESCE(imp.IsEVC, 0) THEN 0 ELSE 1 END,
CASE WHEN COALESCE(sub.IsEVCWV, 0) = COALESCE(imp.IsEVCWV, 0) THEN 0 ELSE 1 END

	FROM	@tblInstitute imp
	LEFT JOIN sub.viewInstitute sub
	ON		sub.InstituteID = imp.InstituteID
	WHERE	sub.InstituteID IS NULL
	   OR	(
				COALESCE(sub.InstituteName, '') <> COALESCE(imp.InstituteName, '')
			OR	COALESCE(sub.[Location], '') <> COALESCE(imp.[Location], '')			 
			OR	COALESCE(CAST(sub.EndDate as varchar(10)), '') <> COALESCE(CAST(imp.EndDate as varchar(10)), '')			 
			OR	COALESCE(sub.HorusID, 0) <> COALESCE(imp.HorusID, 0)			 
			OR	COALESCE(sub.IsEVC, 0) <> COALESCE(imp.IsEVC, 0)			 
			OR	COALESCE(sub.IsEVCWV, 0) <> COALESCE(imp.IsEVCWV, 0)			 
			)

DECLARE cur_institute CURSOR FOR 
	SELECT	imp.InstituteID,
			imp.InstituteName,
			imp.[Location],
			imp.EndDate,
			imp.HorusID,
			imp.IsEVC,
			imp.IsEVCWV
	FROM	@tblInstitute imp
	LEFT JOIN sub.viewInstitute sub
	ON		sub.InstituteID = imp.InstituteID
	WHERE	sub.InstituteID IS NULL
	   OR	(
				COALESCE(sub.InstituteName, '') <> COALESCE(imp.InstituteName, '')
			OR	COALESCE(sub.[Location], '') <> COALESCE(imp.[Location], '')			 
			OR	COALESCE(CAST(sub.EndDate as varchar(10)), '') <> COALESCE(CAST(imp.EndDate as varchar(10)), '')			 
			OR	COALESCE(sub.HorusID, 0) <> COALESCE(imp.HorusID, 0)			 
			OR	COALESCE(sub.IsEVC, 0) <> COALESCE(imp.IsEVC, 0)			 
			OR	COALESCE(sub.IsEVCWV, 0) <> COALESCE(imp.IsEVCWV, 0)			 
			)
		
/* Loop through all selected institutes to update or insert the data from Etalage.	*/
OPEN cur_institute

FETCH NEXT FROM cur_institute INTO @InstituteID, @InstituteName, @Location, @EndDate, @HorusID, @IsEVC, @IsEVCWV

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXECUTE @RC = [sub].[uspInstitute_Upd] 
		@InstituteID,
		@InstituteName,
		@Location, 
		@EndDate, 
		@HorusID, 
		@IsEVC,
		@IsEVCWV,
		0,
		@CurrentUserID

		PRINT @InstituteName

	FETCH NEXT FROM cur_institute INTO @InstituteID, @InstituteName, @Location, @EndDate, @HorusID, @IsEVC, @IsEVCWV

END

CLOSE cur_institute
DEALLOCATE cur_institute

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_CONNECT_Institute_Upd ========================================================	*/
