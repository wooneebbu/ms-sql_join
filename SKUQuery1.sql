--�˴��� ȯ��(����)
-- INSERT INTO #EggUnit ( CompanySeq, ItemSeq, EUnitSeq, EUnitName, ECalc )
SELECT EGG.CompanySeq, ItemSeq, EGG.UnitSeq AS EUnitSeq, C.UnitName AS EUnitName
, CASE WHEN EGG.ConvNum <> 0 THEN EGG.ConvDen / EGG.ConvNum ELSE 0 END ECalc
FROM [JOIN].[DBO]._TDAItemUnit AS EGG WITH(NOLOCK)
INNER JOIN [JOIN].[DBO]._TDAUnit  AS C WITH(NOLOCK) 
ON EGG.CompanySeq  = C.CompanySeq  AND EGG.UnitSeq    = C.UnitSeq      
WHERE EGG.UnitSeq = 1   --��

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
WHERE EGG.UnitSeq = 3   --��

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
WHERE EGG.ConvNum <> 1  --��
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
 -- �ӽ����̺� ����
 -- =================



 CREATE TABLE #SKU_Base (
						     CompanySeq          INT			
						   , InvoiceDate		 NVARCHAR(8)		 -- ���ݰ�꼭 ��¥
						   , DeptSeq			 INT				 -- �μ�Seq
						   , DeptName			 NVARCHAR(100)		 -- �μ�
						   , EmpSeq				 INT				 -- ���seq	
						   , EmpName			 NVARCHAR(100)		 -- ���
						   , ItemSeq		     INT				 -- ��ǰSeq
						   , ItemName	    	 NVARCHAR(200)		 -- ��ǰ
						   , ItemClasSSName 	 NVARCHAR(200)		 -- ǰ�� �Һз�
						   , ItemClasSMName 	 NVARCHAR(200)		 -- ǰ�� �ߺз�
						   , ItemClasSLName 	 NVARCHAR(200)		 -- ǰ�� ��з�
						   , AssetSeq			 INT				 -- ��ǰ/��ǰ/����ǰSeq
						   , AssetName			 NVARCHAR(50)		 -- ��ǰ/��ǰ/����ǰ 
						   , UnitSeq			 INT		
						   , Unit				 NVARCHAR(50)								
						   , Qty				 DECIMAL (19, 5)
						   , STDUnitSeq		     INT				 -- ���ش���Seq
						   , STDUnitName	     NVARCHAR(200)		 -- ���ش���
						   , STDQty              DECIMAL(19,5)		 -- ���ش�������
						   ,  CUnitSeq		     INT				 -- ������Seq
						   ,  CUnitName	         NVARCHAR(200)		 -- ������
						   ,  CQty               DECIMAL(19,5)		 -- ����������
						   ,  DomAmt             DECIMAL(19,5)		-- �ܰ�
						   ,  DomVAT             DECIMAL(19,5)      -- ��
						   ,  TotDomAmt          DECIMAL(19,5)	    -- �Ѵܰ�
						   ,  RawClassMSeq       INT				-- ǰ��� (�����ն�, ���Ư��)
						   ,  RawClassMName	     NVARCHAR(200)		
						   ,  ItemGubun	         INT				-- ��ǰ��/ Ż�����߸�/�Ƕ�
						   ,  ItemGubunName	     NVARCHAR(200)
						   ,  ItemGroup	         INT				 -- ���߸� /��/Ư/���߼�
						   ,  ItemGroupName	     NVARCHAR(200)
			)