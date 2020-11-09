
SELECT --TOP 10000
    date(dateadd(hour,7,iss.AssignDate)) as Date_,
    dateadd(hour,7,iss.AssignDate) as date_time,
    SawSkill.SawSkillName,
    ProductionWorkers.WorkerName,
	ProductionWorkers.WorkerEmail,
	ProductionWorkers.EmployeeCode,
	ProductionWorkers.WorkerOfficeName,
	--iss.ImageID,
    t.TemplateName,
	t.TemplateID,
    Contacts.ContactCompany,
    iss.ContactID,
    iss.SawSkillID,
	GlobalSortOrder,
    count(DIStINCT iss.ImageID) AS Img_Count,
    --round(1.0*sum(ImageSawStep.WorkingTimeInMilliseconds*0.001)/count(DIStINCT ImageSawStep.ImageID),1) AS avg_prod_time_per_img,
    round(1.0*sum(iss.WorkingTimeInMilliseconds*0.001)/count(iss.ImageID),1) as avg_ipt,
    round(1.0*sum(iss.WorkingServicePriceInMiliseconds*0.001)/count(iss.ImageID),1) as avg_opt,
    ROUND(1.0*sum(iss.WorkingTimeInMilliseconds)/nullif(sum(iss.WorkingServicePriceInMiliseconds),0),2) AS efficiency_score,
    round(sum(iss.WorkingTimeInMilliseconds*0.001),1) AS sum_ipt_hours,
	round(sum(iss.WorkingServicePriceInMiliseconds*0.001),1) AS sum_opt_hours,

    count(srl.ImageID) AS rej_count --added

FROM ImageSawStep iss
              INNER JOIN ProductionWorkers ON  ProductionWorkers.WorkerID = iss.ProductionWorkerID
              INNER JOIN SawSkill ON SawSkill.SawSkillID = iss.SawSkillID
              INNER JOIN Images ON Images.ImageID = iss.ImageID
              INNER JOIN Templates t ON t.TemplateName=iss."Template Name" AND iss.ContactID=t.ContactID AND t.TemplateDeleted <> 1
              INNER JOIN Contacts ON Contacts.ContactID=iss.ContactID
              FULL OUTER JOIN SawRejectionLog srl ON srl.SawSkillID = iss.SawSkillID  and srl.ImageID = iss.ImageID

WHERE
		dateadd(hour,7,iss.AssignDate) > date_trunc('Week', getdate()) - INTERVAL '24 Weeks'
        AND t.ContactID=1160192 -- Ssense Customer ID
              --AND  t.TemplateName like 'Test template (SSENSE)%'  -- Ssense Test Template
              --AND ImageSawStep.ImageID > 33100000 -- greater than ~June 2019
              --AND ImageSawStep.SawSkillID = 10 -- Footwear
        AND SawSkill.SawSkillName NOT LIKE 'QA G%'
        AND ProductionWorkers.WorkerName NOT LIKE 'auto%'
      --  AND ReceiverWorkerID IS NOT NULL -- remove bypass rejections
       -- AND IsCustomerRejected IS NULL


GROUP BY
Date_,
date_time,
SawSkill.SawSkillName,
ProductionWorkers.WorkerName,
ProductionWorkers.WorkerEmail,
ProductionWorkers.EmployeeCode,
ProductionWorkers.WorkerOfficeName,
	--iss.ImageID,
t.TemplateName,
t.TemplateID,
Contacts.ContactCompany,
iss.ContactID,
iss.SawSkillID,
GlobalSortOrder


ORDER BY date_ desc
LIMIT 10000 OFFSET 0 
