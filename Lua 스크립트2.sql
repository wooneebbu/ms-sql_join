-- > save


-- 다이나믹 SP 작동 전에 DataBlock3 활용할 조회조건, 타 시트 등에 있는 값 강제로 DataBlock3에 세팅

-- 다이나믹 헤더를 데이터로 활용시 ChangeDataFieldName 활용
-- TITLE_IDX0_SEQ => TitleSeq 값 ex) 20231001 > STDYMD 값으로 사용 
ChangeDataFieldName(m_SendXml.Data, 'DataBlock3', 'TITLE_IDX0_SEQ', 'STDYMD')

-- 코드헬프 값 활용시 코드값은 Control.Value, 네임값은 Control.Text 활용
SetDataColFill(m_SendXml, 'DataBlock3', 'STDYM', txtSTDYM.Value)
SetDataColFill(m_SendXml, 'DataBlock3', 'EggWeight', txtEggWeight.Text) 
SetDataColFill(m_SendXml, 'DataBlock3', 'EggWeightSeq', txtEggWeight.Value)




-- > cut
-- 다이나믹 SP 작동 전에 DataBlock3 활용할 조회조건, 타 시트 등에 있는 값 강제로 DataBlock3에 세팅

-- 다이나믹 헤더를 데이터로 활용시 ChangeDataFieldName 활용
-- TITLE_IDX0_SEQ => TitleSeq 값 ex) 20231001 > STDYMD 값으로 사용 
ChangeDataFieldName(m_SendXml.Data, 'DataBlock3', 'TITLE_IDX0_SEQ', 'STDYMD')

-- 코드헬프 값 활용시 코드값은 Control.Value, 네임값은 Control.Text 활용
SetDataColFill(m_SendXml, 'DataBlock3', 'STDYM', txtSTDYM.Value)
SetDataColFill(m_SendXml, 'DataBlock3', 'EggWeight', txtEggWeight.Text) 
SetDataColFill(m_SendXml, 'DataBlock3', 'EggWeightSeq', txtEggWeight.Value)



-->simulation
local rtnType
 --msg = GetMessage('1012', GetDictionary(1968), '', '', '', '', '', '', '', '', '')
 msg = '이전 자료는 삭제됩니다. 재생성 하시겠습니까?'
 rtnType = MessageBox(msg, '가이드데이터 생성', 'MsgBoxTypeYesNo')
 
 if rtnType == 0 then
 GoTo('END')
 return
 end



 --> click
 txtCustName.Text = CellText(SS1, SS1.ActiveRow, 'CustName')
--SetDataColFill(m_SendXml, 'DataBlock5', 'CustName', txtCustName.Text ) 

RunPgmMethod('SS2_Query');



-->ss2_query


-- label 색변경
lbl01.Foreground = GetBrush("Red")
lbl02.Foreground = GetBrush("Red")


-- 필드 고정 (필드 헤더 클릭 시에도 정렬 안됨)
SS1. IsColumnSortingSkip = true
SS2. IsColumnSortingSkip = true




-- 지역별 색깔 구분
local Check = 0

for col = 0, SS1.MaxCols - 1, 1 do
SS1.ActiveCol = col	-- 현재 컬럼 숫자

for row = 0, SS1.DataRowCnt -1 do
	
	Region = CellText(SS1, row, 'Region')
	
	if CellText(SS1, row - 1 , 'Region') ~= Region then
		Check = Check +1
	end
	
	if Region == '평균' then
		Check = 0
	end
	
	if Check % 2 == 0  and col > 1 then
		SS1.ActiveRow = row
	    --SS1.ActiveCol = -1   -- 전체 라인
	    SS1.ActiveCellBackColor = -1379875 -- 쑥색
	end
end
end


for row = 0,SS1.DataRowCnt -1 do
	for col = 0, SS1.MaxCols - 1, 1 do
		
		SS1.ActiveRow = row	-- 현재 로우 숫자
	    SS1.ActiveCol = col	-- 현재 컬럼 숫자
		
		Region = CellText(SS1, row, 'Region')
		
		--'지역'이 '평균'일 경우 행 전체 노랑색 음영 표시
        if Region == '평균' and col >1 then
            SS1.ActiveRow = row
            --SS1.ActiveCol = -1   -- 전체 라인
            SS1.ActiveCellBackColor = -103  -- 연노랑
        end
	
	end
end


-- 거래처별 색깔 구분
local Check = 0

for col = 0, SS2.MaxCols - 1, 1 do
SS2.ActiveCol = col	-- 현재 컬럼 숫자

for row = 0, SS2.DataRowCnt -1 do
	
	CustTypeName = CellText(SS2, row, 'CustTypeName')
	
	if CellText(SS2, row - 1 , 'CustTypeName') ~= CustTypeName then
		Check = Check +1
	end
	
	if CustTypeName == '평균' then
		Check = 0
	end
	
	if Check % 2 == 0  and col > 0 then
		SS2.ActiveRow = row
	    --SS2.ActiveCol = -1   -- 전체 라인
	    SS2.ActiveCellBackColor = -1379875 -- 쑥색
	end
end
end


