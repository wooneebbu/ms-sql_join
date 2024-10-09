USE [JOIN]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_ConsolComplainQuery]    Script Date: 2024-07-02 오후 4:59:56 ******/
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

  DECLARE @StdYM      VARCHAR(6)
	    		      
   SELECT @StdYM      = ISNULL(StdYM, '')     
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
    
    --   SELECT * FROM #Code_TEMP

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
        	  AND (InvoiceYM   = @PreStdYM   or InvoiceYM  = @StdYM)      
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
		                  AND (LEFT(OccuDate , 6) = @PreStdYM or LEFT(OccuDate , 6)  = @StdYM)
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

    INSERT INTO #BIZ_OUT_DataBlock1 
	           (
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
	      , '2000094000' AS Cons_UMItemSeq
		  , '소계'		AS Cons_UMItemName
		  , RIGHT(OccuYM, 2) AS StdYM
		  , ROUND(((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	END) * 1000000)
    	    - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000))
    	    /((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000)) * 100, 1) AS PPM_P
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty    END) * 1000000)
    	    - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PPM
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) 
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) * 100, 1) AS Complain_P
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS Complain 
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END), 1) AS StdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END), 1) AS StdClaimCnt
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) 
    		 / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END) * 1000000, 1) AS StdClaimPPM
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END), 1) AS PreStdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS PreStdClaimCnt
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PreStdClaimPPM
	   FROM #Consol_Complain
	  WHERE 1=1
	    AND OccuYM = @StdYM OR OccuYM = @PreStdYM
		--AND ConsSeq IS NOT NULL
	  GROUP BY  RIGHT(OccuYM, 2)
	 
	 UNION ALL
     
	 SELECT @CompanySeq
    	  , ConsSeq          AS Cons_UMItemSeq
    	  , ConsName         AS Cons_UMItemName
    	  , RIGHT(OccuYM, 2) AS StdYM
		  , ROUND(((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	END) * 1000000)
    	    - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000))
    	    /((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000)) * 100, 1) AS PPM_P
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty    END) * 1000000)
    	    - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PPM
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) 
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) * 100, 1) AS Complain_P
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS Complain 
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END), 1) AS StdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END), 1) AS StdClaimCnt
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) 
    		 / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END) * 1000000, 1) AS StdClaimPPM
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END), 1) AS PreStdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS PreStdClaimCnt
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PreStdClaimPPM
       --  , ((CASE WHEN OccuYM = @StdYM THEN SUM(SalesQty) END) - (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)) / (CASE WHEN OccuYM = @PreStdYM THEN SUM(SalesQty) END)
	   FROM #Consol_Complain
	  WHERE 1=1
	    AND OccuYM = @StdYM OR OccuYM = @PreStdYM
		AND ConsSeq IS NOT NULL
--	    AND ConsSeq LIKE @Cons_UMItemSeq +'%'
	  GROUP BY ConsSeq 
			 , ConsName
			 , RIGHT(OccuYM, 2)	
	 
	 UNION ALL
      
     SELECT @CompanySeq 
      	  , UMItemSeq        AS Cons_UMItemSeq
      	  , UMItemName		 AS Cons_UMItemName
      	  , RIGHT(OccuYM, 2) AS StdYM
		  , ROUND(((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	END) * 1000000)
    	    - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000))
    	    /((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000)) * 100, 1) AS PPM_P
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty    END) * 1000000)
    	        - (SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PPM
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)) 
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END) * 100, 1) AS Complain_P
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) - SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS Complain 
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END), 1) AS StdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END), 1) AS StdClaimCnt
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN ComplainCnt END) 
    		 / SUM(CASE WHEN LEFT(OccuYM, 4) = @StdYY    THEN SalesQty	  END) * 1000000, 1) AS StdClaimPPM
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END), 1) AS PreStdSalesQty
    	  , ROUND(SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END), 1) AS PreStdClaimCnt
    	  , ROUND((SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN ComplainCnt END)
    	     / SUM(CASE WHEN LEFT(OccuYM, 4) = @PreStdYY THEN SalesQty    END) * 1000000), 1) AS PreStdClaimPPM    
      	  FROM #Consol_Complain
      	  WHERE 1=1
      	    AND OccuYM = @StdYM OR OccuYM = @PreStdYM
      		AND UMItemSeq IS NOT NULL
--	        AND UMItemSeq LIKE @Cons_UMItemSeq +'%'
      	  GROUP BY UMItemSeq
      			, UMItemName
      			, RIGHT(OccuYM, 2)
      
      



	  

