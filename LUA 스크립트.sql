--LUA 스크립트

-- 소숫점 처리
for row = 0,SS1.DataRowCnt -1 do
  --for col = 0, SS1.MaxCols - 1, 1 do

   SS1.ActiveRow = row   -- 현재 로우 숫자
   --SS1.ActiveCol = col   -- 현재 컬럼 숫자
   ProfGubunName = CellText(SS1, row, 'IDNum')
   
    if (aa == '') then
       --MessageBox(ProfGubunName, 'Title', 'MsgBoxTypeOK')
    
    end
   end
end


-- 입추일과 채혈일 함수
InoutDate = CellText(SS1, row, 'InoutDate') 
WorkDate = CellText(SS1, row, 'WorkDate')

if (InoutDate > WorkDate) then
    MessageBox('입추일이 채혈일보다 클 수없습니다', 'Error', 'MsgBoxTypeOK')
end



-- 
ActTimeFr = datActTimeFr.Text
ActTimeTo = datActTimeTo.Text

if  ActTimeFr ~= '' and ActTimeTo ~= '' then
    if string.len(ActTimeFr) ~= 4 or string.len(ActTimeTo) ~= 4 then
        MessageBox('동작시간은 4자리로 입력하세요 ex)1300', '', 'MsgBoxTypeOK')
--MessageBox(ActTimeFr, '', 'MsgBoxTypeOK')
	end

    if tonumber(string.sub(ActTimeFr,3,4)) >= 60 or tonumber(string.sub(ActTimeFr,1,2)) >= 24
        or tonumber(string.sub(ActTimeTo,3,4)) >= 60 or tonumber(string.sub(ActTimeTo,1,2)) >= 24 then
            MessageBox('올바른 시간형식으로 조회해주세요.', '', 'MsgBoxTypeOK')
    end
end



--시작일 

WorkDateFr = datWorkDateFrom.Text
WorkDateTo = datWorkDateTo.Text

if tonumber(string.sub())


--ActTimeFr = txtActTimeFr.Value
--ActTimeTo = txtActTimeTo.Value
--
--if ActTimeFr ~= '' and ActTimeTo ~= '' then
--	if string.len(ActTimeFr) ~= 4 or string.len(ActTimeTo) ~= 4 then
--		MessageBox('동작시간은 4자리로 입력해주세요.', '', 'MsgBoxTypeOK')
--	end
--
--	if tonumber(string.sub(ActTimeFr,3,4)) >= 60 or tonumber(string.sub(ActTimeFr,1,2)) >= 24 or tonumber(string.sub(ActTimeTo,3,4)) >= 60 or tonumber(string.sub(ActTimeTo,1,2)) >= 24 then
--		MessageBox('올바른 시간 형식으로 조회해주세요.', '', 'MsgBoxTypeOK')
--	end
--end
--

InoutDate = CellText(SS1, SS1.ActiveRow, 'InoutDate') 
WorkDate = CellText(SS1, SS1.ActiveRow, 'WorkDate')

if(WorkDate ~= '' and InoutDate ~='') then
	if (InoutDate > WorkDate) then
    	MessageBox('입추일이 채혈일보다 클 수없습니다', 'Error', 'MsgBoxTypeOK')	
	end
end


-- 접수번호랑 채혈일 년도 안맞을때 
for row = 0,SS1.DataRowCnt -1 do
    SS1.ActiveRow = row 
    IDNum = string.sub(CellText(SS1, row, 'IDNum'), 1, 2)
    WorkDate = string.sub(CellText(SS1, row, 'WorkDate'), 3, 4)
    --MessageBox(IDNum, 'IDNum', 'MsgBoxTypeOK')
    --MessageBox(WorkDate, 'WorkDate', 'MsgBoxTypeOK')
    if (IDNum ~= WorkDate) then
        MessageBox('접수번호와 채혈일의 년도가 다릅니다', 'Error', 'MsgBoxTypeOK')
        GoTo('END')
    end
end

-- 항체평균 컬럼 색 입히기 >> 이건 위치로 먹히는거기때문에 컬럼 순서 바뀌면 색 먹히는곳도 바뀜
for col = 0, SS1.MaxCols -1, 1 do
     SS1.ActiveCol = col	 
    	if SS1.ActiveCol == 29 then
				SS1.ActiveColumnStyle = 'fontbold=true; BackColor=Moccasin; Forecolor=Firebrick;'
		end
end



