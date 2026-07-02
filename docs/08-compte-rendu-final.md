# 08 - Compte rendu final

**Auteur** : Etudiant_8  
**Évaluation** : EC06 — ASRC  
**Date** : 27 avril 2026

---

## 1. Synthèse

J'ai mis en place une chaîne CI/CD complète pour industrialiser la publication d'un site web statique Nginx pour l'entreprise fictive Catal-Log. La chaîne repose sur GitHub Actions et GitHub Container Registry (GHCR), sans serveur à administrer.

Le pipeline est composé de trois workflows :
- `01-ci.yml` : build automatique et test HTTP à chaque commit
- `02-publish-ghcr.yml` : publication de l'image taguée dans GHCR à chaque push sur `main`
- `03-promote.yml` : validation en recette simulée puis promotion manuelle en production simulée, sans rebuild

La chaîne respecte le principe fondamental du CI/CD : **Build once, deploy everywhere** — l'image est construite une seule fois et promue telle quelle.

---

## 2. Fonctionnement technique

### Chemin complet d'une livraison

1. **Commit** : je pousse une modification sur la branche `main`
2. **Build** : le workflow `01-ci.yml` se déclenche automatiquement — il construit l'image Docker et la teste via HTTP sur le port 8080
3. **Publication** : le workflow `02-publish-ghcr.yml` publie l'image dans GHCR avec deux tags : `sha-<commit>` (traçabilité) et `latest` (commodité)
4. **Validation recette** : je déclenche manuellement `03-promote.yml` — il pull l'image depuis GHCR et la teste dans l'environnement GitHub `recette`
5. **Promotion** : si la recette est validée, le même workflow re-tag l'image vers `production-simulee` et la pousse dans GHCR — **aucun rebuild**

---

## 3. Conteneurisation C12

### Le Dockerfile

```dockerfile
FROM nginx:1.27-alpine          # Image de base légère et sécurisée
COPY site/ /usr/share/nginx/html/   # Injection du site statique
RUN chmod -R 755 /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O - http://127.0.0.1/ >/dev/null || exit 1
```

**Choix techniques** :
- `nginx:1.27-alpine` : image Alpine très légère (~8 Mo) et maintenue activement
- `HEALTHCHECK` : permet à Docker et aux orchestrateurs de détecter si le conteneur est réellement fonctionnel
- Permissions `755` : accès en lecture seule pour les fichiers du site

### Image produite

- Taille approximative : ~15 Mo (site statique inclus)
- Tags publiés : `sha-<commit>`, `latest`, `production-simulee`
- Registre : `ghcr.io/Etudiant8/mon-projet`

### Preuves

- Lien GHCR : https://github.com/Etudiant8/mon-projet/pkgs/container/mon-projet
- Lien run CI : https://github.com/Etudiant8/mon-projet/actions/workflows/01-ci.yml

---

## 4. Orchestration et scaling C13

### compose.yml

Le fichier `compose.yml` décrit deux services :

- `web` : le serveur Nginx (image construite localement depuis le Dockerfile)
- `tester` : un conteneur `curlimages/curl` qui teste automatiquement le bon fonctionnement de `web`

Ce second service démontre la **coordination de plusieurs conteneurs** : il attend le démarrage de `web` (`depends_on`), puis exécute des tests HTTP et affiche le résultat.

### Simulation de scaling

La simulation de scaling (`docker compose up --scale web=2`) est documentée dans `docs/03-fiche-tests.md` avec les commandes exécutées et le résultat observé localement avec Docker Desktop.

### Limites de Docker Compose vs production réelle

Docker Compose est un excellent outil pour le développement et les tests locaux. En production, ses limites sont fondamentales :

| Besoin | Docker Compose | Kubernetes |
|---|---|---|
| Haute disponibilité | ❌ | ✅ |
| Répartition de charge | ❌ (manuel) | ✅ (Service + Ingress) |
| Auto-scaling (HPA) | ❌ | ✅ |
| Rolling update / rollback | ❌ | ✅ |
| Supervision intégrée | ❌ | ✅ (Prometheus, Grafana) |

**Lien avec la chaîne CI/CD** : la reproductibilité de la chaîne (même Dockerfile, même image, même processus de promotion) garantit que ce qui fonctionne dans Compose fonctionnera dans Kubernetes — sous réserve d'adapter les ressources (Deployment, Service, Ingress).

---

## 5. Automatisation et sécurité C14

### Les trois workflows

- **01-ci.yml** : déclenché sur chaque push/PR, vérifie les fichiers, construit et teste l'image
- **02-publish-ghcr.yml** : déclenché sur push vers main, publie l'image dans GHCR
- **03-promote.yml** : déclenché manuellement, valide en recette et promeut en production simulée

