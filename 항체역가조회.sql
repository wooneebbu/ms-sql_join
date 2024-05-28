USE [JOIN]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_AntiReactionNoteWeekQuery]    Script Date: 2023-06-28 오전 10:25:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 항체역가주령별조회
    작 성 일 - 2023.06.20
    작 성 자 - HHWoon        
 *************************************************************************************************/         
ALTER PROC [dbo].[joinbio_AntiReactionNoteWeekQuery]    
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
    SET ARITHIGNORE ON 
    SET ARITHABORT OFF
-- 검색조건들 (변수값 조회화면에서 받아오는값)

DECLARE 
		  @FarmSeq	   	      INT
		, @BreedSeq           INT
		, @SpeciesName		  VARCHAR(5)	
		, @InspItemSeq		  INT
		, @InoutYY            VARCHAR(5)
		, @InoutDateFr        VARCHAR(10)
		, @InoutDateTo        VARCHAR(10)

SELECT 		
	     @FarmSeq	        =		ISNULL(FarmSeq, 0)
	   , @BreedSeq          =       ISNULL(BreedSeq, 0)
	   , @SpeciesName	    =		ISNULL(SpeciesName, '')
	   , @InspItemSeq	    =	    ISNULL(InspItemSeq, 0)
	   , @InoutYY           =		ISNULL(InoutYY, '')
       , @InoutDateFr       =       ISNULL(InoutDateFr, '')
       , @InoutDateTo       =       ISNULL(InoutDateTo, '')
	  
	 FROM #BIZ_IN_DataBlock1
	
	-- Temp Table, Temp DB에 있으면 지우기 ------------------------------------------------------------
	IF OBJECT_ID('tempdb..#AntiReactionNote')				IS NOT NULL DROP TABLE #AntiReactionNote  
	-------------------------------------------------------------------------------------------------

	-- Temp Table 생성 불러올 값 임시저장 
	-- WeekCnt값 하드코딩 되어있어서 임시 table 필요함

	CREATE TABLE #AntiReactionNote (
									CompanySeq		INT,
									FarmSeq			INT,
									FarmName		VARCHAR(30),
									BreedSeq		INT,
									BreedName		VARCHAR(10),
									SpeciesName     VARCHAR(5),
									InOutDate		VARCHAR(10),
									WorkDate		VARCHAR(10),
									InspItemSeq		INT,
									InspItemName	VARCHAR(10),
									SampleNum		INT,
									ARAVG			DECIMAL(19, 5),
									WeekCnt			VARCHAR(10),
									InoutYY			INT
									)
		INSERT #AntiReactionNote
		 SELECT  
   		 A.CompanySeq,                             	 				                        			 				 
   		 A.FarmSeq,                            		 				 
		 B.MinorName								AS FarmName,     					 				 
  		 A.BreedSeq,                               	 				 
		 F.MinorName								AS BreedName,
		 G.ValueText                                AS SpeciesName,
  		 CONVERT(VARCHAR(10), A.InOutDate, 120)   	AS InOutDate,    
  		 CONVERT(VARCHAR(10), A.WorkDate, 120)    	AS WorkDate,     
  		 A.InspItemSeq,                              				 
		 H.MinorName AS InspItemName,
  		 A.SampleNum,                        						 
  		 ( 0*ARCount00 + 1*ARCount01 + 2*ARCount02 + 3*ARCount03 +   
  		   4*ARCount04 + 5*ARCount05 + 6*ARCount06 + 7*ARCount07 + 
  		   8*ARCount08 + 9*ARCount09 + 10*ARCount10 + 11*ARCount11 +
  		  12*ARCount12 + 13*ARCount13 + 14*ARCount14 + 15*ARCount15 )/SampleNum  AS ARAVG,  -- 0 나누기 오류 발생 구간
         CASE WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 < 8 THEN '1'         
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 8   AND 70  THEN '~10'
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 71  AND 140 THEN '~20'
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 141 AND 210 THEN '~30'
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 211 AND 280 THEN '~40'
     	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 281 AND 350 THEN '~50'
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 351 AND 420 THEN '~60'
    	 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 >= 421 THEN '61~'
     	 ELSE '' END AS WeekCnt,        
         LEFT(CONVERT(VARCHAR(10), A.InOutDate, 120), 4)    AS InoutYY                    
		 -- table값 가져오는 DB로 모두 수정  
          FROM [JOIN_FARMS].[DBO].[joinbio_AntiReactionNote] AS  A  WITH(NOLOCK) 
  		 LEFT OUTER JOIN [JOIN_FARMS].[DBO]._TDAUMinor    AS  B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                AND A.FarmSeq    = B.MinorSeq      					 
                AND B.MajorSeq   = '2000209'        				 
   		 LEFT OUTER JOIN [JOIN_FARMS].[DBO]._TDAUMinor    AS  F  WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq    
                AND A.BreedSeq   = F.MinorSeq     
                AND F.MajorSeq   = '2000211'     					       
  		 LEFT OUTER JOIN [JOIN_FARMS].[DBO]._TDAUMinor    AS  H  WITH(NOLOCK) ON A.CompanySeq  = H.CompanySeq
                AND A.InspItemSeq = H.MinorSeq 
                AND H.MajorSeq    = '2000212'     				    
		 LEFT OUTER JOIN [JOIN_FARMS].[DBO]._TDAUMinorValue   AS  G  WITH(NOLOCK) ON F.CompanySeq = G.CompanySeq 
															  AND F.MinorSeq   = G.MinorSeq
															  AND G.Serl  = '1000001'	
 		 WHERE 1 = 1 -- Temp Table에서 불러오는 Company Seq는 구별 필요  / 조회조건 temp table에 미리 줘도 상관없음 불러오는 값에서 수정 
		  -- A.CompanySeq = @CompanySeq  -- 조회조건만 넣어주면 됨
		  AND (@FarmSeq      =    0   OR   A.FarmSeq  = @FarmSeq)
		  AND (@BreedSeq     =    0   OR   A.BreedSeq = @BreedSeq)
		  AND (G.ValueText LIKE '%' + @SpeciesName + '%')
		  AND (@InspItemSeq  =    0   OR   A.InspItemSeq = @InspItemSeq)
		  AND (LEFT(CONVERT(VARCHAR(10), A.InOutDate, 120), 4) LIKE '%' +@InoutYY + '%')
		  AND (((CONVERT(INT, A.InoutDate) BETWEEN @InoutDateFr AND @InoutDateTo) OR (@InoutDateFr = 0 AND @InoutDateTo = 0))
																				  OR (@InoutDateFr = 0 AND (CONVERT(INT, A.InOutDate) <= @InoutDateTo))
																				  OR ((@InoutDateFr <= CONVERT(INT, A.InOutDate)) AND @InoutDateTo = 0))

	   

	 INSERT INTO #BIZ_OUT_DataBlock1(    				
											FarmName
										,BreedName
										,SpeciesName
										,InspItemName
										,InoutDate
										,InoutYY
										,WeekAvg1
										,WeekAvg10
										,WeekAvg20
										,WeekAvg30
										,WeekAvg40
										,WeekAvg50
										,WeekAvg60
										,WeekAvg61
										,WeekAvg
										,WeekCnt1
										,WeekCnt10
										,WeekCnt20
										,WeekCnt30
										,WeekCnt40
										,WeekCnt50
										,WeekCnt60
										,WeekCnt61
										,WeekCntSum
									)
