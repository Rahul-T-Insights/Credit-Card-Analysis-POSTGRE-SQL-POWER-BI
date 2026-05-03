# PostgreSQL Credit card Analysis

## Project Overview
Designed and analyzed an credit card database using PostgreSQL.

## Database Tables
--Customer
--Credit_Card
--Cust_add
--cc_add

-- Create Tables customer
CREATE TABLE customer (
 client_num BIGINT PRIMARY KEY,
 customer_age INT,
 gender VARCHAR(5),
 dependent_count INT,
 education_level VARCHAR(50),
 marital_status VARCHAR(30),
 state_cd VARCHAR(10),
 zipcode INT,
 car_owner VARCHAR(5),
 house_owner VARCHAR(5),
 personal_loan VARCHAR(5),
 contact VARCHAR(30),
 customer_job VARCHAR(50),
 income NUMERIC,
 cust_satisfaction_score INT
);

--Create Table Credit_card
CREATE TABLE credit_card (
 client_num BIGINT REFERENCES customer(client_num),
 card_category VARCHAR(20),
 annual_fees NUMERIC,
 activation_30_days INT,
 customer_acq_cost NUMERIC,
 week_start_date DATE,
 week_num VARCHAR(20),
 qtr VARCHAR(5),
 current_year INT,
 credit_limit NUMERIC,
 total_revolving_bal NUMERIC,
 total_trans_amt NUMERIC,
 total_trans_vol INT,
 avg_utilization_ratio NUMERIC,
 use_chip VARCHAR(20),
 exp_type VARCHAR(50),
 interest_earned NUMERIC,
 delinquent_acc INT
);

-- Import data into tables
copy customer(client_num, customer_age, Gender, dependent_count, Education_level, marital_status, state_cd, zipcode, car_owner, house_owner, personal_loan, contact, customer_job, income, cust_satisfaction_score)
from 'C:\Users\hp\Desktop\Projects\credit card\customer.csv'
CSV HEADER;

Set datestyle ='ISO, DMY';

copy credit_card(client_num, card_category, annual_fees, activation_30_days, customer_acq_cost, week_start_date, week_num, qtr, current_year, credit_limit, total_revolving_bal, total_trans_amt, total_trans_vol, avg_utilization_ratio, use_chip, exp_type, interest_earned, delinquent_acc)
from 'C:\Users\hp\Desktop\Projects\credit card\credit_card.csv'
CSV HEADER;

Select * from customer;
Select * from credit_card;

--1- Which top 10 states generate the highest total credit card transaction amount, and what is their average customer income?

Select c.state_cd, sum(cc.total_trans_amt) as Top_10_Trans,
avg(c.income) as avg_cust_inc
from credit_card cc
join customer c on c.client_num = cc.client_num
group by c.state_cd
order by Top_10_Trans DESC limit 10;

--2- Which customer segments (Age Group + Gender + Marital Status) contribute the highest revenue through annual fees and interest earned?

select case 
       when c.customer_age <30 then '18-29'
	   when c.customer_age between 30 and 39 then '30-39'
	   when c.customer_age between 40 and 49 then '40-49'
	   when c.customer_age between 50 and 59 then '50-59'
	   else '60+'
	   end as age_group,
c.gender, c.marital_status, sum(cc.annual_fees + cc.interest_earned) as Total_revenue
from customer c
join credit_card cc on c.client_num = c.client_num
group by c.customer_age, c.gender, c.marital_status
order by total_revenue DESC;

--3- Find customers with high credit limits but low transaction activity. Could these customers be underutilized premium customers?

select client_num, credit_limit, total_trans_amt, total_trans_vol, card_category from credit_card
where credit_limit > (select avg (credit_limit) from credit_card) 
and total_trans_vol < (select avg (total_trans_vol) from credit_card)
order by credit_limit DESC;

--4- Which card category (Blue, Silver, Gold, Platinum) has the highest delinquency rate, 
     and what is the total outstanding revolving balance for each category?

select card_category, sum(Total_Revolving_Bal) as Total_outstanding_revo_bal, round (avg(Delinquent_Acc
) *100, 1) as delinquency_rate,
RANK() OVER (ORDER BY AVG(delinquent_acc) DESC) AS risk_rank
from credit_card
group by card_category
order by delinquency_rate desc;

--5- Identify the top 20 customers with the highest credit utilization ratio and analyze whether they are at higher risk of delinquency.

select client_num, ROUND((total_revolving_bal / NULLIF(credit_limit, 0)) * 100,2) AS credit_utilization_percent,
CASE WHEN delinquent_acc = 1 THEN 'High Risk' ELSE 'Low Risk' END AS risk_status
from credit_card
ORDER BY credit_utilization_percent DESC limit 20;

6- Which expense types (Travel, Fuel, Grocery, Entertainment, etc.) 
   generate the highest transaction amount and transaction count across all quarters?

select exp_type, qtr, 
sum(total_trans_amt) as highest_trans_amt, 
sum(total_trans_vol) as highest_trans_cost 
from credit_card
group by exp_type, qtr;

--7- Compare activated vs non-activated customers (Activation_30_Days): 
     who spends more, uses cards more frequently, and earns more interest for the bank?

select sum(total_trans_amt) as spends_more, sum(interest_earned) as most_interest_earned,
case when Activation_30_Days = 1 then 'Activated' else 'NON-Activated' end as Card_status from credit_card
group by Activation_30_Days
order by Card_status asc;

--8- Which job categories (Businessman, Govt, Self-employed, White-collar, etc.) 
     have the highest average income, credit limit, and spending behavior?

select c.Customer_Job, round(avg(c.income),0) as avg_income, round(avg(cc.credit_limit),0) as avg_credit_limit,
round(AVG(cc.total_trans_vol),0) AS spending_behaviour
from customer c
join credit_card cc on cc.client_num = c.client_num
group by c.Customer_Job
ORDER BY c.Customer_Job, avg_income, avg_credit_limit DESC;
