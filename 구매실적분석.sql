/* ���� �ð� ���� ON 
SET STATISTICS TIME ON
SET STATISTICS IO ON

** ���ʽ���� 1:30 ~ 3:00
** 2��������� 10���̳�
** ������ Ȯ�� �� ���� ���� �� Ʃ�� �ʿ� 
** �ӽ����̺� �ε��� Ȯ�� �ʿ�

*/ 

       SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

   DECLARE @StdYM   VARCHAR(6)
   DECLARE @VsStdYM VARCHAR(6)
      
       SET @StdYM   = '202401'
       SET @VsStdYM = '202301'  -- �񱳿��� / ��� ��� ���� RowData �������� �߰�����
  
  /*============================================================== 
      �迭�纰 ���Ŵ�� ����ǰ�� ����Ʈ ����
  ==============================================================*/

   IF OBJECT_ID('tempdb..#DelvInItemClassList')	IS NOT NULL DROP TABLE #DelvInItemClassList

   CREATE TABLE #DelvInItemClassList -- �迭�纰 ��� ǰ�� ����Ʈ
   (
       CompanySeq  INT 
     , CompanyName NVARCHAR(30) 
	 , ItemSeq     INT
	 , ItemName    NVARCHAR(200) 
	 , ItemMGName  NVARCHAR(50)  -- ����׷�
	 , ItemMLName  NVARCHAR(50)  -- �����з�
	 , ItemMMName  NVARCHAR(50)  -- �����ߺз�
	 , ItemMSName  NVARCHAR(50)  -- ����Һз�
	 , ItemGEName  NVARCHAR(50)  -- ���(�Ϲ�/����/��Ÿ)
   ) 
   
   INSERT INTO #DelvInItemClassList
   SELECT CompanySeq, CompanyName, ItemSeq   , ItemName 
        , ItemMGName, ItemMLName , ItemMMName, ItemMSName
		, ItemGEName
     FROM [JOIN_DC].[DBO].joinbio_ItemClassList WITH(NOLOCK)
	WHERE CompanySeq IN (1, 3, 4)                                                    -- ����:1 / �˷���:3 / ����:4 �� ��ȸ
	  AND AssetName IN ('��ǰ', '������')
	  AND (ItemLName = '����' or ItemMName = '����' or ItemLName = 'û��')           -- ǰ���з� or �ߺз����� ����+û��(�̸�Ʈ ����)�� �˻�
	  AND ItemSeq NOT IN ( CASE WHEN (ItemMSSeq = 0 AND ItemName NOT LIKE '%��Ư%') 
	                            THEN ItemSeq ELSE 0 END )                            -- ������Ī �ȵǾ��ִ� ǰ�� �� ��Ư���� ����
	  AND ItemTMName NOT IN ('��ǰ��')                                               -- ���ձ����ߺз��� ��ǰ�� ���� 
	  AND ITemName NOT LIKE '%��ǰ%'                                                 -- ǰ�� ��ǰ�� �پ��ִ� ǰ�� ����  
	  AND PatIndex('%[0-9]%', ItemName) = 0                                          -- ǰ�� ���� ���� ex) �̸�Ʈ �Ͼ� �����(30��/���)-�Ƕ� 
	                                                                                 -- PatIndex > ���ڿ� ��ġ ã�� ������ 0

  /*============================================================== 
      �迭�纰 �ŷ�ó����
	  ****** ��Ź �ŷ�ó ERP ������Ʈ �ʿ�
  ==============================================================*/

   IF OBJECT_ID('tempdb..#DelvInCustClassList')	 IS NOT NULL DROP TABLE #DelvInCustClassList

   CREATE TABLE #DelvInCustClassList -- �迭�纰 ��� ǰ�� ����Ʈ
   (
       CompanySeq  INT 
     , CompanyName NVARCHAR(30) 
	 , CustSeq     INT
	 , CustName    NVARCHAR(200) 
	 , CustGubun   NVARCHAR(30)    
	 , CustType    NVARCHAR(30)   -- �ŷ�ó����(�ܺ�, ����, ��Ź)
   ) 
   

   INSERT INTO #DelvInCustClassList
   SELECT CompanySeq    
        , CompanyName   
	    , CustSeq       
	    , CustName      
	    , CustGubun     
		, CASE WHEN CustGubun = '�ܺΰŷ�ó' or ISNULL(CustGubun, '') = '' THEN '�ܺ�'   
		       WHEN CustGubun = '��Ź'                                     THEN '��Ź'
			   ELSE '����'    END AS CustType
     FROM [JOIN_DC].[DBO].joinbio_CustClassList WITH(NOLOCK)              
	WHERE CompanySeq IN (1, 3, 4)                                                    -- ����:1 / �˷���:3 / ����:4 �� ��ȸ

  /*============================================================== 
  -- ���� ��ȸ ������ ���� �� �̽� ������ 1-3 ���� ����
  ==============================================================*/


  /*============================================================== 
      �迭�纰 ���� ���� ���� ����
	  1. ���� ���ų���(�̻����)
  ==============================================================*/

   SELECT A.CompanyName
        , @StdYM AS DelvInYM
        , A.ItemMGName
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , B.FactUnitName
		, C.CustType
		, SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) AS RealQty
     FROM #DelvInItemClassList                     AS A
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TPUDelvInItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 1
						  AND DelvInYM          = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo

	                 )                             AS B   ON A.CompanySeq        = B.CompanySeq AND A.ItemSeq = B.ItemSeq 

	 LEFT JOIN #DelvInCustClassList                AS C   ON B.CompanySeq        = C.CompanySeq AND B.CustSeq = C.CustSeq 
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TSLSalesItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 1
						  AND SalesYM           = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, ItemSeq, LotNo

	                 )                              AS D  ON A.CompanySeq        = D.CompanySeq AND A.ItemSeq = D.ItemSeq 
														 AND B.LOTNo             = D.LOTNo  -- LOTNo ��Ī(����-�Ǹ�)
    WHERE 1=1
	  AND A.CompanySeq = 1
	  AND B.FactUnitName = '������������'
	  AND A.ItemName NOT LIKE '%�ֶ�%'
	  AND A.ItemMLName  NOT IN( '' , '��Ÿ��')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   , C.CustName 
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0



  /*============================================================== 
      �迭�纰 ���� ���� ���� ����
	  2. �˷��� ���ų���(�̻����)
  ==============================================================*/

   SELECT A.CompanyName
        , @StdYM AS DelvInYM
        , A.ItemMGName
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , B.FactUnitName
		, C.CustType
		, SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) AS RealQty
     FROM #DelvInItemClassList                     AS A
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TPUDelvInItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 3
						  AND DelvInYM          = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo

	                 )                             AS B   ON A.CompanySeq        = B.CompanySeq AND A.ItemSeq = B.ItemSeq 

	 LEFT JOIN #DelvInCustClassList                AS C   ON B.CompanySeq        = C.CompanySeq AND B.CustSeq = C.CustSeq 
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TSLSalesItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 3
						  AND SalesYM           = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, ItemSeq, LotNo

	                 )                              AS D  ON A.CompanySeq        = D.CompanySeq AND A.ItemSeq = D.ItemSeq 
														 AND B.LOTNo             = D.LOTNo  -- LOTNo ��Ī(����-�Ǹ�)
    WHERE 1=1
	  AND A.CompanySeq = 3
	  AND B.FactUnitName = '�缺GP��������'
	  AND A.ItemName NOT LIKE '%�ֶ�%'
	  AND A.ItemMLName  NOT IN( '' , '��Ÿ��')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   , C.CustName 
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0




  /*============================================================== 
      �迭�纰 ���� ���� ���� ����
	  3. ���� ���ų���
	  ***** ������ ��� ���� Ȯ�� �ʿ�
  ==============================================================*/

   SELECT A.CompanyName
        , @StdYM AS DelvInYM
        , A.ItemMGName
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , B.FactUnitName
		, C.CustType
		, SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) AS RealQty
     FROM #DelvInItemClassList                     AS A
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TPUDelvInItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 4
						  AND DelvInYM          = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo

	                 )                             AS B   ON A.CompanySeq        = B.CompanySeq AND A.ItemSeq = B.ItemSeq 

	 LEFT JOIN #DelvInCustClassList                AS C   ON B.CompanySeq        = C.CompanySeq AND B.CustSeq = C.CustSeq 
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM [JOIN_DC].[DBO].joinbio_TSLSalesItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 4
						  AND SalesYM           = @StdYM
						  AND ISNULL(LOTNo, '') <> ''
                        GROUP BY CompanySeq, ItemSeq, LotNo

	                 )                              AS D  ON A.CompanySeq        = D.CompanySeq AND A.ItemSeq = D.ItemSeq 
														 AND B.LOTNo             = D.LOTNo  -- LOTNo ��Ī(����-�Ǹ�)
    WHERE 1=1
	  AND A.CompanySeq = 4
	  AND B.FactUnitName = '�ȼ�����'
	  AND A.ItemName NOT LIKE '%�ֶ�%'
	  AND A.ItemMLName  NOT IN( '' , '��Ÿ��')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0



