USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_DelvPlanSimulationQuery]    Script Date: 2023-11-15 오전 10:50:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 구매계획시뮬레이션 등록_조회
    작 성 일 - 2023.09.14
    작 성 자 - HHWoon      
    수    정 - 2023.11.08 항목추가   
 *************************************************************************************************/         
ALTER PROC [dbo].[joinbio_DelvPlanSimulationQuery]    
     @ServiceSeq        INT         = 0,          
     @WorkingTag        NVARCHAR(10)= '',          
     @CompanySeq        INT         = 1,          
     @LanguageSeq       INT         = 1,          
     @UserSeq           INT         = 0,          
     @PgmSeq            INT         = 0,        
     @IsTransaction     INT         = 0          
AS

DECLARE @STDYM          VARCHAR(8),           -- 기준연월
        @EggWeightSeq   INT                   -- 난중code

SELECT @STDYM            =		ISNULL(STDYM, ''),	
	   @EggWeightSeq	 =		ISNULL(EggWeightSeq, 0)


	  FROM #BIZ_IN_DataBlock1


	  INSERT INTO #BIZ_OUT_DataBlock1(    					    
						    CompanySeq,
                            InCompany,
                            InAVG,
                            CustSeq,
                            CustName,
                            EggTypeSeq,
                            EggType,
                            EggGradeSeq,
                            EggGrade,
                            EggWeightSeq,
                            EggWeight,
							EggMTypeSeq,
							EggMType,
                            MaxWeek,
                            Mon,
                            Tue,
                            Wed,
                            Thu,
                            Fri,
                            Sat,
                            Sun,
                            UserName,
                            LastUserSeq,      
                            LastDateTime
									)


SELECT                      A.CompanySeq,
                            A.InCompany,
                            A.InAVG,         
                            A.CustSeq,
                            B.CustName,
                            A.EggTypeSeq,
                            D.MinorName AS EggType,
                            A.EggGradeSeq,
                            E.MinorName AS EggGrade,
                            A.EggWeightSeq,
                            F.MinorName AS EggWeight,
							A.EggMTypeSeq,
							G.MinorName AS EggMType,
                            C.MaxWeek,
                            A.Mon,
                            A.Tue,
                            A.Wed,              
                            A.Thu,                  
                            A.Fri,              
                            A.Sat,
                            A.Sun,               
                            U.UserName,
                            A.LastUserSeq,      
                            CONVERT(VARCHAR(10), A.LastDateTime, 120)  AS LastDateTime
        FROM joinbio_DelvPlanSimulation      AS  A  WITH(NOLOCK)
        LEFT OUTER JOIN _TDACust             AS  B  WITH(NOLOCK) ON  A.CompanySeq  = B.CompanySeq
                                                                 AND A.CustSeq     = B.CustSeq	    
        LEFT OUTER JOIN _TCAUser             AS  U  WITH(NOLOCK) ON  A.CompanySeq  = U.CompanySeq
													             AND A.LastUserSeq = U.UserSeq
        LEFT OUTER JOIN _TDAUMinor           AS  D  WITH(NOLOCK) ON  A.CompanySeq  = D.CompanySeq
                                                                 AND A.EggTypeSeq  = D.MinorSeq
                                                                 AND D.MajorSeq    = '2000227'
        LEFT OUTER JOIN _TDAUMinor           AS  E  WITH(NOLOCK) ON  A.CompanySeq  = E.CompanySeq
                                                                 AND A.EggGradeSeq = E.MinorSeq
                                                                 AND E.MajorSeq    = '2000192' 
        LEFT OUTER JOIN _TDAUMinor           AS  F  WITH(NOLOCK) ON  A.CompanySeq  = F.CompanySeq
                                                                 AND A.EggWeightSeq = F.MinorSeq
                                                                 AND F.MajorSeq    = '2000226' 
		LEFT OUTER JOIN _TDAUMinor           AS  G  WITH(NOLOCK) ON  A.CompanySeq  = G.CompanySeq
                                                                 AND A.EggMTypeSeq = G.MinorSeq
                                                                 AND G.MajorSeq    = '2000182' 
        LEFT OUTER JOIN (
                         SELECT CompanySeq, Dummy4, 
                         MAX(CONVERT(NVARCHAR,(DATEDIFF(DAY, InDate, GETDATE())/7 + 1)) + '-' + CONVERT(NVARCHAR,((DATEDIFF(DAY, InDate, GETDATE()) % 7) + 1)))    AS MaxWeek
                         FROM join_TPUProducer 
                         WHERE IsNotUse = 0 
                         GROUP BY CompanySeq, Dummy4) AS C ON  B.CompanySeq  = C.CompanySeq 
                                                           AND B.CustName    = C.Dummy4                                                          
  WHERE	 A.CompanySeq      =    @CompanySeq		
    AND  A.STDYM           =    @STDYM                  -- 필수값으로 입력되는거기때문에 where 조건은 [= '' / = 0] 을 주면 안댐
 	AND ( @EggWeightSeq = 0 OR A.EggWeightSeq = @EggWeightSeq ) 
RETURN

