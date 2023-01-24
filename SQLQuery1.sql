
Select *
From CovidAnalysis..CovidVaccinations

Select *
From CovidAnalysis..CovidDeaths

Select location, date, total_cases, new_cases, cast(total_deaths as int) as total_deaths, population
From CovidAnalysis..CovidDeaths
order by 5 DESC

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of death if you contract covid by country and date
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidAnalysis..CovidDeaths
where location like '%states%'
order by 1, 2

-- Looking at total cases vs population

Select location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
From CovidAnalysis..CovidDeaths
where location like '%states%'
order by 1,2

---- Highest infection rate by countries
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentagePopulationInfected
From CovidAnalysis..CovidDeaths
--where location like '%states%'
Group by location, population
order by PercentagePopulationInfected DESC


-- Highest DeathCount per Location
Select location, MAX(cast(total_deaths as int)) as MaxDeathCount
From CovidAnalysis..CovidDeaths
where continent is not null
Group by location
order by MaxDeathCount DESC


-- Highest death rate by countries
Select location, population, MAX(total_deaths) as HighestDeathCount, MAX(total_deaths/population)*100 as PercentagePopulationDeaths
From CovidAnalysis..CovidDeaths
--where location like '%states%'
Group by location, population
order by PercentagePopulationDeaths DESC


-- Analysis by continent

-- Highest DeathCount per Continent
Select continent, MAX(cast(total_deaths as int)) as MaxDeathCount
From CovidAnalysis..CovidDeaths
where continent is not null
Group by continent
order by MaxDeathCount DESC

-- Highest DeathCount per Continent Attempt II
Select location, MAX(cast(total_deaths as int)) as MaxDeathCount
From CovidAnalysis..CovidDeaths
where continent is null and location IN ('north america', 'south america', 'world', 'asia', 'australia', 'antartica', 'europe', 'africa')
Group by location
order by MaxDeathCount DESC


--  Global numbers

-- Total cases by date

Select date, SUM(total_cases) as TotalCasesToDate, SUM(cast(total_deaths as int)) as TotalDeathsToDate, 
SUM(cast(total_deaths as int))/SUM(total_cases)*100 as PercentDeathForCases
From CovidAnalysis..CovidDeaths
where continent is not NULL
Group by date
Order by 1


Select *
From CovidAnalysis..CovidDeaths dea
Join CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
order by 2, 3

--CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, CumulativeVaccinations)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVaccinations
From CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
--order by 2, 3
)
Select *, (CumulativeVaccinations/Population)*100 as PercentagePopVaccinated
From PopvsVac
order by 2, 3


-- Percentage of Population by Country Vaccinated to Date
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, CumulativeVaccinations)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVaccinations
From CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
--order by 2, 3
)
Select Location, Population, MAX(CumulativeVaccinations), MAX((CumulativeVaccinations)/Population)*100 as PercentagePopVaccinated
From PopvsVac
Group by Location, Population
Order by 4, 1


-- Same but with TEMP TABLE

DROP Table if exists #PercentagePopulationVaccinated
CREATE Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
)

Insert into #PercentagePopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVaccinations
From CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL

Select *, (CumulativeVaccinations/Population)*100 as PercentagePopVaccinated
From #PercentagePopulationVaccinated
order by 2, 3


-- Creating view for visaulization later

DROP View if exists CovidAnalysis.PercentagePopulationVaccinated
GO
USE CovidAnalysis
GO
Create View PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVaccinations
From CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL


-- Using View
Select TOP 100 *
From PercentagePopulationVaccinated