## 📌 **SCÉNARIO 1 : Surveillance des Tablespaces**

### **Tâches :**
1. **Créer une vue agrégée** de l’utilisation des tablespaces
2. **Détecter les tablespaces à risque** (> 80% d’utilisation)
3. **Générer une alerte automatique** si > 90%
4. **Visualiser l’évolution** sur 7 jours

### **Requêtes :**
```sql
-- 1. Vue globale
SELECT tablespace_name, used_percent 
FROM dba_tablespace_usage_metrics 
ORDER BY used_percent DESC;

-- 2. Alerte
SELECT tablespace_name, used_percent 
FROM dba_tablespace_usage_metrics 
WHERE used_percent > 80;
```

---

## 📌 **SCÉNARIO 2 : Suivi de l’espace FRA (Fast Recovery Area)**

### **Tâches :**
1. **Surveiller l’espace utilisé** vs limite
2. **Alerter si > 85%**
3. **Proposer une extension automatique** (si configuré)

### **Requêtes :**
```sql
-- Espace FRA
SELECT 
    ROUND(space_used/1024/1024, 2) AS used_mb,
    ROUND(space_limit/1024/1024, 2) AS limit_mb,
    ROUND((space_used/space_limit)*100, 2) AS used_percent
FROM v$recovery_file_dest;
```

---

## 📌 **SCÉNARIO 3 : Vérification des Datafiles**

### **Tâches :**
1. **Lister tous les datafiles** avec statut et taille
2. **Détecter les datafiles non disponibles** (OFFLINE, CORRUPT)
3. **Surveiller l’auto-extensibilité**
4. **Générer un script de correction** si nécessaire

### **Requêtes :**
```sql
-- État des datafiles
SELECT file_name, tablespace_name, status, bytes/1024/1024 AS size_mb
FROM dba_data_files
ORDER BY tablespace_name;

-- Problèmes détectés
SELECT file_name, status 
FROM dba_data_files 
WHERE status <> 'AVAILABLE';
```

---

## 📌 **SCÉNARIO 4 : Contrôle du mode ARCHIVELOG**

### **Tâches :**
1. **Vérifier si la base est en ARCHIVELOG**
2. **Alerter si désactivé** (risque de perte de données)
3. **Fournir le script d’activation**

### **Requêtes :**
```sql
-- Vérification
SELECT log_mode FROM v$database;

-- Script d'activation (documentation)
/*
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
*/
```

---

## 📌 **SCÉNARIO 5 : Suivi des sauvegardes RMAN**

### **Tâches :**
1. **Afficher les dernières sauvegardes** (7 derniers jours)
2. **Détecter les échecs** de sauvegarde
3. **Vérifier la dernière sauvegarde complète**
4. **Alerter si pas de backup depuis 24h**

### **Requêtes :**
```sql
-- Historique des sauvegardes
SELECT start_time, end_time, status, input_type
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE - 7
ORDER BY start_time DESC;

-- Dernière sauvegarde réussie
SELECT MAX(end_time) AS last_backup
FROM v$rman_backup_job_details
WHERE status = 'COMPLETED';
```

---

## 📌 **SCÉNARIO 6 : Nettoyage et maintenance**

### **Tâches :**
1. **Surveiller la taille des archives logs**
2. **Proposer un nettoyage** des vieux archives (> 7 jours)
3. **Vérifier l’espace libérable**

### **Commandes :**
```sql
-- Taille archives par jour
SELECT TRUNC(completion_time) AS jour,
       COUNT(*) AS nb_archives,
       SUM(blocks * block_size)/1024/1024 AS total_mb
FROM v$archived_log
GROUP BY TRUNC(completion_time)
ORDER BY jour DESC;
```

```rman
-- Commande de nettoyage
DELETE ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-7';
```

---

## 📌 **SCÉNARIO 7 : Actions correctives intégrées**

### **Tâches :**
1. **Redimensionner un datafile** depuis le dashboard
2. **Ajouter un datafile** à un tablespace plein
3. **Augmenter la taille du FRA**
4. **Lancer un backup manuel** (bouton d’action)

### **Commandes d’action :**
```sql
-- 1. Redimensionnement
ALTER DATABASE DATAFILE '/chemin/datafile.dbf' RESIZE 4G;

-- 2. Ajout datafile
ALTER TABLESPACE nom_tablespace 
ADD DATAFILE '/chemin/nouveau.dbf' SIZE 2G 
AUTOEXTEND ON NEXT 100M MAXSIZE 10G;

-- 3. Extension FRA
ALTER SYSTEM SET db_recovery_file_dest_size = 30G;
```

---

## 📌 **LIVRABLES ATTENDUS de Yousra :**

1. **Dossier : 04_Stockage_Sauvegarde/**
   ```
   ├── 📄 Surveillance_Tablespaces.sql
   ├── 📄 Suivi_Espace_FRA.sql
   ├── 📄 Verification_Datafiles.sql
   ├── 📄 Controle_ARCHIVELOG.sql
   ├── 📄 Suivi_Sauvegardes_RMAN.sql
   ├── 📄 Nettoyage_Archives.sql
   ├── 📄 Commandes_Action_Rapide.md
   └── 📄 Alertes_Configurations.json
   ```

2. **Dashboard visuel :**
   - Jauge : % utilisation tablespace
   - Graphique : Évolution FRA
   - Tableau : Datafiles avec statuts
   - Timeline : Sauvegardes RMAN
   - Boutons d’action : Resize, Add, Backup

3. **Alertes configurables :**
   - Tablespace > 80%
   - FRA > 85%
   - Pas de backup depuis 24h
   - ARCHIVELOG désactivé
