-------------------------------------
------- INITIAL DATA ANALYSIS -------
-------------------------------------

/*
General recommendations: 
  use limit constrain to speed up the query 
  use where clause in order to avoid pulling the whole table when there is no need for that 
  when joining multiple tables together - pull only what you need & try to limit it as well (select [fields] vs select *)
  aggregate only when needed (aggregation requires more computation -->> higher resources usage)
*/

--| total number of records 
select count(*) as num_of_rows
      ,count(distinct review_id) as num_of_reviews 
      ,count(distinct username) as num_of_users 
      ,count(distinct reply_txt) as num_of_replies 
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init`;
-- 167,296 num_of_rows --<<-- the same as init Excel file - goody
-- Note: num_of_rows = number of unique reviews 
-- 154,271 - number of unique users 
-- 19 - number of replies 

--| date range 
select min(cast(review_dt as datetime format 'mm/dd/yy hh24:mi')) as min_dt
      ,max(cast(review_dt as datetime format 'mm/dd/yy hh24:mi')) as max_dt
from `red-digital-interview-sandbox.interview_proj.tiktok-data-init`;
-- 2022-02-23 - min_dt 
-- 2022-04-05 - max_dt 
