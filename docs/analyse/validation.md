# Validation de la fidélité

## Références et vérifications de phase 1

| Référence | Identification | Résultat |
| --- | --- | --- |
| Source 68k | [`amiga/src/lego17.asm`](../../amiga/src/lego17.asm) et fichiers inclus au commit `5b0725ad3b92dd4d45a099442c48972b2f14d966` | Référence pour l’analyse des règles. Les passages commentés et les archives d’édition sont signalés lorsqu’ils peuvent induire une confusion sur le code exécuté. |
| Binaire du dépôt | [`amiga/src/lego17`](../../amiga/src/lego17), SHA-256 `07d5ebdd869cf1583b4184f8b5d35154a535dfa25d0581e11862b6f1b3d1df4f` | Menu principal et écran des crédits observés avec les données extraites de l’archive Aminet. |
| Distribution Aminet | [`amiga/release_aminet/LegoBlast.lha`](../../amiga/release_aminet/LegoBlast.lha), exécutable extrait SHA-256 `b421343b91857f2762465a7172aa86d845bb0963342fc751fd5c4451f9f9aaee` | Menu principal, navigation au clavier et écran de configuration arène/joueurs observés après extraction neuve. |
| Données de niveaux | Les 130 fichiers du répertoire source et les 130 de l’archive, comparés par SHA-256 et nom insensible à la casse | Correspondance complète. Les 130 listes de téléporteurs contiennent un terminateur négatif et deux en-têtes sont détaillés dans [Données et ressources](donnees.md#format-des-niveaux). |

Les deux lancements utilisent FS-UAE 3.1.66, Amiga 1200, ROM AROS intégrée, un dossier hôte monté comme disque Amiga et un `S/Startup-Sequence` qui appelle `Lego17`. Pour le binaire du dépôt, seul l’exécutable a été remplacé dans une copie séparée du dossier extrait. Le contrôle s’est arrêté aux écrans indiqués. Une manche jouée, les statistiques de fin, le son et les traces de simulation restent à vérifier.

L’assemblage avec `vasm` atteint les inclusions du NDK AmigaOS et s’arrête sur `exec/types.i`. L’origine exacte de chacun des exécutables doit être confirmée avant de le prendre comme référence du source. Les empreintes établissent une différence binaire. Elles ne permettent pas d’attribuer une divergence de gameplay. Pour une réécriture de cette révision, retenir si possible un exécutable reconstruit avec sa configuration et ses dépendances documentées. Utiliser séparément les deux exécutables existants comme témoins de comportements observés. Si l’assembleur et un témoin diffèrent, noter la divergence avec l’entrée utilisée, le résultat, la révision et l’empreinte du témoin.

## Protocole de comparaison proposé

1. Figer le binaire testé, le jeu de données, les préférences initiales, le modèle Amiga, la ROM, le mode vidéo et les contrôles. Documenter les réglages choisis et commencer depuis un état reproductible. Pour un scénario aléatoire, capturer les deux mots longs d’état du générateur ou repartir d’un instantané qui les contient.
2. Enregistrer les commandes avec leur numéro de VBL ou leur phase lorsque l’ordre au sein d’une image compte. Consigner appui, relâchement et maintien. Rejouer le scénario sur le même témoin avant la comparaison avec une autre cible.
3. Relever l’état aux frontières utiles. Consigner au minimum le niveau, la phase de manche, les coordonnées et états des joueurs, les minuteries de bombes, les cellules et phases de flamme, le chrono, le score et l’état aléatoire. Donner aux objets des identifiants stables. Les adresses mémoire et le nombre d’images présentées par la machine hôte ne constituent pas des écarts d’état du jeu.
4. Comparer chronologiquement. Pour le premier écart, isoler l’entrée qui le provoque, la phase, le sous-système, l’attendu et l’observé. Pour le rendu, comparer des images logiques sur des transitions connues. Pour l’audio, comparer d’abord les événements, le déclenchement et l’affectation des canaux, puis le rendu sonore en contrôlant la configuration du mixage.

## Vérifications du port C++ au jalon du match complet

Le scénario automatisé joue cinq manches sur l’arène 001 avec deux joueurs, vérifie la conservation des commandes et du score, puis ouvre le podium. Il a passé les tests sous Linux et avec l’exécutable emballé par GitHub Actions sous Windows x64. Les tests unitaires couvrent aussi les égalités, la spirale de fin de niveau, le chronomètre, l’élimination des absents, les reprises et la transmission des maladies. [Compilation Windows](https://github.com/Elotoha/legoblast/actions/runs/45077967393)

Les deux binaires Amiga ont été relancés séparément sous FS-UAE avec les données et préférences extraites de l’archive. La distribution Aminet a affiché le menu d’options. Le binaire du dépôt a atteint l’écran « Ready?! » de Dynablaster. Le port affiche désormais cet encart à partir des banques graphiques et des polices Amiga. La comparaison des transitions de match et des états à chaque VBL reste à effectuer.

Un nouvel essai avec le NDK AmigaOS 3.2 a franchi l’inclusion `exec/types.i`. L’assemblage avec `vasm` et sa compatibilité Devpac s’arrête encore sur des macros telles que `AgaOnly`, `CpuMini` et `LTest`, ainsi que sur la casse d’un chemin de palette dans l’environnement Linux. Aucun exécutable de référence n’a été reconstruit à cette étape. [Source du jeu](../../amiga/src/lego17.asm)

## Scénarios de parité à préparer

Les scénarios suivants sont proposés pour la phase suivante. Chacun doit produire des résultats de référence avec les exécutables identifiés ci-dessus si le chemin concerné est accessible.

| Scénario | Points à observer | Programme d’origine |
| --- | --- | --- |
| Chargement de 001 et 002 | Nom, compteurs, grille, destination des passages et états des tuiles après chargement. | [`InitLevel`](../../amiga/src/Levels.i#L152) |
| Génération du mode Dynablaster | Plan de départ, cases préservées, dégagement autour des joueurs et état aléatoire avant/après. | [`DynaInit`](../../amiga/src/Levels.i#L700) |
| Marche, virage et deux entrées au même tick | Position pixel et sous-cellule, collision, centrage, animation et ordre entre joueurs. | [`GestionSprites`](../../amiga/src/Sprites.i#L9) · [`TestMur`](../../amiga/src/Sprites.i#L1916) |
| Bombe au repos, poussée ou bloquée | Première et dernière valeur du compteur, case verrouillée, position au moment de l’explosion et effet d’un appui maintenu. | [`Bombes`](../../amiga/src/Bombes.i#L2) · [`PoseBombe`](../../amiga/src/Sprites.i#L2924) |
| Explosion en chaîne près d’un mur | Tick de remise à zéro, tick d’explosion effective, état du mur, propagation et éventuel bonus. | [`Flammes`](../../amiga/src/Flammes.i#L761) · [`NewMur`](../../amiga/src/Murs.i#L8) |
| Tuyaux, dalles, bumpers et téléporteurs | Côté d’entrée, direction de sortie, cas bloqué, différences entre une flamme, un joueur et une bombe. | [Tuyaux](../../amiga/src/Flammes.i#L798) · [Bumpers](../../amiga/src/Bumper.i#L11) · [Téléporteurs](../../amiga/src/Levels.i#L646) |
| Bonus, maladies et Micro | Durées, transmission, empilement et influence sur le mouvement ou la pose de bombe. Pour Micro, activation, objectif et danger retenus. | [`TestMalad`](../../amiga/src/Sprites.i#L2191) · [`Micro`](../../amiga/src/Micro.i#L58) |
| Alarme et fin de manche | Horloge, murs posés en spirale, classement, égalités, équipes, joueurs absents et transition vers le podium ou le niveau suivant. | [Chronomètre](../../amiga/src/Int_VBL.i#L121) · [`TestLevelEnd`](../../amiga/src/Levels.i#L757) |
| Menus, pause, préférences et son | Navigation, sélection des niveaux et commandes, répétition clavier, pause/reprise, effets de palette et ordre d’émission audio. | [Menu](../../amiga/src/menu.i#L28) · [Pause](../../amiga/src/Levels.i#L1457) · [Préférences](../../amiga/src/lego17.asm#L691) · [Musique au VBL](../../amiga/src/Int_VBL.i#L52) |

La phase suivante peut commencer par un niveau fixe et une chaîne de deux bombes. Ils produisent ensemble un premier contrôle du décodeur binaire, de la cadence et de l’ordre des mutations. Un seul scénario réussi ne couvre pas les différences de versions, le rendu ni les règles de victoire.
