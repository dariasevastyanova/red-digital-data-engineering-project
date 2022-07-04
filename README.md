# red-digital-data-engineering-project

## Execution plan


1.	Reviewing all resources provided 
2.	Loading the dataset from GCS into BQ
    a.	Eliminated ASCII characters by converting the given file into CSV UTF-8 format 
    b.	No partitioning needed – dataset is too small. Potentially could use review_dt for it (horizontal partitioning)
    c.	Eliminated issue with parsing timestamp column – loaded it as string column and converted into datetime format after 
3.	Performing the initial [data examination](https://github.com/dariasevastyanova/red-digital-data-engineering-project/blob/main/sql_code/01_init_data_analysis.sql)
4.	Whiteboarding & brainstorming 
5.	Building [multidimensional schema (fact & dim tables)](https://github.com/dariasevastyanova/red-digital-data-engineering-project/blob/main/sql_code/02_multidimensional_schema_build.sql)
6.	Building [ERD](https://github.com/dariasevastyanova/red-digital-data-engineering-project/blob/main/visual_aid/erd.png) using https://dbdiagram.io/home source
7.	Answering all [required questions](https://github.com/dariasevastyanova/red-digital-data-engineering-project/blob/main/sql_code/03_data_questionnaire.sql)


## Tables Created 

tiktok-data-init
    the initial csv doc was loaded 
    pretty column names created  
    columns description added 

tbl-tiktok-fact
    * review_id [string]
    * username [string]
    * review_dt [datetime]

tbl-tiktok-dim-users 
    * username [string]
    * thumbs_up [integer]

tbl-tiktok-dim-reviews 
    * review_id [string]
    * review_txt [string]
    * score [integer]
    * reply_txt [string]
    * reply_dt [datetime]
    * review_version [string]
    * major_release [integer]
    * major_minor [float]
    * minor_release [integer]
    * patch_release [integer]

tbl-tiktok-dim-dt 
    * review_dt [datetime]
    * review_hr [integer]
    * review_dow_num [integer]
    * review_dow [string]
    * review_dt_clean [date]

## Data Qeustionnaire

●	How many unique users were studied? What was the average score for all reviews over the period represented in the dataset?
●	What is the date range of the dataset? 
●	Do you have any recommendations for column names? Are there any patterns you were able to glean from the data? 
●	Does the review score change depending on the day, date, or time?
●	Does a scenario exist that a user has more than one review, and if so, are the reviews approximately the same?
●	What are the distinct review versions? 
●	How many users responded to a review? If any, which users responded? 
●	What is the tone of each response (angry, concerned, confused, etc.)? 
