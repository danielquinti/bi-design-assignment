-- ==================================================================
-- ==================================================================
-- Consultas a nivel de plataforma
-- ==================================================================
-- ==================================================================

-- ==================================================================
-- Consulta 1
-- Enunciado: ingresos totales y visualizaciones totales por género, país y año. Inlcuir todas las combinaciones posibles de subtotales entre estas dimensiones y el total general.
-- ==================================================================
SELECT 
    gender, 
    country, 
    year, 
    SUM(total_vistas) AS num_vistas, 
    SUM(total_revenue) AS ingresos_totales
FROM (
    -- Visualizacion
    SELECT 
        v.gender, 
        v.country, 
        d.year, 
        1 AS total_vistas,
        0 AS total_revenue
    FROM fact_view fv
    INNER JOIN dim_viewer v ON fv.viewer_sk = v.viewer_sk
    INNER JOIN dim_date d ON fv.start_date_utc_sk = d.date_sk
    
    UNION ALL
    
    -- Ingresos
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
-- Enunciado: ingresos totales para cada combinación de género, país, año y tipo de interacción. Además mostrarlos en dos columnas: revenue_sub y revenue_cheer.
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
-- Enunciado: mostrar top 3 espectadores por tiempo de visualización en cada canal.
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
-- Enunciado: para cada espectador que alguna vez haya gastado dinero en la plataforma, mostrar el total gastado y asignarle un "customer tier" (1 a 4) en función de su gasto total.
-- ==================================================================

SELECT 
    dim_viewer.id_viewer, 
    SUM(fact_interaction.revenue) AS total_spent,
    NTILE(4) OVER (ORDER BY SUM(fact_interaction.revenue) DESC) AS customer_tier
FROM
    fact_interaction
    JOIN dim_viewer ON fact_interaction.viewer_sk = dim_viewer.viewer_sk
GROUP BY dim_viewer.id_viewer
HAVING SUM(fact_interaction.revenue) > 0
ORDER BY total_spent DESC;



-- ==================================================================
-- ==================================================================
-- Consultas a nivel temático
-- ==================================================================
-- ==================================================================

-- ==================================================================
-- Consulta 6
-- Enunciado: para cada tipo de juego analizar que combinación de género y país tiene mayor duración de visualizacion. Además analizarlo a nivel global con respecto al género. Mostrar el resultado en una tabla con las siguientes columnas: game, country, male, female, non_binary, other.
-- ==================================================================

SELECT
    activity_name AS game,
    country,
    NVL(male, 0) AS male,
    NVL(female, 0) AS female,
    NVL(non_binary, 0) AS non_binary,
    NVL(other, 0) AS other    
FROM (
    SELECT
        dim_activity.activity_name,
        dim_viewer.country,
        dim_viewer.gender,
        (fact_view.duration_minutes * bridge_activity_group.weighting_factor) AS duration
    FROM
        fact_view
        INNER JOIN bridge_activity_group ON fact_view.activity_group_sk = bridge_activity_group.activity_group_sk
        INNER JOIN dim_activity ON bridge_activity_group.activity_sk = dim_activity.activity_sk
        INNER JOIN dim_viewer ON fact_view.viewer_sk = dim_viewer.viewer_sk
    WHERE
        dim_activity.activity_name != 'NO_APLICA'
    GROUP BY 
        GROUPING SETS (
            (dim_viewer.country, dim_viewer.gender, dim_activity.activity_sk, dim_activity.activity_name, fact_view.duration_minutes, bridge_activity_group.weighting_factor), 
            (dim_viewer.gender, dim_activity.activity_sk, dim_activity.activity_name, fact_view.duration_minutes, bridge_activity_group.weighting_factor)
        )
)
PIVOT (
    SUM(duration) FOR gender IN ('Male' AS male, 'Female' AS female, 'Non-Binary' AS non_binary, 'Other' AS other)
)
ORDER BY 
    country NULLS FIRST, 
    activity_name;

