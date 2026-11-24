# LegoBlast pour Python

Le paquet **LegoBlast-Python-Windows-x64** de GitHub Actions est autonome. Extraire le ZIP entier, puis ouvrir `LegoBlast-Python.exe`.

Python et Pygame pilotent la fenêtre, les entrées, le panneau d’invitations et la lecture audio. La bibliothèque C++ fournie calcule les parties et décode les ressources Amiga. Elle est commune avec les versions Windows et Android, afin que les règles et la simulation de Lia restent identiques.

- **Entrée** ou **Alt droit** fait apparaître un joueur, puis pose une bombe. Les **flèches** le déplacent.
- **Retour arrière** fait rejoindre Micro. Chaque appui sur **L** ajoute une Lia à la première place libre.
- **F1/F2** changent d’arène, **Début** la rejoue, **P** met en pause et **Échap** revient au menu. **F3 à F6** sélectionnent les pistes disponibles et **F10** coupe la musique.
- **Réseau** ou **F11** ouvre le salon WebSocket commun. Les invitations sont optionnelles. Quatre places humaines ou occupées par des bots lancent la partie.

## Lancer depuis les sources

Installer Python 3.12, CMake 3.24 ou plus récent, un compilateur C++20 et libcurl 8 avec WebSocket. Pour extraire les données, installer `lhasa`, `bsdtar` ou `7z`.

Depuis la racine du dépôt, sur Linux x64.

```sh
python3 -m pip install -r port/python/requirements.txt
cmake -S port/legoblast -B build/python -DLEGOBLAST_PYTHON=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build/python --parallel
python3 port/android/prepare.py --data-only build/python
python3 port/python/play.py --library build/python/liblegoblast_python.so --data build/python/data
```

Sur Windows, configurer CMake avec le toolchain vcpkg et le triplet `x64-windows-static`. Le fichier de bibliothèque produit par Visual Studio est `build/python/Release/legoblast_python.dll`. Les préférences restent dans le dossier utilisateur `Gogo/LegoBlastPython`.

L’option `--level 314` ouvre directement l’arène 314. L’option `--smoke` exécute un court test de rendu, audio et gameplay.
