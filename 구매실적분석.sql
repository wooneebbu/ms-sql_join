/* 쿼리 시간 측정 ON 
SET STATISTICS TIME ON
SET STATISTICS IO ON

** 최초실행시 1:30 ~ 3:00
** 2차실행부터 10초이내
** 데이터 확인 후 쿼리 통합 및 튜닝 필요 
** 임시테이블 인덱스 확인 필요

*/ 

       SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

   DECLARE @StdYM   VARCHAR(6)
   DECLARE @VsStdYM VARCHAR(6)
      
       SET @StdYM   = '202401'
       SET @VsStdYM = '202301'  -- 비교연월 / 당월 계산 이후 RowData 단위에서 추가예정
  
  /*============================================================== 
      계열사별 구매대상 원란품목 리스트 생성
  ==============================================================*/

   IF OBJECT_ID('tempdb..#DelvInItemClassList')	IS NOT NULL DROP TABLE #DelvInItemClassList

   CREATE TABLE #DelvInItemClassList -- 계열사별 대상 품목 리스트
   (
       CompanySeq  INT 
     , CompanyName NVARCHAR(30) 
	 , ItemSeq     INT
	 , ItemName    NVARCHAR(200) 
	 , ItemMGName  NVARCHAR(50)  -- 원료그룹
	 , ItemMLName  NVARCHAR(50)  -- 원료대분류
	 , ItemMMName  NVARCHAR(50)  -- 원료중분류
	 , ItemMSName  NVARCHAR(50)  -- 원료소분류
	 , ItemGEName  NVARCHAR(50)  -- 등급(일반/유정/기타)
   ) 
   
   INSERT INTO #DelvInItemClassList
   SELECT CompanySeq, CompanyName, ItemSeq   , ItemName 
        , ItemMGName, ItemMLName , ItemMMName, ItemMSName
		, ItemGEName
     FROM [JOIN_DC].[DBO].joinbio_ItemClassList WITH(NOLOCK)
	WHERE CompanySeq IN (1, 3, 4)                                                    -- 조인:1 / 알로팜:3 / 세양:4 만 조회
	  AND AssetName IN ('상품', '원자재')
	  AND (ItemLName = '생란' or ItemMName = '생란' or ItemLName = '청란')           -- 품목대분류 or 중분류에서 생란+청란(이마트 전용)만 검색
	  AND ItemSeq NOT IN ( CASE WHEN (ItemMSSeq = 0 AND ItemName NOT LIKE '%무특%') 
	                            THEN ItemSeq ELSE 0 END )                            -- 원란매칭 안되어있는 품목 중 무특제외 제거
	  AND ItemTMName NOT IN ('제품란')                                               -- 통합구분중분류로 제품란 제거 
	  AND ITemName NOT LIKE '%상품%'                                                 -- 품명에 상품이 붙어있는 품목 제거  
	  AND PatIndex('%[0-9]%', ItemName) = 0                                          -- 품명에 숫자 제거 ex) 이마트 하얀 백색란(30구/대란)-판란 
	                                                                                 -- PatIndex > 문자열 위치 찾기 없으면 0

  /*============================================================== 
      계열사별 거래처구분
	  ****** 위탁 거래처 ERP 업데이트 필요
  ==============================================================*/

   IF OBJECT_ID('tempdb..#DelvInCustClassList')	 IS NOT NULL DROP TABLE #DelvInCustClassList

   CREATE TABLE #DelvInCustClassList -- 계열사별 대상 품목 리스트
   (
       CompanySeq  INT 
     , CompanyName NVARCHAR(30) 
	 , CustSeq     INT
	 , CustName    NVARCHAR(200) 
	 , CustGubun   NVARCHAR(30)    
	 , CustType    NVARCHAR(30)   -- 거래처구분(외부, 내부, 위탁)
   ) 
   

   INSERT INTO #DelvInCustClassList
   SELECT CompanySeq    
        , CompanyName   
	    , CustSeq       
	    , CustName      
	    , CustGubun     
		, CASE WHEN CustGubun = '외부거래처' or ISNULL(CustGubun, '') = '' THEN '외부'   
		       WHEN CustGubun = '위탁'                                     THEN '위탁'
			   ELSE '내부'    END AS CustType
     FROM [JOIN_DC].[DBO].joinbio_CustClassList WITH(NOLOCK)              
	WHERE CompanySeq IN (1, 3, 4)                                                    -- 조인:1 / 알로팜:3 / 세양:4 만 조회

  /*============================================================== 
  -- 분할 조회 데이터 검증 후 이슈 없으면 1-3 통합 예정
  ==============================================================*/


  /*============================================================== 
      계열사별 원란 구매 내역 집계
	  1. 성본 구매내역(이상없음)
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
														 AND B.LOTNo             = D.LOTNo  -- LOTNo 매칭(구매-판매)
    WHERE 1=1
	  AND A.CompanySeq = 1
	  AND B.FactUnitName = '성본생산사업장'
	  AND A.ItemName NOT LIKE '%쌍란%'
	  AND A.ItemMLName  NOT IN( '' , '기타란')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   , C.CustName 
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0



  /*============================================================== 
      계열사별 원란 구매 내역 집계
	  2. 알로팜 구매내역(이상없음)
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
														 AND B.LOTNo             = D.LOTNo  -- LOTNo 매칭(구매-판매)
    WHERE 1=1
	  AND A.CompanySeq = 3
	  AND B.FactUnitName = '양성GP생산사업장'
	  AND A.ItemName NOT LIKE '%쌍란%'
	  AND A.ItemMLName  NOT IN( '' , '기타란')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   , C.CustName 
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0




  /*============================================================== 
      계열사별 원란 구매 내역 집계
	  3. 세양 구매내역
	  ***** 선별란 사용 내역 확인 필요
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
														 AND B.LOTNo             = D.LOTNo  -- LOTNo 매칭(구매-판매)
    WHERE 1=1
	  AND A.CompanySeq = 4
	  AND B.FactUnitName = '안성공장'
	  AND A.ItemName NOT LIKE '%쌍란%'
	  AND A.ItemMLName  NOT IN( '' , '기타란')
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName
           , A.ItemMSName , B.FactUnitName
		   , C.CustType   
	HAVING SUM(ISNULL(B.Qty, 0) - ISNULL(D.Qty, 0)) > 0



/*==============================================================================
-- LotNo 없는 직납 or 무특 / 음성 계산
==============================================================================*/

   SELECT A.ItemName , B.FactUnitName
		, C.CustType
        , A.ItemMLName
        , A.ItemMMName
        , A.ItemMSName
        , SUM(B.Qty) AS Qty     -- 구매입고수량
        , SUM(D.Qty) AS Qty     -- 판매수량
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
	  AND (ItemMLName  = '' or ItemMLName  = '기타란' )
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


/* 쿼리 시간 측정 OFF 
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
*/




/*------------------------------삭제예정----------------------------------*/




/*  임시 보관용1

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
	  AND (ItemMLName  = '' or ItemMLName  = '기타란' )
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
	  AND (ItemMLName  = '' or ItemMLName  = '기타란' )
    GROUP BY A.ItemName , B.FactUnitName
           --, C.CustName 
		   , C.CustType
           , A.ItemMLName
           , A.ItemMMName
           , A.ItemMSName
*/

/*  임시 보관용2

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
	  AND B.FactUnitName = '성본생산사업장'
    GROUP BY A.CompanyName, A.ItemMGName
           , A.ItemMLName , A.ItemMMName    , A.ItemName
           , A.ItemMSName , B.FactUnitName  , B.LOTNo
		   , C.CustType   , C.CustName 

*/