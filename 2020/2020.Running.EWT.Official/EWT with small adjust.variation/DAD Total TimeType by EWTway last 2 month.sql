/******************************************************************************************
** Name: EWT Official by EWTway with have meal 2020
** Desc:
** Auth: An Pham
** Onwer: Mrs. Sen Nga (HR)
** Created_at: 2019-08-03
**************************
** Change History
**************************
** PR   Date        Author  Description
** --   --------   -------   ------------------------------------
** 1    2019-08-03 An Pham      Create for RJmetric
*******************************************************************************************/
with _ as (
    select dateadd(hour, -7, cast(cast(cast(dateadd(day, 25, date_trunc('month',
              current_date-0/*SUA NGAY THANG TAI DAY*/)) as date) AS varchar) + ' 06:15:00' as datetime)) as time_
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

),ActivityType(MappedTypeID, TypeName) as (
                SELECT 110  , '1_IPT'
      UNION ALL SELECT 1    , '2_Break'
      UNION ALL SELECT 7    , '3_NoAssignedImage'
      UNION ALL SELECT 411  , '4_Others_'
      UNION ALL SELECT 1312 , '5_Browser_'
      UNION ALL SELECT -1   , '6_IDLE'
      UNION ALL SELECT 514  , '7_Skype_'
      UNION ALL SELECT 10   , '1__PostProcessingTime'
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
      UNION ALL SELECT 7116 , '1__IPTAndPostProcessing'
), ActivityLog AS (
    SELECT
      CASE WHEN (isnull(ImageID, 0) > 0 AND (EditorClientLoginTypeID = 0 OR ActivityTimeTypeID = 0)) THEN 110 ELSE
      CASE WHEN ActivityTimeTypeID in (7, 1, 9, 10, 6, 5, 2, 3 ,4, -1, 8) THEN ActivityTimeTypeID ELSE
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
--     WHERE ClientTimeReportAt >= '2019-07-16 23:15:00' AND ClientTimeReportAt < '2019-07-17 23:15:00'
    join _ ON ClientTimeReportAt >= dateadd(month, -2, _.time_)
          AND ClientTimeReportAt <  dateadd(month,  0, _.time_)

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
--            where RequestDatetimeUtc >= '2019-07-16 23:15:00' and RequestDatetimeUtc < '2019-07-17 23:15:00'
           join _ ON RequestDatetimeUtc >= dateadd(month, -2, _.time_)
                 AND RequestDatetimeUtc <  dateadd(month,  0, _.time_)
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
 join _ ON StartAt >= dateadd(month, -2, _.time_)
          AND StartAt <  dateadd(month,  0, _.time_)
  ), time_shift as (
    select *,
           dateadd(minute, (7*60 -(60*6+15)), cast(time_at as datetime)) as time_shift
    from (SELECT * FROM ActivityLog
          UNION ALL SELECT * FROM logout_timing
          UNION ALL SELECT 1091 as MappedTypeID, WorkerID, timing, time_at FROM have_meal_tab
          UNION ALL SELECT 7116 as MappedTypeID, WorkerID, timing, time_at FROM ActivityLog where MappedTypeID in (110, 10)
          UNION ALL SELECT 7117 as MappedTypeID, WorkerID, timing, time_at FROM ActivityLog where MappedTypeID in (110, 10, 5)
         ) __,_

/*IMPORT*/

-- ), shift_ as (
--       select
--         shiftID,
--         to_char(dateadd(minute, -(60*6+15), cast('2112-12-12 ' + start_UTC7 as datetime)), 'HH24:MI:SS') as start_,
--         to_char(dateadd(minute, -(60*6+15), cast('2112-12-12 ' + end_UTC7 as datetime)), 'HH24:MI:SS')   as end_
--     from ( select NULL as shiftID, NULL as start_UTC7, NULL as end_UTC7
--             union all select 1,'06:15:00' ,'14:15:00'
--             union all select 2,'14:15:00' ,'22:15:00'
--             union all select 3,'22:15:00' ,'06:15:00'
--          ) _ where shiftID is not null

), timing AS (
    select
      cast(time_shift as date)       as time_frame,
      datepart(hour, time_shift) / 8 as shiftID,
--       MappedTypeID,
      WorkerID,
      sum(timing)                    AS timing
    from time_shift
    --     join shift_ on to_char(time_shift, 'HH24:MI:SS') >= start_ and
    --                    to_char(time_shift, 'HH24:MI:SS') < end_
    where MappedTypeID in 
	--(110, 7, 10, 5, 9)   --EWT: (110, 7, 10, 5, 9)  -- IPT&Post:(110, 10) 
							(
							 110  , '1_IPT'
							 1    , '2_Break'
							 7    , '3_NoAssignedImage'
							 411  , '4_Others_'
							 1312 , '5_Browser_'
							 -1   , '6_IDLE'
							 514  , '7_Skype_'
							 10   , '1__PostProcessingTime'
						--	 2    , '9_TrainingMeetingTime'
						--	 3    , '9_TrainingMeetingTime'
						--	 4    , '9_TrainingMeetingTime'
							 310  , 'a_Explorer_'
							 1001 , 'b_WorkingTool_'
							 1013 , 'b_IDLE_'
							 6    , 'd_NoDownloadedImage'
							 5    , 'e_WorkingOnBrowser'
							 9    , 'f_WaitForDownloading'
							 8    , 'g_SystemErrorTime'
							 1091 , 'l_HaveMeal'
						--	 1093 , 'l_ref_HaveMeal'
							 1092 , 'l_Logout'
						--	 7116 , '1__IPTAndPostProcessing'
							)
    group by
      cast(time_shift as date),
      datepart(hour, time_shift) / 8,
--       MappedTypeID,
      WorkerID

), RegisterShift as (
    select
      EndShiftReports.WorkerID,
      cast(ShiftStartDateLocalTime as date)       as date_,
      datepart(hour, dateadd(second, -1, ShiftStartDateLocalTime)) / 8 as shiftID,
      ProductionWorkers.WorkerName as TeamName
    from EndShiftReports
    left join ProductionWorkers on ProductionWorkers.WorkerID = EndShiftReports.LeaderID
--     where ShiftStartDateLocalTime >= dateadd(hour, +7, '2019-07-16 23:15:00') and
--           ShiftStartDateLocalTime < dateadd(hour, +7, '2019-07-17 23:15:00')
    join _ on ShiftStartDateLocalTime >= dateadd(month, -2, dateadd(hour, +7, _.time_))
          AND ShiftStartDateLocalTime <  dateadd(month,  0, dateadd(hour, +7, _.time_))
)
SELECT
  time_frame                                             as date_,
  case when time_frame in
      ('2019-01-01', '2019-04-14'/*Hung Vuong*/, '2019-04-30','2019-05-01') then '3_Holiday'

   else case when time_frame in
      ('2019-04-15'/*nghi bu Hung Vuong*/) then '2_Weekend'

   else case when datepart(dw, cast(time_frame as date)) = datepart(dw, cast('2019-03-03' as date))
        then '2_Weekend' else '1_Weekday' end end end as TypeOfDate,
  substring('1_AM2_PM3_NI', (timing.shiftID) * 4 + 1, 4) AS shift_,
  case when RegisterShift.shiftID is null then 0 else 1 end AS isRegisterShift,
  ProductionWorkers.WorkerName,
