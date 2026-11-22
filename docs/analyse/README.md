# LegoBlast · Analyse de phase 1

L’objectif est de documenter le comportement de l’assembleur Amiga pour évaluer la faisabilité d’une réécriture fidèle. L’analyse part du commit `5b0725ad3b92dd4d45a099442c48972b2f14d966` et se réfère aux lignes de cette révision. Elle couvre le déroulement du jeu, la représentation des niveaux, les points de dépendance au matériel et les moyens de mesurer la fidélité sur une future cible.

| Document | Contenu |
| --- | --- |
| [Fonctionnement](fonctionnement.md) | Démarrage, cadence, règles et code à consulter pour chaque sous-système |
| [Données et ressources](donnees.md) | Inventaire vérifié, format des niveaux, dépendances graphiques et sonores |
| [Validation de la fidélité](validation.md) | Références disponibles, vérifications déjà effectuées et scénarios proposés |
| [Choix de la cible](choix-cible.md) | Compromis entre C++, Python et Web, avec une méthode de décision commune |

## Résultats qui orientent le travail

- La logique est répartie entre l’interruption vidéo et la boucle principale. Les contrôles, la mise à jour des bombes et la propagation des flammes suivent un ordre qui peut changer l’issue d’une collision.
- Le dépôt et l’archive Aminet contiennent deux exécutables Amiga distincts. Les 130 fichiers de niveau comparés sont identiques octet pour octet. Les différences éventuelles d’exécution doivent être attribuées à une référence précise.
- Le plateau enregistré est une grille de 19 × 15 tuiles. Le moteur traite les collisions sur une grille plus fine et conserve des couches distinctes pour les bombes, les flammes et d’autres objets. Une capture d’écran ne suffit donc pas à expliquer une divergence de simulation.
- Pour une seule implémentation avec un objectif de fidélité élevé, C++ constitue le choix par défaut. Si le navigateur est la seule cible et que la diffusion par URL prime, TypeScript est une option directe. Python convient bien pour étudier les fichiers et comparer des traces, et reste une cible jouable si le prototype remplit les critères de cadence et d’audio.

La [validation](validation.md) indique les limites de la vérification actuelle, dont l’absence d’un binaire reconstruit à partir de la révision étudiée.