for col = 0, SS1.MaxCols -1, 1 do
     SS1.ActiveCol = col	 
    	if SS1.ActiveColumnName == 'ARAVG' then
				SS1.ActiveColumnStyle = 'fontbold=true; BackColor=Moccasin; Forecolor=Firebrick;'
		end
end


-- 팀장님 색 변경 LUA 

for row = 0,SS1.DataRowCnt -1 do
	--for col = SS1.SheetFixCols, SS1.MaxCols - 1, 1 do 
		SS1.ActiveRow = row
		SS1.ActiveCol = col --col
	
	if SS1.ActiveColumnName == 'DiffDay' then	
			numValue = tonumber(CellText(SS1, row, 'DiffDay'))
	
		if  numValue >= 8 then    
    		SS1.ActiveCellForeColor = -65536	--Red
			SS1.ActiveCellBackColor = -103
			--MessageBoxShow(numValue, 'Title')
		end
	end
end



    row = SS1.ActiveRow
    SampleNum = CellText(SS1, row, 'SampleNum')   
    ARCount00 = CellText(SS1, row, 'ARCount00')
    ARCount01 = CellText(SS1, row, 'ARCount01')
    ARCount02 = CellText(SS1, row, 'ARCount02')
    ARCount03 = CellText(SS1, row, 'ARCount03')
    ARCount04 = CellText(SS1, row, 'ARCount04')
    ARCount05 = CellText(SS1, row, 'ARCount05')
    ARCount06 = CellText(SS1, row, 'ARCount06')
    ARCount07 = CellText(SS1, row, 'ARCount07')
    ARCount08 = CellText(SS1, row, 'ARCount08')
    ARCount09 = CellText(SS1, row, 'ARCount09')
    ARCount10 = CellText(SS1, row, 'ARCount10')
    ARCount11 = CellText(SS1, row, 'ARCount11')
    ARCount12 = CellText(SS1, row, 'ARCount12')
    ARCount13 = CellText(SS1, row, 'ARCount13')
    ARCount14 = CellText(SS1, row, 'ARCount14')
    ARCount15 = CellText(SS1, row, 'ARCount15')

    ARCountSum = (ARCount00 + ARCount01 + ARCount02 + ARCount03 + ARCount04 
                + ARCount05 + ARCount06 + ARCount07 + ARCount08 + ARCount09
                + ARCount10 + ARCount11 + ARCount12 + ARCount13 + ARCount14
                + ARCount15)

    CellText(SS1, row, 'SampleNum') = ARCountSum
   -- if(tonumber(SampleNum) ~= tonumber(ARCountSum)) then -- 숫자로 비교하려고 tonumber 사용
        -- MessageBox('시료수와 항체개수가 일치하지 않습니다.', 'Error', 'MsgBoxTypeOK')
         --MessageBox(SampleNum, 'SampleNum', 'MsgBoxTypeOK')
         --MessageBox(ARCountSum, 'ARCountSum', 'MsgBoxTypeOK')
    --GoTo('END') \
    --end

    MessageBox('IDNum', 'IDNum', 'MsgBoxTypeOK')
    MessageBox('WorkDate', 'WorkDate', 'MsgBoxTypeOK')

row = SS1.ActiveRow

    ARCount00 = CellText(SS1, row, 'ARCount00')
    ARCount01 = CellText(SS1, row, 'ARCount01')
    ARCount02 = CellText(SS1, row, 'ARCount02')
    ARCount03 = CellText(SS1, row, 'ARCount03')
    ARCount04 = CellText(SS1, row, 'ARCount04')
    ARCount05 = CellText(SS1, row, 'ARCount05')
    ARCount06 = CellText(SS1, row, 'ARCount06')
    ARCount07 = CellText(SS1, row, 'ARCount07')
    ARCount08 = CellText(SS1, row, 'ARCount08')
    ARCount09 = CellText(SS1, row, 'ARCount09')
    ARCount10 = CellText(SS1, row, 'ARCount10')
    ARCount11 = CellText(SS1, row, 'ARCount11')
    ARCount12 = CellText(SS1, row, 'ARCount12')
    ARCount13 = CellText(SS1, row, 'ARCount13')
    ARCount14 = CellText(SS1, row, 'ARCount14')
    ARCount15 = CellText(SS1, row, 'ARCount15')
	
    ARCountSum = (ARCount00 + ARCount01 + ARCount02 + ARCount03 + ARCount04 
                          + ARCount05 + ARCount06 + ARCount07 + ARCount08 + ARCount09
        	              + ARCount10 + ARCount11 + ARCount12 + ARCount13 + ARCount14
                          + ARCount15)
	
  SetText(SS1, row, 'SampleNum', ARCountSum)




  --SS1.DefRowHeaderHeight = 25