--  ProductionWorkers.WorkerName + ' (' + cast(ProductionWorkers.WorkerID as nvarchar(5)) + ')' AS WorkerName,
  ProductionWorkers.EmployeeCode,
  isnull(TeamName, '')                                   as TeamName,
  PEGroup.PEGroupName                                    AS Office,
--   ActivityType.TypeName                                  AS ActivityType,
  0.001 * timing / 3600                                  AS TotalActivityTime
FROM timing
  JOIN filter_worker ON filter_worker.WorkerID = timing.WorkerID
  LEFT JOIN ProductionWorkers on ProductionWorkers.WorkerID = timing.WorkerID
--   LEFT JOIN ActivityType ON ActivityType.MappedTypeID = timing.MappedTypeID
  LEFT JOIN PEGroup ON PEGroup.PEGroupID = filter_worker.PEGroupID
  LEFT JOIN RegisterShift on RegisterShift.date_ = timing.time_frame
                             and RegisterShift.shiftID = timing.shiftID
                             and RegisterShift.WorkerID = timing.WorkerID
WHERE filter_worker.PEGroupID in (4)
--       and timing.MappedTypeID in (110, 7, 10, 5, 9)
ORDER BY date_, timing.shiftID, filter_worker.WorkerID--, ActivityType.TypeName
limit 10000 offset 0