USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_EggMarketPriceByYearQuery2]    Script Date: 2024-02-14 오후 6:15:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 연도별 계란시세 조회2
    작 성 일 - 2024.02.14
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_EggMarketPriceByYearQuery2]               
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
		,	@EggColor     	NVARCHAR(10)
		,	@EggValue_Cb    INT 
		
 SELECT		@EggGrade		= ISNULL(EggGrade,    '')
		,	@EggColor     	= ISNULL(EggColor,    '')
		,	@EggValue_Cb    = ISNULL(EggValue_Cb,  0)

   FROM #BIZ_IN_DataBlock1 -- 조회조건 가져오는곳 

--========================
 --TEMP TABLE 사전 정리
--========================

IF OBJECT_ID('tempdb..#EggMarketPriceDelv')			IS NOT NULL DROP TABLE #EggMarketPriceDelv

--================================================
-- 사용할 베이스 테이블 생성 
--================================================
	CREATE TABLE #EggMarketPriceDelv (
										 CompanySeq	     INT
										, Type			 VARCHAR(20)
										, EggColor		 VARCHAR(20)
										, EggValue		 VARCHAR(20)  -- 유정란/일반란 240207
										, Cust			 VARCHAR(8)
										, StdYY 		 VARCHAR(4)
										, EggGrade		 VARCHAR(10)
										, Price			 DECIMAL(19, 5)
										, Qty			 DECIMAL(19, 5)
										, CurAmt	     DECIMAL(19, 5)
										)
   
		INSERT #EggMarketPriceDelv
		    SELECT A.CompanySeq
				  , '구매단가' AS Type
				  , EggColor
				  , EggValue		 -- 유정란/일반란 240207
				  , Cust
				  , StdYY
				  , EggGrade
				--, ROUND(AVG(Price), 0) AS Price
				  , ROUND(SUM(CurAmt) / SUM(Qty) , 0) AS Price
				  , SUM(Qty)      AS Qty
				  , SUM(CurAmt)	  AS CurAmt
			FROM (	
		         SELECT A.CompanySeq 
		        	  , LEFT(B.DelvInDate, 4) AS StdYY
                      , CASE WHEN G.MngValText LIKE '%백색%' OR E.ItemName LIKE '%백색%' THEN '백색란' ELSE '갈색란' END AS EggColor
		        	  , CASE WHEN I.ValueText = 1 THEN '유정' ELSE '일반' END AS EggValue
                      , CASE WHEN D.MngValSeq = 2000056001 THEN '외부' ELSE '내부'    END AS Cust
                	  , RIGHT(F.MngValText, 2) AS EggGrade
                	  , A.Qty
                      , A.CurAmt
                   FROM [JOIN].[dbo]._TPUDelvInItem                AS A  WITH(NOLOCK) --구매입고품목    
                   JOIN [JOIN].[dbo]._TPUDelvIn                    AS B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  AND A.DelvInSeq = B.DelvInSeq    
                   LEFT OUTER JOIN [JOIN].[dbo]._TDACust           AS C  WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq  AND B.CustSeq   = C.CustSeq    
                   LEFT OUTER JOIN [JOIN].[dbo]._TDACustUserDefine AS D  WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq  AND C.CustSeq   = D.CustSeq     AND D.MngSerl = 1000003
                   LEFT OUTER JOIN [JOIN].[dbo]._TDAItem           AS E  WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.ItemSeq   = E.ItemSeq    				  
                   LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS F  WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  AND A.ItemSeq   = F.ItemSeq     AND F.MngSerl = 1000008  --원란구분  
                   LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS G  WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  AND A.ItemSeq   = G.ItemSeq     AND G.MngSerl = 1000013  --난중구분
		           LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS H  WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq  AND A.ItemSeq	  = H.ItemSeq	  AND H.MngSerl	= 1000037  --원료구분(소) 
		           LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue	   AS I  WITH(NOLOCK) ON H.CompanySeq = I.CompanySeq  AND H.MngValSeq = I.MinorSeq	
		                                                                             AND I.MajorSeq   = 2000181       AND I.Serl	  = 1000004  --원료구분(소) / 유정란 여부 
		        															          -- MajorSeq 에 대한 별도 이슈 발생으로 추가(Text > INT 변환 불가)
       	          WHERE E.AssetSeq IN (1, 6) -- 상품, 원재료
                    AND F.MngValSeq < 2000031006 -- 품목그룹 [왕/특/대/중/소]만 조회
                    AND ISNULL(F.MngValSeq, 0) <> 0  
                    -- AND B.DelvInDate LIKE '2022%'
                    AND B.CustSeq <> 11015 --거래처 [조인용인지점(서이천), 11015] 제외
                    AND ISNULL(A.LOTNo, '') <> ''  
		            AND I.ValueText = @EggValue_Cb  -- 일반/유정 조회		
		 	 ) AS A
	   WHERE A.CompanySeq = @CompanySeq
		 AND A.EggGrade  LIKE '%' + @EggGrade + '%' 
		 AND A.EggColor  LIKE '%' + @EggColor + '%'
	   GROUP BY CompanySeq
			   , EggColor
			   , EggValue
		       , StdYY
			   , Cust
			   , EggGrade

