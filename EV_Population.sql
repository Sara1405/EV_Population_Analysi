-- EV Population Analysis

-- Create Database
Create Database ev_analysis;
Use ev_analysis;

-- Create Table and Import Dataset
CREATE TABLE electric_vehicles (
    vin_10 VARCHAR(20),
    county VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(10),
    postal_code INT,
    model_year INT,
    make VARCHAR(100),
    model VARCHAR(100),
    ev_type VARCHAR(100),
    cafv_eligibility VARCHAR(150),
    electric_range DECIMAL(10,2),
    base_msrp DECIMAL(12,2),
    legislative_district INT,
    dol_vehicle_id BIGINT,
    vehicle_location VARCHAR(255),
    electric_utility VARCHAR(255),
    census_tract BIGINT
);

-- Data Quality check

-- Total Records
Select count(*) As total_records
From ev_analysis.electric_vehicles;

-- Check Null Values
Select
sum(vin_10 IS Null) As missing_value,
sum(county Is null) As missing_country,
sum(city Is null) As missing_city,
sum(model_year Is null) As missing_model_year,
sum(make Is null) As missing_make,
sum(model Is null) As missing_model,
sum(ev_type Is null) As missing_ev_type,
sum(electric_range Is null) As missing_electric_range,
sum(base_msrp Is null) As missing_msrp
From ev_analysis.electric_vehicles;

-- Check Duplicate Records
Select 
dol_vehicle_id,
count(*) As duplicate_count
From ev_analysis.electric_vehicles
group by dol_vehicle_id
having count(*) > 1;

-- Basic EV Analysis

-- Total EVs
Select count(*) As total_ev
From ev_analysis.electric_vehicles;

-- Total Manufacturers   -- 41 manufacturers
Select count(distinct make) As total_manufacturers
From ev_analysis.electric_vehicles;

-- Total Models          -- 161 models
Select count(distinct model) As total_model
From ev_analysis.electric_vehicles;

-- States                -- 1 state
Select count(distinct state) As total_states
From ev_analysis.electric_vehicles;

-- BEV vs PHEV Analysis  
-- BEV(Battery Electric Vehicle) count- 27707 - 80.91% and PHEV(Plug-in Hybrid Electric Vehicle)- count- 6537 - 19.09%
select 
ev_type,
count(*) As vehicle_count,
Round(count(*) * 100.0 /
(select count(*) from ev_analysis.electric_vehicles), 2) As percentage
from ev_analysis.electric_vehicles
group by ev_type
order by vehicle_count desc;

-- MAnufacturer Analysis
-- Top 10 Manufacturers    -- TESLA is the Highest Manufacturer and RIVIAN is the Lowest Manufacturer.
Select
make,
count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By make
Order By vehicle_count Desc
Limit 10;

-- Manufacturers Market Share
Select
make,
count(*) AS vehicle_count,
Round(count(*) * 100.0 / (Select count(*) As vehicle_count
From ev_analysis.electric_vehicles), 2) As market_share
From ev_analysis.electric_vehicles
Group By make
Order By market_share;

-- Top EV Models
Select
make, model,
count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By make, model
Order By vehicle_count
Limit 20;

-- EV Adoption by Model Year  -- Highest in 2023 - 8113
Select 
model_year,
count(*) AS vehicle_count
From ev_analysis.electric_vehicles
Group By model_year
Order By model_year;

-- Year-Over-Year Growth
WITH yearly_ev AS (
    SELECT
        model_year,
        COUNT(*) AS vehicle_count
    FROM electric_vehicles
    GROUP BY model_year
)

SELECT
    model_year,
    vehicle_count,
    LAG(vehicle_count) OVER (
        ORDER BY model_year
    ) AS previous_year
FROM yearly_ev
ORDER BY model_year;

WITH yearly_ev AS (
    SELECT
        model_year,
        COUNT(*) AS vehicle_count
    FROM electric_vehicles
    GROUP BY model_year
),
growth AS (
    SELECT
        model_year,
        vehicle_count,
        LAG(vehicle_count) OVER (
            ORDER BY model_year
        ) AS previous_year
    FROM yearly_ev
)

SELECT
    model_year,
    vehicle_count,
    ROUND(
        (vehicle_count - previous_year) * 100.0 /
        NULLIF(previous_year,0),
        2
    ) AS yoy_growth
FROM growth
ORDER BY model_year;

