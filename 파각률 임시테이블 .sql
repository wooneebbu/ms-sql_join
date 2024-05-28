--======================================================
-- 김주임님 쿼리문
--======================================================
  SELECT QCSeq, UMQcTitleSeq
       , MAX(CrackQtyRate) AS MCrackQtyRate
    INTO #Temp1
    FROM join_TPDQCTestReportSub                
   WHERE QcSeq = 54
   GROUP BY QCSeq, UMQcTitleSeq


SELECT *
  FROM #Temp1 AS A

  JOIN join_TPDQCTestReportSub   AS B ON A.QCSeq    = B.QCSeq
			                    AND A.UMQCTitleSeq  = B.UMQCTitleSeq
			                    AND A.MCrackQtyRate = B.CrackQtyRate
 WHERE A.QcSeq = 54
   
 --CrackQty , CrackQtyRate



 --=====================================================
 -- 강책임님 쿼리문 
 --=====================================================
 SELECT T.QCSeq, T.SampleSeq, T.QCTitleBadQty, T.CrackQty, T.CrackQtyRate FROM
(
	SELECT A.QCSeq, A.SampleSeq, A.QCTitleBadQty, A.CrackQty, A.CrackQtyRate, RANK() OVER(PARTITION BY A.QCSeq ORDER BY A.SampleSeq DESC) AS C_SampleSeq
	from join_TPDQCTestReportSub AS A
		JOIN (
      SELECT QCSeq, SampleSeq, MAX(CrackQtyRate) CrackQtyRate, RANK() OVER(PARTITION BY QCSeq ORDER BY CrackQtyRate DESC) AS C_RANK
			FROM join_TPDQCTestReportSub
			--where QCSeq = 50
			GROUP BY QCSeq, SampleSeq, CrackQtyRate
		) AS B ON B.QCSeq = A.QCSeq AND B.SampleSeq = A.SampleSeq
	WHERE B.C_RANK = 1
) AS T
WHERE T.C_SampleSeq = 1



--=========================================================
-- 팀장님 쿼리문 
--=========================================================
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp

select * into #Temp
from (
select 71961 QCSeq, 1 SampleSeq, 4.170 CrackQtyRate, 10 QCTitleBadQty, 100 CrackQty
union all
select 71961, 2, 4.170, 30, 40
union all
select 71961, 3, 4.170, 77, 88) a

--#Temp 조회
select * from #Temp

--====================================================================================
-- 1번	
-- 검사Seq와 MAX(파각률)로 LEFT OUTER JOIN => MAX(수량)을 가져옴
-- 위 1번 방법은 QCTitleBadQty, CrackQty 다른 Row(SampleSeq)의 값을 가져올 수 있음. 
--====================================================================================

	SELECT QCTitleBadQty, CrackQty, T.* 
	FROM 
	(
	SELECT QCSeq,  -- 검사세부항목                          
      MAX(CASE UMQCTitleSeq WHEN 6002009 THEN TestValue ELSE '' END)  AS UMUnItem01,  --난황색도                         
      MAX(CASE UMQCTitleSeq WHEN 6002012 THEN TestValue ELSE '' END)  AS UMUnItem02,  --박스당 수량(EA)                        
      MAX(CASE UMQCTitleSeq WHEN 6002004 THEN TestValue ELSE '' END)  AS UMUnItem03,  --외관상태                         
      MAX(CASE UMQCTitleSeq WHEN 6002014 THEN TestValue ELSE '' END) AS UMUnItem04,  --입고수(BOX)                        
      MAX(CASE UMQCTitleSeq WHEN 6002013 THEN TestValue ELSE '' END)  AS UMUnItem05,  --중량(KG)                         
      MAX(CASE UMQCTitleSeq WHEN 6002010 THEN left(convert(char, CrackQtyRate), 5) ELSE '' END)  AS UMUnItem06,  --파각률(%)                         
      MAX(CASE UMQCTitleSeq WHEN 6002011 THEN TestValue ELSE '' END)  AS UMUnItem07,  --평균중량(g)                        
      MAX(CASE UMQCTitleSeq WHEN 6002005 THEN TestValue ELSE '' END)  AS UMUnItem08,  --평균HU                          
      MAX(CASE UMQCTitleSeq WHEN 6002008 THEN TestValue ELSE '' END)  AS UMUnItem09,  --혈/육반(%)                         
      MAX(CASE UMQCTitleSeq WHEN 6002007 THEN TestValue ELSE '' END)  AS UMUnItem10,  --HU60이상(%)                        
      MAX(CASE UMQCTitleSeq WHEN 6002006 THEN TestValue ELSE '' END)  AS UMUnItem11,  --HU72이상(%)
	  MAX(CASE UMQCTitleSeq WHEN 6002015 THEN TestValue ELSE '' END)  AS UMUnItem12   --불량수(EA)
   --INTO #join_TPDQCTestReportSub                        
   FROM join_TPDQCTestReportSub                          
   where QCSeq = 71961
   GROUP BY QCSeq     
   ) T
   left outer join 
   (select QCSeq, CrackQtyRate, MAX(QCTitleBadQty) QCTitleBadQty, MAX(CrackQty) CrackQty
    --from join_TPDQCTestReportSub
	from #Temp
    group by QCSeq, CrackQtyRate) B 
    on T.QCSeq = B.QCSeq and T.UMUnItem06 = left(convert(char, B.CrackQtyRate), 5)

