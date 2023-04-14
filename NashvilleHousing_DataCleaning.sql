SELECT * 
FROM NashvilleHousing;

SELECT SaleDate, CONVERT(date, SaleDate) AS corrected_SaleDate, COUNT(*) AS daily_sales
FROM NashvilleHousing
GROUP BY SaleDate
ORDER BY SaleDate;



/********************CONVERTING THE FORMAT OF 'SaleDate' to 'YYYY-MM-DD' instead of 'YYYY-MM-DD HH.MM.SS.MS'*********************/

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate); 

SELECT SaleDate
FROM NashvilleHousing
GROUP BY SaleDate
ORDER BY SaleDate;

-- the above update function though seemed to execute succesfully, yet doesn't change the output. so going for another approach

UPDATE NashvilleHousing
SET SaleDate = FORMAT(SaleDate, 'yyyy-MM-dd');

SELECT SaleDate
FROM NashvilleHousing;

-- still executing successfully but changes aren't getting impemented. let's try altering the attribute data type and executing again.

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date;

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate);

SELECT SaleDate
FROM NashvilleHousing
GROUP BY SaleDate
ORDER BY SaleDate;  /*This above query batch is working. Problem was that the attribute has been defined as datetime format in the table
					and so despite the update function, when invoking the table through select, it still displays date with time as 
					the column is stil in datetime format. so first,we altered the column format from datetime to date and then updated 
					the data to reflect on the same.*/



/************************************************ADDRESS DATA REPOPULATING*******************************************************/					 

SELECT PropertyAddress, COUNT(*) AS number_of_units
FROM NashvilleHousing
GROUP BY PropertyAddress; --this reveals that there are 45069 unique addresses and 29 units with no address (NULL).

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL 
AND TaxDistrict IS NULL; /*out of the 29 address-less records, 11 have no data on OwnerName, OwnerAddress, Acreage, TaxDistrict, 
						  LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath and HalfBath - so basically useless data*/

WITH REPOPULATING_ADDRESS_THROUGH_PARCELID 
AS
(SELECT ParcelID
FROM NashvilleHousing
WHERE PropertyAddress IS NULL 
)
SELECT *
FROM NashvilleHousing
WHERE ParcelID IN (SELECT * FROM REPOPULATING_ADDRESS_THROUGH_PARCELID)
ORDER BY ParcelID; /*The 'ParcelID' of properties without address(NULL) data has been filtered out with a CTE and 
					in the following select query all properties under these 'ParcelID's are filtered out. 
					All properties in a particular 'ParcelID' share the same address which means if a property with address 
					shares 'ParcelID' with a property not having address data, then the missing data of the latter can be 
					filled using the data from the former*/


--DROP TABLE IF EXISTS #TEMPADDRESSTABLE 
--CREATE TABLE #TEMPADDRESSTABLE 
--( ParcelID nvarchar(255),
--  PropertyAddress nvarchar(255)
--)
--;

--WITH REPOPULATING_ADDRESS_THROUGH_PARCELID 
--AS
--(SELECT ParcelID
--FROM NashvilleHousing
--WHERE PropertyAddress IS NULL 
--)
--INSERT INTO #TEMPADDRESSTABLE (ParcelID, PropertyAddress)
--SELECT DISTINCT ParcelID, PropertyAddress
--FROM NashvilleHousing
--WHERE ParcelID IN (SELECT * FROM REPOPULATING_ADDRESS_THROUGH_PARCELID) AND  PropertyAddress IS NOT NULL
--;

--SELECT * 
--FROM #TEMPADDRESSTABLE;

--UPDATE NashvilleHousing
--SET PropertyAddress = ( SELECT PropertyAddress FROM #TEMPADDRESSTABLE WHERE #TEMPADDRESSTABLE.ParcelID = NashvilleHousing.ParcelID )
--WHERE ParcelID IN ( SELECT ParcelID FROM #TEMPADDRESSTABLE )
--;

--SELECT * 
--FROM NashvilleHousing
--WHERE PropertyAddress IS NULL;

SELECT * 
FROM NashvilleHousing a 
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
ORDER BY a.[UniqueID ], b.[UniqueID ];
/*All 'ParcelID' fields have same address. so a NULL address field can be filled with the address from another field which shares
the same 'ParcelID'. JOIN is performed to get a row like (parcelid.propertyaddresNULL, parcelid.propertyaddressNOTNULL).
the join is filtered out with only NULL propertyaddress rows from left. But (pID.propaddNULL, pID.propaddNULL) combination 
is also possible. so we alter the JOIN with an additional condition of UqID <> UqID, so that NULL columns which share 
same unique id dont get joined. */

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM NashvilleHousing a 
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

SELECT *
FROM NashvilleHousing 
WHERE OwnerName IS NULL AND OwnerAddress IS NULL /*AND PropertyAddress IS NULL*/
ORDER BY ParcelID; /*There are 30,462 rows with no information on OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue,
TotalValue, YEarBuilt, Bedrooms, FullBath, HalfBath. BUT ALL THESE FIELDS HAVE PROPERTY ADDRESS AND ITS CORRESPONDING DETAILS LIKE
SALEDATE, LEGALREFERENCE ETC. */

SELECT  a.[UniqueID ], a.ParcelID, a.OwnerAddress, b.[UniqueID ], b.ParcelID, b.OwnerAddress
FROM NashvilleHousing a 
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.OwnerAddress IS NULL
ORDER BY a.[UniqueID ], b.[UniqueID ]; /*checked if owneraddress also has similar address sharing across parcels. All the fields with 
missing owner details have unique parcelIDs -implies- cannot fill them like property address. */


/**********************************************ADDRESS DATA PARSING******************************************************/

SELECT PropertyAddress
FROM NashvilleHousing;

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS HOUSELOCATION,
	   TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))) AS LOCATIONCITY,
	   ParcelID
