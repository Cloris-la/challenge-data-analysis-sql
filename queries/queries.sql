-- 1. juridical form percentage
SELECT
    JuridicalForm,
    COUNT(EnterpriseNumber) AS company_count,
    ROUND(
        COUNT(EnterpriseNumber) * 100.0 / SUM(COUNT(EnterpriseNumber)) OVER (), 
        2
    ) AS percentage
FROM enterprise
GROUP BY JuridicalForm
ORDER BY company_count DESC;

-- 2. company statuses
SELECT
    Status,
    count(*) AS count
FROM enterprise
GROUP BY Status
ORDER BY count DESC;

-- 3.average company age(NACE codes)
SELECT
    t.NaceCode,
    ROUND(AVG(company_age), 2) AS avg_company_age
FROM (
    SELECT
        a.NaceCode,
        (JULIANDAY('now') - JULIANDAY(
            SUBSTR(e.StartDate, 7, 4) || '-' || SUBSTR(e.StartDate, 4, 2) || '-' || SUBSTR(e.StartDate, 1, 2)
        )) / 365.25 AS company_age  
    FROM 
        activity a
    JOIN 
        enterprise e 
    ON 
        a.EntityNumber = e.EnterpriseNumber
    WHERE 
        e.StartDate IS NOT NULL
) t
GROUP BY t.NaceCode
ORDER BY avg_company_age DESC;

-- 4. company creation trends
SELECT
  year,
  new_companies,
  LAG(new_companies) OVER (ORDER BY year) AS prev_year,
  ROUND(
    (new_companies - LAG(new_companies) OVER (ORDER BY year)) * 100.0 /
    LAG(new_companies) OVER (ORDER BY year),
    2
  ) AS yoy_change
FROM (
  SELECT
    STRFTIME('%Y', 
        SUBSTR(StartDate, 7, 4) || '-' || SUBSTR(StartDate, 4, 2) || '-' || SUBSTR(StartDate, 1, 2)
    ) AS year,
    COUNT(*) AS new_companies
  FROM enterprise
  WHERE StartDate IS NOT NULL
  GROUP BY year
) t
ORDER BY year;

-- 5. geographical distribution of companies
SELECT
    a.Zipcode,
    COUNT(DISTINCT e.EnterpriseNumber) AS company_count,
    ROUND(
        COUNT(e.EnterpriseNumber) * 100.0 / SUM(COUNT(e.EnterpriseNumber)) OVER (), 
        2
    ) AS percentage
FROM address a
JOIN enterprise e ON a.EntityNumber = e.EnterpriseNumber
GROUP BY a.Zipcode
ORDER BY company_count DESC;

--Personal query below: 
        --1. sector growth yoy trends(2000-2025)  
        --2. Overall growth by industry 
        --3. calculate recent 10 years average growth rate by industry  
        --4. Indentify the rapid rising emerging industries(industries that appeared in large numbers after 2000)
        --5. Invisible champion anlysis: industries with over-average-growth but moderate scale
        --6. Cruel Industry Analysis(High-growth,high-elimination,fiercely competitive industries)
        --7. Comprehensive Comparison: Invisible Champion vs Cruel Industry Characteristics Comparison
-- Create NACE industrial mapping
CREATE TEMPORARY TABLE nace_mapping AS
SELECT 
  nace_code,
  CASE 
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 1 AND 3 THEN 'Agriculture, Forestry and Fishing'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 5 AND 9 THEN 'Mining and Quarrying'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 10 AND 33 THEN 'Manufacturing'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) IS 35 THEN 'Electricity, Gas, Steam and Air Conditioning Supply'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 36 AND 39 THEN 'Water Supply; Sewerage, Waste Management and Remediation Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 41 AND 43 THEN 'Construction'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 46 AND 47 THEN 'Wholesale and Retail Trade'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 49 AND 53 THEN 'Transportation and Storage'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 55 AND 56 THEN 'Accommodation and Food Service Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 58 AND 60 THEN 'Publishing, Broadcasting, Content Production, Distribution Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 61 AND 63 THEN 'Telecommunication, Computer Programming, Consulting, Computing Infrastructure, Other Information Service Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 64 AND 66 THEN 'Financial and Insurance Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) IS 68 THEN 'Real Estate Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 69 AND 75 THEN 'Professional, Scientific and Technical Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 77 AND 82 THEN 'Administrative and Support Service Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) IS 84 THEN 'Public Administration and Defence, Compulsory Social Security'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) IS 85 THEN 'Education'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 86 AND 88 THEN 'Human Health and Social Work Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 90 AND 93 THEN 'Arts, Sports and Recreation'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 94 AND 96 THEN 'Other Service Activities'
    WHEN CAST(SUBSTR('00' || CAST(nace_code AS TEXT),-4,2) AS INTEGER) BETWEEN 97 AND 98 THEN 'Activities Households AS Employers and Undifferentiated Goods-And Service-Producing Activities Of Households For Own Use'
    ELSE 'Activities of Extraterrestrial Organizations And Bodies'  
  END AS sector_name
