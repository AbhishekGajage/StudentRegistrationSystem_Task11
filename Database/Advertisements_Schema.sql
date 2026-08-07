IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Advertisements')
BEGIN
    CREATE TABLE Advertisements (
        AdvertisementID INT IDENTITY(1,1) PRIMARY KEY,
        Title           NVARCHAR(200)   NOT NULL,
        Description     NVARCHAR(MAX)   NULL,
        ImagePath       NVARCHAR(500)   NULL,
        DisplayOrder    INT             NOT NULL DEFAULT 0,
        Status          NVARCHAR(20)    NOT NULL DEFAULT 'Active',   -- 'Active' or 'Inactive'
        CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE(),
        UpdatedDate     DATETIME        NULL,
        CreatedBy       NVARCHAR(100)   NULL
    );
END
GO
