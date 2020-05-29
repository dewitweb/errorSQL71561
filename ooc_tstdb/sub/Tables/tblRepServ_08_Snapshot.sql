CREATE TABLE [sub].[tblRepServ_08_Snapshot] (
    [SnapshotID]                      INT             IDENTITY (1, 1) NOT NULL,
    [Creation_DateTime]               DATETIME        NOT NULL,
    [Creation_UserName]               VARCHAR (100)   NOT NULL,
    [StartDate]                       DATE            NOT NULL,
    [EndDate]                         DATE            NULL,
    [Calculated_CommitmentPercentage] NUMERIC (19, 4) NOT NULL,
    [Calculated_X]                    INT             NOT NULL,
    [Calculated_Y]                    INT             NOT NULL,
    CONSTRAINT [PK_sub_tblRepServ_08_Snapshot] PRIMARY KEY NONCLUSTERED ([SnapshotID] ASC)
);

