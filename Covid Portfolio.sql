#total cases vs total deaths
#shows liklihood of dying if you contract covid by country over time
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidData.coviddeaths;

#total cases vs population in U.S.
#shows what percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as CatchingCovidLiklihood
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
	and dea.date = vac.date;

#Total population vs vaccination
select dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations as DOUBLE) 
as new_vaccinations, SUM(cast(vac.new_vaccinations as DOUBLE)) over (partition by dea.location order by dea.location) as RollingPeopleVaccinated
from CovidData.coviddeaths dea
Join CovidData.covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date;
#where dea.continent is not null;

#USE CTE
with populationVSvaccination (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, cast(dea.date as DATE) as date, dea.population, cast(vac.new_vaccinations as DOUBLE)
as new_vaccinations, SUM(cast(vac.new_vaccinations as DOUBLE)) over (partition by dea.location order by dea.location, cast(dea.date as DATE)) as RollingPeopleVaccinated
from CovidData.coviddeaths dea
Join CovidData.covidvaccinations vac
	on dea.location = vac.location
	and cast(dea.date as DATE) = cast(vac.date as DATE)
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from populationVSvaccination;

Create view Table1 as
select dea.continent, dea.location, dea.population, MAX(cast(vac.new_vaccinations as DOUBLE))
, SUM(cast(vac.new_vaccinations as DOUBLE)) over (partition by dea.location order by dea.location) as RollingPeopleVacinated
from CovidData.coviddeaths dea
join CovidData.covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null;