USE [JOIN]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_ConsolComplainQueryDetail]    Script Date: 2024-07-02 오후 4:55:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 통합클레임발생보고디테일_joinbio
    작 성 일 - 2024.06.21
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_ConsolComplainQueryDetail]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,					
    @IsTransaction     INT         = 0                               
AS          
         
--=========================
-- 변수 선언 1 조회조건 
--=========================

  DECLARE @StdYM			VARCHAR(6)
        , @STDYMTo			VARCHAR(6)
	    , @Cons_UMItemSeq	INT
	    , @Cons_UMItemName	VARCHAR(20)

   SELECT @StdYM	         = ISNULL(StdYM, '')
        , @Cons_UMItemSeq	 = ISNULL(Cons_UMItemSeq, 0)
     FROM #BIZ_IN_DataBlock1  -- 조회조건을 가져오는 Table이 datablock1 인지 2인지 화살표랑 속성값 datablock 확인할것 
  


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
    SET ANSI_WARNINGS OFF  -- 0나누기 오류
    SET ARITHIGNORE ON 
    SET ARITHABORT OFF
-- 검색조건들 (변수값 조회화면에서 받아오는값)


DECLARE @StdYY VARCHAR(4)
--DECLARE @StdYM VARCHAR(6)
DECLARE @PreStdYY VARCHAR(4)
DECLARE @PreStdYM VARCHAR(6)

 
	SET @StdYY	  = LEFT(@StdYM, 4)
	SET @PreStdYY = @StdYY-1
	SET @PreStdYM = LEFT(@PreStdYY, 4) + RIGHT(@StdYM, 2)


--========================================
-- 임시테이블 세팅 / Temp Table 정리
--========================================

IF OBJECT_ID('tempdb..#Consol_Complain')	 IS NOT NULL DROP TABLE #Consol_Complain
IF OBJECT_ID('tempdb..#Code_TEMP')			 IS NOT NULL DROP TABLE #Code_TEMP
IF OBJECT_ID('tempdb..#InvoiceSum')			 IS NOT NULL DROP TABLE #InvoiceSum

--======================================
-- TEMP TABLE 구성 / code 모음 테이블
--======================================

    PRINT 'code 모음 테이블'
    
    CREATE TABLE #Code_TEMP (
    			 Companyseq	 INT
    			,MinorSSeq	 INT
    			,MinorSName	 NVARCHAR(50)
    			,MinorMSeq	 INT
    			,MinorMName	 NVARCHAR(50)
    			,MinorLSeq	 INT
    			,MinorLName	 NVARCHAR(50)
    			,IsUse		 INT
    			,IsClaim	 INT
    			)
    CREATE CLUSTERED INDEX IDX_#Code_TEMP ON #Code_TEMP(CompanySeq, MinorSSeq)						          
    
    INSERT #Code_TEMP
    SELECT A.CompanySeq
         , A.MinorSeq                   AS 소분류Seq
         , A.MinorName                  AS 소분류명
         , ISNULL(C.MinorSeq, '')		AS 중분류Seq --중분류  
         , ISNULL(C.MinorName, '')		AS 중분류명 --중분류명
         , ISNULL(C2.MinorSeq, '')		AS 대분류Seq  --대분류   
         , ISNULL(C2.MinorName, '')		AS 대분류명 --대분류명     
         , A.IsUse
         , ISNULL(D2.ValueText, 0) AS IsClaim
    
      FROM [JOIN].[dbo].[_TDAUMinor]			   AS  A with(nolock) 
      LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS  B with(nolock)   ON A.CompanySeq  = B.CompanySeq
                                                                       AND A.MajorSeq    = B.MajorSeq
                                                                       AND A.MinorSeq    = B.MinorSeq 
                                                                       AND B.Serl        = 1000001
      LEFT OUTER JOIN [JOIN].[dbo].[_TDAUMinor]    AS  C with(nolock)   ON B.ValueSeq    = C.MinorSeq 
                                                                       AND B.CompanySeq  = C.CompanySeq  
    													 			   AND C.MajorSeq    = 2000154
      LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS  D with(nolock)   ON C.MinorSeq    = D.MinorSeq 
                                                                       AND C.MajorSeq    = D.MajorSeq 
                                                                       AND C.CompanySeq  = D.CompanySeq        
                                                                       AND D.Serl        = 1000001 
      LEFT OUTER JOIN [JOIN].[dbo].[_TDAUMinor]    AS C2 with(nolock)   ON D.ValueSeq    = C2.MinorSeq 
                                                                       AND D.CompanySeq  = C2.CompanySeq
    															       AND C2.MajorSeq   = 2000155
      LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS D2 with(nolock)   ON C2.MinorSeq   = D2.MinorSeq 
                                                                       AND C2.MajorSeq   = D2.MajorSeq 
                                                                       AND C2.CompanySeq = D2.CompanySeq
                                                                       AND D2.Serl       = 1000001 
      WHERE A.MajorSeq = 2000016
        AND ISNULL(D2.ValueText, 0) <> 0
      ORDER BY A.CompanySeq, A.MinorSeq
    
    --  SELECT * FROM #Code_TEMP