-- 소계 행 음영처리
for row = 0,SS2.DataRowCnt -1 do
	for col = 0, SS2.MaxCols - 1, 1 do
		
		SS2.ActiveRow = row	-- 현재 로우 숫자
	    SS2.ActiveCol = col	-- 현재 컬럼 숫자
		
		CustTypeName = CellText(SS2, row, 'CustTypeName')
		
		--'거래처'가 '평균'일 경우 행 전체 초록색 음영 표시
        if CustTypeName == '평균' and col >0 then
            SS2.ActiveRow = row
            --SS2.ActiveCol = -1   -- 전체 라인
            SS2.ActiveCellBackColor = -103  -- 연노랑
        end
	
	end
end





-- 지역별 색깔 구분

local Check = 0

for col = 0, SS2.MaxCols -1, 1 do
SS2.ActiveCol = Col
-- SS2.ActiveCellStyle = 'HorizontalAlignment=center; VerticalAlignment = center;'

 for row = 0 , SS2.DataRowCnt -1 do
 Cust = CellText (SS2, row, 'Cust')

	if CellText(SS2, row -1, 'Cust') ~= Cust then
		Check = Check + 1
	end
	
	if Cust == '평균' then
		Check = 0 
	end
	
	if Check % 2 == 0 and Col > 0 then
		SS2.ActiveRow = Row
		SS2.ActiveCellBackColor = -663885
	end	
 end
end	
 




 for row = 0, SS1.DataRowCnt -1 do
	SS2.ActiveRow = row
 	   if CellText(SS2, row, 'Cust') == '평균' then 
       	 for col = 2, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -18751
      	  end
	   end

	   if CellText(SS2, row, 'Cust') == '내부' then 
       	 for col = 2, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -7278960
      	  end
	   end

	    if col > -1 and col <4 then 
       	 for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellStyle = 'HorizontalAlignment = center; VerticalAlignment = center;' 
      	  end
	   end
end	   







 for row = 0, SS1.DataRowCnt -1 do
	SS2.ActiveRow = row
 	   if CellText(SS2, row, 'Region') == '평균' then 
       	 for col = 1, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -18751
      	  end
	   end
 end
	   if CellText(SS2, row, 'Cust') == '내부' then 
       	 for col = 2, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellBackColor = -7278960
      	  end
	   end

	    if col > -1 and col <4 then 
       	 for col = 0, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col
            SS1.ActiveCellStyle = 'HorizontalAlignment = center; VerticalAlignment = center;' 
      	  end
	   end
end	   




 for row = 0, SS2.DataRowCnt -1 do
	SS2.ActiveRow = row	 	   
	 
	 for col = 0,  SS2.MaxCols -1,1 do
            SS2.ActiveCol = col
 
 	   if CellText(SS2, row, 'Cust') == '평균'  and col > 1 then 
            SS2.ActiveCellBackColor = -18751
      	  end
	
	   if CellText(SS2, row, 'Cust') == '내부'  and col > 1   then
            SS2.ActiveCellBackColor = -663885
      	  end
		  	 
	   if col >= 0 and col  < 4 then
	       SS2.ActiveCellHorizontalAlignment  = 2 
	   end
	
     end
 end	  



 
 for row = 0, SS1.DataRowCnt -1 do
	SS2.ActiveRow = row

      for col = 1, SS1.MaxCols -1, 1 do
            SS1.ActiveCol = col

 	     if CellText(SS2, row, 'Region') == '평균' then 
            SS1.ActiveCellBackColor = -18751
      	 end

		 if col >= 0 and col  < 4 then
	       SS2.ActiveCellHorizontalAlignment  = 2 
	     end
      end

 end



  for row = 0, SS2.DataRowCnt -1 do
	SS2.ActiveRow = row	 	   
	 
	 for col = 0,  SS2.MaxCols -1,1 do
            SS2.ActiveCol = col
 
	 -- 갈색란 색 입히기 / 백색란 색 입히기 
       if (CellText(SS2, row, 'EggColor') == '갈색란'  and SS2.ActiveColumnName == 'EggColor') then
			SS2.ActiveCellBackColor = -2180985
	   elseif (CellText(SS2, row, 'EggColor') == '백색란'  and SS2.ActiveColumnName == 'EggColor') then
			SS2.ActiveCellBackColor = -657956
	   elseif(CellText(SS2, row, 'Cust') == '평균'  and col > 2) then 
            SS2.ActiveCellBackColor = -256
	   elseif (CellText(SS2, row, 'Cust') == '내부'  and col > 2)   then
            SS2.ActiveCellBackColor = -2302756
       else
            SS2.ActiveCellBackColor = -1
       END
	 -- 필드 중간 정렬
	   if col >= 0 and col  < 5 then
	       SS2.ActiveCellHorizontalAlignment  = 2 
	   end

     end
 end	 




 
  for row = 0, SS1.DataRowCnt -1 do
	SS1.ActiveRow = row	 	   
	 
	 for col = 0,  SS1.MaxCols -1,1 do
            SS1.ActiveCol = col
 
 	   if (CellText(SS1, row, 'Region') == '평균'  and col > 1) then 
            SS1.ActiveCellBackColor = -256
       else
            SS1.ActiveCellBackColor = -1
       end

	   if col >= 0 and col  < 4 then
	       SS1.ActiveCellHorizontalAlignment  = 2 
	   end

     end
 end	 