--Row 색넣기
for row = 0,SS1.DataRowCnt -1 do
        if CellText(SS1, row, 'OrdGB') == '1' then    --실적미입력
            SS1.ActiveRow = row
			for col = 2, SS1.MaxCols - 1, 1 do
				 SS1.ActiveCol = col	-- 현재 컬럼 숫
			 --if SS1.ActiveCol > 2  then
              	--SS1.ColumnControlKey = ';'
              	--SS1.ActiveColumnStyle = 'width = 80;'
				--SS1.ActiveColumnStyle = 'fontSize=12;FontBold=true;'
           --end
            --SS1.ActiveCol = -1   -- 전체 라인
				if SS1.ActiveCol > 1  and SS1.ActiveCol < 10 then
					SS1.ActiveCellForeColor = -65536	--Red
            		SS1.ActiveCellBackColor = -103  -- 노란색
				end
			end
        end
		
		--if CellText(SS1, row, 'OrdGB') == '1' then    --전사 소계
        --    SS1.ActiveRow = row
        --    SS1.ActiveCol = -1   -- 전체 라인
        --    SS1.ActiveCellBackColor = -18751 -- 분홍색
        --end
		
		--if CellText(SS1, row, 'OrdGB') == '20' then    --소계
        --    SS1.ActiveRow = row
        --    SS1.ActiveCol = -1   -- 전체 라인
        --    SS1.ActiveCellBackColor = -2365967  -- 토탈색
        --end
		
		--if CellText(SS1, row, 'OrdGB') == '30' then    --회사계
        --    SS1.ActiveRow = row
        --    SS1.ActiveCol = -1   -- 전체 라인
        --    SS1.ActiveCellBackColor = -1379875  
			
			-- 글자크기 변경(SS1)			
			--SS1.ActiveCellFontName = '돋움'
			--SS1.ActiveCellFontSize = 12
			--SS1.ActiveCellFontBold  = true  -- 글씨 굵게
        --end
end


-- 컬럼 코드헬프 색변경

for row = 0, SS1.DataRowCnt -1 do
	SS1.ActiveRow = row
 	   if CellText(SS1, row, 'ProgressName') == '2000218003' then 
       	 for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellForeColor = -16777216
            SS1.ActiveCellBackColor = -5658199
      	  end
		end	        
    
	if CellText(SS1, row, 'ProgressName') == '2000218001' then
        for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -1
                if SS1.ActiveColumnName == 'ProgressName' then
                    SS1.ActiveCellForeColor = -40121
                end
        end
    end
    if CellText(SS1, row, 'ProgressName') == '2000218002' then
        for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -1
            SS1.ActiveCellForeColor = -16777216
                if SS1.ActiveColumnName == 'RateName' then
                    if CellText(SS1, row, 'RateName') == '2000217001' then
                        SS1.ActiveCellBackColor = -2252579
                    end 
                    if CellText(SS1, row, 'RateName') == '2000217002' then
                        SS1.ActiveCellBackColor = -8689426
                    end 
                    if CellText(SS1, row, 'RateName') == '2000217003' then
                        SS1.ActiveCellBackColor = -6632142
                    end 
                    if CellText(SS1, row, 'RateName') == '2000217004' then
                        SS1.ActiveCellBackColor = -12799119
                    end
                    if CellText(SS1, row, 'RateName') == '2000217005' then
                        SS1.ActiveCellBackColor = -744352
                    end
                    if CellText(SS1, row, 'RateName') == '2000217006' then
                        SS1.ActiveCellBackColor = -10496
                    end
                    if CellText(SS1, row, 'RateName') == '2000217007' then
                        SS1.ActiveCellBackColor = -7278960
                    end
                    if CellText(SS1, row, 'RateName') == '2000217008' then
                        SS1.ActiveCellBackColor = -14774017
                    end
                    if CellText(SS1, row, 'RateName') == '2000217009' then
                        SS1.ActiveCellBackColor = -38476
                    end
                end
        end 
    end
end

-- DummyCheck


