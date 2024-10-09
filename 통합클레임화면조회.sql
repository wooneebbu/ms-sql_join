USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationQuery_Query]    Script Date: 2024-05-21 오전 11:07:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 통합클레임발생보고_joinbio
    작 성 일 - 2024.06.12
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_ConsolComplainQuery]               
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

DECLARE   @StdYM				VARCHAR(6)
      --  , @STDYMTo			VARCHAR(6)
	  --  , @Cons_UMItemSeq			INT
	   -- , @Cons_UMItemName			VARCHAR(20)
       -- , @UMItemTypeSeq		INT 
       -- , @UMItemTypeName		VARCHAR(20)
       -- , @ChkBox1				INT
	   -- , @ChkBox2				INT

SELECT   @StdYM			     = ISNULL(StdYM, '')
       -- , @STDYMTo		 = ISNULL(STDYMTo, '')
      --  , @Cons_UMItemSeq	 = ISNULL(Cons_UMItemSeq, 0)
      --  , @Cons_UMItemName	 = ISNULL(Cons_UMItemName,  '')
       -- , @UMItemTypeSeq	 = ISNULL(UMItemTypeSeq,   0)
       -- , @UMItemTypeName	 = ISNULL(UMItemTypeName, '')
       -- , @ChkBox1			 = ISNULL(ChkBox1,  0)
	   -- , @ChkBox2			 = ISNULL(ChkBox2,  0)
  FROM  #BIZ_IN_DataBlock1 

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

  FROM [JOIN].[dbo].[_TDAUMinor]				 AS A with(nolock) 
  LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS B with(nolock)   ON A.CompanySeq  = B.CompanySeq
                                                                  AND A.MajorSeq    = B.MajorSeq
                                                                  AND A.MinorSeq    = B.MinorSeq 
                                                                  AND B.Serl        = 1000001
  LEFT OUTER JOIN [JOIN].[dbo].[_TDAUMinor]    AS C with(nolock)   ON B.ValueSeq    = C.MinorSeq 
                                                                  AND B.CompanySeq  = C.CompanySeq  
																  AND C.MajorSeq    = 2000154
  LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS D with(nolock)   ON C.MinorSeq    = D.MinorSeq 
                                                                  AND C.MajorSeq    = D.MajorSeq 
                                                                  AND C.CompanySeq  = D.CompanySeq        
                                                                  AND D.Serl        = 1000001 
  LEFT OUTER JOIN [JOIN].[dbo].[_TDAUMinor]    AS C2 with(nolock)  ON D.ValueSeq    = C2.MinorSeq 
                                                                  AND D.CompanySeq  = C2.CompanySeq
															      AND C2.MajorSeq   = 2000155
  LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue AS D2 with(nolock)  ON C2.MinorSeq   = D2.MinorSeq 
                                                                  AND C2.MajorSeq   = D2.MajorSeq 
                                                                  AND C2.CompanySeq = D2.CompanySeq
                                                                  AND D2.Serl       = 1000001 
  WHERE A.MajorSeq = 2000016
  ORDER BY A.CompanySeq, A.MinorSeq

--   SELECT * FROM #Code_TEMP

--======================================
-- TEMP TABLE 구성 / INVOICESUM
--======================================
PRINT 'INVOICESUM 테이블'

CREATE TABLE #InvoiceSum (
			 Companyseq	     INT
		   , ComplainCodeSeq INT
		   , InvoiceYM	     INT
		   , InoutSeq 	     INT
		   , ItemSeq	     INT
		   , ItemName	     NVARCHAR(100)
		   , StdUnitSeq	     INT
		   , ComplainCnt     DECIMAL(19,5)
		   , Qty     	     DECIMAL(19,5)
			)
CREATE NONCLUSTERED INDEX IDX_#InvoiceSum ON #InvoiceSum(CompanySeq, ComplainCodeSeq, InvoiceYM, ItemSeq)						          

INSERT INTO #InvoiceSum
SELECT A.CompanySeq, A.ComplainCodeSeq
     , B.InvoiceYM , A.InOutSeq
     , B.ItemSeq   , B.ItemName
	 , B.StdUnitSeq
     , Count(A.ComplainSeq) AS ComplainCnt
     , SUM(B.Qty) AS Qty
  FROM [JOIN].[dbo].join_TPDQCComplain      AS A
  LEFT JOIN  [JOIN_DC].[DBO].[joinbio_TSLInvoiceSum_Group]  AS B ON A.CompanySeq  = B.CompanySeq 
				                                               AND A.GoodSeq	 = B.ItemSeq 
				                                               AND B.InvoiceYM   = LEFT(A.OccuDate, 6)
				                                              -- AND LEFT(B.InvoiceYM, 4)  = @StdYY
 WHERE LEFT(B.InvoiceYM, 4) BETWEEN @PreStdYY AND @StdYY
   AND LEFT(A.OccuDate, 4) BETWEEN @PreStdYY AND @StdYY
   AND A.InoutSeq = 2000156001

 GROUP BY A.CompanySeq, A.ComplainCodeSeq
        , B.InvoiceYM , A.InOutSeq
        , B.ItemSeq   , B.ItemName
	    , B.StdUnitSeq

--======================================
-- TEMP TABLE 구성 / 통합테이블
--======================================

PRINT '통합테이블_기준연도'

