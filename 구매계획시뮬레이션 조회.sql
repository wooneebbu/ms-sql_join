USE [JOIN]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationQuery_Query]    Script Date: 2024-05-21 오전 11:07:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션조회_joinbio
    작 성 일 - 2024.03.20
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationQuery_Query]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          
         
--======================
-- 변수 선언 1 조회조건 
--======================

DECLARE @STDYMFr			VARCHAR(6)
      , @STDYMTo			VARCHAR(6)
	  , @EggWeightSeq		INT
	  , @EggWeightName		VARCHAR(20)
      , @EggGradeSeq		INT 
      , @EggGradeName		VARCHAR(20)
      , @EggTypeSeq		    VARCHAR(20) -- INT
      , @EggTypeName		VARCHAR(20)
      , @EggMTypeSeq		INT
      , @EggMTypeName		VARCHAR(20)
      , @InCompany	    	NVARCHAR(30)

SELECT @STDYMFr			 = ISNULL(STDYMFr, '')
     , @STDYMTo			 = ISNULL(STDYMTo, '')
     , @EggWeightSeq     = ISNULL(EggWeightSeq, 0)
     , @EggGradeSeq	     = ISNULL(EggGradeSeq,  0)
     , @EggTypeSeq		 = ISNULL(EggTypeSeq,   0)
     , @EggMTypeSeq	     = ISNULL(EggMTypeSeq,  0)
     , @InCompany	     = ISNULL(InCompany,  '')

  FROM  #BIZ_IN_DataBlock1 


--===================================
-- 변수 선언2  조회일자 변수 LOOP 세팅
--===================================

DECLARE @StdDate    VARCHAR(20)
DECLARE @StdDateFr  VARCHAR(8)
DECLARE @StdDateTo  VARCHAR(8)
DECLARE @DayName    VARCHAR(5)
DECLARE @StartMon   INT  

DECLARE @Month_Ckb			INT
DECLARE @Week_Ckb			INT
DECLARE @Day_Ckb			INT
DECLARE @Total_EggGrade_Ckb INT
DECLARE @Total_EggMType_Ckb INT


SET @StdDateFr  = @STDYMFr + '01' -- 시작일 기준연월 + 01로 셋팅  Ex) 20240101
SET @StdDateTo  = REPLACE(CONVERT(VARCHAR,DATEADD(Day, -1, DATEADD(MONTH, 1, @STDYMTo + '01')), 120),'-', '') -- 기준말일은 조회조건의 To조건으로 셋팅
SET @DayName    = ''
SET @StartMon   = 1



--========================================
-- 임시테이블 세팅 / Temp Table 정리
--========================================

 IF OBJECT_ID('tempdb..#Date')					IS NOT NULL DROP TABLE #Date
 IF OBJECT_ID('tempdb..#DayName')				IS NOT NULL DROP TABLE #DayName
 -- IF OBJECT_ID('tempdb..#TitleBase')				IS NOT NULL DROP TABLE #TitleBase
 IF OBJECT_ID('tempdb..#Title')					IS NOT NULL DROP TABLE #Title
 IF OBJECT_ID('tempdb..#FixTable')				IS NOT NULL DROP TABLE #FixTable
 IF OBJECT_ID('tempdb..#DataTable')				IS NOT NULL DROP TABLE #DataTable
 IF OBJECT_ID('tempdb..#DataSTDMWD')		    IS NOT NULL DROP TABLE #DataSTDMWD


--======================================
-- TEMP TABLE 구성
--======================================
CREATE TABLE #Date (  	   	-- 기준연월Fr 변수 담을 임시테이블
			 StdDate 	   	VARCHAR(8) 
			 )


CREATE TABLE #DayName ( 	-- 날짜 변환 변수들 담을 임시테이블 
			 StdYY			VARCHAR(4)
		   , StdYM			VARCHAR(6)
		   , StdDate		VARCHAR(8)
		   , MM				VARCHAR(2)
		   , WK				VARCHAR(2)
		   , DD				VARCHAR(2) 
		   )


CREATE TABLE #Title (	    -- 변동 타이틀 임시테이블 // 다이나믹시트 부분
			  ColIDX    	INT IDENTITY(0,1)
			, TitleSeq 		INT
			, Title    		VARCHAR(20)
			)

CREATE TABLE #DataTable -- 다이나믹테이블 고정테이블 헤더 날짜기준으로 인덱스 생성
(	
	  RowIDX		INT					 NOT NULL
	, ColIDX		INT					 NOT NULL
	, Qty 			DECIMAL (19, 5)		 NOT NULL -- 연도별 시세
)



