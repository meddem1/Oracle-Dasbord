📘 TABLE DES MATIÈRES

Conception et mise en place d’un Dashboard intelligent de supervision et de contrôle d’une base de données Oracle destiné aux DBA

Remerciements
Dédicaces
Résumé
Abstract
1. Introduction Générale

1.1 Contexte du projet
1.2 Problématique
1.3 Objectifs du projet
 1.3.1 Objectif général
 1.3.2 Objectifs spécifiques
1.4 Méthodologie adoptée
1.5 Structure du rapport

2. Présentation Générale d’Oracle Database

2.1 Introduction à Oracle Database
2.2 Architecture Oracle
 2.2.1 Instance Oracle (SGA & Background Processes)
 2.2.2 Structure physique (Datafiles, Redo Logs, Control Files)
2.3 Architecture Multitenant (CDB / PDB)
2.4 Rôle et responsabilités du DBA

3. Analyse des Besoins

3.1 Étude de l’existant
3.2 Problématiques identifiées
3.3 Besoins fonctionnels
3.4 Besoins non fonctionnels
3.5 Contraintes techniques et sécuritaires

4. Cahier des Charges

4.1 Présentation du projet
4.2 Architecture technique choisie
4.3 Description des modules
4.4 Planning de réalisation

5. Conception de la Solution

5.1 Présentation globale du Dashboard
5.2 Architecture générale de l’application
5.3 Diagramme d’architecture
5.4 Modélisation des données (SQLite)
5.5 Diagramme des rôles utilisateurs

6. Implémentation et Développement

6.1 Environnement de développement
6.2 Intégration Oracle avec PHP (OCI8)
6.3 Développement du module Monitoring
 6.3.1 État de l’instance
 6.3.2 Sessions actives et bloquées
 6.3.3 Surveillance CPU
 6.3.4 Tablespaces et stockage
 6.3.5 Logs Oracle
6.4 Développement du module Administration
 6.4.1 Gestion des PDB
 6.4.2 Gestion des utilisateurs Oracle
 6.4.3 Gestion des sessions
 6.4.4 SQL Runner
6.5 Système d’alertes automatiques

7. Sécurité de l’Application

7.1 Authentification (BCRYPT)
7.2 Gestion des rôles (SuperAdmin, DBA, Viewer)
7.3 Chiffrement AES-256 des identifiants Oracle
7.4 Protection CSRF
7.5 Sécurisation des accès

8. Interface Utilisateur (UI/UX)

8.1 Structure générale
8.2 Dashboard principal
8.3 Navigation
8.4 Présentation graphique des KPI

9. Scénario de Validation : Projet Alpha

9.1 Création de PDB_ALPHA
9.2 Création de l’utilisateur ALPHA_ADMIN
9.3 Création des objets (tables)
9.4 Vérification du stockage
9.5 Audit des logs
9.6 Résultats obtenus

10. Tests et Validation

10.1 Tests fonctionnels
10.2 Tests de sécurité
10.3 Tests de performance
10.4 Résultats

11. Organisation et Gestion du Projet

11.1 Répartition des tâches
11.2 Planning (Gantt)
11.3 Difficultés rencontrées
11.4 Solutions apportées

12. Indicateurs de Performance (KPI)

12.1 Indicateurs techniques
12.2 Indicateurs de supervision
12.3 Indicateurs de sécurité

13. Conclusion Générale

13.1 Bilan du projet
13.2 Limites
13.3 Perspectives d’évolution

Annexes

Annexe A : Glossaire
Annexe B : Requêtes SQL utilisées
Annexe C : Captures d’écran
Annexe D : Références bibliographiques
