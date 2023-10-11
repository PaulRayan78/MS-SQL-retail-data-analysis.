-- SQL CASE STUDY - RETAIL DATA ANALYSIS - by Paul Rayan

-- Business Context - A retail store would like to understand customer behaviour using their point of sale data (POI).

/* Data Availability - 
	 The data set comprises of the following 3 tables:-
	 Customer: Customer Demographics
	 Transactions: Customer transaction details
	 Product Category: Product category and sub category information */

--    **** DATA PREPARATION AND UNDERSTANDING  ****

-- Q1) What is the total number of rows in each of the 3 tables in the database ?

SELECT * FROM 
(SELECT ' CUSTOMER TABLE ' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Customer UNION ALL
SELECT ' TRANSACTIONS ' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Transactions UNION ALL
SELECT ' PRODUCT CATEGORY ' AS TABLENAME,COUNT(*) AS NO_OF_RECORDS FROM Product_Category
) tbl

-- Q2) What is the total number of transactions that have a return ?

SELECT COUNT(*) AS NUM_OF_TRANSACTIONS_WITH_RETURNS
FROM Transactions
WHERE Qty < 0

-- Q3) Convert date variables to valid date formats before proceeding.

/*SELECT CONVERT(DATE,DOB,101) AS DOB_US
FROM Customer
SELECT CONVERT(DATE,Tran_date,101) AS DOB_US
FROM Transactions */

-- data type is of date type after importing as flash file

-- Q4) What is the time range of the transaction data available for analysis ?
--     Show the output in number of days, months and years simultaneously in different columns.
SELECT MIN(Tran_date) AS Starting_Date,
MAX(Tran_date) AS Ending_Date,
DATEDIFF(DAY,MIN(Tran_date),MAX(Tran_date)) AS Num_of_Days,
DATEDIFF(MONTH,MIN(Tran_date),MAX(Tran_date))+1 AS Num_of_Months,    -- To include month unaccounted for
DATEDIFF(YEAR,MIN(Tran_date),MAX(Tran_date))+1 AS Num_of_Years       -- To include year unaccounted for
FROM Transactions

-- Q5) Which product category does the sub-category "DIY" belong to ?
SELECT prod_cat, prod_subcat
FROM Product_Category
WHERE prod_subcat = 'DIY'


--  ***  DATA ANALYSIS  ***

-- Q1) Which channel is most frequently used for transactions ?

SELECT Store_type,COUNT(Store_type) AS Transactions_Occured     -- gives list of storetypes with no. of transactions from which most frequent channel can be determined
FROM Transactions
GROUP BY Store_type
ORDER BY COUNT(Store_type) DESC

-- Q2) What is the count of Male and Female customers in the database ?

SELECT Gender, COUNT(Gender) AS Count_of_Genders      -- it appears that some customers have not specified their gender hence there is a null column appearing
FROM Customer                                         -- as question doesnt ask for non entry values i have not handled the null values
GROUP BY Gender

-- Q3) From which city do we have the maximum number of customers and how many ?

SELECT city_code, COUNT(city_code) AS NUM_OF_CUSTOMERS              -- no data mentioning city values in any of the tables, however i have summerised by city codes 
FROM Customer                                                       -- null values have not been handled here as its not a requirement of the question.
GROUP BY city_code
ORDER BY COUNT(city_code) DESC

-- Q4) How many sub-categories are there under the books category ?

SELECT prod_cat, COUNT(prod_subcat) AS Num_of_Subcat
FROM Product_Category
WHERE prod_cat = 'Books'
GROUP BY prod_cat

-- Q5) What is the maximum quantity of products ever ordered ?

/*SELECT DISTINCT prod_cat_code, Qty
FROM Transactions
WHERE Qty > 0
ORDER BY Qty DESC */

SELECT B.prod_subcat, B.prod_cat, MAX(Qty) AS Max_Quantity_Ordered   -- Gives a better summary by product subcategory
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
WHERE Qty > 0
GROUP BY B.prod_subcat, B.prod_cat

-- Q6) What is the net total revenue generated in categories 'Electronics and Books' ?

/*SELECT Prod_cat_code, SUM(Total_amt) AS Total_Revenue      -- Without mapping product table
FROM Transactions
WHERE (Prod_cat_code = 3 OR Prod_cat_code = 5)
GROUP BY Prod_cat_code */

SELECT B.prod_cat, SUM(A.Total_amt) AS Total_Revenue
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
WHERE (b.prod_cat = 'Electronics' OR b.prod_cat = 'Books')
GROUP BY B.prod_cat

-- Q7) How many customers have >10 transactions with us, excluding returns ?

SELECT cust_id, COUNT(transaction_id) AS Transactions_greater_than_10
FROM Transactions
WHERE Qty > 0
GROUP BY Cust_id
HAVING COUNT(transaction_id) > 10

-- Q8) What is the combined revenue earned from the "Electronics" & "Clothing" categories,
--     from "Flagship Stores" ?

SELECT Store_type, ROUND(SUM(Total_amt),2) AS Total_Revenue
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code -- mapping
WHERE (B.prod_cat = 'Electronics' OR B.prod_cat = 'Clothing')   --  filtering
GROUP BY Store_type

