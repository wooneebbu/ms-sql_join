USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_AntiReactionNoteCheck]    Script Date: 2023-01-29 오후 7:24:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 항체역가체크
    작 성 일 - 2022.11.02
    작 성 자 - HHWoon      
 *************************************************************************************************/         
ALTER PROC [dbo].[joinbio_AntiReactionNoteCheck]        
    @ServiceSeq        INT         = 0,            
    @WorkingTag        NVARCHAR(10)= '',            
    @CompanySeq        INT         = 1,            
    @LanguageSeq       INT         = 1,            
    @UserSeq           INT         = 0,            
    @PgmSeq            INT         = 0,          
    @IsTransaction     INT         = 0            
        
AS         
    DECLARE @MessageType    INT,
			@Count			INT,
            @Status         INT,      
            @Results        NVARCHAR(250),        
            @MessageStatus  INT             
        
--------------------------------------------------------
-- 필수입력 체크 (PK항목에 대해서 체크 > K-studio에서 NOS해도 됨)
--------------------------------------------------------
  EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                         @Status      OUTPUT,          
                         @Results     OUTPUT,          
                         1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')          
                         @LanguageSeq       ,           
                         0,        
                         ''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
        
   UPDATE #BIZ_OUT_DataBlock1              
      SET Result        = @Results,       
          MessageType   = @MessageType,                       
          Status        = @Status                 
     FROM #BIZ_OUT_DataBlock1 AS A        
    WHERE WorkingTag IN ('A', 'U')        
      AND Status = 0         
      AND (IDNum = 0 OR FarmSeq = 0 OR 
		   -- DongSeq = 0 OR 
		   BreedSeq = 0 OR 
		   InOutDate = '' OR WorkDate = '' OR InspItemSeq = 0 )   --pk항목추가      


            
