


   /* -----------------------------------------------------               
     설    명 - SKU판매단가분석_joinbio             
     작 성 일 - 2024-08-27                  
     작 성 자 - HHWoon          
	 ------------------------------------------------------*/

-- ALTER PROC [dbo].[joinbio_SSLOrderInvoiceSalesDayReportQueryAll]                                  
     @xmlDocument	NVARCHAR(MAX) ,                              
     @xmlFlags		INT  = 0,                              
     @ServiceSeq	INT  = 0,                              
     @WorkingTag	NVARCHAR(10)= '',                                    
     @CompanySeq	INT  = 1,                              
     @LanguageSeq	INT  = 1,                              
     @UserSeq		INT  = 0,                              
     @PgmSeq		INT  = 0                           
                          



	
DECLARE	  @StdYM		NVARCHAR(6)
		, @BFStdYM      NVARCHAR(6)


 SET   @StdYM = '202407'
 SET   @BFStdYM = (@StdYM - 1) 
                   
 
CREATE TABLE #TMP_Result  
     (  
         CompanySeq          INT,  
		 CompanyName2        NVARCHAR(100),  
         InvoiceDate	     NCHAR(8),
		 --StdYM			 NVARCHAR(6),
		 DeptSeq		     INT,  
		 DeptName	         NVARCHAR(200),  
		 EmpSeq			     INT,  
		 EmpName	         NVARCHAR(200),  
		 -- CustSeq		     INT,  
		 -- CustName		     NVARCHAR(200),  
		 -- CustSeq2		     INT,  
		 -- CustName2		     NVARCHAR(200),  
		 -- ChannelSeq		     INT,  
		 -- ChannelName         NVARCHAR(200),  
		 -- UMFactType		     INT,  
		 -- UMFactTypeName      NVARCHAR(200), 
		 ItemSeq		     INT,  
		 ItemName	         NVARCHAR(200),   
		 ItemClasSSName      NVARCHAR(200),  
		 ItemClasSMName      NVARCHAR(200),  
		 ItemClasSLName      NVARCHAR(200),  
		 AssetSeq		     INT,  
		 AssetName	         NVARCHAR(200),  
		 UnitSeq		     INT,  
		 UnitName	         NVARCHAR(200),
		 Qty                 DECIMAL(19,5),  
		 STDUnitSeq		     INT,  
		 STDUnitName	     NVARCHAR(200),
		 STDQty              DECIMAL(19,5),  
		 CUnitSeq		     INT,  
		 CUnitName	         NVARCHAR(200),
		 CQty                DECIMAL(19,5),  
		 DomAmt              DECIMAL(19,5),
         DomVAT              DECIMAL(19,5),
		 TotDomAmt           DECIMAL(19,5), 
		 RawClassMSeq        INT,  
		 RawClassMName	     NVARCHAR(200),  
		 ItemGubun	         INT,  
		 ItemGubunName	     NVARCHAR(200),
		 FreeAntibiotic      NVARCHAR(100),
		 ItemGroup	         INT,  
		 ItemGroupName	     NVARCHAR(200),
		 NBPB		         INT,  
		 NBPBName	         NVARCHAR(200),
		 EggQty			     DECIMAL(19,5),
		 OrderDateTo	     NCHAR(8)
     )  
--알단위 환산(조인)
CREATE TABLE #EggUnit
(
	CompanySeq			     INT
	,ItemSeq			     INT
	,EUnitSeq			     INT
	,EUnitName			     VARCHAR(100)
	,ECalc   			     DECIMAL(19, 5)
)
--알단위 환산(조인)
INSERT INTO #EggUnit ( CompanySeq, ItemSeq, EUnitSeq, EUnitName, ECalc )
SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 1   --알


