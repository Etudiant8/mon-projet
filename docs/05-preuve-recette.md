# 05 - Preuve recette simulée

## Workflow de validation recette

- **Workflow concerné** : `03-promote.yml`
- **Environnement GitHub** : `recette`
- **Tag source validé** : `latest` (commit `sha-35d0a9a`)
- **Digest observé** : `sha256:054d4ca9f730eb115a9f5b21d1a83ce1a03fd83f12b985e8514e80b1b17f6c27`
- **Lien du run** : https://github.com/Etudiant8/mon-projet/actions/runs/28567113428

## Comment déclencher la validation recette

1. Dans GitHub, aller dans **Actions → 03 - Promotion recette vers production-simulee**
2. Cliquer sur **Run workflow**
3. Saisir le tag à promouvoir (ex: `latest` ou `sha-abc1234`)
4. Cliquer sur **Run workflow** — le job `validate-recette` s'exécute en premier

## Ce qui se passe dans le job validate-recette

```yaml
environment: recette   # Environnement GitHub "recette" activé
```

1. L'image est **pullée depuis GHCR sans rebuild** (`docker pull ghcr.io/...:<tag>`)
2. Un conteneur est démarré sur le port 8080
3. Curl teste `http://127.0.0.1:8080/` et `http://127.0.0.1:8080/version.json`
4. Le digest de l'image est relevé et affiché dans le résumé
5. Le conteneur est nettoyé après le test

## Résultat

Le test HTTP en recette simulée vérifie que :
- L'image publiée dans GHCR démarre correctement
- Nginx sert bien les pages attendues (index.html et version.json)
- Le comportement est identique à ce qui a été testé dans 01-ci.yml

C'est la preuve que **l'artefact publié** est fonctionnel, indépendamment de l'environnement où il a été construit.

## Rôle de l'environnement GitHub "recette"

L'environnement `recette` est configuré dans **Settings → Environments** du dépôt GitHub.
Il permet de :
- Tracer les déploiements par environnement dans l'interface GitHub
- Ajouter des règles de protection (reviewers requis, délai d'attente) si nécessaire
- Séparer les secrets et variables par environnement
- Avoir un historique de déploiement clair par environnement
