# Lia et le laboratoire LegoBlast

En partie, **L** fait rejoindre Lia. **Retour arrière** reste la touche de Micro. Les deux ordinateurs peuvent jouer dans la même partie si deux places sont libres.

Lia teste dix commandes, soit cinq directions avec ou sans une impulsion de Feu. Elle explore des suites de mouvements sur 40 VBL, puis prolonge les trajectoires retenues sans input jusqu’à l’extinction des bombes ou jusqu’à 900 VBL de plus. Elle utilise des copies de `Session`, avec les mêmes routines de collision, poussée, gel, mèche, rebond, bumper, téléportation, propagation dans les tuyaux et réaction en chaîne que la partie réelle. Elle privilégie les refuges, la collecte des bonus et les occasions d’ouvrir un passage ou de toucher un rival. Elle suppose que les adversaires cessent de donner des commandes pendant ses simulations, puis recalcule toutes les huit VBL.

## Compiler et comparer des agents

CMake 3.24 et un compilateur C++20 suffisent pour le simulateur. Depuis la racine du dépôt sous Linux ou macOS, exécuter les commandes suivantes.

```sh
cmake -S port/legoblast -B build/lia -DCMAKE_BUILD_TYPE=Release
cmake --build build/lia --config Release
ctest --test-dir build/lia -C Release --output-on-failure
build/lia/legoblast_lab duel amiga/src/binary/Lego_Level314.dat lia micro 4 10 4000
```

Le ZIP Windows inclut `legoblast_lab.exe` et les arènes sous `data/binary`. Exemple dans PowerShell depuis le dossier extrait.

```powershell
.\legoblast_lab.exe duel .\data\binary\Lego_Level314.dat lia micro 4 10 4000
```

La commande joue quatre paires, une manche dans chaque place de départ pour chacune des graines 10 à 13. Chaque manche produit une ligne JSON. La dernière ligne donne les victoires, défaites, égalités et fins au plafond de VBL. Ce plafond est configurable. Le résultat d’une manche suit le moteur, notamment pour les reprises après mort rapide. Les agents disponibles sont `idle`, `random`, `micro`, `lia`, `neural=modèle` et `lia=modèle`. Le moteur actuel attribue une seule commande Micro, donc un duel accepte au plus un Micro.

## Entraîner un réseau hors ligne

Le script utilise Python 3 et NumPy. Il lance des sous-processus C++ sans SDL. L’observation comprend l’état du joueur, la direction du rival le plus proche et une vue locale de 7 × 7 cases qui expose les flammes, les mèches, l’énergie des bombes, leurs déplacements, leur gel, les types de case et les téléporteurs. Le réseau de départ a une couche cachée de 64 neurones. La récompense principale est le résultat de la manche. La collecte de bonus, la pose de bombes et les morts contribuent également à la récompense.

```sh
python3 -m pip install numpy
python3 port/legoblast/lia_lab/train_ppo.py \
  --lab build/lia/legoblast_lab \
  --levels amiga/src/binary/Lego_Level001.dat amiga/src/binary/Lego_Level314.dat \
  --opponent micro --output models/lia-ppo.model
build/lia/legoblast_lab duel amiga/src/binary/Lego_Level021.dat \
  neural=models/lia-ppo.model lia 5 100 6000
```

Sous Windows, utiliser `python`, `lia_lab/train_ppo.py`, `--lab ./legoblast_lab.exe` et les chemins d’arènes du ZIP. Le fichier `.model` contient les poids du réseau de décision. Le fichier associé `.model.npz` contient aussi le critique et les données de l’optimiseur. Reprendre avec `--resume models/lia-ppo.model.npz`. Pour entraîner contre une version figée d’un autre réseau, passer `--opponent neural=chemin/ancien.model`. Des checkpoints successifs peuvent ainsi s’affronter ou servir d’adversaires d’entraînement.

`neural=modèle` joue l’action avec le score neuronal maximal. `lia=modèle` garde la simulation tactique et utilise les scores du réseau dans son classement des actions. Dans le jeu Windows, lancer `legoblast_players.exe --menu --lia-model=models/lia-ppo.model` pour utiliser cette seconde configuration.

## Choisir l’algorithme

PPO est le premier algorithme proposé. Il échange des trajectoires fraîches avec le moteur et se prête aux changements d’adversaire entre générations. Il fournit aussi une politique stochastique pendant l’entraînement, ce qui facilite l’exploration d’actions comme lâcher une bombe et changer immédiatement d’axe. DQN est un bon point de comparaison avec dix actions discrètes et un adversaire fixe. Son replay peut réutiliser plus efficacement les parties coûteuses. Pour comparer les deux, conserver les mêmes observations, arènes, adversaires, places de départ et budgets de VBL, puis évaluer sur des arènes et graines tenues à l’écart de l'entraînement.

Le protocole `legoblast_lab serve OPPONENT LEVEL...` accepte `R INDEX_ARÈNE PLACE GRAINE MAX_VBL` et `S ACTION` sur stdin, une commande par ligne. Il renvoie l’observation, la récompense, le résultat, la fin naturelle et la troncature en JSON. Les actions 0 à 4 sont repos, gauche, droite, haut et bas. Les actions 5 à 9 ajoutent Feu au premier VBL. Ce protocole permet de raccorder un autre entraîneur au même moteur.