FROM (
  SELECT DISTINCT NaceCode AS nace_code 
  FROM activity
  WHERE NaceCode IS NOT NULL
);

--Create nacecode yoy industrial growth CTE
WITH sector_yearly_growth AS(
    SELECT
        CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) AS year,
        CAST(SUBSTR('00' || CAST(a.NaceCode AS TEXT), -4, 2) AS INTEGER) AS nace_division,
        a.NaceCode AS nace_code,
        COUNT(DISTINCT e.EnterpriseNumber) AS new_companies
    FROM 
        enterprise e
    INNER JOIN 
        activity a ON e.EnterpriseNumber = a.EntityNumber
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10  -- dd-mm-yyyy format
        AND SUBSTR(e.StartDate, 3, 1) = '-'  --make sure 3rd is -
        AND SUBSTR(e.StartDate, 6, 1) = '-'  -- make sure 6th is -
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2000 AND 2025
        AND a.NaceCode IS NOT NULL
    GROUP BY 
        year, a.NaceCode
),
-- calculate yoy CTE
sector_growth AS(
    SELECT
        year,
        nace_code,
        new_companies,
        LAG(new_companies) OVER (
            PARTITION BY nace_code
            ORDER BY year
        ) AS prev_year_count
        FROM sector_yearly_growth
)
-- Results 
SELECT
    g.year,
    g.nace_code,
    m.sector_name,
    g.new_companies,
    g.prev_year_count,
-- calculate yoy rate
    CASE 
        WHEN g.prev_year_count IS NULL THEN NULL
        WHEN g.prev_year_count = 0 THEN NULL 
        ELSE ROUND(
            (g.new_companies - g.prev_year_count) * 100.0 / g.prev_year_count,
            2
        ) 
    END AS yoy_growth,
    CASE 
        WHEN g.prev_year_count IS NULL THEN 'New Sector' 
        WHEN g.new_companies > g.prev_year_count THEN 'Growth'
        WHEN g.new_companies < g.prev_year_count THEN 'Decline'
        ELSE 'Stable'
    END AS growth_category
FROM sector_growth g
JOIN nace_mapping m ON g.nace_code = m.nace_code
WHERE g.year >= '1970'
ORDER BY g.year DESC;


-- 2. Overall growth by industry 1970 vs 2025
WITH sector_period_data AS (
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) AS year,
        COUNT(DISTINCT e.EnterpriseNumber) AS new_companies
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''  
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) IN (1970, 1980, 1990, 2000, 2010, 2020, 2025)
    GROUP BY sector_name, year
),
sector_comparison AS (
    SELECT 
        sector_name,
        SUM(CASE WHEN year = 1970 THEN new_companies ELSE 0 END) AS companies_1970,
        SUM(CASE WHEN year = 1980 THEN new_companies ELSE 0 END) AS companies_1980,
        SUM(CASE WHEN year = 1990 THEN new_companies ELSE 0 END) AS companies_1990,
        SUM(CASE WHEN year = 2000 THEN new_companies ELSE 0 END) AS companies_2000,
        SUM(CASE WHEN year = 2010 THEN new_companies ELSE 0 END) AS companies_2010,
        SUM(CASE WHEN year = 2020 THEN new_companies ELSE 0 END) AS companies_2020,
        SUM(CASE WHEN year = 2025 THEN new_companies ELSE 0 END) AS companies_2025,
        SUM(new_companies) AS total_companies
    FROM sector_period_data
    GROUP BY sector_name
)
SELECT 
    sector_name,
    companies_1970,
    companies_2025,
    total_companies,
    CASE 
        WHEN companies_1970 = 0 THEN 'New Sector (No 1970 data)'
        ELSE ROUND(
            (companies_2025 - companies_1970) * 100.0 / companies_1970, 
            2
        )
    END AS growth_rate_1970_2025,
    -- calculate companies CAGR (Compound Annual Growth Rate) 
    CASE 
        WHEN companies_1970 > 0 THEN 
            ROUND(
                (POWER(CAST(companies_2025 AS REAL) / companies_1970, 1.0/54) - 1) * 100,
                2
            )
        ELSE NULL
    END AS cagr_1970_2025
