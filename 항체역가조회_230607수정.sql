
/*************************************************************************************************
    설    명 - 항체역가조회
    작 성 일 - 2022.10.31
    작 성 자 - HHWoon        
 *************************************************************************************************/         
ALTER PROC [dbo].[joinbio_AntiReactionNoteQuery]    
     @ServiceSeq        INT         = 0,          
     @WorkingTag        NVARCHAR(10)= '',          
     @CompanySeq        INT         = 1,          
     @LanguageSeq       INT         = 1,          
     @UserSeq           INT         = 0,          
     @PgmSeq            INT         = 0,        
     @IsTransaction     INT         = 0          
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 여부에 따라 조회속도가 느린 업체가 있어 넣어줌
    SET ANSI_WARNINGS OFF  -- 0나누기 오류
    SET ARITHIGNORE ON 
    SET ARITHABORT OFF
-- 검색조건들 (변수값 조회화면에서 받아오는값)
DECLARE @WorkDateFrom		VARCHAR(10), 	 -- 채혈일FROM
		@WorkDateTo			VARCHAR(10), 	 -- 채혈일TO
		@FarmSeq		    INT,    -- 농장명
        --@InspItemName   NVARCHAR(30)		
        @InoutDateFr        VARCHAR(10),     -- 입추일FROM
        @InoutDateTo        VARCHAR(10),     -- 채혈일TO
        @IDNum              VARCHAR(7),      -- 접수번호
        @WeekCnt            VARCHAR(4),      -- 주령
        @DanDong            NVARCHAR(30),    -- 단지/동명
        @TimeNumSeq         INT,             -- 차수   
        @BreedSeq           INT,             -- 품종
		@InspItemSeq		INT,			 -- 검사항목코드
		@MultiInspItemSeq	NVARCHAR(MAX) 	 -- 멀티검사항목코드 -- 멀티박스 사용시 필요한 변수 2가지

