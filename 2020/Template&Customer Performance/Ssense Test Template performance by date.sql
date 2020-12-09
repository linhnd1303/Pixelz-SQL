
WITH imgs_steps AS (
SELECT --TOP 10000
DATEPART(Month, dateadd(hour,7,AssignDate)) AS Month_,
"Template's Name",
SawSkillName,
SawSkillId,
iss.ImageID,
WorkingTimeInMilliseconds,
WorkingServicePriceInMiliseconds
FROM ImageSawStep iss
INNER JOIN Images ON (Images.ImageID = iss.ImageID
                     -- AND Images.ContactID=1100814  
                      --AND TemplateID =2161260  
                     )
WHERE dateadd(hour,7,AssignDate) > '2019-03-01'
AND SawSkillName NOT LIKE 'QA %'
  AND WorkerName NOT LIKE 'auto%' AND WorkerName NOT LIKE 'Auto%' AND WorkerName NOT LIKE '%bot%'
  AND "Template's Name" like 'Test template (SSENSE)%'
AND WorkingServicePriceInMiliseconds > 0
)

, rej_count AS (
  SELECT 
  DATEPART(Month, RejectedDatetime) AS Rej_Month_,
  srl.SawSkillID,
  count(srl.ImageID) AS rej_count
  FROM SawRejectionLog srl
  INNER JOIN imgs_steps ON imgs_steps.ImageID = srl.ImageID AND imgs_steps.SawSkillID = srl.SawSkillID
  WHERE ReceiverWorkerID IS NOT NULL -- remove bypass rejections
  AND IsCustomerRejected IS NULL
  GROUP BY
  Rej_Month_,
  srl.SawSkillID
)



, cust_rej_count AS (
  SELECT 
  DATEPART(Month, RejectedDatetime) AS Rej_Month_,
  srl.SawSkillID,
  count(srl.ImageID) AS cust_rej_count
  FROM SawRejectionLog srl
  INNER JOIN imgs_steps ON imgs_steps.ImageID = srl.ImageID AND imgs_steps.SawSkillID = srl.SawSkillID
  WHERE IsCustomerRejected =1
  GROUP BY
  Rej_Month_,
  srl.SawSkillID
)

--SELECT  top 10 * from cust_rej_count

SELECT 
Month_,
--"Template's Name",
SawSkillName,
iss.SawSkillId,
count(DISTINCT iss.ImageID) AS img_count,
rej_count,
round(1.0*rej_count/count(DISTINCT iss.ImageID),4) AS rej_rate,
cust_rej_count,
round(1.0*cust_rej_count/count(DISTINCT iss.ImageID),6) AS cust_rej_rate,

round(1.0*sum(WorkingTimeInMilliseconds*0.001)/3600,2) AS WorkingTime_Hours,
round(1.0*sum(WorkingServicePriceInMiliseconds*0.001)/3600,2) AS WorkingServicePrice_Hours,
round((1.0*sum(WorkingTimeInMilliseconds*0.001)/3600) / (1.0*sum(WorkingServicePriceInMiliseconds*0.001)/3600),2) AS EfficiencyScore

FROM imgs_steps iss
LEFT JOIN rej_count rc ON rc.SawSkillID = iss.SawSkillID AND rc.Rej_Month_ = iss.Month_
LEFT JOIN cust_rej_count crc ON crc.SawSkillID = iss.SawSkillID AND crc.Rej_Month_ = iss.Month_


GROUP BY
Month_,
--"Template's Name",
SawSkillName,
iss.SawSkillId,
rej_count,
cust_rej_count

ORDER BY Month_ DESC, WorkingServicePrice_Hours DESC
LIMIT 10000 OFFSET 0
