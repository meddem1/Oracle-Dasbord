1️⃣ MODULE : CHECK-UP INSTANCE (Health Check)
✅ État de la base

SELECT name, open_mode, database_role, log_mode
FROM v$database;

________________________________________
✅ État de l’instance

SELECT instance_name, status, startup_time
FROM v$instance;

________________________________________
✅ Vérification SGA (mémoire)

SELECT component,
       current_size/1024/1024 AS MB
FROM v$sga_dynamic_components
ORDER BY current_size DESC;
Mémoire libre :
SELECT name, bytes/1024/1024 AS MB
FROM v$sgainfo
WHERE name LIKE '%Free%';

________________________________________
✅ Vérification dernière sauvegarde RMAN

SELECT MAX(completion_time) AS LAST_BACKUP
FROM v$backup_set;
________________________________________

🏗 2️⃣ MODULE : GESTION PDB (Multitenant)
✅ Liste des PDB

SELECT name, open_mode, total_size/1024/1024 AS SIZE_MB
FROM v$pdbs;

________________________________________
✅ Création PDB_ALPHA

CREATE PLUGGABLE DATABASE PDB_ALPHA
ADMIN USER pdb_admin IDENTIFIED BY Alpha123
FILE_NAME_CONVERT = ('pdbseed','pdb_alpha');

________________________________________
✅ Ouvrir la PDB

ALTER PLUGGABLE DATABASE PDB_ALPHA OPEN;

________________________________________
✅ Vérifier statut

SELECT name, open_mode
FROM v$pdbs
WHERE name = 'PDB_ALPHA';

________________________________________
👤 3️⃣ MODULE : GESTION UTILISATEURS
⚠️ Important : Se connecter d’abord :

ALTER SESSION SET CONTAINER = PDB_ALPHA;
________________________________________
✅ Création user ALPHA_ADMIN

CREATE USER ALPHA_ADMIN
IDENTIFIED BY Alpha@2025
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;

________________________________________
✅ Donner privilèges

GRANT CONNECT, RESOURCE TO ALPHA_ADMIN;
________________________________________
✅ Donner quota illimité

ALTER USER ALPHA_ADMIN QUOTA UNLIMITED ON USERS;
________________________________________
✅ Voir les users de la PDB

SELECT username, account_status, created
FROM dba_users
ORDER BY created DESC;
________________________________________
📦 4️⃣ MODULE : INITIALISATION SCHÉMA
Connecté sur PDB_ALPHA :

ALTER SESSION SET CONTAINER = PDB_ALPHA;
________________________________________
✅ Création table STOCKS

CREATE TABLE ALPHA_ADMIN.STOCKS (
    ID NUMBER PRIMARY KEY,
    NOM VARCHAR2(50),
    QUANTITE NUMBER,
    DATE_ENTREE DATE DEFAULT SYSDATE
);
________________________________________
✅ Vérifier les tables

SELECT table_name
FROM dba_tables
WHERE owner = 'ALPHA_ADMIN';
________________________________________
💾 5️⃣ MODULE : STOCKAGE & TABLESPACES
✅ Utilisation des tablespaces

SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024) AS MB
FROM dba_data_files
GROUP BY tablespace_name;
________________________________________
✅ Espace libre

SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024) AS FREE_MB
FROM dba_free_space
GROUP BY tablespace_name;
________________________________________
✅ Croissance par PDB

SELECT con_id,
       SUM(bytes)/1024/1024 AS SIZE_MB
FROM cdb_data_files
GROUP BY con_id;
________________________________________
📊 6️⃣ MODULE : PERFORMANCE
✅ Sessions actives

SELECT username, status, program
FROM v$session
WHERE status = 'ACTIVE';
________________________________________
✅ Top requêtes consommatrices CPU

SELECT sql_text, executions, cpu_time/1000000 AS CPU_SEC
FROM v$sql
ORDER BY cpu_time DESC
FETCH FIRST 5 ROWS ONLY;
________________________________________
✅ Wait Events

SELECT event, total_waits, time_waited
FROM v$system_event
ORDER BY time_waited DESC;
________________________________________
🔐 7️⃣ MODULE : SÉCURITÉ & AUDIT
✅ Comptes verrouillés

SELECT username, account_status
FROM dba_users
WHERE account_status LIKE '%LOCK%';
________________________________________
✅ Profils

SELECT profile, resource_name, limit
FROM dba_profiles
WHERE profile = 'DEFAULT';
________________________________________
✅ Tentatives de connexion échouées

SELECT username, timestamp, returncode
FROM dba_audit_session
WHERE returncode != 0;
________________________________________
📜 8️⃣ MODULE : LOGS & ERREURS ORA
✅ Voir erreurs récentes

SELECT originating_timestamp,
       message_text
FROM v$diag_alert_ext
WHERE message_text LIKE '%ORA-%'
ORDER BY originating_timestamp DESC;
________________________________________
🔥 9️⃣ MODULE BONUS (PROJET PRO)
📈 Dashboard KPI global

SELECT
  (SELECT COUNT(*) FROM v$session) AS TOTAL_SESSIONS,
  (SELECT COUNT(*) FROM dba_users) AS TOTAL_USERS,
  (SELECT COUNT(*) FROM v$pdbs) AS TOTAL_PDB,
  (SELECT ROUND(SUM(bytes)/1024/1024) FROM dba_data_files) AS TOTAL_DB_MB
FROM dual;
________________________________________
🎯 Résultat
Avec ces requêtes tu peux construire :
•	📊 Graphiques SGA
•	📈 Graphique utilisation tablespace
•	👥 Monitoring utilisateurs
•	🏗 Gestion PDB
•	🔐 Sécurité
•	⚡ Performance
•	📜 Logs système
•	💾 Stockage
•	🔍 SQL Runner

