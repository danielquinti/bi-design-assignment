-- == Consulta 1: Tiempo total de visualización por Año, Mes y Día con subtotales ==
-- Enunciado: Se desea conocer el tiempo total de visualización desglosado por Año, Mes y Día, incluyendo subtotales por cada nivel.
-- Justificación: Es vital para detectar tendencias estacionales (ej. ¿se ve más Twitch en verano o los fines de semana?). El ROLLUP permite obtener el informe detallado y los totales de jerarquía en una sola pasada de datos.
SELECT 
    d.year, 
    d.month_name, 
    d.day_of_month, 
    SUM(fv.duration_minutes) as total_minutes
FROM Fact_View fv
JOIN Dim_Date d ON fv.start_date_local_sk = d.date_sk
GROUP BY ROLLUP(d.year, d.month_name, d.day_of_month)
ORDER BY d.year, d.month_name, d.day_of_month;


-- == Consulta 2: Ingresos totales por género y país con todas las combinaciones posibles ==
-- Enunciado: Obtener los ingresos totales cruzando el género del espectador y su país, incluyendo todas las combinaciones posibles de totales.
-- Justificación: Ayuda a identificar qué demografías son más rentables en qué regiones. CUBE genera un "cubo" de datos con todas las permutaciones de agrupación. 
SELECT 
    v.gender, 
    v.country, 
    SUM(fi.revenue) as total_revenue
FROM Fact_Interaction fi
JOIN Dim_Viewer v ON fi.viewer_sk = v.viewer_sk
GROUP BY CUBE(v.gender, v.country);


-- == Consulta 3: Ingresos por canal desglosados por tipo de interacción ==
-- Enunciado: Mostrar en columnas separadas cuánto dinero ha generado cada canal por 'Sub', 'Follow' y 'Cheer'.
-- Justificación: Permite comparar de un vistazo el modelo de monetización de cada canal (algunos viven de suscripciones, otros de bits/cheers).
SELECT * FROM (
    SELECT 
        c.id_channel, 
        it.interaction_type, 
        fi.revenue
    FROM Fact_Interaction fi
    JOIN Dim_Channel c ON fi.channel_sk = c.channel_sk
    JOIN Dim_Interaction_Type it ON fi.interaction_type_sk = it.interaction_type_sk
)
PIVOT (
    SUM(revenue) 
    FOR interaction_type IN ('Sub' AS Subscriptions, 'Follow' AS Follows, 'Cheer' AS Cheers)
);


-- == Consulta 4: Top 3 espectadores por tiempo de visualización en cada canal ==
-- Enunciado: Listar los 3 espectadores que más tiempo han pasado en cada canal.
-- Justificación: Identificar a los "fieles" o moderadores potenciales. Se usa DENSE_RANK para no saltar números en caso de empate en minutos.
SELECT * FROM (
    SELECT 
        c.id_channel, 
        v.id_viewer, 
        SUM(fv.duration_minutes) as total_min,
        DENSE_RANK() OVER (PARTITION BY fv.channel_sk ORDER BY SUM(fv.duration_minutes) DESC) as ranking
    FROM Fact_View fv
    JOIN Dim_Channel c ON fv.channel_sk = c.channel_sk
    JOIN Dim_Viewer v ON fv.viewer_sk = v.viewer_sk
    GROUP BY c.id_channel, v.id_viewer, fv.channel_sk
) WHERE ranking <= 3;


-- == Consulta 5: Espectadores agrupados por gasto total (cuartiles) ==
-- Enunciado: Dividir a los espectadores en 4 grupos (cuartiles) basados en el gasto total realizado.
-- Justificación: Marketing puede usar esto para definir el "Target Gold" (Q1) y realizar campañas de reactivación en el (Q4).
SELECT 
    v.id_viewer, 
    SUM(fi.revenue) as total_spent,
    NTILE(4) OVER (ORDER BY SUM(fi.revenue) DESC) as customer_tier