--------------------------------------------------------------
--중복입력 체크 (PK항목 일치했을때 저장 안되도록)
--------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                          @Status      OUTPUT,          
                          @Results     OUTPUT,          
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')          
                          @LanguageSeq       ,          
                          0, '데이터',         -- SELECT * FROM _TCADictionary WHERE Word like '%거래처%'          
                          0, ' '    -- SELECT * FROM _TCADictionary WHERE Word like '%점포코드%'          
        
    UPDATE #BIZ_OUT_DataBlock1	 SET  Result       = '중복된 데이터가 입력되었습니다.', --@Results,        
									  MessageType  = @MessageType,          
									  Status       = @Status          
        FROM #BIZ_OUT_DataBlock1 AS A          
        JOIN (          
               SELECT S.IDNum,      S.FarmSeq, 
                      -- S.DongSeq,    
					  S.BreedSeq, 
                      S.InOutDate,  S.WorkDate, 
                      S.InspItemSeq 
                      FROM (          
                        SELECT A.IDNum,     A.FarmSeq, 
                               -- A.DongSeq,   
							   A.BreedSeq, 
                               A.InOutDate, A.WorkDate, 
                               A.InspItemSeq 
                        FROM #BIZ_OUT_DataBlock1 AS A         
                        WHERE A.WorkingTag IN ('A', 'U')          
                          AND A.Status = 0               -- 1차   
                        UNION ALL        --  2차
                        SELECT A.IDNum,     A.FarmSeq, 
                               --A.DongSeq,   
							   A.BreedSeq, 
                               A.InOutDate, A.WorkDate, 
                               A.InspItemSeq 
                        FROM  joinbio_AntiReactionNote AS A          
                        WHERE A.CompanySeq = @CompanySeq          
                          AND NOT EXISTS (    -- PK 관련 컬럼 설정해줌/ AND NOT EXISTS > 서브쿼리에 데이터가 존재하지 않을경우 데이터 조회 > 데이터를 1건이라도 찾으면 검색 멈추고TRUE 반환
                                         SELECT IDNum,     FarmSeq, 
                                                --DongSeq,   
												BreedSeq, 
                                                InOutDate, WorkDate, 
                                                InspItemSeq  
                                         FROM #BIZ_OUT_DataBlock1         
                                             WHERE CompanySeq      = A.CompanySeq
                                             AND   IDNum	       = A.IDNum
                                             AND   FarmSeq	       = A.FarmSeq
                                             --AND   DongSeq	       = A.DongSeq
                                             AND   BreedSeq	       = A.BreedSeq
                                             AND   InOutDate       = A.InOutDate
                                             AND   WorkDate	       = A.WorkDate
                                             AND   InspItemSeq	   = A.InspItemSeq
                                             AND   WorkingTag IN ('U', 'D')   -- 수정된 사항에 대해서 데이터 일치여부 확인      
                                             AND   Status = 0   -- status = 0 은 메세지(error)가 없다는 의미      --1차
                        )   
                        ) AS S          
                  GROUP BY S.IDNum,      S.FarmSeq, 
                           --S.DongSeq,    
						               S.BreedSeq, 
                           S.InOutDate,  S.WorkDate, 
                           S.InspItemSeq 
                  HAVING COUNT(*) > 1   -- 똑같은 값이 2개 이상 인거 (중복되었다)
                 ) AS B ON   A.IDNum	     = B.IDNum
                        AND  A.FarmSeq       = B.FarmSeq
                        --AND  A.DongSeq       = B.DongSeq
                        AND  A.BreedSeq      = B.BreedSeq
                        AND  A.InOutDate     = B.InOutDate
                        AND  A.WorkDate      = B.WorkDate
                        AND  A.InspItemSeq   = B.InspItemSeq
            WHERE A.WorkingTag IN ('A', 'U')          
              AND A.Status = 0   

 -------------------------------------------------------------------------------------------------
 -- PK값 변경 못하게 > 삭제후 재입력 설정              
 -------------------------------------------------------------------------------------------------     

 SELECT @Count = COUNT(1) -- 1은 수정사항이 있음 ('U'붙은게 몇개인지 COUNT)
 FROM #BIZ_OUT_DataBlock1
 WHERE WorkingTag = 'U' --@Count값수정(AND  Status = 0 제외)                                
 
  IF @Count > 0                                
  BEGIN                                                                                               
    UPDATE #BIZ_OUT_DataBlock1                               
    SET  Result = '필수값은 변경이 불가능합니다. 시트삭제후 다시 입력해주세요.'
		,Status = 1234 -- 임의의 수 넣은거 
	FROM #BIZ_OUT_DataBlock1   AS A
	LEFT OUTER JOIN joinbio_AntiReactionNote AS B ON   A.ARNSeq	       = B.ARNSeq    -- 자동채번으로 묶어서 PK값 안건들게 (무조건 관련된 자동채번이 있어야함 CompanySeq로 걸면 다 1로 묶여서 에러발생)                                             
    WHERE WorkingTag = 'U'                                
    AND Status = 0
    AND(A.IDNum	       <> B.IDNum
    OR  A.FarmSeq      <> B.FarmSeq
    -- OR  A.DongSeq      <> B.DongSeq
    OR  A.BreedSeq     <> B.BreedSeq
    OR  A.InOutDate    <> B.InOutDate
    OR  A.WorkDate     <> B.WorkDate
    OR  A.InspItemSeq  <> B.InspItemSeq) -- 황혜운기특하다
  END

--  USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_RPAMoniteringCheck]    Script Date: 2023-02-16 오후 6:28:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************                              
 설  명 - RPA 모니터링 : 체크                              
 작성일 - 20210419                             
 작성자 - 서정한                              
************************************************************/           

                                        
ALTER PROC [dbo].[joinbio_RPAMoniteringCheck]              
    @ServiceSeq		INT			= 0,                        
    @WorkingTag		NVARCHAR(10)	= '',                        
    @CompanySeq		INT			= 1,                        
    @LanguageSeq	INT			= 1,                        
    @UserSeq		INT			= 0,                        
    @PgmSeq			INT			= 0,                      
    @IsTransaction	BIT			= 0                        
                    
AS                     

DECLARE
	@Count			INT    
	,@Seq			INT
	,@Seq1			INT 
	,@MessageType	INT                  
	,@Status         INT       
	,@Results		NVARCHAR(250)              
	,@MessageStatus	INT
       
    
 -------------------------------------------------------------------------------------------------
 -- 서비스 마스터 등록 생성                    
 -------------------------------------------------------------------------------------------------                              
 --    CREATE TABLE #joinbio_TbITWorksList (WorkingTag NCHAR(1) NULL)                                  
 --    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#joinbio_TRPAErrorList'                                     
 --    IF @@ERROR <> 0 RETURN     



    
                  
 -------------------------------------------------------------------------------------------------
 -- 필수 입력 체크                    
 -------------------------------------------------------------------------------------------------                 
