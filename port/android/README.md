# LegoBlast pour Android

Cette version reprend le jeu C++ de la branche Lia. L’APK de test signé fonctionne à partir d’Android 8 sur ARM64 et x86‑64. Le jeu se joue en paysage, hors ligne. L’appli extrait les graphismes et les sons dans son espace privé au premier lancement.

Télécharger **LegoBlast-Android** dans **Actions → LegoBlast Android → Summary → Artifacts**. Extraire le ZIP de GitHub, ouvrir `LegoBlast-Android.apk` sur l’appareil et autoriser l’installation depuis l’application utilisée pour l’ouvrir si Android le demande.

- **Croix** et **OK** pour naviguer dans les menus. **BACK** revient en arrière.
- En partie, garde le pouce sur la **croix** et glisse d’une direction à l’autre pour tourner.
- **FIRE** fait apparaître le joueur tactile. Relâcher puis appuyer à nouveau pour poser une bombe.
- **MICRO** fait rejoindre Micro. Chaque appui sur **LIA** ajoute une Lia à une place libre. Une manette reconnue par Android peut aussi rejoindre avec son bouton principal.
- **PAUSE** suspend ou reprend la partie. **BACK** revient au menu.
- **RACC.** ouvre les raccourcis de la version Windows. En partie, il donne accès aux arènes, à Rejouer, au podium, aux pistes et aux volumes. Dans le menu, il donne accès aux quatre réglages de voix et aux crédits. Les pistes 5 à 7 restent indisponibles dans les ressources d’origine.

L’APK est signé avec une clé de test. Une mise à jour provenant d’un autre environnement de compilation peut avoir une signature différente. Android demande alors de désinstaller l’ancienne version avant l’installation, ce qui efface ses préférences locales.

## Compiler

Utiliser un JDK 17, Gradle 8.10.2, Python 3.12+, curl et `lhasa` ou `bsdtar`. Installer le SDK Android 35, les Build Tools 35.0.0, le NDK 28.2.13676358 et CMake 3.31.6 avec le gestionnaire de SDK. Définir `ANDROID_HOME` vers le SDK ou ajouter `sdk.dir` dans `port/android/local.properties`.

Depuis la racine du dépôt, exécuter les commandes suivantes.

```sh
python3 port/android/prepare.py
gradle -p port/android :app:assembleDebug
```

Gradle écrit le fichier dans `port/android/app/build/outputs/apk/debug/app-debug.apk`. Sur un appareil ou un émulateur avec le débogage USB activé, on peut aussi l’installer ainsi.

```sh
adb install -r port/android/app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n org.legoblast.game/.LegoBlastActivity
```