--===============================================
-- 전체 평균용 추가 
--================================================

		INSERT #EggMarketPriceDelv
		SELECT    CompanySeq
				, '구매단가' AS Type
				, EggColor
				, EggValue
				, '평균'  AS Cust			 
				, StdYY 			
				, EggGrade			 
				, ROUND(SUM(CurAmt) / SUM(Qty) , 0) AS Price
				, SUM(Qty)    AS Qty
				, SUM(CurAmt) AS CurAmt
          FROM #EggMarketPriceDelv
		 GROUP BY CompanySeq
				, EggColor	
				, EggValue
				, StdYY 			
				, EggGrade		



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
	, EggValue		NVARCHAR(10) 		 NOT NULL
	, EggColor		NVARCHAR(10) 		 NOT NULL
	, Cust  		NVARCHAR(10) 		 NOT NULL
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
	   FROM #EggMarketPriceDelv
       WHERE 1=1

--===============================================
-- #FIX TABLE 구성 
--===============================================

INSERT INTO #FixTable (Type, EggValue, EggColor, Cust, EggGrade, CompanySeq)
	SELECT    Type
            , EggValue
            , EggColor
            , Cust  		
            , EggGrade
            , CompanySeq
            FROM #EggMarketPriceDelv
            WHERE 1=1
			GROUP By  Type
            , EggValue
            , EggColor
            , Cust  		
            , EggGrade
            , CompanySeq
		    ORDER BY  (CASE WHEN EggColor = '갈색란' THEN 1 ELSE 2 END)
					, (CASE WHEN EggValue = '일반' THEN 1 ELSE 0 END)
					, (CASE WHEN Cust  = '평균' THEN 1 
							WHEN Cust  = '외부' THEN 2
							ELSE 99 END)
					, (CASE WHEN EggGrade = '왕란' THEN 1 
						    WHEN EggGrade = '특란' THEN 2 
						    WHEN EggGrade = '대란' THEN 3 
						    WHEN EggGrade = '중란' THEN 4 
						    WHEN EggGrade = '소란' THEN 5 
						    ELSE 99 END)

--=========================================================================
-- DATA TABLE 구성 // 만들어지는 데이터와 고정필드의 JOIN 
-- K-STUDIO 방식이 ROW > COL 순으로 읽음 ROWIDX ,COLIDX, 가변필드 순으로 조회
--=========================================================================

INSERT INTO #DataTable
	SELECT	C.RowIDX
		  , B.ColIDX
		  , ISNULL(A.Price, 0) AS ByYear
	 FROM  #EggMarketPriceDelv          	AS A WITH(NOLOCK)
	 LEFT OUTER JOIN #Title					AS B WITH(NOLOCK) ON A.StdYY		= B.TitleSeq
	 LEFT OUTER JOIN #FixTable				AS C WITH(NOLOCK) ON A.CompanySeq	= C.CompanySeq
															 AND A.Type	        = C.Type
															 AND A.EggValue		= C.EggValue
															 AND A.EggColor     = C.EggColor
															 AND A.Cust         = C.Cust
															 AND A.EggGrade     = C.EggGrade

	WHERE A.CompanySeq	 = @CompanySeq
      AND A.EggColor     LIKE '%' + @EggColor + '%'
      AND A.EggGrade     LIKE '%' + @EggGrade + '%'
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
              , EggValue
              , EggColor
              , Cust
              , EggGrade
              , CompanySeq
             )
	 SELECT    Type 
              , EggValue
              , EggColor
              , Cust
              , EggGrade
              , CompanySeq 
	   FROM #FixTable

INSERT INTO #BIZ_OUT_DataBlock4(RowIDX, ColIDX, ByYear)
	 SELECT RowIDX, ColIDX, ByYear
	   FROM #DataTable
RETURN