for row = 0, SS1.DataRowCnt -1 do
    SS1.ActiveRow = row
    ProgressName = CellText(SS1, row, 'ProgressName')
    RateName = CellText(SS1, row, 'RateName')
    ProDummy = CellText(SS1, row, 'ProDummy')
    ProgressSeq = CellText(SS1, row, 'ProgressSeq') 
        if ProgressName == '2000218003' then
                if RateName ~= '2000217010' then
                    MessageBox('진행률을 100%로 변경해주세요', 'Error', 'MsgBoxTypeOK')
                    SetText(SS1, row, 'ProgressName', ProDummy)
                    SetText(SS1, row, 'ProgressSeq', ProDummy)
                    Go to ('end')
                end 
        end        
end
            --CellText(SS1, SS1.ActiveRow, 'RateName') = CellText(SS1, SS1.ActiveRow, 'RateDummy')     



-----------------------------------------================

ProgressName = CellText(SS1, SS1.ActiveRow, 'ProgressName')
RateName = CellText(SS1, SS1.ActiveRow, 'RateName')
   
if RateName == '2000217010' then
    if ProgressName ~= '2000218003' then
        MessageBox('진행상태를 완료로 변경합니다', 'Message', 'MsgBoxTypeOK')
        SetText(SS1, SS1.ActiveRow, 'ProgressName', 2000218003)              
    end 
end         
 
-- 완료 체크 

if CellText(SS1, SS1.ActiveRow, 'ProgressName') == '2000218003' then
    if CellText(SS1, SS1.ActiveRow, 'RateName') ~= '2000217005' then
        MessageBox('진행률을 100%로 변경해주세요', 'Error', 'MsgBoxTypeOK')
    end 
end
    
if CellText(SS1, SS1.ActiveRow, 'ProgressName') == '2000218002' then
    if CellText(SS1, SS1.ActiveRow, 'RateName') == '2000217005' then
         MessageBox('진행상태가 [진행]입니다 [완료]로변경해주세요', 'Error', 'MsgBoxTypeOK')
    end
end
    
if CellText(SS1, SS1.ActiveRow, 'ProgressName') == '2000218001' then
    if CellText(SS1, SS1.ActiveRow, 'RateName') == '2000217005' then
         MessageBox('진행상태가 [대기]입니다 [완료]로변경해주세요', 'Error', 'MsgBoxTypeOK')
    end
end


-- 그룹웨어 점프
fileURL = 'jini.joinbio.co.kr/app/todo/'..CellText(SSNew, SSNew.ActiveRow,'GWSeq')..'/popup'
if CellText(SSNew, SSNew.ActiveRow,'GWSeq') == '' then 
   msg = '그룹웨어 문서번호가 없습니다.'    
   MessageBox(msg, '', 'MsgBoxTypeOK') 
 else WebOpen(fileURL,1,0) 
 end




 -- 글자크기 변경(SS1)
   if CellText(SS1, SS1.ActiveRow, 'PrjName') ~= '' then
   		for row = 0,SS1.DataRowCnt -1 do
            SetRowHeight(SS1, row, 25) -- 컬럼높이
			for col = 1, SS1.MaxCols - 1, 1 do
        		SS1.ActiveRow = row	-- 현재 로우 숫자
				SS1.ActiveCol = col	-- 현재 컬럼 숫자
				 	 SS1.ActiveCellFontBold  = true  -- 글씨 굵게
			end
		end
   else 
          for row = 0, SS1.MaxRows -1 do0
            SetRowHeight(SS1, row, 25)
		  	for col = 1, SS1.MaxCols - 1, 1 do
	            SS1.ActiveRow = row	-- 현재 로우 숫자
				SS1.ActiveCol = col	-- 현재 컬럼 숫자
					SS1.ActiveCellFontBold  = true  -- 글씨 굵게
			end
	     end
    end




-- 옵션별 화면 control 바꾸기

    if (ChkDetail.Value == '0') then -- 방역팀 화면

		SS1.ActiveColumnName = 'FarmName'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'BreedName'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'SpeciesName'
		SS1.ColumnControlKey = 'DIS;'

        SetControlControlKey('txtInspItemName', '')
		SS1.ActiveColumnName = 'InspItemName'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'InoutDate'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'InoutYY'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg1'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg10'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg20'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg30'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg40'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg50'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg60'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg61'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt1'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt10'
		SS1.ColumnControlKey = 'DIS;'
		
		SS1.ActiveColumnName = 'WeekCnt20'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt30'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt40'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt50'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt60'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt61'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCntSum'
		SS1.ColumnControlKey = 'DIS;'


