USE [JOIN]
GO

/****** Object:  View [dbo].[join_TPDQCComplain_All_VW1]    Script Date: 2024-05-22 오후 4:17:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO












-- 2020.01.10
-- 조인 및 계열사 join_TPDQCComplain 뷰

-- 2021.02.19
-- 수정자: 서정한
-- 수정내용1: ProdView -> Reason, FactoryView -> RPlan 변경
-- 수정내용2: RStateSeq, RStateName, QltDt, QltUserSeq, QltUserName 추가

-- 2021.03.08
-- 수정자: 서정한
-- 수정내용: 해원 거래처 추가 ([JOIN_CO3] CompanySeq = 42)

-- 2021.03.27
-- 수정자: 서정한
-- 수정내용: CompanyName 추가

-- 2021.03.30
-- 수정자: 서정한
-- 수정내용: Conc 추가

-- 2021.04.02
-- 수정자: 서정한
-- 수정내용: BlameSeq, BlameName 추가

-- 2021.07.12
-- 수정자: 김종엽
-- 수정내용:[JOIN_FARMS] DB 추가

-- 2021.10.22
-- 수정자: 서정한
-- 수정내용: TargetYNSeq/TargetYNName 필드 추가

-- 2021.10.27
-- 수정자: 서정한
-- 수정내용: IsClaim 필드 추가

-- 2021.10.28
-- 수정자: 서정한
-- 수정내용: 엔제이웰팜 추가 ([JOIN_CO1] CompanySeq = 12)


ALTER VIEW [dbo].[join_TPDQCComplain_All_VW1]
AS
/*

-- 2020.11.17
-- 불만코드 대/중/소분류 뷰

ALTER VIEW [dbo].[join_ComplainCodeSeq_VW1]
AS

SELECT I3.CompanySeq
, I3.MinorSeq                   AS CSSeq
, I3.MinorName                  AS CSSName
, ISNULL(K3.MinorSeq, '')		AS CMSeq  --중분류  
, ISNULL(K3.MinorName, '')		AS CMName --중분류명
, ISNULL(N3.MinorSeq, '')		AS CLSeq  --대분류   
, ISNULL(N3.MinorName, '')		AS CLName --대분류명     
, I3.IsUse
, ISNULL(CL.ValueText, 0) AS IsClaim
FROM _TDAUMinor AS I3 with(nolock) 
LEFT OUTER JOIN _TDAUMinorValue AS J3 with(nolock) ON I3.CompanySeq = J3.CompanySeq
                                                  AND I3.MajorSeq = J3.MajorSeq
                                                  AND I3.MinorSeq = J3.MinorSeq 
                                                  AND J3.Serl = 1000001
LEFT OUTER JOIN _TDAUMinor  AS K3 with(nolock)     ON J3.ValueSeq = K3.MinorSeq 
                                                  and J3.CompanySeq = K3.CompanySeq       
LEFT OUTER JOIN _TDAUMinorValue AS L3 with(nolock) ON K3.MinorSeq = L3.MinorSeq 
                                                  and L3.Serl = 1000001 
                                                  and K3.MajorSeq = L3.MajorSeq 
                                                  and K3.CompanySeq = L3.CompanySeq        
LEFT OUTER JOIN _TDAUMinor  AS N3 with(nolock)     ON L3.ValueSeq = N3.MinorSeq 
                                                  and L3.CompanySeq = N3.CompanySeq
LEFT OUTER JOIN _TDAUMinorValue AS CL with(nolock) ON N3.MinorSeq = CL.MinorSeq 
                                                  and CL.Serl = 1000001 
                                                  and N3.MajorSeq = CL.MajorSeq 
                                                  and N3.CompanySeq = CL.CompanySeq
WHERE I3.MajorSeq = 2000016
--ORDER BY I3.CompanySeq, I3.MinorSort

*/



SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL(I.ItemName, '') AS GoodName
    ,ISNULL(U.UnitName, '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL(F1.MinorName, '') AS ComplainCodeName 
    ,ISNULL(F2.MinorName, '') AS DemandName 
    ,ISNULL(F3.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL(F3.MinorName, '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN   -- 첨부파일 유무 
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL(F4.MinorName, '') AS ComplainStateName 
    ,ISNULL(C1.EmpName, '')   AS DealingEmpName 
    ,ISNULL(E1.DeptName, '')  AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView						--20200318 Add
	,ISNULL(A.Reason, '') AS Reason
    ,ISNULL(A.RPlan, '')  AS RPlan							 			                                --20210219 Update
	,ISNULL(ItemType.UMItemType, 0)      AS UMItemType
    ,ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	                                            --20200608 Add
	, A.DemandSeq2
    , A.InOutSeq
	, F2.MinorName AS DemandName2 
	, F5.MinorName AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq
    , CLName
    , CMSeq
    , CMName
	, VW2.ItemClassLSeq
    , VW2.ItemClassLName
    , VW2.ItemClassMSeq
    , VW2.ItemClassMName
    , VW2.ItemClassSSeq
    , VW2.ItemClassSName
	, A.RootSeq
	,F6.MinorName	AS RootName
	, A.RStateSeq 
    ,A.QltDt 
    ,A.QltUserSeq																							--20210219 Add
	,F7.MinorName AS RStateName				--20210219 Add
	,(SELECT EmpName FROM [JOIN].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 1 AND EmpSeq = A.QltUserSeq)	AS QltUserName				--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 1 AND MinorSeq = A.BlameSeq)	AS BlameName		--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 1 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN].[dbo].join_TPDQCComplain  AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN].[dbo]._TDABizUnit  AS B WITH(NOLOCK)  ON A.CompanySeq = B.CompanySeq      AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN].[dbo]._TDAEmp      AS C WITH(NOLOCK)  ON A.CompanySeq = C.CompanySeq      AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDAEmp      AS C1 WITH(NOLOCK) ON A.CompanySeq = C1.CompanySeq    AND A.DealingEmpSeq = C1.EmpSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDACust     AS D WITH(NOLOCK)  ON A.CompanySeq = D.CompanySeq      AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDADept     AS E WITH(NOLOCK)  ON A.CompanySeq = E.CompanySeq      AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDADept     AS E1 WITH(NOLOCK)    ON A.CompanySeq = E1.CompanySeq AND A.DealingDeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq 
                                                                                                   AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F WITH(NOLOCK)  ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F1 WITH(NOLOCK) ON A.CompanySeq = F1.CompanySeq AND A.ComplainCodeSeq = F1.MinorSeq 
                                                                                                   AND F1.MajorSeq = 2000016          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F2 WITH(NOLOCK) ON A.CompanySeq = F2.CompanySeq AND A.DemandSeq    = F2.MinorSeq 
                                                                                                   AND F2.MajorSeq = 2000017          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F3 WITH(NOLOCK) ON A.CompanySeq = F3.CompanySeq AND A.BlackYN   = F3.MinorSeq 
                                                                                                   AND F3.MajorSeq = 2000030          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F4 WITH(NOLOCK) ON A.CompanySeq = F4.CompanySeq AND A.ComplainState = F4.MinorSeq 
                                                                                                   AND F4.MajorSeq = 2000062          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F5 WITH(NOLOCK) ON A.CompanySeq = F5.CompanySeq AND A.InOutSeq = F5.MinorSeq 
                                                                                                   AND F5.MajorSeq = 2000015          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F6 WITH(NOLOCK) ON A.CompanySeq = F5.CompanySeq AND A.RootSeq = F6.MinorSeq 
                                                                                                   AND F6.MajorSeq = 2000157          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F7 WITH(NOLOCK) ON A.CompanySeq = F5.CompanySeq AND A.RStateSeq = F7.MinorSeq 
                                                                                                   AND F7.MajorSeq = 2000169        -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F7 WITH(NOLOCK) ON A.CompanySeq = F5.CompanySeq AND A.RStateSeq = F7.MinorSeq 
                                                                                                   AND F7.MajorSeq = 2000169        -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor      AS F7 WITH(NOLOCK) ON A.CompanySeq = F5.CompanySeq AND A.RStateSeq = F7.MinorSeq 
                                                                                                   AND F7.MajorSeq = 2000169        -- subquery 수정

   LEFT OUTER JOIN [JOIN].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN].[dbo]._TDAItem        AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq   AND A.GoodSeq = I.ItemSeq          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo]._TDAUnit        AS U WITH(NOLOCK) ON A.CompanySeq = U.CompanySeq   AND A.UnitSeq = U.UnitSeq          -- subquery 수정
   LEFT OUTER JOIN [JOIN].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq -- 품질 코드 가져옴
   -- LEFT OUTER JOIN [JOIN].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq / 제품 대/중/소분류 가져오는 뷰
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq -- 품목유형 가져오는 테이블 / 이것만 필요





UNION ALL
--20210712 Add
SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_FARMS].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 7 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_FARMS].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 7 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_FARMS].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 7 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_FARMS].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 7 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView						--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																							--20210219 Add
	,(SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.RStateSeq)	AS RStateName			--20210219 Add
	,(SELECT EmpName FROM [JOIN_FARMS].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 7 AND EmpSeq = A.QltUserSeq)	AS QltUserName				--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.BlameSeq)	AS BlameName			--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_FARMS].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 7 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_FARMS].[dbo].join_TPDQCComplain  AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_FARMS].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_FARMS].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_FARMS].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_FARMS].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq

UNION ALL

SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_AL].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 3 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_AL].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 3 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_AL].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 3 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_AL].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 3 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView							--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																							--20210219 Add
	,(SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.RStateSeq)	AS RStateName			--20210219 Add
	,(SELECT EmpName FROM [JOIN_AL].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 3 AND EmpSeq = A.QltUserSeq)	AS QltUserName				--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.BlameSeq)	AS BlameName		--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_AL].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 3 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_AL].[dbo].join_TPDQCComplain   AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_AL].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_AL].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_AL].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_AL].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_AL].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq

UNION ALL

SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_SYNEW].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 4 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_SYNEW].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 4 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_SYNEW].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 4 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_SYNEW].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 4 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView							--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																							--20210219 Add
	,(SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.RStateSeq)	AS RStateName			--20210219 Add
	,(SELECT EmpName FROM [JOIN_SYNEW].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 4 AND EmpSeq = A.QltUserSeq)	AS QltUserName			--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.BlameSeq)	AS BlameName		--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_SYNEW].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 4 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_SYNEW].[dbo].join_TPDQCComplain   AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_SYNEW].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_SYNEW].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_SYNEW].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq

UNION ALL

SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_SING].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 6 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_SING].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 6 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_SING].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 6 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_SING].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 6 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView							--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																						--20210219 Add
	,(SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.RStateSeq)	AS RStateName		--20210219 Add
	,(SELECT EmpName FROM [JOIN_SING].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 6 AND EmpSeq = A.QltUserSeq)	AS QltUserName		--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.BlameSeq)	AS BlameName		--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_SING].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 6 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_SING].[dbo].join_TPDQCComplain   AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_SING].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_SING].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_SING].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_SING].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_SING].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq


UNION ALL

SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_CO3].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 42 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_CO3].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 42 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_CO3].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 42 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_CO3].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 42 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView							--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																							--20210219 Add
	,(SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.RStateSeq)	AS RStateName			--20210219 Add
	,(SELECT EmpName FROM [JOIN_CO3].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 42 AND EmpSeq = A.QltUserSeq)	AS QltUserName				--20210219 Add
	,concat('00',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.BlameSeq)	AS BlameName		--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_CO3].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 42 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_CO3].[dbo].join_TPDQCComplain   AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_CO3].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_CO3].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_CO3].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_CO3].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq


UNION ALL
--20211028 Add
SELECT A.CompanySeq
	,A.ComplainSeq
    ,A.BizUnit
    ,A.OccuDate
    ,A.ComplainNo
    ,A.GoodSeq
    ,A.UnitSeq
    ,A.Qty
    ,A.KeepStatus
    ,A.BuyingDate
    ,A.PkgDate
    ,A.DeptSeq
    ,A.EmpSeq
    ,A.CustSeq
    ,A.Customer
    ,A.Tel
    ,A.AddrZip
    ,A.Addr
    ,A.Addr2
    ,A.ComplainCodeSeq
    ,A.DemandSeq
    ,A.Amt
    ,A.ComplainSpec
    ,A.DealingSpec
    ,A.EtcSpec
    ,A.UptDate
    ,A.LimitTerm
    ,ISNULL(B.BizUnitName, '') AS BizUnitName
    ,ISNULL((SELECT ItemName FROM [JOIN_CO1].[dbo]._TDAItem WITH(NOLOCK) Where CompanySeq = 12 AND ItemSeq =  A.GoodSeq), '') AS GoodName
    ,ISNULL((SELECT UnitName FROM [JOIN_CO1].[dbo]._TDAUnit WITH(NOLOCK) Where CompanySeq = 12 AND UnitSeq =  A.UnitSeq), '') AS UnitName 
    ,ISNULL(E.DeptName, '') AS DeptName
    ,ISNULL(C.EmpName, '')  AS EmpName
    ,ISNULL(D.CustName, '') AS CustName
    ,ISNULL((SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq =  A.ComplainCodeSeq), '') AS ComplainCodeName 
    ,ISNULL((SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.DemandSeq), '') AS DemandName 
    ,ISNULL(F.MinorName, '') AS UMChannelName
    ,ISNULL(D1.UMCustClass, 0) AS UMChannel
    ,A.BlackYN
    ,ISNULL((SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq =  A.BlackYN), '') AS BlackYNName 
    ,(CASE ISNULL(A.FileSeq, 0) WHEN 0 THEN 0  ELSE 1 END) AS FileYN
    ,A.FileSeq
    ,A.FactUnit
    ,ISNULL(FU.FactUnitName, '') AS FactUnitName
    ,ComplainState  
    ,DealingEmpSeq
    ,DealingDeptSeq
    ,ISNULL((SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.ComplainState), '') AS ComplainStateName 
    ,ISNULL((SELECT EmpName   FROM [JOIN_CO1].[dbo]._TDAEmp    WITH(NOLOCK) Where CompanySeq = 12 AND EmpSeq = A.DealingEmpSeq), '')   AS DealingEmpName 
    ,ISNULL((SELECT DeptName  FROM [JOIN_CO1].[dbo]._TDADept   WITH(NOLOCK) Where CompanySeq = 12 AND DeptSeq = A.DealingDeptSeq), '') AS DealingDeptName 
	--,ISNULL(A.ProdView, '') AS ProdView, ISNULL(A.FactoryView, '') AS FactoryView						--20200318 Add
	,ISNULL(A.Reason, '') AS Reason, ISNULL(A.RPlan, '') AS RPlan										--20210219 Update
	,ISNULL(ItemType.UMItemType, 0) AS UMItemType, ISNULL(ItemType.UMItemTypeName, '') AS UMItemTypeName	--20200608 Add
	, A.DemandSeq2, A.InOutSeq
	,(SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.DemandSeq2)	AS DemandName2 
	,(SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.InOutSeq)	AS InOutName 
	, VW.IsClaim AS IsClaim		-- Add 20211027
	, CLSeq, CLName, CMSeq, CMName
	, VW2.ItemClassLSeq, VW2.ItemClassLName, VW2.ItemClassMSeq, VW2.ItemClassMName, VW2.ItemClassSSeq, VW2.ItemClassSName
	, A.RootSeq
	,(SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.RootSeq)	AS RootName
	, A.RStateSeq ,A.QltDt ,A.QltUserSeq																							--20210219 Add
	,(SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.RStateSeq)	AS RStateName			--20210219 Add
	,(SELECT EmpName FROM [JOIN_CO1].[dbo]._TDAEmp WITH(NOLOCK) Where CompanySeq = 12 AND EmpSeq = A.QltUserSeq)	AS QltUserName				--20210219 Add
	,concat('000',A.CompanySeq)+concat('000',A.FactUnit) AS Conc	--20210330 Add
	, A.BlameSeq													--20210402 Add
	, (SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.BlameSeq)	AS BlameName			--20210402 Add
	, A.TargetYNSeq													--20211022 Add
	, (SELECT MinorName FROM [JOIN_CO1].[dbo]._TDAUMinor WITH(NOLOCK) Where CompanySeq = 12 AND MinorSeq = A.TargetYNSeq)	AS TargetYNName		--20211022 Add

   FROM [JOIN_CO1].[dbo].join_TPDQCComplain  AS A WITH(NOLOCK)
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDABizUnit  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDAEmp      AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  AND A.EmpSeq = C.EmpSeq
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDACust     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  AND A.CustSeq = D.CustSeq
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDADept     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  AND A.DeptSeq = E.DeptSeq
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDACustClass   AS D1 WITH(NOLOCK) ON D.CompanySeq = D1.CompanySeq AND D.CustSeq = D1.CustSeq AND D1.UMajorCustClass = 8004 
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDAUMinor      AS  F WITH(NOLOCK) ON D1.CompanySeq = F.CompanySeq AND D1.UMCustClass  = F.MinorSeq
   LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDAFactUnit    AS FU WITH(NOLOCK) ON FU.CompanySeq = A.CompanySeq AND FU.FactUnit   = A.FactUnit
   LEFT OUTER JOIN [JOIN_CO1].[dbo].join_ComplainCodeSeq_VW1	AS VW  ON VW.CompanySeq  = A.CompanySeq AND VW.CSSeq	= A.ComplainCodeSeq
   LEFT OUTER JOIN [JOIN_CO1].[dbo].join_TDAItemClass_VW1		AS VW2 ON VW2.CompanySeq = A.CompanySeq AND VW2.ItemSeq	= A.GoodSeq
   LEFT OUTER JOIN  (  
						SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMItemType, ISNULL(B.MinorName, '') AS UMItemTypeName  
						FROM [JOIN_CO1].[dbo]._TDAItemUserDefine AS A WITH(NOLOCK)  
						LEFT OUTER JOIN [JOIN_CO1].[dbo]._TDAUMinor AS B WITH(NOLOCK)   
						ON A.CompanySeq = B.CompanySeq            
						AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000145  --품목유형(품질)_join
						WHERE A.MngSerl = 1000033 --품목유형(품질)_join  
					) AS ItemType ON A.CompanySeq = ItemType.CompanySeq  AND A.GoodSeq = ItemType.ItemSeq
				
GO

