# 01 - Cadrage du projet

## Identité

- **Nom et prénom** : Anonyme
- **Email** : anonyme@formation.fr
- **Dépôt GitHub** : https://github.com/DEimazoute/mon-projet
- **Date de démarrage** : 27 avril 2026

## Objectif

Mettre en place une chaîne CI/CD permettant de construire, tester, publier et promouvoir une image Docker Nginx contenant un site web statique pour le scénario Catal-Log.

La chaîne doit être automatisée, traçable et reproductible. Chaque étape est documentée et prouvée par des exécutions visibles dans GitHub Actions et GHCR.

## Contraintes du projet

- Travail individuel.
- Aucune infrastructure fournie, préparée, administrée ou maintenue par le formateur.
- Pas de serveur distant, pas de SSH, pas de cloud provider imposé.
- Les traitements principaux sont exécutés dans GitHub Actions.
- Docker local n'est pas disponible sur mon environnement personnel (voir justification ci-dessous).
- Pas de VM personnelle disponible (voir justification ci-dessous).

## Choix personnels

### Dépôt
- Dépôt **public** sur GitHub pour permettre les exécutions GitHub Actions gratuites et la visibilité des preuves.
- Nom du dépôt : `mon-projet`

### Stratégie de tags
- **Tag `sha-`** : tag automatique basé sur le SHA du commit (`sha-abc1234`), pour une traçabilité précise.
- **Tag `latest`** : tag pointant toujours vers la dernière image construite sur la branche `main`.
- **Tag `production-simulee`** : tag appliqué lors de la promotion, sans rebuild.

### Environnement local
Je n'ai pas Docker installé sur mon poste de travail personnel. J'ai donc utilisé exclusivement GitHub Actions comme environnement d'exécution. Les workflows effectuent le build, le test HTTP et la publication directement sur les runners GitHub.

**Justification documentée** : l'absence de Docker local ne compromet pas la chaîne CI/CD car GitHub Actions fournit un environnement Ubuntu complet avec Docker préinstallé. Les tests HTTP automatisés dans le workflow `01-ci.yml` remplacent fonctionnellement les tests locaux.

### VM personnelle
Je ne dispose pas d'une VM personnelle. La chaîne CI/CD est entièrement exécutée dans les GitHub-hosted runners, ce qui est le cas d'usage standard des pipelines DevOps modernes.

**Justification documentée** : l'utilisation d'un runner GitHub-hosted est équivalente à une VM temporaire — elle est provisionnée, exécute les tâches, puis est détruite. Cette approche est plus propre et reproductible qu'une VM fixe.
