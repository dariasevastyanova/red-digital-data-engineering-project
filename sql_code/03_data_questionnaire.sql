-----------------------------------------------
-------------  DATA QUESTIONNAIRE -------------
-----------------------------------------------

--| How many unique users were studied? What was the average score 
--| for all reviews over the period represented in the dataset?

select count(*) as num_of_users 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users`;
-- 154,271 - unique users

select round(avg(score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`;
-- 4.3 - avg score, calculated as 719069 (sum of score) / 167296 (number of reviews)


--| What is the date range of the dataset? 

select min(review_dt) as min_dt 
      ,max(review_dt) as max_dt  
      ,extract(day from (max(review_dt) - min(review_dt))) as num_of_days 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt`;
-- 2022-02-23 - min review_dt 
-- 2022-04-05 - max review_dt 
-- 41 days - period represented 


--| Do you have any recommendations for column names? 
--| Are there any patterns you were able to glean from the data? 

/*
column names updated: 

camelCase removed & unified structure added

  userName -->>-- username 
  userImage	-->>-- user_image 
  content	-->>-- review_txt 
  score	-->>-- score 
  thumbsUpCount	-->>-- thumbs_up 
  reviewCreatedVersion -->>-- review_version 
  at -->>-- review_dt 
  replyContent -->>-- reply_txt
  repliedAt	-->>-- reply_dt 
  reviewId -->>-- review_id 

Please note: user_image column got excluded from downstream tables 
*/

--| patterns | things to notice | data quality concerns: 

-- score dynamic based on version 
-- init assumption: avg score should get better as versions are progressing, i.e. bugs fixing, interface improving, etc 

select count(review_id) as total_reviews 
      ,count(case when review_version is not null 
                  then review_id 
                  else null 
                  end) as reviews_with_version 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`; 
-- out of 167,296 reviews, 117,885 has verison available 

select count(distinct review_version) as num_of_versions 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`;
-- 437 

select review_version 
      ,sum(score) as total_score
      ,count(review_id) as total_reviews 
      ,round(avg(score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where review_version is not null 
group by review_version 
order by review_version; 

-- simplified: 
select major_release
      ,sum(score) as total_score
      ,count(review_id) as total_reviews 
      ,round(avg(score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where review_version is not null 
group by major_release 
order by major_release; 
-- The assumption is correct. There is confident improvement 
-- from major release 4 to 23. The average score changed from 3.2 to 4.4 

-- highest / lowes user activity 

with tbl0 as (
select a.review_id 
      ,b.review_dt_clean 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
) 
select review_dt_clean
      ,count(review_id) as num_of_reviews --<<-- users activity   
from tbl0 
group by review_dt_clean 
order by review_dt_clean; 
-- lowest activity: 2022-02-23 - 729 reviews --<<-- number is too low - assuming that the data got truncated here 
-- highest activity: 2022-03-19 - 4556 reviews 

with tbl0 as (
select a.review_id 
      ,b.review_dow 
      ,b.review_dow_num --<<-- in this case we are using it for ordering purpose 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
) 
select review_dow_num 
      ,review_dow
      ,count(review_id) as num_of_reviews --<<-- users activity   
from tbl0 
group by review_dow_num 
        ,review_dow 
order by review_dow_num; 
-- lowest activity: Wed - 20,782 reviews
-- highest activity: Sat - 25,540 reviews 

with tbl0 as (
select a.review_id 
      ,b.review_hr 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
) 
select review_hr 
      ,count(review_id) as num_of_reviews --<<-- users activity   
from tbl0 
group by review_hr 
order by review_hr; 
-- lowest activity: between midnight and 2 AM & between 9 PM and 11 PM (~ 4k - 5k reviews)
-- highest activity: between 2 PM and 6 PM (~ 8k - 9k reviews)

-- highest response (thumbs up)- top 10 

select * 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users`
order by thumbs_up desc 
limit 10; 
-- Courtney Ruppe       20102
-- Patricia Beard	      11030
-- Safdar khral	      10298
-- Lissy	            10146
-- shafiq xhan	      9059
-- indira shadows	      8734
-- Isobel Young	      7797
-- Rodolphe Duprey	7686
-- Irfan Ali	      6903
-- Baseer khan	      6595

