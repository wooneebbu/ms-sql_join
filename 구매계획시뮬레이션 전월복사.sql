USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationBtn]    Script Date: 2023-09-18 오후 9:44:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션 등록_전월복사
    작 성 일 - 2023.09.18
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationBtn]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

-- 로그테이블 남기기

DECLARE	 @TableColumns NVARCHAR(4000)                             			  
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_DelvPlanSimulation')                

EXEC _SCOMLog @CompanySeq  ,                              
              @UserSeq      ,          
              'joinbio_DelvPlanSimulation',	            	-- 원테이블명                              
              '#BIZ_OUT_DataBlock1',		                -- 임시테이블명                              
              'InCompany,CustSeq,EggWeightSeq,StdYM',    -- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns,  @PgmSeq                 
             -- @TableColumns, 'InCompany', 'CustSeq', 'EggWeightSeq', 'STDYM' ,@PgmSeq                 

-- 변수선언
DECLARE @STDYM		    NVARCHAR(6), 
        @EggWeightSeq		INT,
        @BEFYM          NVARCHAR(6)

-- 전월복사 데이터 말고 다른것들은 BIZ_OUT에서 불러오기
 SELECT @STDYM        = StdYM,  
        @EggWeightSeq = EggWeightSeq
   FROM #BIZ_OUT_DataBlock1


-- 전월복사 데이터 SET 
SET @BEFYM = REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @STDYM + '01'), 120), '-', '') 
/* month에 -1을하고 @STDYM기준연월에 + 01 붙여서 총 글자7개의 형태로 바꾸고 '-' 부분을 '' 으로 replace */

/* dateadd(datepart, number, date)
 replace('mssql', 's', 'x' ) >> s -> x로 치환 */

/* 확인 
SElECT DATEADD(Month, -1, @STDYM + '01')
SELECT CONVERT(VARCHAR(7), DATEADD(Month, -1, @STDYM + '01'), 120)
SELECT REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @STDYM + '01'), 120), '-', '')
*/


-- 전월복사 데이터 불러오기 기준연월에 전월복사부분 가져오기
SELECT * INTO #TEMPBEFYM
FROM joinbio_DelvPlanSimulation
WHERE 1=1
AND STDYM = @BEFYM
-- AND EggWeightSeq = @EggWeightSeq 

-- 현재 기준연월에 전월복사부분 update 
UPDATE #TEMPBEFYM
SET STDYM = @STDYM
FROM #TEMPBEFYM

-- 현재월에 있던 데이터 지우기
DELETE joinbio_DelvPlanSimulation
WHERE 1=1
AND STDYM = @STDYM
-- AND EggWeightSeq = @EggWeightSeq 

-- 전월복사 불러온 부분 insert 
INSERT INTO joinbio_DelvPlanSimulation 
SELECT * FROM #TEMPBEFYM


RETURN