USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_EggMarketPriceByMonthQuery]    Script Date: 2024-01-05 오전 8:49:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************                  
      설  명 - 월별계란시세조회_joinbio          
      작성일 - 2023-12-19                  
      작성자 - HHWoon
************************************************************/ 


ALTER PROC [dbo].[joinbio_EggMarketPriceByMonthQuery]                                                        
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
                  @StdYY		NVARCHAR(4)		     -- 기준년월     
				 ,@EggGrade		NVARCHAR(10)	     -- 계란등급(왕,특,대,중,소) codehelp	
				 ,@Region		NVARCHAR(10)         -- 
				-- ,@EggColor		NVARCHAR(20)       

                    
       SELECT     @StdYY		= ISNULL(StdYY, '')  
				 ,@EggGrade		= ISNULL(EggGrade, '') 
				 ,@Region		= ISNULL(Region, '') 
				-- ,@EggColor		= ISNULL(EggColor, '')

		FROM #BIZ_IN_DataBlock1

	-- Temp Table, Temp DB에 있으면 지우기 ------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Temp_OrderNo')				IS NOT NULL DROP TABLE #Temp_OrderNo 
	IF OBJECT_ID('tempdb..#Temp_OrderNo2')				IS NOT NULL DROP TABLE #Temp_OrderNo2
	IF OBJECT_ID('tempdb..#EggMarketPrice')				IS NOT NULL DROP TABLE #EggMarketPrice
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
			   
			  
  --====================================================================

  INSERT INTO #BIZ_OUT_DataBlock1 (
									CompanySeq
									--  TypeSeq
									, Type
									--, EggGradeSeq
									, Region
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
   SELECT @CompanySeq
   		--, T.Type
		, B.MinorName AS Type
		, T.Region
		, T.Grade  AS EggGrade
		, T.MM01   AS Prc01 
		, T.MM02   AS Prc02
		, T.MM03   AS Prc03
		, T.MM04   AS Prc04
		, T.MM05   AS Prc05
		, T.MM06   AS Prc06
		, T.MM07   AS Prc07
		, T.MM08   AS Prc08
		, T.MM09   AS Prc09
		, T.MM10   AS Prc10
		, T.MM11   AS Prc11
		, T.MM12   AS Prc12
		FROM (
    SELECT B.CompanySeq
		, B.Type
		, B.Region
		, 0 AS RegionNo
		, B.Grade
		, B.GradeNo
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 01 THEN B.Price ELSE 0 END) AS MM01
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 02 THEN B.Price ELSE 0 END) AS MM02
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 03 THEN B.Price ELSE 0 END) AS MM03
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 04 THEN B.Price ELSE 0 END) AS MM04
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 05 THEN B.Price ELSE 0 END) AS MM05
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 06 THEN B.Price ELSE 0 END) AS MM06
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 07 THEN B.Price ELSE 0 END) AS MM07
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 08 THEN B.Price ELSE 0 END) AS MM08
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 09 THEN B.Price ELSE 0 END) AS MM09
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 10 THEN B.Price ELSE 0 END) AS MM10
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 11 THEN B.Price ELSE 0 END) AS MM11
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 12 THEN B.Price ELSE 0 END) AS MM12
  FROM( 
						 SELECT   A.CompanySeq
								, A.Type
								, A.STDDT
						 		, A.Grade
								, B.GradeNo
								, '평균' AS Region
								, 0		 AS RegionNo
								, AVG(A.Price) AS Price
								, COUNT(A.Region) AS CNT
						 FROM (
												SELECT    CompanySeq
														, CASE WHEN Type = 2000153001 OR Type = 2000153003 THEN 2000153001 ELSE Type END Type 
														, LEFT(STDDT, 6) AS STDDT
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
						 GROUP BY A.CompanySeq, A.Type, A.STDDT, B.GradeNo, A.Grade --,A.Region --, A.Price
	) AS B
  WHERE LEFT(B.STDDT, 4) =  @StdYY
  GROUP BY B.CompanySeq, B.Type, B.Region, B.Grade, B.GradeNo --, B.STDDT, B.Price

  UNION ALL

  SELECT  B.CompanySeq
        , B.Type
		, B.Region
		, B.RegionNo
		, B.Grade
		, B.GradeNo
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 01 THEN B.Price ELSE 0 END) AS MM01
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 02 THEN B.Price ELSE 0 END) AS MM02
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 03 THEN B.Price ELSE 0 END) AS MM03
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 04 THEN B.Price ELSE 0 END) AS MM04
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 05 THEN B.Price ELSE 0 END) AS MM05
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 06 THEN B.Price ELSE 0 END) AS MM06
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 07 THEN B.Price ELSE 0 END) AS MM07
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 08 THEN B.Price ELSE 0 END) AS MM08
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 09 THEN B.Price ELSE 0 END) AS MM09
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 10 THEN B.Price ELSE 0 END) AS MM10
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 11 THEN B.Price ELSE 0 END) AS MM11
		, SUM(CASE WHEN SUBSTRING(B.STDDT, 5,2) = 12 THEN B.Price ELSE 0 END) AS MM12
  FROM( 
						 SELECT  A.CompanySeq 
								, A.Type
								, A.STDDT
						 		, A.Grade
								, B.GradeNo
								, A.Region
								, C.RegionNo
								, AVG(A.Price) AS Price
								--, COUNT(*) AS CNT
						 FROM (
												SELECT   CompanySeq 
														,CASE WHEN Type = 2000153001 OR Type = 2000153003 THEN 2000153001 ELSE Type END Type 
														,LEFT(STDDT, 6) AS STDDT
														, Grade
														--, Region
														, CASE WHEN Region = '경기' OR Region = '수도권' OR Region = '충청' THEN '수도권' 
															   WHEN Region = '경상' OR Region = '경남' OR Region = '경북' OR Region = '영주' THEN '경상'
														  ELSE Region END AS Region
														-- , COUNT(*) AS CNT
														, Price
												FROM #EggMarketPrice
											    GROUP BY CompanySeq, Type, LEFT(STDDT, 6), Grade, Region, Price
								) AS A
						 INNER JOIN #Temp_OrderNo  AS B	ON A.Grade  = B.Grade
						 INNER JOIN #Temp_OrderNo2 AS C ON A.Region = C.Region
						 GROUP BY  A.CompanySeq, A.Type, A.STDDT, B.GradeNo, C.RegionNo, A.Grade, A.Region --, A.Price
	) AS B
  WHERE LEFT(B.STDDT, 4) =  @StdYY
  GROUP BY  B.CompanySeq, B.Type, B.Region, B.Grade, B.RegionNo, B.GradeNo --, B.STDDT, B.Price
  ) AS T
  LEFT JOIN _TDAUMinor AS B ON T.CompanySeq = B.CompanySeq AND T.Type = B.MinorSeq AND B.MajorSeq = 2000153
  WHERE T.CompanySeq = @CompanySeq
	AND T.Grade LIKE '%' + @EggGrade + '%' 
	AND T.Region LIKE '%' + @Region	+ '%'
	-- AND T.EggColor LIKE '%' + @EggColor + '%'
  ORDER BY T.RegionNo, T.GradeNo ASC





   