IF @IsSales = 0	--전체
BEGIN
	IF @CompanySeq2 = 1			--조인
	BEGIN
		INSERT INTO #TMP_Result
		SELECT A.CompanySeq, COM.CompanyName CompanyName2, A.BizUnit, BIZ.BizUnitName, A.InvoiceDate
			, A.DeptSeq, ISNULL(DEPT.DeptName, '') DeptName, A.EmpSeq, ISNULL(EMP.EmpName, '') EmpName 
			, A.CustSeq, CUST.CustName 
			, CASE WHEN CANm.CustName IS NOT NULL THEN CAdd.MngValSeq ELSE A.CustSeq END AS CustSeq2					-- 실적집계거래처가 없다면 거래처로
			, CASE WHEN CANm.CustName IS NOT NULL THEN CANm.CustName ELSE CUST.CustName END AS CustName2				-- 실적집계거래처가 없다면 거래처로
			, ISNULL(CCls.UMCustClass, '') AS ChannelSeq     -- 거래처분류값 (유통구조) 코드 
			, (SELECT ISNULL(U.MinorName  , '') FROM [JOIN].[DBO]._TDAUMinor U WHERE U.CompanySeq = CCls.CompanySeq AND CCls.UMCustClass = U.MinorSeq) AS ChannelName   -- 유통구조 이름    
			, ISNULL(Fact.UMFactType, '') UMFactType, ISNULL(Fact.UMFactTypeName, '') UMFactTypeName   
			, I.ItemSeq, I.ItemName --품목명	   
			, V3.ItemClassSName  -- 소분류명
			, V3.ItemClassMName  -- 중분류명
			, V3.ItemClassLName  -- 대분류명
			, I.AssetSeq, Asset.AssetName 
			, SUnit.SUnitSeq AS UnitSeq, SUnit.SUnitName AS UnitName
			, B.Qty
			, I.UnitSeq AS STDUnitSeq, K.UnitName AS STDUnitName
			, B.STDQty 
			, CUnit.CUnitSeq, CUnit.CUnitName
			, ISNULL(CASE WHEN CUnit.CUnitSeq IS NULL OR CUnit.CUnitSeq = 0 OR ISNULL(CUnitC.ConvNum,0) = 0 THEN NULL 
				ELSE (B.STDQty * (CUnitC.ConvDen / CUnitC.ConvNum)) END, 0) AS CQty 
			, B.DomAmt  
			, B.DomVAT
			, B.DomAmt + B.DomVAT AS TotDomAmt
			, ISNULL(BB.MngValSeq, 0) AS RawClassMSeq
			, ISNULL(DD.MinorName, '') AS RawClassMName
			, EE.MngValSeq           AS ItemGubun
			, GG.MinorName          AS ItemGubunName	--20230602_khs
			, CASE WHEN CONVERT(INT, ISNULL(RR.MngValText, 0)) = 1 THEN 'TRUE' ELSE 'FALSE' END FreeAntibiotic  --무항생제유무
			, HH.MngValSeq AS ItemGroup
			, ISNULL(II.MinorName, '') AS ItemGroupName
			, JJ.MngValSeq AS NBPB
			, ISNULL(KK.MinorName, '') AS NBPBName
			, ISNULL(B.STDQty, 0) * ISNULL(EGG.ECalc, 0) AS EggQty --알단위 수량
			,ISNULL(OO2.OrderDate, '') AS OrderDateTo
		FROM [JOIN].[DBO]._TSLInvoice AS A WITH(NOLOCK)    
			JOIN [JOIN].[DBO]._TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.InvoiceSeq = A.InvoiceSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TDACust	  AS CUST WITH(NOLOCK) ON A.CompanySeq   = CUST.CompanySeq AND A.CustSeq   = CUST.CustSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDACustClass AS CCls WITH(NOLOCK) ON CUST.CompanySeq = CCls.CompanySeq AND CUST.CustSeq    = CCls.CustSeq AND CCls.UMajorCustClass = 8004   --유통구조 
			LEFT OUTER JOIN [JOIN].[DBO]._TDACustUserDefine	  AS CAdd WITH(NOLOCK) ON CUST.CompanySeq   = CAdd.CompanySeq AND CUST.CustSeq   = CAdd.CustSeq AND CAdd.MngSerl = '1000004'	-- 실적집계거래처
			LEFT OUTER JOIN [JOIN].[DBO]._TDACust	  AS CANm WITH(NOLOCK) ON CAdd.CompanySeq   = CANm.CompanySeq AND CAdd.MngValSeq   = CANm.CustSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItem      AS I WITH(NOLOCK) ON B.CompanySeq   = I.CompanySeq AND B.ItemSeq   = I.ItemSeq     
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemClass_VW1 AS V3 with(nolock) ON  B.ItemSeq = V3.ItemSeq and B.CompanySeq = V3.CompanySeq         
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUnit      AS J WITH(NOLOCK) ON B.CompanySeq   = J.CompanySeq AND B.UnitSeq   = J.UnitSeq                  
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUnit      AS K WITH(NOLOCK) ON I.CompanySeq   = K.CompanySeq AND I.UnitSeq   = K.UnitSeq    
			LEFT OUTER JOIN [JOIN].[DBO]._TDADept	  AS DEPT WITH(NOLOCK) ON A.CompanySeq = DEPT.CompanySeq AND A.DeptSeq   = DEPT.DeptSeq			
			LEFT OUTER JOIN [JOIN].[DBO]._TDAEmp		  AS EMP WITH(NOLOCK) ON A.CompanySeq = EMP.CompanySeq AND A.EmpSeq   = EMP.EmpSeq		
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemAsset AS Asset WITH (NOLOCK) ON I.CompanySeq = Asset.CompanySeq AND I.AssetSeq = Asset.AssetSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TDABizUnit	  AS BIZ with(nolock) ON  A.CompanySeq = BIZ.CompanySeq and A.BizUnit = BIZ.BizUnit
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemUnit_VW1 AS CUnit	with(nolock) ON  B.CompanySeq = CUnit.CompanySeq AND B.ItemSeq = CUnit.ItemSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUnit  AS CUnitC WITH(NOLOCK) ON CUnit.CompanySeq = CUnitC.CompanySeq AND CUnit.ItemSeq = CUnitC.ItemSeq AND CUnit.CUnitSeq = CUnitC.UnitSeq     
			LEFT OUTER JOIN  
				(  
					SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMFactType, ISNULL(B.MinorName, '') AS UMFactTypeName  
					FROM [JOIN].[DBO]._TDAItemUserDefine AS A WITH(NOLOCK)  
					LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor AS B WITH(NOLOCK)   
					ON A.CompanySeq = B.CompanySeq            
					AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000093     
					WHERE A.MngSerl = 1000027 --대표생산사업장  
				) AS Fact ON A.CompanySeq = Fact.CompanySeq  AND B.ItemSeq = Fact.ItemSeq                      
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemUnit_VW1 AS SUnit	with(nolock) ON A.CompanySeq = SUnit.CompanySeq 
																			AND B.ItemSeq = SUnit.ItemSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUnit		 AS SUnitC  WITH(NOLOCK) ON SUnit.CompanySeq = SUnitC.CompanySeq 
																			AND SUnit.ItemSeq = SUnitC.ItemSeq 
																			AND SUnit.SUnitSeq = SUnitC.UnitSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS BB WITH(NOLOCK)	ON BB.CompanySeq = A.CompanySeq AND BB.ItemSeq = B.ItemSeq AND BB.MngSerl = 1000037
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinorValue AS CC with(nolock) ON ( BB.MngValSeq = CC.MinorSeq and CC.Serl in (1000001) and CC.CompanySeq = 1)          
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS DD with(nolock) ON ( CC.ValueSeq = DD.MinorSeq and DD.CompanySeq = 1) -- 원료중분류
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS EE WITH(NOLOCK)	ON EE.CompanySeq = A.CompanySeq AND EE.ItemSeq = B.ItemSeq AND EE.MngSerl = 1000011 --제품란판란
			--LEFT OUTER JOIN _TDAUMinorValue AS F with(nolock) ON ( E.MngValSeq = F.MinorSeq and F.Serl in (1000001) and F.CompanySeq = @CompanySeq)          
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS GG with(nolock) ON ( EE.MngValSeq = GG.MinorSeq and GG.CompanySeq = 1) -- 원료중분류
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS RR WITH(NOLOCK) ON A.CompanySeq = RR.CompanySeq  
																					AND B.ItemSeq = RR.ItemSeq  
																					AND RR.MngSerl = 1000041 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS HH WITH(NOLOCK)	ON HH.CompanySeq = A.CompanySeq AND HH.ItemSeq = B.ItemSeq AND HH.MngSerl = 1000008 --품목그룹
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS II WITH(NOLOCK) ON ( HH.MngValSeq = II.MinorSeq and II.CompanySeq = 1) -- 품목그룹
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS JJ WITH(NOLOCK)	ON JJ.CompanySeq = A.CompanySeq AND JJ.ItemSeq = B.ItemSeq AND JJ.MngSerl = 1000035 --NB/PB
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS KK WITH(NOLOCK) ON ( JJ.MngValSeq = KK.MinorSeq and KK.CompanySeq = 1) -- NB/PB
			LEFT OUTER JOIN [JOIN].[DBO]._TCACompany  AS COM WITH(NOLOCK) ON COM.CompanySeq = A.CompanySeq
			LEFT OUTER JOIN #EggUnit     AS Egg ON B.CompanySeq = EGG.CompanySeq AND B.ItemSeq = EGG.ItemSeq
			LEFT OUTER JOIN (SELECT Distinct CompanySeq, ToSeq, FromSeq, ADD_DEL FROM [JOIN].[DBO]._TCOMSourceDaily
							 WHERE ToSeq = 4095061 AND ADD_DEL <> -1 AND ToSerl = 1
						 ) AS SS2 ON SS2.CompanySeq = A.CompanySeq AND SS2.ToSeq = A.InvoiceSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TSLOrder				AS OO2 WITH(NOLOCK) ON OO2.CompanySeq = SS2.CompanySeq AND OO2.OrderSeq = SS2.FromSeq
		WHERE A.InvoiceDate BETWEEN @FromYMD AND @ToYMD
	
	END