SELECT @WorkDateFrom	   =		ISNULL(WorkDateFrom, ''),	
	   @WorkDateTo	       =		ISNULL(WorkDateTo, ''),	
	   @FarmSeq	           =		ISNULL(FarmSeq, 0),
       --@InspItemName	   =	    ISNULL(InspItemName, '')
       @InoutDateFr        =        ISNULL(InoutDateFr, ''),
       @InoutDateTo        =        ISNULL(InoutDateTo, ''),
       @IDNum              =        ISNULL(IDNum, ''),
       @WeekCnt            =        ISNULL(WeekCnt, ''),
       @DanDong            =        ISNULL(DanDong, ''),
       @TimeNumSeq         =        ISNULL(TimeNumSeq, 0),
       @BreedSeq           =        ISNULL(BreedSeq, 0),
	   @InspItemSeq		   =		ISNULL(InspItemSeq, 0),
	   @MultiInspItemSeq   =		ISNULL(MultiInspItemSeq, '')
	  
	  FROM #BIZ_IN_DataBlock1
	   

	----------------------------------------------------
	---- 멀티 체크관련 
	----------------------------------------------------
	CREATE TABLE #InspItemSeq      -- 검사항목 코드  
     (          
         InspItemSeq     INT          
     )
	 DECLARE @XmlToInspItemSeq  INT          
     SELECT @XmlToInspItemSeq = Code         
       FROM _FCOMXmlToSeq(@InspItemSeq, @MultiInspItemSeq) -- xml문 가져와서 code만 남기고 다른내용 delete해주는 반환함수         
      WHERE IDX_No = 1        
           
     IF ISNULL(@XmlToInspItemSeq, 0) = 0	-- 검사항목 코드를 선택하지 않았을 경우        
     BEGIN                
         INSERT INTO #InspItemSeq SELECT 0 -- 테이블에 회사코드 없을 경우에도 조회                 
     END          
     ELSE          
     BEGIN          
         INSERT INTO #InspItemSeq         
         SELECT Code          
           FROM _FCOMXmlToSeq(@InspItemSeq, @MultiInspItemSeq)          -- 테이블에 회사코드 담아서 가져오기
     END
	 ---------------------------------------------------------


	   INSERT INTO #BIZ_OUT_DataBlock1(    					    -- 서비스구성값
										CompanySeq,		        -- 회사코드
										ARNSeq,			        -- 순서코드(키값)
										IDNum,					-- 접수번호
										IDDate,		            -- 접수날짜
										FarmSeq,				-- 농장코드 (사용자코드)
                                        FarmName,			    -- 농장명
										DanDong,				-- 단지/동명
										DanSeq,					-- 단지코드 (사용자코드)
                                        DanName,	            -- 단지명
										DongSeq,				-- 동코드 (사용자코드)
                                        DongName,			    -- 동명
										TimeNumSeq,             -- 차수코드 (사용자코드)
										TimeNumName,			-- 차수
										BreedSeq,				-- 품종코드 (사용자코드)
										BreedName,				-- 품종명
										--SpeciesSeq,				-- 계종코드 (사용자코드)
										SpeciesName,			-- 계종명
										InOutDate,				-- 입추일
										WorkDate,				-- 채혈일
										InspItemSeq, 			-- 검사항목코드 (사용자코드)
										InspItemName,			-- 검사항목
										InspComplete,			-- 검사완료	(체크박스)
										SampleNum,				-- 시료수
										ARCount00,				-- 항체개수0
										ARCount01,				-- 항체개수1
										ARCount02,				-- 항체개수2
										ARCount03,				-- 항체개수3
										ARCount04,				-- 항체개수4
										ARCount05,				-- 항체개수5
										ARCount06,				-- 항체개수6
										ARCount07,				-- 항체개수7
										ARCount08,				-- 항체개수8
										ARCount09,				-- 항체개수9
										ARCount10, 				-- 항체개수10
										ARCount11,				-- 항체개수11
										ARCount12,				-- 항체개수12
										ARCount13,				-- 항체개수13
										ARCount14,				-- 항체개수14
										ARCount15,				-- 항체개수15
										ARAVG,					-- 항체평균
										LastUserSeq,	        -- 최종수정자코드
										UserName,               -- 최종수정자이름
										LastDateTime,	        -- 최종수정일
                                        DayCnt,					-- 일령
										WeekCnt,				-- 주령
										InoutYY					-- 입추년도
									)
		-- Seq값은 테이블에 생성, Name값은 칸만 생성해서 다른곳에서 조회하기



