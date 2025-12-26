use highcloud_airlines;
Desc maindata;
SELECT * FROM maindata;

ALTER TABLE maindata ADD COLUMN `Loadfactor%` int;

# Row Level - Calculation of Loadfactor%
UPDATE maindata SET `Loadfactor%` =CASE WHEN Available_Seats = 0 THEN Null
ELSE Transported_Passengers*100.0 / Available_Seats
END;

ALTER TABLE maindata 
MODIFY COLUMN `Loadfactor%` DECIMAL(5,2);


# Total Load factor%-
SELECT ROUND(SUM(Transported_Passengers)*100/SUM(Available_Seats),2) AS `Total_Load_Factor%` from maindata;

# Year wise Load-factor%
SELECT Year, ROUND(SUM(Transported_Passengers)*100/SUM(Available_Seats),2) as Total_Loadfactor from maindata
GROUP BY Year;

ALTER TABLE maindata RENAME COLUMN `Month (#)` to Month_No;
ALTER TABLE maindata ADD COLUMN Dates date;
UPDATE maindata set Dates = str_to_date(CONCAT(Year,'-', Month_No,'-', Day),"%Y-%m-%d")
WHERE Year IS NOT NULL 
AND Month_No IS NOT NULL
AND DAY IS NOT NULL;

# Year-Month wise Load factor % -
SELECT Year, Month_No ,monthname(Dates) as Month_name,
ROUND(SUM(Transported_Passengers)*100/SUM(Available_Seats),2) as Total_Loadfactor from maindata
GROUP BY 1,2,3 ORDER BY 1,2;

# Quarter wise Load-factor% -
SELECT CONCAT("Q-",Quarter(Dates)) AS Quarters, 
ROUND(SUM(Transported_Passengers)*100/SUM(Available_Seats),2) AS Load_Factor
FROM maindata GROUP BY Quarters ORDER BY Quarters;

# Year - Quarter Wise Load-Factor -
SELECT Year, CONCAT("Q-",Quarter(Dates)) AS Quarters,
ROUND(SUM(Transported_Passengers)*100/SUM(Available_Seats),2) AS Load_Factor from maindata
GROUP BY Year, Quarters ORDER BY Year, Quarters; 

# Top 10 Carrier Names by Load-Factor% -
SELECT Carrier_Name, ROUND(SUM(Transported_Passengers)*100/NULLIF(SUM(Available_Seats),0),2) AS Loadfactor 
FROM maindata Group by Carrier_Name Having SUM(Available_Seats) > 0 Order by Loadfactor DESC Limit 10;

# Load-factor% based on Routes Grouped by carrier names -
SELECT Carrier_Name, `From - To City`,
ROUND(SUM(Transported_Passengers)*100.0/NULLIF(SUM(Available_Seats),0),2) AS Loadfactor 
FROM maindata GROUP BY Carrier_Name, `From - To City` HAVING SUM(Available_Seats)>0 
ORDER BY Loadfactor DESC; 

# Distribution Check - how load factor varies across individual records (rows) Grouped by Carrier Names
SELECT Carrier_Name, MIN(`Loadfactor%`) AS Min_LF, MAX(`Loadfactor%`) AS Max_LF,
ROUND(AVG(`Loadfactor%`),2) AS Avg_LF FROM maindata GROUP BY Carrier_Name;

# YOY Load Factor -
SELECT Year, Loadfactor, Last_Year_LF, ROUND((Loadfactor- Last_Year_LF)*100/NULLIF(Last_Year_LF,0),2) AS YOY FROM(
SELECT Year, Loadfactor, LAG(Loadfactor) OVER(ORDER BY Year) AS Last_Year_LF FROM(
SELECT Year, ROUND(SUM(Transported_Passengers)*100.0/NULLIF(SUM(Available_Seats),0),2) AS Loadfactor FROM 
maindata GROUP BY Year ORDER BY Year)M) T;