CREATE TABLE #Consol_Complain (
			Companyseq			INT
		  , ComplainCodeSeq		INT
		  , ItemSeq				INT
		  , ItemName			NVARCHAR(100)
		  , OccuYM		     	NVARCHAR(6)
		  , UnitSeq		     	INT
		  , ComplainCnt			DECIMAL (19, 5)
		  , SalesQty			DECIMAL (19, 5)
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
SELECT  A.CompanySeq  
	  , A.ComplainCodeSeq
	  , A.ItemSeq
	  , A.ItemName
	  , A.InvoiceYM AS OccuYM
	  , P.UnitSeq
	  , A.ComplainCnt
	  , ISNULL(CASE WHEN A.StdUnitSeq IS NULL THEN NULL ELSE A.Qty * (P.ConvDen/P.ConvNum) END, 0) AS SalesQty
	  , D.MinorSeq
	  , D.MinorName  AS UMItemName
	  , H.MinorSeq
	  , H.MinorName  AS ConsName
	  , T.MinorSSeq  
	  , T.MinorSName  
	  , T.MinorMSeq  
	  , T.MinorMName  
	  , T.MinorLSeq  
	  , T.MinorLName  
	  , T.IsUse
	  , T.IsClaim
FROM #InvoiceSum AS A

LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine	   AS C WITH(NOLOCK)  ON A.CompanySeq  = C.CompanySeq
												  				     AND A.ItemSeq	   = C.ItemSeq
												  				     AND C.MngSerl	   = 1000033 --품목유형(품질)_join  
LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor			   AS D WITH(NOLOCK)  ON C.CompanySeq  = D.CompanySeq            
												  				     AND C.MngValSeq   = D.MinorSeq 
												  				     AND D.MajorSeq	   = 2000145  --품목유형(품질)_join
LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine	   AS G WITH(NOLOCK)  ON A.CompanySeq  = G.CompanySeq
												  				     AND A.ItemSeq     = G.ItemSeq
												  				     AND G.MngSerl     = '1000027' 
												  				  --  AND G.MngValText LIKE '%사업장%'
LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor			   AS H WITH(NOLOCK)  ON G.CompanySeq  = H.CompanySeq            
												  				     AND G.MngValSeq   = H.MinorSeq 
												  				     AND H.MajorSeq	   = 2000093  --사업장(품질)_join
LEFT OUTER JOIN [JOIN].dbo._TDAItemUnit			   AS P WITH(NOLOCK)  ON A.CompanySeq  = P.CompanySeq 
												  				     AND A.ItemSeq     = P.ItemSeq 
												  				     AND P.UnitSeq	   = 3	
LEFT OUTER JOIN #Code_TEMP						   AS T WITH(NOLOCK)  ON A.CompanySeq  = T.CompanySeq
												  				     AND A.ComplainCodeSeq = T.MinorSSeq

WHERE 1=1
  -- LEFT(A.InvoiceYM, 4) = @StdYY 
ORDER BY A.CompanySeq  
	   , A.ComplainCodeSeq

--=========================
-- 데이터 테이블 
--=========================

INSERT INTO #BIZ_OUT_DataBlock1 (
				CompanySeq
			  , Cons_UMItemSeq
			  , Cons_UMItemName
			  , StdYM
			  --, UMItemSeq
			  --, UMItemName
			  , PPM_P
			  , PPM
			  , Complain_P
			  , ComplainCnt
			  , StdSalesQty
			  , StdClaimCnt
			  , StdClaimPPM
			  , PreStdSalesQty
			  , PreStdClaimCnt
			  , PreStdClaimPPM
			)

SELECT @CompanySeq
	  , ConsSeq     AS  Cons_UMItemSeq
	  , ConsName    AS  Cons_UMItemName
	  , RIGHT(OccuYM, 2) AS StdYM
	  , (((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END) * 1000000)
	  -(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000))
	  /((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000))) * 100 AS PPM_P
	  , ((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty END) * 1000000)
	   - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000)) AS PPM
	  , ((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) 
	   / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) * 100 AS Complain_P
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) AS Complain 
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END) AS StdSalesQty
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) AS StdClaimCnt
	  , (SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) 
		/ SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END)) * 1000000 AS StdClaimPPM
	  , SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) AS PreStdSalesQty
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) AS PreStdClaimCnt
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)
	    /SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000 AS PreStdClaimPPM
   --  , ((CASE WHEN OccuYM = @StdYM THEN SUM(SalesQty) END) - (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)) / (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)
	  FROM #Consol_Complain
	  WHERE 1=1
	    AND OccuYM = @StdYM OR OccuYM = @PreStdYM
		AND ConsSeq IS NOT NULL
	  GROUP BY ConsSeq 
			, ConsName
			, RIGHT(OccuYM, 2)
		--	, SalesQty

UNION ALL

SELECT @CompanySeq 
	  , UMItemSeq      AS  Cons_UMItemSeq
	  , UMItemName		AS  Cons_UMItemName
	  , RIGHT(OccuYM, 2) AS StdYM
	  , (((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END) * 1000000)
	  -(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000))
	  /((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000))) * 100 AS PPM_P
	  , ((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty END) * 1000000)
	   - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)/SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000)) AS PPM
	  , ((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) 
	   / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) * 100 AS Complain_P
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) AS Complain
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END) AS StdSalesQty
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) AS StdClaimCnt
	  , (SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN ComplainCnt END) 
		/ SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY THEN SalesQty	END)) * 1000000 AS StdClaimPPM
	  , SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) AS PreStdSalesQty
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) AS PreStdClaimCnt
	  , SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)
	    /SUM(CASE WHEN LEFT(OccuYM, 4) =  @PreStdYY THEN SalesQty END) * 1000000 AS PreStdClaimPPM
   --  , ((CASE WHEN OccuYM = @StdYM THEN SUM(SalesQty) END) - (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)) / (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)
	  FROM #Consol_Complain
	  WHERE 1=1
	    AND OccuYM = @StdYM OR OccuYM = @PreStdYM
		AND UMItemSeq IS NOT NULL
	  GROUP BY UMItemSeq
			, UMItemName
			, RIGHT(OccuYM, 2)
		--	, SalesQty

