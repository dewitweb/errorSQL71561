






CREATE VIEW [crm].[viewPaymentArrear_MNData]
AS
SELECT	fonds,
		debiteurnummer,
		docdatum,
		RecordCreatedOn,
		RecordAlteredOn
FROM	[10.66.66.11\SQL2017].[OTIBMNData].[dbo].[tblPaymentArrear]

