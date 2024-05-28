
 for col = 0,  SS1.MaxCols - 1, 1 do
     SS1.ActiveCol = col	-- 현재 컬럼 숫자
   
     ColHeadName = SS1.ColumnTitle                                         -- 칼럼 헤더의 Dynamic Text 가져오기
     ColName          = string.sub(SS1.ActiveColumnName, 1 , 3)  -- 칼럼 헤더의 이름 가져오기
   
     CHLen  = string.len(ColHeadName)     -- 칼럼 헤더의 Dynamic Text 길이 가져오기 끝자리 비교용
     -- CNLen  = string.len(ColName)
  
     MatchName = string.sub(ColHeadName, CHLen-1 , CHLen)
  
     if ColName == 'Qty' and MatchName == '월' then
         if Month_Ckb.Value == '1' then
  	       SS1.ColumnControlKey =';'
  	     else 
  		   	SS1.ColumnControlKey ='HID;'   
  	     end
	 elseif 	 ColName == 'Qty' and MatchName == '주' then
	     if Week_Ckb.Value == '1' then
  	       SS1.ColumnControlKey =';'
  	     else 
  		   	SS1.ColumnControlKey ='HID;'   
  	     end
	 elseif 	 ColName == 'Qty' and (MatchName ~= '월' and MatchName ~= '주') then
	     if Day_Ckb.Value == '1' then
  	       SS1.ColumnControlKey =';'
  	     else 
  		   	SS1.ColumnControlKey ='HID;'   
  	     end
		 
     end 
	   
end	
	



 for col = 0,  SS2.MaxCols - 1, 1 do
     SS2.ActiveCol = col  	-- 현재 컬럼 숫자
   
     ColHeadName = SS2.ColumnTitle                                         -- 칼럼 헤더의 Dynamic Text 가져오기
     ColName          = string.sub(SS2.ActiveColumnName, 1 , 3)  -- 칼럼 헤더의 이름 가져오기 / 한글은 2개로 침 / Qty00 ~ Qty99 
   
     CHLen  = string.len(ColHeadName)     -- 칼럼 헤더의 Dynamic Text 길이 가져오기 끝자리 비교용 
     -- CNLen  = string.len(ColName)
  
     MatchName = string.sub(ColHeadName, CHLen-1 , CHLen) -- 끝에서 두자리 (한글 월/주) 매치
  
     if ColName == 'Qty' and MatchName == '월' then
         if Month_Ckb.Value == '1' then
  	       SS2.ColumnControlKey ='DIS;'
  	     else 
  		   	SS2.ColumnControlKey ='HID;DIS;'   
  	     end
	 elseif 	 ColName == 'Qty' and MatchName == '주' then
	     if Week_Ckb.Value == '1' then
  	       SS2.ColumnControlKey ='DIS;'
  	     else 
  		   	SS2.ColumnControlKey ='HID;DIS;'   
  	     end
	 elseif 	 ColName == 'Qty' and (MatchName ~= '월' and MatchName ~= '주') then
	     if Day_Ckb.Value == '1' then
  	       SS2.ColumnControlKey ='DIS;'
  	     else 
  		   	SS2.ColumnControlKey ='HID;DIS;'   
  	     end
		 
     end 
	   
end	
	