CREATE TABLE #DataSTDMWD
			(
			  CompanySeq			 INT
			, InCompany			 NVARCHAR(20)
			, STDYMWD			 VARCHAR(15)
			, EggTypeSeq		 INT
			, EggGradeSeq		 INT
			, EggMTypeSeq		 INT
			, EggWeightSeq		 INT
			, Qty				 DECIMAL (19, 5)
			, MM				 VARCHAR(2)
			, WK				 VARCHAR(2)
			, DD				 VARCHAR(2) 
			)


--=========================
-- 날짜 다이나믹테이블
--=========================


  SET @StdDate = @StdDateFr
WHILE @StdDate <= @StdDateTo
  BEGIN 

 -- PRINT '@StdDatefr = ' + @StdDatefr + '@StdDateTo  =  ' + @StdDateTo     

       INSERT INTO #Date 
       SELECT @StdDate
	      SET @StdDate = REPLACE(CONVERT(Date, DATEADD(day, 1, @StdDate ), 23), '-', '')

  END

          INSERT INTO #DayName 
          SELECT LEFT(StdDate, 4) AS StdYY
               , LEFT(StdDate, 6) AS StdYM
        	   , StdDate
               , RIGHT('0'+ CAST(DATEPART(MM, CONVERT(VARCHAR(10), (CONVERT(datetime, StdDate)), 23) ) AS VARCHAR), 2) AS MM
               , RIGHT('0'+ CAST(((DAY(convert(varchar(10),StdDate,120)) + (DATEPART(dw, DATEADD (MONTH, DATEDIFF (MONTH, 0,convert(varchar(10),StdDate,120)), 0)) -1)-1)/7 + 1  ) AS VARCHAR), 2)AS WeekOrigin
               , RIGHT('0'+ CAST(DATEPART(DD, CONVERT(VARCHAR(10), (CONVERT(datetime, StdDate)), 23) ) AS VARCHAR), 2) AS DD
            FROM #Date

--=========================
-- 데이터 테이블 
--=========================

-- 1. ROW DATA
 INSERT #DataSTDMWD
 SELECT A.CompanySeq
	  , A.InCompany
	  , CONCAT(A.STDYM, B.WK, B.DD) 
	  , A.EggTypeSeq
	  , A.EggGradeSeq
	  , A.EggMTypeSeq
	  , A.EggWeightSeq
	  , SUM(A.Qty) AS QTY
	  , B.MM
	  , B.WK
	  , B.DD
   FROM joinbio_DelvPlanSimulationMake   AS  A WITH (NOLOCK)
   LEFT OUTER JOIN #DayName			     AS  B WITH (NOLOCK) ON A.STDYMD = B.StdDate
  WHERE A.CompanySeq = @CompanySeq
	AND A.STDYMD BETWEEN @StdDateFr AND @StdDateTo
	AND A.InCompany LIKE '%' + @InCompany + '%'
    AND (@EggTypeSeq   = 0 OR A.EggTypeSeq   = @EggTypeSeq)
	AND (@EggMTypeSeq  = 0 OR A.EggMTypeSeq  = @EggMTypeSeq)
	AND (@EggGradeSeq  = 0 OR A.EggGradeSeq  = @EggGradeSeq)
	AND (@EggWeightSeq = 0 OR A.EggWeightSeq = @EggWeightSeq)

 GROUP BY A.CompanySeq
		, A.InCompany 
		, A.STDYM
		, A.EggTypeSeq
		, A.EggGradeSeq
		, A.EggMTypeSeq
		, A.EggWeightSeq
	    , B.MM
	    , B.WK
	    , B.DD

-- 2. 소계/ 주별
 INSERT #DataSTDMWD  -- EggGradeSeq 99
 SELECT CompanySeq
      , InCompany
 	  , LEFT(STDYMWD, 8) + '00'  AS STDYMWD
 	  , EggTypeSeq  
 	  , EggGradeSeq
 	  , EggMTypeSeq
 	  , EggWeightSeq
 	  , SUM(Qty)    AS QTY
 	  , MM
 	  , WK
 	  , '00' AS DD
   FROM #DataSTDMWD
 
  GROUP BY CompanySeq
         , InCompany
 	     , LEFT(STDYMWD, 8) 
 	     , EggTypeSeq  
 	     , EggGradeSeq
 	     , EggMTypeSeq
 	     , EggWeightSeq
 	     , MM
 	     , WK


