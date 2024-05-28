USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_RPAMasterCheck_kdj]    Script Date: 2023-02-20 오전 10:16:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션 등록_체크
    작 성 일 - 2023.09.20
    작 성 자 - HHWoon     
 *************************************************************************************************/        
ALTER PROC [dbo].[joinbio_DelvPlanSimulationCheck]        
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
      AND (InCompany = '')   --pk항목추가  
      AND (CustSeq = 0)
      AND (EggWeightSeq = 0)
      AND (STDYM = '')    
            
-------------------------------------------------------------
--중복입력 체크 (PK항목 일치했을때 저장 안되도록)
--------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                          @Status      OUTPUT,          
                          @Results     OUTPUT,          
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')          
                          @LanguageSeq       ,          
                          0, '데이터',         -- SELECT * FROM _TCADictionary WHERE Word like '%거래처%'          
                          0, ' '    -- SELECT * FROM _TCADictionary WHERE Word like '%점포코드%'          
        
    UPDATE #BIZ_OUT_DataBlock1	 SET  Result       = '중복된 필수값이 입력되었습니다.', --@Results,        
									  MessageType  = @MessageType,          
									  Status       = @Status          
        FROM #BIZ_OUT_DataBlock1 AS A          
        JOIN (          
               SELECT S.InCompany, S.CustSeq, S.EggWeightSeq, S.STDYM
                      FROM (          
                        SELECT A.InCompany, A.CustSeq, A.EggWeightSeq, A.STDYM
                        FROM #BIZ_OUT_DataBlock1 AS A         
                        WHERE A.WorkingTag IN ('A', 'U')          
                          AND A.Status = 0                
                        UNION ALL        
                        SELECT A.InCompany, A.CustSeq, A.EggWeightSeq, A.STDYM
                        FROM  joinbio_DelvPlanSimulation AS A          
                        WHERE A.CompanySeq = @CompanySeq          
                          AND NOT EXISTS ( 
                                         SELECT GWSeq 
                                         FROM #BIZ_OUT_DataBlock1         
                                             WHERE CompanySeq      = A.CompanySeq					   
											 AND   InCompany	   = A.InCompany                                   
											 AND   CustSeq	       = A.CustSeq                                   
											 AND   EggWeightSeq	   = A.EggWeightSeq                                   
											 AND   STDYM	       = A.STDYM                                   
                                             AND   WorkingTag IN ('U', 'D')       
                                             AND   Status = 0   
                                        )   
                        ) AS S          
                  GROUP BY S.InCompany, S.CustSeq, S.EggWeightSeq, S.STDYM
                  HAVING COUNT(*) > 1 
                 ) AS B ON A.InCompany    = B.InCompany
                       AND A.CustSeq      = B.CustSeq
                       AND A.EggWeightSeq = B.EggWeightSeq 
                       AND A.STDYM        = B.STDYM
            WHERE A.WorkingTag IN ('A', 'U')         
              AND A.Status = 0    

