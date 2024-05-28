USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_AntiReactionNoteSave]    Script Date: 2022-11-09 오후 3:13:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 프로젝트관리_저장
    작 성 일 - 2023.03.22
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_PrjManageSave]               
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
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_Prjmanager')                
	
EXEC _SCOMLog @CompanySeq  ,                              
              @UserSeq      ,          
              'joinbio_Prjmanager',	            	-- 원테이블명                              
              '#BIZ_OUT_DataBlock1',		        -- 임시테이블명                              
              'GWSeq',      		                -- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns, 'GWSeq', @PgmSeq                 

-- DELETE  --임시테이블에 자료값을 담았고, 임시테이블에 있으면, JOIN걸어서 원래 테이블에서도 지우는거

IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0)
BEGIN
	DELETE joinbio_Prjmanager FROM #BIZ_OUT_DataBlock1			AS A  
				  LEFT OUTER JOIN  joinbio_Prjmanager	        AS B WITH(NOLOCK) ON  A.CompanySeq    = B.CompanySeq  -- PK값 JOIN할때
																			     AND  A.GWSeq         = B.GWSeq
	WHERE B.CompanySeq  = @CompanySeq
	  AND A.WorkingTag  = 'D'
	  AND A.Status      =  0
	  IF @@ERROR <> 0 RETURN
END


-- UPDATE   --PK관련 값들은 UPDATE문에 써놓지 않도록 (바꿀수 없다)

IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0)
BEGIN
	UPDATE joinbio_Prjmanager SET        -- PK 값 X --자동채번Seq 값은 Update/Insert 되면 안됨 Identity 설정해놔서 
							              PrjName		        = A.PrjName,
                            PrjGubunSeq       = A.PrjGubunSeq,
                            PrjPurpose        = A.PrjPurpose,
                            WorkDate          = A.WorkDate,
                            DueDate           = A.DueDate,
                    				EndDate           = A.EndDate,
                            PrjDept           = A.PrjDept,
                            RateSeq           = A.RateSeq,      
                            AdminUser         = A.AdminUser,
                            ProgressSeq       = A.ProgressSeq,
                            PrjIssue          = A.PrjIssue,
                            Remark            = A.Remark,
							              LastUserSeq       = @UserSeq,
							              LastDateTime      = GETDATE()
	 FROM #BIZ_OUT_DataBlock1		    AS A
	 LEFT OUTER JOIN joinbio_Prjmanager AS B WITH(NOLOCK)   ON  A.CompanySeq    = B.CompanySeq     -- PK값은 다 걸어주기
													        AND A.GWSeq         = B.GWSeq
         WHERE B.CompanySeq = @CompanySeq                                              
           AND A.WorkingTag = 'U'                       
           AND A.Status     = 0                                                     
     IF @@ERROR <> 0 RETURN                             
END


-- INSERT
IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )
BEGIN
	INSERT INTO joinbio_Prjmanager(  -- insert into와 select에 순서는 맞춰줘야함
                            CompanySeq,         GWSeq,             PrjName,                      
                            PrjGubunSeq,        PrjPurpose,        WorkDate,         DueDate,
                            EndDate,            PrjDept,           RateSeq,          AdminUser,
                            ProgressSeq,        PrjIssue,          Remark,                 
                            LastUserSeq,        LastDateTime
								)
	SELECT  @CompanySeq,	          GWSeq,             PrjName,
            PrjGubunSeq,          PrjPurpose,        WorkDate,         DueDate,
            EndDate,              PrjDept,           RateSeq,          AdminUser,
            ProgressSeq,          PrjIssue,          Remark,
            @UserSeq,    		  GETDATE() 
    FROM #BIZ_OUT_DataBlock1
    WHERE WorkingTag = 'A'
	  AND Status = 0   
	IF @@ERROR <> 0 RETURN 
END


RETURN
						
