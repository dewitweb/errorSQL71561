


CREATE VIEW [crm].[viewEmployment_CRM]
AS
SELECT [Id]
      ,[otb_werkgever]
      ,[otb_werknemer]
      ,[otb_aanvangsdatum]
      ,[otb_einddatum]
      ,[otb_beroepcode]
      ,[otb_functiecategorie]
      ,[otb_redenuitstroom]
  FROM [OTIBDYNAMICS365SYNC].[Dynamics365_PROD_sync].[dbo].[otb_dienstverband]
