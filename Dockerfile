FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="Projet CICD - Catal-Log"
LABEL org.opencontainers.image.description="Image Nginx servant un site statique pour l'évaluation EC06 - Etudiant_8"
LABEL org.opencontainers.image.source="https://github.com/Etudiant8/mon-projet"
LABEL org.opencontainers.image.authors="Etudiant_8"

COPY site/ /usr/share/nginx/html/
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -q -O - http://127.0.0.1/ >/dev/null || exit 1