SELECT 	-- DataBlock1 에 보여지는 DataFieldName 이름이랑 같아야함
		A.CompanySeq,		      							              -- 회사코드
		A.ARNSeq,			        						              -- 순서코드(키값)
		A.IDNum,											              -- 접수번호
		CONVERT(VARCHAR(10), A.IDDate, 120)      AS IDDate,		          -- 접수날짜
		A.FarmSeq,				    						              -- 농장코드 (사용자코드)
        B.MinorName 				             AS FarmName,			  -- 농장명
		A.DanDong,														  -- 단지/동명
		A.DanSeq,					       						          -- 단지코드 (사용자코드)
        C.MinorName  	                         AS DanName,   			  -- 단지명
		A.DongSeq,				           					              -- 동코드   (사용자코드)
        D.MinorName					             AS DongName,			  -- 동명
		A.TimeNumSeq,                      						          -- 차수코드 (사용자코드)
		E.MinorName					             AS TimeNumName,	      -- 차수
		A.BreedSeq,				           						          -- 품종코드 (사용자코드)
		F.MinorName 				             AS BreedName,			  -- 품종명
		--A.SpeciesSeq,				       						          -- 계종코드 (사용자코드)
		G.ValueText                              AS SpeciesName,		  -- 계종명
		CONVERT(VARCHAR(10), A.InOutDate, 120)   AS InOutDate,			  -- 입추일  DATE를 INT형으로 바꿔서 반환하는오류 > CONVERT로 변환
		CONVERT(VARCHAR(10), A.WorkDate, 120)    AS WorkDate,			  -- 채혈일
		A.InspItemSeq, 			           						          -- 검사항목코드 (사용자코드)
		H.MinorName 				             AS InspItemName,		  -- 검사항목
		A.InspComplete,			    						              -- 검사완료	(체크박스)
		A.SampleNum,										              -- 시료수
		A.ARCount00,													  -- 항체개수0
		A.ARCount01,										              -- 항체개수1
		A.ARCount02,										              -- 항체개수2
		A.ARCount03,										              -- 항체개수3
		A.ARCount04,										              -- 항체개수4
		A.ARCount05,										              -- 항체개수5
		A.ARCount06,										              -- 항체개수6
		A.ARCount07,										              -- 항체개수7
		A.ARCount08,										              -- 항체개수8
		A.ARCount09,										              -- 항체개수9
		A.ARCount10, 										              -- 항체개수10
		A.ARCount11,										              -- 항체개수11
		A.ARCount12,										              -- 항체개수12
		A.ARCount13,										              -- 항체개수13
		A.ARCount14,										              -- 항체개수14
		A.ARCount15,										              -- 항체개수15
		( 0*ARCount00 + 1*ARCount01 + 2*ARCount02 + 3*ARCount03 +		  -- 항체평균  (도수분포표 평균 계산) INT형으로 했더니 평균을 DECIMAL(19, 5)로 해도 INT형으로 반환 항체개수의 전체 데이터형식 변환했음
		  4*ARCount04 + 5*ARCount05 + 6*ARCount06 + 7*ARCount07 + 
		  8*ARCount08 + 9*ARCount09 + 10*ARCount10 + 11*ARCount11 +
		 12*ARCount12 + 13*ARCount13 + 14*ARCount14 + 15*ARCount15 )/SampleNum  AS ARAVG,  -- 0 나누기 오류 발생 구간
		A.LastUserSeq,	        							              -- 최종수정자코드
		U.UserName,           							                  -- 최종수정자이름
        CONVERT(VARCHAR(10), A.LastDateTime, 120)  AS LastDateTime,	      -- 최종수정일	
		DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 AS DayCnt,   							     -- DayCnt 일령
        CASE WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 = 1 THEN '1'     				 -- WeekCnt 주령
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 2   AND 70  THEN '~10'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 71  AND 140 THEN '~20'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 141 AND 210 THEN '~30'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 211 AND 280 THEN '~40'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 281 AND 350 THEN '~50'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 351 AND 420 THEN '~60'
			 WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 >= 421 THEN '60~'
			 ELSE '' END AS WeekCnt,	       
        LEFT(CONVERT(VARCHAR(10), A.InOutDate, 120), 4)				AS InoutYY				  													 -- 입추년도

        FROM joinbio_AntiReactionNote AS  A  WITH(NOLOCK) 
		LEFT OUTER JOIN _TDAUMinor    AS  B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
													     AND A.FarmSeq 	  = B.MinorSeq		    -- 밑에 > 사용자코드 설정을 해줘야 시간적으로 빨리처리되기도 하고 오류도 적음
														 AND B.MajorSeq   = '2000209'  		    -- 사용자코드 : 농장명(방역용)_join
		LEFT OUTER JOIN _TDAUMinor    AS  C  WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq	   
														 AND A.DanSeq     = C.MinorSeq		   
														 AND C.MajorSeq   = '2000178'  		    -- 사용자코드 : 농장단지(코드용)_join
		LEFT OUTER JOIN _TDAUMinor    AS  D  WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq	   
														 AND A.DongSeq    = D.MinorSeq		   
														 AND D.MajorSeq   = '2000213'		    -- 사용자코드 : 동명(방역용)_join
		LEFT OUTER JOIN _TDAUMinor    AS  E  WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq	   
														 AND A.TimeNumSeq = E.MinorSeq		   
														 AND E.MajorSeq   = '2000210'		    -- 사용자코드 : 차수(방역용)_join
		LEFT OUTER JOIN _TDAUMinor    AS  F  WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq	   
														 AND A.BreedSeq   = F.MinorSeq		   
														 AND F.MajorSeq   = '2000211'		    -- 사용자코드 : 품종(방역용)_join										 
        LEFT OUTER JOIN _TDAUMinorValue    AS  G  WITH(NOLOCK) ON F.CompanySeq = G.CompanySeq  
															  AND F.MinorSeq   = G.MinorSeq
															  AND G.Serl  = '1000001'			-- 사용자코드 : 품종(방역용)_join > 추가정보정의 ValueText 추가정보정의에 일련번호를 코드로물어옴 
		LEFT OUTER JOIN _TDAUMinor    AS  H  WITH(NOLOCK) ON A.CompanySeq  = H.CompanySeq
														 AND A.InspItemSeq = H.MinorSeq 
														 AND H.MajorSeq    = '2000212'	        -- 사용자코드 : 검사항목(방역용)_join
		LEFT OUTER JOIN _TCAUser      AS  U  WITH(NOLOCK) ON A.CompanySeq  = U.CompanySeq
													     AND A.LastUserSeq = U.UserSeq

