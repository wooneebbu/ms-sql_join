 --SELECT * FROM joinbio_DelvPlanSimulation
  

-- SELECT * FROM joinbio_DelvPlanSimulationMake


-- 참고화면 농장현황 // joinbio_DailyReportGubunQuery

IF OBJECT_ID('tempdb..#DataMonth')		IS NOT NULL DROP TABLE #DataMonth

--=================================================
-- 월별 조회화면 합계 -- MONTH
--=================================================

--========================
-- 임시테이블 생성
--========================


CREATE TABLE #DataMonth
			(
			 InCompany			 NVARCHAR(20)
			, STDYMWD			 VARCHAR(10)
			, EggTypeSeq		 VARCHAR(10)
			, EggGradeSeq		 INT
			, EggMTypeSeq		 INT
			, EggWeightSeq		 INT
			, Qty				 DECIMAL (19, 5)
			)

--=========================
-- 데이터 테이블 
--=========================

 INSERT #DataMonth
 SELECT  InCompany 
		, LEFT(STDYMD, 6) + '0000'  AS STDYMWD
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
		, SUM(Qty) AS QTY
 FROM joinbio_DelvPlanSimulationMake
 WHERE SUBSTRING(STDYMD, 5, 2) = 11  
  -- InCompany IN ('조인', '성본')
  -- AND EggGradeSeq = @EggGradeSeq
  -- AND EggMTypeSeq = @EggMTypeSeq 
  -- AND SUBSTRING(STDYMD, 5, 2) = 09
  -- AND Qty <> 0
 GROUP BY InCompany
		, LEFT(STDYMD, 6) + '0000' 
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
 ORDER BY CASE WHEN InCompany = '성본' THEN 1
			   WHEN InCompany = '음성' THEN 2
			   WHEN InCompany = '세양' THEN 3
			   ELSE 9 END

--================================
-- 소계 INSERT (
--================================

-- IF @Total_EggGrade_Ckb = 1

INSERT #DataMonth

SELECT   InCompany
	   , LEFT(STDYMD, 6) + '0000'  AS STDYMWD
	   , '소계' AS  EggTypeSeq
	   , EggGradeSeq
	   , 2000182099
	   , 0
	   , SUM(Qty) AS QTY
  FROM joinbio_DelvPlanSimulationMake
WHERE SUBSTRING(STDYMD, 5, 2) = 11  
GROUP BY InCompany
		, LEFT(STDYMD, 6) + '0000' 
		, EggTypeSeq
		, EggGradeSeq

	   
-- ELSE IF @Total_EggMType_Ckb = 1

INSERT #DataMonth

SELECT   InCompany
	   , LEFT(STDYMD, 6) + '0000'  AS STDYMWD
	   , '소계' AS  EggTypeSeq
	   , 2000182099
	   , EggMTypeSeq
	   , 0
	   , SUM(Qty) AS QTY
  FROM joinbio_DelvPlanSimulationMake
WHERE SUBSTRING(STDYMD, 5, 2) = 11  
GROUP BY InCompany
		, LEFT(STDYMD, 6) + '0000' 
		, EggMTypeSeq
		, EggGradeSeq


SELECT * FROM #DataMonth
ORDER BY InCompany,  EggTypeSeq , EggMTypeSeq, EggGradeSeq
--ORDER BY InCompany, EggMtypeSeq, EggTypeSeq









/*
 UNION ALL
 SELECT   InCompany
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
		, SUM(Qty) AS QTY
		, SUBSTRING(STDYMD, 5, 2) AS MONTH
 FROM joinbio_DelvPlanSimulationMake
 WHERE InCompany = '음성'
  -- AND EggGradeSeq = @EggGradeSeq
  -- AND EggMTypeSeq = @EggMTypeSeq 
	 AND SUBSTRING(STDYMD, 5, 2) = 09
  -- AND Qty <> 0
 GROUP BY InCompany
		, SUBSTRING(STDYMD, 5, 2)
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
 UNION ALL
 SELECT   InCompany
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
		, SUM(Qty) AS QTY
		, SUBSTRING(STDYMD, 5, 2) AS MONTH
 FROM joinbio_DelvPlanSimulationMake
 WHERE InCompany = '세양'
  -- AND EggGradeSeq = @EggGradeSeq
  -- AND EggMTypeSeq = @EggMTypeSeq 
	 AND SUBSTRING(STDYMD, 5, 2) = 09
  -- AND Qty <> 0
 GROUP BY InCompany
		, SUBSTRING(STDYMD, 5, 2)
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
 UNION ALL
 SELECT   InCompany
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
		, SUM(Qty) AS QTY
		, SUBSTRING(STDYMD, 5, 2) AS MONTH
 FROM joinbio_DelvPlanSimulationMake
 WHERE InCompany = '알로팜'
  -- AND EggGradeSeq = @EggGradeSeq
  -- AND EggMTypeSeq = @EggMTypeSeq 
	 AND SUBSTRING(STDYMD, 5, 2) = 09
  -- AND Qty <> 0
 GROUP BY InCompany
		, SUBSTRING(STDYMD, 5, 2)
		, EggTypeSeq
		, EggGradeSeq
		, EggMTypeSeq
		, EggWeightSeq
*/