 
with get_onlyone_worker as (
    select
      ImageID,
      WorkerImageReport.SawSkillID,
      avg(WorkerID)               workerID,
      --sum(RuntimeInMiliSecond * 0.001) as IPT,
      count(distinct WorkerID) as count_PE
    from WorkerImageReport
      inner join SawSkill on SawSkill.SawSkillID=WorkerImageReport.SawSkillID
      and SawSkillKindID=0
    and --SawSkillID =167
           CreatedDateTime >= '2020-12-06'
          and CreatedDateTime <= '2021-06-09'
          and WorkerImageReportStatusID = 10
    --       and ImageID=39168366
    group by ImageID, WorkerImageReport.SawSkillID
    having count(distinct WorkerID) = 1
)
  , img_allSkill as (
    select
to_char(dateadd(hour, 7, AssignDate), 'YYYY') + '-' + RIGHT('W0' + CAST(DATEPART(week, AssignDate) AS varchar(2)), 2) 	as Month_,
       AssignDate,
      get_onlyone_worker.workerID,
      ProductionWorkers.WorkerName,
      Sawskillname,
      ImageSawStep.ImageID,
      get_onlyone_worker.SawSkillID,
      WorkingTimeInMilliseconds * 0.001                                                             as IPT,
      WorkingServicePriceInMiliseconds * 0.001                                                      as OPT,
      (WorkingTimeInMilliseconds * 0.001) / (WorkingServicePriceInMiliseconds * 0.001)              as Efficiency_score,
      row_number()
      over ( partition by get_onlyone_worker.SawSkillID,Month_
        order by (WorkingTimeInMilliseconds * 0.001) / (WorkingServicePriceInMiliseconds * 0.001) ) as rank_byES
    from get_onlyone_worker
      inner join ImageSawStep on get_onlyone_worker.ImageID = ImageSawStep.ImageID
                                 --         and ImageSawStepID>530000000--4019710
                                 and get_onlyone_worker.SawSkillID = ImageSawStep.SawskillID
                                 and get_onlyone_worker.workerID = ImageSawStep.ProductionWorkerID
                                 and AssignDate >= '2020-12-06'
                                 and AssignDate <= '2021-06-09'
                                 and WorkingTimeInMilliseconds > 0
                                 and WorkingServicePriceInMiliseconds > 0
      inner join ProductionWorkers on get_onlyone_worker.workerID = ProductionWorkers.workerID
    							 and ProductionWorkers.WorkerName not like '%bot%'
)
  , number_outlier as (
    select
    Month_,
    Sawskillname,
      sawskillID,
      round(0.05 * count(ImageID), 0) as number_outliers,
      count(ImageID)                     Image_count
    from img_allSkill
    group by Month_,sawskillID,Sawskillname
)
 , remmove_outliers as (
    select
      img_allSkill.*,
      number_outliers,
      Image_count
--       row_number()
--       over ( partition by img_allSkill.SawSkillID
--         order by Efficiency_score, IPT ) as rank_byES_2
    from img_allSkill
      inner join number_outlier on img_allSkill.sawskillid = number_outlier.SawskillID
   								   and img_allSkill.Month_ = number_outlier.Month_
                                   and img_allSkill.rank_byES > number_outliers
                                   and img_allSkill.rank_byES < Image_count - number_outliers
)
, PE_ES as (
    select
  remmove_outliers.Month_,
      remmove_outliers.SawSkillID,
  remmove_outliers.Sawskillname,
      workerID,
  count(ImageID) Image_count,
  sum(IPT) as total_IPT,
  sum(OPT) as total_OPT,
  avg(IPT) avg_IPT,
      (sum(IPT) / Sum(OPT)) as ES,
       row_number()
      over ( partition by remmove_outliers.SawSkillID,remmove_outliers.Month_
        order by (sum(IPT) / Sum(OPT)) ) as rank_PEbyES
    from remmove_outliers
    group by remmove_outliers.Month_,remmove_outliers.SawSkillID, remmove_outliers.Sawskillname, workerID
  )
, skill_mastery as(
  select
  Month_,
  sawskillID,
  Sawskillname,
  count(workerID) as PE_count,
  round(0.25*count(workerID),0) number_Master,
  round(0.50*count(workerID),0) number_Pre_Master,
  count(workerID)-(round(0.25*count(workerID),0)+round(0.5*count(workerID),0))number_Bottom
  from PE_ES
--where sawskillid=10
  group by Month_,sawskillID,Sawskillname
  )
select
skill_mastery.Month_ as Week_,

skill_mastery.sawskillID,

skill_mastery.Sawskillname,

PE_ES.workerID,
"WorkerName",
"WorkerOfficeName",
Image_count,
avg_IPT,
PE_ES.total_IPT,
PE_ES.total_OPT,

ES
--case when PE_ES.rank_PEbyES<=number_Master then 'Master'
--when PE_ES.rank_PEbyES>number_Master and PE_ES.rank_PEbyES<=(number_Master+number_Pre_Master) then 'Pre-Master'
--when PE_ES.rank_PEbyES>(number_Master+number_Pre_Master) then 'Bottom' end as matery_level
--sum(case when PE_ES.rank_PEbyES=number_Pre_Master then PE_ES.ES end) as Pre_mastery_zone
--PE_ES2.ES as Pre_mastery_zone
from  PE_ES inner join skill_mastery on skill_mastery.sawskillID=PE_ES.sawskillID
and skill_mastery.Month_=PE_ES.Month_
--and skill_mastery.sawskillID=10
inner join Productionworkers on Productionworkers.workerID=PE_ES.WorkerID
Order by Week_ DESC
--group by 1,2
