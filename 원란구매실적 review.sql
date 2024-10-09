DECLARE @StdYM   		VARCHAR(6)     --  기준연월
      , @StdYMBF   		VARCHAR(6)	   --  기준연월전월(이월 Lot 내외부 확인용)
      , @PreYM   		VARCHAR(6)	   --  비교연월
      , @PreYMBF   		VARCHAR(6)	   --  비교연월전월(이월 Lot 내외부 확인용)
	  , @FactUnit		INT			  --  생산사업장코드
	  , @MultiFactUnit	VARCHAR(2000) --  멀티생산사업장코드
      , @FactUnitName	VARCHAR(200)  --  생산사업장
      , @CalcUnit		INT			  --  계산단위
      , @MatLSeq		INT			  --  원료대분류(그룹)코드
      , @MatLName		VARCHAR(20)	  --  원료대분류(그룹)
      , @MultiMatLSeq 	NVARCHAR(30)  --  멀티원료대분류(그룹)코드  
      , @MatMSeq		INT			  --  원료중분류(난색)코드
      , @MatMName		VARCHAR(20)	  --  원료중분류(난색) 
      , @MatSSeq		INT			  --  원료소분류(중량)코드
      , @MatSName		VARCHAR(20)	  --  원료소분류(중량)



SET @StdYM = 202407
SET @PreYM = 202307


SET @StdYMBF =  REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @StdYM+'01'), 23), '-', '') -- before stdym에서 한달 뺌
SET @PreYMBF =  REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @PreYM+'01'), 23), '-', '')




SELECT @StdYM, @PreYM, @StdYMBF, @PreYMBF