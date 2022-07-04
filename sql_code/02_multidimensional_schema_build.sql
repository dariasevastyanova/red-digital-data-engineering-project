----------------------------------------------
-------  MULTIDIMENSIONAL SCHEMA BUILD -------
----------------------------------------------

/*
multidimensional schema - star
  benefits:
    simple structure 
    queries run faster 
    easy to set up 

please refer to ERD for additional details 
*/

--| fact table - init 
--|   review_id [string]
--|   username [string]
--|   review_dt [datetime]
--|
--| 167,296 records
--| review_id --<<-- unique identifier 

insert into `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact`
select review_id 
      ,username 
      ,cast(review_dt as datetime format 'mm/dd/yy hh24:mi') as review_dt
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init`;

select * 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact`
limit 10;

--| dim table - users  
--|   username [string]
--|   thumbs_up [integer]
--|
--| 154,271 records
--| username --<<-- unique identifier 

insert into `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users`
select username 
      ,sum(thumbs_up) as thumbs_up
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init` 
group by username; 

select * 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users`
limit 10;

--| dim table - reviews   
--|   review_id [string]
--|   review_txt [string]
--|   score [integer]
--|   reply_txt [string]
--|   reply_dt [datetime]
--|   review_version [string]
--|   major_release [integer]
--|   major_minor [float]
--|   minor_release [integer]
--|   patch_release [integer]
--|
--| 167,296 records
--| review_id --<<-- unique identifier 

insert into `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` 
select review_id 
      ,review_txt
      ,score
      ,reply_txt 
      ,cast(reply_dt as datetime format 'mm/dd/yy hh24:mi') as reply_dt
      ,review_version
      ,cast(split(review_version, '.')[offset(0)] as int64) as major_release 
      ,cast(concat(split(review_version, '.')[offset(0)], '.', 
                   split(review_version, '.')[offset(1)]) as float64) as major_minor
      ,cast(split(review_version, '.')[offset(1)] as int64) as minor_release
      ,cast(split(review_version, '.')[offset(2)] as int64) as patch_release 
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init`; 

select * 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` 
limit 10;

--| dim table - dt    
--|   review_dt [datetime]
--|   review_hr [integer]
--|   review_dow_num [integer]
--|   review_dow [string]
--|   review_dt_clean [date]
--|
--| 54,936 records
--| review_id --<<-- unique identifier 

insert into `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt`
with tbl0 as (
select distinct(cast(review_dt as datetime format 'mm/dd/yy hh24:mi')) as review_dt 
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init` 
), 
tbl1 as (
select a.*
      ,extract(hour from review_dt) as review_hr
      ,extract(dayofweek from review_dt) as review_dow_num  
      ,extract(month from review_dt) as month        
      ,extract(day from review_dt) as day  
      ,extract(year from review_dt) as year        
from tbl0 a  
)
select review_dt
      ,review_hr
      ,review_dow_num 
      ,case when review_dow_num = 1 then 'Sunday'
            when review_dow_num = 2 then 'Monday'
            when review_dow_num = 3 then 'Tuesday'
            when review_dow_num = 4 then 'Wednesday'
            when review_dow_num = 5 then 'Thursday'
            when review_dow_num = 6 then 'Friday'
            when review_dow_num = 7 then 'Saturday'
            end as review_dow
      ,cast(concat(month, '/', day, '/', year) as date format 'mm/dd/yyyy') as review_dt_clean 
from tbl1; 

select * 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt`
limit 10;
