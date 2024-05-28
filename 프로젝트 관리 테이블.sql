DROP TABLE joinbio_Prjmanager
DROP TABLE joinbio_PrjmanagerLog




CREATE TABLE joinbio_Prjmanager
(
    CompanySeq		INT 	          NOT NULL, 
    PrjSeq		    INT IDENTITY(1,1) NOT NULL, 
    GWSeq		    INT               NOT NULL, 
    PrjName		    NVARCHAR(100) 	  NOT NULL, 
    PrjGubunSeq		INT 	          NOT NULL, 
    PrjPurpose		NVARCHAR(500) 	  NOT NULL, 
    WorkDate		NVARCHAR(8) 	  NOT NULL, 
    DueDate		    NVARCHAR(8)  	  NOT NULL, 
    EndDate		    NVARCHAR(8) 	  NULL, 
    PrjDept		    NVARCHAR(50) 	  NOT NULL, 
    RateSeq		    INT 	          NOT NULL, 
    AdminUser		NVARCHAR(10) 	  NOT NULL, 
    ProgressSeq		INT 	          NOT NULL, 
    PrjIssue		NVARCHAR(500) 	  NULL, 
    Remark		    NVARCHAR(100) 	  NULL, 
    LastUserSeq		INT 	          NOT NULL, 
    LastDateTime	DATETIME 	      NOT NULL, 
CONSTRAINT PKjoinbio_Prjmanager PRIMARY KEY CLUSTERED (CompanySeq ASC, GWSeq ASC)

)


CREATE TABLE joinbio_PrjmanagerLog
(
    LogSeq		    INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT               NOT NULL, 
    LogDateTime		DATETIME          NOT NULL, 
    LogType		    NCHAR(1)          NOT NULL, 
    LogPgmSeq		INT               NULL, 
    CompanySeq		INT 	          NOT NULL, 
    PrjSeq		    INT           	  NOT NULL, 
    GWSeq		    INT          	  NOT NULL, 
    PrjName		    NVARCHAR(100) 	  NOT NULL, 
    PrjGubunSeq		INT 	          NOT NULL, 
    PrjPurpose		NVARCHAR(500) 	  NOT NULL, 
    WorkDate		NVARCHAR(8) 	  NOT NULL, 
    DueDate		    NVARCHAR(8) 	  NOT NULL, 
    EndDate		    NVARCHAR(8) 	  NULL, 
    PrjDept		    NVARCHAR(50) 	  NOT NULL, 
    RateSeq		    INT 	          NOT NULL, 
    AdminUser		NVARCHAR(10) 	  NOT NULL, 
    ProgressSeq		INT 	          NOT NULL, 
    PrjIssue		NVARCHAR(500) 	  NULL, 
    Remark		    NVARCHAR(100) 	  NULL, 
    LastUserSeq		INT 	          NOT NULL, 
    LastDateTime	DATETIME 	      NOT NULL
)

CREATE UNIQUE CLUSTERED INDEX IDXTempjoinbio_PrjmanagerLog ON joinbio_PrjmanagerLog (LogSeq)

IF NOT EXISTS (SELECT 1 FROM _TCOMTableLogInfo WHERE TableSeq = 2000134)
BEGIN
	INSERT _TCOMTableLogInfo (TableName, CompanySeq, TableSeq, UseLog, LastUserSeq, LastDateTime)
	SELECT 'joinbio_Prjmanager', 1, 2000134, '1', 1, GETDATE()
END
go