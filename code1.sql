📘 DOSSIER TECHNIQUE COMPLET : REQUÊTES SQL PAR SCÉNARIO
Projet Dashboard Oracle – Responsable Performance : Amanou Wiam
📁 1. SCÉNARIO 1 : SESSIONS BLOQUÉES EN TEMPS RÉEL
1.1 Requête de collecte des données
sql
-- Collecte des sessions actives avec blocage
INSERT INTO STG_PERF_SESSION (session_id, username, status, blocking_session, cpu_used, sample_time)
SELECT 
    s.sid AS session_id,
    s.username,
    s.status,
    s.blocking_session,
    st.value AS cpu_used,
    SYSTIMESTAMP AS sample_time
FROM V$SESSION s
LEFT JOIN V$SESSTAT st ON s.sid = st.sid
LEFT JOIN V$STATNAME sn ON st.statistic# = sn.statistic#
WHERE sn.name = 'CPU used by this session'
  AND s.type = 'USER'
  AND s.username IS NOT NULL;
1.2 Requête pour le dashboard (temps réel)
sql
SELECT 
    s1.session_id AS blocker_sid,
    s1.username AS blocker_user,
    s2.session_id AS blocked_sid,
    s2.username AS blocked_user,
    s2.status AS blocked_status,
    TO_CHAR(s2.sample_time, 'HH24:MI:SS') AS blocked_since,
    s2.cpu_used AS blocked_cpu
FROM FACT_SESSION s1
JOIN FACT_SESSION s2 ON s1.session_id = s2.blocking_session
WHERE s2.blocking_session IS NOT NULL
  AND s2.sample_time > SYSTIMESTAMP - INTERVAL '5' MINUTE
ORDER BY s2.sample_time DESC;
1.3 Vue matérialisée pour optimisation
sql
CREATE MATERIALIZED VIEW MV_BLOCKING_SESSIONS
REFRESH FAST ON COMMIT
AS
SELECT 
    s1.session_id AS blocker_sid,
    s1.username AS blocker_user,
    s2.session_id AS blocked_sid,
    s2.username AS blocked_user,
    s2.sample_time
FROM FACT_SESSION s1
JOIN FACT_SESSION s2 ON s1.session_id = s2.blocking_session
WHERE s2.blocking_session IS NOT NULL;
📁 2. SCÉNARIO 2 : REQUÊTES GOURMANDES EN CPU
2.1 Collecte des requêtes lentes
sql
-- Collecte TOP 20 requêtes par CPU
INSERT INTO STG_PERF_SQL (sql_id, sql_text, elapsed_time, cpu_time, executions, disk_reads, buffer_gets, sample_time)
SELECT 
    sql_id,
    sql_text,
    elapsed_time,
    cpu_time,
    executions,
    disk_reads,
    buffer_gets,
    SYSTIMESTAMP
FROM (
    SELECT 
        sql_id,
        SUBSTR(sql_text, 1, 1000) AS sql_text,
        elapsed_time,
        cpu_time,
        executions,
        disk_reads,
        buffer_gets,
        RANK() OVER (ORDER BY cpu_time DESC) AS cpu_rank
    FROM V$SQL
    WHERE parsing_schema_name NOT IN ('SYS', 'SYSTEM')
      AND cpu_time > 0
      AND last_active_time > SYSDATE - 1/24  -- Dernière heure
)
WHERE cpu_rank <= 20;
2.2 Requête dashboard (TOP 10 CPU - 1 heure)
sql
SELECT 
    sql_id,
    SUBSTR(sql_text, 1, 100) AS sql_extrait,
    ROUND(cpu_time / 1000000, 2) AS cpu_seconds,
    executions,
    ROUND(elapsed_time / 1000000, 2) AS elapsed_seconds,
    ROUND(buffer_gets / NULLIF(executions, 0), 0) AS buffer_gets_per_exec,
    TO_CHAR(sample_time, 'HH24:MI') AS heure_collecte
FROM FACT_SQL
WHERE sample_time > SYSTIMESTAMP - INTERVAL '1' HOUR
  AND cpu_time > 1000000  -- > 1 seconde CPU
ORDER BY cpu_time DESC
FETCH FIRST 10 ROWS ONLY;
2.3 Vue agrégée pour tendances
sql
CREATE VIEW V_CPU_QUERIES_HOURLY AS
SELECT 
    TRUNC(sample_time, 'HH') AS heure,
    sql_id,
    SUM(cpu_time) AS total_cpu_time,
    SUM(executions) AS total_executions,
    COUNT(*) AS nb_echantillons
