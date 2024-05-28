USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationMakeBtn]    Script Date: 2023-11-23 오후 7:47:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션생성_Btn
    작 성 일 - 2023.10.19
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationMakeBtn]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

--========================
-- 로그테이블 남기기
--========================

DECLARE	 @TableColumns NVARCHAR(4000)                             			  
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_DelvPlanSimulationMake')                

EXEC _SCOMLog @CompanySeq  ,                              
              @UserSeq      ,          
              'joinbio_DelvPlanSimulationMake',	            	-- 원테이블명                              
              '#BIZ_OUT_DataBlock1',		                -- 임시테이블명                              
              'InCompany,CustSeq,EggWeightSeq,STDYM,STDYMD,EggGradeSeq,EggTypeSeq,EggMTypeSeq',    -- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns,  @PgmSeq                 
             -- @TableColumns, 'InCompany', 'CustSeq', 'EggWeightSeq', 'STDYM' ,@PgmSeq                 


--======================
-- 변수 선언 1 조회조건 
--======================

DECLARE  @STDYM				VARCHAR(6)
		,@EggWeightSeq		INT 

SELECT   @STDYM			  = ISNULL(STDYM, '')
		,@EggWeightSeq	  = ISNULL(EggWeightSeq, 0)
  FROM  #BIZ_IN_DataBlock1


--===================================
-- 변수 선언2  기준연월 일자변수 세팅
--===================================

DECLARE	@EndDay					VARCHAR(8)  -- 말일
DECLARE @ToDay					VARCHAR(8)	-- 오늘 'YYYYMMDD' 
DECLARE @TodayValue				VARCHAR(30) -- 오늘 'YYYY-MM-DD'
DECLARE @PlanYM					VARCHAR(6)  -- @PlanDay의 월
DECLARE @PlanDay				VARCHAR(8)  -- 루프변수 시뮬레이션 +1달  
DECLARE @PlanDayValue			VARCHAR(30) -- 루프변수 시뮬레이션 +1달 요일까지
DECLARE @DayCnt					INT			-- 루프MAX
DECLARE @Cnt					INT			-- 루프
DECLARE @DayName				VARCHAR(5)	-- 요일명

  --  SET @STDYM = '202310'

	SET @ToDay		=  @STDYM + '01'   -- 시작일에 기준연월+01로 셋팅
	SET @PlanDay	=  @Today		   -- 루프시작일 Today로 셋팅
	SET @EndDay		= REPLACE(CONVERT(VARCHAR,DATEADD(Day, -1, DATEADD(MONTH, 1, @ToDay)), 120),'-', '') -- 기준말일 Today로 셋팅 
	

	--> 기준말일 셋팅해
	--SELECT DATEADD(MONTH, 1, @ToDay)
	--SELECT DATEADD(Day, -1, DATEADD(MONTH, 1, @ToDay))
	--SELECT CONVERT(VARCHAR,DATEADD(Day, -1, DATEADD(MONTH, 1, @ToDay)), 120)
	--SELECT REPLACE(CONVERT(VARCHAR,DATEADD(Day, -1, DATEADD(MONTH, 1, @ToDay)), 120),'-', '')

	SET @DayCnt     = DATEDIFF(Day,@Today, @EndDay)
	SET @Cnt		= 0



--============================================================
-- TEMP TABLE 정리 // 기존에 있는 임시테이블 지우고 새로 만들기
--============================================================

  IF OBJECT_ID('tempdb..#Calendar')					IS NOT NULL DROP TABLE #Calendar
  IF OBJECT_ID('tempdb..#FixTable')					IS NOT NULL DROP TABLE #FixTable
  IF OBJECT_ID('tempdb..#DataTable')	    		IS NOT NULL DROP TABLE #DataTable
  IF OBJECT_ID('tempdb..#Allocate_Table')	    	IS NOT NULL DROP TABLE #Allocate_Table


--======================================
-- TEMP TABLE 구성
--======================================

CREATE TABLE #Calendar  --타이틀 테이블(헤더 만들기)
(
    STDYM		NVARCHAR(6)			NOT NULL			-- 타이틀명
  , STDYMD		NVARCHAR(8)			NOT NULL			-- 타이틀코드
)
CREATE CLUSTERED INDEX IDX_#Calendar ON #Calendar(STDYM, STDYMD) -- Temp table INDEX 구성시 필요설정