--  SELECT B.Type
--		, B.Region
--		, B.Grade
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 01 THEN B.Price ELSE 0 END AS MM01
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 02 THEN B.Price ELSE 0 END AS MM02
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 03 THEN B.Price ELSE 0 END AS MM03
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 04 THEN B.Price ELSE 0 END AS MM04
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 05 THEN B.Price ELSE 0 END AS MM05
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 06 THEN B.Price ELSE 0 END AS MM06
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 07 THEN B.Price ELSE 0 END AS MM07
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 08 THEN B.Price ELSE 0 END AS MM08
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 09 THEN B.Price ELSE 0 END AS MM09
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 10 THEN B.Price ELSE 0 END AS MM10
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 11 THEN B.Price ELSE 0 END AS MM11
--		, CASE WHEN SUBSTRING(B.STDDT, 5,2) = 12 THEN B.Price ELSE 0 END AS MM12
--  FROM( 
  	
--	SELECT  CASE WHEN Type = 2000153001 OR Type = 2000153003 THEN 2000153001 ELSE Type END Type 
--			,LEFT(STDDT, 6) AS STDDT
--			, A.Grade
--			, B.GradeNo
--			, '평균' AS Region
--			, AVG(A.Price) AS Price
--			-- , COUNT(A.Region) AS CNT
--	FROM #EggMarketPrice AS A 
--	INNER JOIN #Temp_OrderNo  AS B	ON A.Grade  = B.Grade
--	WHERE LEFT(STDDT, 4) = 2023
--	GROUP BY Type, LEFT(STDDT, 6), A.Grade, B.GradeNo 
----	ORDER BY B.GradeNo ASC
-- ) AS B	
-- GROUP BY B.Type, B.Region, B.Grade, B.GradeNo --, B.STDDT, B.Price 
-- ORDER BY B.GradeNo ASC