/*==============================================================================
-- LotNo ���� ���� or ��Ư / ���� ���
==============================================================================*/

   SELECT A.ItemName , B.FactUnitName
		, C.CustType
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , SUM(B.Qty) AS Qty     -- �����԰����
        , SUM(D.Qty) AS Qty     -- �Ǹż���
        , SUM(B.Qty - D.Qty) AS Qty
     FROM #DelvInItemClassList      AS A
     LEFT OUTER JOIN (
	                  SELECT CompanySeq, FactUnitName, ItemSeq, DelvInYM, CustSeq, Qty
				        FROM [JOIN_DC].[DBO].joinbio_TPUDelvInItem_Group  
					   WHERE CompanySeq = 1
                         AND DelvInYM = @StdYM
	 
	                 ) AS B ON A.CompanySeq = b.CompanySeq AND A.ItemSeq = B.ItemSeq
	 LEFT JOIN #DelvInCustClassList               AS C ON B.CompanySeq = C.CompanySeq AND B.CustSeq = C.CustSeq 
     LEFT OUTER JOIN  (
	                  SELECT CompanySeq, ItemSeq, InvoiceYM, Qty
				        FROM [JOIN_DC].[DBO].joinbio_TSLInvoiceItem_Group  
					   WHERE CompanySeq = 1
                         AND InvoiceYM  = @StdYM
	 
	                 ) AS D ON A.CompanySeq = D.CompanySeq AND A.ItemSeq  =D.ItemSeq

    WHERE 1=1 
	  AND A.CompanySeq = 1
	  AND (ItemMLName  = '' or ItemMLName  = '��Ÿ��' )
    GROUP BY A.ItemName , B.FactUnitName
           --, C.CustName 
		   , C.CustType
           , A.ItemMLName
           , A.ItemMMName
           , A.ItemMSName
    HAVING SUM(B.Qty) is not null
	   AND SUM(D.Qty) is not null

