# 07 - Sécurité minimale

## Permissions GitHub Actions

Les workflows appliquent le **principe du moindre privilège** : chaque workflow ne reçoit que les permissions strictement nécessaires.

| Workflow | Permissions | Justification |
|---|---|---|
| `01-ci.yml` | `contents: read` | Lire le code source uniquement — aucun besoin d'écriture |
| `02-publish-ghcr.yml` | `contents: read` + `packages: write` | Lire le code + écrire dans GHCR |
| `03-promote.yml` | `contents: read` + `packages: write` | Lire + re-tagger l'image dans GHCR |

Sans déclaration explicite de permissions, GitHub accordait historiquement des droits étendus. La déclaration explicite réduit la surface d'attaque : si un workflow est compromis par une injection de code malveillant, il ne peut pas écrire dans le dépôt ou accéder à d'autres ressources.

## Gestion des secrets

### Pourquoi aucun secret ne doit être stocké dans le code

Stocker un secret (token, mot de passe, clé API) directement dans le code ou dans un fichier du dépôt présente plusieurs risques critiques :
- **Exposition publique** : si le dépôt est public, le secret est immédiatement accessible à tous.
- **Historique Git** : même supprimé, un secret commité reste visible dans l'historique (`git log`).
- **Rotation impossible** : changer un secret nécessite de modifier le code et de recommitter.
- **Non-conformité** : les standards de sécurité (CIS, NIST, ISO 27001) interdisent cette pratique.

### Usage du GITHUB_TOKEN dans ce projet

Le `GITHUB_TOKEN` est un token temporaire **généré automatiquement par GitHub** pour chaque exécution de workflow. Il :
- N'est jamais stocké dans le code
- Expire à la fin de chaque run
- Est limité aux permissions déclarées dans le workflow
- Est révocable par GitHub en cas d'incident

```yaml
# Exemple d'utilisation dans 02-publish-ghcr.yml
- name: Connexion à GHCR avec GITHUB_TOKEN
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}   # ← jamais en clair dans le code
```

### Éléments à placer dans GitHub Secrets en production réelle

| Élément | Stockage recommandé |
|---|---|
| Tokens d'accès externes (registre privé) | GitHub Secrets |
| Clés API (services tiers) | GitHub Secrets ou coffre (Vault, AWS Secrets Manager) |
| Mots de passe de base de données | Coffre de secrets (jamais dans le code) |
| Certificats TLS | Gestionnaire de certificats (Let's Encrypt, Vault PKI) |
| Variables par environnement | GitHub Environment Secrets (recette vs prod séparés) |

## Rollback

### Comment revenir à une version précédente

Le rollback s'appuie sur les **tags** et les **digests** conservés dans GHCR.

**Méthode 1 — Rollback via tag SHA**
```bash
# Identifier le tag de la version précédente dans GHCR
# Ex: sha-abc1234 correspond au commit abc1234

# Déclencher le workflow 03-promote.yml avec ce tag
# Actions → Run workflow → source_tag: sha-abc1234
```

**Méthode 2 — Rollback via digest**
```bash
# Utiliser le digest exact de l'image précédente (immuable)
docker pull ghcr.io/Etudiant8/mon-projet@sha256:abc123...
docker tag  ghcr.io/Etudiant8/mon-projet@sha256:abc123... \
            ghcr.io/Etudiant8/mon-projet:production-simulee
docker push ghcr.io/Etudiant8/mon-projet:production-simulee
```

**Avantage du rollback par artefact** : on ne reconstruit pas l'image — on réutilise exactement ce qui a fonctionné avant. Le digest garantit l'intégrité.

## Sauvegarde / restauration

### Ce qu'il faudrait sauvegarder

| Élément | Méthode de sauvegarde |
|---|---|
| Dépôt GitHub (code + historique) | Git lui-même + export/mirror régulier |
| Workflows (`.github/workflows/`) | Versionnés dans le dépôt |
| Documentation (`docs/*.md`) | Versionnée dans le dépôt |
| Images Docker publiées (GHCR) | Conservation des tags anciens + archivage |
| Secrets et configuration | Coffre de secrets sécurisé (Vault, AWS SM) |
| Environnements GitHub | Documentation + Infrastructure as Code |
| Preuves d'exécution | Captures + liens archivés dans les docs |

### Procédure de restauration

1. **Restaurer le code** : `git clone` depuis GitHub (ou depuis un mirror)
2. **Restaurer les images** : GHCR conserve les images — les tags `sha-` permettent de retrouver toute version
3. **Restaurer les secrets** : réinjecter depuis le coffre de secrets dans les GitHub Secrets
4. **Recréer les environnements** : recréer `recette` et `production-simulee` dans Settings → Environments
5. **Vérifier** : déclencher un run complet pour valider la restauration

## Deux éléments complémentaires pour la production réelle

### 1. Contrôle des vulnérabilités (Trivy)

En production réelle, chaque image Docker devrait être scannée avant publication. L'outil **Trivy** s'intègre directement dans GitHub Actions :

```yaml
- name: Scanner les vulnérabilités avec Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: projet-cicd:${{ github.sha }}
    format: table
    exit-code: 1           # Bloque le pipeline si vulnérabilité CRITICAL
    severity: CRITICAL,HIGH
```

Cela garantit qu'aucune image avec des failles connues critiques n'est publiée.

### 2. Séparation stricte des environnements

En production, les environnements `recette` et `production` doivent être **strictement séparés** :
- Secrets différents (tokens, clés, credentials)
- Règles de protection différentes (reviewers obligatoires en production)
- Registres d'images distincts si possible
- Accès réseau cloisonnés
- Journalisation et alertes spécifiques à chaque environnement

Dans ce projet, la simulation est réalisée via les environnements GitHub (`recette` et `production-simulee`), mais en production réelle il faudrait des infrastructures physiquement ou logiquement séparées.
