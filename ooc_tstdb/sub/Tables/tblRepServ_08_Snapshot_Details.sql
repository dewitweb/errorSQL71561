CREATE TABLE [sub].[tblRepServ_08_Snapshot_Details] (
    [SnapshotDetailID] INT             IDENTITY (1, 1) NOT NULL,
    [SnapshotID]       INT             NOT NULL,
    [PartitionYear]    VARCHAR (20)    NOT NULL,
    [PartitionMonth]   VARCHAR (2)     NOT NULL,
    [EmployerNumber]   VARCHAR (6)     NOT NULL,
    [EmployeeNumber]   VARCHAR (8)     NOT NULL,
    [DeclarationID]    INT             NOT NULL,
    [PaymentDate]      DATE            NOT NULL,
    [AmountToBePaid]   DECIMAL (19, 4) NOT NULL,
    [EducationLevel]   INT             NULL,
    CONSTRAINT [PK_sub_tblRepServ_08_Snapshot_Details] PRIMARY KEY NONCLUSTERED ([SnapshotDetailID] ASC),
    CONSTRAINT [FK_sub_tblRepServ_08_Snapshot_Details_tblRepServ_08_Snapshot] FOREIGN KEY ([SnapshotID]) REFERENCES [sub].[tblRepServ_08_Snapshot] ([SnapshotID])
);


GO
CREATE CLUSTERED INDEX [CI_sub_tblRepServ_08_Snapshot_Details_SnapshotID]
    ON [sub].[tblRepServ_08_Snapshot_Details]([SnapshotID] ASC);

