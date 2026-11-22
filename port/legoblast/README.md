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

L’image exportée correspond au terrain initial et couvre la grille de 304 × 240 pixels. Le rendu ignore les enregistrements de téléporteur dont la source tombe hors de cette grille, tout en les conservant dans les données décodées. Les comparaisons image par image avec l’Amiga et le portage des manches, des flammes, des écrans et du son restent à faire. Cet exécutable de vérification exporte le terrain.

## Vérifier l’apparition et les déplacements

Le moteur reçoit les huit entrées logiques de `JoyList` et maintient six emplacements de joueurs. `prepare` reprend les coordonnées et les paramètres de `PrepPos`. Au premier appui sur Feu, `tick` réserve une manette ou un clavier dans l’ordre d’origine, applique les exclusions de clavier, puis déclenche `NotActive` après l’attente imposée par le mode. Le retour `Don't Move` garde les périphériques attribués et arme l’apparition automatique à 100 VBL.

L’animation utilise les mêmes numéros d’images et repasse à l’arrêt en image 33. Le déplacement reprend `TestDir`, `ScreenPos`, `CentreJ`, `TestFleche`, `TestMur` et `CalcVue`. La carte conserve la séparation de `Dim2` et `Dim7` sur des sous-cellules de huit pixels. Les tests distinguent le mouvement autorisé de l’animation, qui récupère `DirJoue` même face à un mur. Les branches de collision avec une bombe lisent le numéro et la vitesse fournis par l’appelant. Les téléporteurs suivent les demi-cases de destination et la séquence disparition, saut puis apparition.

La fenêtre SDL3 facultative dessine le terrain et la banque de sprites attachés d’origine. Extraire `LEGO_SPRITES.DAT` de `amiga/release_aminet/LegoBlast.lha`, puis utiliser le chemin obtenu.

```sh
cmake -S port/legoblast -B /tmp/legoblast-source -DLEGOBLAST_PLAYER_VIEW=ON
cmake --build /tmp/legoblast-source --parallel
ctest --test-dir /tmp/legoblast-source --output-on-failure
/tmp/legoblast-source/legoblast_players amiga/src /chemin/LEGO_SPRITES.DAT amiga/src/binary/Lego_Level021.dat
```

Avec le clavier 1, **Alt droit** fait apparaître le joueur, les **flèches** le déplacent et **Échap** ferme la fenêtre. Le moteur accepte aussi les entrées des autres contrôleurs via son API. Cette fenêtre sert à vérifier la marche et l’apparition. Elle n’exécute ni les manches, ni les maladies, ni les effets sonores, et utilise le mode graphique à sprites attachés. La parité avec des traces d’exécution sur Amiga reste à vérifier.

### Palette matérielle et test Windows

En mode à quatre sprites attachés, `SUITEO` charge les 32 premières entrées de `Lego_Sprites.col` à partir du registre 64. `SetScreenRegisters` sélectionne la banque 5 avec `BPLCON4 = $0055`. Les quatre plans du sprite adressent les registres 80 à 95. L’indice 0 est transparent et les indices 1 à 15 lisent les entrées 17 à 31 du fichier, en RVB 24 bits. La fenêtre est limitée à ce mode de rendu. Le mode à sprites indépendants utilise `MakeSprPal` et sa propre palette.

Le ZIP Windows x64 est produit par le workflow [Joueurs LegoBlast Windows](https://github.com/Elotoha/legoblast/actions/workflows/legoblast-players-windows.yml). Extraire le ZIP entier, puis ouvrir `legoblast_players.exe`. Le dossier `data` inclut le niveau « Test tuyaux » et la banque de sprites. Appuyer sur **Alt droit** puis utiliser les **flèches**. Pour comparer deux joueurs, lancer une nouvelle fenêtre et utiliser **Espace** et **flèche droite** pour l’apparition des claviers 2 et 3. Ne pas appuyer sur Alt droit dans cette fenêtre, car le clavier 1 exclut les deux autres dans le code d’origine.

## Tester les bombes

Après l’apparition, relâcher **Alt droit**, puis appuyer de nouveau pour poser une bombe. Les flèches permettent de s’éloigner. **F5** recharge le niveau, **Échap** ferme la fenêtre. Avec les claviers 2 et 3, leurs touches Feu respectives (**Espace** et **flèche droite**) posent également des bombes après l’apparition.

La pose reprend `PoseBombe` et `NewBomb`. Elle échantillonne le Feu avant le déplacement, aligne la bombe sur une tuile entière et vérifie ses quatre sous-cellules. Le compte à rebours et les images de bombe avancent une VBL sur deux. Les flammes avancent à chaque VBL et déclenchent les autres bombes au prochain passage de `Bombes`. Les destructibles ont un état intermédiaire avant de libérer la case. L’aperçu compose les bombes, les blocs en destruction et les flammes à partir des plans et des palettes Amiga.

Les flammes prennent aussi les coudes et les embranchements de tuyaux. Le code suit les bits d’ouverture de `TestToyoX` et `TestToyoY`. Une sortie dans l’axe conserve la propagation en ligne droite. Lorsque cette sortie est fermée, chaque branche latérale ouverte devient une flamme indépendante et perd une unité d’énergie. Les tests couvrent le passage dans les deux sens, le refus d’une entrée fermée, les coudes, l’embranchement, la priorité à la sortie droite et la réaction en chaîne après un coude.

Les collisions de poussée de base et l’animation d’élimination par les flammes sont incluses. Le son, le déroulement des manches et la transmission des maladies entre joueurs restent à traduire. La fenêtre utilise une graine fixe et n’a pas encore été comparée à une trace Amiga.

## Bonus et déplacements spéciaux des bombes

Les bombes poussées testent les deux sous-cellules de l’avant. Elles se téléportent lorsqu’elles s’alignent sur une entrée et que les quatre sous-cellules de sortie sont libres. Elles gardent leur vitesse à la sortie. Le bonus de rebond s’applique aux nouvelles bombes pendant sa durée. Une bombe qui a déjà avancé inverse sa vitesse lorsqu’elle heurte un bloc.

Les flammes font jouer l’animation de destruction d’un bonus visible. La destruction d’un mur révèle son bonus caché, s’il en contenait un. Les effets à la prise sont branchés sur les 23 identifiants de la table Amiga. Ils comprennent les changements de capacité, de portée, de vitesse et de mèche, les commandes inversées, le gel, l’horloge, le rebond, l’invincibilité et l’ambulance. Les temporisations reprennent l’ordre de `TestMalad`. Les effets sonores, la barre d’état et la transmission par contact restent à intégrer. En cas de choc simultané contre deux bombes différentes, le C++ traite les deux cibles par identifiant. Cette situation et le reste du comportement n’ont pas encore été comparés à des traces Amiga.

Pour lancer le niveau original **Bump Alert** depuis le ZIP Windows, ouvrir un terminal dans le dossier extrait et exécuter `legoblast_players.exe 314`. Ce niveau contient des téléporteurs, autorise la poussée et peut révéler le bonus de rebond sous les murs.
