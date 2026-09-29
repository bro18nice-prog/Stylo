# StylO — testare pe Android

Logo selectat: S gotic în cercul format de șarpele ouroboros. Versiune 1.0.1+2.

## Stare
Logo-ul este aplicat. Testele anterioare schimbării logo-ului: 15 trecute și flutter analyze fără probleme. Compilarea Android din sesiunea Codex a eșuat; SDK-ul local returnează Access denied. Nu există încă un APK nou verificat. APK-ul din 14 septembrie este vechi.

## Construirea pe laptop
Deschide PowerShell în folderul proiectului Stylo și rulează:

```powershell
.\tool\build_android_beta.ps1
```

Scriptul rulează flutter pub get și flutter build apk --release și copiază APK-ul numai dacă compilarea reușește, în dist\StylO-1.0.1-beta.apk. Nu cumpără și nu publică nimic. Dacă PowerShell blochează scripturile, rulează manual:

```powershell
flutter pub get
flutter build apk --release
```

Fișierul rezultat este build\app\outputs\flutter-apk\app-release.apk.

## Trimitere și instalare
1. Trimite APK-ul ca document sau încarcă-l în propriul Drive și trimite linkul.
2. Destinatarul descarcă APK-ul pe un telefon Android și îl deschide.
3. Dacă Android cere, permite instalarea din acea sursă (browser sau Files), apoi apasă Instalare. Denumirile diferă între telefoane.
4. Deschide StylO. Fiecare persoană își adaugă propriile haine; garderoba se păstrează local și nu se sincronizează între telefoane.

APK-ul nu se instalează pe iPhone. Nu este necesară publicarea în Google Play pentru acest test privat. Regulile de verificare Android diferă după regiune/dispozitiv; dacă apare un blocaj, păstrează mesajul exact pentru diagnostic.

## Actualizări
Trimite noul APK și instalează-l peste cel existent, fără dezinstalare, pentru păstrarea datelor. Păstrează același applicationId și aceeași cheie de semnare. Configurația actuală release folosește cheia debug locală: pachet de test privat, nu release pentru magazin. Nu șterge cheia locală și nu o trimite împreună cu APK-ul. O semnătură diferită împiedică actualizarea peste versiunea existentă. Nu dezinstala înainte de a salva datele importante.

Documentație: https://developer.android.com/distribute/marketing-tools/alternative-distribution
