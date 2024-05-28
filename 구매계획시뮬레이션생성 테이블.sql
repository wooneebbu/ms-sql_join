IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'joinbio_DelvPlanSimulationMake' AND xtype = 'U' )
BEGIN
CREATE TABLE joinbio_DelvPlanSimulationMake
(
    CompanySeq		    INT     	 NOT NULL,  -- CompanySeq, LastUserSeq, LastDateTime 3가지는 필수로 집어 넣어야 함 
    InCompany		NVARCHAR(30) 	 NOT NULL,  -- 비지니스 테이블에서는 Name값 가져와야함 
    CustSeq		        INT 	     NOT NULL,  -- code로 들어가는 테이블값만 있으면 됨 Name은 굳이 테이블로 안만들어도 된다.
    EggWeightSeq		INT 	     NOT NULL,  
    STDYM		    NVARCHAR(6) 	 NOT NULL, 
    STDYMD          NVARCHAR(8)      NOT NULL,  -- 다이나믹시트로 쓸 테이블은 title 과 titleseq 쓰기 때문에  titleseq 컬럼 만들어줘야함 
    Qty             DECIMAL(19,5) 	 NULL,
    LastUserSeq		INT 	         NOT NULL,  
    LastDateTime	DATETIME 	     NOT NULL, 
CONSTRAINT PKjoinbio_DelvPlanSimulationMake PRIMARY KEY CLUSTERED (CompanySeq ASC, InCompany ASC, CustSeq ASC, EggWeightSeq ASC, STDYM ASC, STDYMD ASC)

)
END

--============
--테이블컬럼추가
--============


SELECT * FROM joinbio_DelvPlanSimulationMake
SELECT * FROM joinbio_DelvPlanSimulationMakeLog

ALTER TABLE joinbio_DelvPlanSimulationMake ADD EggGradeSeq INT NOT NULL DEFAULT 0
ALTER TABLE joinbio_DelvPlanSimulationMake ADD EggTypeSeq INT NOT NULL DEFAULT 0
ALTER TABLE joinbio_DelvPlanSimulationMake ADD EggMTypeSeq INT NOT NULL DEFAULT 0

ALTER TABLE joinbio_DelvPlanSimulationMakeLog ADD EggGradeSeq INT NOT NULL DEFAULT 0
ALTER TABLE joinbio_DelvPlanSimulationMakeLog ADD EggTypeSeq INT NOT NULL DEFAULT 0
ALTER TABLE joinbio_DelvPlanSimulationMakeLog ADD EggMTypeSeq INT NOT NULL DEFAULT 0


SELECT constraint_schema
     , table_name
     , constraint_name
     , column_name
     , ordinal_position
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
 WHERE table_name = 'joinbio_DelvPlanSimulationMake'


ALTER TABLE joinbio_DelvPlanSimulationMake DROP CONSTRAINT PKjoinbio_DelvPlanSimulationMake
ALTER TABLE joinbio_DelvPlanSimulationMake ADD CONSTRAINT PKjoinbio_DelvPlanSimulationMake PRIMARY KEY (CompanySeq, InCompany, CustSeq, EggWeightSeq, STDYM, STDYMD, EggGradeSeq, EggTypeSeq, EggMTypeSeq)


--====================


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'joinbio_DelvPlanSimulationMakeLog' AND xtype = 'U' )
BEGIN
CREATE TABLE joinbio_DelvPlanSimulationMakeLog
(
    LogSeq		    INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT               NOT NULL, 
    LogDateTime		DATETIME          NOT NULL, 
    LogType		    NCHAR(1)          NOT NULL, 
    LogPgmSeq		INT               NULL, 
    CompanySeq		INT 	          NOT NULL, 
    InCompany		NVARCHAR(30) 	  NOT NULL, 
    CustSeq		    INT 	          NOT NULL, 
    EggWeightSeq    INT               NOT NULL, 
    STDYM		    NVARCHAR(6)       NOT NULL, 
    STDYMD          NVARCHAR(8)       NOT NULL,  
    Qty             DECIMAL(19,5) 	  NULL,
    LastUserSeq		INT 	          NOT NULL, 
    LastDateTime    DATETIME 	      NOT NULL
)
END

CREATE UNIQUE CLUSTERED INDEX IDXTempjoinbio_DelvPlanSimulationMakeLog ON joinbio_DelvPlanSimulationMakeLog (LogSeq)

IF NOT EXISTS (SELECT 1 FROM _TCOMTableLogInfo WHERE TableSeq = 2000135)
BEGIN
	INSERT _TCOMTableLogInfo (TableName, CompanySeq, TableSeq, UseLog, LastUserSeq, LastDateTime)
	SELECT 'joinbio_DelvPlanSimulationMake', 1, 2000135, '1', 1, GETDATE()
END
