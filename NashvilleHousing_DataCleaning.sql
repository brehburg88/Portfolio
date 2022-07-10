#Data Cleaning Project-------------------------------------------------------------------------------------------------------

select * 
from HousingData.NashvilleHousing;

#Standardize date format-----------------------------------------------------------------------------------------------------
alter table HousingData.NashvilleHousing add column n_saledate DATE;
SET SQL_SAFE_UPDATES = 0;
update HousingData.NashvilleHousing
set n_saledate = str_to_date(SaleDate, '%M %d, %Y');

#populate property address data----------------------------------------------------------------------------------------------
update HousingData.NashvilleHousing 
set PropertyAddress = NULL 
where PropertyAddress = '';

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.PropertyAddress, b.PropertyAddress)
from HousingData.NashvilleHousing a
join HousingData.NashvilleHousing b
	on a.ParcelID = b.ParcelID
    and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

update HousingData.NashvilleHousing a
	join HousingData.NashvilleHousing b
    on a.ParcelID = b.ParcelID
set PropertyAddress = ifnull(a.PropertyAddress, b.PropertyAddress)
where a.PropertyAddress is null;

#Breaking out property address into individual columns (address, city, state)------------------------------------------------
select
substring(PropertyAddress, 1, locate(',', PropertyAddress)-1) as Address,
substring(PropertyAddress, locate(',', PropertyAddress)+1, length(PropertyAddress)) as Address 
from HousingData.NashvilleHousing;

alter table HousingData.NashvilleHousing
add PropertySplitAddress nvarchar(255);
update HousingData.NashvilleHousing
set PropertySplitAddress = substring(PropertyAddress, 1, locate(',', PropertyAddress)-1);

alter table HousingData.NashvilleHousing
add PropertySplitCity nvarchar(255);
update HousingData.NashvilleHousing
set PropertySplitCity = substring(PropertyAddress, locate(',', PropertyAddress)+1, length(PropertyAddress));

#Breaking out owner address into individual columns (address, city, state)---------------------------------------------------
select
substring_index(OwnerAddress, ',', 1),
substring_index(substring_index(OwnerAddress, ',', 2), ',', -1),
substring_index(OwnerAddress, ',', -1)
from HousingData.NashvilleHousing;

alter table HousingData.NashvilleHousing
add OwnerSplitAddress nvarchar(255);
update HousingData.NashvilleHousing
set OwnerSplitAddress = substring_index(OwnerAddress, ',', 1);

alter table HousingData.NashvilleHousing
add OwnerSplitCity nvarchar(255);
update HousingData.NashvilleHousing
set OwnerSplitCity = substring_index(substring_index(OwnerAddress, ',', 2), ',', -1);

alter table HousingData.NashvilleHousing
add OwnerSplitState nvarchar(255);
update HousingData.NashvilleHousing
set OwnerSplitState = substring_index(OwnerAddress, ',', -1);

#Change Y and N to yes and no in "sold as vacant" field----------------------------------------------------------------------
select distinct(SoldAsVacant), count(SoldAsVacant)
from HousingData.NashvilleHousing
group by SoldAsVacant
order by 2;

select SoldAsVacant,
	case when SoldAsVacant = 'Y' then 'Yes'
    when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
    end
from HousingData.NashvilleHousing;

update HousingData.NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
    end;
    
#Remove duplicates-----------------------------------------------------------------------------------------------------------
with RowNumCTE as (
select *,
	row_number() over (
    partition by ParcelID, SalePrice, PropertyAddress, SaleDate, LegalReference
    order by UniqueID) as row_num
from HousingData.NashvilleHousing
)

delete
from RowNumCTE
where row_num > 1;

#Delete unused columns-------------------------------------------------------------------------------------------------------
Select *
from HousingData.NashvilleHousing;

alter table HousingData.NashvilleHousing
drop column OwnerAddress, 
drop column TaxDistrict, 
drop column PropertyAddress;

alter table HousingData.NashvilleHousing
drop column SaleDate;