/*


		   */


/* ���� �ð� ���� OFF 
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
*/




/*------------------------------��������----------------------------------*/




/*  �ӽ� ������1

   SELECT A.ItemName , B.FactUnitName
        --, C.CustName 
		, C.CustType
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , SUM(B.Qty) AS Qty
     FROM #DelvInItemClassList      AS A
     LEFT OUTER JOIN joinbio_TPUDelvInItem_Group  AS B ON A.CompanySeq = b.CompanySeq AND A.ItemSeq = B.ItemSeq
	 LEFT JOIN #DelvInCustClassList               AS C ON B.CompanySeq = C.CompanySeq AND B.CustSeq = C.CustSeq 
	
    WHERE DelvInYM = @StdYM
	  AND A.CompanySeq = @CompanySeq
	  AND (ItemMLName  = '' or ItemMLName  = '��Ÿ��' )
    GROUP BY A.ItemName , B.FactUnitName
           --, C.CustName 
		   , C.CustType
           , A.ItemMLName
           , A.ItemMMName
           , A.ItemMSName

   SELECT A.ItemName , B.FactUnitName
        --, C.CustName 
		, C.CustType
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , SUM(B.Qty) AS Qty
     FROM #DelvInItemClassList      AS A
     LEFT OUTER JOIN  joinbio_TSLInvoiceItem_Group AS B ON A.CompanySeq = b.CompanySeq AND A.ItemSeq  =B.ItemSeq
	 LEFT JOIN #DelvInCustClassList                AS C   ON B.CompanySeq        = C.CompanySeq AND B.CustSeq = C.CustSeq 

    WHERE InvoiceYM = @StdYM
	  AND A.CompanySeq = @CompanySeq
	  AND (ItemMLName  = '' or ItemMLName  = '��Ÿ��' )
    GROUP BY A.ItemName , B.FactUnitName
           --, C.CustName 
		   , C.CustType
           , A.ItemMLName
           , A.ItemMMName
           , A.ItemMSName
*/

/*  �ӽ� ������2

   SELECT A.CompanyName
        , @StdYM AS DelvInYM
        , A.ItemMGName
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , A.ItemName
        , B.FactUnitName
		, C.CustType
		, C.CustName 
		, B.LOTNo
		, SUM(ISNULL(B.Qty, 0))
		, SUM(ISNULL(D.Qty, 0))
		, SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) AS RealQty
		--, *
     FROM #DelvInItemClassList                     AS A
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM joinbio_TPUDelvInItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 1
						  AND DelvInYM          = @StdYM
						  AND ISNULL(LOTNo, '') = ''
                        GROUP BY CompanySeq, FactUnitName, CustSeq, ItemSeq, LotNo

	                 )                             AS B   ON A.CompanySeq        = B.CompanySeq AND A.ItemSeq = B.ItemSeq 

	 LEFT JOIN #DelvInCustClassList                AS C   ON B.CompanySeq        = C.CompanySeq AND B.CustSeq = C.CustSeq 
	 LEFT OUTER JOIN (
	                   SELECT CompanySeq, ItemSeq, LotNo, SUM(Qty) AS Qty
					     FROM joinbio_TSLSalesItem_Group WITH(NOLOCK)
						WHERE CompanySeq        = 1
						  AND SalesYM           = @StdYM
						  AND ISNULL(LOTNo, '') = ''
                        GROUP BY CompanySeq, ItemSeq, LotNo

	                 )                              AS D  ON A.CompanySeq        = D.CompanySeq AND A.ItemSeq = D.ItemSeq 
														
    WHERE 1=1
	  AND A.CompanySeq = 1
	  AND B.FactUnitName = '������������'
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName    , A.ItemName
           , A.ItemMSName , B.FactUnitName  , B.LOTNo
		   , C.CustType   , C.CustName 

*/