--======================================
-- TEMP TABLE 구성 / INVOICESUM
--======================================
PRINT 'INVOICESUM 테이블'

CREATE TABLE #InvoiceSum (
			 Companyseq	        INT
		   , ComplainCodeSeq    INT
		   , InvoiceYM	        VARCHAR(6)
		   , InoutSeq 	        INT
		   , MainFactUnitSeq	INT
		   , MainFactUnitName	NVARCHAR(100)
		   , UMItemSeq	        INT
		   , UMItemName	        NVARCHAR(100)
		   , ComplainCnt        DECIMAL(19,5)
		   , Qty     	        DECIMAL(19,5)
			)
CREATE NONCLUSTERED INDEX IDX_#InvoiceSum ON #InvoiceSum(CompanySeq, ComplainCodeSeq, InvoiceYM, MainFactUnitSeq)						          

INSERT INTO #InvoiceSum


    SELECT A.CompanySeq     , B.ComplainCodeSeq
         , A.InvoiceYM      , B.InOutSeq
         , A.MainFactUnitSeq, A.MainFactUnitName
         , A.QCTypeSeq      , A.QCTypeNAme
    	 , ISNULL(B.ComplainCnt, 0) AS ComplainCnt
    	 , ISNULL(A.Qty ,0) AS Qty
     FROM (
           SELECT A.CompanySeq     , A.InvoiceYM
                , A.ItemSeq        , 3 AS SalesUnitSeq
           	    , ISNULL(C.MainFactUnitSeq , 0)  AS MainFactUnitSeq
				, ISNULL(C.MainFactUnitName, '사업장없음') AS MainFactUnitName
           	    , ISNULL(C.QCTypeSeq , 0)  AS QCTypeSeq     
				, ISNULL(C.QCTypeNAme, '품질유형없음')	AS QCTypeNAme
                , ISNULL(SUM(CASE WHEN A.SalesUnitName  = '팩' or B.UnitName   = 'Pack' THEN SalesQty
                	    ELSE A.StdQty * B.ConvDen/B.ConvNum END ), 0) AS Qty
             FROM [JOIN_DC].[DBO].[joinbio_TSLInvoiceSum_Group]  AS A 
             LEFT OUTER JOIN [JOIN_DC].[dbo].[joinbio_ItemUnitList_Group] AS B ON A.CompanySeq = B.CompanySeq 
                                                                              AND A.ItemSeq    = B.ItemSeq
                                                                              AND (B.UnitName  = '팩' or B.UnitName   = 'Pack')
             LEFT OUTER JOIN [JOIN_DC].[dbo].[joinbio_ItemClassList]      AS C ON A.CompanySeq = C.CompanySeq
                                                                              AND A.ItemSeq    = C.ItemSeq
           
        	WHERE 1=1
			  AND A.CompanySeq = @CompanySeq
        	  AND (LEFT(InvoiceYM, 4) = @PreStdYY   or LEFT(InvoiceYM, 4)  = @StdYY)      
        	  AND C.MainFactUnitName NOT IN ('상품')		
			  AND (C.ItemName NOT LIKE '%선별%' AND C.ItemName NOT LIKE '%무특%' AND C.ItemName NOT LIKE '%내부매출%')
        	  --AND C.MainFactUnitName IS NOT NULL		
        	GROUP BY A.CompanySeq
        	       , A.InvoiceYM
        		   , A.ItemSeq   
        		   , A.StdUnitSeq
        		   , C.MainFactUnitSeq
        	       , C.MainFactUnitName
        	       , C.QCTypeSeq
        	       , C.QCTypeNAme
         ) AS A
    LEFT OUTER JOIN (
	                
                        SELECT CompanySeq, ComplainCodeSeq
		            		, LEFT(OccuDate , 6) AS OccuYM
		            		, GoodSeq, InoutSeq
		            		, COUNT(ComplainSeq) AS ComplainCnt
		            	 FROM [JOIN].[dbo].join_TPDQCComplain
		            	WHERE 1=1 
		                  AND (LEFT(OccuDate , 4) = @PreStdYY or LEFT(OccuDate , 4)  = @StdYY)
			              AND CompanySeq = @CompanySeq
		            
					    GROUP BY CompanySeq, ComplainCodeSeq
		            		   , LEFT(OccuDate , 6) 
		            		   , GoodSeq, InoutSeq
				    ) AS B ON A.CompanySeq = B.CompanySeq
					      AND A.ItemSeq    = B.GoodSeq			
						  AND A.InvoiceYM  = B.OccuYM
 WHERE 1=1


