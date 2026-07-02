# 04 - Preuve image GHCR

## Image publiée

- **Nom de l'image** : `ghcr.io/Etudiant8/mon-projet`
- **Tag principal** : `sha-6fe66b3`
- **Tag secondaire** : `latest`
- **Tag promotion** : `production-simulee`
- **Digest** : `sha256:df86bf7a1397dfaca5dd0849c3b2ef02afefce92524f61106f0df5d60f4182e3`
- **Lien GHCR** : https://github.com/Etudiant8/mon-projet/pkgs/container/mon-projet

## Comment retrouver le digest

Le digest est affiché dans le résumé du workflow `02-publish-ghcr.yml`, dans la section "Publication GHCR" :

```
Image : ghcr.io/Etudiant8/mon-projet
Tags : sha-abc1234 / latest
Digest : sha256:abc123...
```

Il est également visible sur la page GHCR du package, dans l'onglet "Package versions".

## Explication : tag vs digest

### Le tag
Un tag est un **alias humain lisible** qui pointe vers une image. Il peut être réécrit (par exemple `latest` est mis à jour à chaque build). Il est utile pour identifier rapidement quelle version est déployée.

### Le digest (sha256)
Le digest est l'**empreinte cryptographique immuable** de l'image. Il ne change jamais, même si le tag est réattribué. C'est la garantie que l'artefact déployé est **exactement** celui qui a été construit et testé.

### Pourquoi c'est important pour la traçabilité et le rollback

| Besoin | Tag | Digest |
|---|---|---|
| Identifier une version rapidement | ✅ | ✅ |
| Garantir l'immuabilité de l'artefact | ❌ (peut être réécrit) | ✅ |
| Rollback vers une version précise | Partiel | ✅ (certitude absolue) |
| Audit et conformité | Insuffisant seul | ✅ |

**Exemple concret de rollback avec le digest** :

```bash
# Revenir à une version précise via son digest
docker pull ghcr.io/Etudiant8/mon-projet@sha256:abc123...

# Ou dans le workflow 03-promote.yml, utiliser le tag sha- correspondant :
# source_tag: sha-abc1234
```

La promotion repose sur ce principe : on ne reconstruit jamais l'image, on promeut le même digest d'un environnement à l'autre.