EXEC dbo._SCOMMessage	@MessageType		OUTPUT
					,@Status			OUTPUT                      
                    ,@Results		OUTPUT                      
                    ,1038                -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')                      
                    ,@LanguageSeq                              
                    ,0                    
                    ,''					-- SELECT * FROM _TCADictionary WHERE Word like '%%'                      
         
	UPDATE #BIZ_OUT_DataBlock1                          
	SET Result			= @Results
		,MessageType	= @MessageType
		,Status			= @Status
		
	FROM #BIZ_OUT_DataBlock1 AS A
	  
	WHERE WorkingTag IN ('A', 'U')                    
	AND Status = 0                     
	AND (								-- 필수 입력 필드 : 해당 부분 아래에 필수 필드 입력
		(	GubunSeq	=	0 )			-- 구분코드
		OR (GrpCustSeq	=	0 )			-- 집계거래처코드
		OR (ActNo		=	0 )			-- 차수
		)          
                       
					   



 -------------------------------------------------------------------------------------------------
 -- 구분, 집계거래처, 차수 체크 (키 값은 중복 불가)                  
 -------------------------------------------------------------------------------------------------         
 -- WorkingTag가 A일 경우

 /** GW문서번호, 순번 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '중복된 구분, 집계거래처, 차수가 입력되었습니다.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
    AND	(SELECT COUNT(GubunSeq) FROM joinbio_TRPAMoniter WHERE (GubunSeq = A.GubunSeq AND GrpCustSeq = A.GrpCustSeq AND ActNo = A.ActNo)) >= 1				-- 기존 저장된 GubunSeq, GrpCustSeq, ActNo 중복 확인
	AND	A.WorkingTag = 'A'




/*
 -------------------------------------------------------------------------------------------------
 -- 차수 체크 (차수는 수정 불가)                   
 -------------------------------------------------------------------------------------------------         
 -- WorkingTag가 U일 경우

 /** GW문서번호, 순번 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '차수는 수정 할 수 없습니다.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
    AND	(SELECT COUNT(GubunSeq) FROM joinbio_TRPAMoniter WHERE ActNo = A.ActNo AND (GrpCustSeq <> A.GrpCustSeq OR GubunSeq <> A.GubunSeq)) >= 1
	AND	A.WorkingTag = 'U'
*/



/*
 -------------------------------------------------------------------------------------------------
 -- GW문서번호, 순번 체크 3                   
 -------------------------------------------------------------------------------------------------         
 -- 한번에 여러줄 입력 시 동일 GW문서번호, 순번 입력 불가

 /** GW문서번호, 순번 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '중복된 GW문서번호, 순번이 입력되었습니다.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
	AND (SELECT COUNT(DISTINCT(GWDoc+CAST(GWDocSerl AS NVARCHAR(100)))) FROM #BIZ_OUT_DataBlock1) <> (SELECT COUNT(*) FROM #BIZ_OUT_DataBlock1)
	AND	A.WorkingTag = 'A'
*/






 ---------------------------------------------------------------------------------------------------
 ---- GW문서 ID 체크               
 ---------------------------------------------------------------------------------------------------         
 ---- GW문서 ID는 숫자만 입력 가능
                   
 --   UPDATE #BIZ_OUT_DataBlock1                       
 --   SET	Result = 'GW문서 ID는 숫자만 입력 가능합니다.',             
	--	Status = 1234                        
 --   FROM #BIZ_OUT_DataBlock1				AS A

 --   WHERE A.Status = 0
 --   AND	ISNUMERIC(GWDocID) = 0





 /*
 -------------------------------------------------------------------------------------------------
 -- 동작시간 체크 (동작시간 4자리 입력)                 
 -------------------------------------------------------------------------------------------------         

 /** 동작시간 자릿수 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '동작시간 형식이 맞지 않습니다. (4자리)',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
    AND	((LEN(ActTime)	!=	4)						-- 동작시간 글자수 체크 (4자리)
*/





 
 -------------------------------------------------------------------------------------------------
 -- 동작시간 체크 (24시간 형태)                 
 -------------------------------------------------------------------------------------------------         

 /** 동작시간 자릿수 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '옳바른 동작시간을 입력해주십시오.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
    AND	(LEFT(ActTime,2) >= 24 OR RIGHT(ActTime,2) >=60)






/*
 -------------------------------------------------------------------------------------------------
 -- AS-IS /TO-BE 작업시간 체크 (양수만 입력 가능)                 
 -------------------------------------------------------------------------------------------------         
                          
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = 'AS-IS 작업시간과 TO-BE 작업시간은 0 이상이어야 합니다.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1				AS A

    WHERE A.Status = 0
	AND	(WkMinute < 0 OR RMinute < 0)
*/



 ---------------------------------------------------------------------------------------------------
 ---- 팀장확인일자, 평가점수, 조정점수 체크                   
 ---------------------------------------------------------------------------------------------------         
 ---- 지정한 사용자가 아니면 해당부분 입력, 수정 불가

 --/** 팀장확인일자, 평가점수, 조정점수 체크 **/                            
 --   UPDATE #BIZ_OUT_DataBlock1                       
 --   SET	Result = '[팀장확인일자], [평가점수], [조정점수]는 지정된 사용자가 아니면 입력/수정 할 수 없습니다.',             
	--	Status = 1234                        
 --   FROM #BIZ_OUT_DataBlock1				AS A

 --   WHERE A.Status = 0                     
 --   AND	@UserSeq <> 1201		-- UserName 김종엽1 (_TCAUser)
	--AND	(A.CfmDt <> ''		-- 팀장확인일자
	--OR	A.CfmPoint <> 0		-- 평가점수
	--OR	A.CfmBonus <> 0)		-- 조정점수