CREATE TABLE #FixTable -- 고정테이블 ( Group by 기준 ) // 다이나믹 시트 외 고정부분
(
	 CompanySeq		INT				NOT NULL			-- 회사코드
   , InCompany		NVARCHAR(8)		NOT NULL			-- 입고처명
   , CustSeq		INT				NOT NULL			-- 거래처코드
   , EggGradeSeq	INT				NOT NULL			-- 원란형태코드
   , EggTypeSeq		INT				NOT NULL			-- 품종코드
   , EggMTypeSeq	INT				NOT NULL			-- 원료중분류코드
   , EggWeightSeq	INT				NOT NULL			-- 품목코드

)
CREATE CLUSTERED INDEX IDX_#FixTable ON #FixTable(CompanySeq, InCompany, CustSeq, EggGradeSeq, EggTypeSeq, EggMTypeSeq, EggWeightSeq) 



--=========================
-- 날짜 다이나믹테이블
--=========================

BEGIN
	WHILE @Cnt <= @DayCnt  -- 매달 일수가 다르기때문에 LOOP 
  
  BEGIN
		SET @PlanYM = LEFT(@PlanDay, 6) -- @Today에서 앞에 6자리만 끌어옴
		/*달력채우기*/
		INSERT INTO #Calendar(STDYM, STDYMD)
		VALUES (@PlanYM, @PlanDay)
		/*루프차수*/
		SET @PlanDay = REPLACE(CONVERT(VARCHAR, DATEADD(Day, 1, @PlanDay), 120), '-', '')  --루프일자 증가 
		SET @Cnt	 = @Cnt + 1   -- 루프차수 증가
  END
END


--=========================
-- 배분값 계산 임시 테이블 생성
--=========================
 
 SELECT   CompanySeq
		, InCompany
	    , CustSeq
	    , EggGradeSeq
		, EggTypeSeq
		, EggMTypeSeq
		, EggWeightSeq
	    , STDYM
	    , INAVG
		,SUM(MON)  AS  MON
		,SUM(TUE)  AS  TUE
		,SUM(WED)  AS  WED
		,SUM(THU)  AS  THU
		,SUM(FRI)  AS  FRI
		,SUM(SAT)  AS  SAT
		,SUM(SUN)  AS  SUN
  INTO #Allocate_Table 
  FROM (SELECT	  CompanySeq
				, InCompany
				, EggTypeSeq
				, EggMTypeSeq
			--  , EggWeightSeq 
	            , CustSeq
	            , EggGradeSeq
				, ALLOCATE
				, STDYM
				, INAVG
				, CASE WHEN(EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226002 AND ALLOCATE = 0.4) OR (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226002 AND ALLOCATE = 0.2) THEN 2000226001
					   WHEN(EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226006 AND ALLOCATE = 0.4) OR (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226006 AND ALLOCATE = 0.2) THEN 2000226005
					   WHEN(EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226002 AND ALLOCATE = 0.6) OR (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226002 AND ALLOCATE = 0.8) THEN 2000226002
					   WHEN(EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226006 AND ALLOCATE = 0.6) OR (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226006 AND ALLOCATE = 0.8) THEN 2000226006
					   -- WHEN ALLOCATE = 0.4 OR ALLOCATE = 0.2 THEN 2000226001
				   	   -- WHEN ALLOCATE = 0.6 OR ALLOCATE = 0.8 THEN 2000226002
				   	   ELSE EggWeightSeq 
				   	    END EggWeightSeq 
				, Mon * ALLOCATE AS MON
				, Tue * ALLOCATE AS TUE
				, Wed * ALLOCATE AS WED
				, Thu * ALLOCATE AS THU
				, Fri * ALLOCATE AS FRI
				, Sat * ALLOCATE AS SAT
				, Sun * ALLOCATE AS SUN
		        

		FROM	(
				SELECT (CASE WHEN (EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226002) THEN 0.4  -- 갈색특대란/등급_특 /
							 WHEN (EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226006) THEN 0.4  -- 갈색특대란/특란
							 WHEN (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226002) THEN 0.2  -- 갈색유정란/등급_특 /
							 WHEN (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226006) THEN 0.2  -- 갈색유정란/특란
				             --WHEN EggWeightSeq = 2000226001 THEN 0.4
							 --WHEN EggWeightSeq = 2000226001 THEN 0.6
				             --WHEN EggWeightSeq = 2000226002 THEN 0.2
				             --WHEN EggWeightSeq = 2000226002 THEN 0.8 
							 ELSE 1 END) AS ALLOCATE ,*
				FROM JOINBIO_delvplansimulation
				WHERE 1=1
				  AND EggMtypeSeq  IN (2000182006 , 2000182011 ) 
				  AND EggWeightSeq IN (2000226002 , 2000226006 )
				  AND STDYM = @STDYM

				UNION ALL

				SELECT (CASE WHEN (EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226002) THEN 0.6  -- 갈색특대란/등급_대
							 WHEN (EggMtypeSeq = 2000182006 AND EggWeightSeq = 2000226006) THEN 0.6  -- 갈색특대란/대란
							 WHEN (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226002) THEN 0.8  -- 갈색유정란/등급_대
							 WHEN (EggMtypeSeq = 2000182011 AND EggWeightSeq = 2000226006) THEN 0.8  -- 갈색유정란/대란
							 --WHEN EggWeightSeq = 2000226001 THEN 0.4
				             --WHEN EggWeightSeq = 2000226001 THEN 0.6
				             --WHEN EggWeightSeq = 2000226002 THEN 0.2
				             --WHEN EggWeightSeq = 2000226002 THEN 0.8 
							 ELSE 1 END) AS ALLOCATE, *
				FROM JOINBIO_delvplansimulation
				WHERE -- EggWeightSeq IN (2000226001, 2000226002)
					  STDYM = @STDYM
				) AS T
			-- WHERE  InCompany = '조인'
			) AS A 
	GROUP BY CompanySeq, InCompany, EggTypeSeq, EggMTypeSeq, EggWeightSeq, CustSeq, EggGradeSeq, STDYM, INAVG


	    


