# Formulaire de contribution

Le site fonctionne sans serveur : le formulaire prépare un message et propose de l’ouvrir dans la messagerie ou de le copier. Il ne prétend pas avoir envoyé un message.

Pour activer l’envoi direct après activation de la boîte officielle :

1. Déployer `contributions.py` derrière un reverse proxy HTTPS, avec limites de taille, de débit et de connexions. Le service écoute uniquement sur 127.0.0.1. Le limiteur intégré est partagé par adresse de connexion; derrière un proxy, configurer aussi une limite par visiteur dans le proxy.
2. Fournir les variables d’environnement `SMTP_HOST`, `SMTP_PORT` (465 par défaut), `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `MAIL_TO` et `ALLOWED_ORIGINS` (origines exactes séparées par des virgules, sans barre finale). Les identifiants restent hors du dépôt et du site généré.
3. Définir `CONTRIBUTION_EMAIL` avec la boîte officielle activée et `CONTRIBUTION_ENDPOINT=https://votre-service/contributions` pendant le rendu Quarto. Le formulaire activera l’envoi direct. Le texte de confidentialité s’adapte automatiquement au mode.
4. Tester une réception réelle avec autorisation d’envoi et vérifier les erreurs SMTP, la limitation et les origines refusées avant publication. Aucun service n’est déployé par ce dépôt.

Aucune pièce jointe ni publication automatique. Le destinataire est fixé côté serveur. Aucune donnée de proposition n’est journalisée ou stockée sur disque par le service. Les messages reçus restent dans la boîte de destination selon sa gestion habituelle.