# MOM Load Factor
SELECT Year, Month_Name, Load_Factor, Prev_Month_LF, ROUND((Load_Factor - Prev_Month_LF)*100/NULLIF(Prev_Month_LF,0),2) AS MOM FROM(
SELECT Year, Month_No, Month_Name, Load_Factor, 
LAG(Load_Factor) OVER(ORDER BY Year, Month_No) AS Prev_Month_LF FROM(
SELECT Year, Month_No, Monthname(Dates) AS Month_Name, 
ROUND(SUM(Transported_Passengers)*100/NULLIF(SUM(Available_Seats),0),2)
AS Load_Factor FROM maindata GROUP BY Year, Month_No, Month_Name ORDER BY Year, Month_No)M) T;

# Quarter Wise Load_Factor -
SELECT Year, Quarters, Load_Factor, Prev_Quarter_LF, ROUND((Load_Factor - Prev_Quarter_LF)*100/NULLIF(Prev_Quarter_LF,0),2) AS QOQ FROM(
SELECT Year, Quarters, Load_Factor, 
LAG(Load_Factor) OVER(ORDER BY Year,Quarters) AS Prev_Quarter_LF FROM(
SELECT Year, CONCAT("Qtr-",Quarter(Dates)) AS Quarters, 
ROUND(SUM(Transported_Passengers)*100/NULLIF(SUM(Available_Seats),0),2)
AS Load_Factor FROM maindata GROUP BY Year, Quarters ORDER BY Year, Quarters)M) T;

# Top 10 most travelled Destination City -
SELECT Destination_City, SUM(Transported_Passengers) AS Passengers_Count
FROM maindata GROUP BY Destination_City ORDER BY Passengers_Count DESC Limit 10;

# Top 10 Routes that Passengers travelled -
SELECT `From - To City`, SUM(Transported_Passengers) AS Passengers_Count 
FROM maindata GROUP BY `From - To City` ORDER BY Passengers_Count DESC Limit 10;

# Top Destination Markets by LoadFactor% -
SELECT Destination_City, ROUND(SUM(Transported_Passengers)*100/NULLIF(SUM(Available_Seats),0),2) AS Load_Factor 
FROM maindata GROUP BY Destination_City ORDER BY Load_Factor DESC LIMIT 10;

# Top Routes by Load Factor% - 
SELECT `From - To City`, ROUND(SUM(Transported_Passengers)*100/NULLIF(SUM(Available_Seats),0),2) AS Load_Factor 
FROM maindata GROUP BY `From - To City` ORDER BY Load_Factor DESC LIMIT 10;

Rename table `aircraft groups` to aircraft_groups;
ALTER TABLE aircraft_groups RENAME COLUMN `ï»¿%Aircraft Group ID` to Aircraft_group_ID;
ALTER TABLE aircraft_groups RENAME COLUMN `Aircraft Group` to Aircraft_Group;

# Load Factor % Based on Aircraft Groups - 
SELECT A.Aircraft_Group, ROUND(SUM(M.Transported_Passengers)*100/NULLIF(SUM(M.Available_Seats),0),2) AS Load_Factor 
FROM maindata AS M LEFT JOIN aircraft_groups AS A ON M.`%Aircraft Group ID` = A.Aircraft_group_ID 
GROUP BY A.Aircraft_Group;

ALTER TABLE aircraft_types RENAME COLUMN `ï»¿%Aircraft Type ID` TO Aircraft_Type_ID;
ALTER TABLE aircraft_types RENAME COLUMN `Aircraft Type` TO Aircraft_Types;

# Load Factor % Based on Aircraft Types - 
SELECT A.Aircraft_Types, ROUND(SUM(M.Transported_Passengers)*100/NULLIF(SUM(M.Available_Seats),0),2) AS Load_Factor 
FROM maindata AS M LEFT JOIN aircraft_types AS A ON M.`%Aircraft Type ID` = A.Aircraft_Type_ID
GROUP BY A.Aircraft_Types;

ALTER TABLE `destination markets` RENAME COLUMN `Destination Market` TO Destination_Markets;
ALTER TABLE `destination markets`  RENAME TO Destination_Markets;