-- review_dt vs reply_dt

select count(*) as num_of_reviews_with_replies 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where reply_dt is not null; 
-- out of 167,296 total records only 51 reviews received a reply 

select a.review_id 
      ,a.review_dt 
      ,b.reply_dt 
      ,b.reply_txt 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` b 
        on a.review_id = b.review_id 
where b.reply_dt is not null 
    and b.reply_dt >= a.review_dt; 
-- only 17 reviews with replies (out of 51) has the correct chronology:  

select a.review_id 
      ,a.review_dt 
      ,b.reply_dt 
      ,b.reply_txt 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` b 
        on a.review_id = b.review_id 
where b.reply_dt is not null 
    and b.reply_dt < a.review_dt; 
-- bad data     

select min(reply_dt)
      ,max(reply_dt)
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`;
-- from 2018-10-25 to 2022-04-03 - the min reply_dt is out of review_dt range 

--| Does the review score change depending on the day, date, or time?

--select min(avg_score)
--      ,max(avg_score)
--from (      
select b.review_dt_clean
      ,sum(c.score) as total_score  
      ,count(a.review_id) as num_of_reviews
      ,round(avg(c.score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` c
        on a.review_id = c.review_id  
group by b.review_dt_clean  
order by b.review_dt_clean;
--);          
-- the average score fluctuates between 4.1 and 4.38 
-- date dependency: 
--    the lowes point is 2022-03-10 
--    the highest point is 2022-03-21

