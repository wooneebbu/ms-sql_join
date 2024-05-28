IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'joinbio_DelvPlanSimulation' AND xtype = 'U' )
BEGIN
CREATE TABLE joinbio_DelvPlanSimulation
(
    CompanySeq		    INT     	 NOT NULL,  -- CompanySeq, LastUserSeq, LastDateTime 3가지는 필수로 집어 넣어야 함 
    InCompany		NVARCHAR(30) 	 NOT NULL,  -- 비지니스 테이블에서는 Name값 가져와야함 
    CustSeq		        INT 	     NOT NULL,  -- code로 들어가는 테이블값만 있으면 됨 Name은 굳이 테이블로 안만들어도 된다.
    EggWeightSeq		INT 	     NOT NULL, 
    STDYM		    NVARCHAR(6) 	 NOT NULL, 
    Mon		        DECIMAL(19,5) 	 NULL, 
    Tue		        DECIMAL(19,5) 	 NULL, 
    Wed		        DECIMAL(19,5) 	 NULL, 
    Thu		        DECIMAL(19,5) 	 NULL, 
    Fri		        DECIMAL(19,5) 	 NULL, 
    Sat		        DECIMAL(19,5) 	 NULL, 
    Sun		        DECIMAL(19,5) 	 NULL, 
    Dummy1		    NVARCHAR(50) 	 NULL, 
    Dummy2		    NVARCHAR(50) 	 NULL, 
    Dummy3		    NVARCHAR(50) 	 NULL, 
    Dummy4		    NVARCHAR(50) 	 NULL, 
    Dummy5		    NVARCHAR(50) 	 NULL, 
    LastUserSeq		INT 	         NOT NULL, 
    LastDateTime	DATETIME 	     NOT NULL, 
CONSTRAINT PKjoinbio_DelvPlanSimulation PRIMARY KEY CLUSTERED (CompanySeq ASC, InCompany ASC, CustSeq ASC, EggWeightSeq ASC, STDYM ASC)

)
END


 -- Dummy1, Dummy2 COLUMN명 변경 TABLE 데이터타입이랑 PK 변경 

 SP_RENAME 'joinbio_DelvPlanSimulation.[Dummy1]','EggGradeSeq','COLUMN'
 SP_RENAME 'joinbio_DelvPlanSimulation.[Dummy2]','EggTypeSeq','COLUMN'
 SP_RENAME 'joinbio_DelvPlanSimulationLog.[Dummy1]','EggGradeSeq','COLUMN'
 SP_RENAME 'joinbio_DelvPlanSimulationLog.[Dummy2]','EggTypeSeq','COLUMN'
 
 EXEC SP_RENAME 'joinbio_DelvPlanSimulation.[Dummy3]','EggMTypeSeq','COLUMN'
 EXEC SP_RENAME 'joinbio_DelvPlanSimulationLog.[Dummy3]','EggMTypeSeq','COLUMN'
 
 


SELECT * FROM joinbio_DelvPlanSimulation
SELECT * FROM joinbio_DelvPlanSimulationLog

ALTER TABLE joinbio_DelvPlanSimulation ALTER COLUMN EggGradeSeq INT NOT NULL
ALTER TABLE joinbio_DelvPlanSimulation ALTER COLUMN EggTypeSeq INT NOT NULL
ALTER TABLE joinbio_DelvPlanSimulation ALTER COLUMN EggMTypeSeq INT NOT NULL

ALTER TABLE joinbio_DelvPlanSimulationLog ALTER COLUMN EggGradeSeq INT NOT NULL
ALTER TABLE joinbio_DelvPlanSimulationLog ALTER COLUMN EggTypeSeq INT NOT NULL
ALTER TABLE joinbio_DelvPlanSimulationLog ALTER COLUMN EggMTypeSeq INT NOT NULL


/* 
- PK명 조회방법 

SELECT constraint_schema
     , table_name
     , constraint_name
     , column_name
     , ordinal_position
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
 WHERE table_name = 'joinbio_DelvPlanSimulation' // 테이블명 //

 */

 -- PK의 경우 삭제하고 재생성

ALTER TABLE joinbio_DelvPlanSimulation DROP CONSTRAINT pk_delvsimulation
ALTER TABLE joinbio_DelvPlanSimulation ADD CONSTRAINT pk_delvsimulation PRIMARY KEY (CompanySeq, InCompany, CustSeq, EggWeightSeq, STDYM, EggGradeSeq, EggTypeSeq)



UPDATE joinbio_DelvPlanSimulation 
  -- SET EggGradeSeq = 0, EggTypeSeq = 0
	 SET EggMTypeSeq = 0

UPDATE joinbio_DelvPlanSimulationLog 
-- SET EggGradeSeq = 0, EggTypeSeq = 0
   SET EggMTypeSeq = 0










IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'joinbio_DelvPlanSimulationLog' AND xtype = 'U' )
BEGIN
CREATE TABLE joinbio_DelvPlanSimulationLog
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
    Mon		        DECIMAL(19,5) 	  NULL, 
    Tue		        DECIMAL(19,5) 	  NULL, 
    Wed		        DECIMAL(19,5) 	  NULL, 
    Thu		        DECIMAL(19,5) 	  NULL, 
    Fri		        DECIMAL(19,5) 	  NULL, 
    Sat		        DECIMAL(19,5) 	  NULL, 
    Sun		        DECIMAL(19,5) 	  NULL, 
    Dummy1		    NVARCHAR(50) 	  NULL, 
    Dummy2		    NVARCHAR(50) 	  NULL, 
    Dummy3		    NVARCHAR(50) 	  NULL, 
    Dummy4		    NVARCHAR(50) 	  NULL, 
    Dummy5		    NVARCHAR(50) 	  NULL, 
    LastUserSeq		INT 	          NOT NULL, 
    LastDateTime	DATETIME 	      NOT NULL
)
END

CREATE UNIQUE CLUSTERED INDEX IDXTempjoinbio_DelvPlanSimulationLog ON joinbio_DelvPlanSimulationLog (LogSeq)

IF NOT EXISTS (SELECT 1 FROM _TCOMTableLogInfo WHERE TableSeq = 2000135)
BEGIN
	INSERT _TCOMTableLogInfo (TableName, CompanySeq, TableSeq, UseLog, LastUserSeq, LastDateTime)
	SELECT 'joinbio_DelvPlanSimulation', 1, 2000135, '1', 1, GETDATE()
END