# Load Factor % Based on Destination markets - 
SELECT A.Destination_Markets, ROUND(SUM(M.Transported_Passengers)*100/NULLIF(SUM(M.Available_Seats),0),2) AS Load_Factor 
FROM maindata AS M LEFT JOIN Destination_Markets AS A ON M.`%Destination Airport Market ID` = A.`%Destination Airport Market ID`
GROUP BY A.Destination_Markets;

ALTER TABLE `distance groups` Rename to Distance_Groups;
ALTER TABLE Distance_Groups RENAME COLUMN `ï»¿%Distance Group ID` TO Distance_Group_ID;
ALTER TABLE Distance_Groups RENAME COLUMN `Distance Interval` TO Distance_Interval;

# Load factor % Based on Distance groups -
SELECT A.Distance_Interval, ROUND(SUM(M.Transported_Passengers)*100/NULLIF(SUM(M.Available_Seats),0),2) AS Load_Factor 
FROM maindata AS M LEFT JOIN Distance_Groups AS A ON M.`%Distance Group ID` = A.Distance_Group_ID
GROUP BY A.Distance_Interval;

ALTER TABLE `flight types` RENAME TO Flight_Types;
ALTER TABLE Flight_Types RENAME COLUMN `ï»¿%Datasource ID` TO Datasource_ID;
ALTER TABLE Flight_Types RENAME COLUMN `Flight Type` TO Flight_Types;

# Load factor % Based on Flight Types -
SELECT A.Flight_Types, ROUND(SUM(M.Transported_Passengers)*100/NULLIF(SUM(M.Available_Seats),0),2) AS Load_Factor 
FROM maindata AS M LEFT JOIN Flight_Types AS A ON M.`%Datasource ID` = Datasource_ID
GROUP BY A.Flight_Types;

# Rolling Load Factor - year, months, aircraft groups
SELECT Year, Month_No, Month_name, coalesce(Aircraft_Group,"Unknown Aircraft Group")AS Aircraft_Groups, ROUND(SUM(Total_Passengers) OVER(Partition by 
coalesce(Aircraft_Group,"Unknown Aircraft Group") Order by Year, Month_No ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)*100.0 / NULLIF(SUM(Total_Available_Seats) 
OVER(Partition by coalesce(Aircraft_Group,"Unknown Aircraft Group") Order by Year, Month_No ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),0),2) AS Rolling_Total_Loadfactor From(
SELECT M.Year, M.Month_No, Monthname(M.Dates) AS Month_name, A.Aircraft_Group,
SUM(M.Transported_Passengers) AS Total_Passengers, SUM(M.Available_Seats)AS Total_Available_Seats 
FROM maindata AS M LEFT JOIN aircraft_groups AS A ON M.`%Aircraft Group ID` = A.Aircraft_group_ID 
GROUP BY M.Year, M.Month_No, Month_name, A.Aircraft_Group
ORDER BY M.Year, M.Month_No, A.Aircraft_Group)M;

# Contribution analysis - Route Contribution to Total Passengers
SELECT `From - To City`, SUM(Transported_Passengers) AS Total_Passengers,
ROUND(SUM(Transported_Passengers)*100.0/ NULLIF(SUM(SUM(Transported_Passengers)) OVER(),0),2) AS Contribution_Percent
FROM maindata GROUP BY `From - To City` ORDER BY Contribution_Percent DESC;

# Underperforming routes - High Capacity but Low Load Factor Routes
SELECT * FROM(
SELECT `From - To City`, SUM(Available_Seats) AS Total_Seats, 
ROUND(SUM(Transported_Passengers)*100.0/NULLIF(SUM(Available_Seats),0),2) AS Load_Factor,
ROUND(AVG(SUM(Available_Seats)) OVER(),2) AS Avg_Route_Seats
FROM maindata GROUP BY `From - To City`)T WHERE Load_Factor < 60 AND 
Total_Seats > Avg_Route_Seats;

# Data quality check - Missing Dimension Mapping Check
SELECT COUNT(*) AS Unmapped_Records FROM maindata M
LEFT JOIN aircraft_groups A ON M.`%Aircraft Group ID` = A.Aircraft_group_ID
WHERE A.Aircraft_group_ID IS NULL;

