        
--=========================
-- 변수 선언 1 조회조건 
--=========================
	
	DECLARE @CompanySeq INT
		SET @CompanySeq = 1

      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
      SET ANSI_WARNINGS OFF  -- 0나누기 오류
      SET ARITHIGNORE ON 
      SET ARITHABORT OFF
	   -- 검색조건들 (변수값 조회화면에서 받아오는값)

      IF @CompanySeq = 1 
	     SET @CompanySeq = 0

    DECLARE @StdYM      VARCHAR(6)
    DECLARE @StdYY VARCHAR(4)
    --DECLARE @StdYM VARCHAR(6)
    DECLARE @PreStdYY VARCHAR(4)
    DECLARE @PreStdYM VARCHAR(6)
 
	  SET @PreStdYM = 202406
      SET @StdYY	= LEFT(@StdYM, 4)
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
      FROM [JOIN_DM].[dbo].[joinbio_TDAUMinorClass]		            AS  A WITH(NOLOCK) 
      LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_TDAUMinorValueClass] AS  B WITH(NOLOCK)   ON A.CompanySeq  = B.CompanySeq
                                                                                        AND A.MajorSeq    = B.MajorSeq
                                                                                        AND A.MinorSeq    = B.MinorSeq 
                                                                                        AND B.Serl        = 1000001
      LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_TDAUMinorClass]      AS  C WITH(NOLOCK)   ON B.ValueSeq    = C.MinorSeq 
                                                                                        AND B.CompanySeq  = C.CompanySeq  
    													 			                    AND C.MajorSeq    = 2000154
      LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_TDAUMinorValueClass] AS  D WITH(NOLOCK)   ON C.MinorSeq    = D.MinorSeq 
                                                                                        AND C.MajorSeq    = D.MajorSeq 
                                                                                        AND C.CompanySeq  = D.CompanySeq        
                                                                                        AND D.Serl        = 1000001 
      LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_TDAUMinorClass]      AS C2 WITH(NOLOCK)   ON D.ValueSeq    = C2.MinorSeq 
                                                                                        AND D.CompanySeq  = C2.CompanySeq
    															                        AND C2.MajorSeq   = 2000155
      LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_TDAUMinorValueClass] AS D2 WITH(NOLOCK)   ON C2.MinorSeq   = D2.MinorSeq 
                                                                                        AND C2.MajorSeq   = D2.MajorSeq 
                                                                                        AND C2.CompanySeq = D2.CompanySeq
                                                                                        AND D2.Serl       = 1000001 
         WHERE	  A.MajorSeq = 2000016
           AND	 ISNULL (D2.ValueText,  0) <> 0
	  ORDER BY	  A.CompanySeq
				, A.MinorSeq
    
     --   SELECT * FROM #Code_TEMP

