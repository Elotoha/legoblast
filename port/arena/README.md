# Ember Relay

Premier jeu original en C++20 et SDL3. Deux joueurs partagent le clavier dans une arène aux visuels pixel art dessinés par le programme. Évite les explosions, ouvre des passages dans les caisses et fais exploser plusieurs bombes en chaîne. Trois manches gagnées remportent le match. Une double élimination ou la fin des 75 secondes donne une manche nulle.

| Joueur | Déplacement | Bombe |
| --- | --- | --- |
| Ambre | ZQSD (AZERTY) / WASD (QWERTY) | Espace |
| Cyan | Flèches | M ou 0 du pavé numérique |

Entrée relance après une manche ou un match. Échap ferme la fenêtre.

## Windows x64

Télécharge l’artefact `Ember-Relay-Windows-x64` depuis une exécution réussie du workflow [Ember Relay Windows](https://github.com/Elotoha/legoblast/actions/workflows/ember-relay-windows.yml), extrais le ZIP et ouvre `EmberRelay.exe`.

## Compiler

Avec CMake 3.24+, SDL3 3.2+ et un compilateur C++20, depuis la racine du dépôt.

```sh
cmake -S port/arena -B /tmp/ember-relay
cmake --build /tmp/ember-relay --parallel
ctest --test-dir /tmp/ember-relay --output-on-failure
/tmp/ember-relay/EmberRelay
```

Sous Windows, le workflow utilise le manifeste vcpkg de ce dossier et le triplet `x64-windows-static`.
