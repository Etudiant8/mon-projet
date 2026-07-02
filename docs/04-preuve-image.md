# 04 - Preuve image GHCR

## Image publiée

- **Nom de l'image** : `ghcr.io/Etudiant8/mon-projet`
- **Tag principal** : `sha-641ca4e`
- **Tag secondaire** : `latest`
- **Tag promotion** : `production-simulee`
- **Digest** : `sha256:6b260baa99b1e621b3da7afa2f19013208d001363c770def11cf609ddb3cc998`
- **Lien GHCR** : https://github.com/Etudiant8/mon-projet/pkgs/container/mon-projet
- **Lien run de publication** : https://github.com/Etudiant8/mon-projet/actions/runs/28567259274

*(Note : chaque push republie une image via `02-publish-ghcr.yml`, y compris pour une modification de documentation seule. Le digest change à chaque build car GitHub attache des métadonnées de provenance horodatées, même si le contenu du site est identique. Le tag et le digest ci-dessus correspondent au dernier run réussi au moment de la rédaction.)*

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
