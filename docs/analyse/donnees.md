# Données et ressources Amiga

## Corpus de niveaux

L’inventaire compare `amiga/src/binary/` et une extraction neuve de `amiga/release_aminet/LegoBlast.lha`. Les deux contiennent 130 fichiers de niveau aux contenus identiques, comparés par SHA-256 en ignorant la casse des noms. Les 129 noms à trois chiffres et `Lego_Level0-1.dat` constituent ce total. Le code impose une sélection plus étroite que le contenu de ces répertoires.

| Ensemble | Comptage | Accès établi dans le source |
| --- | ---: | --- |
| Mondes 0 à 5, suffixes 01 à 30 | 113 | `LoadLevels` essaie les 180 noms de cette plage. Les fichiers présents sont répartis par monde en 21, 20, 20, 20, 20 et 12. Le chargement et l’éligibilité dans chaque mode sont deux étapes distinctes. |
| Niveau 999 | 1 | Chargé séparément dans `DynaBlaster`. `DynaInit` réécrit les cases éligibles et dégage les abords des départs. |
| Fichiers 000, 700 à 714 et 0-1 | 16 | Hors de la plage générée par `LoadLevels`. Le chemin `lego_level000.dat` est le tampon utilisé pour construire les noms, avant remplacement des chiffres. L’accès éventuel par un autre chemin reste à établir. |