FROM NashvilleHousing;

CREATE TABLE #PROPERTYADDRESSPARSING
(
houselocation nvarchar(255),
locationcity nvarchar(255),
ParcelID nvarchar(255)
)

INSERT INTO #PROPERTYADDRESSPARSING
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS HOUSELOCATION,
	   TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))) AS LOCATIONCITY,
	   ParcelID
FROM NashvilleHousing;

SELECT * 
FROM #PROPERTYADDRESSPARSING

SELECT a.ParcelID, a.PropertyAddress, b.houselocation, b.locationcity, b.ParcelID
FROM NashvilleHousing a
JOIN #PROPERTYADDRESSPARSING b
ON a.ParcelID = b.ParcelID;

ALTER TABLE NashvilleHousing 
ADD HouseLocation nvarchar(255),
	LocationCity nvarchar(255);

UPDATE a
SET a.HouseLocation = b.houselocation, a.LocationCity = b.locationcity
FROM NashvilleHousing a
JOIN #PROPERTYADDRESSPARSING b
ON a.ParcelID = b.ParcelID;

SELECT PropertyAddress, ParcelID, HouseLocation, LocationCity 
FROM NashvilleHousing;

/*NOTE : propertyaddress column in table nashvillehousing is split and added into the same table as houselocation and locationcity
creation of a temptable and updating original table through a join on temptable has overhead in process. the update of new columns from
a substring of another column in the same table can be set directly in the update statement after altering the table for new columns 
i.e., UPDATE NashvilleHousing 
	  SET houselocation = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
		  locationcity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))) */

SELECT 
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 3) AS OwnerLocation,
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 1) AS OwnerState
FROM NashvilleHousing;

SELECT OwnerCity, COUNT(OwnerCity) AS citywise_salesnumbers
FROM
(
SELECT 
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 3) AS OwnerLocation,
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME( REPLACE (OwnerAddress, ',', '.'), 1) AS OwnerState
FROM NashvilleHousing
) AS NAHOOWNCITY
GROUP BY OwnerCity
ORDER BY 2 DESC;


ALTER TABLE NashvilleHousing
ADD OwnerLocation nvarchar(255),
	OwnerCity nvarchar(255),
	OwnerState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerLocation = PARSENAME( REPLACE (OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME( REPLACE (OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME( REPLACE (OwnerAddress, ',', '.'), 1);

SELECT ParcelID, PropertyAddress, OwnerAddress, OwnerLocation, OwnerCity, OwnerState
FROM NashvilleHousing;


/**************************************NORMALIZATION OF BOOLEAN DATA TO AVOID INCONSISTENCIES**********************************/

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS istrue
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;
-- distinct i/p identified as Y, N, Yes, No. most prevelant - Yes and No. Y and N convertion to Yes and No respectively for normalization.

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
				   WHEN SoldAsVacant = 'Y' THEN 'YES'
				   WHEN SoldAsVacant = 'N' THEN 'NO'
				   ELSE SoldAsVacant
				   END

/**************************NORMALIZATION OF TABLE FROM REDUNDANCIES - ELIMINATE DUPLICATE RECORDS*********************************/

SELECT *
FROM (
SELECT ParcelID, SaleDate, SalePrice, LegalReference,
ROW_NUMBER() OVER ( PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY ParcelID) AS partition_count
FROM NashvilleHousing
) AS RWN
WHERE partition_count > 1
;

/* 175 02 0B 137.00	2014-12-19	121590	20141230-0118712
   175 02 0B 137.00	2015-12-28	140000	20151231-0131664 - In these two records though parcel id is the same the saledate, price 
   and legalreference are unique and so they are two seperate sales records of two different blocks of plots from the same parcel
   while
   175 06 0A 001.00	2015-02-02	187000	20150203-0010184	1
   175 06 0A 001.00	2015-02-02	187000	20150203-0010184	2 - here there is no grounds or inference to believe they are two seperate 
   blocks as every crucial detail including legal reference of sales is the same. this is duplicate */

WITH DUPLICATEROWS AS 
(
SELECT ParcelID, SaleDate, SalePrice, LegalReference,
ROW_NUMBER() OVER ( PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY ParcelID) AS partition_count
FROM NashvilleHousing
) 
DELETE 
FROM DUPLICATEROWS
WHERE partition_count > 1;


/******************NORMALIZATION OF ATTRIBUTES - DELETING REDUNDANT ATTRIBUTES PropertyAddress and OwnerAddress 
                          which have been extracted into much useful and operable atomic attributes************************************/

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress;

SELECT * FROM NashvilleHousing;


