### GITHUB_TOKEN et permissions

Aucun secret manuel n'est créé. Le `GITHUB_TOKEN` est utilisé pour s'authentifier auprès de GHCR — il est généré automatiquement par GitHub, limité aux permissions déclarées, et expire à la fin du run.

Les permissions sont réduites au minimum nécessaire dans chaque workflow (`contents: read` + `packages: write` seulement là où c'est nécessaire).

### Absence de secrets dans le code

Aucune clé, token ou credential n'est présent dans le code source, les fichiers de configuration ou l'historique Git. Tout secret futur devrait transiter par GitHub Secrets ou un coffre (HashiCorp Vault, AWS Secrets Manager).

### Rollback

Le rollback est possible à tout moment grâce aux tags `sha-<commit>` conservés dans GHCR. Il suffit de déclencher `03-promote.yml` avec le tag de la version précédente — l'image est promue sans rebuild, avec la certitude absolue du digest.

### Sauvegarde/restauration

Le dépôt GitHub contient l'intégralité de la chaîne (code, workflows, documentation). Les images sont conservées dans GHCR. La restauration complète est possible depuis Git + GHCR.

---

## 6. Production réelle

### Gestion des secrets

En production, le `GITHUB_TOKEN` serait remplacé par des tokens dédiés avec des droits limités. Les secrets applicatifs (clés de base de données, API keys, certificats) seraient stockés dans un coffre de secrets (HashiCorp Vault, AWS Secrets Manager) et injectés au runtime, jamais dans le code.

### Rollback

Le rollback en production s'appuierait sur les digests d'image (immuables) et les tags `sha-`. Un workflow dédié permettrait de re-promouvoir une version précédente en un clic, sans reconstruction.

### Sauvegarde/restauration

En production réelle, je sauvegarderais : le dépôt GitHub (miroir), les workflows, la documentation, les images GHCR (avec politique de rétention), les secrets (dans Vault), les configurations des environnements. La restauration serait testée régulièrement (exercice de DR).

### Éléments complémentaires

**Contrôle des vulnérabilités** : intégration de Trivy dans le pipeline pour scanner les images avant publication et bloquer les builds avec des CVE critiques.

**Séparation stricte des environnements** : en production, `recette` et `production` auraient des secrets distincts, des règles de protection différentes (reviewers obligatoires, délais d'attente), et idéalement des infrastructures réseau séparées.

---

## 7. Preuves

| Élément | Lien |
|---|---|
| Dépôt GitHub | https://github.com/Etudiant8/mon-projet |
| Runs 01-ci.yml | https://github.com/Etudiant8/mon-projet/actions/workflows/01-ci.yml |
| Runs 02-publish-ghcr.yml | https://github.com/Etudiant8/mon-projet/actions/workflows/02-publish-ghcr.yml |
| Runs 03-promote.yml | https://github.com/Etudiant8/mon-projet/actions/workflows/03-promote.yml |
| Image GHCR | https://github.com/Etudiant8/mon-projet/pkgs/container/mon-projet |

---

## 8. Difficultés et apprentissages

### Difficultés rencontrées

- **Comprendre le rôle respectif de GitHub Actions et de Docker local** : les traitements principaux (build, test, publication, promotion) devaient rester dans GitHub Actions. Le test local avec Docker Desktop est venu en complément, ce qui m'a demandé de bien comprendre la structure des workflows pour que les deux environnements restent cohérents.

- **Comprendre la différence tag vs digest** : au départ, j'assimilais tag et digest. La documentation m'a permis de comprendre qu'un tag peut être réécrit (mutable) alors que le digest est l'empreinte cryptographique immuable de l'image.

- **La promotion sans rebuild** : comprendre pourquoi on ne doit pas reconstruire en promotion a été un apprentissage important. `docker tag` et `docker push` permettent de re-tagger une image existante sans recompiler quoi que ce soit — le digest reste identique.

### Ce que j'ai compris techniquement

1. Un pipeline CI/CD est avant tout une question de **confiance** : on teste une fois, on promeut ce qui a été testé.
2. Les **environnements GitHub** permettent une séparation claire des étapes de déploiement, avec traçabilité et contrôle d'accès.
3. Le `GITHUB_TOKEN` est un mécanisme élégant d'authentification temporaire qui évite de gérer des secrets manuellement pour les opérations standard.
4. Docker Compose est un outil pédagogique excellent pour comprendre l'orchestration, mais Kubernetes est indispensable pour une vraie production avec haute disponibilité et scaling automatique.
