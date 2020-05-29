
CREATE VIEW [hrs].[viewBPV_DTG]
AS

SELECT	bpv.EmployeeNumber,					-- Performance: First field of the clustered index of table tblBPV
		dtg.DSR_ID,
		dtg.DTG_ID,
		dtg.ReferenceDate,
		dtg.PaymentStatus,
		dtg.DTG_Status,
		dtg.PaymentType,
		dtg.PaymentNumber,
		dtg.PaymentAmount,
		dtg.PaymentDate,
		dtg.AmountPaid,
		dtg.PaymentDateReversal,
		dtg.AmountReversed,
		dtg.LastPayment,
		dtg.ReasonNotPaidShort,
		dtg.ReasonNotPaidLong
FROM	hrs.viewBPV bpv
INNER JOIN hrs.tblBPV_DTG dtg ON dtg.DSR_ID = bpv.DSR_ID