-- 서비스 in out값 설정 주의!
SELECT 			
				FarmName
				,BreedName
				,SpeciesName
				,InspItemName
				,InoutDate
				,InoutYY
				,SUM(WeekAvg1)/SUM(CntWeekAvg1)   AS WeekAvg1
				,SUM(WeekAvg10)/SUM(CntWeekAvg10) AS WeekAvg10
				,SUM(WeekAvg20)/SUM(CntWeekAvg20) AS WeekAvg20
				,SUM(WeekAvg30)/SUM(CntWeekAvg30) AS WeekAvg30
				,SUM(WeekAvg40)/SUM(CntWeekAvg40) AS WeekAvg40
				,SUM(WeekAvg50)/SUM(CntWeekAvg50) AS WeekAvg50
				,SUM(WeekAvg60)/SUM(CntWeekAvg60) AS WeekAvg60
				,SUM(WeekAvg61)/SUM(CntWeekAvg61) AS WeekAvg61
				,AVG(WeekAVG)   AS WeekAvg
				,SUM(WeekCnt1)  AS WeekCnt1 
				,SUM(WeekCnt10) AS WeekCnt10
				,SUM(WeekCnt20) AS WeekCnt20
				,SUM(WeekCnt30) AS WeekCnt30
				,SUM(WeekCnt40) AS WeekCnt40
				,SUM(WeekCnt50) AS WeekCnt50
				,SUM(WeekCnt60) AS WeekCnt60
				,SUM(WeekCnt61) AS WeekCnt61
				,SUM(WeekCntSum) AS WeekCntSum
				