--======================================
-- TEMP TABLE 구성 / INVOICESUM
--======================================
 
	PRINT 'INVOICESUM 테이블'
    
    CREATE TABLE #InvoiceSum (
     			 Companyseq	          INT
     	   	   --, ComplainCodeSeq    INT        --디테일 SP에서 사용
     		   , InvoiceYM	          VARCHAR(6)
     		   , MainFactUnitSeq	  INT
     		   , MainFactUnitName	  NVARCHAR(100)
     		   , UMItemSeq	          INT
     		   , UMItemName	          NVARCHAR(100)
     		   , ComplainCnt          DECIMAL(19,5)
     		   , Qty     	          DECIMAL(19,5)
     			)

     CREATE NONCLUSTERED INDEX IDX_#InvoiceSum ON #InvoiceSum(CompanySeq, InvoiceYM, MainFactUnitSeq)						              

     INSERT INTO #InvoiceSum

     SELECT  A.CompanySeq     
	       , ISNULL(A.InvoiceYM, B.OccuYM)	 AS StdYM       
	       --, B.ComplainCodeSeq  -- 디테일 SP에서 사용
           , A.MainFactUnitSeq
		   , A.MainFactUnitName
           , A.UMItemSeq      
		   , A.UMItemName
     	   , ISNULL(B.ComplainCnt, 0)		AS ComplainCnt
     	   , ISNULL(A.Qty ,0)				AS Qty
      FROM (
			SELECT A.CompanySeq     
				 , A.InvoiceYM
           	     , ISNULL(C.MainFactUnitSeq , 0)								 AS MainFactUnitSeq
				 , ISNULL(C.MainFactUnitName, '사업장없음')						 AS MainFactUnitName
           	     , ISNULL(C.QCTypeSeq , 0)										 AS UMItemSeq     
				 , ISNULL(C.QCTypeNAme, '품질유형없음')							 AS UMItemName
                 , ISNULL(SUM(CASE WHEN A.SalesUnitName  = '팩' or B.UnitName = 'Pack' THEN SalesQty
                				   ELSE A.StdQty * B.ConvDen/B.ConvNum END ), 0) AS Qty
             FROM [JOIN_DM].[DBO].[joinbio_TSLInvoiceSum_Group]			  AS A 
             LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_ItemUnitList_Group] AS B ON A.CompanySeq = B.CompanySeq 
                                                                              AND A.ItemSeq    = B.ItemSeq
                                                                              AND (B.UnitName  = '팩' or B.UnitName   = 'Pack')
             LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_ItemClassList]      AS C ON A.CompanySeq = C.CompanySeq
                                                                              AND A.ItemSeq    = C.ItemSeq
        	WHERE 1=1
			  -- AND A.CompanySeq = @CompanySeq
			  AND (@CompanySeq = 0 OR A.CompanySeq = @CompanySeq)
			  AND A.CompanySeq		 NOT IN (7)
        	  AND (InvoiceYM   = @PreStdYM   or InvoiceYM  = @StdYM)
        	  AND C.MainFactUnitName NOT IN ('상품')		
        	  AND C.MainFactUnitName NOT LIKE '%농장'
			  AND (C.ItemName		 NOT LIKE '%선별%' AND C.ItemName NOT LIKE '%무특%' AND C.ItemName NOT LIKE '%내부매출%')
        	 --AND  C.MainFactUnitName IS NOT NULL		
        	GROUP BY A.CompanySeq
        	       , A.InvoiceYM
        		   , C.MainFactUnitSeq
        	       , C.MainFactUnitName
        	       , C.QCTypeSeq
        	       , C.QCTypeNAme
         ) AS A
      LEFT OUTER JOIN (
	                
                       SELECT A.CompanySeq  --, A.ComplainCodeSeq  -- 디테일 SP에서 사용
		            		, LEFT(A.OccuDate , 6)                     AS OccuYM
           	                , ISNULL(B.MainFactUnitSeq , 0)            AS MainFactUnitSeq
				            , ISNULL(B.MainFactUnitName, '사업장없음') AS MainFactUnitName
           	                , ISNULL(B.QCTypeSeq , 0)                  AS UMItemSeq     
				            , ISNULL(B.QCTypeNAme, '품질유형없음')	   AS UMItemName
		            		, COUNT(ComplainSeq)                       AS ComplainCnt
		            	 FROM [JOIN].[dbo].join_TPDQCComplain AS A
                         LEFT OUTER JOIN [JOIN_DM].[dbo].[joinbio_ItemClassList] AS B ON A.CompanySeq      = B.CompanySeq
                                                                                     AND A.GoodSeq         = B.ItemSeq
                         LEFT OUTER JOIN #Code_TEMP						        AS T  ON A.CompanySeq      = T.CompanySeq
                         												  	         AND A.ComplainCodeSeq = T.MinorSSeq
		            	WHERE 1=1 
		                  AND (LEFT(A.OccuDate , 6) = @PreStdYM or LEFT(A.OccuDate , 6)  = @StdYM)
			              AND ( @CompanySeq = 0 or A.CompanySeq = @CompanySeq)
			              AND A.CompanySeq NOT IN (7)
			              AND InoutSeq     = 2000156001
        	              AND B.MainFactUnitName NOT LIKE '%농장'
						  AND T.isClaim    is not null
					    GROUP BY A.CompanySeq
						       --, A.ComplainCodeSeq -- 디테일 SP에서 사용
		            		   , LEFT(A.OccuDate , 6) 
		            		   , B.MainFactUnitSeq
        	                   , B.MainFactUnitName
        	                   , B.QCTypeSeq
        	                   , B.QCTypeNAme
				    ) AS B ON A.CompanySeq       = B.CompanySeq
					      AND A.MainFactUnitSeq  = B.MainFactUnitSeq			
					      AND A.UMItemSeq        = B.UMItemSeq			
						  AND A.InvoiceYM        = B.OccuYM
         WHERE 1=1


 -- SELECT * FROM #InvoiceSum

--======================================
-- TEMP TABLE 구성 / 통합테이블
--======================================

PRINT '통합테이블_기준연도'

CREATE TABLE #Consol_Complain (
			Companyseq			INT
		  --, ComplainCodeSeq		INT  -- 디테일 SP에서 사용
		  , OccuYM		     	NVARCHAR(6)
		  , ComplainCnt			Float
		  , SalesQty			Float
		  , UMItemSeq			INT
		  , UMItemName			NVARCHAR(20)
		  , ConsSeq				INT
		  , ConsName			NVARCHAR(20)
		)
-- CREATE CLUSTERED INDEX IDX_#Consol_Complain ON #Consol_Complain(CompanySeq, ComplainCodeSeq, ItemSeq)						          


    INSERT #Consol_Complain

    SELECT A.CompanySeq  
    	 --, A.ComplainCodeSeq  -- 디테일 SP에서 사용
    	 , A.InvoiceYM AS OccuYM
    	 , A.ComplainCnt
    	 , A.Qty       AS SalesQty
    	 , A.UMItemSeq	     	AS UMItemSeq 
    	 , A.UMItemName	        AS UMItemName
    	 , A.MainFactUnitSeq	AS ConsSeq
    	 , A.MainFactUnitName   AS ConsName
      FROM #InvoiceSum AS A
      
     WHERE 1=1
       -- LEFT(A.InvoiceYM, 4) = @StdYY 
     ORDER BY A.CompanySeq, A.MainFactUnitSeq  

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
      
      