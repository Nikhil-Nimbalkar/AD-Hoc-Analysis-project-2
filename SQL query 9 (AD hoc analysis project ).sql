use retail_events_db;
select * from `dim_campaigns`;
select * from `dim_products`;
select * from `dim_stores`;
select * from `fact_events`;

-- problem 1  Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free). 
-- This information will help us identify high-value products that are currently being heavily discounted,
-- which can be useful for evaluating our pricing and promotion strategies.

select event_id, store_id, campaign_id, product_code, base_price, promo_type
from fact_events

where base_price > 500 and promo_type = 'BOGOF' ;



-- 2.	Generate a report that provides an overview of the number of stores in each city. The results will be sorted in descending order of 
-- store counts, allowing us to identify the cities with the highest store presence. The report includes two essential fields: city and 
-- store count, which will assist in optimizing our retail operations.

select city ,count(store_id) as store_count from dim_stores group by city order by store_count desc;


-- 3.	Generate a report that displays each campaign along with the total revenue generated before and after the campaign? The report 
-- includes three key fields: campaign _name, total revenue(before_promotion), total revenue(after_promotion). This report should help 
-- in evaluating the financial impact of our promotional campaigns. (Display the values in millions).

-- Chnaged the column name for the better syntax
ALTER TABLE retail_events_db.fact_events
CHANGE COLUMN `quantity_sold(before_promo)` quantity_sold_before_promo VARCHAR(50);

ALTER TABLE retail_events_db.fact_events
CHANGE COLUMN `quantity_sold(after_promo)` quantity_sold_after_promo VARCHAR(50);	

SELECT 
    campaign_id, 
    SUM(base_price * quantity_sold_before_promo) / 1000000 AS total_revenue_before_promotion,
    SUM(base_price * quantity_sold_after_promo) / 1000000 AS total_revenue_after_promotion
FROM 
    fact_events
GROUP BY 
    campaign_id;
    
                                 -- OR --
                                 
   select dim_campaigns.campaign_name , sum(Total_revenue_before_promo), sum(Total_revenue_after_promo ) from                             
  (select *, (base_price * quantity_sold_before_promo) as Total_revenue_before_promo, 
 (base_price * quantity_sold_after_promo) as Total_revenue_after_promo from fact_events) as inner_table
 join dim_campaigns on inner_table.campaign_id = dim_campaigns.campaign_id group by dim_campaigns.campaign_name;
 
 
 
 -- 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. Additionally, 
-- provide rankings for the categories based on their ISU%. The report will include three key fields: category, isu%, and rank order. 
-- This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.

-- Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage increase/decrease in quantity sold (after promo) 
-- compared to quantity sold (before promo)

USE retail_events_db;

-- Calculate ISU% and rank categories
SELECT 
    dim_products.category AS Category,
    ROUND(((SUM(fact_events.quantity_sold_after_promo) - SUM(fact_events.quantity_sold_before_promo)) / SUM(fact_events.quantity_sold_before_promo)) * 100, 2) AS ISU_Percentage,
    RANK() OVER (ORDER BY ((SUM(fact_events.quantity_sold_after_promo) - SUM(fact_events.quantity_sold_before_promo)) / SUM(fact_events.quantity_sold_before_promo)) DESC) AS Rank_Order
FROM 
    fact_events
JOIN 
    dim_products ON fact_events.product_code = dim_products.product_code
WHERE 
    fact_events.campaign_id = 'CAMP_DIW_01' 
GROUP BY 
    dim_products.category;
                                 
                                 
   
  -- 5.Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. The report 
-- will provide essential information including product name, category, and ir%. This analysis helps identify the most successful products
-- in terms of incremental revenue across our campaigns, assisting in product optimization.

-- Note: The submissions are evaluated based on the query readability, logic, and also presentation of the result

USE retail_events_db;

-- Calculate Incremental Revenue Percentage (IR%) and rank products
WITH product_revenue AS (
    SELECT 
        dim_products.product_name,
        dim_products.category,
        fact_events.product_code,
        SUM(fact_events.base_price * fact_events.quantity_sold_before_promo) AS revenue_before_promo,
        SUM(fact_events.base_price * fact_events.quantity_sold_after_promo) AS revenue_after_promo
    FROM 
        fact_events
    JOIN 
        dim_products ON fact_events.product_code = dim_products.product_code
    GROUP BY 
        dim_products.product_name, dim_products.category, fact_events.product_code
),
product_ir AS (
    SELECT
        product_name,
        category,
        ROUND((revenue_after_promo - revenue_before_promo) / revenue_before_promo * 100, 2) AS IR_Percentage
    FROM 
        product_revenue
)
SELECT
    product_name AS Product_Name,
    category AS Category,
    ir_percentage
FROM
    product_ir
ORDER BY
    ir_percentage DESC
LIMIT 5;


                                      -- OR
                                      
select inner_table.product_code,dim_products.product_name,dim_products.category,
round((SUM(rev_after_promo) - SUM(rev_before_promo)) / SUM(rev_before_promo) * 100, 2) AS IR_Percentage

from                                       

(select * ,(base_price * quantity_sold_before_promo) as rev_before_promo,
(base_price * quantity_sold_after_promo) as rev_after_promo from fact_events ) as inner_table 
join dim_products on inner_table.product_code = dim_products.product_code
group by inner_table.product_code
order by  IR_percentage desc limit 5 ; 
                                 
                         
                                 
                                 



