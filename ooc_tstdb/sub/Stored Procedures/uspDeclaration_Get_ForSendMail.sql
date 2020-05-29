CREATE PROCEDURE [sub].[uspDeclaration_Get_ForSendMail]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get declaration information on bases of a DeclarationID.

	08-10-2019	Sander van Houten		OTIBSUB-1613	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID	int = 400411
--  */

SELECT
		d.DeclarationID,
		d.SubsidySchemeID,
		CASE d.SubsidySchemeID
            WHEN 1 THEN crs.CourseName
            WHEN 2 THEN 'BPV'
            WHEN 3 THEN (   
                            SELECT  emp.FullName
                            FROM    sub.tblDeclaration_Employee dem
                            INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
                            WHERE   dem.DeclarationID = d.DeclarationID
                        )
            WHEN 4 THEN (   
                            SELECT  emp.FullName
                            FROM    sub.tblDeclaration_Employee dem
                            INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
                            WHERE   dem.DeclarationID = d.DeclarationID
                        )
            WHEN 5 THEN (   
                            SELECT  emp.FullName
                            FROM    sub.tblDeclaration_Employee dem
                            INNER JOIN sub.tblEmployee emp ON emp.EmployeeNumber = dem.EmployeeNumber
                            WHERE   dem.DeclarationID = d.DeclarationID
                        )
            ELSE 'Onbekend'
        END     AS EmailSubject
FROM	sub.tblDeclaration d
LEFT JOIN osr.tblDeclaration osrd ON osrd.DeclarationID = d.DeclarationID
LEFT JOIN sub.tblCourse crs ON crs.CourseID = osrd.CourseID
WHERE	d.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Get_ForSendMail ====================================================	*/