ELSE
BEGIN
IF @CompanySeq2 = 1			--조인
	BEGIN
		INSERT INTO #TMP_Result
		SELECT A.CompanySeq, COM.CompanyName CompanyName2, A.BizUnit, BIZ.BizUnitName, A.InvoiceDate
			, A.DeptSeq, ISNULL(DEPT.DeptName, '') DeptName, A.EmpSeq, ISNULL(EMP.EmpName, '') EmpName 
			, A.CustSeq, CUST.CustName 
			, CASE WHEN CANm.CustName IS NOT NULL THEN CAdd.MngValSeq ELSE A.CustSeq END AS CustSeq2					-- 실적집계거래처가 없다면 거래처로
			, CASE WHEN CANm.CustName IS NOT NULL THEN CANm.CustName ELSE CUST.CustName END AS CustName2				-- 실적집계거래처가 없다면 거래처로
			, ISNULL(CCls.UMCustClass, '') AS ChannelSeq     -- 거래처분류값 (유통구조) 코드 
			, (SELECT ISNULL(U.MinorName  , '') FROM [JOIN].[DBO]._TDAUMinor U WHERE U.CompanySeq = CCls.CompanySeq AND CCls.UMCustClass = U.MinorSeq) AS ChannelName   -- 유통구조 이름    
			, ISNULL(Fact.UMFactType, '') UMFactType, ISNULL(Fact.UMFactTypeName, '') UMFactTypeName   
			, I.ItemSeq, I.ItemName --품목명	   
			, V3.ItemClassSName  -- 소분류명
			, V3.ItemClassMName  -- 중분류명
			, V3.ItemClassLName  -- 대분류명
			, I.AssetSeq, Asset.AssetName 
			, SUnit.SUnitSeq AS UnitSeq, SUnit.SUnitName AS UnitName
			, B.Qty
			, I.UnitSeq AS STDUnitSeq, K.UnitName AS STDUnitName
			, B.STDQty 
			, CUnit.CUnitSeq, CUnit.CUnitName
			, ISNULL(CASE WHEN CUnit.CUnitSeq IS NULL OR CUnit.CUnitSeq = 0 OR ISNULL(CUnitC.ConvNum,0) = 0 THEN NULL 
				ELSE (B.STDQty * (CUnitC.ConvDen / CUnitC.ConvNum)) END, 0) AS CQty 
			, B.DomAmt  
			, B.DomVAT
			, B.DomAmt + B.DomVAT AS TotDomAmt
			, ISNULL(BB.MngValSeq, 0) AS RawClassMSeq
			, ISNULL(DD.MinorName, '') AS RawClassMName
			, EE.MngValSeq           AS ItemGubun
			, GG.MinorName          AS ItemGubunName	--20230602_khs
			, CASE WHEN CONVERT(INT, ISNULL(RR.MngValText, 0)) = 1 THEN 'TRUE' ELSE 'FALSE' END FreeAntibiotic  --무항생제유무
			, HH.MngValSeq AS ItemGroup
			, ISNULL(II.MinorName, '') AS ItemGroupName
			, JJ.MngValSeq AS NBPB
			, ISNULL(KK.MinorName, '') AS NBPBName
			, ISNULL(B.STDQty, 0) * ISNULL(EGG.ECalc, 0) AS EggQty --알단위 수량
			,ISNULL(OO2.OrderDate, '') AS OrderDateTo
		FROM [JOIN].[DBO]._TSLInvoice AS A WITH(NOLOCK)    
			JOIN [JOIN].[DBO]._TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.InvoiceSeq = A.InvoiceSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TDACust	  AS CUST WITH(NOLOCK) ON A.CompanySeq   = CUST.CompanySeq AND A.CustSeq   = CUST.CustSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDACustClass AS CCls WITH(NOLOCK) ON CUST.CompanySeq = CCls.CompanySeq AND CUST.CustSeq    = CCls.CustSeq AND CCls.UMajorCustClass = 8004   --유통구조 
			LEFT OUTER JOIN [JOIN].[DBO]._TDACustUserDefine	  AS CAdd WITH(NOLOCK) ON CUST.CompanySeq   = CAdd.CompanySeq AND CUST.CustSeq   = CAdd.CustSeq AND CAdd.MngSerl = '1000004'	-- 실적집계거래처
			LEFT OUTER JOIN [JOIN].[DBO]._TDACust	  AS CANm WITH(NOLOCK) ON CAdd.CompanySeq   = CANm.CompanySeq AND CAdd.MngValSeq   = CANm.CustSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItem      AS I WITH(NOLOCK) ON B.CompanySeq   = I.CompanySeq AND B.ItemSeq   = I.ItemSeq     
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemClass_VW1 AS V3 with(nolock) ON  B.ItemSeq = V3.ItemSeq and B.CompanySeq = V3.CompanySeq         
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUnit      AS J WITH(NOLOCK) ON B.CompanySeq   = J.CompanySeq AND B.UnitSeq   = J.UnitSeq                  
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUnit      AS K WITH(NOLOCK) ON I.CompanySeq   = K.CompanySeq AND I.UnitSeq   = K.UnitSeq    
			LEFT OUTER JOIN [JOIN].[DBO]._TDADept	  AS DEPT WITH(NOLOCK) ON A.CompanySeq = DEPT.CompanySeq AND A.DeptSeq   = DEPT.DeptSeq			
			LEFT OUTER JOIN [JOIN].[DBO]._TDAEmp		  AS EMP WITH(NOLOCK) ON A.CompanySeq = EMP.CompanySeq AND A.EmpSeq   = EMP.EmpSeq		
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemAsset AS Asset WITH (NOLOCK) ON I.CompanySeq = Asset.CompanySeq AND I.AssetSeq = Asset.AssetSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TDABizUnit	  AS BIZ with(nolock) ON  A.CompanySeq = BIZ.CompanySeq and A.BizUnit = BIZ.BizUnit
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemUnit_VW1 AS CUnit	with(nolock) ON  B.CompanySeq = CUnit.CompanySeq AND B.ItemSeq = CUnit.ItemSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUnit  AS CUnitC WITH(NOLOCK) ON CUnit.CompanySeq = CUnitC.CompanySeq AND CUnit.ItemSeq = CUnitC.ItemSeq AND CUnit.CUnitSeq = CUnitC.UnitSeq     
			LEFT OUTER JOIN  
				(  
					SELECT A.CompanySeq, A.ItemSeq, A.MngValSeq AS UMFactType, ISNULL(B.MinorName, '') AS UMFactTypeName  
					FROM [JOIN].[DBO]._TDAItemUserDefine AS A WITH(NOLOCK)  
					LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor AS B WITH(NOLOCK)   
					ON A.CompanySeq = B.CompanySeq            
					AND A.MngValSeq = B.MinorSeq AND B.MajorSeq = 2000093     
					WHERE A.MngSerl = 1000027 --대표생산사업장  
				) AS Fact ON A.CompanySeq = Fact.CompanySeq  AND B.ItemSeq = Fact.ItemSeq                      
			LEFT OUTER JOIN [JOIN].[DBO].join_TDAItemUnit_VW1 AS SUnit	with(nolock) ON A.CompanySeq = SUnit.CompanySeq 
																			AND B.ItemSeq = SUnit.ItemSeq 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUnit		 AS SUnitC  WITH(NOLOCK) ON SUnit.CompanySeq = SUnitC.CompanySeq 
																			AND SUnit.ItemSeq = SUnitC.ItemSeq 
																			AND SUnit.SUnitSeq = SUnitC.UnitSeq 
			JOIN  
				(  
					SELECT DISTINCT A.CompanySeq, B.ValueSeq
					FROM [JOIN].[DBO]._TDAUMinor A WITH(NOLOCK) 
					INNER JOIN [JOIN].[DBO]._TDAUMinorValue B WITH(NOLOCK) 
					ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.MinorSeq
					AND B.Serl = 1000001		--영업부서
					WHERE A.CompanySeq = 1
					AND A.MajorSeq = 2000097	--영업부서 
				) AS Sales ON A.CompanySeq = Sales.CompanySeq  AND A.DeptSeq = Sales.ValueSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS BB WITH(NOLOCK)	ON BB.CompanySeq = A.CompanySeq AND BB.ItemSeq = B.ItemSeq AND BB.MngSerl = 1000037
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinorValue AS CC with(nolock) ON ( BB.MngValSeq = CC.MinorSeq and CC.Serl in (1000001) and CC.CompanySeq = 1)          
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS DD with(nolock) ON ( CC.ValueSeq = DD.MinorSeq and DD.CompanySeq = 1) -- 원료중분류
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS EE WITH(NOLOCK)	ON EE.CompanySeq = A.CompanySeq AND EE.ItemSeq = B.ItemSeq AND EE.MngSerl = 1000011 --제품란판란
			--LEFT OUTER JOIN _TDAUMinorValue AS F with(nolock) ON ( E.MngValSeq = F.MinorSeq and F.Serl in (1000001) and F.CompanySeq = @CompanySeq)          
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS GG with(nolock) ON ( EE.MngValSeq = GG.MinorSeq and GG.CompanySeq = 1) -- 원료중분류
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS RR WITH(NOLOCK) ON A.CompanySeq = RR.CompanySeq  
																					AND B.ItemSeq = RR.ItemSeq  
																					AND RR.MngSerl = 1000041 
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS HH WITH(NOLOCK)	ON HH.CompanySeq = A.CompanySeq AND HH.ItemSeq = B.ItemSeq AND HH.MngSerl = 1000008 --품목그룹
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS II with(nolock) ON ( HH.MngValSeq = II.MinorSeq and II.CompanySeq = 1) -- 품목그룹
			LEFT OUTER JOIN [JOIN].[DBO]._TDAItemUserDefine    AS JJ WITH(NOLOCK)	ON JJ.CompanySeq = A.CompanySeq AND JJ.ItemSeq = B.ItemSeq AND JJ.MngSerl = 1000035 --NB/PB
			LEFT OUTER JOIN [JOIN].[DBO]._TDAUMinor  AS KK with(nolock) ON ( JJ.MngValSeq = KK.MinorSeq and KK.CompanySeq = 1) -- NB/PB
			LEFT OUTER JOIN [JOIN].[DBO]._TCACompany  AS COM WITH(NOLOCK) ON COM.CompanySeq = A.CompanySeq
			LEFT OUTER JOIN #EggUnit     AS Egg ON B.CompanySeq = EGG.CompanySeq AND B.ItemSeq = EGG.ItemSeq
			LEFT OUTER JOIN (SELECT Distinct CompanySeq, ToSeq, FromSeq, ADD_DEL FROM [JOIN].[DBO]._TCOMSourceDaily
							 WHERE ToSeq = 4095061 AND ADD_DEL <> -1 AND ToSerl = 1
						 ) AS SS2 ON SS2.CompanySeq = A.CompanySeq AND SS2.ToSeq = A.InvoiceSeq
			LEFT OUTER JOIN [JOIN].[DBO]._TSLOrder				AS OO2 WITH(NOLOCK) ON OO2.CompanySeq = SS2.CompanySeq AND OO2.OrderSeq = SS2.FromSeq
		WHERE A.InvoiceDate BETWEEN @FromYMD AND @ToYMD
	
	END
