# iPhone test pres GitHub a MobAI

Projekt je pripraveny pro testovaci iOS build s temito hodnotami:

- iOS nazev aplikace: `Servis WWII Jeepu`
- bundle ID: `cz.servisww2.jeep`

## Co jeste udelas ty

1. Nahraj projekt do vlastniho GitHub repozitare.
2. Otevri `Actions` a spust workflow `iOS Build`.
3. Stahni vytvoreny `.ipa` artifact.
4. V MobAI / ios-builder se prihlas svym Apple ID a pripoj iPhone.
5. Povol na iPhonu `Developer Mode` a duveru pro aplikaci.

## Kde je workflow

- `.github/workflows/ios-build.yml`

Workflow dela:

1. checkout projektu
2. `flutter pub get`
3. `pod install`
4. `flutter build ipa --release --no-codesign`
5. nahraje `.ipa` jako artifact

## Poznamka

Pokud MobAI bude chtit jine signing nastaveni nebo vlastni workflow, tenhle soubor je dobry zaklad. Nejdulezitejsi casti uz jsou pripravene:

- hotova iOS slozka
- jednotne bundle ID
- spravny nazev aplikace
- automaticky GitHub build artifact
