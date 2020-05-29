
CREATE PROCEDURE [ait].[uspExactData_Import] 
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Import exported payments file (Exact).

	30-04-2019	Sander van Houten		Initial version.
	==========================================================================================	*/

/*	Testdata.
DECLARE @PaymentRunID	int = 60007
--	*/

--DECLARE	@FileName			varchar(100) = 'vergoedingen_osr_60004_ADFOWNER.xml',
--		@FilePath			varchar(200) = 'E:\DataExchange\OTIBDS_To_Exact\Boekstuknrs\',
--		@FileStream			varbinary(max),
--		@Command			nvarchar(1000)

--SET @command = N'SELECT @FileStream1 = CAST(bulkcolumn AS varbinary(max))
--				FROM OPENROWSET(BULK ''' + @FilePath + @FileName + ''',
--				SINGLE_BLOB) AS x'

--/*	Make sure the xp_cmdshell options are accessable.	*/
--EXEC master.dbo.sp_configure 'show advanced options', 1
--RECONFIGURE
--EXEC master.dbo.sp_configure 'xp_cmdshell', 1
--RECONFIGURE

--/*	Import file into variable.	*/
--EXEC sp_executesql @Command, N'@FileStream1 VARBINARY(MAX) OUTPUT',@FileStream1 =@FileStream OUTPUT

--/*	Disable the xm_cmdshell options.	*/
--EXEC master.dbo.sp_configure 'show advanced options', 1
--RECONFIGURE
--EXEC master.dbo.sp_configure 'xp_cmdshell', 0
--RECONFIGURE

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
WHERE	PaymentRunID = 60007

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
		CAST(x.r.query('FinEntryLine/Amount/Debit/text()') AS varchar(100)) AS PaymentAmountDebit,
		CAST(x.r.query('Amount/Credit/text()') AS varchar(100)) AS PaymentAmountCredit
INTO #tblExactData
FROM ait.tblExactData_XML
CROSS APPLY xmldata.nodes('/eExact/GLEntries/GLEntry/FinEntryLine') AS x(r)

SELECT  t1.JournalEntryCode, t1.PaidAmount, sub1.SumPartitionAmount, sub1.SumVoucherAmount
FROM	(SELECT	PaymentRunID,
				JournalEntryCode, 
				SUM(CAST(PaymentAmountDebit AS decimal(19,2))) - SUM(CAST(PaymentAmountCredit AS decimal(19,2))) AS PaidAmount 
		 FROM	#tblExactData
		 WHERE	PaymentRunID = 60007
		 GROUP BY 
				PaymentRunID,
				JournalEntryCode
		) t1
INNER JOIN (SELECT	t2.PaymentRunID,
					t2.JournalEntryCode,
					SUM(t4.SumPartitionAmount)	AS SumPartitionAmount,
					SUM(t4.SumVoucherAmount)	AS SumVoucherAmount
			FROM	sub.tblJournalEntryCode t2
			INNER JOIN sub.tblPaymentRun_Declaration t3
					ON t3.JournalEntryCode = t2.JournalentryCode
			INNER JOIN sub.tblDeclaration_Specification t4
					ON	t4.PaymentRunID = t3.PaymentRunID
			AND		t4.DeclarationID = t3.DeclarationID
			WHERE	t2.PaymentRunID = 60007
			GROUP BY 
					t2.PaymentRunID,
					t2.JournalEntryCode
		   ) sub1
ON		sub1.PaymentRunID = t1.PaymentRunID
AND		sub1.JournalEntryCode = t1.JournalEntryCode
WHERE	t1.PaidAmount <> (sub1.SumPartitionAmount + sub1.SumVoucherAmount)

ORDER BY 
		t1.JournalEntryCode

/*	== dbo.uspExactData_Import ===============================================================	*/

