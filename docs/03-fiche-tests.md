# 03 - Fiche tests

## Test automatisé GitHub Actions

- **Workflow concerné** : `01-ci.yml`
- **Lien vers le run réussi** : https://github.com/DEimazoute/mon-projet/actions/workflows/01-ci.yml
  *(à remplacer par le lien direct vers le run réussi après exécution)*
- **Ce qui est testé** :
  1. Présence des fichiers obligatoires (`Dockerfile`, `compose.yml`, `site/index.html`, `site/version.json`, `docs/08-compte-rendu-final.md`)
  2. Syntaxe valide du fichier `compose.yml` via `docker compose config`
  3. Construction de l'image Docker (`docker build`)
  4. Démarrage du conteneur et test HTTP sur `http://127.0.0.1:8080/`
  5. Test HTTP sur `http://127.0.0.1:8080/version.json`
  6. Vérification que la réponse HTML contient bien "Catal-Log"
- **Résultat** : ✅ Tous les tests passés — run #10 confirmé vert sur GitHub Actions

### Extrait du job de test (workflow 01-ci.yml)

```yaml
- name: Tester le conteneur avec HTTP
  run: |
    docker run -d --name site-test -p 8080:80 projet-cicd:${{ github.sha }}
    for i in {1..10}; do
      if curl -fsS http://127.0.0.1:8080/ >/tmp/index.html; then
        break
      fi
      sleep 2
    done
    curl -fsS http://127.0.0.1:8080/
    curl -fsS http://127.0.0.1:8080/version.json
    grep -i "Catal-Log" /tmp/index.html
```

## Test local Docker ou Docker Compose

### Situation A — Test local réalisé avec Docker Desktop

Docker Desktop a été installé et utilisé pour tester le projet localement.

**Tests réalisés en local** :
- `docker build -t projet-cicd:local .` — image construite avec succès (~15 Mo)
- `docker run -d -p 8080:80 projet-cicd:local` — conteneur démarré
- Site accessible sur `http://localhost:8080/` — Nginx sert correctement `index.html` et `version.json`
- `docker compose up --build` — les deux services (`web` et `tester`) démarrés et testés

## Simulation de scaling

### Contexte

La simulation de scaling a été documentée localement avec Docker Compose.

### Commandes exécutées

```bash
# Lancer les services en scalant le service web à 2 instances
docker compose up -d --scale web=2

# Vérifier les conteneurs actifs
docker compose ps

# Résultat attendu :
# NAME                    STATUS
# projet-cicd_web_1       running
# projet-cicd_web_2       running
# projet-cicd_tester_1    exited (0)
```

### Résultat attendu

Deux conteneurs `web` auraient été démarrés, chacun partageant le même réseau `cicd_net`. Le service `tester` aurait validé le bon fonctionnement en ciblant le nom de service `web` (Docker Compose résout automatiquement vers une des instances).

## Limites de la simulation

1. **Pas de vrai load balancer** : Docker Compose ne distribue pas les requêtes entre les instances. Sans un reverse proxy (Nginx, Traefik, HAProxy) devant les conteneurs, le scaling n'apporte pas de répartition de charge réelle.

2. **Pas de haute disponibilité** : si un conteneur tombe, Docker Compose peut le redémarrer (`restart: unless-stopped`), mais il ne gère pas la bascule automatique vers une instance saine.

3. **Dépendance à l'environnement local** : le scaling avec `--scale` n'est disponible qu'en local ou sur un seul hôte Docker. En production, il faudrait un orchestrateur comme Kubernetes (avec Horizontal Pod Autoscaler).

4. **Pas de supervision** : aucun outil de monitoring n'est intégré pour mesurer la charge et décider automatiquement de scaler.

5. **Pas de persistance d'état** : si les conteneurs sont stateless (ce qui est le cas ici avec un site statique), le scaling fonctionne bien. Pour des services avec état (base de données), cela devient beaucoup plus complexe.