--====================================================================================
-- 2번
-- 검사Seq와 MAX(파각률)로 LEFT OUTER JOIN => MAX(SampleSeq)을 가져옴 
-- => 검사Seq, MAX(SampleSeq) 고유Key값으로 LEFT OUTER JOIN 하여 수량을 가져옴
--====================================================================================

	SELECT C.QCTitleBadQty, C.CrackQty, T.*  
	FROM 
	(
	SELECT QCSeq,  -- 검사세부항목                          
      MAX(CASE UMQCTitleSeq WHEN 6002009 THEN TestValue ELSE '' END)  AS UMUnItem01,  --난황색도                         
      MAX(CASE UMQCTitleSeq WHEN 6002012 THEN TestValue ELSE '' END)  AS UMUnItem02,  --박스당 수량(EA)                        
      MAX(CASE UMQCTitleSeq WHEN 6002004 THEN TestValue ELSE '' END)  AS UMUnItem03,  --외관상태                         
      MAX(CASE UMQCTitleSeq WHEN 6002014 THEN TestValue ELSE '' END) AS UMUnItem04,  --입고수(BOX)                        
      MAX(CASE UMQCTitleSeq WHEN 6002013 THEN TestValue ELSE '' END)  AS UMUnItem05,  --중량(KG)                         
      MAX(CASE UMQCTitleSeq WHEN 6002010 THEN left(convert(char, CrackQtyRate), 5) ELSE '' END)  AS UMUnItem06,  --파각률(%)                         
      MAX(CASE UMQCTitleSeq WHEN 6002011 THEN TestValue ELSE '' END)  AS UMUnItem07,  --평균중량(g)                        
      MAX(CASE UMQCTitleSeq WHEN 6002005 THEN TestValue ELSE '' END)  AS UMUnItem08,  --평균HU                          
      MAX(CASE UMQCTitleSeq WHEN 6002008 THEN TestValue ELSE '' END)  AS UMUnItem09,  --혈/육반(%)                         
      MAX(CASE UMQCTitleSeq WHEN 6002007 THEN TestValue ELSE '' END)  AS UMUnItem10,  --HU60이상(%)                        
      MAX(CASE UMQCTitleSeq WHEN 6002006 THEN TestValue ELSE '' END)  AS UMUnItem11,  --HU72이상(%)
	  MAX(CASE UMQCTitleSeq WHEN 6002015 THEN TestValue ELSE '' END)  AS UMUnItem12   --불량수(EA)
   --INTO #join_TPDQCTestReportSub            
   FROM join_TPDQCTestReportSub                          
   -- where QCSeq = 71961
   GROUP BY QCSeq     
   ) T
   left outer join 
   (select QCSeq, CrackQtyRate, MAX(SampleSeq) SampleSeq	
    --from join_TPDQCTestReportSub
	from #Temp
    group by QCSeq, CrackQtyRate) B 
    on T.QCSeq = B.QCSeq and T.UMUnItem06 = left(convert(char, B.CrackQtyRate), 5)
	--left outer join join_TPDQCTestReportSub C
	left outer join #Temp C
	on B.QCSeq = C.QCSeq and B.SampleSeq = C.SampleSeq
   

--================================================
--22.12.29 수정사항 반영 (팀장님 수정까지)
--================================================

 SUM(ISNULL(QCTitleBadQty, 0)) AS QCTitleBadQty, -- 파각수량
    SUM(ISNULL(CrackQty, 0)) AS CrackQty, -- 수량
    CASE WHEN SUM(ISNULL(QCTitleBadQty, 0)) <> 0 THEN 
	LEFT(CONVERT(CHAR, ROUND(SUM(ISNULL(CrackQty, 0))/SUM(ISNULL(QCTitleBadQty, 0))*100, 2)), 5) 
  ELSE '' END AS UMUnItem06 --파각률 

-- ISNULL처리는 숫자들어간 모든부분에 들어가줘야함 
-- 0나누기 오류가 안나려면 0나누기 오류 안나는 기본 쿼리문을 써줘도 되지만, CASE 문으로 오류 최대한 줄일수 있게 해야됨
--========================================================

