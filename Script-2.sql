-- ==========================================
-- 0. LIMPIEZA DEL ENTORNO (DROP IF EXISTS)
-- ==========================================

DROP TABLE Fact_Viewer_Channel_Role CASCADE CONSTRAINTS;
DROP TABLE Fact_Interaction CASCADE CONSTRAINTS;
DROP TABLE Fact_View CASCADE CONSTRAINTS;
DROP TABLE Bridge_Activity_Group CASCADE CONSTRAINTS;
DROP TABLE Dim_Activity CASCADE CONSTRAINTS;
DROP TABLE Dim_Streaming_Session CASCADE CONSTRAINTS;
DROP TABLE Dim_Channel CASCADE CONSTRAINTS;
DROP TABLE Dim_Viewer CASCADE CONSTRAINTS;
DROP TABLE Dim_Interaction_Type CASCADE CONSTRAINTS; 
DROP TABLE Dim_Time CASCADE CONSTRAINTS;
DROP TABLE Dim_Date CASCADE CONSTRAINTS;

-- ==========================================
-- 1. CREACIÓN DE TABLAS DE DIMENSIÓN
-- ==========================================

CREATE TABLE Dim_Date (
    date_sk INT PRIMARY KEY,
    full_date DATE,
    day_of_month INT,
    day_of_week VARCHAR2(20),
    is_weekend NUMBER(1), 
    month_name VARCHAR2(20),
    quarter INT,
    year INT,
    week_of_year INT
);

CREATE TABLE Dim_Time (
    time_sk INT PRIMARY KEY,
    time_of_day VARCHAR2(20),
    hour INT,
    minute INT,
    second INT
);

CREATE TABLE Dim_Viewer (
    viewer_sk INT PRIMARY KEY,
    id_viewer VARCHAR2(50),
    gender VARCHAR2(20),
    country VARCHAR2(50),
    birthdate DATE
);

CREATE TABLE Dim_Channel (
    channel_sk INT PRIMARY KEY,
    id_channel VARCHAR2(50),
    primary_language VARCHAR2(50)
);

CREATE TABLE Dim_Streaming_Session (
    session_sk INT PRIMARY KEY,
    id_streaming_session VARCHAR2(50),
    title VARCHAR2(255),
    language VARCHAR2(50)
);

CREATE TABLE Dim_Activity (
    activity_sk INT PRIMARY KEY,
    id_activity VARCHAR2(50),
    activity_name VARCHAR2(100),
    collection_name VARCHAR2(100),
    directory_name VARCHAR2(100)
);

-- NUEVA TABLA: Tipo de Interacción
CREATE TABLE Dim_Interaction_Type (
    interaction_type_sk INT PRIMARY KEY,
    description VARCHAR2(100)
);

-- ==========================================
-- 2. CREACIÓN DE TABLAS PUENTE Y HECHOS
-- ==========================================

CREATE TABLE Bridge_Activity_Group (
    activity_group_sk INT,
    activity_sk INT,
    weighting_factor NUMBER(5,2),
    PRIMARY KEY (activity_group_sk, activity_sk),
    FOREIGN KEY (activity_sk) REFERENCES Dim_Activity(activity_sk)
);

CREATE TABLE Fact_View (
    view_sk INT PRIMARY KEY,
    viewer_sk INT,
    channel_sk INT,
    session_sk INT,
    activity_group_sk INT,
    start_date_local_sk INT,
    start_time_local_sk INT,
    end_date_local_sk INT,
    end_time_local_sk INT,
    start_date_utc_sk INT,
    start_time_utc_sk INT,
    end_date_utc_sk INT,
    end_time_utc_sk INT,
    junk_status_sk INT,
    duration_minutes INT,
    FOREIGN KEY (viewer_sk) REFERENCES Dim_Viewer(viewer_sk),
    FOREIGN KEY (channel_sk) REFERENCES Dim_Channel(channel_sk),
    FOREIGN KEY (session_sk) REFERENCES Dim_Streaming_Session(session_sk),
    FOREIGN KEY (start_date_local_sk) REFERENCES Dim_Date(date_sk)
);

CREATE TABLE Fact_Interaction (
    interaction_sk INT PRIMARY KEY,
    viewer_sk INT,
    channel_sk INT,
    session_sk INT,
    activity_sk INT,
    interaction_type_sk INT, -- NUEVA CLAVE FORÁNEA
    date_local_sk INT,
    time_local_sk INT,
    date_utc_sk INT,
    time_utc_sk INT,
    junk_status_sk INT,
    amount NUMBER(10,2), 
    revenue NUMBER(10,2), 
    FOREIGN KEY (viewer_sk) REFERENCES Dim_Viewer(viewer_sk),
    FOREIGN KEY (channel_sk) REFERENCES Dim_Channel(channel_sk),
    FOREIGN KEY (activity_sk) REFERENCES Dim_Activity(activity_sk),
    FOREIGN KEY (interaction_type_sk) REFERENCES Dim_Interaction_Type(interaction_type_sk)
);

