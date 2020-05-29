

CREATE PROCEDURE [hrs].[uspSynchronizeDeclaration2018Data]
AS
/*	==========================================================================================
	Purpose:	Synchronize all declaration2 018 data to Horus.

	17-01-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Only if the linked server exists.	*/
IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN
	DECLARE @SQL	varchar(max),
			@Result	varchar(8000)

	DECLARE @DeclarationID		int,
			@DeclarationNumber	varchar(6)

	DECLARE cur_Declaration2018 CURSOR FOR 
		SELECT	dep.DeclarationID
		FROM	sub.tblDeclaration_Partition dep
		INNER JOIN osr.tblDeclaration decl ON decl.DeclarationID = dep.DeclarationID
		LEFT JOIN hrs.tblDeclaration_HorusNr_OTIBDSID dho ON dho.DeclarationNumber = dep.DeclarationID 
		WHERE	dep.PartitionYear = '2018'
		  AND	dho.DeclarationNumber IS NULL

	-- Loop through queue table.
	OPEN cur_Declaration2018

	FETCH NEXT FROM cur_Declaration2018 INTO @DeclarationID

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		-- Sync declaration record.
		SELECT	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.INDIENENDECLARATIE'
						+ '(''' + decl.EmployerNumber + ''', '
						+ '''' + ISNULL(ins.HorusID, '')  + ''', '
						+ '''' + crs.ClusterNumber + ''', '
						+ '''Cursus'', '
						+ 'TO_DATE(''' + REPLACE(CONVERT(varchar(10), decl.StartDate, 102), '.', '-') + ''', ''YYYY-MM-DD''), '
						+ 'TO_DATE(''' + REPLACE(CONVERT(varchar(10), CASE WHEN decl.EndDate > '20181231' 
																			THEN '20181231' 
																			ELSE decl.EndDate 
																	  END, 102), '.', '-') + ''', ''YYYY-MM-DD''), '
						+ CAST(CAST(dep.PartitionAmountCorrected AS decimal(19,2)) AS varchar(20)) + ', '
						+ 'TO_DATE(''' + REPLACE(CONVERT(varchar(10), decl.DeclarationDate, 102), '.', '-') + ''', ''YYYY-MM-DD''), '
						+ '''Nieuw'', '
						+ '''' + CAST(decl.DeclarationID AS varchar(6)) + ''', '
						+ '''' + osr.[Location] + ''''
						+ '); END;'
		FROM	sub.tblDeclaration decl
		INNER JOIN osr.tblDeclaration osr ON osr.DeclarationID = decl.DeclarationID
		INNER JOIN sub.tblDeclaration_Partition dep ON dep.DeclarationID = decl.DeclarationID
		INNER JOIN sub.tblCourse crs ON crs.CourseID = osr.CourseID
		INNER JOIN sub.tblInstitute ins ON ins.InstituteID = decl.InstituteID
		WHERE	decl.DeclarationID = @DeclarationID
		  AND	decl.StartDate >= '20180101'
		  AND	dep.PartitionYear = '2018'
		  AND	decl.DeclarationStatus IN ('0002', '0004')

		IF DB_NAME() = 'OTIBDS'
			EXEC(@SQL,  @Result OUTPUT) AT HORUS_P
		ELSE
			EXEC(@SQL,  @Result OUTPUT) AT HORUS_A

		-- Record Horus DeclarationNumber.
		IF @Result LIKE '%<resultaat>Goed</resultaat>%'
		BEGIN
			SELECT @DeclarationNumber = SUBSTRING(@Result, CHARINDEX('hrs_declaratienr', @Result, 1)+17, 6)

			INSERT INTO hrs.tblDeclaration_HorusNr_OTIBDSID
					(	
						DeclarationNumber,
						DeclarationID
					)
				 VALUES
					(	
					    @DeclarationNumber,
						@DeclarationID
					)

			-- Sync declarationrow record.
			DECLARE cur_DeclarationRow2018 CURSOR FOR 
				SELECT	'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.INDIENENDECLARATIEREGEL'
						+ '(''' + decl.EmployerNumber + ''', '
						+ '''' + dem.EmployeeNumber + ''', '
						+ 'TO_DATE(''' + REPLACE(CONVERT(varchar(10), eme.StartDate, 102), '.', '-') + ''', ''YYYY-MM-DD''), '
						+ '''' + @DeclarationNumber + ''', '
						+ '''' + CAST(@DeclarationID AS varchar(6)) + ''', '
						+ CASE WHEN dev.VoucherNumber IS NULL THEN '''''' ELSE '''' + dev.VoucherNumber + '''' END
						+ '); END;'
				FROM	sub.tblDeclaration decl
				INNER JOIN sub.tblDeclaration_Employee dem ON dem.DeclarationID = decl.DeclarationID
				INNER JOIN sub.tblEmployer_Employee eme ON eme.EmployerNumber = decl.EmployerNumber AND eme.EmployeeNumber = dem.EmployeeNumber
				LEFT JOIN  sub.tblDeclaration_Voucher dev ON dev.DeclarationID = decl.DeclarationID AND dev.EmployeeNumber = eme.EmployeeNumber
				WHERE	decl.DeclarationID = @DeclarationID

			-- Loop through queue table.
			OPEN cur_DeclarationRow2018

			FETCH NEXT FROM cur_DeclarationRow2018 INTO @SQL

			WHILE @@FETCH_STATUS = 0  
			BEGIN
				PRINT @sql
				IF DB_NAME() = 'OTIBDS'
					EXEC(@SQL,  @Result OUTPUT) AT HORUS_P
				ELSE
					EXEC(@SQL,  @Result OUTPUT) AT HORUS_A
	
				FETCH NEXT FROM cur_DeclarationRow2018 INTO @SQL
			END

			CLOSE cur_DeclarationRow2018
			DEALLOCATE cur_DeclarationRow2018
		END
		ELSE
		BEGIN
			PRINT @Result
		END

		FETCH NEXT FROM cur_Declaration2018 INTO @DeclarationID
	END

	CLOSE cur_Declaration2018
	DEALLOCATE cur_Declaration2018
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== hrs.spSynchronizeDeclaration2018Data ==================================================	*/
