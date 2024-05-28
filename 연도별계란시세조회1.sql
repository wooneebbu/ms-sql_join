USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_EggMarketPriceByYearQuery1]    Script Date: 2024-02-14 오후 6:14:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 연도별 계란시세 조회1
    작 성 일 - 2024.02.14
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_EggMarketPriceByYearQuery1]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

--================================================
-- 사용변수 선언 & 조회조건 DATABLOCK에서 가져오기
--================================================

DECLARE		@EggGrade		NVARCHAR(10)
		,	@Region     	NVARCHAR(10)
		,	@ByYearTo		VARCHAR(4)
		,	@ByYearFrom		VARCHAR(4)

		
 SELECT		@EggGrade		= ISNULL(EggGrade,    '')
		,	@Region     	= ISNULL(Region,      '')
		,	@ByYearTo		= ISNULL(ByYearTo,    '')
		,	@ByYearFrom		= ISNULL(ByYearFrom,  '')


   FROM #BIZ_IN_DataBlock1 -- 조회조건 가져오는곳 


-- Temp Table, Temp DB에 있으면 지우기 ------------------------------------------------------------
IF OBJECT_ID('tempdb..#Temp_OrderNo')				IS NOT NULL DROP TABLE #Temp_OrderNo 
IF OBJECT_ID('tempdb..#Temp_OrderNo2')				IS NOT NULL DROP TABLE #Temp_OrderNo2
IF OBJECT_ID('tempdb..#EggMarketPrice')				IS NOT NULL DROP TABLE #EggMarketPrice
IF OBJECT_ID('tempdb..#TempEggMarketPrice')			IS NOT NULL DROP TABLE #TempEggMarketPrice
-------------------------------------------------------------------------------------------------	

	  ----------------------------------------------------    
	  --  등급 별 순번 테이블 생성
      ----------------------------------------------------
	  
	  CREATE TABLE #Temp_OrderNo
	  (
		  Grade			NVARCHAR(50),
		  GradeNo		INT
	  )

	  INSERT INTO #Temp_OrderNo(Grade, GradeNo)
	  VALUES ('왕란', 1), ('특란', 2), ('대란', 3), ('중란', 4), ('소란', 5)

	  ----------------------------------------------------    
	  --  지역 별 순번 테이블 생성
      ----------------------------------------------------
	  
	  CREATE TABLE #Temp_OrderNo2
	  (
		  Region		NVARCHAR(50),
		  RegionNo		INT
	  )

	  INSERT INTO #Temp_OrderNo2(Region, RegionNo)
	  --VALUES ('수도권', 1), ('경북', 2), ('경남', 3), ('전북', 4), ('전남', 5)
	  VALUES ('수도권', 1), ('경북', 2), ('경남', 3), ('전북', 4), ('전남', 5), ('경상', 6)	--230530 경상 추가


	  ----------------------------------------------------    
	  --  임시테이블 생성 (사용할 베이스 테이블)
      ----------------------------------------------------

		CREATE TABLE #EggMarketPrice (
									  CompanySeq	INT,
									  Type 			INT,
									  EggDT			VARCHAR(8),
									  STDDT			VARCHAR(8),
									  Region		VARCHAR(10),
									  Grade			VARCHAR(10),
									  Price			DECIMAL(19, 5)
										)
		INSERT #EggMarketPrice
		SELECT CompanySeq,
			   RPTType,
			   EggDT,
			   STDDT,	
			   Region,
			   Grade,	
			   Price	
		  FROM [JOIN].[dbo].[joinbio_FMEggMarketPrice]
		 WHERE 1=1
			   


        CREATE TABLE #TempEggMarketPrice (
				    			    	  CompanySeq	INT,
				    					  Type 			VARCHAR(20),
				    					  Region		VARCHAR(10),
				    					  StdYY   		VARCHAR(4),
				    					  EggGrade		VARCHAR(10),
				    					  Price			DECIMAL(19, 5)
										)
			  
  --====================================================================