FROM sector_comparison
WHERE total_companies >= 10  -- drop industries have less than 10 companies 
ORDER BY 
    CASE 
        WHEN companies_1970 > 0 THEN 
            (POWER(CAST(companies_2025 AS REAL) / companies_1970, 1.0/54) - 1) * 100
        ELSE -999
    END DESC
LIMIT 15;

-- 3. calculate recent 10 years average growth rate by industry 
WITH recent_growth AS (
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) AS year,
        COUNT(DISTINCT e.EnterpriseNumber) AS new_companies
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2015 AND 2025
    GROUP BY sector_name, year
),
yearly_growth AS (
    SELECT
        sector_name,
        year,
        new_companies,
        LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year) AS prev_year,
        CASE 
            WHEN LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year) > 0 THEN
                ROUND(
                    (new_companies - LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year)) * 100.0 /
                    LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year),
                    2
                )
            ELSE NULL
        END AS yoy_growth
    FROM recent_growth
)
SELECT 
    sector_name,
    COUNT(year) AS years_with_data,
    SUM(new_companies) AS total_new_companies_2015_2025,
    ROUND(AVG(new_companies), 1) AS avg_annual_new_companies,
    ROUND(AVG(yoy_growth), 2) AS avg_yoy_growth_rate,
    MIN(yoy_growth) AS min_growth_rate,
    MAX(yoy_growth) AS max_growth_rate
FROM yearly_growth
WHERE yoy_growth IS NOT NULL
GROUP BY sector_name
HAVING COUNT(year) >= 5  -- at least 5 years date
    AND SUM(new_companies) >= 50  -- at least 50 companies
ORDER BY avg_yoy_growth_rate DESC
LIMIT 15;

-- 4. Indentify the rapid rising emerging industries(industries that appeared in large numbers after 2000)
WITH emerging_sectors AS (
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) AS year,
        COUNT(DISTINCT e.EnterpriseNumber) AS new_companies
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 1990 AND 2025
    GROUP BY sector_name, year
)
SELECT 
    sector_name,
    SUM(CASE WHEN year BETWEEN 1990 AND 1999 THEN new_companies ELSE 0 END) AS companies_1990s,
    SUM(CASE WHEN year BETWEEN 2000 AND 2009 THEN new_companies ELSE 0 END) AS companies_2000s,
    SUM(CASE WHEN year BETWEEN 2010 AND 2019 THEN new_companies ELSE 0 END) AS companies_2010s,
    SUM(CASE WHEN year BETWEEN 2020 AND 2025 THEN new_companies ELSE 0 END) AS companies_2020s,
    SUM(new_companies) AS total_companies,
    -- Calculate the proportion of companies after 2000
    ROUND(
        SUM(CASE WHEN year >= 2000 THEN new_companies ELSE 0 END) * 100.0 / 
        SUM(new_companies),
        1
    ) AS post_2000_percentage
FROM emerging_sectors
GROUP BY sector_name
HAVING SUM(new_companies) >= 100  -- at least 100 companies
ORDER BY post_2000_percentage DESC, companies_2020s DESC
LIMIT 15;


