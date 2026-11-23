# Jeu en réseau Windows et Android

Depuis le menu, ouvre **RESEAU** ou appuie sur **F11**. Active les invitations sur les appareils qui veulent les recevoir. Sur un appareil, sélectionne **INVITER**, puis accepte la fenêtre sur les autres instances. Les invitations apparaissent pendant que le jeu est ouvert et connecté. Couper les invitations remet le jeu en mode local.

Chaque participant occupe une place et peut ajouter une **Lia** ou un **Micro** dans le salon. Un bot compte pour une place. **– BOT** retire le dernier bot ajouté par ce participant tant que le salon attend. La manche commence automatiquement lorsque quatre places sont prises et que tous les participants du salon sont connectés. Pendant la partie, chaque appareil joue avec sa croix tactile, les flèches ou une manette.

Les raccourcis d’arène et de piste du clavier et du panneau Android **RACC.** sont partagés. Le volume se règle sur chaque appareil. L’hôte joue la simulation à 50 VBL/s. Les invités lui envoient leurs commandes et reçoivent les images logiques compressées à environ 25 par seconde, accompagnées des effets sonores. La musique est lue sur chaque appareil depuis une position fournie par l’hôte. Plusieurs Micro peuvent occuper des places distinctes dans un même match.

Une perte de connexion libère les commandes du joueur. L’application tente de revenir dans le même salon pendant 25 secondes. Un départ explicite pendant la partie ou l’expiration du délai ferme le salon. Le moteur reste sur l’instance qui a créé la partie pendant tout le match.

## Service Cloudflare

Le Worker `legoblast` relaie les messages via le Durable Object `LegoBlastLobby`. Le bouton Réseau utilise `wss://legoblast.elom75.workers.dev/v1/socket`. Le serveur attribue les quatre places, contrôle le rôle de l’émetteur et limite la taille des messages. Les tâches de jeu restent sur l’hôte.

Pour une installation séparée, ajuster le nom du compte dans l’URL du client ou lancer le jeu de bureau avec `--menu --network-url=wss://ADRESSE/v1/socket`. Le fichier `wrangler.toml` décrit le déploiement et la migration du Durable Object.

Le test de relais ouvre trois connexions, remplit un salon avec deux humains et deux bots, vérifie la limite de quatre, relaie une image et contrôle la reprise d’un invité. Il crée un salon éphémère sur l’URL fournie.

```sh
node port/network/check.mjs wss://legoblast.elom75.workers.dev/v1/socket
```
