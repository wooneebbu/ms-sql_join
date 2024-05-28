USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationMakeQuery]    Script Date: 2023-10-27 오후 3:30:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션생성_조회
    작 성 일 - 2023.10.23
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationMakeQuery]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          


--================================================
-- 사용변수 선언 & 조회조건 DATABLOCK에서 가져오기
--================================================

DECLARE		@STDYM			VARCHAR(8)
		,	@EggWeightSeq	INT
 SELECT		@STDYM			= ISNULL(STDYM,		  '')
		,	@EggWeightSeq	= ISNULL(EggWeightSeq, 0)
   FROM #BIZ_IN_DataBlock1 -- 조회조건 가져오는곳 

DECLARE		@NextYM			VARCHAR(6)
	SET		@NextYM			= REPLACE(CONVERT(VARCHAR(7), DATEADD(MONTH, 1, @STDYM + '01'), 120), '-', '') -- 다음달

--========================
 --TEMP TABLE 사전 정리
--========================

  IF OBJECT_ID('tempdb..#Title')		IS NOT NULL DROP TABLE #Title
  IF OBJECT_ID('tempdb..#FixTable')		IS NOT NULL DROP TABLE #FixTable
  IF OBJECT_ID('tempdb..#DataTable')	IS NOT NULL DROP TABLE #DataTable



--==========================
--TEMP TABLE 구성
--==========================

CREATE TABLE #Title 
(
	  ColIDX		INT IDENTITY (0, 1)  NOT NULL -- 자동 인덱스 구성 
	, Title			NVARCHAR(30)         NOT NULL
	, TitleSeq		NVARCHAR(8)	     NOT NULL
)



CREATE TABLE #FixTable
(
	  RowIDX		INT IDENTITY (0, 1)      NOT NULL  -- 자동인덱스 구성 // 조회에 둘다 들어감 col, row
	, CompanySeq	INT				 NOT NULL
	, InCompany		NVARCHAR(8) 		 NOT NULL
	, CustSeq		INT			 NOT NULL
	, CustName		NVARCHAR(20) 		 NOT NULL
	, EggGradeSeq	INT				 NOT NULL
	, EggGrade		NVARCHAR(30) 		 NOT NULL
	, EggTypeSeq	INT				 NOT NULL
	, EggType		NVARCHAR(30) 		 NOT NULL
	, EggMTypeSeq	INT				 NOT NULL
	, EggMType		NVARCHAR(30) 		 NOT NULL
	, EggWeightSeq	INT				 NOT NULL
	, EggWeight		NVARCHAR(30) 		 NOT NULL
	, MaxWeek		NVARCHAR(20)		 NOT NULL  -- 최고주령 
)


CREATE TABLE #DataTable -- 다이나믹테이블 고정테이블 헤더 날짜기준으로 인덱스 생성
(	
	  RowIDX		INT			 NOT NULL
	, ColIDX		INT			 NOT NULL
	, Qty			DECIMAL (19, 5)		 NOT NULL
)


--================================================================
-- #TITLE TABLE 구성 // TITLESEQ 는 날짜데이터활용과 JOIN 값으로 활용
--================================================================

INSERT INTO #Title (TitleSeq, Title)
	 SELECT DISTINCT  STDYMD AS TitleSeq
			, SUBSTRING(STDYMD, 5, 2) + '/' + RIGHT(STDYMD, 2) AS Title   -- '10/01' 이런식으로 헤더 구성
	   FROM joinbio_DelvPlanSimulationMake
	   WHERE STDYM = @STDYM



--===============================================
-- #FIX TABLE 구성 
-- 최고주령은 거래처명 기준으로 생산자관리_joinbio 에서 Dummy4랑 join해서 가져옴 
-- 데이터 오류시 Dummy4확인 및 현업 입력 권고
--===============================================