-- 3. 소계/ 월별
 INSERT #DataSTDMWD  -- EggGradeSeq 99
 SELECT CompanySeq
      , InCompany
 	  , LEFT(STDYMWD, 6) + '0000'  AS STDYMWD
 	  , EggTypeSeq  
 	  , EggGradeSeq
 	  , EggMTypeSeq
 	  , EggWeightSeq
 	  , SUM(Qty)    AS QTY
 	  , MM
 	  , '00'
 	  , '00'
   FROM #DataSTDMWD
  WHERE DD = '00'
  GROUP BY CompanySeq
         , InCompany 
  	     , EggGradeSeq
  	     , LEFT(STDYMWD, 6)
 	     , EggTypeSeq  
 	     , EggGradeSeq
 	     , EggMTypeSeq
 	     , EggWeightSeq
 	     , MM

 -- 4. 원료중분류 소계 / 월별

 
 INSERT #DataSTDMWD  -- EggGradeSeq 99
 SELECT CompanySeq
      , InCompany
 	  , STDYMWD
 	  , EggTypeSeq   -- '소계'
 	  , EggGradeSeq
 	  , 2000182000  AS EggMTypeSeq
 	  , 2000226000  AS EggWeightSeq
 	  , SUM(Qty)    AS QTY
 	  , MM
 	  , WK
 	  , DD
   FROM #DataSTDMWD
 
  GROUP BY CompanySeq
         , InCompany
 	     , STDYMWD
		 , EggTypeSeq
		 , EggGradeSeq
 	     , MM
 	     , WK
 	     , DD


-- 5. 전체 원란형태 소계  4 > 5

 INSERT #DataSTDMWD  
 SELECT CompanySeq
      , '전체소계'     AS InCompany
 	  , STDYMWD
 	  , 2000227000     AS EggTypeSeq 
 	  , EggGradeSeq
 	  , 2000182000     AS EggMTypeSeq
 	  , 2000226000  AS EggWeightSeq
 	  , SUM(Qty)       AS QTY
 	  , MM
 	  , WK
 	  , DD
   FROM #DataSTDMWD
  WHERE EggMTypeSeq  = 2000182000
  GROUP BY CompanySeq
 	     , STDYMWD
 	     , EggGradeSeq
 	     , MM
 	     , WK
 	     , DD
		