/*
 -------------------------------------------------------------------------------------------------
 -- 개발시작일, 개발종료일 체크                    
 -------------------------------------------------------------------------------------------------         
 -- 개발시작일이 개발종료일보다 클 수 없음

 /** 개발시작일, 개발종료일 체크 **/                            
    UPDATE #BIZ_OUT_DataBlock1                       
    SET	Result = '개발시작일(실제)이 개발종료일(실제)보다 클 수 없습니다.',             
		Status = 1234                        
    FROM #BIZ_OUT_DataBlock1   AS A                        
    WHERE A.Status = 0
	AND A.RStDt <> NULL
	AND A.REndDt <> NULL
    AND REPLACE(A.RStDt,' ','') > REPLACE(A.REndDt,' ','')
*/






/*
 -------------------------------------------------------------------------------------------------
 -- 순번 중복 번호 입력 가능하게 부여 (INSERT 번호 부여(맨 마지막 처리))                    
 -------------------------------------------------------------------------------------------------     
 -- 순번 자동 증가 입력

 SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' --@Count값수정(AND  Status = 0 제외)                                
  IF @Count > 0                                
  BEGIN                                  
    -- 키값생성코드부분 시작                                  
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'joinbio_TbITWorksList', 'ITWkSeq', @Count                                
    -- Temp Talbe 에 생성된 키값 UPDATE                                
    UPDATE #BIZ_OUT_DataBlock1                               
    SET ITWkSeq = @Seq + DataSeq                                
    WHERE WorkingTag = 'A'                                
    AND Status = 0
	
  END                                                               
     --SELECT * FROM #BIZ_OUT_DataBlock1                                  
*/                   






/*
 -------------------------------------------------------------------------------------------------
 -- 순번 중복 번호 입력 가능하게 부여 (INSERT 번호 부여(맨 마지막 처리))                    
 -------------------------------------------------------------------------------------------------     
 -- 순번 자동 증가 입력

 SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' --@Count값수정(AND  Status = 0 제외)                                
  IF @Count > 0                                
  BEGIN                                  
    -- 키값생성코드부분 시작                                  
    EXEC @Seq1 = dbo._SCOMCreateSeq @CompanySeq, 'joinbio_TbITWorksList', 'GWDocSerl', @Count                                
    -- Temp Talbe 에 생성된 키값 UPDATE                                
    UPDATE #BIZ_OUT_DataBlock1                               
    SET GWDocSerl = @Seq1 + DataSeq                                
    WHERE WorkingTag = 'A'                                
    AND Status = 0
	
  END                                                               
     --SELECT * FROM #BIZ_OUT_DataBlock1                 
*/ 
                 
				 



RETURN
          


RETURN