-- Geographic Analysis

-- Top 10 Countries     -- Top 1 King-25094 Vehicle count
Select 
    county, 
    count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By county
Order By vehicle_count Desc
Limit 10;

-- Top 20 Cities  -- Top 1 is Seattle-King-6501 Vehicles
Select 
    city, county,
    count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By city, county
Order By vehicle_count Desc
Limit 20;

-- State Analysis          -- WA - 34244 
Select 
	  state,
      count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By state
Order By vehicle_count desc;

-- Electric Range Analysis

-- Average Range    -- avg_range - 115
Select 
       Round(avg(electric_range), 0) As avg_range
From ev_analysis.electric_vehicles
Where electric_range > 0;

-- Maximum Range           -- max_range - 337
Select 
     Round(Max(electric_range), 0) As max_range
From ev_analysis.electric_vehicles;

-- Minimum Range         -- min_range - 1.00
Select 
     min(electric_range) As min_range
From ev_analysis.electric_vehicles
Where electric_range > 0;

-- Range By Manufacturers
Select 
      make,
      count(*) As vehicle_count,
     round(avg(electric_range), 0) As avg_range,
     max(electric_range) As max_range
From ev_analysis.electric_vehicles
Where electric_range > 0
Group By make
Having count(*) >= 100
Order By avg_range Desc;

-- Range by EV Type
Select 
      ev_type,
      Count(*) As vehicle_count
From ev_analysis.electric_vehicles
Where electric_range > 0
Group By ev_type;

-- CAFV Eligibility'
SELECT
    cafv_eligibility,
    COUNT(*) AS vehicle_count
FROM electric_vehicles
GROUP BY cafv_eligibility
ORDER BY vehicle_count DESC;

-- Percentage
Select 
	 cafv_eligibility,
	 count(*) As vehicle_count,
     Round(
     Count(*) * 100.0 / (
     select count(*) From ev_analysis.electric_vehicles), 2) As percentage
From ev_analysis.electric_vehicles
Group By cafv_eligibility
Order By vehicle_count Desc;

-- Manufactuere + EV Type
Select
     make, ev_type,
     count(*) As vehicle_count
From ev_analysis.electric_vehicles
Group By make, ev_type
Order By vehicle_count Desc;   

-- Top Manufacturers by BEV       -- TESLA -count 14868
Select
    make,
    count(*) As bev_count
From ev_analysis.electric_vehicles
Where ev_type Like '%Battery%'
Group By make
Order By bev_count Desc
Limit 10;  

-- Top Manufacturers by PHEV
Select
     make,
     count(*) As phev_count
From ev_analysis.electric_vehicles
Where ev_type Like '%Plug-in%'
Group By make
Order By phev_count Desc
Limit 10;

-- Popular Models + Range
SELECT
    make,
    model,
    COUNT(*) AS vehicle_count,
    ROUND(AVG(electric_range),2) AS avg_range
FROM electric_vehicles
GROUP BY make, model
HAVING COUNT(*) >= 100
ORDER BY vehicle_count DESC
LIMIT 20;

-- Rank Manufacturers
WITH manufacturer_stats AS (
    SELECT
        make,
        COUNT(*) AS vehicle_count
    FROM electric_vehicles
    GROUP BY make
)

SELECT
    make,
    vehicle_count,
    RANK() OVER (
        ORDER BY vehicle_count DESC
    ) AS manufacturer_rank
FROM manufacturer_stats;

-- Top 3 Models per Manufacturers
WITH model_counts AS (
    SELECT
        make,
        model,
        COUNT(*) AS vehicle_count
    FROM electric_vehicles
    GROUP BY make, model
),
ranked_models AS (
    SELECT
        make,
        model,
        vehicle_count,
        ROW_NUMBER() OVER (
            PARTITION BY make
            ORDER BY vehicle_count DESC
        ) AS model_rank
    FROM model_counts
)

SELECT *
FROM ranked_models
WHERE model_rank <= 3
ORDER BY make, model_rank;

-- Create SQL Analytical View
CREATE VIEW ev_dashboard AS

SELECT
    dol_vehicle_id,
    county,
    city,
    state,
    postal_code,
    model_year,
    make,
    model,
    ev_type,
    cafv_eligibility,
    electric_range,
    base_msrp,
    legislative_district,
    vehicle_location,
    electric_utility,
    census_tract
FROM electric_vehicles;