------------------------------------------------------------------
	
	
	    INSERT INTO #Title 
        SELECT TitleSeq, Title
		  FROM (
		  
               SELECT DISTINCT STDYMWD AS  TitleSeq
--               	    , CASE WHEN WK = '00'  AND DD = '00'  THEN CONCAT(MM, '월') 
--					       WHEN WK <> '00' AND DD = '00'  THEN CONCAT(WK, '주') 

               	    , CASE WHEN WK = '00'  AND DD = '00'  THEN CONCAT(SUBSTRING(STDYMWD, 3, 2), '''', MM, '월') 
					       WHEN WK <> '00' AND DD = '00'  THEN CONCAT(SUBSTRING(STDYMWD, 3, 2), '''', MM, '''', REPLACE(WK, 0,''), '주') 
					       WHEN WK <> '00' AND DD <> '00' THEN CONCAT(SUBSTRING(STDYMWD, 3, 2), '/', MM, '/', DD)
						   ELSE '' END AS Title
                 FROM #DataSTDMWD
				GROUP BY STDYMWD, MM, WK, DD

			   ) AS A
--		 ORDER BY CASE WHEN TitleSeq = LEFT(TitleSeq, 6) + '0000' THEN 1
		 ORDER BY CASE WHEN TitleSeq = LEFT(TitleSeq, 6) + '0000' THEN TitleSeq / 10
			   ELSE TitleSeq END
--------------------------------------------------------------------





--==============================
-- 고정 테이블 구성 
--==============================

CREATE TABLE #FixTable 		-- 고정 테이블 // 다이나믹 시트 외 고정부분
(
	 RowIDX			INT IDENTITY (0, 1)  NOT NULL
   , CompanySeq		INT				     NOT NULL			-- 회사코드
   , InCompany		NVARCHAR(8)		     NOT NULL			-- 입고처명
   , EggTypeSeq		INT      			 NOT NULL			-- 품종코드
   , EggType	    VARCHAR(30)			 NOT NULL			-- 품종
   , EggGradeSeq	INT				     NOT NULL			-- 원란형태코드
   , EggGrade	    VARCHAR(30)			 NOT NULL			-- 원란형태
   , EggMTypeSeq	INT				     NOT NULL			-- 원료중분류코드
   , EggMType	    VARCHAR(30)			 NOT NULL			-- 원료중분류
   , EggWeightSeq	INT				     NOT NULL			-- 품목코드
   , EggWeight	    VARCHAR(30)			 NOT NULL			-- 품목
)


INSERT INTO #FixTable 
SELECT  A.CompanySeq
     ,  A.InCompany
     ,  A.EggTypeSeq
     , CASE WHEN EggTypeSeq   = 2000227000 THEN '' ELSE B1.MinorName  END   AS EggType
     ,  A.EggGradeSeq
     , CASE WHEN EggGradeSeq  = 2000192000  THEN '' ELSE B2.MinorName  END   AS EggGrade
     ,  A.EggMTypeSeq
--     , CASE WHEN EggMTypeSeq  = 2000182000  THEN '소계' ELSE B3.MinorName  END   AS EggMType   
     , CASE WHEN EggMTypeSeq  = 2000182000 AND InCompany = '전체소계' THEN '' 
	        WHEN EggMTypeSeq  = 2000182000 AND InCompany <> '전체소계' THEN '소계' 
			ELSE B3.MinorName  END   AS EggMType                                                -- '전체소계' 일때 원료중분류의 '소계' 안나오도록
     ,  A.EggWeightSeq
     , CASE WHEN EggWeightSeq = 2000226000  THEN '' ELSE B4.MinorName  END   AS EggWeight
  FROM (
        SELECT DISTINCT
		       CompanySeq , InCompany  , EggTypeSeq
             , EggGradeSeq, EggMTypeSeq, EggWeightSeq
          FROM #DataSTDMWD  
		 GROUP BY CompanySeq , InCompany  , EggTypeSeq
                , EggGradeSeq, EggMTypeSeq, EggWeightSeq
		) AS A
  LEFT OUTER JOIN _TDAUMinor  AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq AND A.EggTypeSeq   = B1.MinorSeq AND B1.MAjorSeq = 2000227
  LEFT OUTER JOIN _TDAUMinor  AS B2 WITH(NOLOCK) ON A.CompanySeq = B2.CompanySeq AND A.EggGradeSeq  = B2.MinorSeq AND B2.MAjorSeq = 2000192
  LEFT OUTER JOIN _TDAUMinor  AS B3 WITH(NOLOCK) ON A.CompanySeq = B3.CompanySeq AND A.EggMTypeSeq  = B3.MinorSeq AND B3.MAjorSeq = 2000182
  LEFT OUTER JOIN _TDAUMinor  AS B4 WITH(NOLOCK) ON A.CompanySeq = B4.CompanySeq AND A.EggWeightSeq = B4.MinorSeq AND B4.MAjorSeq = 2000226
 ORDER BY CASE WHEN InCompany = '전체소계' THEN 1      
               WHEN InCompany = '성본' THEN 2
               WHEN InCompany = '세양' THEN 3
               WHEN InCompany = '알로팜' THEN 4
               WHEN InCompany = '음성' THEN 5
               ELSE 99 END
        , A.EggTypeSeq
        , A.EggGradeSeq
        , A.EggMTypeSeq
        , A.EggWeightSeq

--========================================
-- DATATABLE 구성 
--========================================

 INSERT INTO #DataTable
 SELECT A.RowIDX
	  , B.COlIDX
      , ISNULL(C.Qty, 0)       AS Qty
  FROM #FixTable               AS A 
  LEFT JOIN #Title       AS B ON 1=1
  LEFT JOIN #DataSTDMWD  AS C WITH(NOLOCK) ON B.TitleSeq      = C.STDYMWD
                                                AND A.CompanySeq    = C.CompanySeq 
                                                AND A.InCompany     = C.InCompany
	                                            AND A.EggTypeSeq	= C.EggTypeSeq
	                                            AND A.EggGradeSeq	= C.EggGradeSeq
	                                            AND A.EggMTypeSeq	= C.EggMTypeSeq
	                                            AND A.EggWeightSeq  = C.EggWeightSeq

--------------------------------------------------


 
INSERT INTO #BIZ_OUT_DataBlock2(
			Title
		  , TitleSeq
		  )
	 SELECT Title, TitleSeq 
	   FROM #Title
	
INSERT INTO #BIZ_OUT_DataBlock3
			 ( CompanySeq	
             , InCompany	
             , EggTypeSeq	
             , EggType	    
             , EggGradeSeq	
             , EggGrade	    
             , EggMTypeSeq	
             , EggMType	    
             , EggWeightSeq	
             , EggWeight	
             )
	    SELECT CompanySeq	
             , InCompany	
             , EggTypeSeq	
             , EggType	    
             , EggGradeSeq	
             , EggGrade	    
             , EggMTypeSeq	
             , EggMType	    
             , EggWeightSeq	
             , EggWeight	
	      FROM #FixTable

INSERT INTO #BIZ_OUT_DataBlock4 (
			  RowIDX
			, ColIDX
			, Qty
			)
	 SELECT RowIDX, ColIDX,  Qty
	   FROM #DataTable




RETURN


