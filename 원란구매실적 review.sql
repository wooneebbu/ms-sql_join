DECLARE @StdYM   		VARCHAR(6)     --  ���ؿ���
      , @StdYMBF   		VARCHAR(6)	   --  ���ؿ�������(�̿� Lot ���ܺ� Ȯ�ο�)
      , @PreYM   		VARCHAR(6)	   --  �񱳿���
      , @PreYMBF   		VARCHAR(6)	   --  �񱳿�������(�̿� Lot ���ܺ� Ȯ�ο�)
	  , @FactUnit		INT			  --  ���������ڵ�
	  , @MultiFactUnit	VARCHAR(2000) --  ��Ƽ���������ڵ�
      , @FactUnitName	VARCHAR(200)  --  ��������
      , @CalcUnit		INT			  --  ������
      , @MatLSeq		INT			  --  �����з�(�׷�)�ڵ�
      , @MatLName		VARCHAR(20)	  --  �����з�(�׷�)
      , @MultiMatLSeq 	NVARCHAR(30)  --  ��Ƽ�����з�(�׷�)�ڵ�  
      , @MatMSeq		INT			  --  �����ߺз�(����)�ڵ�
      , @MatMName		VARCHAR(20)	  --  �����ߺз�(����) 
      , @MatSSeq		INT			  --  ����Һз�(�߷�)�ڵ�
      , @MatSName		VARCHAR(20)	  --  ����Һз�(�߷�)



SET @StdYM = 202407
SET @PreYM = 202307


SET @StdYMBF =  REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @StdYM+'01'), 23), '-', '') -- before stdym���� �Ѵ� ��
SET @PreYMBF =  REPLACE(CONVERT(VARCHAR(7), DATEADD(Month, -1, @PreYM+'01'), 23), '-', '')




SELECT @StdYM, @PreYM, @StdYMBF, @PreYMBF