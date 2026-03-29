-- ==================================================================
-- ==================================================================
-- Consultas a nivel de plataforma
-- ==================================================================
-- ==================================================================

-- ==================================================================
-- Constula 1
-- Enunciado: ingresos totales y visualizaciones totales por género, país y año.
-- ==================================================================
-- Parte de visualizaciones
SELECT gender, country, year, count(fact_view.view_sk)
FROM
    fact_view INNER JOIN dim_viewer ON
        fact_view.viewer_sk = dim_viewer.viewer_sk
    INNER JOIN dim_date ON
        fact_view.start_date_utc_sk = dim_date.date_sk
GROUP BY CUBE(gender, country, year);

-- Parte de ingresos
SELECT gender, country, year, sum(fact_interaction.revenue)
FROM
    fact_interaction INNER JOIN dim_viewer ON
        fact_interaction.viewer_sk = dim_viewer.viewer_sk
    INNER JOIN dim_date ON
        fact_interaction.date_utc_sk = dim_date.date_sk
GROUP BY CUBE(gender, country, year);

-- Combinación
SELECT 
    gender, 
    country, 
    year, 
    SUM(total_vistas) AS num_vistas, 
    SUM(total_revenue) AS ingresos_totales
FROM (
    -- Parte 1: Recolectamos la actividad de visualización
    SELECT 
        v.gender, 
        v.country, 
        d.year, 
        1 AS total_vistas, -- Cada fila en Fact_View es 1 vista
        0 AS total_revenue
    FROM fact_view fv
    INNER JOIN dim_viewer v ON fv.viewer_sk = v.viewer_sk
    INNER JOIN dim_date d ON fv.start_date_utc_sk = d.date_sk
    
    UNION ALL
    
    -- Parte 2: Recolectamos la actividad de ingresos
    SELECT 
        v.gender, 
        v.country, 
        d.year, 
        0 AS total_vistas, 
        fi.revenue AS total_revenue
    FROM fact_interaction fi
    INNER JOIN dim_viewer v ON fi.viewer_sk = v.viewer_sk
    INNER JOIN dim_date d ON fi.date_utc_sk = d.date_sk
) 
GROUP BY CUBE(gender, country, year)
ORDER BY year NULLS LAST, country NULLS LAST, gender NULLS LAST;


-- ==================================================================
-- Consulta 2
-- Enunciado: ingresos totales para cada combinación de género, país, año y tipo de interacción. Además mostrarlos en dos columnas: revenue_sub, revenue_cheer, revenue_sub.
-- ==================================================================

SELECT
    gender,
    country,
    year,
    NVL(revenue_sub, 0) AS revenue_sub,
    NVL(revenue_cheer, 0) AS revenue_cheer
FROM (
    SELECT gender, country, year, interaction_type, revenue
    FROM
        fact_interaction INNER JOIN dim_viewer ON
            fact_interaction.viewer_sk = dim_viewer.viewer_sk
        INNER JOIN dim_date ON
            fact_interaction.date_utc_sk = dim_date.date_sk
    WHERE interaction_type IN ('sub', 'cheer')
    GROUP BY CUBE(gender, country, year), interaction_type, revenue
)
PIVOT (
    SUM(revenue) 
    FOR interaction_type IN (
        'sub' AS revenue_sub, 
        'cheer' AS revenue_cheer 
    )
)
ORDER BY year NULLS LAST, country NULLS LAST, gender NULLS LAST;