select b.review_dow_num
      ,b.review_dow 
      ,sum(c.score) as total_score  
      ,count(a.review_id) as num_of_reviews
      ,round(avg(c.score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` c
        on a.review_id = c.review_id  
group by b.review_dow_num 
        ,b.review_dow 
order by b.review_dow_num;
-- day dependency: very insignificant fluctuation noticed – between 4.27 and 4.31
-- dow doesn’t show any significant effect on avg score metrics 

select b.review_hr
      ,sum(c.score) as total_score  
      ,count(a.review_id) as num_of_reviews
      ,round(avg(c.score), 2) as avg_score 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-dt` b 
        on a.review_dt = b.review_dt 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` c
        on a.review_id = c.review_id  
group by b.review_hr 
order by b.review_hr;
-- time dependency: very insignificant fluctuation noticed (as above)

--| Does a scenario exist that a user has more than one 
--| review, and if so, are the reviews approximately the same?

select username 
      ,count(*) as num_of_reviews 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` 
group by username 
having count(*) > 1 
order by count(*) desc; 
-- there are 5,309 users who has more than one review 

with tbl0 as (
select username 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` 
group by username 
having count(*) > 1 
), 
tbl1 as ( --<<-- pulling mode score for each user 
select a.*
      ,row_number() over (partition by a.username order by a.cnt desc) as ro
from (      
  select a.username
        ,b.review_id
        ,b.score
        ,count(b.score) over (partition by a.username, b.score) as cnt   
  from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
      join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` b
          on a.review_id = b.review_id  
  where a.username in (select username from tbl0) --<<-- users who has more than one review 
  group by a.username
          ,b.review_id
          ,b.score        
     ) a     
), 
tbl2 as (
select username 
      ,score as mode_score  
from tbl1
where ro = 1  
), 
tbl3 as (
select username
      ,count(review_id) as total_reviews 
      ,min(score) as min_score 
      ,max(score) as max_score 
      ,round(avg(score), 2) as avg_score   
from tbl1  
group by username      
)
select a.* 
      ,b.mode_score 
from tbl3 a 
    join tbl2 b 
        on a.username = b.username;       
-- pulling the following fields to better understand users behavior
--    total_reviews 
--    min_score 
--    max_score 
--    avg_score 
--    mode_score

-- Please note: here are multiple examples when score and review content 
-- doesn’t match (low score & good/great review and visa versa)

--| What are the distinct review versions? 

select distinct review_version 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where review_version is not null 
order by review_version; 
-- 437 distinct review versions (when available)
-- Please note: review version format - 1.2.3 -->>-- major.minor.patch

select count(distinct major_release) as num_of_major_releases  
      ,count(distinct minor_release) as num_of_minor_releases  
      ,count(distinct patch_release) as num_of_patch_releases        
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where review_version is not null; 
-- 20 distinct major releases (range from 4 to 23)
-- 11 distinct minor releases (range from 0 to 15)
-- 28 distinct patch releases (range from 0 to 55)

--| How many users responded to a review? ** in other words, how many users received a reply **
--| If any, which users responded? 

select count(*) as num_or_reviews_with_replies 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where reply_dt is not null;
-- 51 reviews received a reply from Tiktok representative 
-- 51 unique users received a reply form TikTok representative 

-- list of users 
with tbl0 as (
select a.review_id
      ,b.username 
      ,a.review_dt 
      ,c.reply_dt 
      ,c.reply_txt 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users` b 
        on a.username = b.username 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` c
        on a.review_id = c.review_id  
where c.reply_dt is not null 
) 
select username
from tbl0; 

with tbl0 as (
select a.review_id
      ,b.username 
      ,a.review_dt 
      ,c.reply_dt 
      ,c.reply_txt 
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-fact` a 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-users` b 
        on a.username = b.username 
    join `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews` c
        on a.review_id = c.review_id  
where c.reply_dt is not null 
) 
select sum(case when reply_dt >= review_dt 
                then 1 
                else null 
                end) as num_of_replies_correct_ord --<<-- reply occured after the review was received 
      ,sum(case when reply_dt < review_dt 
                then 1 
                else null 
                end) as num_of_replies_incorrect_ord --<<-- reply occured before the review was received           
from tbl0;
-- num_of_replies_correct_ord - 17
-- num_of_replies_incorrect_ord - 34 --<<-- bad data 


--| What is the tone of each response (angry, concerned, confused, etc.)? 

-- Thinking process: 
--
--    pull the most popular words
--    create several groups with the most popular adjectives based on emotion (anger, confusion, happiness, satisfaction, etc)
--    map those groups back to actual reviews 
--
-- Please note: 
-- To solve this issue, sql code isn’t enough. The ideal solution is to build and train NLP model. 
-- with sql we can determine the general idea of it 
--
-- Additional resources
--    IBM tone analyzer tool - https://cloud.ibm.com/apidocs/tone-analyzer
--    motion detection with Hugging Face - https://huggingface.co/ 

with tbl0 as (
select review_id 
      ,regexp_replace(lower(review_txt), ' ', ', ') as review_txt
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
--limit 500
), 
tbl1 as (
select trim(review_txt) as review_txt   
      ,count(1) as cnt 
from tbl0, 
unnest(split(review_txt)) review_txt 
group by review_txt  
)
select * 
from tbl1 
order by cnt desc;

-- from the codew above: top 500 was analyzed 
/*
review_txt  |     cnt 
-----------------------
good        |     25516
love        |     17716
nice        |     16422
best        |     8326
great       |     6488
fun         |     5699
amazing     |     4445
viral       |     4033
cool        |     2724
awesome     |     2379
banned      |     2138
bad         |     1996
funny       |     1873
wow         |     1683	
entertainment |   1577
fix         |     1393
help        |     1370
ok          |     1365
excellent   |     1294
problem     |     1280
enjoy       |     1233
need        |     1186
entertaining |    1158
hate        |     1134
super       |     1037
happy       |     969
interesting |     879
doesn't     |     844
easy        |     831
wonderful   |     783
beautiful   |     730
dont        |     685	
well        |     684
perfect     |     605
favorite    |     597
bored       |     573
recommend   |     525	
fantastic   |     520
wrong       |     477
pretty      |     464
lovely      |     462
addictive   |     453
wish        |     452
annoying    |     427
addicted    |     425
enjoying    |     424
tried       |     414
hard        |     406
stupid      |     400
issue       |     373 
slow        |     346
fine        |     339
worst       |     319
sad         |     318
sucks       |     308
waste       |     305
helps       |     302
inappropriate |   289
problems    |     287
favourite   |     277
addicting   |     274
good.       |     265
mean        |     242
enjoyable   |     238
loved       |     231
fun.        |     227
horrible    |     224
stress      |     217
lost        |     215
trash       |     211
loving      |     209
boring      |     197
interested  |     197
awsome      |     173 
*/

-- Please note: we should account for different shapesof emotion, i.e horrible vs horrible! vs horrible... 

select review_id 
      ,review_txt
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
where lower(review_txt) like '%good%'
    or lower(review_txt) like '%love%'
    or lower(review_txt) like '%nice%'
    or lower(review_txt) like '%best%'
    or lower(review_txt) like '%great%'
    or lower(review_txt) like '%fun%'
    or lower(review_txt) like '%amazing%'
    or lower(review_txt) like '%viral%'
    or lower(review_txt) like '%cool%'
    or lower(review_txt) like '%awesome%'
    or lower(review_txt) like '%banned%'
    or lower(review_txt) like '%bad%'
    or lower(review_txt) like '%funny%'
    or lower(review_txt) like '%wow%'
    or lower(review_txt) like '%entertainment%'
    or lower(review_txt) like '%fix%'
    or lower(review_txt) like '%help%'
    or lower(review_txt) like '%ok%'
    or lower(review_txt) like '%excellent%'
    or lower(review_txt) like '%problem%'
    or lower(review_txt) like '%enjoy%' 
    or lower(review_txt) like '%need%' 
    or lower(review_txt) like '%entertaining%'
    or lower(review_txt) like '%hate%'        
    or lower(review_txt) like '%super%'       
    or lower(review_txt) like '%happy%'       
    or lower(review_txt) like '%interesting%' 
    or lower(review_txt) like '%doesn\'t%'     
    or lower(review_txt) like '%easy%'        
    or lower(review_txt) like '%wonderful%'   
    or lower(review_txt) like '%beautiful%'   
    or lower(review_txt) like '%dont%'        
    or lower(review_txt) like '%well%'        
    or lower(review_txt) like '%perfect%'     
    or lower(review_txt) like '%favorite%'    
    or lower(review_txt) like '%bored%'       
    or lower(review_txt) like '%recommend%'   
    or lower(review_txt) like '%fantastic%'   
    or lower(review_txt) like '%wrong%'       
    or lower(review_txt) like '%pretty%'      
    or lower(review_txt) like '%lovely%'      
    or lower(review_txt) like '%addictive%'   
    or lower(review_txt) like '%wish%'        
    or lower(review_txt) like '%annoying%'    
    or lower(review_txt) like '%addicted%'    
    or lower(review_txt) like '%enjoying%'    
    or lower(review_txt) like '%tried%'       
    or lower(review_txt) like '%hard%'        
    or lower(review_txt) like '%stupid%'      
    or lower(review_txt) like '%issue%'       
    or lower(review_txt) like '%slow%'        
    or lower(review_txt) like '%fine%'        
    or lower(review_txt) like '%worst%'       
    or lower(review_txt) like '%sad%'         
    or lower(review_txt) like '%sucks%'       
    or lower(review_txt) like '%waste%'       
    or lower(review_txt) like '%helps%'  
    or lower(review_txt) like '%inappropriate%'  
    or lower(review_txt) like '%problems%'  
    or lower(review_txt) like '%favourite%' 
    or lower(review_txt) like '%addicting%' 
    or lower(review_txt) like '%good%'     
    or lower(review_txt) like '%mean%'      
    or lower(review_txt) like '%enjoyable%' 
    or lower(review_txt) like '%loved%'     
    or lower(review_txt) like '%fun%'      
    or lower(review_txt) like '%horrible%'  
    or lower(review_txt) like '%stress%'    
    or lower(review_txt) like '%lost%'   
    or lower(review_txt) like '%trash%'     
    or lower(review_txt) like '%loving%'      
    or lower(review_txt) like '%boring%'      
    or lower(review_txt) like '%interested%'  
    or lower(review_txt) like '%awsome%';
-- 117,574 reviews segmented (70% of all reviews)

-- adding response tone flag: 
--    1. anger & unsatisfaction 
--    2. confusion  
--    3. happinnes
--    4. neutral 

select case when response_tone_flag = 1 then 'anger & unsatisfaction'
            when response_tone_flag = 2 then 'confusion'
            when response_tone_flag = 3 then 'happinnes'
            when response_tone_flag = 4 then 'neutral'
            end as response_tone     
      ,count(review_id) as num_of_reviews  
from (
select review_id 
      ,review_txt
      ,case when lower(review_txt) like '%bad%'
              or lower(review_txt) like '%hate%'
              or lower(review_txt) like '%mean%'
              or lower(review_txt) like '%horrible%'
              or lower(review_txt) like '%trash%'
              or lower(review_txt) like '%waste%'
              or lower(review_txt) like '%worst%'
              or lower(review_txt) like '%sad%'
              or lower(review_txt) like '%boring%'
              or lower(review_txt) like '%bored%'
              or lower(review_txt) like '%inappropriate%'
              or lower(review_txt) like '%stupid%'
              or lower(review_txt) like '%slow%'
              or lower(review_txt) like '%sucks%'
              or lower(review_txt) like '%annoying%'      
            then 1
            when lower(review_txt) like '%banned%'
              or lower(review_txt) like '%problem%' 
              or lower(review_txt) like '%need%'
              or lower(review_txt) like '%fix%'
              or lower(review_txt) like '%help%'
              or lower(review_txt) like '%doesn\'t%'
              or lower(review_txt) like '%dont%'
              or lower(review_txt) like '%stress%'
              or lower(review_txt) like '%lost%'
              or lower(review_txt) like '%wrong%'
              or lower(review_txt) like '%wish%'
              or lower(review_txt) like '%hard%'
              or lower(review_txt) like '%tried%'
              or lower(review_txt) like '%issue%'
            then 2
            when lower(review_txt) like '%love%'
              or lower(review_txt) like '%nice%'
              or lower(review_txt) like '%best%'
              or lower(review_txt) like '%great%'
              or lower(review_txt) like '%fun%'
              or lower(review_txt) like '%amazing%'
              or lower(review_txt) like '%viral%'
              or lower(review_txt) like '%cool%'
              or lower(review_txt) like '%awesome%'
              or lower(review_txt) like '%awsome%'
              or lower(review_txt) like '%super%'
              or lower(review_txt) like '%happy%'
              or lower(review_txt) like '%funny%'
              or lower(review_txt) like '%wow%'
              or lower(review_txt) like '%excellent%'
              or lower(review_txt) like '%enjoy%'
              or lower(review_txt) like '%wonderful%'
              or lower(review_txt) like '%beautiful%'
              or lower(review_txt) like '%loving%'
              or lower(review_txt) like '%favourite%'
              or lower(review_txt) like '%addict%'
              or lower(review_txt) like '%perfect%'
              or lower(review_txt) like '%pretty%'
              or lower(review_txt) like '%fantastic%'
              or lower(review_txt) like '%favorite%'
            then 3
            when lower(review_txt) like '%good%'
              or lower(review_txt) like '%entertain%'
              or lower(review_txt) like '%ok%'
              or lower(review_txt) like '%interesting%'
              or lower(review_txt) like '%easy%'
              or lower(review_txt) like '%well%'
              or lower(review_txt) like '%recommend%'
              or lower(review_txt) like '%interested%'
              or lower(review_txt) like '%fine%'
            then 4
            else null 
            end as response_tone_flag
from `red-digital-interview-sandbox.interview_proj.tbl-tiktok-dim-reviews`
     )
where response_tone_flag is not null 
group by case when response_tone_flag = 1 then 'anger & unsatisfaction'
              when response_tone_flag = 2 then 'confusion'
              when response_tone_flag = 3 then 'happinnes'
              when response_tone_flag = 4 then 'neutral'
              end;     
-- 117,678 reviews were flagged (comparing with 117,574 - logic was improved a bit to make it more inclusive)

/*
anger & unsatisfaction   | 7648     | 6.5%  
happinnes                | 69245    | 58.8%
confusion                | 8993	| 7.6%
neutral                  | 31792    | 27%

total                    | 117678 --<<-- 70% of total reviews 
*/

-- Please note: it's very rough representation of it. It gives the general idea 
-- To obtain more accurate result, different approaches required
