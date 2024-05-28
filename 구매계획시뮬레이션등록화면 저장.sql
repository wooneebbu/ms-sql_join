USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationSave]    Script Date: 2023-11-07 오후 6:16:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션 등록_저장
    작 성 일 - 2023.09.14
    작 성 자 - HHWoon   
    수    정 - 2023.11.18 품종(EggTypeSeq), 등급(EggGradeSeq) 추가 / 필수값 설정
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_DelvPlanSimulationSave]               
    @ServiceSeq        INT         = 0,                
    @WorkingTag        NVARCHAR(10)= '',                
    @CompanySeq        INT         = 1,                
    @LanguageSeq       INT         = 1,                
    @UserSeq           INT         = 0,                
    @PgmSeq            INT         = 0,              
    @IsTransaction     INT         = 0                               
AS          

-- 로그테이블 남기기

DECLARE	 @TableColumns NVARCHAR(4000)                             			  
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_DelvPlanSimulation')                


EXEC _SCOMLog @CompanySeq  ,                              
              @UserSeq      ,          
              'joinbio_DelvPlanSimulation',	            	-- 원테이블명                              
              '#BIZ_OUT_DataBlock1',		                -- 임시테이블명                              
              'InCompany,CustSeq,EggWeightSeq,StdYM,EggGradeSeq,EggTypeSeq',    -- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns, '',  @PgmSeq                 
             -- @TableColumns, 'InCompany', 'CustSeq', 'EggWeightSeq', 'STDYM' ,@PgmSeq                 


-- DELETE
IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0)
BEGIN
	DELETE joinbio_DelvPlanSimulation FROM #BIZ_OUT_DataBlock1			AS A  
				  LEFT OUTER JOIN  joinbio_DelvPlanSimulation	        AS B WITH(NOLOCK) ON  A.CompanySeq    = B.CompanySeq 
																			             AND  A.InCompany     = B.InCompany
																			             AND  A.CustSeq       = B.CustSeq
																			             AND  A.EggTypeSeq    = B.EggTypeSeq
																			             AND  A.EggGradeSeq   = B.EggGradeSeq
                                                   AND  A.EggWeightSeq  = B.EggWeightSeq
																			             AND  A.STDYM         = B.STDYM
	WHERE B.CompanySeq  = @CompanySeq
	  AND A.WorkingTag  = 'D'
	  AND A.Status      =  0
	  IF @@ERROR <> 0 RETURN
END


-- UPDATE  
IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0)
BEGIN
PRINT 'UPDATE'

	UPDATE joinbio_DelvPlanSimulation SET        
                            EggTypeSeq      = A.EggTypeSeq, -- 입력 끝나면 다시 주석처리 
                            EggGradeSeq     = A.EggGradeSeq,
                            EggWeightSeq    = A.EggWeightSeq,
                            Mon		          = A.Mon,		  
                            Tue		          = A.Tue,		  
                            Wed		          = A.Wed,		  
                            Thu		          = A.Thu,		  
                            Fri		          = A.Fri,		  
                            Sat		          = A.Sat,		  
                            Sun		          = A.Sun,		  
                            InAVG             = A.InAVG,		  
                            Dummy3            = A.Dummy3,	
                            Dummy4	          = A.Dummy4,	
                            Dummy5	          = A.Dummy5,	
							              LastUserSeq       = @UserSeq,
							              LastDateTime      = GETDATE()
	 FROM #BIZ_OUT_DataBlock1		    AS A
	 LEFT OUTER JOIN joinbio_DelvPlanSimulation AS B WITH(NOLOCK)   ON  A.CompanySeq    = B.CompanySeq     
													                                       AND  A.InCompany     = B.InCompany
																                                 AND  A.CustSeq       = B.CustSeq
                                                                -- AND  A.EggTypeSeq    = B.EggTypeSeq
																			                          -- AND  A.EggGradeSeq   = B.EggGradeSeq
																                                -- AND  A.EggWeightSeq  = B.EggWeightSeq
																                                 AND  A.STDYM         = B.STDYM
     WHERE B.CompanySeq = @CompanySeq                                              
       AND A.WorkingTag = 'U'                       
       AND A.Status     = 0       
	   
     IF @@ERROR <> 0 RETURN                             
END

-- INSERT
IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )
BEGIN
	INSERT INTO joinbio_DelvPlanSimulation(  
                            CompanySeq,
                            InCompany,
                            CustSeq,
                            EggWeightSeq,
                            STDYM,
                            Mon,
                            Tue,
                            Wed,
                            Thu,
                            Fri,
                            Sat,
                            Sun,
                            InAVG,
                            EggGradeSeq,
                            EggTypeSeq,
                            Dummy3,
                            Dummy4,
                            Dummy5,              
                            LastUserSeq,        
                            LastDateTime
								)
	SELECT  @CompanySeq,
          InCompany,
          CustSeq, 
          EggWeightSeq,
          STDYM,
          Mon,
          Tue,
          Wed,
          Thu,
          Fri,
          Sat,
          Sun,
          InAVG,
          EggGradeSeq,
          EggTypeSeq,
          Dummy3,
          Dummy4,
          Dummy5,             	    
          @UserSeq,    		  
          GETDATE() 
    FROM #BIZ_OUT_DataBlock1
    WHERE WorkingTag = 'A'
	  AND Status = 0   
	IF @@ERROR <> 0 RETURN 
END


RETURN