Le README annonce six mondes de vingt niveaux. L’inventaire des fichiers et le parcours du chargeur constituent deux informations plus précises pour identifier les données à vérifier. [README](../../README.md) · [Plage de chargement](../../amiga/src/Levels.i#L1534) · [Ressource 999](../../amiga/src/lego17.asm#L3115) · [Génération](../../amiga/src/Levels.i#L700)

## Format des niveaux

Les offsets ci-dessous sont décimaux et partent du premier octet. Le format contient des champs de 16 ou 32 bits en ordre big-endian. Interpréter le signe selon l’instruction qui lit le champ, notamment pour les sentinelles et les types de case. [Déclaration `RS`](../../amiga/src/lego17.asm#L617) · [Lecture du nom](../../amiga/src/Levels.i#L913) · [Lecture des téléporteurs](../../amiga/src/Levels.i#L646)

| Offset | Taille (octets) | Champ |
| ---: | ---: | --- |
| 0 | 4 | Offset du nom relatif au début du niveau. Le nom est terminé par NUL. |
| 4 | 8 | Deux compteurs de 32 bits, alerte ou remplissage puis fin de manche, en VBL. |
| 12 | 10 | Cinq mots `FillXMin`, `FillYMin`, `FillXMax`, `FillYMax`, `FillNb`. |
| 22 | 8 | Vitesse des joueurs, capacité de bombes, longueur des flammes, réglage de poussée. |
| 30 | 32 | Huit paires X/Y de départ, en mots de 16 bits. |
| 62 | 4 | Indices de palette et de flammes. |
| 66 | 60 | Table de 30 mots d’indices graphiques des blocs. |
| 126 | 4 | Temporisation des bombes et réglage de tir automatique. |
| 130 | 36 | Réserve déclarée `Level_BordelVide`. |
| 166 | 60 | Table `Level_BonusOk` de 30 mots. L’interprétation de chaque poids reste à relever. |
| 226 | 285 | Grille, de 19 colonnes par 15 lignes, un octet par tuile. |
| 511 | 1 | Champ `Level_Nothing`, avant la liste de téléporteurs. |
| 512 | Variable | Entrées de quatre mots X/Y source et X/Y destination. Un X source négatif termine la liste. |

Deux exemples relus dans les octets du dépôt.

| Fichier | Taille | Compteurs bruts | Fin de liste | Offset du nom |
| --- | ---: | --- | --- | ---: |
| [Lego_Level001.dat](../../amiga/src/binary/Lego_Level001.dat) | 521 | 1 000 et 15 000 | `FFFF` à 512, aucune entrée | 514 |
| [Lego_Level002.dat](../../amiga/src/binary/Lego_Level002.dat) | 558 | 9 000 et 15 000 | `FFFF` à 544, quatre entrées | 546 |

Sur les 130 fichiers, le parcours par blocs de huit octets à partir de 512 trouve un X source `FFFF`. Le format doit néanmoins suivre le test < 0 du code. Les compteurs ci-dessus précèdent l’ajustement réalisé à l’initialisation de la manche. [Ajustement](../../amiga/src/Levels.i#L191)

## Passage de la carte au terrain en mémoire

`InitLevel` lit les tuiles par lignes et écrit des groupes de 2 × 2 sous-cellules. Une couche ordinaire possède un pas de 64 sous-cellules et des entrées de 4 octets. `Dim4` possède des entrées de 16 octets pour les masques et les compteurs de flamme. Le terrain lu par les collisions associe sept couches à la position. Les noms ci-dessous décrivent les usages lus dans le source.

| Couche | Contenu |
| --- | --- |
| `Dim1`, `Dim2` | Indice de bombe et état visible ou collision de la case |
| `Dim3`, `Dim4` | Destination des passages et état des flammes |
| `Dim5`, `Dim6`, `Dim7` | Information de bonus, indice de bumper et dalles spéciales |

Les codes de carte comprennent les familles de murs, tuiles spéciales, bumpers et tuyaux. Au chargement, le bit 6 identifie des codes de bonus traités à part. Le type visible produit et la donnée secondaire doivent être contrôlés ensemble, notamment pour distinguer une tuile avec un bonus d’un bonus en cours de destruction. [Types et constantes](../../amiga/src/lego17.asm#L283) · [Conversion de la carte](../../amiga/src/Levels.i#L219) · [Allocations des couches](../../amiga/src/lego17.asm#L833) · [Mémo des couches](../../amiga/src/lego17.asm#L3491)

## Ressources, préférences et dépendances

| Famille | Ce que le code établit | À vérifier dans une phase suivante |
| --- | --- | --- |
| Affichage | Données planaires, palettes, listes Copper, sprites et blitter Amiga. Plusieurs palettes et listes Copper sont incluses à l’assemblage. D’autres ressources sont chargées par nom. | Inventorier les fichiers réellement lus par écran. Relever composition, transparence, priorité des sprites, changements de palette, synchronisation vidéo et différence de résolution entre jeu et barre. |
| Musique et sons | `MultiP6.asm` fournit le lecteur P61 appelé au VBL. Les modules sont référencés dans `mods/`. Les bruitages passent par `PlaySon` avec priorités et boucles, et `samples.def` entre dans leur chargement. | Identifier les modules et les bruitages présents pour chaque distribution, le partage des canaux et le comportement en mémoire limitée. Comparer mixage et instant de déclenchement. |
| Images compressées | `decrunch.i` est inclus et décrit un décodeur. Des appels de décompression sont commentés dans `ChargeCRP` malgré son nom. | Vérifier les octets et les consommateurs de chaque ressource. Une extension seule ne décide pas si une décompression est requise. |
| Préférences | `LegoBlast.Prefs` contient un en-tête `LEGO`, des volumes, des options et une table d’activation des niveaux. `PrefsR` vérifie la taille, puis l’en-tête. | Relever l’encodage des valeurs et l’interprétation des références de menus avant d’établir une compatibilité de lecture ou d’écriture. |

[Registres Amiga](../../amiga/src/Big.i#L28) · [Palettes et listes Copper](../../amiga/src/lego17.asm#L3177) · [Musique au VBL](../../amiga/src/Int_VBL.i#L52) · [Chargement des échantillons](../../amiga/src/LoadFiles.i#L7) · [Routine `ChargeCRP`](../../amiga/src/menu.i#L140) · [Lecture des préférences](../../amiga/src/lego17.asm#L691)

La casse des chemins est à traiter dans l’inventaire. Le source fait par exemple référence à `Binary/MenuA.cop` et le répertoire suivi s’appelle `binary`, avec plusieurs variantes de majuscules dans les noms. Le dépôt contient aussi des ressources d’édition ou d’archive, notamment `Amos/`, `OBSOLETE/` et `SoundWork/`. L’usage d’une ressource se déduit du chargement ou de l’inclusion, et la présence dans Git permet de vérifier sa provenance. Le README mentionne « Freeware », tandis que l’en-tête source mentionne « GiftWare ». Les droits de redistribution d’un port et de ses ressources doivent être établis pour le canal choisi. [README](../../README.md) · [En-tête de l’assembleur](../../amiga/src/lego17.asm#L1) · [Inclusions](../../amiga/src/lego17.asm#L3177)
