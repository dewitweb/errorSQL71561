
CREATE VIEW [ait].[viewDeclaration_Unknown_Source_Control]
AS
/*	==========================================================================================
	Purpose:	Gets all declarations which are in process in Etalage according to DS.

	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	17-06-2018	Jaap van Assenbergh	Initial version.
	==========================================================================================	*/

SELECT	d.DeclarationID,
		d.DeclarationDate,
		d.DeclarationAmount,
		h.horDatumBehandeldDoorOTIB,
		h.horEtalageCursusID,
		h.horDatumTerugkoppelingNaarHorus,
		c.curClusterID,
		--h.horPlaats AS InstituutInDS,
		c.curInstituutID,
		CASE WHEN h.horID IS NULL THEN 'Staat niet in Etalage (tblHorus)'
			 WHEN h.horEtalageCursusID IS NULL THEN 'Is nog niet behandeld in Etalage'
			 WHEN h.horEtalageCursusID IS NOT NULL AND c.curID IS NULL THEN 'Opleiding is verwijderd in Etalage'
			 WHEN c.curClusterID IS NULL OR c.curClusterID <= 0 THEN 'Wel behandeld, maar opleiding heeft geen cluster in Etalage'
			 WHEN c.curInstituutID = -1 THEN 'Wel behandeld, maar opleiding heeft geen instituut in Etalage'
			 WHEN ISNULL(h.horEtalageCursusID, 0) > 0 AND ISNULL(c.curClusterID, 0) > 0 AND ISNULL(c.curInstituutID, 0) > 0 
              AND h.horDatumTerugkoppelingNaarHorus IS NOT NULL 
              THEN 'Wel behandeld en teruggestuurd, maar niet aangekomen (oplossing: datum naar Horus NULL maken)'
			 ELSE ''
		END AS BehandelStatusInEtalage,
		c.curNaam,
		i.instNaam AS InstituutInEtalage
FROM	sub.tblDeclaration d
INNER JOIN sub.tblDeclaration_Unknown_Source dus ON dus.DeclarationID = d.DeclarationID
LEFT JOIN [10.66.66.6].[OTIBEtalage].[dbo].[tblHorus] h ON h.horDeclaratienummer = d.DeclarationID
LEFT JOIN [10.66.66.6].[OTIBEtalage].[dbo].[tblCursus] c ON c.curID = h.horEtalageCursusID
LEFT JOIN [10.66.66.6].[OTIBEtalage].[dbo].[tblInstituut] i ON i.instID = c.curInstituutID
WHERE   d.DeclarationStatus = '0022'
/*	== ait.viewDeclaration_Unknown_Source_Control ============================================	*/