END

--select * from #TMP_Result
--where CompanySeq = 1 and CustSeq2 = 6475 and ItemSeq = 11368 

SELECT A.CompanySeq AS CompanySeq2, CompanyName2, BizUnit, BizUnitName, DeptSeq, DeptName, EmpSeq, EmpName
	   , CustSeq2, CustName2
	   , UMFactType, UMFactTypeName
	   , A.ItemSeq, ItemName	   
	   , ItemClassSName
       , ItemClassMName
       , ItemClassLName
	   , AssetSeq, AssetName
	   , UnitSeq, UnitName
	   , STDUnitSeq, STDUnitName
	   , CUnitSeq, CUnitName
	   , RawClassMSeq
	   , RawClassMName
	   , ItemGubun
	   , ItemGubunName
	   , FreeAntibiotic
	   , ItemGroup
	   , ItemGroupName
       , NBPB
	   , NBPBName
	   , SUM(CQty) AS CQty
	   , SUM(DomAmt) AS DomAmt
	   , ROUND(CASE WHEN SUM(CQty) <> 0 AND SUM(DomAmt) <> 0 THEN SUM(DomAmt) /  SUM(CQty) ELSE 0 END, 2) CPrc
	   , SUM(EggQty) AS EggQty
	   , ISNULL(MAX(E.Qty), 0) AS EQty
