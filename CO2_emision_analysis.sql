select distinct year from co2_emission_project_sql_main_last;
--1: Select all rows but only display country, year, and co2_emission_tons.
select country,year,co2_emission_tons
from co2_emission_project_sql_main_last;
--2: Retrieve all records where year = 2022 and emissions are greater than 1,000,000,000.
select * from co2_emission_project_sql_main_last
where year=2020 and co2_emission_tons>=1000000000;
--3: Find the total number of distinct countries in the dataset.
select distinct country from co2_emission_project_sql_main_last;
--4: Show the total CO₂ emissions for each country (all years combined).
select country,sum(co2_emission_tons) from co2_emission_project_sql_main_last
group by country;
--5: Show the average per capita emissions for each country.
select country, sum(co2_emission_tons)/ population_2022 from co2_emission_project_sql_main_last
where population_2022 is not null
group by country, population_2022;
--6: Find the top 5 countries by total emissions in 2022.
select country, sum(co2_emission_tons) as Total_Emission from co2_emission_project_sql_main_last
group by country
order by Total_Emission desc limit 5;
--7: Show the global total emissions trend year by year.
select year, sum(co2_emission_tons) from co2_emission_project_sql_main_last
group by year
order by year asc;
--first and most co2 emission before 1800 
select country,year,co2_emission_tons from co2_emission_project_sql_main_last
where co2_emission_tons <>0 and year<1800
order by  co2_emission_tons desc limit 1;
--8: Show the emissions trend for India across years.
select year,co2_emission_tons from co2_emission_project_sql_main_last
where country = 'India' ;
--9: Find all countries whose average emissions exceed 1 billion tons.
select country,avg(co2_emission_tons) as average_emission from co2_emission_project_sql_main_last
group by country
having avg(co2_emission_tons)>=1000000000;
--10: Rank countries by emissions for each year.
SELECT country, year, co2_emission_tons,
       RANK() OVER (PARTITION BY year ORDER BY co2_emission_tons DESC) AS emission_rank
FROM co2_emission_project_sql_main_last;
--11: Calculate the percentage share of each country in global emissions for 2022.
SELECT country, year, co2_emission_tons,
       100 * co2_emission_tons / SUM(co2_emission_tons) OVER (PARTITION BY country) AS percent_share
FROM co2_emission_project_sql_main_last
ORDER BY percent_share DESC;
--12: Find the 3-year rolling average emissions for each country.
SELECT country, year, co2_emission_tons,
       AVG(co2_emission_tons) OVER (
           PARTITION BY country 
           ORDER BY year 
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS rolling_avg_3yr
FROM co2_emission_project_sql_main_last
ORDER BY country, year;
--13: Which country had the highest year-over-year growth rate
WITH yearly_growth AS (
    SELECT country, year,
           co2_emission_tons,
           LAG(co2_emission_tons) OVER (PARTITION BY country ORDER BY year) AS prev_year
    FROM co2_emissions
)
SELECT country, year,
       ROUND(100.0 * (co2_emission_tons - prev_year) / NULLIF(prev_year,0), 2) AS growth_rate_percent
FROM yearly_growth
WHERE prev_year IS NOT NULL
ORDER BY growth_rate_percent DESC
LIMIT 1;
--14: Cumulative Global Emissions
SELECT year,
       SUM(co2_emission_tons) AS yearly_total,
       SUM(SUM(co2_emission_tons)) OVER (ORDER BY year) AS cumulative_total
FROM co2_emissions
GROUP BY year
ORDER BY year;
--15: Rising Share of Global Emissions
WITH country_share AS (
    SELECT country, year,
           ROUND(100.0 * co2_emission_tons / SUM(co2_emission_tons) OVER (PARTITION BY year), 2) AS share_percent
    FROM co2_emissions
)
SELECT country, year, share_percent,
       share_percent - LAG(share_percent) OVER (PARTITION BY country ORDER BY year) AS share_change
FROM country_share
WHERE share_percent IS NOT NULL
ORDER BY share_change DESC
LIMIT 5;
--16: Countries with Consistent Decreases
WITH ranked AS (
    SELECT country, year, co2_emission_tons,
           LAG(co2_emission_tons,1) OVER (PARTITION BY country ORDER BY year) AS prev1,
           LAG(co2_emission_tons,2) OVER (PARTITION BY country ORDER BY year) AS prev2
    FROM co2_emissions
)
SELECT country, year, co2_emission_tons
FROM ranked
WHERE co2_emission_tons < prev1 AND prev1 < prev2;
--17: 5-Year Moving Average of Global Emissions
WITH yearly_totals AS (
    SELECT year, SUM(co2_emission_tons) AS global_emissions
    FROM co2_emissions
    GROUP BY year
)
SELECT year, global_emissions,
       AVG(global_emissions) OVER (
           ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
       ) AS moving_avg_5yr
FROM yearly_totals
ORDER BY year;
--18: Most Emission-Efficient Country (per Area)
SELECT country, year,
       co2_emission_tons / NULLIF(area,0) AS emission_per_area
FROM co2_emissions
WHERE year = 2020
ORDER BY emission_per_area ASC
LIMIT 1;
