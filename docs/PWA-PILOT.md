# StylO 1.1.1 — PWA cu decupare locală

Importul fotografiilor, decuparea opțională și salvarea imaginilor folosesc Hive/IndexedDB pe web. Decuparea rulează local, prin ONNX Runtime Web într-un Worker, fără trimiterea fotografiei către un serviciu AI. Prima utilizare descarcă motorul și modelul. Imaginea de lucru este limitată la 1280 px pentru procesare.

Verificat în browser Chromium: import fotografie, decupare PNG transparent, salvare în garderobă și păstrare după reîncărcare. 18 teste Flutter trecute, inclusiv cele cinci ancore, persistența potrivirii, pantofi separați, manechin feminin și teme.

Link public: https://stylo-wardrobe-pilot.bro18nice.chatgpt.site

Pe iPhone se deschide în Safari și se adaugă pe ecranul principal. Testul pe un iPhone fizic rămâne necesar; nu promitem calitate perfectă pentru orice fotografie sau funcționare completă offline. Fotografiile cu fundal simplu și contrast bun dau rezultate mai bune. Datele rămân în browserul dispozitivului; ștergerea datelor site-ului poate șterge garderoba. Nu există sincronizare sau backup cloud automat.