--==============================
--고정테이블 구성 
--==============================

INSERT INTO #FixTable (CompanySeq, InCompany, CustSeq, EggGradeSeq, EggTypeSeq, EggMTypeSeq, EggWeightSeq)
SELECT DISTINCT  -- 기준등록화면에서 등록된 데이터만 추리기 
	   A.CompanySeq
	 , A.InCompany
	 , A.CustSeq
	 , A.EggGradeSeq
	 , A.EggTypeSeq
	 , A.EggMTypeSeq
	 , A.EggWeightSeq
 FROM #Allocate_Table AS A WITH(NOLOCK)
WHERE A.STDYM IN (SELECT DISTINCT STDYM FROM #Calendar) -- 전체 고정값 생성시 WHERE절 삭제하거나 주석처리


--===============================================================
-- DATA TABLE 삭제 후 입력 > 해당 생성 기간 및 난중만 제거 후 생성 
--===============================================================



DELETE FROM joinbio_DelvPlanSimulationMake
	  WHERE STDYM IN (SELECT DISTINCT STDYM FROM #Calendar)


INSERT INTO joinbio_DelvPlanSimulationMake (CompanySeq, InCompany, CustSeq, EggGradeSeq, EggTypeSeq, EggMTypeSeq, EggWeightSeq, STDYM, STDYMD, Qty, LastUserSeq, LastDateTime)
-- 테이블 컬럼위치 설정
SELECT  A.CompanySeq
	  , A.InCompany
	  , A.CustSeq
	  , A.EggGradeSeq
	  , A.EggTypeSeq
	  , A.EggMTypeSeq
	  , A.EggWeightSeq
	  , B.STDYM
	  , B.STDYMD AS STDYMD
	  , ISNULL(CASE WHEN DATEPART(WEEKDAY, B.STDYMD) = '1' THEN Sun
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '2' THEN Mon
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '3' THEN Tue
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '4' THEN Wed
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '5' THEN Thu
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '6' THEN Fri
					WHEN DATEPART(WEEKDAY, B.STDYMD) = '7' THEN Sat
				ELSE 0 END, 0) AS Qty
	  , @UserSeq
	  , GETDATE()
FROM			#FixTable					AS A WITH(NOLOCK)
LEFT JOIN		#Calendar					AS B WITH(NOLOCK) ON 1 = 1
LEFT OUTER JOIN #Allocate_Table             AS C WITH(NOLOCK) ON A.CompanySeq	=	C.CompanySeq
															 AND A.InCompany	=   C.InCompany
															 AND A.CustSeq		=	C.CustSeq
															 AND A.EggGradeSeq	=	C.EggGradeSeq
															 AND A.EggTypeSeq	=	C.EggTypeSeq
															 AND A.EggMTypeSeq	=	C.EggMTypeSeq
															 AND A.EggWeightSeq	=	C.EggWeightSeq
															 AND B.STDYM		=	C.STDYM

RETURN


