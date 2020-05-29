CREATE TABLE [ait].[tblMaintenance] (
    [RecordID]  INT      IDENTITY (1, 1) NOT NULL,
    [StartDate] DATETIME NOT NULL,
    [Duration]  SMALLINT NULL,
    CONSTRAINT [PK_ait_tblMaintenance] PRIMARY KEY CLUSTERED ([RecordID] ASC)
);

