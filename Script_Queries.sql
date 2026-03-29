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




-- ==================================================================
-- ==================================================================
-- Consultas a nivel de canal
-- ==================================================================
-- ==================================================================

-- ==================================================================
-- Consulta 3
-- Enunciado: para cada canal mostrar:
--              - Ingresos diarios.
--              - Ingresos acumulados por día a lo largo del tiempo.
--              - Ingresos en ventanas de 7 días.
-- ==================================================================

SELECT DISTINCT
    dim_channel.channel_sk,
    id_channel,
    date_utc_sk,
    SUM(fact_interaction.revenue) OVER (PARTITION BY dim_channel.channel_sk, date_utc_sk) AS ingreso_diario,
    SUM(fact_interaction.revenue) OVER (PARTITION BY dim_channel.channel_sk ORDER BY date_utc_sk) AS total_ingresos,
    SUM(fact_interaction.revenue) OVER (PARTITION BY dim_channel.channel_sk ORDER BY date_utc_sk ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS ingresos_7_dias
FROM 
    fact_interaction
    INNER JOIN dim_channel ON fact_interaction.channel_sk = dim_channel.channel_sk
ORDER BY id_channel, date_utc_sk;



-- ==================================================================
-- ==================================================================
-- Consultas a nivel de viewer
-- ==================================================================
-- ==================================================================

-- ==================================================================
-- Consulta 4
-- Enunciado: top 3 espectadores por tiempo de visualización en cada canal.
-- ==================================================================
SELECT * FROM (
    SELECT 
        dim_channel.id_channel, 
        dim_viewer.id_viewer, 
        SUM(fact_view.duration_minutes) AS total_min,
        DENSE_RANK() OVER (PARTITION BY fact_view.channel_sk ORDER BY SUM(fact_view.duration_minutes) DESC) AS ranking
    FROM 
        fact_view
        INNER JOIN dim_Channel ON fact_view.channel_sk = dim_Channel.channel_sk
        INNER JOIN dim_Viewer ON fact_view.viewer_sk = dim_Viewer.viewer_sk
    GROUP BY 
        dim_channel.id_channel, 
        dim_viewer.id_viewer, 
        fact_view.channel_sk
) 
WHERE ranking <= 3
ORDER BY id_channel, total_min DESC;


-- ==================================================================
-- Consulta 5
-- Enunciado: para cada espectador mostrar el total gastado en la plataforma y asignarle un "customer tier" (1 a 4) en función de su gasto total.
-- ==================================================================

SELECT 
    dim_viewer.id_viewer, 
    SUM(fact_interaction.revenue) AS total_spent,
    NTILE(4) OVER (ORDER BY SUM(fact_interaction.revenue) DESC) AS customer_tier
FROM
    fact_interaction
    JOIN dim_viewer ON fact_interaction.viewer_sk = dim_viewer.viewer_sk
GROUP BY dim_viewer.id_viewer
ORDER BY total_spent DESC;
