/******************************************************************************************
** Name: DAD Mastery KPIs plus Expert-in-level last many weeks 
** Desc:
** Auth: Shan mod by Linhnd
** Onwer: 
** Created_at: 2019-08-03
**************************
** Change History
**************************
** PR	Date 		Author		Description
** --	--------	-------		------------------------------------
** 2	2020-10-26	linhnd		add step 521 new garment 
** 1	2020-10-21	linhnd		Ceate for RJmetric
*******************************************************************************************/


WITH Global_Imgs AS (
    SELECT
      ImageID,
      ProductionWorkerID,
      "Worker Name",
      JoinedDate,
      pw.WorkerOfficeName,
      SawSkillName,
      SawSkillID,
      dateadd(hour, 7, AssignDate) AS AssignDate_UTC7,
      to_char(dateadd(hour, 7, AssignDate), 'IYYY') + '-W' + to_char(dateadd(hour, 7, AssignDate), 'IW') 	as Week_,
      iss.WorkingTimeInSeconds                                                AS IPT_secs,
      iss.WorkingServicePriceInMiliseconds * 0.001                            AS ExpectedIPT_secs
    FROM ImageSawStep iss
  	INNER JOIN ProductionWorkers pw ON pw.WorkerID = iss.ProductionWorkerID
    WHERE dateadd(hour, 7, AssignDate) >= date_trunc('Week', getdate()) - INTERVAL '12 Weeks'
          AND iss.WorkingServicePriceInMiliseconds > 0
          AND "Worker Name" NOT LIKE 'Freel%'
          AND "Worker Name" NOT LIKE 'Auto%'
          AND "Worker Name" NOT LIKE 'auto%'
          AND "Worker Name" NOT LIKE '%demo%'
          AND "Worker Name" NOT LIKE '% Bot %'
          AND "Worker Name" NOT LIKE '%test%'
          AND "Worker Name" NOT LIKE '%dev%'
  		  
          AND SawSkillID IN (
            121, --NLM
            5,   --Retouch Shape
            43,  --Adv Path
            479, --New Adv Path
            44,  --Background Retouch
            160, --Path&Mask
            9,   --Retouch: Model
            22,  --Shadow Natural
            29,  --Finalize
            10,  --Retouch: Footwear
            6,   --Retouch 3D
            65,  --AutoStencil
            40,  --AdvMask
            46,  --Burberry
            16,  --Color Adjustment
            13,  --Retouch Accessories
            14,  --Retouch Cosmetics
            3,   --Retouch Skin Processing
            8,   --Garments 1
            74,  --Garments 2
            75,  --Garments 3
			521, --New Garment 
            128, --Combination
            120, --New Path
            70,  --Stencil Manual
            303, --McQueen
            47,  --Recreate Details
            1,   --Preparation
            434, --ComplexMask
            328, --NEWLOOK
            23,  --Shadow Cast
            12,  --Retouch Furniture
            133, --Generic Retouch
            131, --Background Extension
            11,  --Retouch Jewelry
            430, --Garment Retouch
            313, --The Flash
            167, --Bumblebee
            304, --Mater
            168, --Optimus
            15,  --Color Change
            39,  --General Retouch
            21,  --Shadow Reflection
            333, --Orendt
            20,  --Shadow Drop
            26,  --Texture Replacement
            444, --Model Retouch
            145, --Select Style
            435, --TJX
            452, --TJX01
            455, --TJX02
            330, --VPE Background Extension (editors only)
            461, --RetouchShape & 3D
            326, --Subjectivity
            490, --CD General
            491, --CD Lululemon
            198, --Fix
            135, --Photo Correction
            337, --Stencil Manual X
            458, --Color Matching
            461, --Retouch Shape&3D
            480, --Ralph Lauren
            488, --RL REC
            484, --RL REC 1
            486, --RL REC 2
            426, --IHS Other
            438, --Nike
            439  --Fossil
    ))

