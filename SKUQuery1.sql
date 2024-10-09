--알단위 환산(조인)
-- INSERT INTO #EggUnit ( CompanySeq, ItemSeq, EUnitSeq, EUnitName, ECalc )
SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 1   --알

SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 2   --EA

SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 3   --팩

SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 5   --KG



SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc, EGG.ConvDen, EGG.ConvNum 
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.ConvNum <> 1  --알
  AND EGG.UnitSeq = 5



	
DECLARE	  @StdYM		NVARCHAR(6)
		, @BFStdYM      NVARCHAR(6)


 SET   @StdYM = '202407'
 SET   @BFStdYM = ((CONVERT(INT,@StdYM)) - 1) 


-- SELECT @StdYM, @BFStdYM


SELECT *
  FROM _TSLInvoice
 WHERE LEFT(InvoiceDate, 6) BETWEEN @BFStdYM AND @StdYM


SELECT *
  FROM _TSLInvoiceSum
 WHERE SalesYM BETWEEN @BFStdYM AND @StdYM


 -- =================
 -- 임시테이블 생성
 -- =================



 CREATE TABLE #SKU_Base (
						     CompanySeq          INT			
						   , InvoiceDate		 NVARCHAR(8)		 -- 세금계산서 날짜
						   , DeptSeq			 INT				 -- 부서Seq
						   , DeptName			 NVARCHAR(100)		 -- 부서
						   , EmpSeq				 INT				 -- 사원seq	
						   , EmpName			 NVARCHAR(100)		 -- 사원
						   , ItemSeq		     INT				 -- 제품Seq
						   , ItemName	    	 NVARCHAR(200)		 -- 제품
						   , ItemClasSSName 	 NVARCHAR(200)		 -- 품목 소분류
						   , ItemClasSMName 	 NVARCHAR(200)		 -- 품목 중분류
						   , ItemClasSLName 	 NVARCHAR(200)		 -- 품목 대분류
						   , AssetSeq			 INT				 -- 제품/상품/반제품Seq
						   , AssetName			 NVARCHAR(50)		 -- 제품/상품/반제품 
						   , UnitSeq			 INT		
						   , Unit				 NVARCHAR(50)								
						   , Qty				 DECIMAL (19, 5)
						   , STDUnitSeq		     INT				 -- 기준단위Seq
						   , STDUnitName	     NVARCHAR(200)		 -- 기준단위
						   , STDQty              DECIMAL(19,5)		 -- 기준단위수량
						   ,  CUnitSeq		     INT				 -- 계산단위Seq
						   ,  CUnitName	         NVARCHAR(200)		 -- 계산단위
						   ,  CQty               DECIMAL(19,5)		 -- 계산단위수량
						   ,  DomAmt             DECIMAL(19,5)		-- 단가
						   ,  DomVAT             DECIMAL(19,5)      -- 세
						   ,  TotDomAmt          DECIMAL(19,5)	    -- 총단가
						   ,  RawClassMSeq       INT				-- 품목명 (갈생왕란, 백색특대)
						   ,  RawClassMName	     NVARCHAR(200)		
						   ,  ItemGubun	         INT				-- 제품란/ 탈각ㅔ추리/판란
						   ,  ItemGubunName	     NVARCHAR(200)
						   ,  ItemGroup	         INT				 -- 메추리 /왕/특/대중소
						   ,  ItemGroupName	     NVARCHAR(200)
			)