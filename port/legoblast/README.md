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

L’image exportée correspond au terrain initial et couvre la grille de 304 × 240 pixels. Le rendu ignore les enregistrements de téléporteur dont la source tombe hors de cette grille, tout en les conservant dans les données décodées. Les comparaisons image par image avec l’Amiga et le portage des déplacements, des bombes, des flammes, des écrans et du son restent à faire. Cet exécutable de vérification ne lance pas une manche.