, rej_img_ids AS (

    SELECT DISTINCT
      srl.ImageID,
      srl.SawSkillID,
  	  srl.ReceiverWorkerID,
      gi.Week_,
      gi.WorkerOfficeName

    FROM SawRejectionLog srl
      INNER JOIN Global_Imgs gi ON (gi.SawSkillID = srl.SawSkillID AND gi.ImageID = srl.ImageID
                                     AND gi.Week_ = to_char(dateadd(hour, 7, RejectedDatetime), 'IYYY') + '-W' +
                                                            to_char(dateadd(hour, 7, RejectedDatetime), 'IW')
                                    AND gi.ProductionWorkerID = srl.ReceiverWorkerID
                                   )
WHERE RejectedDatetime >= date_trunc('Week', getdate()) - INTERVAL '12 weeks'
          AND isnull(IsCustomerRejected, 0) = 0
)

, rej_img_by_skills AS (

    SELECT
Week_,
rii.SawSkillID,
count (rii.ImageID) AS rej_img_count,
count (CASE WHEN WorkerOfficeName = 'Da Nang Office' THEN rii.ImageID END) AS rej_img_count_DN,
count (CASE WHEN WorkerOfficeName = 'My Dinh Office' THEN rii.ImageID END) AS rej_img_count_HN,
count (CASE WHEN WorkerOfficeName = 'bZm Graphics' THEN rii.ImageID END) AS rej_img_count_bzm,
count (CASE WHEN WorkerOfficeName = 'Cambodia Office' THEN rii.ImageID END) AS rej_img_count_DDD
FROM rej_img_ids rii
    GROUP BY
Week_,
rii.SawSkillID
)

, rej_counts_per_worker AS (
  SELECT 
    Week_,
    ReceiverWorkerID,
    SawSkillID,
    WorkerOfficeName,
    count(ImageID) AS rej_img_count
  FROM rej_img_ids
  GROUP BY
    Week_,
    ReceiverWorkerID,
    SawSkillID,
    WorkerOfficeName
)

, filtered_imgs AS (

 SELECT
gi.*,
rej.ImageID AS rejImageID
FROM Global_Imgs gi
LEFT JOIN rej_img_ids rej on (rej.ImageID = gi.ImageID AND rej.SawSkillID = gi.SawSkillID AND gi.ProductionWorkerID = rej.ReceiverWorkerID)
WHERE rejImageID IS NULL
  --AND wt.Week_ = '2019-W06'
)

 , Worker_Stats AS (
    SELECT
      --TOP 10000
      filtered_imgs.Week_,
      SawSkillName,
      filtered_imgs.SawSkillID,
      ProductionWorkerID                                    AS WorkerID,
      "Worker Name",
      JoinedDate,
      filtered_imgs.WorkerOfficeName,
      round(avg(IPT_secs),2)                                         as avg_ipt,
      round(avg(ExpectedIPT_secs),2)                                 as avg_ExpectedIPT,
      count(ImageID)                                        AS img_count,
      round(sum(IPT_secs), 2)                               AS sum_IPT_secs,
      round(sum(ExpectedIPT_secs), 2)                       AS sum_ExpectedIPT_secs,
      rej_img_count,
      round(1.0 * rej_img_count / (rej_img_count + count(filtered_imgs.ImageID)),4) AS rej_rate,
      round(1.0 * sum(IPT_secs) / nullif(sum(ExpectedIPT_secs), 0), 5) AS efficiency_on_sums
    FROM filtered_imgs
    INNER JOIN rej_counts_per_worker ON (rej_counts_per_worker.Week_=filtered_imgs.Week_ 
                               AND rej_counts_per_worker.ReceiverWorkerID=filtered_imgs.ProductionWorkerID
                               AND rej_counts_per_worker.SawSkillID = filtered_imgs.SawSkillID
                              )
    GROUP BY
      filtered_imgs.Week_,
      ProductionWorkerID,
      "Worker Name",
      JoinedDate,
      --OfficeId,
      filtered_imgs.WorkerOfficeName,
      SawSkillName,
      filtered_imgs.SawSkillID,
      rej_img_count
) -- Returns unique month and workerID and SkillID


, Editor_Ranks_unfiltered AS (
    SELECT
      Worker_Stats.*,
      RANK()
      OVER ( PARTITION BY SawSkillID, Week_
        ORDER BY efficiency_on_sums ASC ) AS rank_ipt_to_opt
    FROM Worker_Stats
) -- Returns unique Month and WorkerID

