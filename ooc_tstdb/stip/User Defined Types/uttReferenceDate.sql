CREATE TYPE [stip].[uttReferenceDate] AS TABLE (
    [PartitionID]              INT             NULL,
    [DeclarationID]            INT             NULL,
    [PartitionYear]            VARCHAR (20)    NULL,
    [PartitionAmount]          DECIMAL (19, 4) NULL,
    [PartitionAmountCorrected] DECIMAL (19, 4) NULL,
    [PaymentDate]              DATE            NULL,
    [PartitionStatus]          VARCHAR (4)     NULL,
    [CreatePartition]          BIT             NULL,
    [DiplomaPartition]         BIT             NULL);

