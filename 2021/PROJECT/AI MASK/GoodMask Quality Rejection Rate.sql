--https://dashboard.rjmetrics.com/v2/client/2863/dashapp/reports/sql/2352627?dashboardId=468666 

WITH ai_imgids AS (
    SELECT 
    ImageID,
  	max(CreatedAt) AS MaxCreatedAt
	FROM AiMaskQualityLogs 
	WHERE dateadd(hour,7,CreatedAt) >= '2019-05-24'
    
	GROUP BY
	ImageID
)
, aimq AS (
  SELECT 
  ai_imgids.ImageID,
  ai_imgids.MaxCreatedAt,
  MaskQualityName,
  sum(CASE WHEN SawSkillID=121 AND ProductionWorkerID IS NOT NULL THEN 1 ELSE 0 END) AS NLM
  FROM AiMaskQualityLogs
  INNER JOIN ai_imgids ON ai_imgids.ImageID = AiMaskQualityLogs.ImageID
  INNER JOIN ImageSawStep iss ON ai_imgids.ImageID = iss.ImageID AND SawSkillID IN (121)
  WHERE AiMaskQualityLogs.CreatedAt = ai_imgids.MaxCreatedAt
  AND MaskQualityName='Good'
  GROUP BY ai_imgids.ImageID,MaskQualityName,MaxCreatedAt
  HAVING sum(CASE WHEN SawSkillID=121 AND ProductionWorkerID IS NOT NULL THEN 1 ELSE 0 END) > 0
)

SELECT TOP 1000
  	  CAST(dateadd(hour,7,aimq.MaxCreatedAt) AS date) AS Date_,
	  aimq.MaskQualityName,
      ROUND(1.0*COUNT(srl.ReceiverWorkerID)/COUNT(DISTINCT aimq.ImageID),4) AS Worker_Rej_Rate,
      COUNT(DISTINCT aimq.ImageID) AS total_worker_img_count,
      COUNT(srl.ReceiverWorkerID) AS worker_rej_count
FROM aimq  		
INNER JOIN SawRejectionLog srl ON srl.ImageID = aimq.ImageID 
WHERE srl.SawSkillID=121
GROUP BY Date_, MaskQualityName

ORDER BY Date_, MaskQualityName ASC