CREATE TABLE Fact_Viewer_Channel_Role (
    role_sk INT PRIMARY KEY,
    viewer_sk INT,
    channel_sk INT,
    role_name VARCHAR2(50),
    effective_start_date DATE,
    effective_end_date DATE,
    is_current NUMBER(1), 
    FOREIGN KEY (viewer_sk) REFERENCES Dim_Viewer(viewer_sk),
    FOREIGN KEY (channel_sk) REFERENCES Dim_Channel(channel_sk)
);

-- ==========================================
-- 3. INSERCIÓN DE DATOS DE PRUEBA (SAMPLE DATA)
-- ==========================================

-- Dimensiones Base
INSERT INTO Dim_Date (date_sk, full_date, day_of_month, day_of_week, is_weekend, month_name, quarter, year, week_of_year) VALUES 
(20231012, DATE '2023-10-12', 12, 'Thursday', 0, 'October', 4, 2023, 41);
INSERT INTO Dim_Date (date_sk, full_date, day_of_month, day_of_week, is_weekend, month_name, quarter, year, week_of_year) VALUES 
(20231014, DATE '2023-10-14', 14, 'Saturday', 1, 'October', 4, 2023, 41);
INSERT INTO Dim_Date (date_sk, full_date, day_of_month, day_of_week, is_weekend, month_name, quarter, year, week_of_year) VALUES 
(20231015, DATE '2023-10-15', 15, 'Sunday', 1, 'October', 4, 2023, 41);

INSERT INTO Dim_Time (time_sk, time_of_day, hour, minute, second) VALUES 
(090000, '09:00:00', 9, 0, 0);
INSERT INTO Dim_Time (time_sk, time_of_day, hour, minute, second) VALUES 
(143000, '14:30:00', 14, 30, 0);
INSERT INTO Dim_Time (time_sk, time_of_day, hour, minute, second) VALUES 
(201500, '20:15:00', 20, 15, 0);

-- Dimensiones de Entidades
INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES 
(1, 'VWR-001', 'Male', 'Spain', DATE '1995-05-15');
INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES 
(2, 'VWR-002', 'Female', 'Mexico', DATE '2001-08-22');
INSERT INTO Dim_Viewer (viewer_sk, id_viewer, gender, country, birthdate) VALUES 
(3, 'VWR-003', 'Non-Binary', 'Argentina', DATE '1998-11-30');

INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES 
(1, 'CHN-001', 'Spanish');
INSERT INTO Dim_Channel (channel_sk, id_channel, primary_language) VALUES 
(2, 'CHN-002', 'English');

INSERT INTO Dim_Streaming_Session (session_sk, id_streaming_session, title, language) VALUES 
(1, 'SESS-1001', 'Weekend LoL Ranked Clims!', 'Spanish');
INSERT INTO Dim_Streaming_Session (session_sk, id_streaming_session, title, language) VALUES 
(2, 'SESS-1002', 'Chill Minecraft Building', 'English');
INSERT INTO Dim_Streaming_Session (session_sk, id_streaming_session, title, language) VALUES 
(3, 'SESS-1003', 'Valorant Pro Scrims', 'Spanish');

INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES 
(1, 'ACT001', 'League of Legends', 'MOBA Collection', 'MOBA');
INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES 
(2, 'ACT002', 'Valorant', 'Shooter Collection', 'FPS');
INSERT INTO Dim_Activity (activity_sk, id_activity, activity_name, collection_name, directory_name) VALUES 
(3, 'ACT003', 'Minecraft', 'Sandbox Collection', 'Sandbox');

-- NUEVOS DATOS: Tipos de Interacción
INSERT INTO Dim_Interaction_Type (interaction_type_sk, description) VALUES (1, 'Suscripción');
INSERT INTO Dim_Interaction_Type (interaction_type_sk, description) VALUES (2, 'Compra de bits');
INSERT INTO Dim_Interaction_Type (interaction_type_sk, description) VALUES (3, 'Gasto de bits');
INSERT INTO Dim_Interaction_Type (interaction_type_sk, description) VALUES (4, 'Caducidad de suscripción');

