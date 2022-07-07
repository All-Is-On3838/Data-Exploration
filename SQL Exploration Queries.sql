/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

 Select *
 From [Portfolio Project].[dbo].[CovidDeath]
 Where continent is not null 
 order by 3,4

 --Looking at Total Cases vs Total Death
 --Chance of death if infected
 SELECT Location, date, total_cases, total_deaths, NULLIF(CONVERT(float,total_deaths),0)/NULLIF(CONVERT(float,total_cases),0)*100 as DeathPercent
 FROM [Portfolio Project].[dbo].[CovidDeath]
 WHERE Location LIKE 'Taiwan'

-- Looking at Total Cases vs Population
-- Chance of infection
SELECT Location, date, total_cases, population, NULLIF(CONVERT(float, total_cases),0)/NULLIF(CONVERT(float, population),0)*100 as InfectionRate
FROM [Portfolio Project].[dbo].[CovidDeath]
WHERE Location LIKE 'Taiwan'

-- Countries with highest infection rates by population
SELECT Location, MAX(total_cases) as HighestInfectionCount, population, MAX(NULLIF(CONVERT(float, total_cases),0)/NULLIF(CONVERT(float, population),0)*100) as PercentPopulationInfected
FROM [Portfolio Project].[dbo].[CovidDeath]
GROUP BY population, location
ORDER BY PercentPopulationInfected DESC

-- Countries with highest death count per population
SELECT Location, MAX(CAST(total_deaths AS int)) as TotalDeathCount, population, MAX(NULLIF(CONVERT(float, total_deaths),0)/NULLIF(CONVERT(float, population),0)*100) as PercentPopulationDeaths
FROM [Portfolio Project].[dbo].[CovidDeath]
GROUP BY population, location
ORDER BY PercentPopulationDeaths DESC

-- Break down by continent
-- Continent with highest death counts
SELECT continent, MAX(CAST(total_deaths AS bigint)) as TotalDeathCount
FROM [Portfolio Project].[dbo].[CovidDeath]
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
-- Percent of death among infected by date
SELECT date, SUM(CONVERT(int, new_cases)) AS TotalCases, SUM(CONVERT(int, new_deaths)) AS TotalDeaths, (SUM(NULLIF(CONVERT(float,new_deaths),0))/SUM(NULLIF(CONVERT(float,new_cases),0)))*100 AS DeathPercent
FROM [Portfolio Project].[dbo].[CovidDeath]
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

-- Percent of death among infection 
SELECT SUM(CONVERT(bigint,new_cases)) AS total_cases, SUM(CONVERT(bigint,new_deaths)) AS total_deaths, (SUM(CONVERT(float,new_deaths))/SUM(CONVERT(float,new_cases)))*100 AS DeathPercent
FROM [Portfolio Project].[dbo].[CovidDeath]
WHERE continent is not NULL
ORDER BY 1,2


-- Join Death table and Vaccination table
-- Looking at global population vs total vaccinations
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningVaccinationTotal
-- , RunningVaccinationTotal/dea.population*100 AS PercentPopulationVaccinated
FROM [Portfolio Project].[dbo].[CovidDeath] AS dea
JOIN [Portfolio Project].[dbo].[CovidVaccinations] As vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.date > '2021-01-01'
AND dea.continent is not null
ORDER BY dea.location, dea.date

-- Use CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RunningPeopleVaccinated)
AS
(
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningPeopleVaccinated
-- , RunningPeopleVaccinated/dea.population*100 AS PercentPopulationVaccinated
FROM [Portfolio Project].[dbo].[CovidDeath] AS dea
JOIN [Portfolio Project].[dbo].[CovidVaccinations] As vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.date > '2021-01-01'
AND dea.continent is not null
--ORDER BY dea.location, dea.date
)
SELECT *, NULLIF(CAST(RunningPeopleVaccinated AS float),0)/NULLIF(CAST(Population AS float),0)*100 AS PercentPopulationVaccinated
FROM PopvsVac


-- TEMP Table
DROP Table if exists #PercentPeopleVaccinated
CREATE Table #PercentPeopleVaccinated	
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_Vaccinations float,
RunningPeopleVaccinated float,
)

INSERT INTO #PercentPeopleVaccinated
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningPeopleVaccinated
-- , RunningPeopleVaccinated/dea.population*100 AS PercentPopulationVaccinated
FROM [Portfolio Project].[dbo].[CovidDeath] AS dea
JOIN [Portfolio Project].[dbo].[CovidVaccinations] As vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.date > '2021-01-01'
--AND dea.continent is not null

SELECT *, NULLIF(CAST(RunningPeopleVaccinated AS float),0)/NULLIF(CAST(Population AS float),0)*100 AS PercentPopulationVaccinated
FROM #PercentPeopleVaccinated

-- Creating View to store date for later visualization

Create View PercentPeopleVaccinated AS
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningPeopleVaccinated
-- , RunningPeopleVaccinated/dea.population*100 AS PercentPopulationVaccinated
FROM [Portfolio Project].[dbo].[CovidDeath] AS dea
JOIN [Portfolio Project].[dbo].[CovidVaccinations] As vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPeopleVaccinated
/*
Conclusions and Remarks
-- Population data does not change across years
*/