CREATE TYPE [stip].[uttSnapshotDetailsPercentage] AS TABLE (
    [DeclarationID]  INT             NOT NULL,
    [PaymentDate]    DATE            NOT NULL,
    [AmountToBePaid] DECIMAL (19, 2) NOT NULL);

