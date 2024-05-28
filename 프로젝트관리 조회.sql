USE [JOINDEV]
GO
/****** Object:  StoredProcedure [dbo].[joinbio_AntiReactionNoteQuery]    Script Date: 2022-11-09 오후 3:13:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
    설    명 - 프로젝트관리_조회
    작 성 일 - 2023.03.23
    작 성 자 - HHWoon        
 *************************************************************************************************/         
ALTER PROC [dbo].[joinbio_PrjManageQuery]    
     @ServiceSeq        INT         = 0,          
     @WorkingTag        NVARCHAR(10)= '',          
     @CompanySeq        INT         = 1,          
     @LanguageSeq       INT         = 1,          
     @UserSeq           INT         = 0,          
     @PgmSeq            INT         = 0,        
     @IsTransaction     INT         = 0          
AS


-- 검색조건들 (변수값 조회화면에서 받아오는값)
DECLARE @WorkDateFrom      VARCHAR(10),           -- 시작일From
        @WorkDateTo        VARCHAR(10),           -- 시작일To
        @ProgressSeq       INT,                   -- 진행상태
        @PrjName           NVARCHAR(100)          -- 프로젝트명

SELECT @WorkDateFrom            =		ISNULL(WorkDateFrom, ''),	
	   @WorkDateTo	            =		ISNULL(WorkDateTo, ''),
       @ProgressSeq	            =	    ISNULL(ProgressSeq, 0),
	   @PrjName                 =		ISNULL(PrjName, '')


	   FROM #BIZ_IN_DataBlock1
	  INSERT INTO #BIZ_OUT_DataBlock1(    					    -- 서비스구성값
							CompanySeq,                         -- 회사코드
                            GWSeq,                              -- 그룹웨어주소, 숫자6자리
                            PrjSeq,                             -- 프로젝트 넘버 (Identity)
                            PrjName,                            -- 프로젝트이름
                            PrjGubunName,                       -- 진행상태
                            PrjGubunSeq,                        -- 진행상태Seq
                            PrjPurpose,                         -- 프로젝트목적
                            WorkDate,                           -- 시작일
                            DueDate,                            -- 완료예정일
                            EndDate,                            -- 실제종료일
                            PrjDept,                            -- 주관부서
                            -- PrjDeptSeq,
                            RateName,                           -- 진행률
                            RateSeq,                            -- 진행률seq
                            AdminUser,                          -- 운영자
                            -- AdminSeq,                    
                            ProgressName,                       -- 진행상태
                            ProgressSeq,                        -- 진행상태Seq
                            PrjIssue,                           -- 특이사항
                            Remark,                             -- 비고 
                            LastUserName,                       -- 최근사용자
                            LastUserSeq,      
                            LastDateTime
									)
		-- Seq값은 테이블에 생성, Name값은 칸만 생성해서 다른곳에서 조회하기

SELECT 	-- DataBlock1 에 보여지는 DataFieldName 이름이랑 같아야함
                            A.CompanySeq,
                            A.GWSeq,
                            A.PrjSeq,         
                            A.PrjName,            
                            B.MinorName         AS PrjGubunName,          
                            A.PrjGubunSeq, 
                            A.PrjPurpose,
                            A.WorkDate,
                            A.DueDate,              
                            A.EndDate,                  
                            A.PrjDept,              
                            -- A.PrjDeptSeq,
                            C.MinorName         AS RateName,
                            A.RateSeq,               
                            A.AdminUser,                  
                            -- A.AdminSeq,              
                            D.MinorName         AS ProgressName,
                            A.ProgressSeq,             
                            A.PrjIssue,          
                            A.Remark,      
                            U.UserName,
                            A.LastUserSeq,      
                            CONVERT(VARCHAR(10), A.LastDateTime, 120)  AS LastDateTime
        FROM joinbio_Prjmanager              AS  A  WITH(NOLOCK)
        LEFT OUTER JOIN _TDAUMinor           AS  B  WITH(NOLOCK) ON A.CompanySeq   = B.CompanySeq	   
														        AND A.PrjGubunSeq  = B.MinorSeq		   
														        AND B.MajorSeq     = '2000216'		    -- 사용자코드 : 과제구분(프로젝트)_join
        LEFT OUTER JOIN _TDAUMinor           AS  C  WITH(NOLOCK) ON A.CompanySeq   = C.CompanySeq	   
														        AND A.RateSeq      = C.MinorSeq		   
														        AND C.MajorSeq     = '2000217'		    -- 사용자코드 : 진행률(프로젝트)_join
        LEFT OUTER JOIN _TDAUMinor           AS  D  WITH(NOLOCK) ON A.CompanySeq   = D.CompanySeq	   
														        AND A.ProgressSeq  = D.MinorSeq		   
														        AND D.MajorSeq     = '2000218'		    -- 사용자코드 : 진행(프로젝트)_join
        LEFT OUTER JOIN _TCAUser             AS  U  WITH(NOLOCK) ON A.CompanySeq  = U.CompanySeq
													            AND A.LastUserSeq = U.UserSeq
WHERE	 A.CompanySeq      =    @CompanySeq		-- 조회조건만 넣어주면 됨 -- INT 값으로 받아야하고 K-Studio에서 Seq설정 꼭 해야함 (조회 안될때는 test SP생성 후 where절 하나씩 지우면서 확인해볼것) 
    AND (@ProgressSeq      =    0    OR   A.ProgressSeq   =  @ProgressSeq)
	AND (@PrjName          =    ''   OR   A.PrjName       LIKE '%' + @PrjName      + '%') -- 이름만 넣으면 검색될수 잇게 기본값 like 설정해줌
	AND (((CONVERT(INT, A.WorkDate) BETWEEN @WorkDateFrom AND @WorkDateTo) OR (@WorkDateFrom = 0 AND @WorkDateTo = 0))
                                                                          OR (@WorkDateFrom = 0 AND (CONVERT(INT, A.WorkDate) <= @WorkDateTo))
                                                                          OR ((@WorkDateFrom <= CONVERT(INT, A.WorkDate)) AND @WorkDateTo =0))  -- between 조건으로 from ~ to 설정 
ORDER BY ProgressSeq, RateSeq ASC
RETURN

-- 핸드폰 번호 NVARCHAR()로 설정하고 MULTITEXT설정은 NVARCHAR(4000)으로 K-STUDIO는 -1로 설정하고 MULTITEXT로 설정하기 
-- 처음 TEST할때는 모든 컬럼 다 채워보고 오류가 무엇인지 확인해봐야한다 (개인적으로 먼저)
-- 숫자 관련해서는 더 정확하고 오류없도록 신중을 기해서 개발할것 
-- type을 모두 맞춰줘야하고 /int > float, 코드는 float으로 , where절까지 맞춰줘야함
-- acttime > 지금 숫자로 검색되는 조건절 더 맞춰야함  
-- 디버깅 조회조건 안될때 > SP에 where 절 하나하나 값을 물어오는지 확인할것 
-- 루아 조건으로 from ~ to 조회조건 from 값이 to 값보다 크지 않도록 


									
			 