-- Q9) What is the total revenue generated from 'Male' customers in 'Electronics' category ?
--     Output should display total revenue by prod_subcat.

SELECT B.prod_cat, SUM(Total_amt) AS Total_Revenue
FROM Transactions A
LEFT JOIN Customer ON Cust_id = customer_Id
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code  -- mapping tables to transactions table
WHERE (B.prod_cat = 'Electronics' AND Gender = 'M')   -- filtering
GROUP BY B.prod_cat

-- Q10) What is percentage of sales and returns by product sub_category; display only top 5
--      sub categories in terms of sales.

SELECT TOP 5 B.prod_subcat, B.prod_cat, ROUND(SUM(A.Total_amt),2) AS Net_Sales, ROUND(SUM(A.Total_amt)*100/(SELECT SUM(Total_amt) FROM Transactions),2) AS Percentage_Sales,   -- Calculating percentage sales
(SUM(CASE WHEN A.Qty < 0 THEN A.Qty* -1 ELSE 0 END)*100)/(SELECT SUM(CASE WHEN Qty < 0 THEN Qty* -1 ELSE 0 END) FROM Transactions) AS Percentage_Returns   -- Calculating percentage returns
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
GROUP BY B.prod_cat, B.prod_subcat

-- Q11) For all customers aged between 25 to 35 years find what is the net total revenue generated
--	    by these consumers in the last 30 days of transactions from max transaction date available in the data.

SELECT SUM(A.Total_amt) AS Net_total_Revenue
FROM (SELECT * FROM Transactions WHERE Tran_date BETWEEN DATEADD(DAY,-30,(SELECT MAX(Tran_date)FROM Transactions)) AND (SELECT MAX(Tran_date) FROM Transactions)) A   -- Filtering Last 30 days of transactions
LEFT JOIN Customer ON A.Cust_id = customer_Id
WHERE DOB BETWEEN DATEADD(YEAR,-35,(SELECT MAX(Tran_date) FROM Transactions)) AND DATEADD(YEAR,-25,(SELECT MAX(Tran_date) FROM Transactions))   -- Filtering ages between 25 to 35 years

-- Q12) Which product category has seen the max value of returns in the last 3 months of
--      transactions ?
/*SELECT Prod_cat_code, SUM(Qty) AS No_of_Returns                 --Explicitly mentioning conditions 
FROM Transactions 
WHERE Tran_date > '2013-11-30' AND Qty < 0
GROUP BY prod_cat_code
ORDER BY SUM(Qty) */

SELECT B.prod_cat, SUM(CASE WHEN qty<0 THEN qty*(-1) ELSE 0 END) AS No_of_Returns  --Dynamically specified conditions
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
WHERE  Tran_date > DATEADD(MONTH,-3,(SELECT MAX(Tran_date) FROM Transactions)) 
GROUP BY B.prod_cat
ORDER BY SUM(case WHEN Qty <0 THEN Qty*(-1) ELSE 0 END) Desc

-- Q13) Which store-type sells the maximum products; by value of sales amount and by quantity sold ?

SELECT Store_type, ROUND(SUM(Total_amt),2) AS Total_Sales, SUM(Qty) AS Max_Quantity
FROM Transactions
GROUP BY Store_type
ORDER BY Max_Quantity desc

-- Q14) What are the categories for which average revenue is above the overall average.

SELECT prod_cat, ROUND(AVG(Total_amt),2) AS Average_Revenue,(SELECT ROUND(AVG(Total_amt),2) FROM Transactions) AS Overall_Average
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code
GROUP BY prod_cat
HAVING AVG(Total_amt) > (SELECT AVG(Total_amt) FROM Transactions)


-- Q15) Find the average and total revenue by each subcategory for the categories which are among 
--      top 5 categories in terms of quantity sold.

/* SELECT prod_cat, prod_subcat, AVG(Total_amt) AS Average_Revenue, SUM(Total_amt) AS Total_Revenue --TABLE B   obtaining average and total revenue by each subcategory
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
GROUP BY prod_cat, prod_subcat
ORDER BY prod_cat

SELECT TOP 5 B.prod_cat, SUM(A.Qty) AS Quantity_Sold  --TABLE A  top 5 categories in terms of quantity sold
FROM Transactions A
LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
WHERE A.Qty > 0
GROUP BY B.prod_cat
ORDER by SUM(A.Qty) desc   */

SELECT TBL_A.prod_cat, TBL_B.prod_subcat, TBL_B.Average_Revenue, TBL_B.Total_Revenue 
FROM (SELECT TOP 5 B.prod_cat, SUM(A.Qty) AS Quantity_Sold
	FROM Transactions A
	LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
	WHERE A.Qty > 0
	GROUP BY B.prod_cat
	ORDER by SUM(A.Qty) desc) TBL_A
LEFT JOIN (SELECT prod_cat, prod_subcat, ROUND(AVG(Total_amt),2) AS Average_Revenue, ROUND(SUM(Total_amt),2) AS Total_Revenue
	FROM Transactions A
	LEFT JOIN Product_Category B ON A.Prod_cat_code = B.prod_cat_code AND A.Prod_subcat_code = B.prod_sub_cat_code
	GROUP BY prod_cat, prod_subcat) TBL_B ON TBL_A.prod_cat = TBL_B.prod_cat
