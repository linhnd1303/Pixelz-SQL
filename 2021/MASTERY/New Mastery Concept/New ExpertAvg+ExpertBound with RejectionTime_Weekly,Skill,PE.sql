 
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
           CreatedDateTime > '2020-10-01'
          and CreatedDateTime < '2021-12-12'
          and WorkerImageReportStatusID = 10
    --       and ImageID=39168366
    group by ImageID, WorkerImageReport.SawSkillID
    having count(distinct WorkerID) = 1
)
  , img_allSkill as (
    select
      datepart(Week, AssignDate)                                                                   as Week_,
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
      over ( partition by get_onlyone_worker.SawSkillID,Week_
        order by (WorkingTimeInMilliseconds * 0.001) / (WorkingServicePriceInMiliseconds * 0.001) ) as rank_byES
    from get_onlyone_worker
      inner join ImageSawStep on get_onlyone_worker.ImageID = ImageSawStep.ImageID
                                 --         and ImageSawStepID>530000000--4019710
                                 and get_onlyone_worker.SawSkillID = ImageSawStep.SawskillID
                                 and get_onlyone_worker.workerID = ImageSawStep.ProductionWorkerID
                                 and AssignDate > '2020-10-01'
                                 and AssignDate < '2021-12-12'
                                 and WorkingTimeInMilliseconds > 0
                                 and WorkingServicePriceInMiliseconds > 0
      inner join ProductionWorkers on get_onlyone_worker.workerID = ProductionWorkers.workerID
    							 and ProductionWorkers.WorkerName not like '%bot%'
)
  , number_outlier as (
    select
    Week_,
    Sawskillname,
      sawskillID,
      round(0.05 * count(ImageID), 0) as number_outliers,
      count(ImageID)                     Image_count
    from img_allSkill
    group by Week_,sawskillID,Sawskillname
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
   								   and img_allSkill.Week_ = number_outlier.Week_
                                   and img_allSkill.rank_byES > number_outliers
                                   and img_allSkill.rank_byES < Image_count - number_outliers
)
, PE_ES as (
    select
  remmove_outliers.Week_,
      remmove_outliers.SawSkillID,
  remmove_outliers.Sawskillname,
      workerID,
  sum(IPT) as IPT_,
  sum(OPT) as OPT_,
  count(ImageID) Image_count,
  avg(IPT) avg_IPT,
      (sum(IPT) / Sum(OPT)) as ES,
       row_number()
      over ( partition by remmove_outliers.SawSkillID,remmove_outliers.Week_
        order by (sum(IPT) / Sum(OPT)) ) as rank_PEbyES
    from remmove_outliers
    group by remmove_outliers.Week_,remmove_outliers.SawSkillID, remmove_outliers.Sawskillname, workerID
  )
,
NumRankOfExpertsPerSkill as(
  select
  Week_,
  sawskillID,
  Sawskillname,
  count(workerID) as PE_count,
  round(0.1*count(workerID),0) NumRankOfExperts
  from PE_ES
  group by Week_,sawskillID,Sawskillname
  )
--, Boundary as (
   SELECT
      a.Week_,
      a.SawSkillName,
      a.SawSkillID,
      NumRankOfExperts,
--      a.rank_PEbyES,
     sum(a.IPT_)/sum(a.OPT_) As Eff_Score,

      round(avg(CASE WHEN a.rank_PEbyES <= NumRankOfExperts
        THEN ES END), 2) AS Expert_UpperBound_AVG,
      round(avg(CASE WHEN a.rank_PEbyES = NumRankOfExperts
        THEN ES END), 2) AS Expert_UpperBound_Bound

  --    round(Expert_UpperBound*1.3,2) As Mastery_Boundary,
 --     round(Expert_UpperBound*1.5,2) As Pre_mastery_Boundary


    FROM PE_ES a
     INNER JOIN NumRankOfExpertsPerSkill nroeps ON (nroeps.Week_ = a.Week_ AND nroeps.SawSkillID = a.SawSkillID)
 --   Where a.SawSkillName = 'Retouch: Accessories'
    GROUP BY
      a.Week_,
      a.SawSkillName,
      a.SawSkillID,
      NumRankOfExperts
--      a.rank_PEbyES

Order by  month_ DESC, eff_score DESC
--Limit 100 offset 0
--)


 
     