FROM FACT_SQL
WHERE sample_time > SYSDATE - 7
GROUP BY TRUNC(sample_time, 'HH'), sql_id;
📁 3. SCÉNARIO 3 : SURVEILLANCE TABLESPACES
3.1 Collecte espace disque
sql
-- Collecte statut tablespaces
INSERT INTO STG_STORAGE (tablespace_name, total_mb, used_mb, free_mb, used_percent, sample_time)
SELECT 
    d.tablespace_name,
    ROUND(SUM(d.bytes) / 1024 / 1024, 2) AS total_mb,
    ROUND(SUM(d.bytes - NVL(f.bytes, 0)) / 1024 / 1024, 2) AS used_mb,
    ROUND(NVL(SUM(f.bytes), 0) / 1024 / 1024, 2) AS free_mb,
    ROUND((SUM(d.bytes - NVL(f.bytes, 0)) / SUM(d.bytes)) * 100, 2) AS used_percent,
    SYSTIMESTAMP
FROM DBA_DATA_FILES d
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) AS bytes
    FROM DBA_FREE_SPACE
    GROUP BY tablespace_name
) f ON d.tablespace_name = f.tablespace_name
GROUP BY d.tablespace_name;
3.2 Requête dashboard avec alertes
sql
WITH dernier_echantillon AS (
    SELECT MAX(sample_time) AS dernier_ts FROM FACT_STORAGE
)
SELECT 
    s.tablespace_name,
    ROUND(s.total_mb, 2) AS total_mb,
    ROUND(s.used_mb, 2) AS used_mb,
    ROUND(s.used_percent, 2) AS used_percent,
    CASE 
        WHEN s.used_percent > 95 THEN '🔴 CRITIQUE'
        WHEN s.used_percent > 85 THEN '🟠 ALERTE'
        WHEN s.used_percent > 70 THEN '🟡 ATTENTION'
        ELSE '🟢 NORMAL'
    END AS statut,
    TO_CHAR(s.sample_time, 'DD/MM HH24:MI') AS derniere_maj
FROM FACT_STORAGE s, dernier_echantillon d
WHERE s.sample_time = d.dernier_ts
  AND s.tablespace_name NOT LIKE 'TEMP%'
ORDER BY s.used_percent DESC;
3.3 Vue d'évolution sur 7 jours
sql
CREATE VIEW V_STORAGE_TREND AS
SELECT 
    tablespace_name,
    TRUNC(sample_time) AS jour,
    MAX(used_percent) AS max_used_percent,
    MIN(used_percent) AS min_used_percent,
    ROUND(AVG(used_percent), 2) AS avg_used_percent
FROM FACT_STORAGE
WHERE sample_time > SYSDATE - 7
GROUP BY tablespace_name, TRUNC(sample_time);
📁 4. SCÉNARIO 4 : UTILISATEURS VERROUILLÉS/EXPIRÉS
4.1 Collecte statut utilisateurs
sql
-- Mise à jour DIM_USER
MERGE INTO DIM_USER du
USING (
    SELECT 
        username,
        account_status,
        lock_date,
        expiry_date,
        created,
        profile
    FROM DBA_USERS
    WHERE username NOT LIKE '%SYS%'
) src
ON (du.username = src.username)
WHEN MATCHED THEN 
    UPDATE SET 
        du.account_status = src.account_status,
        du.lock_date = src.lock_date,
        du.expiry_date = src.expiry_date,
        du.profile = src.profile,
        du.last_update = SYSDATE
WHEN NOT MATCHED THEN 
    INSERT (username, account_status, lock_date, expiry_date, created, profile)
    VALUES (src.username, src.account_status, src.lock_date, src.expiry_date, src.created, src.profile);
4.2 Requête dashboard sécurité
sql
SELECT 
    username,
    account_status,
    TO_CHAR(lock_date, 'DD/MM/YYYY') AS lock_date,
    TO_CHAR(expiry_date, 'DD/MM/YYYY') AS expiry_date,
    profile,
    TO_CHAR(created, 'DD/MM/YYYY') AS created_date,
    CASE 
        WHEN account_status LIKE 'LOCKED%' THEN '🔒'
        WHEN account_status LIKE 'EXPIRED%' THEN '⏰'
        ELSE '✅'
    END AS icone_statut
FROM DIM_USER
WHERE account_status IN ('LOCKED', 'LOCKED(TIMED)', 'EXPIRED', 'EXPIRED(GRACE)')
   OR lock_date > SYSDATE - 30
ORDER BY lock_date DESC NULLS LAST, expiry_date DESC;
📁 5. SCÉNARIO 5 : TENTATIVES DE CONNEXION ÉCHOUÉES
5.1 Collecte logs d'audit
sql
-- Création table de staging pour audit
CREATE TABLE STG_AUDIT_LOG AS
SELECT 
    username,
    timestamp,
    action_name,
    returncode,
    os_username,
    userhost
FROM DBA_AUDIT_SESSION
WHERE 1=0;

-- Insertion nouvelles tentatives échouées
INSERT INTO STG_AUDIT_LOG
SELECT 
    username,
    timestamp,
    action_name,
    returncode,
    os_username,
    userhost
