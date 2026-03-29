-- ==========================================
-- SCRIPT DE INSERCIÓN DE DATOS DE PRUEBA
-- ==========================================
-- Este script puebla de manera proactiva todas las tablas de dimensiones
-- y genera un volumen significativo de registros en las tablas de hechos
-- utilizando PL/SQL para poder realizar consultas analíticas complejas.

-- El comando SET no es de Oracle nativo (sino de SQL*Plus) y causa ORA-00922 en IDEs como DBeaver:
-- SET SERVEROUTPUT ON;

DECLARE
   v_date_sk     DATE;
   v_date        DATE;
   v_time_sk     VARCHAR2(8);
   v_is_weekend  CHAR(1);
   v_junk_sk     NUMBER := 1;
   v_start_time  VARCHAR2(8);
   v_end_time    VARCHAR2(8);
   
   -- Variables utilizadas para el mapeo semántico de Fact Tables
   v_random_viewer NUMBER;
   v_random_channel NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando inserción de datos de prueba...');
    -- 1. Dim_Date (Desde 2023-01-01 hasta 2025-01-10)
    -- Extendemos un poco hacia 2025 por si alguna sesión del 31 de Diciembre cruza la medianoche
    DBMS_OUTPUT.PUT_LINE('1. Dim_Date...');
    v_date := TO_DATE('2023-01-01', 'YYYY-MM-DD');
    WHILE v_date <= TO_DATE('2025-01-10', 'YYYY-MM-DD') LOOP
        
        IF TRIM(TO_CHAR(v_date, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH')) IN ('SATURDAY', 'SUNDAY') THEN
            v_is_weekend := 'Y';
        ELSE
            v_is_weekend := 'N';
        END IF;

        INSERT INTO Dim_Date (date_sk, day_of_month, day_of_week, is_weekend, month_name, quarter, year, week_of_year)
        VALUES (
            v_date,
            EXTRACT(DAY FROM v_date),
            TRIM(TO_CHAR(v_date, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH')),
            v_is_weekend,
            TRIM(TO_CHAR(v_date, 'MONTH', 'NLS_DATE_LANGUAGE=ENGLISH')),
            TO_NUMBER(TO_CHAR(v_date, 'Q')),
            EXTRACT(YEAR FROM v_date),
            TO_NUMBER(TO_CHAR(v_date, 'IW'))
        );
        
        v_date := v_date + 1;
    END LOOP;

    -- 2. Dim_Time (Todas las horas y minutos: 1440 registros)
    DBMS_OUTPUT.PUT_LINE('2. Dim_Time...');
    FOR h IN 0..23 LOOP
        FOR m IN 0..59 LOOP
            v_time_sk := TO_CHAR(h, 'FM00') || ':' || TO_CHAR(m, 'FM00') || ':00';
            INSERT INTO Dim_Time (time_sk, hour, minute, second)
            VALUES (v_time_sk, h, m, 0);
        END LOOP;
    END LOOP;
    -- (Commit final unificado al término del script)

    -- (Variables de mapeo declaradas en cabecera)

    -- 3. Dim_Viewer (15,200 Viewers agrupados por región)
    DBMS_OUTPUT.PUT_LINE('3. Dim_Viewer (15,200 Viewers)...');
    
    -- Función auxiliar en PL/SQL (bucles)
    -- ESPAÑOL (1-4700)
    FOR i IN 1..1000 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'España', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 1001..3000 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Mexico', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 3001..3500 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Uruguay', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 3501..4100 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Argentina', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 4101..4400 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Colombia', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 4401..4500 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Peru', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 4501..4700 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Paraguay', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;

    -- INGLÉS (4701-12200)
    FOR i IN 4701..6700 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Reino Unido', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 6701..11700 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'EEUU', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 11701..12200 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Australia', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;

    -- PORTUGUÉS (12201-15200)
    FOR i IN 12201..13200 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Portugal', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;
    FOR i IN 13201..15200 LOOP INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES (i, 'VW_' || LPAD(i, 5, '0'), CASE ROUND(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' WHEN 3 THEN 'Non-Binary' ELSE 'Other' END, 'Brasil', ADD_MONTHS(TO_DATE('2000-01-01', 'YYYY-MM-DD'), -ROUND(DBMS_RANDOM.VALUE(1, 300)))); END LOOP;

    -- 4. Dim_Channel (12 Canales Extrapolados)
    DBMS_OUTPUT.PUT_LINE('4. Dim_Channel (12 Canales)...');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (1, 'rubius', 'Spanish');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (2, 'xokas', 'Spanish');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (3, 'ibai', 'Spanish');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (4, 'auron', 'Spanish');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (5, 'gref', 'Spanish');
    
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (6, 'xqc', 'English');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (7, 'speed', 'English');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (8, 'mrbeast', 'English');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (9, 'ninja', 'English');
    
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (10, 'gaules', 'Portuguese');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (11, 'zorlakoka', 'Portuguese');
    INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES (12, 'paulinhoLOKObr', 'Portuguese');

    -- 5. Dim_Streaming_Session (500 Sessions)
    DBMS_OUTPUT.PUT_LINE('5. Dim_Streaming_Session...');
    FOR i IN 1..500 LOOP
        INSERT INTO Dim_Streaming_Session (session_sk, id_streaming_session, title, language)
        VALUES (
            i,
            'SESS_' || LPAD(i, 6, '0'),
            'Stream Title ' || i,
            CASE ROUND(DBMS_RANDOM.VALUE(1, 3))
                WHEN 1 THEN 'Spanish' WHEN 2 THEN 'English' ELSE 'Portuguese' END
        );
    END LOOP;

    -- 6. Dim_Activity (Actividades basadas en jerarquía)
    DBMS_OUTPUT.PUT_LINE('6. Dim_Activity...');
    
    -- Juegos
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (1, 'ACT_001', 'Valorant', 'Shooters / FPS', 'Juegos');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (2, 'ACT_002', 'Elden Ring', 'Juegos de Rol', 'Juegos');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (3, 'ACT_003', 'LoL', 'Estrategia', 'Juegos');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (4, 'ACT_004', 'CS:GO 2', 'Shooters / FPS', 'Juegos');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (5, 'ACT_005', 'Baldurs Gate 3', 'Juegos de Rol', 'Juegos');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (6, 'ACT_006', 'Dota 2', 'Estrategia', 'Juegos');
    
    -- IRL
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (7, 'ACT_007', 'NO_APLICA', 'Just Chatting', 'IRL');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (8, 'ACT_008', 'NO_APLICA', 'Viajes', 'IRL');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (9, 'ACT_009', 'NO_APLICA', 'Cocina', 'IRL');

    -- Música y DJ
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (10, 'ACT_010', 'NO_APLICA', 'Sesiones DJ', 'Música y DJ');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (11, 'ACT_011', 'NO_APLICA', 'Producción', 'Música y DJ');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (12, 'ACT_012', 'NO_APLICA', 'Covers', 'Música y DJ');

    -- Creative
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (13, 'ACT_013', 'NO_APLICA', 'Arte Digital', 'Creative');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (14, 'ACT_014', 'NO_APLICA', 'Programación', 'Creative');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (15, 'ACT_015', 'NO_APLICA', 'Cosplay', 'Creative');

    -- Esports
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (16, 'ACT_016', 'LoL', 'Torneos Int.', 'Esports');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (17, 'ACT_017', 'Valorant', 'Ligas Reg.', 'Esports');
    INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES (18, 'ACT_018', 'CS:GO 2', 'Eventos Com.', 'Esports');


    -- 8. Dim_Junk_Status (8 combinaciones booleanas)
    DBMS_OUTPUT.PUT_LINE('8. Dim_Junk_Status...');
    FOR li IN 0..1 LOOP
        FOR su IN 0..1 LOOP
            FOR fc IN 0..1 LOOP
                INSERT INTO Dim_Junk_Status (junk_status_sk, isLoggedIn, isSubbed, follows_channel)
                VALUES (
                    v_junk_sk,
                    CASE WHEN li=1 THEN 'Y' ELSE 'N' END,
                    CASE WHEN su=1 THEN 'Y' ELSE 'N' END,
                    CASE WHEN fc=1 THEN 'Y' ELSE 'N' END
                );
                v_junk_sk := v_junk_sk + 1;
            END LOOP;
        END LOOP;
    END LOOP;
    -- (Commit unificado al final)
    -- 8.5 Dim_Activity_Group
    DBMS_OUTPUT.PUT_LINE('8.5. Dim_Activity_Group...');
    FOR i IN 1..20 LOOP
        INSERT INTO Dim_Activity_Group (activity_group_sk, group_name)
        VALUES (i, 'Activity Group ' || i);
    END LOOP;

    -- 9. Bridge_Activity_Group
    -- Creamos 20 grupos (activity_group_sk de 1 a 20), cada uno con 2 actividades asociadas
    DBMS_OUTPUT.PUT_LINE('9. Bridge_Activity_Group...');
    FOR i IN 1..20 LOOP
        INSERT INTO Bridge_Activity_Group (activity_group_sk, activity_sk, weighting_factor)
        VALUES (i, MOD(i*2, 18)+1, 0.4);
        INSERT INTO Bridge_Activity_Group (activity_group_sk, activity_sk, weighting_factor)
        VALUES (i, MOD(i*2+1, 18)+1, 0.6);
    END LOOP;

    -- 10. Dim_Viewer_Channel_Role (Roles históricos)
    DBMS_OUTPUT.PUT_LINE('10. Dim_Viewer_Channel_Role...');
    FOR i IN 1..200 LOOP
        -- Cruce lógico de idiomas
        v_random_viewer := ROUND(DBMS_RANDOM.VALUE(1, 15200));
        IF v_random_viewer <= 4700 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(1, 5));
        ELSIF v_random_viewer <= 12200 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(6, 9));
        ELSE v_random_channel := ROUND(DBMS_RANDOM.VALUE(10, 12)); END IF;

        INSERT INTO Dim_Viewer_Channel_Role (viewer_sk, channel_sk, role_name, effective_start_date, effective_end_date, is_current)
        VALUES (
            v_random_viewer, 
            v_random_channel, 
            'Moderator',
            TO_DATE('2023-01-01', 'YYYY-MM-DD') + ROUND(DBMS_RANDOM.VALUE(0, 300)),
            NULL,
            'Y'
        );
    END LOOP;

    -- (Commit unificado al final)

    -- 11. Fact_View (5.000 registros para testing de volumetría)
    DBMS_OUTPUT.PUT_LINE('11. Fact_View (Insertando ~5.000 filas)...');
    FOR i IN 1..5000 LOOP
        v_date := TO_DATE('2023-01-01', 'YYYY-MM-DD') + ROUND(DBMS_RANDOM.VALUE(0, 700));
        v_start_time := TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 23)), 'FM00') || ':' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 59)), 'FM00') || ':00';
        v_end_time := TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 23)), 'FM00') || ':' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 59)), 'FM00') || ':00';
        
        -- Cruce lógico de idiomas
        v_random_viewer := ROUND(DBMS_RANDOM.VALUE(1, 15200));
        IF v_random_viewer <= 4700 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(1, 5));
        ELSIF v_random_viewer <= 12200 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(6, 9));
        ELSE v_random_channel := ROUND(DBMS_RANDOM.VALUE(10, 12)); END IF;

        -- Si v_end_time es menor que v_start_time, significa que ha cruzado a día siguiente
        INSERT INTO Fact_View (
            viewer_sk, channel_sk, session_sk, activity_group_sk,
            start_date_local_sk, end_date_local_sk, start_date_utc_sk, end_date_utc_sk,
            start_time_local_sk, end_time_local_sk, start_time_utc_sk, end_time_utc_sk,
            start_junk_status_sk, end_junk_status_sk, duration_minutes
        ) VALUES (
            v_random_viewer, 
            v_random_channel, 
            ROUND(DBMS_RANDOM.VALUE(1, 500)), 
            ROUND(DBMS_RANDOM.VALUE(1, 20)),
            v_date, v_date + CASE WHEN v_end_time < v_start_time THEN 1 ELSE 0 END, 
            v_date, v_date + CASE WHEN v_end_time < v_start_time THEN 1 ELSE 0 END, 
            v_start_time, v_end_time, v_start_time, v_end_time,
            ROUND(DBMS_RANDOM.VALUE(1, 8)), ROUND(DBMS_RANDOM.VALUE(1, 8)),
            ROUND(DBMS_RANDOM.VALUE(1, 300), 2)
        );
        
        -- Commit por lotes para mantener el log transaccional bajo control
        IF MOD(i, 1000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    -- (Commit unificado al final)

    -- 12. Fact_Interaction (5.000 registros para análisis complejos)
    DBMS_OUTPUT.PUT_LINE('12. Fact_Interaction (Insertando ~5.000 filas)...');
    FOR i IN 1..5000 LOOP
        v_date := TO_DATE('2023-01-01', 'YYYY-MM-DD') + ROUND(DBMS_RANDOM.VALUE(0, 700));
        v_start_time := TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 23)), 'FM00') || ':' || TO_CHAR(ROUND(DBMS_RANDOM.VALUE(0, 59)), 'FM00') || ':00';

        -- Cruce lógico de idiomas
        v_random_viewer := ROUND(DBMS_RANDOM.VALUE(1, 15200));
        IF v_random_viewer <= 4700 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(1, 5));
        ELSIF v_random_viewer <= 12200 THEN v_random_channel := ROUND(DBMS_RANDOM.VALUE(6, 9));
        ELSE v_random_channel := ROUND(DBMS_RANDOM.VALUE(10, 12)); END IF;

        INSERT INTO Fact_Interaction (
            viewer_sk, channel_sk, session_sk, activity_sk,
            date_local_sk, time_local_sk, date_utc_sk, time_utc_sk,
            interaction_type, revenue
        ) VALUES (
            v_random_viewer,
            v_random_channel,
            ROUND(DBMS_RANDOM.VALUE(1, 500)),
            ROUND(DBMS_RANDOM.VALUE(1, 18)),
            v_date, v_start_time, v_date, v_start_time,
            CASE ROUND(DBMS_RANDOM.VALUE(1, 5))
                WHEN 1 THEN 'follow' WHEN 2 THEN 'sub' WHEN 3 THEN 'cheer' WHEN 4 THEN 'unsub' ELSE 'unfollow' END,
            CASE WHEN ROUND(DBMS_RANDOM.VALUE(1, 10)) > 8 THEN ROUND(DBMS_RANDOM.VALUE(1, 100), 2) ELSE 0 END
        );
        
        IF MOD(i, 1000) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Proceso de inserción masiva completado con éxito!');
    COMMIT;
END;