else -- 계종 연도별 화면 
        SetControlControlKey('txtInspItemName', 'NOQ;')
		SS1.ActiveColumnName = 'FarmName'
		SS1.ColumnControlKey = 'DIS;HID;'

		SS1.ActiveColumnName = 'BreedName'
		SS1.ColumnControlKey = 'DIS;HID;'

		SS1.ActiveColumnName = 'SpeciesName'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'InspItemName'
		SS1.ColumnControlKey = 'DIS;HID;'

		SS1.ActiveColumnName = 'InoutDate'
		SS1.ColumnControlKey = 'DIS;HID;'

		SS1.ActiveColumnName = 'InoutYY'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg1'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg10'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg20'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg30'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg40'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg50'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg60'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg61'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekAvg'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt1'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt10'
		SS1.ColumnControlKey = 'DIS;'
		
		SS1.ActiveColumnName = 'WeekCnt20'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt30'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt40'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt50'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt60'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCnt61'
		SS1.ColumnControlKey = 'DIS;'

		SS1.ActiveColumnName = 'WeekCntSum'
		SS1.ColumnControlKey = 'DIS;'
end


-- column 전체색 변경 
for col = 0, SS1.MaxCols -1, 1 do
     SS1.ActiveCol = col	
        if SS1.ActiveColumnName == 'BreedName' then
				SS1.ActiveColumnStyle = 'BackColor=White;'
		end
        if SS1.ActiveColumnName == 'FarmName' then
				SS1.ActiveColumnStyle = 'BackColor=White; fontname = 돋움;' -- 돋움으로 할때 따옴표 안씀
		end
        if SS1.ActiveColumnName == 'SpeciesName' then
				SS1.ActiveColumnStyle = 'BackColor=White;'
		end
        if SS1.ActiveColumnName == 'InspItemName' then
				SS1.ActiveColumnStyle = 'BackColor=White;'
		end
        if SS1.ActiveColumnName == 'InoutDate' then
				SS1.ActiveColumnStyle = 'BackColor=White;'
		end
        if SS1.ActiveColumnName == 'InoutYY' then
				SS1.ActiveColumnStyle = 'BackColor=White;'
		end
        if SS1.ActiveColumnName == 'WeekCntSum' then
				SS1.ActiveColumnStyle = 'BackColor=MistyRose;'
		end
        if SS1.ActiveColumnName == 'WeekAvg' then
				SS1.ActiveColumnStyle = 'BackColor=MistyRose;'
		end
end


-- 콤보박스 색변경
for row = 0, SS1.DataRowCnt -1 do
	SS1.ActiveRow = row
 	   if CellText(SS1, row, 'ProgressName') == '2000218003' then 
       	 for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellForeColor = -16777216
            SS1.ActiveCellBackColor = -5658199
      	  end
		end	        



--  0.00 > 0 으로만들기 
for row = 0, SS1.DataRowCnt -1 do
    for col = 0, SS1.MaxCols -1, 1 do 
	       SS1.ActiveRow = row 
		   SS1.ActiveCol = col   
           ColName = SS1.ActiveColumnName
       if SS1.ActiveCol > 5 then             
		 if CellText(SS1, row, ColName) == '0' then 
              SS1.ActiveColumnName = ColName
			  SS1.ActiveCellDecimalPlaces = 0 -- 소숫점 없애기
        --else 
        --   SS1.ActiveCellFontBold  = true
         end
       end              
    end 
end 



-- 조회조건으로 입력된 사항 Text로 변환하여 테이블에 입력될수 있도록 하는 LUA
--SetDataColFill(m_SendXml, 'DataBlock1', 'BizUnit', cmbBizUnitName.TextCd)
SetDataColFill(m_SendXml, 'DataBlock1', 'PlanYY', datPlanYY.Text)  
SetDataColFill(m_SendXml, 'DataBlock1', 'SMType', txtSMType.TextCd)
SetDataColFill(m_SendXml, 'DataBlock1', 'UMFactType', cmbFactUnit.TextCd)



-- 전월데이터 버튼 눌렀을때 이전 자료 삭제 된다는 경고창 LUA
local rtnType
 --msg = GetMessage('1012', GetDictionary(1968), '', '', '', '', '', '', '', '', '')
 msg = '이전 자료는 삭제됩니다. 재생성 하시겠습니까?'
 rtnType = MessageBox(msg, '가이드데이터 생성', 'MsgBoxTypeYesNo')
 
 if rtnType == 0 then
 GoTo('END')
 return
 end




 