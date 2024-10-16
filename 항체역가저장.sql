USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_AntiReactionNoteSave]    Script Date: 2022-11-09 오후 3:13:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 항체역가저장
    작 성 일 - 2022.10.28
    작 성 자 - HHWoon   
 *************************************************************************************************/          
ALTER PROC [dbo].[joinbio_AntiReactionNoteSave]               
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
SELECT	 @TableColumns = dbo._FGetColumnsForLog('joinbio_AntiReactionNote')                
	
EXEC _SCOMLog @CompanySeq   ,                              
              @UserSeq      ,          
              'joinbio_AntiReactionNote',	            	-- 원테이블명                              
              '#BIZ_OUT_DataBlock1',		            	-- 임시테이블명                              
              'IDNum, InspItemSeq' ,		            	-- PK키가 여러개일 경우는 , 로 연결한다.                               
              @TableColumns, 'IDNum, FarmSeq, DongSeq, BreedSeq, InOutDate, WorkDate, InspItemSeq, ', @PgmSeq                 

-- DELETE  --임시테이블에 자료값을 담았고, 임시테이블에 있으면, JOIN걸어서 원래 테이블에서도 지우는거

IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0)
BEGIN
	DELETE joinbio_AntiReactionNote FROM #BIZ_OUT_DataBlock1			AS A  
						LEFT OUTER JOIN  joinbio_AntiReactionNote	    AS B WITH(NOLOCK) ON  A.CompanySeq  = B.CompanySeq
																			              AND A.IDNum       = B.IDNum 
                                                                                          AND A.FarmSeq     = B.FarmSeq
                                                                                          AND A.DongSeq     = B.DongSeq
                                                                                          AND A.BreedSeq    = B.BreedSeq
                                                                                          AND A.InOutDate   = B.InOutDate
                                                                                          AND A.WorkDate    = B.WorkDate
                                                                                          AND A.InspItemSeq = B.InspItemSeq
	WHERE B.CompanySeq  = @CompanySeq
	  AND A.WorkingTag  = 'D'
	  AND A.Status      =  0
	  IF @@ERROR <> 0 RETURN
END


-- UPDATE   --PK관련 값들은 UPDATE문에 써놓지 않도록 (바꿀수 없다)

IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0)
BEGIN
	UPDATE joinbio_AntiReactionNote SET        -- PK 값 X --ARNSeq 값은 Update/Insert 되면 안됨 Identity 설정해놔서 
							              IDDate		 = A.IDDate,
							              DanSeq		 = A.DanSeq,
                                          TimeNumSeq     = A.TimeNumSeq,
                                          SpeciesSeq     = A.SpeciesSeq,
                                          InspComplete   = A.InspComplete,
                                          SampleNum      = A.SampleNum,
										  ARCount00      = A.ARCount00,
                                          ARCount01      = A.ARCount01,
                                          ARCount02      = A.ARCount02,      
                                          ARCount03      = A.ARCount03,
                                          ARCount04      = A.ARCount04,
                                          ARCount05      = A.ARCount05,
                                          ARCount06      = A.ARCount06,
                                          ARCount07      = A.ARCount07,
                                          ARCount08      = A.ARCount08,
                                          ARCount09      = A.ARCount09,
                                          ARCount10      = A.ARCount10,
                                          ARCount11      = A.ARCount11,
                                          ARCount12      = A.ARCount12,
                                          ARCount13      = A.ARCount13,
                                          ARCount14      = A.ARCount14,
                                          ARCount15      = A.ARCount15,
							              LastUserSeq    = @UserSeq,
							              LastDateTime   = GETDATE()
	 FROM #BIZ_OUT_DataBlock1		AS A
	 LEFT OUTER JOIN joinbio_AntiReactionNote AS B WITH(NOLOCK) ON  A.CompanySeq  = B.CompanySeq     -- PK값은 다 걸어주기
													            AND A.IDNum       = B.IDNum
                                                                AND A.FarmSeq     = B.FarmSeq
                                                                AND A.DongSeq     = B.DongSeq
                                                                AND A.BreedSeq    = B.BreedSeq
                                                                AND A.InOutDate   = B.InOutDate
                                                                AND A.WorkDate    = B.WorkDate
                                                                AND A.InspItemSeq = B.InspItemSeq
         WHERE B.CompanySeq = @CompanySeq                                              
           AND A.WorkingTag = 'U'                       
           AND A.Status     = 0                                                   
     IF @@ERROR <> 0 RETURN                             
END


-- INSERT
IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )
BEGIN
	INSERT INTO joinbio_AntiReactionNote(  -- insert into와 select에 순서는 맞춰줘야함
								CompanySeq,					IDNum,					InspItemSeq,					IDDate,
								FarmSeq,					DanSeq,					DongSeq,						TimeNumSeq,					BreedSeq,
                                SpeciesSeq,					InOutDate,				WorkDate,						InspComplete,				SampleNum,
								ARCount00,					ARCount01,				ARCount02,						ARCount03,					ARCount04,
                                ARCount05,					ARCount06,				ARCount07,						ARCount08,					ARCount09,
                                ARCount10,					ARCount11,				ARCount12,						ARCount13,					ARCount14,
                                ARCount15,					ARAVG,					LastUserSeq,					LastDateTime
								)
	SELECT @CompanySeq,					IDNum,					InspItemSeq,					IDDate, 
           FarmSeq,						DanSeq,					DongSeq,						TimeNumSeq,					BreedSeq, 
           SpeciesSeq,					InOutDate,				WorkDate,						InspComplete,				SampleNum,
		   ARCount00,					ARCount01,				ARCount02,						ARCount03,					ARCount04, 
           ARCount05,					ARCount06,				ARCount07,						ARCount08,					ARCount09,
           ARCount10,					ARCount11,				ARCount12,						ARCount13,					ARCount14,
           ARCount15,					ARAVG,
           @UserSeq, 
		   GETDATE() 
    FROM #BIZ_OUT_DataBlock1
    WHERE WorkingTag = 'A'
	  AND Status = 0

	IF @@ERROR <> 0 RETURN 
END


RETURN
						
