# Ressources modernes et aperçu C++/SDL3

Ce socle charge et vérifie un paquet de ressources puis présente des images et du son dans un aperçu SDL3. Le moteur de jeu Amiga, ses données de collision et les comparaisons de manches restent au stade de l’[analyse](../docs/analyse/README.md).

## Compiler et tester

Prérequis pour le C++ et les tests intégrés. CMake 3.24+, un compilateur C++20, SDL3 3.2+, libpng, libsndfile, nlohmann-json, Python 3, Pillow, NumPy et FFmpeg. Sur Debian 13, les bibliothèques de développement sont disponibles sous les noms `libsdl3-dev`, `libpng-dev`, `libsndfile1-dev` et `nlohmann-json3-dev`.

Depuis la racine du dépôt, avec les dépendances installées.

```sh
cmake -S port -B /tmp/legoblast-build
cmake --build /tmp/legoblast-build --parallel
ctest --test-dir /tmp/legoblast-build --output-on-failure
```

Le test construit son propre paquet temporaire et exécute l’aperçu avec les pilotes SDL sans écran et sans sortie audio. Il vérifie aussi les pixels sur une surface logicielle et les échantillons du mixeur.

## Préparer et afficher un paquet

Placer une recette JSON à côté de ressources dont tu disposes. Les chemins des fichiers source sont relatifs à la recette. La commande prépare un répertoire neuf et vérifie chaque ressource avec le chargeur C++ avant de le publier. Le chargeur utilise `manifest.json` et les fichiers modernes du paquet.

```sh
python3 port/tools/convert.py /chemin/recipe.json /tmp/legoblast-assets \
  --validator /tmp/legoblast-build/asset_preview
/tmp/legoblast-build/asset_preview /tmp/legoblast-assets
```

Dans l’aperçu, la flèche droite change d’image, Espace joue le bruitage suivant et Échap ferme la fenêtre. La première musique démarre si le paquet en contient une. `--check` vérifie un paquet existant sans ouvrir de fenêtre. `--frames N` permet d’arrêter l’aperçu après N images présentées.

Exemple de recette. Les noms correspondent à des fichiers à fournir et les valeurs sont illustratives.

```json
{
  "images": {
    "sprite": {
      "logical_size": [16, 16],
      "pixel_size": [32, 16],
      "anchor": [8, 15],
      "grid": [2, 1],
      "frame_ticks": 4,
      "cycles": [{"first": 1, "last": 3, "ticks": 2, "direction": 1}],
      "sources": {
        "1": {"path": "sprite.iff", "format": "ilbm"},
        "4": {"path": "sprite-4x.png", "format": "png", "mask": "sprite-4x-mask.png"}
      }
    }
  },
  "sounds": {
    "cue": {
      "priority": 2,
      "volume": 0.6,
      "source": {"path": "cue.8svx", "format": "8svx"}
    }
  },
  "music": {
    "theme": {
      "loop": [24000, 288000],
      "volume": 0.4,
      "stems": [
        {"path": "theme-1.wav", "format": "wav"},
        {"path": "theme-2.wav", "format": "wav"}
      ]
    }
  }
}
```

### Images

- `logical_size` et `anchor` s’appliquent à une image d’animation, en coordonnées logiques. `pixel_size` est la taille pixel du PNG ou de la planche à l’échelle de base. Une barre de 640 pixels peut ainsi occuper 320 unités logiques. `grid` donne les colonnes et lignes de la planche, dans l’ordre de lecture. `frame_ticks` est exprimé en pas de 20 ms.
- Le convertisseur accepte les PNG fixes, les IFF **ILBM** fixes en couleurs indexées avec ou sans ByteRun1, et les RAW planaires décrits explicitement. Pour `planar`, fournir `width`, `height`, `planes`, `layout` (`plane-major` ou `row-interleaved`) et `palette` (couleurs RVB). `stride` fixe le nombre d’octets par rangée de plan. Sa valeur par défaut suit l’alignement ILBM sur 16 bits. `transparent_index` est facultatif.
- Utiliser des sources indexées à tous les facteurs d’une image cyclée. Les indices définis par `cycles` sont inclusifs. Une direction positive avance les couleurs vers les indices croissants. Un masque séparé conserve l’opacité par pixel pendant le cycle. Le convertisseur exporte le plan de masque ILBM ou accepte un PNG gris externe à la résolution exacte de la variante.
- Le facteur `1` est requis. Les facteurs `2`, `3` et `4` sont facultatifs. L’aperçu choisit par image le plus grand facteur compatible, dessine sur la vraie surface de sortie avec le filtrage au plus proche et centre l’espace logique de 320 × 256. La géométrie est commune à tous les facteurs.

Les formats IFF ANIM, HAM et Extra Half-Brite nécessitent un export préalable. Pour une animation exportée, fournir une planche PNG et sa grille.

### Générer des variantes HD

Ajouter un objet `upscale` à l’entrée de l’image dans la recette. Exemple pour un sprite ou un élément d’interface à pixels nets.

```json
"upscale": {"method": "pixel-art", "factors": [2, 3, 4]}
```

- **`pixel-art`** utilise Scale2x, Scale3x ou deux passages Scale2x pour le facteur 4. Il adoucit les escaliers visibles dans les diagonales en réutilisant les pixels de bord. Les indices de palette et l’opacité indépendante sont transportés ensemble. Ce mode convient aux sprites, aux textes et aux éléments à palette animée.
- **`lanczos`** filtre les couleurs en lumière linéaire avec alpha prémultiplié pour limiter les halos. Il convient aux fonds, illustrations et dégradés. Choisir `pixel-art` si l’image doit conserver des indices de palette ou un masque séparé.
- Chaque case d’une planche est traitée isolément selon `grid`, ce qui évite les débordements entre images d’animation. Une variante fournie dans `sources` est prioritaire au même facteur. L’agrandissement conserve la composition et la géométrie logique. Le détail supplémentaire provient d’une variante HD fournie.

Le convertisseur de paquet génère les variantes, puis les fait vérifier par le chargeur C++. Il est aussi possible de convertir un PNG seul.

```sh
python3 port/tools/upscale.py sprite.png sprite-4x.png --method pixel-art --factor 4
python3 port/tools/upscale.py fond.png fond-3x.png --method lanczos --factor 3
```

Pour une planche utilisée seule, ajouter par exemple `--grid 6 2` pour six colonnes et deux lignes. La destination PNG doit être neuve.

### Audio

- Les sources `wav`, `flac` et `8svx` passent par FFmpeg. Pour du PCM brut signé 8 bits, utiliser `pcm-s8` et préciser `rate` et `channels`. Les bruitages sortent en WAV PCM 16 bits. La musique est empaquetée en FLAC.
- Pour les modules P6/P61, produire en amont un rendu WAV ou FLAC depuis un lecteur de référence. Si les canaux doivent rester indépendants, exporter une piste par canal à cadence et durée égales. `loop` est un intervalle `[début, fin)` en échantillons par canal du fichier source. Sans intervalle, l’intégralité de la piste boucle.
- Le mixeur travaille à 48 kHz. Il conserve la phase d’une piste momentanément coupée. Lorsqu’il manque une voix de bruitage, la priorité décide et la voix la plus ancienne cède parmi celles de même priorité. Cette politique sert à l’aperçu. Son équivalence avec l’arbitrage Amiga reste à établir.