FROM
( -- 서브쿼리 Group by절 
	SELECT FarmName, BreedName, InspItemName, SpeciesName, InOutDate, InoutYY, WeekCnt,
	   CASE WHEN WeekCnt = '1'   THEN AVG(ARAVG) ELSE 0 END AS WeekAvg1,
	   CASE WHEN WeekCnt = '~10' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg10,
	   CASE WHEN WeekCnt = '~20' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg20,
	   CASE WHEN WeekCnt = '~30' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg30,
	   CASE WHEN WeekCnt = '~40' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg40,
	   CASE WHEN WeekCnt = '~50' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg50,
	   CASE WHEN WeekCnt = '~60' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg60,
	   CASE WHEN WeekCnt = '61~' THEN AVG(ARAVG) ELSE 0 END AS WeekAvg61,
	   AVG(ARAVG) AS WeekAVG,
	   -- case문 활용 and, then, 
	   CASE WHEN WeekCnt = '1'   AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg1,
	   CASE WHEN WeekCnt = '~10' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg10,
	   CASE WHEN WeekCnt = '~20' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg20,
	   CASE WHEN WeekCnt = '~30' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg30,
	   CASE WHEN WeekCnt = '~40' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg40,
	   CASE WHEN WeekCnt = '~50' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg50,
	   CASE WHEN WeekCnt = '~60' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg60,
	   CASE WHEN WeekCnt = '61~' AND AVG(ARAVG) > 0 THEN 1 ELSE 0 END AS CntWeekAvg61,

	   CASE WHEN WeekCnt = '1'   THEN COUNT(WeekCnt) END AS WeekCnt1,
	   CASE WHEN WeekCnt = '~10' THEN COUNT(WeekCnt) END AS WeekCnt10,
	   CASE WHEN WeekCnt = '~20' THEN COUNT(WeekCnt) END AS WeekCnt20,
	   CASE WHEN WeekCnt = '~30' THEN COUNT(WeekCnt) END AS WeekCnt30,
	   CASE WHEN WeekCnt = '~40' THEN COUNT(WeekCnt) END AS WeekCnt40,
	   CASE WHEN WeekCnt = '~50' THEN COUNT(WeekCnt) END AS WeekCnt50,
	   CASE WHEN WeekCnt = '~60' THEN COUNT(WeekCnt) END AS WeekCnt60,
	   CASE WHEN WeekCnt = '61~' THEN COUNT(WeekCnt) END AS WeekCnt61,
	   COUNT(WeekCnt) AS WeekCntSum

	FROM #AntiReactionNote
	WHERE 1 = 1 
	GROUP BY FarmName, BreedName, InspItemName, SpeciesName, InOutDate, InoutYY, WeekCnt 
) AS A
	GROUP BY FarmName, BreedName, InspItemName, SpeciesName, InOutDate, InoutYY

RETURN