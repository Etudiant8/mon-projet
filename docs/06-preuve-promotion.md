# 06 - Preuve promotion production-simulee

## Promotion

- **Workflow concerné** : `03-promote.yml`
- **Environnement GitHub** : `production-simulee`
- **Tag source** : `latest` (commit `sha-641ca4e`)
- **Tag cible** : `production-simulee`
- **Lien du run** : https://github.com/Etudiant8/mon-projet/actions/runs/28567349876

## Point essentiel : promotion sans rebuild

La promotion **ne reconstruit pas l'image**. Elle réutilise l'image déjà publiée dans GHCR.

### Comment ça fonctionne

```yaml
- name: Promouvoir le même artefact
  run: |
    # 1. Pull de l'image existante (celle déjà construite et testée)
    docker pull ghcr.io/${{ env.IMAGE_NAME }}:${{ inputs.source_tag }}

    # 2. Re-tag vers production-simulee (même couches, même digest)
    docker tag  ghcr.io/${{ env.IMAGE_NAME }}:${{ inputs.source_tag }} \
                ghcr.io/${{ env.IMAGE_NAME }}:production-simulee

    # 3. Push du nouveau tag (aucun build, aucune compilation)
    docker push ghcr.io/${{ env.IMAGE_NAME }}:production-simulee
```

### Preuve que la promotion s'est faite sans rebuild

Le workflow `03-promote.yml` ne contient **aucune étape `docker build`** dans le job `promote-production-simulee`.
Il effectue uniquement `docker pull` → `docker tag` → `docker push`.

Le digest de l'image `production-simulee` est **identique** au digest de l'image source :
- Source : `ghcr.io/Etudiant8/mon-projet:latest` → `sha256:6b260baa99b1e621b3da7afa2f19013208d001363c770def11cf609ddb3cc998`
- Cible  : `ghcr.io/Etudiant8/mon-projet:production-simulee` → `sha256:6b260baa99b1e621b3da7afa2f19013208d001363c770def11cf609ddb3cc998`

*(Les deux digests sont identiques car il s'agit du même artefact — uniquement le tag change.)*

## Pourquoi c'est important

En CI/CD, le principe fondamental est : **"Build once, deploy everywhere"**.

- On construit **une seule fois** lors du commit (01-ci.yml)
- On publie **une seule fois** dans le registre (02-publish-ghcr.yml)
- On **promeut** le même artefact de recette vers production (03-promote.yml)

Cela garantit que l'image qui va en production est **exactement** celle qui a été testée en recette — pas une recompilation potentiellement différente.

## Rôle de l'environnement GitHub "production-simulee"

L'environnement `production-simulee` est configuré dans **Settings → Environments**.
Il représente l'étape finale du pipeline. En production réelle, cet environnement serait protégé par :
- Des reviewers requis (validation humaine obligatoire)
- Un délai d'attente avant déploiement
- Des secrets spécifiques à la production
- Des règles de protection de branche strictes
