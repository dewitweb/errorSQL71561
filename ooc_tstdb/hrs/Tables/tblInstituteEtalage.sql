CREATE TABLE [hrs].[tblInstituteEtalage] (
    [EtalageInstituteID]   INT           NOT NULL,
    [HorusInstituteID]     INT           NOT NULL,
    [EtalageInstituteName] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_hrs_tblInstituteEtalage] PRIMARY KEY CLUSTERED ([EtalageInstituteID] ASC, [HorusInstituteID] ASC)
);

