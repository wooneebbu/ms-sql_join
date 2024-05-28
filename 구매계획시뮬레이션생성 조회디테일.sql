USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationMakeQuery2]    Script Date: 2023-10-27 오후 3:30:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션생성_조회디테일
    작 성 일 - 2023.10.24
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationMakeQuery2]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

--===========
-- 변수선언
--===========

DECLARE @CustName		VARCHAR(40)

 SELECT @CustName		=  ISNULL(CustName, '')
   FROM #BIZ_IN_DataBlock5  -- 디테일조회조건 데이터블록5

		
--========================================================
-- DataTable / Query
-- Dummy4의 데이터 중 null과 '' 으로 인한 데이터 로딩 방지
--========================================================

INSERT INTO  #BIZ_OUT_DataBlock5
			(
			   CompanySeq
			 , ProducerSeq
			 , ProducerName
			 , CustName
			 , BizNo
			 , InDate
			 , DayCnt
			 , WeekCnt
			 , BreedQty
			)
	SELECT  CompanySeq
		  , ProducerSeq
		  , ProducerName
		  , Dummy4   AS  CustName
		  , BizNo
		  , InDate
		  , CONVERT(NVARCHAR, (DATEDIFF(DAY, InDate, GETDATE()) + 1))	AS	DayCnt
		  , CONVERT(NVARCHAR,(DATEDIFF(DAY, InDate, GETDATE())/7 + 1))	+ '-' + CONVERT(NVARCHAR,((DATEDIFF(DAY, InDate, GETDATE()) % 7) + 1))	AS  WeekCnt
		  , BreedQty
	 FROM join_TPUProducer WITH(NOLOCK)

	WHERE 1 = 1
	  AND CompanySeq		  = @CompanySeq
	  AND IsNotUse			  = 0
	  AND ISNULL(Dummy4, '')  = @CustName
 ORDER BY WeekCnt DESC
								
								

RETURN