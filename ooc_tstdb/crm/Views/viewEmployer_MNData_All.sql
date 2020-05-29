CREATE VIEW [crm].[viewEmployer_MNData_All]
AS
SELECT fonds
      ,nummer
      ,naam
      ,ingangsdatum
      ,einddatum
      ,lidmaatschap
      ,ingangsdatumLidmaatschap
      ,einddatumLidmaatschap
      ,rechtsvorm
      ,fondscode
      ,groepVanWerkzaamheden
      ,terAttentieVan
      ,zaakAdresStraat
      ,zaakAdresHuisnummer + zaakAdresToevoeging						AS zaakAdresHuisnummer
      ,zaakAdresPostcode
      ,zaakAdresPlaats
      ,zaakAdresLandcode
      ,zaakAdresLandnaam
      ,correspondentieAdresStraat
      ,correspondentieAdresHuisnummer + correspondentieAdresToevoeging	AS correspondentieAdresHuisnummer
      ,correspondentieAdresPostcode
      ,correspondentieAdresPlaats
      ,correspondentieAdresLandcode
      ,correspondentieAdresLandnaam
      ,telefoonnummer
      ,iban
      ,datumBeeindiging
      ,redenBeeindiging
      ,overnameDoor
      ,aantalDienstverbanden
      ,kvkNummer
      ,collectiefVrijwilligContract
      ,RecordCreatedOn
      ,RecordAlteredOn
  FROM [10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployer]
