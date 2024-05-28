USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationMakeSave]    Script Date: 2023-10-27 오후 3:29:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션생성_저장
    작 성 일 - 2023.10.23
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationMakeSave]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

--=========================================
-- SQL TRANSACTION 정리 및 0나누기 에러방지
--=========================================
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
	 SET ANSI_WARNINGS OFF  -- 0나누기 에러 방지 
     SET ARITHIGNORE ON 	-- 0나누기 에러 방지 
     SET ARITHABORT OFF		-- 0나누기 에러 방지 

--========================
-- 로그테이블 남기기
--========================


DECLARE	 @TableColumns NVARCHAR(4000)                             			  
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_DelvPlanSimulationMake')                

EXEC _SCOMLog @CompanySeq  ,                              
              @UserSeq      ,          
              'joinbio_DelvPlanSimulationMake',	            -- 원테이블명                              
              '#BIZ_OUT_DataBlock3',		                -- 임시테이블명  // 다이나믹 시트는 고정필드(DATABLOCK3) 기반                            
              'InCompany,CustSeq,EggWeightSeq,STDYM,STDYMD,EggGradeSeq,EggTypeSeq,EggMTypeSeq',    -- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns,  '' -- @PgmSeq                 
             -- @TableColumns, 'InCompany', 'CustSeq', 'EggWeightSeq', 'STDYM' ,@PgmSeq                 

DECLARE		@STDYM			NVARCHAR(6)
		,	@EggWeightSeq	INT
		,	@InCompany		NVARCHAR(40)
		,	@CustSeq		INT
		,	@STDYMD			NVARCHAR(8)
		,	@Qty			DECIMAL(19,	5)
		,	@EggGradeSeq	INT
		,	@EggTypeSeq		INT
		,	@EggMTypeSeq	INT


SELECT		@STDYM			= ISNULL(STDYM			, '')
		,	@EggWeightSeq	= ISNULL(EggWeightSeq	, 0)
		,	@InCompany		= ISNULL(InCompany		, '')
		,	@CustSeq		= ISNULL(CustSeq		, 0)
		,	@STDYMD			= ISNULL(STDYMD			, '')
		,	@Qty			= ISNULL(Qty			, 0)
		,	@EggGradeSeq	= ISNULL(EggGradeSeq	, 0)
		,	@EggTypeSeq		= ISNULL(EggTypeSeq		, 0)
		,	@EggMTypeSeq	= ISNULL(EggMTypeSeq	, 0)
		 	
  FROM #BIZ_OUT_DataBlock3

		
--====================
-- DELETE 문
-- > 별도로직반영
--====================

IF EXISTS ( SELECT 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag ='D' AND Status = 0 ) 
BEGIN -- DELETE 했을시 시트삭제시 값을 0으로 업데이트 되도록 별도로직 반영

	--UPDATE joinbio_DelvPlanSimulationMake
	--   SET	Qty			 = 0
	--	  , LastUserSeq  = @UserSeq
	--	  , LastDateTime = GETDATE()
	 DELETE joinbio_DelvPlanSimulationMake
	 FROM	   #BIZ_OUT_DataBlock3			  AS A
	 LEFT JOIN joinbio_DelvPlanSimulationMake AS B ON B.CompanySeq		= @CompanySeq
												  AND A.STDYM			= B.STDYM		
												  AND A.STDYMD			= B.STDYMD		
												  AND A.EggWeightSeq	= B.EggWeightSeq
												  AND A.EggTypeSeq		= B.EggTypeSeq
												  AND A.EggGradeSeq		= B.EggGradeSeq
												  AND A.EggMTypeSeq		= B.EggMTypeSeq
												  AND A.InCompany		= B.InCompany	
												  AND A.CustSeq			= B.CustSeq	
	WHERE A.WorkingTag	= 'D' AND Status = 0

	IF @@ERROR <> 0
		BEGIN
			RETURN
		END
END
	
--==================
-- UPDATE문
--> 별도로직반영
--==================
IF EXISTS ( SELECT 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag ='U' AND Status = 0 ) 
BEGIN 

	UPDATE joinbio_DelvPlanSimulationMake
	   SET	Qty			 = A.Qty
		  , LastUserSeq  = @UserSeq
		  , LastDateTime = GETDATE()
	 FROM	   #BIZ_OUT_DataBlock3			  AS A
	 LEFT JOIN joinbio_DelvPlanSimulationMake AS B ON B.CompanySeq		= @CompanySeq
												  AND A.STDYM			= B.STDYM		
												  AND A.STDYMD			= B.STDYMD		
												  AND A.EggWeightSeq	= B.EggWeightSeq
												  AND A.EggTypeSeq		= B.EggTypeSeq
												  AND A.EggGradeSeq		= B.EggGradeSeq
												  AND A.EggMTypeSeq		= B.EggMTypeSeq
												  AND A.InCompany		= B.InCompany	
												  AND A.CustSeq			= B.CustSeq	
	WHERE A.WorkingTag	= 'U' AND Status = 0

	IF @@ERROR <> 0
		BEGIN
			RETURN
		END
END
												
RETURN



