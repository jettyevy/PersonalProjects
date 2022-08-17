--select *
--from PortfolioProject..CovidDeaths
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

--looking at total cases vs total deaths
-- Shows likelihood of dying in singapore if one contracts covid (pretty low)
select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100.0 as death_percentage
from PortfolioProject..CovidDeaths
where location like 'Singapore'
order by 1,2


--by far 04/04/2020 is the date with the high percentage 0.5% chance of dying in singapore
select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100.0 as death_percentage
from PortfolioProject..CovidDeaths
where location like 'Singapore'
order by death_percentage desc

--Looking at total cases vs population
--shows what percentage of population has gotten covid
--interestingly, population has not changed across the dates, so there may be a skew
select location, date, total_cases, population, (total_cases/population) * 100.0 as infection_rate
from PortfolioProject..CovidDeaths
where location like 'Singapore'
order by 1,2

--finding out which country has highest max infection rates
select location, population, max(total_cases) as max_infection_count, max(total_cases/population) * 100.0 as max_infection_rate
from PortfolioProject..CovidDeaths
group by location, population
order by max_infection_rate desc

--finding out which country has highest averege infection rates
select location, population, avg(total_cases) as avg_infection_count, avg(total_cases/population) * 100.0 as avg_infection_rate
from PortfolioProject..CovidDeaths
group by location, population
order by avg_infection_rate desc

--finding out countries with highest death count per country
select location, max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by total_death_count desc

--showing continents with the highest death counts
select continent, max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by total_death_count desc

--global numbers
select sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
		sum(cast(new_deaths as int))/sum(new_cases) * 100 as death_percentage
from portfolioproject..CovidDeaths
where continent is not null
order by 1,2


--looking at total population vs vaccination
--note: overflow error from converting to int -> convert to bigint instead
--use cte
with PvS (continent, location, date, population, new_vaccinations, rolling_vaccinated)
as(
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_vaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
--order by 2,3
)
select *, (rolling_vaccinated/population)*100
from PvS

--Temp table
drop table if exists PercentPopulationVaccinated
create table PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccincations numeric,
rolling_vaccinated numeric)

insert into PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_vaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3

select *, (rolling_vaccinated/population)*100 as rolling_vac_percentage
from PercentPopulationVaccinated


drop view PercentPopulationVaccinated
--Create view to store data for visualisation
create view PortfolioProject.PercentPopulationVaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_vaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
