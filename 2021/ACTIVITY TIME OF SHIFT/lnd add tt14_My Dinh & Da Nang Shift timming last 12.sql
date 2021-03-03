/******************************************************************************************
** Name: IPT Shift timing (PS table)
** Desc: Ha Noi, Da Nang
** Auth: An Pham
** Onwer: Mr.Vu Production
** Created_at: 2019-09-15
**************************
** Change History
**************************
** PR   Date        Author  Description
** --   --------   -------   ------------------------------------
** 1    2019-09-15 An Pham      Create for RJmetric
** 2 	2020-02-27	Thu			Update Have_Meal 
*******************************************************************************************/
with _ as (
    select
--            dateadd(hour, -7, '2019-07-28 06:15:00') as start_,
--            dateadd(hour, -7, '2019-09-01 06:15:00') as end_,
           dateadd(month, -12, date_) as start_,
           dateadd(month,  1, date_) as end_,
           7*60 - mins_ as shifted_
    from (select dateadd(hour, -7, dateadd(minute, mins_, dateadd(day, 25, date_trunc('month',
                 current_date - 0/*SUA NGAY THANG TAI DAY*/)))) as date_, * from (select 60*6 + 15 as mins_))
), filter_worker AS (
    SELECT DISTINCT
      ProductionWorkers.WorkerID,
      ProductionWorkers.WorkerName,
      CASE WHEN ProductionWorkerRoles.WorkerRoleID = 8 THEN 999 ELSE
      CASE WHEN (lower(ProductionWorkers.WorkerName) LIKE 'auto%' OR
                 lower(ProductionWorkers.WorkerName) LIKE '% bot %') THEN 998
      ELSE ProductionWorkers.WorkerOfficeID END END AS PEGroupID
    FROM ProductionWorkers
      JOIN ProductionWorkerRoles ON ProductionWorkerRoles.WorkerID = ProductionWorkers.WorkerID
                                    AND ProductionWorkerRoles.WorkerRoleID IN (3, 8, 33)
                                    AND lower(ProductionWorkers.WorkerName) NOT LIKE '%demo%'
                                    AND lower(ProductionWorkers.WorkerName) NOT LIKE '%test%'
                                    AND lower(ProductionWorkers.WorkerName) NOT LIKE '%dev%'
), PEGroup AS (
    SELECT
      _.PEGroupID,
      isnull(_.PEGroupName, '') + isnull('_' + Office.OfficeName, '') AS PEGroupName
    FROM (          SELECT 2  , '1'
          UNION ALL SELECT 3  , '3'
          UNION ALL SELECT 4  , '2'
          UNION ALL SELECT 8  , '4'
          UNION ALL SELECT 990, '2_Da Nang Looklet Worker'
          UNION ALL SELECT 996, '1_My Dinh Looklet Team Ho Thi Ha'
          UNION ALL SELECT 998, '6_AutoBot'
          UNION ALL SELECT 999, '5_Freelancer') AS _ (PEGroupID, PEGroupName)
      FULL OUTER JOIN Office ON _.PEGroupID = Office.OfficeID
), team as (
    select
      ProductionWorkers.PlanningGroupID,
      min(WorkerName) as TeamName
    from ProductionWorkers
      join ProductionWorkerRoles
        on isnull(ProductionWorkers.WorkerIsLocked, 0) = 0
        and ProductionWorkerRoles.WorkerRoleID = 9 /*Team Leader*/
        and ProductionWorkers.WorkerID = ProductionWorkerRoles.WorkerID
    group by ProductionWorkers.PlanningGroupID

),ActivityType(MappedTypeID, TypeName) as (
                SELECT 110  , '1_IPT'
      UNION ALL SELECT 1    , '2_Break'
      UNION ALL SELECT 7    , '3_NoAssignedImage'
      UNION ALL SELECT 411  , '4_Others_'
      UNION ALL SELECT 1312 , '5_Browser_'
      UNION ALL SELECT -1   , '6_IDLE'
      UNION ALL SELECT 514  , '7_Skype_'
      UNION ALL SELECT 10   , '1__FullAutoPostProcessingTime'
      UNION ALL SELECT 2    , '9_TrainingMeetingTime'
      UNION ALL SELECT 3    , '9_TrainingMeetingTime'
      UNION ALL SELECT 4    , '9_TrainingMeetingTime'
      UNION ALL SELECT 310  , 'a_Explorer_'
      UNION ALL SELECT 1001 , 'b_WorkingTool_'
      UNION ALL SELECT 1013 , 'b_IDLE_'
      UNION ALL SELECT 6    , 'd_NoDownloadedImage'
      UNION ALL SELECT 5    , 'e_WorkingOnBrowser'
      UNION ALL SELECT 9    , 'f_WaitForDownloading'
      UNION ALL SELECT 8    , 'g_SystemErrorTime'
      UNION ALL SELECT 1091 , 'l_HaveMeal'
  	  UNION ALL SELECT 1093 , 'l_ref_HaveMeal'
      UNION ALL SELECT 1092 , 'l_Logout'
  	  UNION ALL SELECT 14	, '1__SemiPostProcessingTime'
      UNION ALL SELECT 7116 , '1__IPTAndPostProcessing'
      UNION ALL SELECT 7117 , '1__IPTAndPostProcessingWorkOnBrowser'

), ActivityLog AS (
    SELECT
      CASE WHEN (isnull(ImageID, 0) > 0 AND (EditorClientLoginTypeID = 0 OR ActivityTimeTypeID = 0)) THEN 110 ELSE
      CASE WHEN ActivityTimeTypeID in (7, 1, 9, 10, 6, 5, 2, 3 ,4, -1, 8, 14) THEN ActivityTimeTypeID ELSE
      CASE WHEN ActivityTimeTypeID!= 12 AND (
        (UPPER(ApplicationName) LIKE '%PHOTO EDITOR CLIENT%'
        	  OR UPPER(ApplicationName) LIKE 'PHOTOEDITORCLIENT%'
       		  OR UPPER(ApplicationName) LIKE 'PIXELZEDITORCLIENT%'
      		  OR UPPER(ApplicationName) LIKE '%CALC%'
      		  OR UPPER(ApplicationName) LIKE 'CHROME%' 
      		  OR UPPER(ApplicationName) LIKE 'GOOGLE CHROME%'
      			     OR ApplicationName LIKE 'Photoshop'
        			 OR ApplicationName LIKE 'Adobe Photoshop C%'
        			 OR ApplicationName LIKE 'Lightshot'
         			 OR ApplicationName LIKE 'Notepad'
        			 OR ApplicationName LIKE 'Notepad++%%'
        			 OR ApplicationName LIKE 'Snipping Tool'
        			 OR ApplicationName LIKE 'Sticky Notes'
        			 OR ApplicationName LIKE '7-Zip GUI'
        			 OR ApplicationName LIKE 'WinRAR'
        			 OR ApplicationName LIKE 'Adobe Bridge CC%'
        			 OR ApplicationName LIKE 'Microsoft Excel'
        	  OR lower(ApplicationName) LIKE '%stemain.exe%'
        		OR lower(ApplicationName) IN ('stemain', 'ste', 'ste launcher')
        	  OR lower(ApplicationName) LIKE '%smooth_path%' 
                															   )) THEN 1001 ELSE --'WorkingTool'

      CASE WHEN ActivityTimeTypeID!= 12 AND ((UPPER(ApplicationName) LIKE '%SKYPE%')) THEN 514 ELSE --'Skype'

      CASE WHEN ActivityTimeTypeID!= 12 AND ((UPPER(ApplicationName) LIKE 'IDLE%')) THEN 1013 ELSE --'IDLE'

	    CASE WHEN ActivityTimeTypeID!= 12 AND ((UPPER(ApplicationName) LIKE '%EXPLORER%')) THEN 310 ELSE --'EXPLORER'

      CASE WHEN ActivityTimeTypeID!= 12 AND (
        (UPPER(ApplicationName) LIKE 'COCCOC%' OR
				 UPPER(ApplicationName) LIKE 'COC COC%' OR
				 UPPER(ApplicationName) LIKE 'INTERNET EXPLORER%' OR
				 UPPER(ApplicationName) LIKE '%FIREFOX%' OR
        		 UPPER(ApplicationName) LIKE '%BRAVE%' OR
                        ApplicationName LIKE 'UC Browser' OR
                        ApplicationName LIKE 'Opera Internet Browser' OR
				 UPPER(ApplicationName) LIKE 'BROWSER%')) THEN 1312 ELSE--1312 'BROWSER'
  	  CASE WHEN ActivityTimeTypeID= 12 then 1093 -- ref_haveMeal
  		ELSE 411 -- 411 others
      END END END END END END END END AS MappedTypeID,
      WorkerID,
      RuntimeInMiliSecond as timing,
      ClientTimeReportAt as time_at
    FROM ActivityApplicationRunningTimeLogs
    join _ ON start_ <= ClientTimeReportAt AND ClientTimeReportAt < end_

), logout_log as (
    select
      *,
      LEAD(time_at, 1) OVER ( PARTITION BY WorkerID ORDER BY time_at ) as after_event_at_
    from ( SELECT WorkerID, time_at, NULL as type_ FROM ActivityLog
           union all
           select
             LogoutRequest.WorkerID,
             LogoutRequest.RequestDatetimeUtc,
             LogoutRequest.LogoutReasonID
           from LogoutRequest
           join _ ON start_ <= RequestDatetimeUtc AND RequestDatetimeUtc < end_
         ) _
), logout_timing as (
    select
      case when type_ = 7 /*Have meal*/ then 1091 else 1092 end as MappedTypeID,
      WorkerID,
      datediff(millisecond, time_at, after_event_at_) as timing,
      time_at
    from logout_log
    where type_ is not null and type_ != 6 /*End shift*/

),have_meal_tab as(
  select
  --1901 as MappedTypeID,
  WorkerID,
  datediff(millisecond, StartAt, FinishAt) as timing,
  StartAt as time_at
  from WorkerMeals
  join _ ON start_ <= StartAt AND StartAt < end_
  ), time_shift as (
    select *,
           dateadd(minute, shifted_, cast(time_at as datetime)) as time_shift
    from (SELECT * FROM ActivityLog
          UNION ALL SELECT * FROM logout_timing
          UNION ALL SELECT 1091 as MappedTypeID, WorkerID, timing, time_at FROM have_meal_tab
          UNION ALL SELECT 7116 as MappedTypeID, WorkerID, timing, time_at FROM ActivityLog where MappedTypeID in (110, 10, 14)  -- lnd add
          UNION ALL SELECT 7117 as MappedTypeID, WorkerID, timing, time_at FROM ActivityLog where MappedTypeID in (110, 10, 5, 14)  --lnd add
         ) __,_
), timing AS (
    select
      cast(time_shift as date)       as time_frame,
      datepart(hour, time_shift) / 8 as shiftID,
      WorkerID,
      MappedTypeID,
      sum(timing)                    AS timing
    from time_shift
--     where MappedTypeID in (110, 7, 10, 5, 9)
    group by
      cast(time_shift as date),
      datepart(hour, time_shift) / 8,
      WorkerID,
      MappedTypeID

), RegisterShift as (
    select
      EndShiftReports.WorkerID,
      cast(ShiftStartDateLocalTime as date)       as date_,
      datepart(hour, dateadd(second, -1, ShiftStartDateLocalTime)) / 8 as shiftID,
      ProductionWorkers.WorkerName as TeamShift,
      1 as isRegisterShift
    from EndShiftReports
    left join ProductionWorkers on ProductionWorkers.WorkerID = EndShiftReports.LeaderID
    join _ ON dateadd(hour, 7, start_) <= ShiftStartDateLocalTime AND ShiftStartDateLocalTime < dateadd(hour, 7, end_)

), NormalShift AS (
    select
      cast(time_shift as date)       as date_,
      datepart(hour, time_shift) / 8 as shiftID,
      WorkerID,
      dateadd(hour, datepart(hour, time_shift) / 8 * 8, cast(time_shift as date)) as shift_start,
      min(time_shift) AS min_, max(time_shift) as max_, 1 as isNormalShift
    from time_shift
    group by
      cast(time_shift as date),
      datepart(hour, time_shift) / 8,
      WorkerID

), exclude_PE as (
    select WorkerID from ProductionWorkers where WorkerID not in (
            1634  /*Hồ Văn Đường LL*/
      , 1645  /*Lương Thị Kiều Trang LL	*/
      , 2113  /* Le Qui Thong LL */
      , 1644  /* Luu Cong Anh LL */
      , 982    /*Lê Thị Thanh Loan LL	*/
      , 2023  /* Le Dinh Hoang LL */
      , 1637  /* Mai Hung Sang LL */
      , 980    /* Nguyen Thi Thu Trang LL */
      , 1639  /* Pham Ngoc Dinh LL */
      , 1890  /* Tran Thi Phuong LL */
      , 2736  /* Tran Thi To Linh LL */
      , 1649  /* Dinh Thi Trinh LL */
      , 1027  /* Tran Thi Ngoc Anh LL */
      , 1640  /* Vo Thi Kim Anh LL */
      , 1031  /* Tran Thi Thuy Nhung LL */
      , 2307  /* Tran Le Thu */
      , 2191 /* Giang Thị Thanh Hiền	*/
      , 1922 /*Ngô Văn Quyết	*/
      , 1808 /*Nguyễn Văn Huân	*/
      , 2192 /*Nguyễn Thị Hồng*/
      , 1831  /* Nguyen Thi Bich Hong */
      , 1939  /* Ngo Thanh Xuan */
      , 1443  /* Nguyen Thi Huong Giang 3 */
      , 1925  /* Tran Thi Huong */
      , 3258  /* Nguyen Trong Hieu */
      , 3644  /* Cao Thi Phuong Thao */
      , 4201 /* Nguyễn Bá Hợp*/
        )
), ps_table as (
    SELECT
      time_frame, timing.shiftID, filter_worker.PEGroupID,
             timing.MappedTypeID, isnull(NormalShift.isNormalShift, 0) as isNormalShift,
      sum(timing) as timing, count(filter_worker.WorkerID) as number_editor
    FROM timing
    JOIN filter_worker ON filter_worker.WorkerID = timing.WorkerID
    JOIN exclude_PE on exclude_PE.WorkerID = timing.WorkerID
    LEFT JOIN ProductionWorkers on ProductionWorkers.WorkerID = timing.WorkerID
    LEFT JOIN team on team.PlanningGroupID = ProductionWorkers.PlanningGroupID
    LEFT JOIN NormalShift on NormalShift.date_ = timing.time_frame
                               and NormalShift.shiftID = timing.shiftID
                               and NormalShift.WorkerID = timing.WorkerID
                               and datediff(minute, NormalShift.shift_start, NormalShift.min_) < 1*60
                               and datediff(minute, NormalShift.shift_start, NormalShift.max_) > 7*65
    group by time_frame, timing.shiftID, filter_worker.PEGroupID,
             timing.MappedTypeID, isnull(NormalShift.isNormalShift, 0)
)
SELECT
  time_frame                                             as date_,
  substring('1_AM2_PM3_NI', (timing.shiftID) * 4 + 1, 4) AS shift_,
  PEGroup.PEGroupName                                    AS Office,
  isNormalShift,
  number_editor,
  --timing.*,
  ActivityType.TypeName                                  AS ActivityType,
  0.001 * timing / 3600                                  AS TotalActivityTime
FROM ps_table as timing
  LEFT JOIN ActivityType ON ActivityType.MappedTypeID = timing.MappedTypeID
  LEFT JOIN PEGroup ON PEGroup.PEGroupID = timing.PEGroupID
WHERE PEGroup.PEGroupID=4
ORDER BY time_frame desc, timing.shiftID desc, PEGroup.PEGroupName, isNormalShift desc, ActivityType.TypeName
LIMIT 10000 OFFSET 0
 