FROM DBA_AUDIT_SESSION
WHERE returncode != 0
  AND timestamp > SYSTIMESTAMP - INTERVAL '1' HOUR;
5.2 Requête heatmap des échecs
sql
SELECT 
    username,
    TO_CHAR(TRUNC(timestamp, 'HH24'), 'HH24') AS heure,
    COUNT(*) AS failed_attempts,
    LISTAGG(TO_CHAR(timestamp, 'HH24:MI'), ', ') WITHIN GROUP (ORDER BY timestamp) AS heures_detail
FROM STG_AUDIT_LOG
WHERE timestamp > SYSDATE - 1  -- 24 dernières heures
GROUP BY username, TO_CHAR(TRUNC(timestamp, 'HH24'), 'HH24')
HAVING COUNT(*) >= 3
ORDER BY failed_attempts DESC, heure;
5.3 Vue agrégée par plage horaire
sql
CREATE VIEW V_FAILED_LOGINS_DAILY AS
SELECT 
    TRUNC(timestamp) AS jour,
    username,
    COUNT(*) AS total_failed,
    MIN(timestamp) AS first_attempt,
    MAX(timestamp) AS last_attempt
FROM STG_AUDIT_LOG
GROUP BY TRUNC(timestamp), username;
📁 6. SCÉNARIO 6 : ÉTAT SAUVEGARDES RMAN
6.1 Collecte statut backups
sql
-- Table de staging RMAN
CREATE TABLE STG_RMAN_STATUS AS
SELECT 
    start_time,
    end_time,
    input_type,
    status,
    input_bytes,
    output_bytes,
    SYSTIMESTAMP AS collect_time
FROM V$RMAN_BACKUP_JOB_DETAILS
WHERE 1=0;

-- Insertion nouveaux jobs
INSERT INTO STG_RMAN_STATUS
SELECT 
    start_time,
    end_time,
    input_type,
    status,
    input_bytes,
    output_bytes,
    SYSTIMESTAMP
FROM V$RMAN_BACKUP_JOB_DETAILS
WHERE start_time > SYSDATE - 1/24;  -- Dernière heure
6.2 Requête dashboard sauvegardes
sql
SELECT 
    TO_CHAR(start_time, 'DD/MM HH24:MI') AS debut,
    TO_CHAR(end_time, 'DD/MM HH24:MI') AS fin,
    input_type AS type_backup,
    CASE status
        WHEN 'COMPLETED' THEN '🟢 SUCCÈS'
        WHEN 'FAILED' THEN '🔴 ÉCHEC'
        WHEN 'RUNNING' THEN '🟠 EN COURS'
        ELSE status
    END AS statut,
    ROUND(input_bytes/1024/1024, 1) AS input_mb,
    ROUND(output_bytes/1024/1024, 1) AS output_mb,
    ROUND((end_time - start_time) * 24 * 60, 0) AS duree_minutes
FROM STG_RMAN_STATUS
WHERE start_time > SYSDATE - 7
ORDER BY start_time DESC;
6.3 Vue statut dernier backup par type
sql
CREATE VIEW V_LAST_BACKUP_BY_TYPE AS
SELECT 
    input_type,
    MAX(start_time) AS last_backup_time,
    status AS last_status,
    ROUND(MIN((end_time - start_time) * 24 * 60), 0) AS min_duration_min,
    ROUND(MAX((end_time - start_time) * 24 * 60), 0) AS max_duration_min
FROM STG_RMAN_STATUS
GROUP BY input_type, status;
📁 7. SCÉNARIO 7 : MODE ARCHIVELOG & ARCHIVES
7.1 Collecte info archives
sql
-- Table statut archive log
CREATE TABLE STG_ARCHIVE_STATUS AS
SELECT 
    name,
    log_mode,
    archiver,
    SYSTIMESTAMP AS sample_time
FROM V$DATABASE;

-- Collecte espace archives
INSERT INTO STG_ARCHIVE_STATUS
SELECT 
    'ARCHIVE_SPACE' AS name,
    NULL AS log_mode,
    TO_CHAR(ROUND(SUM(blocks * block_size)/1024/1024, 2)) || ' MB' AS archiver,
    SYSTIMESTAMP
FROM V$ARCHIVED_LOG
WHERE completion_time > SYSDATE - 1;
7.2 Requête dashboard archive
sql
SELECT 
    'Mode Archive' AS indicateur,
    log_mode AS valeur,
    CASE WHEN log_mode = 'ARCHIVELOG' THEN '🟢' ELSE '🔴' END AS statut
FROM V$DATABASE
UNION ALL
SELECT 
    'Archives 24h',
    TO_CHAR(COUNT(*)) || ' fichiers',
    CASE WHEN COUNT(*) > 100 THEN '🟠' ELSE '🟢' END