--  SELECT * FROM #InvoiceSum

--======================================
-- TEMP TABLE 구성 / 통합테이블
--======================================

PRINT '통합테이블_기준연도'

CREATE TABLE #Consol_Complain (
			Companyseq			INT
		  , ComplainCodeSeq		INT
		  , OccuYM		     	NVARCHAR(6)
		  , ComplainCnt			Float
		  , SalesQty			Float
		  , UMItemSeq			INT
		  , UMItemName			NVARCHAR(20)
		  , ConsSeq				INT
		  , ConsName			NVARCHAR(20)
		  , MinorSSeq			INT
		  , MinorSName			NVARCHAR(50)
		  , MinorMSeq 			INT
		  , MinorMName			NVARCHAR(50)
		  , MinorLSeq 			INT
		  , MinorLName			NVARCHAR(50)
		  , IsUse			    INT
		  , IsClaim			    INT
		)
-- CREATE CLUSTERED INDEX IDX_#Consol_Complain ON #Consol_Complain(CompanySeq, ComplainCodeSeq, ItemSeq)						          


    INSERT #Consol_Complain

    SELECT A.CompanySeq  
    	 , A.ComplainCodeSeq
    	 , A.InvoiceYM AS OccuYM
    	 , A.ComplainCnt
    	 , A.Qty       AS SalesQty
    	 , A.UMItemSeq	     	AS UMItemSeq 
    	 , A.UMItemName	        AS UMItemName
    	 , A.MainFactUnitSeq	AS ConsSeq
    	 , A.MainFactUnitName   AS ConsName
    	 , T.MinorSSeq  
    	 , T.MinorSName  
    	 , T.MinorMSeq  
    	 , T.MinorMName  
    	 , T.MinorLSeq  
    	 , T.MinorLName  
    	 , T.IsUse
    	 , T.IsClaim
      FROM #InvoiceSum AS A
      LEFT OUTER JOIN #Code_TEMP						   AS T WITH(NOLOCK)  ON A.CompanySeq      = T.CompanySeq
      												  				         AND A.ComplainCodeSeq = T.MinorSSeq
      
     WHERE 1=1
	   AND T.IsClaim is not null
       -- LEFT(A.InvoiceYM, 4) = @StdYY 
     ORDER BY A.CompanySeq  
      	    , A.ComplainCodeSeq

--SELECT * FROM #Consol_Complain




--=========================
-- 데이터 테이블 
--=========================

INSERT INTO #BIZ_OUT_DataBlock2 (
				CompanySeq
			  , Cons_UMItemSeq
			  , Cons_UMItemName
			  , YMType
			  , DetailType
			  , YY_Sum
			  , YMTotal
			  , MinorMSeq01
			  , MinorMSeq02
			  , MinorMSeq03
			  , MinorMSeq04
			  , MinorMSeq05
			  , MinorMSeq06
			  ,	MinorMSeq07
			  , MinorMSeq08
			  , MinorMSeq09
			  , MinorMSeq10
			  ,	MinorMSeq11
			  ,	MinorMSeq12
			  ,	MinorMSeq13
			  ,	MinorMSeq14
			  ) 
			 