INSERT INTO #FixTable ( CompanySeq, InCompany, CustSeq, CustName, EggGradeSeq, EggGrade, EggTypeSeq, EggType, EggMTypeSeq, EggMType, EggWeightSeq, EggWeight, MaxWeek)
	SELECT DISTINCT   A.CompanySeq
					, A.InCompany
					, A.CustSeq
					, B.CustName
					, A.EggGradeSeq
					, ISNULL(E.MinorName, '')AS  EggGrade
					, A.EggTypeSeq
					, ISNULL(F.MinorName, '')AS  EggType
					, A.EggMTypeSeq
					, ISNULL(G.MinorName, '')AS  EggMType
					, A.EggWeightSeq
					, ISNULL(C.MinorName, '')	AS  EggWeight
					, ISNULL(D.MaxWeek, '' )
	   FROM		 joinbio_DelvPlanSimulationMake	AS A WITH(NOLOCK)
	   LEFT JOIN _TDACust			 AS B WITH(NOLOCK)	ON A.CompanySeq	    = B.CompanySeq
					            		   AND A.CustSeq		= B.CustSeq
	   LEFT JOIN _TDAUMinor           	 AS  C  WITH(NOLOCK) ON  A.CompanySeq  = C.CompanySeq
                                                                 AND A.EggWeightSeq  = C.MinorSeq
                                                                 AND C.MajorSeq    = '2000226'
           LEFT OUTER JOIN _TDAUMinor           AS  E  WITH(NOLOCK) ON  A.CompanySeq  = E.CompanySeq
                                                                 AND A.EggGradeSeq = E.MinorSeq
                                                                 AND E.MajorSeq    = '2000192' 
           LEFT OUTER JOIN _TDAUMinor           AS  F  WITH(NOLOCK) ON  A.CompanySeq  = F.CompanySeq
                                                                 AND A.EggTypeSeq  = F.MinorSeq
                                                                 AND F.MajorSeq    = '2000227' 
	   LEFT OUTER JOIN _TDAUMinor           AS  G  WITH(NOLOCK) ON  A.CompanySeq  = G.CompanySeq
                                                                 AND A.EggMTypeSeq = G.MinorSeq
                                                                 AND G.MajorSeq    = '2000182' 
	   LEFT JOIN (
					SELECT  CompanySeq
						  , Dummy4		AS  CustName
						  , MAX(CONVERT(NVARCHAR,(DATEDIFF(DAY, InDate, GETDATE())/7 + 1)) + '-' + CONVERT(NVARCHAR,((DATEDIFF(DAY, InDate, GETDATE()) % 7) + 1))) AS MaxWeek  -- 시작한 날짜 세기 위해서 +1
					 FROM join_TPUProducer WITH(NOLOCK)
					 WHERE  1=1
					   AND  CompanySeq = @CompanySeq
					   AND  IsNotUse   = 0
					   AND  ISNULL(InDate, '' ) <> ''
					   GROUP BY CompanySeq, Dummy4
				  )  AS D		ON B.CompanySeq = D.CompanySeq
							   AND B.CustName	= D.CustName
		WHERE A.CompanySeq = @CompanySeq
		  AND		 STDYM = @STDYM
		  AND ( @EggWeightSeq = 0 OR A.EggWeightSeq = @EggWeightSeq ) 
		 -- AND EggWeightSeq = @EggWeightSeq


--=========================================================================
-- DATA TABLE 구성 // 만들어지는 데이터와 고정필드의 JOIN 
-- K-STUDIO 방식이 ROW > COL 순으로 읽음 ROWIDX ,COLIDX, 가변필드 순으로 조회
--=========================================================================



INSERT INTO #DataTable
	SELECT	C.RowIDX
		  , B.ColIDX
		  , ISNULL(A.Qty, 0) AS Qty
	 FROM  joinbio_DelvPlanSimulationMake	AS A WITH(NOLOCK)
	 LEFT OUTER JOIN #Title					AS B WITH(NOLOCK) ON A.STDYMD		= B.TitleSeq
	 LEFT OUTER JOIN #FixTable				AS C WITH(NOLOCK) ON A.CompanySeq	= C.CompanySeq
															 AND A.InCompany	= C.InCompany
															 AND A.CustSeq		= C.CustSeq
															 AND A.EggWeightSeq = C.EggWeightSeq
															 AND A.EggTypeSeq	= C.EggTypeSeq
												  			 AND A.EggGradeSeq	= C.EggGradeSeq
												  			 AND A.EggMTypeSeq	= C.EggMTypeSeq
	WHERE A.CompanySeq	 = @CompanySeq
	  AND ( @EggWeightSeq = 0 OR A.EggWeightSeq = @EggWeightSeq ) 
	  AND A.STDYM = @STDYM  -- 필수값으로 들어가는 조회조건은 ''/ 0 값 안됨




--====================================================
--BIZ_OUT_DATA BLOCK TABLE에 각각 정리된 DATA입력
-- > 타이틀/고정부에는 IDX 입력 안함
-- > TITLE/ TITLESEQ 순으로 입력
-- > 다이나믹으로 만들어진 datablock들 다 채우기 조회 부
--====================================================


INSERT INTO #BIZ_OUT_DataBlock2(Title, TitleSeq)
	 SELECT Title, TitleSeq 
	   FROM #Title



INSERT INTO #BIZ_OUT_DataBlock3
			 (
			   CompanySeq
			 , InCompany
			 , CustSeq
			 , CustName
			 , EggWeightSeq
			 , EggWeight
			 , EggGradeSeq
			 , EggGrade
			 , EggTypeSeq
			 , EggType
			 , EggMTypeSeq
			 , EggMType
			 , MaxWeek
			)
	 SELECT   CompanySeq
			, InCompany
			, CustSeq
			, CustName
			, EggWeightSeq
			, EggWeight
			, EggGradeSeq
			, EggGrade
			, EggTypeSeq
			, EggType
			, EggMTypeSeq
			, EggMType
			, MaxWeek
	   FROM #FixTable




INSERT INTO #BIZ_OUT_DataBlock4(RowIDX, ColIDX, Qty)
	 SELECT RowIDX, ColIDX, Qty
	   FROM #DataTable
RETURN