--================================================
-- 사용할 베이스 테이블 생성 
--================================================

  INSERT INTO #TempEggMarketPrice (
									CompanySeq
									--  TypeSeq
									, Type
                                    , StdYY
									, Region
									, EggGrade
									, Price									
							
  )
   SELECT @CompanySeq
   		--, T.Type
		, B.MinorName AS Type
        , T.StdYY
		, T.Region
		, T.Grade  AS EggGrade
		, T.Price
		FROM (
                   SELECT B.CompanySeq
                		, B.Type
                		, B.StdYY
                		, B.Region
                		, 0 AS RegionNo
                		, B.Grade
                		, B.GradeNo
                		, SUM(B.Price) AS Price
                     FROM ( 
                						 SELECT   A.CompanySeq
                								, A.Type
                								, A.StdYY
                						 		, A.Grade
                								, B.GradeNo
                								, '평균' AS Region
                								, 0		AS RegionNo
                								, AVG(A.Price) AS Price
                								, COUNT(A.Region) AS CNT
                						 FROM (
                												SELECT    CompanySeq
                														, CASE WHEN Type = 2000153001 OR Type = 2000153003 THEN 2000153001 ELSE Type END Type 
                														, LEFT(STDDT, 4) AS StdYY
                														, Grade
                														--, Region
                														, CASE WHEN Region = '경기' OR Region = '수도권' OR Region = '충청' THEN '수도권' 
                															   WHEN Region = '경상' OR Region = '경남' OR Region = '경북' OR Region = '영주' THEN '경상'
                														  ELSE Region END AS Region
                														-- , COUNT(*) AS CNT
                														, Price
                												FROM #EggMarketPrice
                												--GROUP BY Type, LEFT(STDDT, 6), Grade, Region , Price
                								) AS A
                						 INNER JOIN #Temp_OrderNo  AS B	ON A.Grade  = B.Grade
                						 INNER JOIN #Temp_OrderNo2 AS C ON A.Region = C.Region
                						 GROUP BY A.CompanySeq, A.Type, A.StdYY, B.GradeNo, A.Grade --,A.Region --, A.Price
                	) AS B
                  WHERE 1=1
                  GROUP BY B.CompanySeq, B.Type, B.Region, B.Grade, B.GradeNo, B.Price , B.STDYY--, B.Price
                
                  UNION ALL
                
                  SELECT  B.CompanySeq
                        , B.Type
                		, B.StdYY
                		, B.Region
                		, B.RegionNo
                		, B.Grade
                		, B.GradeNo
                		, SUM(B.Price) AS Price
                  FROM( 
                						 SELECT  A.CompanySeq 
                								, A.Type
                								, A.StdYY
                						 		, A.Grade
                								, B.GradeNo
                								, A.Region
                								, C.RegionNo
                								, AVG(A.Price) AS Price
                								--, COUNT(*) AS CNT
                						 FROM (
                												SELECT   CompanySeq 
                														,CASE WHEN Type = 2000153001 OR Type = 2000153003 THEN 2000153001 ELSE Type END Type 
                														,LEFT(STDDT, 4) AS StdYY
                														, Grade
                														--, Region
                														, CASE WHEN Region = '경기' OR Region = '수도권' OR Region = '충청' THEN '수도권' 
                															   WHEN Region = '경상' OR Region = '경남' OR Region = '경북' OR Region = '영주' THEN '경상'
                														  ELSE Region END AS Region
                														-- , COUNT(*) AS CNT
                														, Price
                												FROM #EggMarketPrice
                											    -- GROUP BY CompanySeq, Type, LEFT(STDDT, 4), Grade, Region, Price
                								) AS A
                						 INNER JOIN #Temp_OrderNo  AS B	ON A.Grade  = B.Grade
                						 INNER JOIN #Temp_OrderNo2 AS C ON A.Region = C.Region
                						 GROUP BY  A.CompanySeq, A.Type, A.StdYY, B.GradeNo, C.RegionNo, A.Grade, A.Region --, A.Price
                	) AS B
                  WHERE 1=1
                  GROUP BY  B.CompanySeq, B.Type, B.Region, B.Grade, B.RegionNo, B.GradeNo , B.STDYY--, B.Price
  ) AS T
  LEFT JOIN _TDAUMinor AS B ON  T.CompanySeq = B.CompanySeq 
							AND T.Type		 = B.MinorSeq 
							AND B.MajorSeq	 = 2000153
  WHERE T.CompanySeq = @CompanySeq
	AND T.Grade LIKE '%' + @EggGrade + '%' 
	AND (T.Region LIKE '%' + @Region	+ '%' OR T.Region = '평균')
	-- AND T.EggColor LIKE '%' + @EggColor + '%'
  ORDER BY T.RegionNo, T.GradeNo ASC


--========================
 --TEMP TABLE 사전 정리
--========================

  IF OBJECT_ID('tempdb..#Title')		IS NOT NULL DROP TABLE #Title
  IF OBJECT_ID('tempdb..#FixTable')		IS NOT NULL DROP TABLE #FixTable
  IF OBJECT_ID('tempdb..#DataTable')	IS NOT NULL DROP TABLE #DataTable



--==========================
--TEMP TABLE 구성
--==========================

CREATE TABLE #Title 
(
	  ColIDX		INT IDENTITY (0, 1)  NOT NULL -- 자동 인덱스 구성 
	, Title			NVARCHAR(30)		 NOT NULL
	, TitleSeq		NVARCHAR(8)			 NOT NULL
)



