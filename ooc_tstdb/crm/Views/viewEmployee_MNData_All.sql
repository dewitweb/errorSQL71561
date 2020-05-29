


CREATE VIEW [crm].[viewEmployee_MNData_All]
AS
SELECT fonds
      ,nummer
      ,naam
      ,voorletters
      ,voorvoegsels
      ,geslacht
      ,geboortedatum
      ,ingangsdatum
      ,einddatum
      ,werkgeverNummer
      ,aanvangsdatumDienstverband
      ,einddatumDienstverband
      ,omvangDienstverband
      ,redenUitstroom
      ,inkomen
      ,inkomensfrequentie
      ,functiecategorie
      ,beroepcode
      ,voorvoegselsEchtgenoot
      ,naamEchtgenoot
      ,datumOverlijden
      ,adresStraat
      ,adresHuisnummer
      ,adresToevoeging
      ,adresPostcode
      ,adresPlaats
      ,adresLandcode
      ,adresLandnaam
      ,RecordCreatedOn
      ,RecordAlteredOn
  FROM [10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblEmployee]
