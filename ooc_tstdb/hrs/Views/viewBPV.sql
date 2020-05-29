CREATE VIEW [hrs].[viewBPV]
AS

SELECT	bpv.EmployeeNumber,
		bpv.EmployerNumber,
		bpv.StartDate,
		bpv.EndDate,
		bpv.CourseID,
		bpv.CourseName,
		bpv.StatusCode,
		bpv.StatusDescription,
		bpv.DSR_ID,
        bpv.TypeBPV
FROM	hrs.tblBPV bpv
WHERE	bpv.StatusCode NOT IN (3, 4)
