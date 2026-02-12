🔎 Monitoring avancé

📊 KPI performance

🚨 Alertes automatiques

⚡ Analyse I/O

🧠 Analyse mémoire PGA

📈 AWR / charge globale

🔐 Détection anomalie utilisateur ALPHA_ADMIN

👩‍💻 PERSONNE 2 — SURVEILLANCE & PERFORMANCE (VERSION AVANCÉE)
✅ 1️⃣ Vérifier la charge globale de la base

🎯 Voir si le Projet Alpha impacte l’instance globale

SELECT 
    TO_CHAR(begin_time, 'HH24:MI') AS heure,
    value AS active_sessions
FROM v$sysmetric_history
WHERE metric_name = 'Average Active Sessions'
ORDER BY begin_time DESC;


🔎 KPI :

Active Sessions > nombre de CPU → surcharge

✅ 2️⃣ Vérifier la charge CPU système globale
SELECT 
    metric_name,
    value
FROM v$sysmetric
WHERE metric_name IN ('CPU Usage Per Sec', 
                      'Host CPU Utilization (%)');


🔎 Si CPU > 80% → risque saturation

✅ 3️⃣ Analyse I/O (Disque)

🎯 Voir si PDB_ALPHA génère trop d’accès disque

SELECT 
    file_id,
    phyrds,
    phywrts,
    readtim,
    writetim
FROM v$filestat;


🔎 Indicateur :

readtim / writetim élevé → disque lent

✅ 4️⃣ Surveillance Tablespaces PDB_ALPHA
ALTER SESSION SET CONTAINER = PDB_ALPHA;

SELECT 
    tablespace_name,
    ROUND(used_space*8/1024,2) AS used_MB,
    ROUND(tablespace_size*8/1024,2) AS total_MB,
    ROUND((used_space/tablespace_size)*100,2) AS usage_percent
FROM dba_tablespace_usage_metrics;


🚨 Alerte si > 85%

✅ 5️⃣ Analyse mémoire PGA (requêtes lourdes)
SELECT 
    name,
    value/1024/1024 AS MB
FROM v$pgastat
WHERE name IN ('total PGA allocated',
               'total PGA inuse');


🔎 Si PGA augmente fortement → requêtes mal optimisées

✅ 6️⃣ Top 10 requêtes les plus consommatrices CPU
SELECT *
FROM (
    SELECT 
        sql_id,
        cpu_time/1000000 AS cpu_sec,
        executions,
        parsing_schema_name
    FROM v$sql
    ORDER BY cpu_time DESC
)
WHERE ROWNUM <= 10;


🎯 Identifier si ALPHA_ADMIN apparaît

✅ 7️⃣ Détection Deadlocks
SELECT * 
FROM v$session
WHERE event LIKE '%deadlock%';


🚨 Deadlock = incident critique

✅ 8️⃣ Vérifier les Wait Events dominants
SELECT 
    event,
    total_waits,
    time_waited
FROM v$system_event
ORDER BY time_waited DESC;


🔎 Si :

db file sequential read → problème index

log file sync → problème commit

✅ 9️⃣ Vérifier Temp Tablespace (requêtes lourdes)
SELECT 
    tablespace_name,
    used_blocks*8/1024 AS used_MB
FROM v$temp_space_header;


🚨 Si TEMP saturé → tri massif / requêtes mal écrites

✅ 🔟 Uptime & stabilité instance
SELECT 
    instance_name,
    status,
    startup_time
FROM v$instance;


🎯 Vérifier qu’il n’y a pas eu de redémarrage anormal

📊 KPI PERFORMANCE À AFFICHER DANS TON DASHBOARD
KPI	Seuil Critique
CPU > 80%	🔴
Tablespace > 85%	🔴
Sessions actives > CPU cores	🔴
Requête > 3 sec moyenne	⚠
Deadlock détecté	🔴
TEMP > 70%	⚠
🚨 ALERTES AUTOMATIQUES À IMPLÉMENTER

Tu peux créer des alertes automatiques via requêtes conditionnelles :

Exemple :

SELECT COUNT(*) 
FROM v$session
WHERE blocking_session IS NOT NULL;


Si résultat > 0 → afficher alerte rouge dans dashboard.

🎯 Ton Rôle Stratégique dans le Projet Alpha

Tu es responsable de :

✔ Performance temps réel
✔ Stabilité instance
✔ Détection surcharge
✔ Analyse requêtes lentes
✔ Optimisation
✔ Prévention incident
