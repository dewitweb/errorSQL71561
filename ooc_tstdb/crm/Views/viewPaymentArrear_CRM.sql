



CREATE VIEW [crm].[viewPaymentArrear_CRM]
AS
SELECT [Id]
      ,[otb_werkgever]
      ,[otb_heffingbetaaldtm]
  FROM [OTIBDYNAMICS365SYNC].[Dynamics365_PROD_sync].[dbo].[otb_betalingsachterstand]
