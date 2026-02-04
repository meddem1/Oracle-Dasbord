# 📊 Dashboard : Administration Oracle 

[![Database Status](https://img.shields.io/badge/Oracle_PDB-Active-success?style=for-the-badge&logo=oracle)](https://github.com/votre-repo)
[![Project Phase](https://img.shields.io/badge/Phase-Configuration_Initiale-blue?style=for-the-badge)](https://github.com/votre-repo)
[![Backup Status](https://img.shields.io/badge/RMAN_Backup-Ready-brightgreen?style=for-the-badge)](https://github.com/votre-repo)

## 📝 Présentation du Projet
Gestion d'une infrastructure **Oracle Multitenant** pour une plateforme d'enseignement supportant des pics de charge durant les sessions d'examens au Maroc.

---

## 🏗️ Architecture & Suivi des Tâches

### 📋 Tableau de Bord de l'Équipe
| Membre | Module Oracle | Statut | Jalon (Milestone) |
| :--- | :--- | :---: | :--- |
| **Wiam** | Configuration PDB | ✅ | Setup Infrastructure |
| **Yousra** | Gestion Stockage (TS) | 🏗️ | Stockage & I/O |
| **Abderrahim** | Sécurité & Profils | ⏳ | Hardening |
| **Salma** | Schéma & Objets | 🏗️ | Modélisation |
| **Mohamed** | Stratégie RMAN | ✅ | Disponibilité |

---

## 🛠️ État des Composants Techniques

### 💾 Stockage (Tablespaces)
- [x] **TS_ELEARN_DATA** : Données étudiants (Autoextend ON)
- [ ] **TS_ELEARN_EXAMS** : Données critiques (Local Management)
- [x] **UNDO_RETENTION** : Configuré pour transactions longues (Examens)

### 🔐 Sécurité & Ressources
> **Profil `STUDENT_PROF` :**
> - Sessions simultanées : 1
> - CPU par session : 10s
> - Idle Time : 15 min

---

## 📂 Structure du Répertoire
| Fichier | Description | Responsable |
| :--- | :--- | :--- |
| `01_setup_pdb.sql` | Création de la PDB & Instance | **Wiam** |
| `02_storage_mgmt.sql` | Scripts `CREATE TABLESPACE` | **Yousra** |
| `03_resource_profiles.sql` | Gestion `CREATE PROFILE` | **Abderrahim** |
| `04_db_schema.sql` | Tables (Users, Exams, Answers) | **Salma** |
| `05_backup_strategy.rman