CREATE TABLE #FixTable
(
	  RowIDX		INT IDENTITY (0, 1)  NOT NULL  -- 자동인덱스 구성 // 조회에 둘다 들어감 col, row
	, Type      	NVARCHAR(20)		 NOT NULL
	, Region		NVARCHAR(10) 		 NOT NULL
	, EggGrade		NVARCHAR(10) 		 NOT NULL
	, CompanySeq	INT					 NOT NULL
)	


CREATE TABLE #DataTable -- 다이나믹테이블 고정테이블 헤더 날짜기준으로 인덱스 생성
(	
	  RowIDX		INT					 NOT NULL
	, ColIDX		INT					 NOT NULL
	, ByYear		DECIMAL (19, 5)		 NOT NULL -- 연도별 시세
)


--================================================================
-- #TITLE TABLE 구성 // TITLESEQ 는 날짜데이터활용과 JOIN 값으로 활용
--================================================================

INSERT INTO #Title (TitleSeq, Title)
	 SELECT DISTINCT  StdYY AS TitleSeq
					, LEFT(StdYY, 4) AS Title   
	   FROM #TempEggMarketPrice
       WHERE 1=1

--===============================================
-- #FIX TABLE 구성 
--===============================================

INSERT INTO #FixTable (Type, Region, EggGrade, CompanySeq)
	SELECT   Type
           , Region		
           , EggGrade
           , CompanySeq
            FROM #TempEggMarketPrice
            WHERE 1=1
			GROUP By Type
					, Region		
					, EggGrade
					, CompanySeq
			ORDER BY -- (CASE WHEN EggColor = '갈색란' THEN 1 ELSE 2 END)
					--, (CASE WHEN EggValue = '일반' THEN 1 ELSE 0 END)
					 (CASE WHEN Region  = '평균'	THEN 1 
						   WHEN Region  = '수도권'  THEN 2
						   WHEN Region  = '전북'	THEN 3
						   WHEN Region  = '전남'	THEN 4 ELSE 99 END)
					, (CASE WHEN EggGrade = '왕란' THEN 1 
						    WHEN EggGrade = '특란' THEN 2 
						    WHEN EggGrade = '대란' THEN 3 
						    WHEN EggGrade = '중란' THEN 4 
						    WHEN EggGrade = '소란' THEN 5 ELSE 99 END)

--=========================================================================
-- DATA TABLE 구성 // 만들어지는 데이터와 고정필드의 JOIN 
-- K-STUDIO 방식이 ROW > COL 순으로 읽음 ROWIDX ,COLIDX, 가변필드 순으로 조회
--=========================================================================


    INSERT INTO #DataTable
	SELECT C.RowIDX
	     , B.ColIDX
	     , ISNULL(A.Price, 0) AS ByYear
	  FROM #TempEggMarketPrice          	AS A WITH(NOLOCK)
	  LEFT OUTER JOIN #Title				AS B WITH(NOLOCK) ON A.StdYY		= B.TitleSeq
	  LEFT OUTER JOIN #FixTable				AS C WITH(NOLOCK) ON A.CompanySeq	= C.CompanySeq
															 AND A.Type	        = C.Type
															 AND A.Region       = C.Region
															 AND A.EggGrade     = C.EggGrade

	WHERE A.CompanySeq	 = @CompanySeq
      AND A.Region     LIKE '%' + @Region + '%'
      AND A.EggGrade     LIKE '%' + @EggGrade + '%'
	  AND (((CONVERT(INT, A.ByYear) BETWEEN @ByYearFrom AND @ByYearTo) OR (@ByYearFrom = 0 AND @ByYearTo = 0))
																				  OR (@ByYearFrom = 0 AND (CONVERT(INT, A.ByYear) <= @@ByYearTo))
																				  OR ((@ByYearFrom <= CONVERT(INT, A.ByYear)) AND @ByYearTo = 0))

--====================================================
--BIZ_OUT_DATA BLOCK TABLE에 각각 정리된 DATA입력
-- > 타이틀/고정부에는 IDX 입력 안함
-- > TITLE/ TITLESEQ 순으로 입력
--====================================================


INSERT INTO #BIZ_OUT_DataBlock2(Title, TitleSeq)
	 SELECT Title, TitleSeq 
	   FROM #Title

INSERT INTO #BIZ_OUT_DataBlock3
			 (
                Type 
              , Region
              , EggGrade
              , CompanySeq
             )
	 SELECT    Type 
              , Region
              , EggGrade
              , CompanySeq
	   FROM #FixTable

INSERT INTO #BIZ_OUT_DataBlock4(RowIDX, ColIDX, ByYear)
	 SELECT RowIDX, ColIDX, ByYear
	   FROM #DataTable
RETURN