FROM Fact_Interaction fi
JOIN Dim_Viewer v ON fi.viewer_sk = v.viewer_sk
GROUP BY v.id_viewer;


-- == Consulta 6: Comparación de duración de sesiones actuales vs anteriores por espectador ==
-- Enunciado: Para cada espectador, comparar la duración de su sesión actual con la anterior.
-- Justificación: ¿El usuario está perdiendo interés (sesiones cada vez más cortas) o está "enganchado"?
SELECT 
    v.id_viewer, 
    fv.start_date_local_sk, 
    fv.duration_minutes as current_session,
    LAG(fv.duration_minutes, 1) OVER (PARTITION BY fv.viewer_sk ORDER BY fv.start_date_local_sk) as prev_session,
    fv.duration_minutes - LAG(fv.duration_minutes, 1) OVER (PARTITION BY fv.viewer_sk ORDER BY fv.start_date_local_sk) as difference
FROM Fact_View fv
JOIN Dim_Viewer v ON fv.viewer_sk = v.viewer_sk;


-- == Consulta 7: Media de ingresos por canal considerando el día actual y los 2 días anteriores ==
-- Enunciado: Calcular la media de ingresos de un canal considerando el día actual y los 2 días anteriores.
-- Justificación: Suaviza las fluctuaciones diarias para entender si el crecimiento de un canal es estable.
SELECT 
    c.id_channel, 
    d.date_sk, 
    SUM(fi.revenue) as daily_rev,
    AVG(SUM(fi.revenue)) OVER (
        PARTITION BY fi.channel_sk 
        ORDER BY d.date_sk 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg_3days
FROM Fact_Interaction fi
JOIN Dim_Channel c ON fi.channel_sk = c.channel_sk
JOIN Dim_Date d ON fi.date_local_sk = d.date_sk
GROUP BY c.id_channel, fi.channel_sk, d.date_sk;


-- == Consulta 8: Por cada país, obtener el tiempo total de visualización y el total de ingresos generados ==
-- Enunciado: Por cada país, obtener el tiempo total de visualización y el total de ingresos generados.
-- Justificación: Es la consulta definitiva de rentabilidad. Permite ver si países con mucha audiencia (muchos minutos) realmente retornan inversión (mucho revenue).
WITH VistaMinutos AS (
    SELECT v.country, SUM(fv.duration_minutes) as total_min
    FROM Fact_View fv
    JOIN Dim_Viewer v ON fv.viewer_sk = v.viewer_sk
    GROUP BY v.country
),
VistaIngresos AS (
    SELECT v.country, SUM(fi.revenue) as total_rev
    FROM Fact_Interaction fi
    JOIN Dim_Viewer v ON fi.viewer_sk = v.viewer_sk
    GROUP BY v.country
)
SELECT 
    m.country, 
    m.total_min, 
    i.total_rev,
    (i.total_rev / NULLIF(m.total_min, 0)) as revenue_per_minute
FROM VistaMinutos m
LEFT JOIN VistaIngresos i ON m.country = i.country
ORDER BY revenue_per_minute DESC;


-- == Consulta 9: Identificar cuál es el segundo juego (actividad) en el que los espectadores pasan más tiempo por cada canal ==
-- Enunciado: Identificar cuál es el segundo juego (actividad) en el que los espectadores pasan más tiempo por cada canal.
-- Justificación: Ayuda a entender la variedad de contenido de un streamer más allá de su "juego principal".
SELECT DISTINCT
    c.id_channel,
    NTH_VALUE(a.activity_name, 2) OVER (
        PARTITION BY c.channel_sk 
        ORDER BY SUM(fv.duration_minutes) DESC
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as second_most_watched_game
FROM Fact_View fv
JOIN Dim_Channel c ON fv.channel_sk = c.channel_sk
JOIN Bridge_Activity_Group bag ON fv.activity_group_sk = bag.activity_group_sk
JOIN Dim_Activity a ON bag.activity_sk = a.activity_sk
GROUP BY c.id_channel, c.channel_sk, a.activity_name;




-- == Consulta 1: Ranking de eficiencia de monetización por canal ==
-- Enunciado: Calcular el "Revenue per Minute" (RPM) de cada canal, comparando el total de ingresos con el tiempo total visualizado, y rankearlos dentro de su idioma principal.
-- Justificación: Un canal con pocos espectadores pero muy comprometidos puede ser más rentable que uno masivo. Esta query permite identificar a los streamers más eficientes monetizando su tiempo de aire.
SELECT 
    primary_language,
    id_channel,
    total_revenue,
    total_minutes,
    revenue_per_minute,
    DENSE_RANK() OVER (PARTITION BY primary_language ORDER BY revenue_per_minute DESC) as rank_efficiency,
    PERCENT_RANK() OVER (PARTITION BY primary_language ORDER BY revenue_per_minute ASC) as percentile_rank
FROM (
    SELECT 
        c.primary_language,
        c.id_channel,
        SUM(fi.revenue) as total_revenue,
        SUM(fv.duration_minutes) as total_minutes,
        SUM(fi.revenue) / NULLIF(SUM(fv.duration_minutes), 0) as revenue_per_minute
    FROM Dim_Channel c
    LEFT JOIN Fact_View fv ON c.channel_sk = fv.channel_sk
    LEFT JOIN Fact_Interaction fi ON c.channel_sk = fi.channel_sk
    GROUP BY c.primary_language, c.id_channel
)
ORDER BY primary_language, rank_efficiency;



-- == Consulta 2: Distribución acumulada de gasto vs tiempo de visualización ==
-- Enunciado: Para cada espectador, obtener su tiempo total de visualización y su gasto total, calculando la distribución acumulada (CUME_DIST) del gasto.
-- Justificación: Permite identificar a las "ballenas" (usuarios que gastan mucho) y ver si su consumo de horas es proporcional a su gasto. Ayuda a segmentar usuarios VIP.
SELECT 
    v.id_viewer,
    v.country,
    SUM(fv.duration_minutes) as total_view_mins,
    SUM(fi.revenue) as total_spent,
    CUME_DIST() OVER (ORDER BY SUM(fi.revenue) DESC) as spend_percentile,
    NTILE(10) OVER (ORDER BY SUM(fi.duration_minutes) DESC) as view_decile
FROM Dim_Viewer v
LEFT JOIN Fact_View fv ON v.viewer_sk = fv.viewer_sk
LEFT JOIN Fact_Interaction fi ON v.viewer_sk = fi.viewer_sk
GROUP BY v.id_viewer, v.country
ORDER BY total_spent DESC;


-- == Consulta 3: Super-reporte de rendimiento Geográfico-Temporal ==
-- Enunciado: Obtener métricas cruzadas de visualización e ingresos por Año, País y Género, utilizando subtotales específicos.
-- Justificación: En lugar de un simple ROLLUP, GROUPING SETS permite definir exactamente qué combinaciones de totales queremos para un dashboard ejecutivo, evitando filas innecesarias.
SELECT 
    d.year,
    v.country,
    v.gender,
    SUM(fv.duration_minutes) as total_mins,
    SUM(fi.revenue) as total_rev,
    COUNT(DISTINCT fv.session_sk) as total_sessions
FROM Fact_View fv
FULL OUTER JOIN Fact_Interaction fi ON fv.viewer_sk = fi.viewer_sk 
    AND fv.channel_sk = fi.channel_sk 
    AND fv.session_sk = fi.session_sk
JOIN Dim_Viewer v ON COALESCE(fv.viewer_sk, fi.viewer_sk) = v.viewer_sk
JOIN Dim_Date d ON COALESCE(fv.start_date_local_sk, fi.date_local_sk) = d.date_sk
GROUP BY GROUPING SETS (
    (d.year, v.country),
    (v.country, v.gender),
    (d.year),
    ()
);


-- == Consulta 4: Media móvil de ingresos vs tendencia de visualización ==
-- Enunciado: Calcular la media móvil de ingresos de los últimos 3 días y compararla con el tiempo de visualización del día actual para cada canal.
-- Justificación: Detectar si una caída en la visualización precede a una caída en los ingresos o si el público sigue donando a pesar de ver menos contenido.
SELECT 
    c.id_channel,
    d.date_sk,
    SUM(fv.duration_minutes) as daily_mins,
    SUM(fi.revenue) as daily_rev,
    AVG(SUM(fi.revenue)) OVER (
        PARTITION BY c.channel_sk 
        ORDER BY d.date_sk 
        RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND CURRENT ROW
    ) as moving_avg_rev_3d,
    FIRST_VALUE(SUM(fv.duration_minutes)) OVER (
        PARTITION BY c.channel_sk 
        ORDER BY d.date_sk DESC
    ) as last_day_mins
FROM Dim_Channel c
JOIN Dim_Date d ON 1=1 -- Para asegurar continuidad si se desea
LEFT JOIN Fact_View fv ON c.channel_sk = fv.channel_sk AND d.date_sk = fv.start_date_local_sk
LEFT JOIN Fact_Interaction fi ON c.channel_sk = fi.channel_sk AND d.date_sk = fi.date_local_sk
WHERE d.year = 2024
GROUP BY c.id_channel, c.channel_sk, d.date_sk;


-- == Consulta 5: Matriz de Ingresos por Tipo de Interacción y Categoría de Juego ==
-- Enunciado: Pivotar los ingresos para ver cuánto genera cada 'Juego' (Activity) por Follows, Subs y Cheers.
-- Justificación: Permite saber qué juegos son mejores para conseguir suscriptores y cuáles para recibir donaciones directas (Cheers).
SELECT * FROM (
    SELECT 
        a.activity_name,
        it.interaction_type,
        fi.revenue
    FROM Fact_Interaction fi
    JOIN Dim_Activity a ON fi.activity_sk = a.activity_sk
    JOIN Dim_Interaction_Type it ON fi.interaction_type_sk = it.interaction_type_sk
    WHERE a.activity_name <> 'NO_APLICA'
)
PIVOT (
    SUM(revenue)
    FOR interaction_type IN ('Follow' AS Follow_Rev, 'Sub' AS Sub_Rev, 'Cheer' AS Cheer_Rev)
)
ORDER BY Sub_Rev DESC NULLS LAST;


-- == Consulta 6: Valor de la sesión y navegación Lead/Lag ==
-- Enunciado: Por cada sesión de streaming, mostrar el tiempo de visualización, el ingreso generado y cuánto se generó en la sesión inmediatamente anterior del mismo usuario.
-- Justificación: Analizar si sesiones largas tienden a generar más ingresos en la siguiente vez que el usuario se conecta (fidelización latente).
SELECT 
    v.id_viewer,
    s.id_streaming_session,
    fv.duration_minutes,
    SUM(fi.revenue) as session_revenue,
    LAG(SUM(fi.revenue)) OVER (PARTITION BY v.viewer_sk ORDER BY fv.start_date_local_sk) as prev_session_revenue,
    NTH_VALUE(SUM(fi.revenue), 1) OVER (
        PARTITION BY v.viewer_sk 
        ORDER BY fv.start_date_local_sk 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as first_ever_session_revenue
FROM Fact_View fv
JOIN Dim_Viewer v ON fv.viewer_sk = v.viewer_sk
JOIN Dim_Streaming_Session s ON fv.session_sk = s.session_sk
LEFT JOIN Fact_Interaction fi ON fv.session_sk = fi.session_sk AND fv.viewer_sk = fi.viewer_sk
GROUP BY v.id_viewer, v.viewer_sk, s.id_streaming_session, fv.duration_minutes, fv.start_date_local_sk;
