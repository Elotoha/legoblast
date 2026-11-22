# Choix du langage et de la plateforme

## Ce que le langage doit permettre

La priorité est de reproduire les comportements établis par l’assembleur. Quel que soit le langage, isoler l’état et les règles de jeu du rendu, de l’audio, des périphériques et du stockage. Un même scénario doit pouvoir avancer la simulation d’un tick, sans fenêtre ni son, à partir d’un état et d’entrées enregistrés. L’essai avec affichage doit utiliser les mêmes règles. Les formats de données, l’ordre des événements et les observations de référence restent communs aux trois cibles.

Le noyau devra représenter explicitement la largeur des valeurs, la distinction signé/non signé aux comparaisons et le débordement quand il a un effet observable. Le générateur aléatoire partagé, par exemple, doit pouvoir partir de l’état observé dans l’Amiga. Le rendu se cale sur les états produits par le noyau et peut être présenté à une cadence différente. Le comportement en cas de retard doit découler de mesures sur l’original. [Cadence et ordre](fonctionnement.md#horloge-et-ordre-des-mises-à-jour) · [Scénarios](validation.md#scénarios-de-parité-à-préparer)

## Comparaison des cibles

| Cible | Atouts pour LegoBlast | Coûts et points à mesurer |
| --- | --- | --- |
| **C++ natif**, par exemple avec SDL | Types entiers de largeur explicite, contrôle du budget vidéo et audio, bonne intégration clavier et manettes. Le noyau peut être testé en ligne de commande. | Écrire les débordements intentionnels avec des opérations non signées ou des conversions explicites. Prévoir compilation et distribution par système. Tester le rendu à échelle entière et la latence de plusieurs périphériques. |
| **Python**, par exemple avec Pygame | Lecture rapide des fichiers binaires, instrumentation simple, comparaison de traces et souplesse pour les outils d’analyse. Peut aussi servir à un jeu de bureau selon les mesures. | Les entiers Python grandissent automatiquement. Les masques et conversions sont indispensables aux points sensibles. Mesurer rendu, génération d’événements sonores, cadences de plusieurs joueurs et distribution autonome. |
| **Web en TypeScript**, avec Canvas et Web Audio | Accès par URL, déploiement statique, boucle logique testable hors navigateur. Les tableaux typés conviennent à la lecture des formats et au rendu à pixels indexés. | Les opérations bit à bit utilisent des entiers 32 bits signés. Normaliser là où le code Amiga compare sans signe et utiliser une multiplication 32 bits quand nécessaire. Évaluer audio après interaction, onglets masqués, focus, touches réservées et variations de manettes entre navigateurs. |
| **C++ compilé en WebAssembly** | Permet de partager un noyau avec une version native si les deux distributions sont nécessaires. | Prévoir deux chaînes de livraison. Le navigateur conserve la responsabilité du clavier, des manettes, de l’audio et de la présentation. Regrouper les échanges entre noyau et hôte et mesurer le coût ainsi que les contraintes propres au Web. |

## Recommandation

**C++ est le choix par défaut si la cible reste ouverte et que le jeu doit d’abord tourner sur ordinateur.** Il offre le plus de marge pour le rendu, le mixage et les entrées locales multiples. Il laisse la possibilité d’une version WebAssembly sans décider maintenant de maintenir deux distributions.

**Si l’accès par URL est une exigence ferme et que le navigateur est la seule cible, privilégier TypeScript.** Tester tôt les configurations de clavier à plusieurs, les entrées de manettes et la restitution sonore. Si une distribution native doit également exister, comparer cette voie à un noyau C++ commun avant de dupliquer la logique.

**Utiliser volontiers Python pour l’analyse binaire et les comparaisons de traces**, y compris avec un jeu final dans un autre langage. Pour choisir Python comme cible jouable, mesurer sur une machine représentative la tenue des ticks de 20 ms en charge, le comportement audio et la mise en paquet.

Avant de trancher, utiliser les mêmes critères pour toutes les cibles retenues. Mesurer une séquence d’entrées reproductible, le coût d’une scène chargée avec plusieurs joueurs, le délai entre image et audio, et la fidélité de l’image logique. Une moyenne d’images par seconde ne suffit pas. Un verdict doit indiquer les ticks ratés, les écarts d’état et les limitations concrètes sur le matériel de destination.
