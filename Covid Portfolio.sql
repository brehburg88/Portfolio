#Fixing dates from string to date
alter table CovidData.coviddeaths add column n_date DATE;
update CovidData.coviddeaths
set n_date = str_to_date(date, '%m/%d/%Y');

alter table CovidData.covidvaccinations add column n_date DATE;
update CovidData.covidvaccinations
set n_date = str_to_date(date, '%m/%d/%Y');

#total cases vs total deaths
#shows liklihood of dying if you contract covid by country over time
select location, n_date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidData.coviddeaths;

#total cases vs population in U.S.
#shows what percentage of population got covid
select location, n_date, population, total_cases, (total_cases/population)*100 as CatchingCovidLiklihood
from CovidData.coviddeaths
where location like '%united states%';

#Countries with highest infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as CatchingCovidLiklihood
from CovidData.coviddeaths
group by location, population
order by CatchingCovidLiklihood desc;

#Showing Countries with highest death count per population
select location, MAX(cast(total_deaths as DECIMAL)) as TotalDeathCount
from CovidData.coviddeaths
where continent is not null
group by location
order by TotalDeathCount desc;

#Breaking down death count by continent
select continent, MAX(cast(total_deaths as DECIMAL)) as TotalDeathCount
from CovidData.coviddeaths
where continent is not null
group by continent
order by TotalDeathCount desc;

#Global numbers
select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from CovidData.coviddeaths
where continent is not null;

#Joining covid deaths and covid vaccinations
select *
from CovidData.coviddeaths dea
join CovidData.covidvaccinations vac
	on dea.location = vac.location
	and dea.n_date = vac.n_date;

#Total population vs vaccination
select dea.continent, dea.location, dea.n_date, dea.population, vac.new_people_vaccinated_smoothed, 
SUM(vac.new_vaccinations) over 
(partition by dea.location order by dea.location, dea.n_date) as RollingPeopleVaccinated
from CovidData.coviddeaths dea
Join CovidData.covidvaccinations vac
	on dea.location = vac.location
	and dea.n_date = vac.n_date
where dea.continent is not null
order by 2,3;

#USE CTE
with populationVSvaccination (continent, location, n_date, population, new_people_vaccinated_smoothed, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.n_date, dea.population, vac.new_people_vaccinated_smoothed,
SUM(vac.new_people_vaccinated_smoothed) over (partition by dea.location order by dea.location, dea.n_date) as RollingPeopleVaccinated1Dose
from CovidData.coviddeaths dea
Join CovidData.covidvaccinations vac
	on dea.location = vac.location
	and dea.n_date = vac.n_date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 as RollingVaccinatedPercent1Dose
from populationVSvaccination;

#Temp table
drop table if exists PercentPopulationVaccinated;
create table PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
n_date date,
population INT,
new_people_vaccinated_smoothed TEXT,
RollingPeopleVaccinated DECIMAL
);

Insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.n_date, dea.population, vac.new_people_vaccinated_smoothed,
SUM(vac.new_people_vaccinated_smoothed) over (partition by dea.location order by dea.location, dea.n_date) as RollingPeopleVaccinated
from CovidData.coviddeaths dea
join CovidData.covidvaccinations vac
	on dea.location = vac.location
    and dea.n_date = vac.n_date
where dea.continent is not null;

select *, (RollingPeopleVaccinated/population)*100
from PercentPopulationVaccinated;

#Creating view to store data for visualizations
Create view RollingPopulationVaccinated as
select dea.continent, dea.location, dea.n_date, dea.population, vac.new_people_vaccinated_smoothed, 
SUM(vac.new_people_vaccinated_smoothed) over (partition by dea.location order by dea.location, dea.n_date) as RollingPeopleVacinated1Dose
from CovidData.coviddeaths dea
join CovidData.covidvaccinations vac
	on dea.location = vac.location
    and dea.n_date = vac.n_date
where dea.continent is not null
group by dea.continent, dea.location, dea.n_date, dea.population, vac.new_people_vaccinated_smoothed;