-- 5. Invisible champion anlysis: industries with over-average-growth but moderate scale
WITH sector_stats AS (
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) AS year,
        COUNT(DISTINCT e.EnterpriseNumber) AS new_companies
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2015 AND 2025
    GROUP BY sector_name, year
),
sector_growth AS (
    SELECT
        sector_name,
        year,
        new_companies,
        LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year) AS prev_year,
        CASE 
            WHEN LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year) > 0 THEN
                ROUND(
                    (new_companies - LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year)) * 100.0 /
                    LAG(new_companies) OVER (PARTITION BY sector_name ORDER BY year),
                    2
                )
            ELSE NULL
        END AS yoy_growth
    FROM sector_stats
),
sector_summary AS (
    SELECT 
        sector_name,
        COUNT(year) AS years_with_data,
        SUM(new_companies) AS total_new_companies,
        ROUND(AVG(new_companies), 1) AS avg_annual_new_companies,
        ROUND(AVG(yoy_growth), 2) AS avg_yoy_growth_rate,
        ROUND(SQRT(AVG(yoy_growth * yoy_growth) - AVG(yoy_growth) * AVG(yoy_growth)), 2
) AS growth_volatility
    FROM sector_growth
    WHERE yoy_growth IS NOT NULL
    GROUP BY sector_name
    HAVING COUNT(year) >= 5
),
market_averages AS (
    SELECT 
        AVG(avg_annual_new_companies) AS market_avg_companies,
        AVG(avg_yoy_growth_rate) AS market_avg_growth
    FROM sector_summary
    WHERE total_new_companies >= 50
)
SELECT 
    s.sector_name,
    s.total_new_companies,
    s.avg_annual_new_companies,
    s.avg_yoy_growth_rate,
    s.growth_volatility,
    m.market_avg_companies,
    m.market_avg_growth,
    -- Invisible champion index
    CASE 
        WHEN s.avg_yoy_growth_rate > m.market_avg_growth 
        AND s.avg_annual_new_companies BETWEEN m.market_avg_companies * 0.3 AND m.market_avg_companies * 1.5
        AND s.growth_volatility < 50  -- the growth is relatively stable
        THEN '🏆 Invisible champion'
        WHEN s.avg_yoy_growth_rate > m.market_avg_growth * 1.5 
        THEN '🚀 High speed growth'
        WHEN s.avg_annual_new_companies > m.market_avg_companies * 2 
        THEN '🏭 scale giants'
        ELSE '📊 ordinary industries'
    END AS sector_category,
    -- Invisible champion score(grwoth rate weight 60%,stability weight 40%)
    ROUND(
        (s.avg_yoy_growth_rate / m.market_avg_growth * 0.6) + 
        ((100 - COALESCE(s.growth_volatility, 50)) / 100 * 0.4),
        2
    ) AS hidden_champion_score
FROM sector_summary s
CROSS JOIN market_averages m
WHERE s.total_new_companies >= 50
ORDER BY 
    CASE WHEN s.avg_yoy_growth_rate > m.market_avg_growth 
        AND s.avg_annual_new_companies BETWEEN m.market_avg_companies * 0.3 AND m.market_avg_companies * 1.5
        AND s.growth_volatility < 50 THEN 1 ELSE 2 END,
    hidden_champion_score DESC
LIMIT 20;

-- 6. Cruel Industry Analysis(High-growth,high-elimination,fiercely competitive industries)
WITH active_enterprises AS (
    -- get data of activate componies
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        COUNT(DISTINCT e.EnterpriseNumber) AS total_enterprises,
        -- classify by "Status"
        SUM(CASE WHEN e.Status = 'AC' THEN 1 ELSE 0 END) AS active_count,
        SUM(CASE WHEN e.Status IN ('ST', 'CE') THEN 1 ELSE 0 END) AS ceased_count,
        -- classify by "StartDate"
        SUM(CASE WHEN CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) >= 2020 THEN 1 ELSE 0 END) AS recent_enterprises,
        SUM(CASE WHEN CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2015 AND 2019 THEN 1 ELSE 0 END) AS mid_period_enterprises
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) >= 2010  -- focus on last 15 years data
    GROUP BY sector_name
),
recent_growth AS (
    -- get recent growth data
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        SUM(CASE WHEN CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2020 AND 2025 THEN 1 ELSE 0 END) AS new_2020_2025,
        SUM(CASE WHEN CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2015 AND 2019 THEN 1 ELSE 0 END) AS new_2015_2019
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
        AND SUBSTR(e.StartDate, 3, 1) = '-'
        AND SUBSTR(e.StartDate, 6, 1) = '-'
        AND CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) BETWEEN 2015 AND 2025
    GROUP BY sector_name
)
SELECT 
    ae.sector_name,
    ae.total_enterprises,
    ae.active_count,
    ae.ceased_count,
    ae.recent_enterprises,
    rg.new_2020_2025,
    rg.new_2015_2019,
    -- calculate important index
    ROUND(ae.ceased_count * 100.0 / ae.total_enterprises, 2) AS cessation_rate,
    ROUND(ae.recent_enterprises * 100.0 / ae.total_enterprises, 2) AS recent_entry_rate,
    CASE 
        WHEN rg.new_2015_2019 > 0 THEN 
            ROUND((rg.new_2020_2025 - rg.new_2015_2019) * 100.0 / rg.new_2015_2019, 2)
        ELSE NULL
    END AS growth_acceleration,
    -- Cruelity index = (shutdown rate * 0.4) + (new entry rate * 0.3) + (growth acceleration/10 * 0.3)
    ROUND(
        (ae.ceased_count * 100.0 / ae.total_enterprises * 0.4) +
        (ae.recent_enterprises * 100.0 / ae.total_enterprises * 0.3) +
        (CASE 
            WHEN rg.new_2015_2019 > 0 THEN 
                ((rg.new_2020_2025 - rg.new_2015_2019) * 100.0 / rg.new_2015_2019 / 10 * 0.3)
            ELSE 0
        END),
        2
    ) AS battleground_index,
    -- industry classification
    CASE 
        WHEN ae.ceased_count * 100.0 / ae.total_enterprises > 15 
        AND ae.recent_enterprises * 100.0 / ae.total_enterprises > 25 
        THEN '⚔️ Cruel industry'
        WHEN ae.ceased_count * 100.0 / ae.total_enterprises > 20 
        THEN '💀 High elimination'
        WHEN ae.recent_enterprises * 100.0 / ae.total_enterprises > 30 
        THEN '🌊 New popular'
        WHEN ae.ceased_count * 100.0 / ae.total_enterprises < 5 
        THEN '🛡️ Stable fortress'
        ELSE '📈 Conventional competition'
    END AS competition_category
