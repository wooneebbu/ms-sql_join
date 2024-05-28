USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_EggMarketPriceByMonthQuery2_TEST]    Script Date: 2024-02-02 오후 1:36:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************                  
      설    명 - 월별계란시세조회2_joinbio_구매단가          
      작 성 일 - 2024-01-05                  
      작 성 자 - HHWoon

      작 성 일 - 2024-01-31
      작 성 자 - HHWoon
	  작성내용 - 일반/유정구분 추가
************************************************************/ 

ALTER PROC [dbo].[joinbio_EggMarketPriceByMonthQuery2_TEST]                                                        
     @ServiceSeq        INT         = 0,          
     @WorkingTag        NVARCHAR(10)= '',          
     @CompanySeq        INT         = 1,          
     @LanguageSeq       INT         = 1,          
     @UserSeq           INT         = 0,          
     @PgmSeq            INT         = 0,        
     @IsTransaction     INT         = 0          
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
    SET ANSI_WARNINGS OFF  -- 0나누기 오류
    SET ARITHIGNORE   ON 
    SET ARITHABORT    OFF

-- 검색조건들 (변수값 조회화면에서 받아오는값)
               
       DECLARE 
                  @StdYY		NVARCHAR(4)		     -- 기준년월     
				 ,@EggGrade		NVARCHAR(10)	     -- 계란등급(왕,특,대,중,소) codehelp	
				 ,@Region		NVARCHAR(10)         -- 
				 ,@EggColor		NVARCHAR(20)         -- 난색
				 ,@EggViableYN  INT                  -- 240131 조회조건으로 유정란여부 추가     
           
        SELECT @StdYY		= ISNULL(StdYY, '')  
			 , @EggGrade	= ISNULL(EggGrade, '') 
			 , @Region		= ISNULL(Region, '') 
			 , @EggColor	= ISNULL(EggColor, '')
			 , @EggViableYN	= ISNULL(EggViableYN, 0)
		  FROM #BIZ_IN_DataBlock1

	-- Temp Table, Temp DB에 있으면 지우기 ------------------------------------------------------------
	IF OBJECT_ID('tempdb..#EggMarketPriceDelv')			IS NOT NULL DROP TABLE #EggMarketPriceDelv
	-------------------------------------------------------------------------------------------------	
	  ----------------------------------------------------    
	  --  임시테이블 생성 (사용할 베이스 테이블)
      ----------------------------------------------------

		CREATE TABLE #EggMarketPriceDelv (
										 CompanySeq	     INT
										, EggColor		 VARCHAR(20)
										, EggViable      VARCHAR(20)  -- 240131 유정란표시 추가
										, Cust			 VARCHAR(8)
										, StdYM 		 VARCHAR(6)
										, EggGrade		 VARCHAR(10)
										, Price			 DECIMAL(19, 5)
										, Qty			 DECIMAL(19, 5)
										, CurAmt	     DECIMAL(19, 5)
										)
		INSERT #EggMarketPriceDelv
		SELECT    CompanySeq
				, EggColor	
				, EggViable	
				, Cust			 
				, StdYM 			
				, EggGrade			 
				, Price			 		
				, Qty
				, CurAmt
		FROM (
		    SELECT A.CompanySeq 
				  , EggColor
				  , EggViable	
				  , Cust
				  , StdYM
				  , EggGrade
				--, ROUND(AVG(Price), 0) AS Price
				  , ROUND(SUM(CurAmt) / SUM(Qty) , 0) AS Price
				  , SUM(Qty)      AS Qty
				  , SUM(CurAmt)	  AS CurAmt
			FROM (	
      	             SELECT A.CompanySeq 
    		        	  , LEFT(B.DelvInDate, 6) AS StdYM
                          , CASE WHEN G.MngValText LIKE '%백색%' OR E.ItemName LIKE '%백색%' THEN '백색란' ELSE '갈색란' END AS EggColor
                          , CASE WHEN I.ValueText = 1 THEN '유정' ELSE '일반' END AS EggViable
                          , CASE WHEN D.MngValSeq = 2000056001                              THEN '외부'   ELSE '내부'    END AS Cust
                    	  , RIGHT(F.MngValText, 2) AS EggGrade
                          , Price
                    	  , Qty
                          , CurAmt
                       FROM [JOIN].[dbo]._TPUDelvInItem                AS A  WITH(NOLOCK) --구매입고품목    
                       JOIN [JOIN].[dbo]._TPUDelvIn                    AS B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  AND A.DelvInSeq = B.DelvInSeq    
                       LEFT OUTER JOIN [JOIN].[dbo]._TDACust           AS C  WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq  AND B.CustSeq   = C.CustSeq    
                       LEFT OUTER JOIN [JOIN].[dbo]._TDACustUserDefine AS D  WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq  AND C.CustSeq   = D.CustSeq     
    		                                                                                                              AND D.MngSerl   = 1000003
                       LEFT OUTER JOIN [JOIN].[dbo]._TDAItem           AS E  WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.ItemSeq   = E.ItemSeq    				    
                       LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS F  WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  AND A.ItemSeq   = F.ItemSeq     
    		                                                                                                              AND F.MngSerl   = 1000008  --원란구분  
                       LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS G  WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  AND A.ItemSeq   = G.ItemSeq     
    		                                                                                                              AND G.MngSerl   = 1000013  --난중구분  
                       LEFT OUTER JOIN [JOIN].[dbo]._TDAItemUserDefine AS H  WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq  AND A.ItemSeq   = H.ItemSeq     
    		                                                                                                              AND H.MngSerl   = 1000037  --원료구분(소)  240131 추가
                       LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinorValue    AS I  WITH(NOLOCK) ON H.CompanySeq = I.CompanySeq  AND H.MngValSeq = I.MinorSeq    
    		                                                                                                              AND I.Serl      = 1000004  --원료구분(소)/유정란여부    240131 추가
                      
    	          
                   		WHERE E.AssetSeq IN (1, 6) -- 상품, 원재료
                     	  AND F.MngValSeq < 2000031006 -- 품목그룹 [왕/특/대/중/소]만 조회
                      	  AND isnull(F.MngValSeq, 0) <> 0  
                      	   AND B.DelvInDate LIKE @StdYY + '%'
                      	  -- AND B.DelvInDate LIKE '2022%'
                      	  AND B.CustSeq <> 11015 --거래처 [조인용인지점(서이천), 11015] 제외
                      	  AND isnull(A.LOTNo, '') <> ''  
		                  AND (@EggViableYN = 0    -- 일반/유정 전체조회
		                       OR I.ValueText = (CASE WHEN @EggViableYN = 1 THEN 0   -- 일반조회
		               	                              WHEN @EggViableYN = 2 THEN 1   -- 유정조회
		               			                      END )
    	                      )
    	          
    	          
    		 	) AS A
	    GROUP BY CompanySeq
				, EggColor
				, Eggviable
		        , StdYM
				, Cust
				, EggGrade
				) AS A
		WHERE 1=1

  --====================================================================
  --  전체 평균용 추가
  --====================================================================

		INSERT #EggMarketPriceDelv
		SELECT    CompanySeq
				, EggColor	
				, EggViable	
				, '평균'  AS Cust			 
				, StdYM 			
				, EggGrade			 
				, ROUND(SUM(CurAmt) / SUM(Qty) , 0) AS Price
				, SUM(Qty)    AS Qty
				, SUM(CurAmt) AS CurAmt
          FROM #EggMarketPriceDelv
		 GROUP BY CompanySeq
				, EggColor	
				, EggViable	
				, StdYM 			
				, EggGrade			 

  --====================================================================

  INSERT INTO #BIZ_OUT_DataBlock2 (
									CompanySeq
									, Type
									, EggColor
									, EggViable
									, Cust
									, EggGrade
									, Prc01									
									, Prc02
									, Prc03
									, Prc04
									, Prc05
									, Prc06
									, Prc07
									, Prc08
									, Prc09
									, Prc10
									, Prc11
									, Prc12
  )
  
 SELECT   @CompanySeq
		, T.Type
		, T.EggColor
		, T.EggViable
		, T.Cust
		, T.EggGrade
		, T.MM01  AS Prc01
		, T.MM02  AS Prc02
		, T.MM03  AS Prc03
		, T.MM04  AS Prc04
		, T.MM05  AS Prc05
		, T.MM06  AS Prc06
		, T.MM07  AS Prc07
		, T.MM08  AS Prc08
		, T.MM09  AS Prc09
		, T.MM10  AS Prc10
		, T.MM11  AS Prc11
		, T.MM12  AS Prc12
 FROM (
		
					 SELECT   CompanySeq
							, '구매단가' AS	Type
							, EggColor
							, EggViable
							, Cust
							, EggGrade
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 01 THEN Price ELSE 0 END) AS MM01
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 02 THEN Price ELSE 0 END) AS MM02
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 03 THEN Price ELSE 0 END) AS MM03
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 04 THEN Price ELSE 0 END) AS MM04
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 05 THEN Price ELSE 0 END) AS MM05
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 06 THEN Price ELSE 0 END) AS MM06
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 07 THEN Price ELSE 0 END) AS MM07
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 08 THEN Price ELSE 0 END) AS MM08
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 09 THEN Price ELSE 0 END) AS MM09
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 10 THEN Price ELSE 0 END) AS MM10
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 11 THEN Price ELSE 0 END) AS MM11
							, SUM(CASE WHEN SUBSTRING(StdYM, 5,2) = 12 THEN Price ELSE 0 END) AS MM12
					 FROM #EggMarketPriceDelv
					 WHERE LEFT(StdYM, 4) = @StdYY
					   --AND EggGrade <> ''
					 GROUP BY CompanySeq
							, EggColor
							, Cust
							, EggGrade
	) AS T				
  WHERE T.CompanySeq = @CompanySeq
    AND T.EggGrade LIKE '%' + @EggGrade + '%' 
  -- AND T.Region LIKE '%' + @Region	+ '%'
    AND T.EggColor LIKE '%' + @EggColor + '%'
 ORDER BY (CASE WHEN EggColor  = '갈색란' THEN 1 ELSE 2 END)
        , (CASE WHEN EggViable = '일반' THEN 1 ELSE 0 END)
	    , (CASE WHEN Cust  = '평균' THEN 1 
				WHEN Cust  = '외부' THEN 2
				ELSE 99 END)
	    , (CASE WHEN EggGrade = '왕란' THEN 1 
	            WHEN EggGrade = '특란' THEN 2 
	            WHEN EggGrade = '대란' THEN 3 
	            WHEN EggGrade = '중란' THEN 4 
	            WHEN EggGrade = '소란' THEN 5 
	            ELSE 99 END)

RETURN