-- Tablas Puente
INSERT INTO Bridge_Activity_Group (activity_group_sk, activity_sk, weighting_factor) VALUES 
(100, 1, 1.0);
INSERT INTO Bridge_Activity_Group (activity_group_sk, activity_sk, weighting_factor) VALUES 
(101, 2, 1.0);
INSERT INTO Bridge_Activity_Group (activity_group_sk, activity_sk, weighting_factor) VALUES 
(102, 3, 1.0);

-- Tablas de Hechos
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(1, 1, 1, 1, 100, 20231012, 090000, 20231012, 143000, 20231012, 070000, 20231012, 123000, 0, 45);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(2, 2, 2, 2, 100, 20231014, 143000, 20231014, 201500, 20231014, 123000, 20231014, 181500, 0, 120);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(3, 3, 1, 3, 100, 20231015, 090000, 20231015, 143000, 20231015, 070000, 20231015, 123000, 0, 60);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(4, 1, 2, 2, 101, 20231014, 143000, 20231014, 143000, 20231014, 123000, 20231014, 123000, 0, 30);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(5, 2, 1, 1, 101, 20231015, 090000, 20231015, 090000, 20231015, 070000, 20231015, 070000, 0, 45);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(6, 3, 2, 2, 101, 20231015, 201500, 20231015, 201500, 20231015, 181500, 20231015, 181500, 0, 90);
INSERT INTO Fact_View (view_sk, viewer_sk, channel_sk, session_sk, activity_group_sk, start_date_local_sk, start_time_local_sk, end_date_local_sk, end_time_local_sk, start_date_utc_sk, start_time_utc_sk, end_date_utc_sk, end_time_utc_sk, junk_status_sk, duration_minutes) VALUES 
(7, 1, 1, 3, 102, 20231012, 143000, 20231012, 143000, 20231012, 123000, 20231012, 123000, 0, 15);

-- Fact_Interaction (Ahora incluye interaction_type_sk)
INSERT INTO Fact_Interaction (interaction_sk, viewer_sk, channel_sk, session_sk, activity_sk, interaction_type_sk, date_local_sk, time_local_sk, date_utc_sk, time_utc_sk, junk_status_sk, amount, revenue) VALUES 
(1, 1, 1, 1, 1, 1, 20231014, 143000, 20231014, 123000, 0, 5.00, 3.50); -- 1 = Suscripción
INSERT INTO Fact_Interaction (interaction_sk, viewer_sk, channel_sk, session_sk, activity_sk, interaction_type_sk, date_local_sk, time_local_sk, date_utc_sk, time_utc_sk, junk_status_sk, amount, revenue) VALUES 
(2, 2, 2, 2, 3, 2, 20231015, 201500, 20231015, 181500, 0, 10.00, 7.00); -- 2 = Compra de bits
INSERT INTO Fact_Interaction (interaction_sk, viewer_sk, channel_sk, session_sk, activity_sk, interaction_type_sk, date_local_sk, time_local_sk, date_utc_sk, time_utc_sk, junk_status_sk, amount, revenue) VALUES 
(3, 3, 1, 3, 2, 4, 20231012, 090000, 20231012, 070000, 0, 0.00, 0.00); -- 4 = Caducidad

INSERT INTO Fact_Viewer_Channel_Role (role_sk, viewer_sk, channel_sk, role_name, effective_start_date, effective_end_date, is_current) VALUES 
(1, 1, 1, 'Subscriber', DATE '2023-01-01', NULL, 1);
INSERT INTO Fact_Viewer_Channel_Role (role_sk, viewer_sk, channel_sk, role_name, effective_start_date, effective_end_date, is_current) VALUES 
(2, 2, 2, 'Moderator', DATE '2022-05-10', NULL, 1);
INSERT INTO Fact_Viewer_Channel_Role (role_sk, viewer_sk, channel_sk, role_name, effective_start_date, effective_end_date, is_current) VALUES 
(3, 3, 1, 'Follower', DATE '2023-10-01', NULL, 1);

COMMIT;

-- ==========================================
-- 4. CONSULTA DE NEGOCIO (EJEMPLO)
-- ==========================================

SELECT 
    a.directory_name AS categoria_videojuego,
    COUNT(fv.view_sk) AS numero_visualizaciones
FROM Fact_View fv
JOIN Dim_Date d 
    ON fv.start_date_local_sk = d.date_sk
JOIN Bridge_Activity_Group bag 
    ON fv.activity_group_sk = bag.activity_group_sk
JOIN Dim_Activity a 
    ON bag.activity_sk = a.activity_sk
WHERE d.is_weekend = 1
GROUP BY a.directory_name
ORDER BY numero_visualizaciones DESC;