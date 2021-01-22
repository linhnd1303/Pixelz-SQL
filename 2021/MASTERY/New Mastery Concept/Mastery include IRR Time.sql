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
           CreatedDateTime > '2020-12-01'
          and CreatedDateTime < '2021-08-01'
          and WorkerImageReportStatusID = 10
    --       and ImageID=39168366
    group by ImageID, WorkerImageReport.SawSkillID
    having count(distinct WorkerID) = 1
    
    -- Return ImageID,SawSkillID, Workder ID, Count_dist_PE
    -- Lấy ID ảnh điều kiện 1 PE làm.
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
                                 and AssignDate > '2020-12-01'
                                 and AssignDate < '2021-08-01'
                                 and WorkingTimeInMilliseconds > 0
                                 and WorkingServicePriceInMiliseconds > 0
      inner join ProductionWorkers on get_onlyone_worker.workerID = ProductionWorkers.workerID
    							 and ProductionWorkers.WorkerName not like '%bot%'
    							 
    -- Lấy Month, assgindate, Worker ID, Worker Name, Skill, ImageiD, IPT, OPT, ES, RankbyES
    -- Lấy các thông tin từ bảng get_onlyone_worker
    
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
    
    -- Trả về số lượng outlier 5% của mỗi skill.
    
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
                                   
    -- Trả về thông tin ảnh đã remove outlier của skill đó. % đầu và % cuối
    
)
, PE_ES as (
   	 		select
  				remmove_outliers.Week_,
      			remmove_outliers.SawSkillID,
  				remmove_outliers.Sawskillname,
     			workerID,
  				count(ImageID) Image_count,
  				avg(IPT) avg_IPT,
  				avg(OPT) avg_OPT,
  				sum(IPT) as Sum_IPT,
  				sum(OPT) as Sum_OPT,
      			(sum(IPT) / Sum(OPT)) as ES,
       			row_number()
      			over ( partition by remmove_outliers.SawSkillID,remmove_outliers.Week_
        			order by (sum(IPT) / Sum(OPT)) ) as rank_PEbyES
    		from remmove_outliers
    		group by remmove_outliers.Week_,remmove_outliers.SawSkillID, remmove_outliers.Sawskillname, workerID
    
    -- Trả về Rank lại PE ES mới sau khi đã Remove Outlier
    
)
, skill_mastery as(
  select
  Week_,
  sawskillID,
  Sawskillname,
  count(workerID) as PE_count,
  round(0.10*count(workerID),0) number_Expert,   -- linhnd: add number of expert.
  round(0.10*count(workerID)*1.3,0) number_Master,  -- linhnd: Expert + 130%
  round(0.10*count(workerID)*1.5,0) number_Pre_Master,
  count(workerID)-(round(0.10*count(workerID),0) + round(0.10*count(workerID)*1.3,0) + round(0.10*count(workerID)*1.5,0)) number_Bottom   --linhnd: adjust
  from PE_ES
--where sawskillid=10
  group by Week_,sawskillID,Sawskillname
  
  -- Trả về số lượng Expert,master,premaster,bottom từ bản PE ES đã remove outlier
  
  )
select
	skill_mastery.Week_,
	skill_mastery.sawskillID,
 	skill_mastery.Sawskillname,
	PE_ES.workerID,
	"WorkerName","WorkerOfficeName",
	Image_count,
	avg_IPT,
  	avg_IPT,
  	avg_OPT,
  	Sum_IPT,
  	Sum_OPT,
	ES,
	case    when PE_ES.rank_PEbyES<=number_Expert then 'Expert'
        	when PE_ES.rank_PEbyES>number_Expert and PE_ES.rank_PEbyES<=number_Master then 'Master'
        	when PE_ES.rank_PEbyES>number_Master and PE_ES.rank_PEbyES<=(number_Master+number_Pre_Master) then 'Pre-Master'
       		when PE_ES.rank_PEbyES>(number_Master+number_Pre_Master) then 'Bottom' end as matery_level
            --sum(case when PE_ES.rank_PEbyES=number_Pre_Master then PE_ES.ES end) as Pre_mastery_zone
            --PE_ES2.ES as Pre_mastery_zone

from  PE_ES inner join skill_mastery on skill_mastery.sawskillID	=	PE_ES.sawskillID
									and skill_mastery.Week_		=	PE_ES.Week_
			inner join Productionworkers on Productionworkers.workerID	=	PE_ES.WorkerID
										--and skill_mastery.sawskillID=10
										--group by 1,2

Order by skill_mastery.Week_

Limit 10000 offset 0
