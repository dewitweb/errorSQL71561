CREATE PROCEDURE [ait].[uspExactData_Check] 
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Check on exported payments file (Exact).

	21-05-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE @PaymentRunID	int = 60010
--	*/

/*	Initialize XML import tabel.	*/
DELETE 
FROM	ait.tblExactData_XML
WHERE	PaymentRunID = @PaymentRunID

/*	Transfer data from variable to XML import table.	*/
INSERT INTO ait.tblExactData_XML
	(
		PaymentRunID, 
		XMLData
	)
--SELECT CAST(@FileStream AS xml)
SELECT	@PaymentRunID,
		XMLPayments
FROM	sub.tblPaymentRun_XMLExport
WHERE	PaymentRunID = @PaymentRunID

/*	Remove namespace tag from xml.	*/
UPDATE	ait.tblExactData_XML
SET		XMLData = CAST(REPLACE(CAST(XMLData AS varchar(max)),' xmlns="http://qios.nl/ORL-Schema"','') AS xml)
WHERE	PaymentRunID = @PaymentRunID
--SELECT XMLData.value('(/werkgevers/werkgever/nummer)[1]', 'varchar(max)') FROM dbo.tblEmployerData_XML

/*	Initialize import table.	*/
--	DELETE FROM sub.tblExactData

SELECT	@PaymentRunID AS PaymentRunID,
		x.r.value('(../Description)[1]', 'varchar(10)') AS JournalEntryCode,
		x.r.value('(../Date)[1]', 'date') AS ProcessDate,
		x.r.value('(../DocumentDate)[1]', 'date') AS DocumentDate,
		x.r.value('(../Journal/@type)[1]', 'varchar(1)') AS JournalType,
		x.r.value('(../Journal/@Code)[1]', 'varchar(2)') AS JournalCode,
		x.r.value('(../Amount/Currency/@code)[1]', 'varchar(3)') AS CurrencyCode,
		x.r.value('(../Amount/Value)[1]', 'decimal(19,2)') AS PaidAmount,
		x.r.value('(@number)[1]', 'tinyint') AS LineNumber,
		x.r.value('(Date)[1]', 'date') AS PaymentDate,
		x.r.value('(GLAccount/@code)[1]', 'int') AS GLAccount,
		x.r.value('(Costcenter/@code)[1]', 'int') AS Costcenter,
		x.r.value('(Creditor/@code)[1]', 'varchar(6)') AS EmployerNumber,
		x.r.value('(Amount/Currency/@code)[1]', 'varchar(3)') AS PaymentCurrencyCode,
		CAST(x.r.query('Amount/Debit/text()') AS varchar(100)) AS PaymentAmountDebit,
		CAST(x.r.query('Amount/Credit/text()') AS varchar(100)) AS PaymentAmountCredit
INTO #tblExactData
FROM ait.tblExactData_XML
CROSS APPLY xmldata.nodes('/eExact/GLEntries/GLEntry/FinEntryLine') AS x(r)
WHERE	PaymentRunID = @PaymentRunID

SELECT * FROM #tblExactData ORDER BY journalentrycode

--SELECT  t1.JournalEntryCode, t1.PaidAmount, sub1.SumPartitionAmount, sub1.SumVoucherAmount
--FROM	(SELECT	PaymentRunID,
--				JournalEntryCode, 
--				SUM(CAST(PaymentAmountDebit AS decimal(19,2))) - SUM(CAST(PaymentAmountCredit AS decimal(19,2))) AS PaidAmount 
--		 FROM	#tblExactData
--		 WHERE	PaymentRunID = @PaymentRunID
--		 GROUP BY 
--				PaymentRunID,
--				JournalEntryCode
--		) t1
--INNER JOIN (SELECT	t2.PaymentRunID,
--					t2.JournalEntryCode,
--					SUM(t3.SumPartitionAmount)	AS SumPartitionAmount,
--					SUM(t3.SumVoucherAmount)	AS SumVoucherAmount
--			FROM	sub.tblPaymentRun_Declaration t2
--			INNER JOIN sub.tblDeclaration_Specification t3
--			ON		t3.PaymentRunID = t2.PaymentRunID
--			AND		t3.DeclarationID = t2.DeclarationID
--			WHERE	t2.PaymentRunID = @PaymentRunID
--			GROUP BY 
--					t2.PaymentRunID,
--					t2.JournalEntryCode
--		   ) sub1
--ON		sub1.PaymentRunID = t1.PaymentRunID
--AND		sub1.JournalEntryCode = t1.JournalEntryCode
--WHERE	t1.PaidAmount <> (sub1.SumPartitionAmount + sub1.SumVoucherAmount)

--ORDER BY 
--		t1.JournalEntryCode

/*	== dbo.uspExactData_Import ===============================================================	*/