FROM V$ARCHIVED_LOG
WHERE completion_time > SYSDATE - 1
UNION ALL
SELECT 
    'Espace archives 24h',
    ROUND(SUM(blocks * block_size)/1024/1024, 2) || ' MB',
    CASE WHEN SUM(blocks * block_size) > 10*1024*1024*1024 THEN '🟠' ELSE '🟢' END
FROM V$ARCHIVED_LOG
WHERE completion_time > SYSDATE - 1;
📋 FICHE TECHNIQUE TYPE PAR REQUÊTE
Modèle de documentation :
text
┌─────────────────────────────────────────────────────┐
│ FICHE REQUÊTE SQL - [NOM DU SCÉNARIO]               │
├─────────────────────────────────────────────────────┤
│ ID : SCENARIO_01                                    │
│ Objectif : Détection sessions bloquées temps réel   │
│ Fréquence : Toutes les 1 minute                     │
│ Tables source : V$SESSION, V$SESSTAT                │
│ Tables destination : FACT_SESSION                   │
│ Impact performance : Faible (0.2s d'exécution)      │
│ Responsable : Amanou Wiam                           │
│ Dernière modification : 15/03/2024                  │
├─────────────────────────────────────────────────────┤
│ PARAMÈTRES :                                        │
│ - intervalle_minutes : 5 (fenêtre d'analyse)        │
│ - seuil_cpu : 100000 (filtre sessions inactives)    │
├─────────────────────────────────────────────────────┤
│ ALERTES ASSOCIÉES :                                 │
│ - CRITICAL : Session bloquée > 5 minutes            │
│ - WARNING : Plus de 3 sessions bloquées simultanées │
└─────────────────────────────────────────────────────┘
⚙️ SCRIPT DE DÉPLOIEMENT COMPLET
sql
-- ============================================
-- SCRIPT DE DÉPLOIEMENT - COLLECTE AUTOMATIQUE
-- ============================================

-- 1. Création des jobs planifiés
BEGIN
    -- Job sessions (toutes les 1 min)
    DBMS_SCHEDULER.CREATE_JOB(
        job_name   => 'COLLECT_SESSIONS_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => 'BEGIN INSERT INTO STG_PERF_SESSION...; END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1',
        enabled    => TRUE
    );
    
    -- Job requêtes (toutes les 15 min)
    DBMS_SCHEDULER.CREATE_JOB(
        job_name   => 'COLLECT_SQL_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => 'BEGIN INSERT INTO STG_PERF_SQL...; END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=15',
        enabled    => TRUE
    );
    
    -- Job stockage (toutes les 30 min)
    DBMS_SCHEDULER.CREATE_JOB(
        job_name   => 'COLLECT_STORAGE_JOB',
        job_type   => 'PLSQL_BLOCK',
        job_action => 'BEGIN INSERT INTO STG_STORAGE...; END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=30',
        enabled    => TRUE
    );
END;
/

-- 2. Création des vues pour le dashboard
CREATE OR REPLACE VIEW V_DASHBOARD_SUMMARY AS
SELECT 
    'SESSIONS' AS categorie,
    COUNT(*) AS valeur,
    TO_CHAR(MAX(sample_time), 'HH24:MI') AS derniere_maj
FROM FACT_SESSION
WHERE sample_time > SYSTIMESTAMP - INTERVAL '5' MINUTE
UNION ALL
SELECT 
    'REQUÊTES LENTES',
    COUNT(*),
    TO_CHAR(MAX(sample_time), 'HH24:MI')
FROM FACT_SQL
WHERE sample_time > SYSTIMESTAMP - INTERVAL '1' HOUR
  AND elapsed_time > 10000000  -- > 10 secondes
UNION ALL
SELECT 
    'TABLESPACES >80%',
    COUNT(*),
    TO_CHAR(MAX(sample_time), 'HH24:MI')
FROM FACT_STORAGE
WHERE used_percent > 80;
📊 EXEMPLE DE SORTIE JSON POUR L'API DASHBOARD
json
{
  "dashboard": {
    "timestamp": "2024-03-15T14:30:00",
    "statut_general": "NORMAL",
    "alertes_actives": 2,
    "metriques": [
      {
        "scenario": "sessions_bloquees",
        "valeur": 3,
        "seuil": 0,
        "statut": "WARNING",
        "donnees": [
          {"blocker": "USER1", "blocked": "USER2", "since": "14:28:15"},
          {"blocker": "USER3", "blocked": "USER4", "since": "14:29:30"}
        ]
      },
      {
        "scenario": "tablespaces",
        "valeur": 92,
        "seuil": 85,
        "statut": "CRITICAL",
        "donnees": [
          {"tablespace": "USERS", "used_percent": 92, "free_mb": 120}
        ]
      }
    ]
  }
}