WHERE	A.CompanySeq = @CompanySeq		-- 조회조건만 넣어주면 됨
	AND (@DanDong      =    ''  OR   A.DanDong LIKE '%' + @DanDong + '%') -- 이름만 넣으면 검색될수 잇게 기본값 like 설정해줌 
	AND (@IDNum        =    ''  OR   A.IDNum LIKE '%' + @IDNum + '%' ) 
    AND (@FarmSeq      =    0   OR   B.MinorSeq = @FarmSeq)
    AND (@TimeNumSeq   =    0   OR   E.MinorSeq = @TimeNumSeq)
    AND (@BreedSeq     =    0   OR   F.MinorSeq = @BreedSeq)
    AND (@WeekCnt      =    ''  OR   @WeekCnt = CASE WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 = 1 THEN '1' 
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 2   AND 70  THEN '~10'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 71  AND 140 THEN '~20'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 141 AND 210 THEN '~30'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 211 AND 280 THEN '~40'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 281 AND 350 THEN '~50'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 BETWEEN 351 AND 420 THEN '~60'
			                                         WHEN DATEDIFF(dd, CONVERT(VARCHAR(10), A.InOutDate, 120), CONVERT(VARCHAR(10), A.WorkDate, 120))+1 >= 421 THEN '60~'
			                                         ELSE '' END)  -- CASE 앞에 % 붙이고 싶으면 = 지우고 LIKE 로 걸면 됨
    AND (((CONVERT(INT, A.InoutDate) BETWEEN @InoutDateFr AND @InoutDateTo) OR (@InoutDateFr = 0 AND @InoutDateTo = 0))
                                                                            OR (@InoutDateFr = 0 AND (CONVERT(INT, A.InOutDate) <= @InoutDateTo))
                                                                            OR ((@InoutDateFr <= CONVERT(INT, A.InOutDate)) AND @InoutDateTo = 0))
    AND (((CONVERT(INT, A.WorkDate) BETWEEN @WorkDateFrom AND @WorkDateTo) OR (@WorkDateFrom = 0 AND @WorkDateTo = 0))
                                                                           OR (@WorkDateFrom = 0 AND (CONVERT(INT, A.WorkDate) <= @WorkDateTo))
                                                                           OR ((@WorkDateFrom <= CONVERT(INT, A.WorkDate)) AND @WorkDateTo =0)) 
	--AND (@InspItemName = '' OR H.MinorName LIKE @InspItemName + '%')
	/*멀티체크 조건 추가 Start*/  
	AND (EXISTS(SELECT 1                                             --멀티 생산사업장코드  
			    FROM #InspItemSeq     
			    WHERE (InspItemSeq = A.InspItemSeq OR InspItemSeq = 0 )
			     ))       
	/*멀티체크 조건 추가 End*/


RETURN


--숨겨놓는 컬럼은 맨 뒤로 정렬하는게 나중에 엑셀파일 카피앤페이스트 햇을때 오류 안남

										
			 