SELECT  @CompanySeq 
	   , T.ConsSeq   AS Cons_UMItemSeq
	   , T.ConsName  AS Cons_UMItemName
	   , T.YMType
	   , T.DetailType 
	   , T.YY_Sum
	   , T.YMTotal
	   , MinorMSeq01
	   , MinorMSeq02
	   , MinorMSeq03
	   , MinorMSeq04
	   , MinorMSeq05
	   , MinorMSeq06
	   , MinorMSeq07
	   , MinorMSeq08
	   , MinorMSeq09
	   , MinorMSeq10
	   , MinorMSeq11
	   , MinorMSeq12
	   , MinorMSeq13
	   , MinorMSeq14
 FROM (
 ---------------------
 -- 생산사업장 증감 
 ---------------------

 SELECT @CompanySeq	  AS CompanySeq 									
		  , ConsSeq   AS ConsSeq
		  , ConsName  AS ConsName
		  , '증감'    AS YMType
		  , 'PPM'     AS DetailType
		  ,  ROUND(((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY	    THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY	   THEN SalesQty END)) * 1000000)
		   - ((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY    THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY    THEN SalesQty END)) * 1000000), 1) AS YY_Sum
		  ,  ROUND(((SUM(CASE WHEN OccuYM			= @StdYM    THEN ComplainCnt END)/SUM(CASE WHEN OccuYM			= @StdYM    THEN SalesQty END)) * 1000000) 
		   - ((SUM(CASE WHEN OccuYM			= @PreStdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM			= @PreStdYM THEN SalesQty END)) * 1000000), 1) AS YMTotal
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq01
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq02	 
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq03
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1)AS MinorMSeq04
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq05
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq06
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq07
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq08
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq09
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq10
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq11
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq12
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq13
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		   - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1 
	  -- AND MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

	UNION ALL

	 SELECT @CompanySeq	AS CompanySeq 										
		  , ConsSeq     AS ConsSeq
		  , ConsName    AS ConsName
		  , '증감'		AS YMType
		  , '발생건수'  AS DetailType
		  ,   (SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY	 THEN ComplainCnt END)) 
		   -  (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) AS YY_Sum
		  ,   (SUM(CASE WHEN OccuYM			 = @StdYM    THEN ComplainCnt END)) 
		   -  (SUM(CASE WHEN OccuYM			 = @PreStdYM THEN ComplainCnt END)) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0) AS MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0) AS MinorMSeq02	 
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0) AS MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0) AS MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0) AS MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0) AS MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0) AS MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0) AS MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0) AS MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0) AS MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0) AS MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0) AS MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0)
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0) AS MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1 
	  -- MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

   UNION ALL

     SELECT @CompanySeq	  AS CompanySeq 									
		  , UMItemSeq     AS ConsSeq
		  , UMItemName	  AS ConsName
		  , '증감'        AS YMType
		  , 'PPM'         AS DetailType
		  ,  ROUND(((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY	   THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY	   THEN SalesQty END)) * 1000000)
		         - ((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty END)) * 1000000), 1) AS YY_Sum
		  ,  ROUND(((SUM(CASE WHEN OccuYM		   = @StdYM    THEN ComplainCnt END)/SUM(CASE WHEN OccuYM		   = @StdYM    THEN SalesQty END)) * 1000000) 
		         - ((SUM(CASE WHEN OccuYM		   = @PreStdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM		   = @PreStdYM THEN SalesQty END)) * 1000000), 1) AS YMTotal
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq01
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq02	 
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq03
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq04
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq05
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq06
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq07
		  ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq08
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq09
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq10
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq11
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq12
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq13
	      ,  ROUND((ISNULL((SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM    THEN SalesQty END)) * 1000000 , 0)) 
		         - (ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0)), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  -- MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL

	 SELECT @CompanySeq	AS CompanySeq 										
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , '증감'		AS YMType
		  , '발생건수'  AS DetailType
		  ,   (SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END)) 
		   -  (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) AS YY_Sum
		  ,   (SUM(CASE WHEN OccuYM			 = @StdYM    THEN ComplainCnt END)) 
		   -  (SUM(CASE WHEN OccuYM			 = @PreStdYM THEN ComplainCnt END)) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0) AS MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0) AS MinorMSeq02	 
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0) AS MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0) AS MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0) AS MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0) AS MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0) AS MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0) AS MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0) AS MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0) AS MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0) AS MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0) AS MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0)
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0) AS MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM    AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0) 
		   - ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL

 ---------------------
 -- 생산사업장 비교연월
 ---------------------
	SELECT @CompanySeq	AS CompanySeq 										
		  , ConsSeq     AS ConsSeq
		  , ConsName	AS ConsName
		  , @PreStdYM   AS YMType
		  , 'PPM'       AS DetailType
		  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty END)) * 1000000, 1) AS YY_Sum
		  , ROUND((SUM(CASE WHEN OccuYM			 = @PreStdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM			 = @PreStdYM THEN SalesQty END)) * 1000000, 1) AS YMTotal
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq01
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq02	 
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq03
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq04
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq05
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq06
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq07
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq08
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq09
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq10
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq11
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq12
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq13
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , ConsSeq     AS ConsSeq
		  , ConsName	AS ConsName
		  , @PreStdYM   AS YMType
		  , '발생건수'  AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4)  = @PreStdYY THEN ComplainCnt END) AS YY_Sum
		  ,  SUM(CASE WHEN OccuYM			= @PreStdYM THEN ComplainCnt END) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0 ) AS  MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0 ) AS  MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0 ) AS  MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0 ) AS  MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0 ) AS  MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0 ) AS  MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0 ) AS  MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0 ) AS  MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0 ) AS  MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0 ) AS  MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0 ) AS  MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0 ) AS  MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0 ) AS  MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0 ) AS  MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , ConsSeq     AS ConsSeq
		  , ConsName	AS ConsName
		  , @PreStdYM   AS YMType
		  , '판매팩수'  AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty END) AS YY_Sum
		  ,  SUM(CASE WHEN OccuYM			= @PreStdYM THEN SalesQty END) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1
	  -- MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName


 ---------------------
 -- 생산사업장 기준연월
 ---------------------

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , ConsSeq     AS ConsSeq
		  , ConsName	AS ConsName
		  , @StdYM      AS YMType
		  , 'PPM'	    AS DetailType
		  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty END)) * 1000000, 1) AS YY_Sum
		  , ROUND((SUM(CASE WHEN OccuYM			 = @StdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM		  = @StdYM THEN SalesQty END)) * 1000000, 1) AS YMTotal
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq01
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq02	 
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq03
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq04
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq05
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq06
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq07
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq08
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq09
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq10
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq11
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq12
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq13
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1 -- MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , ConsSeq     AS ConsSeq
		  , ConsName	AS ConsName
		  , @StdYM     AS YMType
		  , '발생건수' AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)  AS PPMYY
		  ,  SUM(CASE WHEN OccuYM		   = @StdYM THEN ComplainCnt END)  AS PPMYM
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0 ) AS  MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0 ) AS  MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0 ) AS  MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0 ) AS  MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0 ) AS  MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0 ) AS  MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0 ) AS  MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0 ) AS  MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0 ) AS  MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0 ) AS  MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0 ) AS  MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0 ) AS  MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0 ) AS  MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0 ) AS  MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		 , ConsSeq     AS ConsSeq
		 , ConsName	AS ConsName
		 , @StdYM      AS YMType
		 , '판매팩수'	AS DetailType
		 , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY  THEN SalesQty END) AS PPMYY
		 , SUM(CASE WHEN OccuYM			 = @StdYM  THEN SalesQty END) AS PPMYM
		 , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq01
		 , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq02
		 , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq03
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq04
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq05
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq06
		 , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq07
		 , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq08
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq09
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq10
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq11
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq12
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq13
	     , ISNULL(SUM(CASE WHEN OccuYM   = @StdYM  THEN SalesQty END), 0) AS MinorMSeq14
	  FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND ConsSeq IS NOT NULL
	 GROUP BY ConsSeq 
			, ConsName