FROM active_enterprises ae
LEFT JOIN recent_growth rg ON ae.sector_name = rg.sector_name
WHERE ae.total_enterprises >= 100  -- Industries with too small filter samples
ORDER BY battleground_index DESC
LIMIT 20;

-- 7. Comprehensive Comparison: Invisible Champion vs Cruel Industry Characteristics Comparison
WITH sector_classification AS (
    SELECT
        CASE 
            WHEN a.NaceCode IS NULL THEN 'No NACE Code Available'
            ELSE COALESCE(m.sector_name, 'Unknown Sector')
        END AS sector_name,
        COUNT(DISTINCT e.EnterpriseNumber) AS total_enterprises,
        SUM(CASE WHEN e.Status IN ('ST', 'CE') THEN 1 ELSE 0 END) AS ceased_count,
        SUM(CASE WHEN CAST(SUBSTR(e.StartDate, 7, 4) AS INTEGER) >= 2020 THEN 1 ELSE 0 END) AS recent_entries,
        AVG(
            CASE 
                WHEN e.StartDate IS NOT NULL AND LENGTH(e.StartDate) = 10 THEN
                    (JULIANDAY('2025-12-31') - JULIANDAY(
                        SUBSTR(e.StartDate, 7, 4) || '-' || SUBSTR(e.StartDate, 4, 2) || '-' || SUBSTR(e.StartDate, 1, 2)
                    )) / 365.25
                ELSE NULL
            END
        ) AS avg_company_age
    FROM 
        enterprise e
    LEFT JOIN activity a ON e.EnterpriseNumber = a.EntityNumber
    LEFT JOIN nace_mapping m ON a.NaceCode = m.nace_code
    WHERE 
        e.StartDate IS NOT NULL
        AND e.StartDate != ''
        AND LENGTH(e.StartDate) = 10
    GROUP BY sector_name
    HAVING COUNT(DISTINCT e.EnterpriseNumber) >= 50
)
SELECT 
    sector_name,
    total_enterprises,
    ROUND(ceased_count * 100.0 / total_enterprises, 2) as cessation_rate,
    ROUND(recent_entries * 100.0 / total_enterprises, 2) as recent_entry_rate,
    ROUND(avg_company_age, 1) as avg_company_age,
    -- Industry type judgement
    CASE 
        WHEN ceased_count * 100.0 / total_enterprises > 15 
        AND recent_entries * 100.0 / total_enterprises > 25 
        THEN '⚔️ Cruel Industry'
        WHEN ceased_count * 100.0 / total_enterprises < 8 
        AND recent_entries * 100.0 / total_enterprises BETWEEN 10 AND 20
        AND avg_company_age > 10
        THEN '🏆 Invisible Champion'
        WHEN recent_entries * 100.0 / total_enterprises > 30 
        THEN '🌊 New popular Industry'
        WHEN avg_company_age > 20 
        THEN '🏛️ Traditional stability'
        ELSE '📊 Conventional industry'
    END AS industry_archetype
FROM sector_classification
ORDER BY 
    CASE 
        WHEN ceased_count * 100.0 / total_enterprises > 15 
        AND recent_entries * 100.0 / total_enterprises > 25 THEN 1
        WHEN ceased_count * 100.0 / total_enterprises < 8 
        AND recent_entries * 100.0 / total_enterprises BETWEEN 10 AND 20 THEN 2
        ELSE 3
    END,
    cessation_rate DESC;
