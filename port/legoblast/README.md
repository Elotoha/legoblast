# Portage C++ depuis le code 68k de LegoBlast

Ce dossier est le début de la traduction des routines Amiga. Il lit les fichiers du jeu directement dans `amiga/src`. Les noms de routines et les références ci-dessous donnent le point de départ assembleur de chaque composant.

| Partie traduite | Référence |
| --- | --- |
| Lecture big-endian de l’en-tête, des départs, de la carte et de la liste des téléporteurs | [`Level_*`](../../amiga/src/lego17.asm#L617) |
| Générateur à deux états, valeurs de seuil et génération de l’arène 999 | [`Rnd_Engine`, `Rnd_Bool` et `Rnd_Init`](../../amiga/src/rnd.i#L9) · [`DynaInit`](../../amiga/src/Levels.i#L700) |
| Table de fréquences des bonus, tirages pour les téléporteurs et bonus sous les blocs | [`MakeRndCorresp`](../../amiga/src/Levels.i#L612) · [`Teleporteurs`](../../amiga/src/Levels.i#L646) · [Bonus cachés](../../amiga/src/Levels.i#L275) |
| Composition du terrain avec les indices et palettes d’origine, à partir de `Lego_Blocs.dat` | [`InitLevel`](../../amiga/src/Levels.i#L219) · [`TraceBlocWithFont`](../../amiga/src/Grafx.i#L373) · [`TraceBlocWithBloc`](../../amiga/src/Grafx.i#L672) · [Palettes](../../amiga/src/lego17.asm#L3026) |

## Vérifier la traduction

```sh
cmake -S port/legoblast -B /tmp/legoblast-source
cmake --build /tmp/legoblast-source --parallel
ctest --test-dir /tmp/legoblast-source --output-on-failure
/tmp/legoblast-source/legoblast_levels amiga/src/binary/Lego_Level021.dat amiga/src /tmp/test-tuyaux.ppm
```

Le test charge et dessine les 130 fichiers de niveau suivis dans le dépôt. Il contrôle notamment les sorties du générateur, la carte et l’état aléatoire après `DynaInit`, et l’ordre des tirages à l’initialisation. [Rendu des tuiles originales du niveau 021](test-tuyaux.png)

L’image exportée correspond au terrain initial et couvre la grille de 304 × 240 pixels. Le rendu ignore les enregistrements de téléporteur dont la source tombe hors de cette grille, tout en les conservant dans les données décodées. Cet exécutable exporte le terrain pour les comparaisons image par image avec l’Amiga.

## Vérifier l’apparition et les déplacements

Le moteur reçoit les huit entrées logiques de `JoyList` et maintient six emplacements de joueurs. `prepare` reprend les coordonnées et les paramètres de `PrepPos`. Au premier appui sur Feu, `tick` réserve une manette ou un clavier dans l’ordre d’origine, applique les exclusions de clavier, puis déclenche `NotActive` après l’attente imposée par le mode. Le retour `Don't Move` garde les périphériques attribués et arme l’apparition automatique à 100 VBL.

L’animation utilise les mêmes numéros d’images et repasse à l’arrêt en image 33. Le déplacement reprend `TestDir`, `ScreenPos`, `CentreJ`, `TestFleche`, `TestMur` et `CalcVue`. La carte conserve la séparation de `Dim2` et `Dim7` sur des sous-cellules de huit pixels. Les tests distinguent le mouvement autorisé de l’animation, qui récupère `DirJoue` même face à un mur. Les branches de collision avec une bombe lisent le numéro et la vitesse fournis par l’appelant. Les téléporteurs suivent les demi-cases de destination et la séquence disparition, saut puis apparition.

La fenêtre utilise SDL3 et libsndfile. Extraire `amiga/release_aminet/LegoBlast.lha` et passer le chemin de `binary/LEGO_SPRITES.DAT` dans le dossier extrait. Les quatre barres de joueurs, la barre en bois et leurs banques sont lues à côté de ce fichier.

```sh
cmake -S port/legoblast -B /tmp/legoblast-source -DLEGOBLAST_PLAYER_VIEW=ON
cmake --build /tmp/legoblast-source --parallel
ctest --test-dir /tmp/legoblast-source --output-on-failure
/tmp/legoblast-source/legoblast_players amiga/src /chemin/LEGO_SPRITES.DAT amiga/src/binary/Lego_Level001.dat
```

Avec le clavier simple, **Alt droit** ou **Entrée** fait apparaître le joueur et sert de touche Feu. Les **flèches** le déplacent.

### Palette matérielle et test Windows

En mode à quatre sprites attachés, `SUITEO` charge les 32 premières entrées de `Lego_Sprites.col` à partir du registre 64. `SetScreenRegisters` sélectionne la banque 5 avec `BPLCON4 = $0055`. Les quatre plans du sprite adressent les registres 80 à 95. L’indice 0 est transparent et les indices 1 à 15 lisent les entrées 17 à 31 du fichier, en RVB 24 bits. À partir de cinq commandes attribuées, le rendu utilise les sprites indépendants et les quatre entrées par joueur de `Mec8_normal.col`. La banque indépendante fournie compte 199 images par joueur. Les animations de résultat à partir de l’image 190 existent dans la banque attachée récente. Le rendu indépendant y revient à la pose de repos.

Le ZIP Windows x64 est produit par le workflow [Joueurs LegoBlast Windows](https://github.com/Elotoha/legoblast/actions/workflows/legoblast-players-windows.yml). Extraire le ZIP entier, puis ouvrir `legoblast_players.exe`. Le menu s'ouvre au démarrage. Sélectionner **Start** avec **Entrée** pour jouer le niveau 001, ou **Options** pour configurer l'arène et le type de match. La commande `legoblast_players.exe 021` ouvre « Test tuyaux ».

### Commandes en partie

| Commande | Action |
| --- | --- |
| **F1**, **F2** | Arène précédente ou suivante. En aléatoire, F2 effectue un tirage et F1 revient à l’arène précédente. |
| **F3** à **F6** | Pistes de jeu 1 à 4. F5 sélectionne la piste 3. |
| **F7** à **F9** | Pistes 5 à 7. Les modules correspondants sont absents des ressources disponibles, ce qui coupe la musique et affiche un message. |
| **F10** | Coupe la musique. |
| **Début** ou **Aide** | Rejoue l’arène. En Dynablaster, génère un nouveau labyrinthe. |
| **P**, **Échap** | Pause ou retour au menu. En lancement direct, Échap ferme le jeu. |

Les changements d’arène conservent les victoires et les commandes attribuées. En mode séquentiel, les raccourcis avancent ou reculent d’une arène activée.

Pour jouer à deux au clavier, appuyer d’abord sur **Espace**, puis sur **flèche droite**. On peut aussi choisir un clavier B dans les options pour autoriser les deux touches Feu dès le début. Le clavier 2 se déplace avec **Z** en AZERTY (**W** en QWERTY), **R**, **3** ou **4** vers le haut et **E** vers le bas. Le clavier 3 utilise **7**, **9**, **5** vers le haut et **8** vers le bas au pavé numérique. Le choix du clavier simple exclut les deux claviers partagés pour le match.

## Tester les bombes

Après l’apparition, relâcher Feu, puis appuyer de nouveau pour poser une bombe. La même commande s’applique aux claviers et aux manettes.

La pose reprend `PoseBombe` et `NewBomb`. Elle échantillonne le Feu avant le déplacement, aligne la bombe sur une tuile entière et vérifie ses quatre sous-cellules. Le compte à rebours et les images de bombe avancent une VBL sur deux. Les flammes avancent à chaque VBL et déclenchent les autres bombes au prochain passage de `Bombes`. Les destructibles ont un état intermédiaire avant de libérer la case. L’aperçu compose les bombes, les blocs en destruction et les flammes à partir des plans et des palettes Amiga.

Les flammes prennent aussi les coudes et les embranchements de tuyaux. Le code suit les bits d’ouverture de `TestToyoX` et `TestToyoY`. Une sortie dans l’axe conserve la propagation en ligne droite. Lorsque cette sortie est fermée, chaque branche latérale ouverte devient une flamme indépendante et perd une unité d’énergie. Les tests couvrent le passage dans les deux sens, le refus d’une entrée fermée, les coudes, l’embranchement, la priorité à la sortie droite et la réaction en chaîne après un coude.

Les collisions de poussée de base et l’animation d’élimination par les flammes sont incluses. Les joueurs actifs sur la même case de 16 pixels échangent leurs maladies selon `ColJoue` et `FileMal`.

## Bonus et déplacements spéciaux des bombes

Les bombes poussées testent les deux sous-cellules de l’avant. Elles se téléportent lorsqu’elles s’alignent sur une entrée et que les quatre sous-cellules de sortie sont libres. Elles gardent leur vitesse à la sortie. Le bonus de rebond s’applique aux nouvelles bombes pendant sa durée. Une bombe qui a déjà avancé inverse sa vitesse lorsqu’elle heurte un bloc.

Les flammes font jouer l’animation de destruction d’un bonus visible. La destruction d’un mur révèle son bonus caché, s’il en contenait un. Les effets à la prise sont branchés sur les 23 identifiants de la table Amiga. Ils comprennent les changements de capacité, de portée, de vitesse et de mèche, les commandes inversées, le gel, l’horloge, le rebond, l’invincibilité et l’ambulance. Les temporisations reprennent l’ordre de `TestMalad`. En cas de choc simultané contre deux bombes différentes, le C++ traite les deux cibles par identifiant. Cette situation et le reste du comportement n’ont pas encore été comparés à des traces Amiga.

Pour lancer le niveau original **Bump Alert** depuis le ZIP Windows, ouvrir un terminal dans le dossier extrait et exécuter `legoblast_players.exe 314`. Ce niveau contient des téléporteurs, autorise la poussée et peut révéler le bonus de rebond sous les murs.


## Jouer un match complet en cinq victoires

Le premier joueur à apparaître lance le compte à rebours. La première élimination ou l'alerte à dix secondes ferme les inscriptions. Le terrain se referme en spirale lorsque le délai d'alerte expire. Quand le temps total s'écoule, les bombes actives sont déclenchées. La manche attend la fin des bombes, des flammes et des animations avant d'afficher le résultat. Une victoire rapporte un point lorsqu'au moins deux joueurs ont participé.

L’encart « Ready?! » apparaît après 15 VBL et présente le niveau, les temps et les bonus de départ avec les polices et les graphismes Amiga. Feu passe à la manche suivante après le résultat. Le joueur conserve le périphérique qui lui a été attribué.

Le moteur avance par pas de 20 ms. `legoblast_session_checks` vérifie cinq victoires consécutives, le match nul, la conservation des commandes, la pause, le départ différé du chronomètre, le premier bloc de la spirale et la résolution du temps écoulé avec une bombe active. Le workflow Windows lance également l'exécutable emballé avec `--smoke` et vérifie le menu, cinq victoires au niveau 001 et l'ouverture du podium.

La barre de joueurs utilise les portraits, chiffres et jauges Amiga. Les joueurs survivants reprennent les séquences de victoire et d'égalité de `ChooseAnim` et `AnimEnd`. Après la cinquième victoire, Feu ouvre le podium avec le fond, la palette et les animations de l'Amiga. Relâcher puis appuyer de nouveau pour afficher le récapitulatif. Le tableau de statistiques affiche les victoires et les bombes posées. Feu revient au menu ou démarre un nouveau match en lancement direct.


## Essayer les autres modes

- `legoblast_players.exe 314 --teams` joue en équipes. Les emplacements alternent entre les deux équipes.
- `legoblast_players.exe --free` ouvre le jeu libre et permet de rejoindre sans attendre les 40 VBL du match en cinq victoires.
- `legoblast_players.exe --survivor` rejoue l'arène après une élimination si au moins deux joueurs survivent. Les survivants retrouvent leur commande.
- `legoblast_players.exe --sequential` joue à partir du niveau choisi, dans l'ordre des fichiers d'arène.
- `legoblast_players.exe --random` ouvre d'abord le niveau choisi, puis tire les arènes avec `Rnd_Engine`.
- `legoblast_players.exe --dyna` génère l'arène à partir de `Lego_Level999.dat` et garde l'état du générateur entre les manches.

Les quatre manettes SDL peuvent rejoindre avec le bouton du bas et se déplacer au stick gauche ou à la croix. Les règles de redémarrage « Don't Move » s'appliquent après une mort rapide. Le compteur de victoires est conservé et les joueurs reviennent automatiquement avec leur commande. Les bumpers surveillent les cases devant eux, animent leur piston et poussent les joueurs et les bombes.

Le port utilise une graine déterministe. Les options en ligne de commande chargent les niveaux présents sur disque et excluent le dernier monde en jeu individuel. Dans **Options**, choisir **Arena** pour activer ou désactiver un niveau avec **Entrée** sur son nom. **Go** revient au menu principal.


## Ressources sonores

Le paquet contient les 20 effets de `samples.def` au format WAV PCM 16 bits et les cinq modules P61 au format FLAC. La conversion des effets conserve les mots PCM envoyés à Paula par `ChargeOneSon` et utilise la période du sample pour calculer sa fréquence PAL. Les pistes de jeu sont rendues en trois canaux Tracker, avec un canal réservé aux effets pendant la partie. Le FLAC conserve sans perte le rendu de xmp en stéréo à 48 kHz. La comparaison du mix et des points de boucle avec P61 sur Amiga reste à effectuer.

La musique 1 démarre par défaut. Lancer `legoblast_players.exe --music=2` pour choisir la piste 2 ou `legoblast_players.exe --music=0` pour jouer avec les effets seuls. Le menu joue `Mod_Menu.flac`. Pour régénérer les fichiers avec xmp 4.2, libxmp 4.6 et FFmpeg disponibles dans le PATH, exécuter depuis la racine du dépôt

```sh
python3 port/legoblast/export_audio.py amiga/src port/legoblast/audio
```


## Écarts encore ouverts

- Le joueur Micro et son routage sont à porter depuis `Micro.i`.
- Les écrans d'introduction, de crédits et de bonus, la sauvegarde des préférences et le tableau complet de statistiques sont à porter.
- Les traces VBL et les comparaisons d'images et de mixage avec les deux binaires Amiga restent à établir. Le menu démarre au niveau 001 et la résolution est agrandie en mise à l'échelle entière.
