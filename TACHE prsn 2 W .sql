👩‍💻 🎯 Personne 2 – Surveillance & Performance (Projet Alpha)
✅ 1️⃣ Vérifier les sessions actives dans PDB_ALPHA

🎯 Objectif : Voir si l’application commence à générer de la charge.

ALTER SESSION SET CONTAINER = PDB_ALPHA;

SELECT username,
       status,
       machine,
       program,
       logon_time
FROM v$session
WHERE type = 'USER';


🔎 Surveillance :

Trop de sessions = risque surcharge

Sessions INACTIVE très longues = problème applicatif

✅ 2️⃣ Détecter les sessions bloquées (Blocking Sessions)

🎯 Objectif : Vérifier qu’il n’y a pas de blocage après création des tables.

SELECT s1.sid || ',' || s1.serial# AS bloqueur,
       s2.sid || ',' || s2.serial# AS bloque,
       s1.username
FROM v$lock l1
JOIN v$session s1 ON l1.sid = s1.sid
JOIN v$lock l2 ON l1.id1 = l2.id1 AND l1.id2 = l2.id2
JOIN v$session s2 ON l2.sid = s2.sid
WHERE l1.block = 1;


🔎 Si résultat ≠ vide → problème critique

✅ 3️⃣ Surveiller la consommation CPU

🎯 Objectif : Vérifier si ALPHA_ADMIN consomme trop de ressources.

SELECT s.username,
       s.sid,
       s.serial#,
       p.spid,
       s.program,
       ss.value AS cpu_usage
FROM v$session s
JOIN v$sesstat ss ON s.sid = ss.sid
JOIN v$statname sn ON ss.statistic# = sn.statistic#
JOIN v$process p ON s.paddr = p.addr
WHERE sn.name = 'CPU used by this session'
AND s.username IS NOT NULL
ORDER BY ss.value DESC;


🔎 Surveillance :

Une session avec CPU élevé = requête lourde

Peut nécessiter optimisation SQL

✅ 4️⃣ Identifier les requêtes lentes (SQL lent)

🎯 Objectif : Voir si l’application génère des requêtes mal optimisées.

SELECT sql_id,
       executions,
       elapsed_time/1000000 AS temps_total_sec,
       elapsed_time/decode(executions,0,1,executions)/1000000 AS temps_moyen_sec
FROM v$sql
WHERE executions > 0
ORDER BY temps_moyen_sec DESC
FETCH FIRST 10 ROWS ONLY;


🔎 Analyse :

Temps moyen élevé = problème index / plan d'exécution

✅ 5️⃣ Vérifier l'utilisation mémoire (SGA)

🎯 Objectif : Confirmer qu'il reste de la mémoire après création PDB_ALPHA.

SELECT component,
       current_size/1024/1024 AS MB
FROM v$sga_dynamic_components;


🔎 Si SGA presque saturée → risque performance

✅ 6️⃣ Monitoring en temps réel (Sessions actives)

🎯 Voir les sessions actuellement actives :

SELECT sid,
       username,
       status,
       event,
       wait_class,
       seconds_in_wait
FROM v$session
WHERE status = 'ACTIVE';


🔎 Si beaucoup de wait_class = 'Application' ou 'Concurrency'
→ contention

📊 Résumé de ton rôle dans le scénario Alpha
Étape	Ton intervention
Création PDB	Vérifier impact performance
Création user	Vérifier sessions
Création tables	Vérifier SQL lent
Import données	Surveiller CPU
Post-déploiement	Détecter blocages
🎓 Conclusion (Rôle Personne 2)

Tu es responsable de :

✔ Stabilité performance

✔ Détection des anomalies

✔ Analyse des requêtes lentes

✔ Surveillance charge CPU

✔ Prévention des blocages

Tu ne crées rien.
Tu surveilles, analyses, optimises.
