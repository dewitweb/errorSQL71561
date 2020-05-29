




CREATE VIEW [crm].[viewEmployer_CRM]
AS
SELECT [Id]
	  ,[otb_mnwerkgevernummer]
      ,[name]
      ,[otb_terattentievan]
      ,[address1_line1]
      ,[address1_line2]
      ,[address1_line3]
      ,[address1_postalcode]
      ,[address1_city]
      ,[address1_composite]
      ,[address2_line1]
      ,[address2_line2]
      ,[telephone1]
	  ,[emailaddress1]
	  ,[emailaddress2]
	  ,[emailaddress3]
      ,[otb_kvknummer]
      ,[accountnumber]
      ,[otb_iban]
      ,[otb_datumbeeindiging]
  FROM [OTIBDYNAMICS365SYNC].[Dynamics365_PROD_sync].[dbo].[account]