-- 뷰테이블 대신 사용할 베이스 Data

--=========================
-- 변수 선언 1 조회조건 
--=========================

  DECLARE @StdYM      VARCHAR(6)
 -- DECLARE @CompanySeq  INT

	   

      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
      SET ANSI_WARNINGS OFF  -- 0나누기 오류
      SET ARITHIGNORE ON 
      SET ARITHABORT OFF
	 -- 검색조건들 (변수값 조회화면에서 받아오는값)


  DECLARE @StdYY VARCHAR(4)
  --DECLARE @StdYM VARCHAR(6)
  DECLARE @PreStdYY VARCHAR(4)
  DECLARE @PreStdYM VARCHAR(6)
 
	  SET @StdYM = '202405'
  --    SET @CompanySeq = '1'
	  SET @StdYY	  = LEFT(@StdYM, 4)
      SET @PreStdYY = @StdYY-1
      SET @PreStdYM = LEFT(@PreStdYY, 4) + RIGHT(@StdYM, 2)

--========================================
-- 임시테이블 세팅 / Temp Table 정리
--========================================

       IF OBJECT_ID('tempdb..#Consol_Complain')		 IS NOT NULL DROP TABLE #Consol_Complain
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
    
     -- SELECT * FROM #Code_TEMP

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


    SELECT A.CompanySeq     
		 , B.ComplainCodeSeq
         , A.InvoiceYM      
		 , B.InOutSeq
         , A.MainFactUnitSeq
		 , A.MainFactUnitName
         , A.QCTypeSeq      
		 , A.QCTypeNAme
    	 , ISNULL(B.ComplainCnt, 0) AS ComplainCnt
    	 , ISNULL(A.Qty ,0)			AS Qty
     FROM (
           SELECT A.CompanySeq     
				, A.InvoiceYM
                , A.ItemSeq        
				, 3 AS SalesUnitSeq
           	    , ISNULL(C.MainFactUnitSeq , 0)				AS MainFactUnitSeq
				, ISNULL(C.MainFactUnitName, '사업장없음')  AS MainFactUnitName
           	    , ISNULL(C.QCTypeSeq , 0)					AS QCTypeSeq     
				, ISNULL(C.QCTypeNAme, '품질유형없음')		AS QCTypeNAme
                , ISNULL(SUM(CASE WHEN A.SalesUnitName  = '팩' or B.UnitName   = 'Pack' 
								  THEN SalesQty ELSE A.StdQty * B.ConvDen/B.ConvNum END ), 0) AS Qty
             FROM [JOIN_DC].[DBO].[joinbio_TSLInvoiceSum_Group]  AS A 
             LEFT OUTER JOIN [JOIN_DC].[dbo].[joinbio_ItemUnitList_Group] AS B ON A.CompanySeq = B.CompanySeq 
                                                                              AND A.ItemSeq    = B.ItemSeq
                                                                              AND (B.UnitName  = '팩' or B.UnitName   = 'Pack')
             LEFT OUTER JOIN [JOIN_DC].[dbo].[joinbio_ItemClassList]      AS C ON A.CompanySeq = C.CompanySeq
                                                                              AND A.ItemSeq    = C.ItemSeq   
        	WHERE 1=1
			--  AND A.CompanySeq = @CompanySeq
        	  AND (InvoiceYM = @PreStdYM  or InvoiceYM = @StdYM)      
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
                        SELECT CompanySeq
							, ComplainCodeSeq
		            		, LEFT(OccuDate , 6) AS OccuYM
		            		, GoodSeq, InoutSeq
		            		, COUNT(ComplainSeq) AS ComplainCnt
		            	 FROM [JOIN].[dbo].join_TPDQCComplain
		            	WHERE 1=1 
		                  AND (LEFT(OccuDate , 6) = @PreStdYM or LEFT(OccuDate , 6)  = @StdYM)
			            --  AND CompanySeq = @CompanySeq            
					    GROUP BY CompanySeq
							   , ComplainCodeSeq
		            		   , LEFT(OccuDate , 6) 
		            		   , GoodSeq, InoutSeq
				    ) AS B ON A.CompanySeq = B.CompanySeq
					      AND A.ItemSeq    = B.GoodSeq			
						  AND A.InvoiceYM  = B.OccuYM
 WHERE 1=1


 SELECT * FROM #InvoiceSum

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