UNION ALL

 ---------------------
 -- 품목별 비교연월
 ---------------------
	SELECT @CompanySeq	AS CompanySeq 
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @PreStdYM  AS YMType
		  , 'PPM'  AS DetailType
		  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty END)) * 1000000, 1) AS YY_Sum
		  , ROUND((SUM(CASE WHEN OccuYM			 = @PreStdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM			 = @PreStdYM THEN SalesQty END)) * 1000000, 1) AS YMTotal
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq01
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq02	 
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq03
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq04
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq05
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq06
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq07
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq08
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq09
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq10
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq11
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq12
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq13
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM   = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @PreStdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @PreStdYM  AS YMType
		  , '발생건수' AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4)  = @PreStdYY THEN ComplainCnt END) AS YY_Sum
		  ,  SUM(CASE WHEN OccuYM			= @PreStdYM THEN ComplainCnt END) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0 ) AS  MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0 ) AS  MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0 ) AS  MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0 ) AS  MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0 ) AS  MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0 ) AS  MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0 ) AS  MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0 ) AS  MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0 ) AS  MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0 ) AS  MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0 ) AS  MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0 ) AS  MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0 ) AS  MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0 ) AS  MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  -- MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName
	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @PreStdYM  AS YMType
		  , '판매팩수' AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty END) AS YY_Sum
		  ,  SUM(CASE WHEN OccuYM		   = @PreStdYM THEN SalesQty END) AS YMTotal
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @PreStdYM  THEN SalesQty END), 0) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  -- MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL
	
	SELECT @CompanySeq	AS CompanySeq 
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @StdYM   AS YMType
		  , 'PPM'	 AS DetailType
		  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty END)) * 1000000, 1) AS YY_Sum
		  , ROUND((SUM(CASE WHEN OccuYM			 = @StdYM THEN ComplainCnt END)/SUM(CASE WHEN OccuYM		  = @StdYM THEN SalesQty END)) * 1000000, 1) AS YMTotal
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq01
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq02	 
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq03
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq04
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq05
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq06
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq07
		  , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq08
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq09
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq10
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq11
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq12
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq13
	      , ROUND(ISNULL((SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END)/SUM(CASE WHEN OccuYM = @StdYM THEN SalesQty END)) * 1000000 , 0), 1) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL

	SELECT @CompanySeq	AS CompanySeq 
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @StdYM       AS YMType
		  , '발생건수'	 AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)  AS PPMYY
		  ,  SUM(CASE WHEN OccuYM		   = @StdYM THEN ComplainCnt END)  AS PPMYM
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154001 THEN ComplainCnt END), 0 ) AS  MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154003 THEN ComplainCnt END), 0 ) AS  MinorMSeq02	
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154004 THEN ComplainCnt END), 0 ) AS  MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154002 THEN ComplainCnt END), 0 ) AS  MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154014 THEN ComplainCnt END), 0 ) AS  MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154015 THEN ComplainCnt END), 0 ) AS  MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154017 THEN ComplainCnt END), 0 ) AS  MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154005 THEN ComplainCnt END), 0 ) AS  MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154007 THEN ComplainCnt END), 0 ) AS  MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154009 THEN ComplainCnt END), 0 ) AS  MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154010 THEN ComplainCnt END), 0 ) AS  MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154011 THEN ComplainCnt END), 0 ) AS  MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154012 THEN ComplainCnt END), 0 ) AS  MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM AND MinorMSeq = 2000154020 THEN ComplainCnt END), 0 ) AS  MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  --MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName

	UNION ALL

	 SELECT @CompanySeq	AS CompanySeq  
		  , UMItemSeq   AS ConsSeq
		  , UMItemName	AS ConsName
		  , @StdYM      AS YMType
		  , '판매팩수'	AS DetailType
		  ,  SUM(CASE WHEN LEFT(OccuYM, 4)  = @StdYY THEN SalesQty END) AS PPMYY
		  ,  SUM(CASE WHEN OccuYM			= @StdYM THEN SalesQty END) AS PPMYM
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq01
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq02
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq03
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq04
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq05
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq06
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq07
		  ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq08
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq09
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq10
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq11
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq12
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq13
	      ,  ISNULL(SUM(CASE WHEN OccuYM = @StdYM  THEN SalesQty END), 0) AS MinorMSeq14
	 FROM #Consol_Complain
	 WHERE 1=1  -- MinorSSeq <> 2000016043
	   AND UMItemSeq IS NOT NULL
	 GROUP BY UMItemSeq
		  , UMItemName	

	
	)  AS T
WHERE 1=1 
  AND T.ConsSeq = @Cons_UMItemSeq
ORDER BY T.ConsSeq
	, (CASE WHEN T.YMType = '증감' THEN 1 ELSE 2 END)

v