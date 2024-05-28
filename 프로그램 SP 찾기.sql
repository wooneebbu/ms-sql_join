DECLARE @Caption VARCHAR(1000)

SET @Caption = ''   --  프로그램 검색 명 넣기

select DISTINCT A.PgmID, A.Caption, A.PgmSeq, A.timeOut, D.ServiceID, D.ServiceName, F.SqlScriptSeq, Q.SqlScriptID

  from [JOINCommon].[DBO]._TCAPgm As A 
  LEFT OUTER JOIN [JOINCommon].[DBO]._TCAPgmMethod As B ON A.PgmSEq = B.PgmSeq

  LEFT OUTER JOIN [JOINCommon].[DBO]._TCAPgmMethodItem AS C ON A.PgmSEq = C.PgmSeq AND B.PgmMethodSeq = C.PgmMethodSeq
  
  JOIN [JOINCommon].[DBO]._TCAService AS D ON C.ServiceSeq = D.ServiceSeq
  
  LEFT OUTER JOIN [JOINCommon].[DBO]._TCAServiceMethod AS E ON C.ServiceSeq = E.ServiceSeq AND C.MethodSeq = E.MethodSeq
  
  LEFT OUTER JOIN [JOINCommon].[DBO]._TCAServiceMethodKWF AS F ON E.ServiceSeq = F.ServiceSeq AND E.MethodSeq = F.MethodSeq AND F.SqlScriptSeq > 0
  
  LEFT OUTER JOIN [JOINCommon].[DBO]._TCASQLScripts AS Q ON F.SqlScriptSeq = Q.SqlScriptSeq
  
  WHERE A.Caption LIKE '%' + @Caption + '%'
  
  
  --WHERE SqlScriptID like 'joinbio_AntiReactionNoteQuery'