FROM #TMP_Result A
	--LEFT OUTER JOIN join_TDACompany2_VW1 AS VW1 ON A.CompanySeq  = VW1.CompanySeq
	LEFT OUTER JOIN #join_TSLPromotionItem AS E ON E.CompanySeq = A.CompanySeq AND E.CustSeq = A.CustSeq2 AND E.ItemSeq = A.ItemSeq-- AND E.PromoDate = A.OrderDateTo
WHERE (@CompanySeq2   = 0 OR A.CompanySeq    = @CompanySeq2)    
	--AND InvoiceDate BETWEEN @FromYMD AND @ToYMD
	AND (@BizUnitName   = '' OR BizUnitName  LIKE @BizUnitName + '%')  
	AND (@DeptName   = '' OR DeptName  LIKE @DeptName + '%')  
	AND (@EmpName   = '' OR EmpName  LIKE @EmpName + '%')  
	AND (@CustName2   = '' OR CustName2  LIKE @CustName2 + '%')  
	AND (@UMFactTypeName   = '' OR UMFactTypeName  LIKE @UMFactTypeName + '%')  
	AND (@ItemName   = '' OR ItemName  LIKE @ItemName + '%')                   
	AND (@ItemClassLName   = '' OR ItemClassLName  LIKE @ItemClassLName + '%')  
	AND (@ItemClassMName   = '' OR ItemClassMName  LIKE @ItemClassMName + '%')  
	AND (@ItemClassSName   = '' OR ItemClassSName  LIKE @ItemClassSName + '%')  
	AND (@AssetSeq    = 0 OR AssetSeq    = @AssetSeq)     
	--AND DeptSeq IN (SELECT DeptSeq FROM #Dept)
GROUP BY A.CompanySeq, CompanyName2, BizUnit, BizUnitName, DeptSeq, DeptName, EmpSeq, EmpName
	   , CustSeq2, CustName2
	   , UMFactType, UMFactTypeName
	   , A.ItemSeq, ItemName	   
	   , ItemClassSName
       , ItemClassMName
       , ItemClassLName
	   , AssetSeq, AssetName
	   , UnitSeq, UnitName
	   , STDUnitSeq, STDUnitName
	   , CUnitSeq, CUnitName
	   , RawClassMSeq
	   , RawClassMName
	   , ItemGubun
	   , ItemGubunName
	   , FreeAntibiotic
	   , ItemGroup
	   , ItemGroupName
       , NBPB
	   , NBPBName



RETURN