, Editor_Ranks AS (
    SELECT
      Worker_Stats.*,
      RANK()
      OVER ( PARTITION BY SawSkillID, Week_
        ORDER BY efficiency_on_sums ASC ) AS rank_ipt_to_opt
    FROM Worker_Stats
    -- Weekly Img Count Minimums				
WHERE img_count >=				
			CASE	
				WHEN SawSkillID IN (15,439,426) THEN 5
				WHEN SawSkillID IN (6,11,47,434,521) THEN 15  --add 521 New Garment 
				WHEN SawSkillID IN (12,14,20,21,23,39,40,43,46,70,120,128,160,167,303,328,198,452,455,480,486) THEN 25
				WHEN SawSkillID IN (13,5,10,16,44,121,133,304,461,135,458,484) THEN 50
				WHEN SawSkillID IN (1,22,29,65,337,430,444) THEN 125
				ELSE 50
			END	
) -- Returns unique Month and WorkerID

, NumRankOfExpertsPerSkill AS (
    SELECT
      --TOP 9000
      Week_,
      SawSkillName,
      SawSkillID,
      SUM(img_count),
      CEILING(0.10 * count(rank_ipt_to_opt)) AS NumRankOfExperts
    FROM Editor_Ranks
    GROUP BY
      Week_,
      SawSkillName,
      SawSkillID
) -- Returns unique Month and WorkerID

, SMZ_UpperBounds AS (
    SELECT
      --TOP 9000
      a.Week_,
      a.SawSkillName,
      a.SawSkillID,
      NumRankOfExperts,

      round(avg(CASE WHEN rank_ipt_to_opt <= NumRankOfExperts
        THEN efficiency_on_sums END) + 0.3, 2) AS SkillMasteryZone_UpperBound,
        
        	round(avg(CASE WHEN rank_ipt_to_opt <= NumRankOfExperts
        THEN efficiency_on_sums END) , 2) AS SkillExpertZone_UpperBound

    FROM Editor_Ranks a
      INNER JOIN NumRankOfExpertsPerSkill nroeps ON (nroeps.Week_ = a.Week_ AND nroeps.SawSkillID = a.SawSkillID)
    GROUP BY
      a.Week_,
      a.SawSkillName,
      a.SawSkillID,
      NumRankOfExperts
)

, editor_ranks_with_smz AS (
    SELECT
      eru.Week_,
      eru.SawSkillName,
      eru.SawSkillID,
      eru.WorkerID,
      eru."Worker Name",
      eru.JoinedDate,
      eru.WorkerOfficeName,
      eru.avg_ipt,
      eru.avg_ExpectedIPT,
      eru.img_count,
      eru.sum_IPT_secs,
      eru.sum_ExpectedIPT_secs,
      eru.rej_img_count,
      eru.rej_rate,
      eru.efficiency_on_sums AS efficiency_score,
      smz.SkillMasteryZone_UpperBound,
  eru.efficiency_on_sums -	smz.SkillMasteryZone_UpperBound  AS Distance_from_mastery,
  	  CASE 
            WHEN efficiency_on_sums<=SkillExpertZone_UpperBound THEN 'Expert'
            WHEN efficiency_on_sums<=SkillMasteryZone_UpperBound THEN 'Master'
  	  	   WHEN (efficiency_on_sums>SkillMasteryZone_UpperBound AND efficiency_on_sums<=(SkillMasteryZone_UpperBound+0.2)) THEN 'Premaster'
   		   WHEN efficiency_on_sums>(SkillMasteryZone_UpperBound+0.2) THEN 'Bottom'
  		ELSE NULL
  	  END AS Mastery_Level,
      eru.rank_ipt_to_opt AS global_efficiency_rank
    FROM Editor_Ranks_unfiltered eru 
    INNER JOIN SMZ_UpperBounds smz ON (smz.Week_=eru.Week_ 
                                               AND smz.SawSkillID=eru.SawSkillID)
)


SELECT TOP 10000 * 
FROM editor_ranks_with_smz 
WHERE WorkerOfficeName LIKE 'D%'
ORDER BY "Worker Name", SawSkillID, Week_--, rank_ipt_to_opt
