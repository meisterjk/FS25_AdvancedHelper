# FS25_AdvancedHelper

[English](#english) | [Deutsch](#deutsch)

---

<a id="english"></a>

## English

A full worker/employee management system for Farming Simulator 25 that replaces the default AI helpers. Hire workers with unique skills, manage them via HUD or InGame menu, and let them work your fields — with real consequences for fuel consumption, speed and vehicle wear.

### What does this mod do?

Instead of the unlimited default AI helpers, you hire individual workers. Each worker has three skill attributes that directly affect how they perform:

- **Only as many AI helpers as workers hired** — no workers, no AI
- **Workers cost a monthly salary** — based on their skill level and game difficulty
- **Skills affect gameplay** — a bad driver is slower, a skilled worker causes less wear
- **Multiplayer support** — each farm hires and manages its own workers

### Worker Attributes

Every worker has three attributes on a scale of 1–10 (5 is average):

| Attribute | Low (1) | Average (5) | High (10) |
|-----------|---------|-------------|-----------|
| **Efficiency** | +10% fuel consumption | No effect | −10% fuel consumption |
| **Driving** | −30% work speed | No effect | No bonus (only reduction) |
| **Skill** | +20% vehicle wear | No effect | −20% vehicle wear |

Better workers cost more salary. The salary also scales with the game difficulty setting (Easy ×0.7, Normal ×1.0, Hard ×1.5).

### Controls

| Action | Default Binding |
|--------|----------------|
| Toggle HUD | Ctrl + H |
| Toggle HUD cursor | Middle Mouse Button |
| InGame Menu | ESC → Advanced Helper tab |

### HUD

The HUD overlay shows all hired workers for your farm at a glance:

- Worker name and three attribute values
- Status: **Free** or **Active** (with vehicle name and source like CP/AD)
- Play button to start a free worker on your current vehicle
- Stop button to dismiss a worker from their job
- Drag the header to move the HUD

### InGame Menu

Open the ESC menu and find the **Advanced Helper** tab:

- **Applicants** — Browse available workers, hire them with one click. New applicants appear every 3 days
- **Employees** — View all hired workers with their attributes and salary. Dismiss workers here
- Total monthly costs and available AI helpers shown at the bottom

### Courseplay & AutoDrive

Works alongside both mods — no conflicts:

- **Courseplay** — Workers are automatically assigned to CP jobs. When CP finishes, the worker is released
- **AutoDrive** — Workers are assigned to AD vehicles. When AD stops, the worker is released
- Both integrations can be disabled in the config file if you prefer independent operation

### Hiring & Salary

- Workers appear as applicants every 3 game days (3–5 new ones)
- Hiring costs the first month's salary immediately
- Monthly salary is deducted automatically at each period change
- If you can't afford the salaries, you'll get a notification with the missing amount
- Worker salaries appear as a separate line in the finance overview

### Multiplayer

Fully multiplayer-compatible. Each farm manages its own workers independently. All actions (hire, fire, assign) are synced automatically via the server.

### Installation

1. Download the latest `FS25_AdvancedHelper.zip` from [Releases](https://github.com/meisterjk/FS25_AdvancedHelper/releases)
2. Place the ZIP file in your `mods/` folder
3. Enable the mod in the FS25 mod menu

### Changelog

**v1.3.0.5:**
- Updated mod icon texture
- Added changelog to mod description

**v1.3.0.4:**
- Fixed steering mode and AI settings being blocked when all workers are busy
- Workers are now properly released when an AI job ends or is cancelled

**v1.3.0.0:**
- Worker names now match the game language (German, English, US)
- No more duplicate worker names
- Fixed Giants AI dialog bypass

**v1.2.0.0:**
- Improved fuel consumption, work speed and vehicle wear effects — now apply during all activities
- Worker names now show readable names in notifications instead of internal IDs
- Better integration with Courseplay and AutoDrive
- Restructured project layout

**v1.1.0.0:**
- Better Courseplay and AutoDrive integration
- Fixed worker assignment issues when switching between AI, Courseplay and AutoDrive
- Fixed handoff between Courseplay and AutoDrive

**v1.0.0.0:**
- Initial release with hire/fire, attribute system, HUD, InGame menu, payroll, multiplayer

### License

MIT — see [LICENSE](LICENSE) for details.

---

<a id="deutsch"></a>

## Deutsch

Ein vollständiges Personalmanagement-System für Farming Simulator 25, das die Standard-KI-Helfer ersetzt. Stelle Arbeiter mit einzigartigen Fähigkeiten ein, verwalte sie über das HUD oder das InGame-Menü und lasse sie auf deinen Feldern arbeiten — mit echten Auswirkungen auf Spritverbrauch, Geschwindigkeit und Fahrzeugverschleiß.

### Was macht dieser Mod?

Statt der unbegrenzten Standard-KI-Helfer stellst du einzelne Arbeiter ein. Jeder Arbeiter hat drei Fähigkeiten, die sich direkt auf seine Leistung auswirken:

- **Nur so viele KI-Helfer wie Arbeiter eingestellt** — keine Arbeiter, keine KI
- **Arbeiter kosten ein Monatsgehalt** — basierend auf ihren Fähigkeiten und dem Schwierigkeitsgrad
- **Fähigkeiten beeinflussen das Spiel** — ein schlechter Fahrer ist langsamer, ein geschickter Arbeiter verursacht weniger Verschleiß
- **Multiplayer-fähig** — jede Farm stellt und verwaltet ihre eigenen Arbeiter ein

### Arbeiter-Attribute

Jeder Arbeiter hat drei Attribute auf einer Skala von 1–10 (5 ist Durchschnitt):

| Attribut | Niedrig (1) | Durchschnitt (5) | Hoch (10) |
|-----------|---------|-------------|-----------|
| **Effizienz** | +10% Spritverbrauch | Kein Effekt | −10% Spritverbrauch |
| **Fahrweise** | −30% Arbeitstempo | Kein Effekt | Kein Bonus (nur Reduktion) |
| **Können** | +20% Fahrzeugverschleiß | Kein Effekt | −20% Fahrzeugverschleiß |

Bessere Arbeiter kosten mehr Gehalt. Das Gehalt skaliert auch mit dem Schwierigkeitsgrad (Einfach ×0.7, Normal ×1.0, Schwer ×1.5).

### Steuerung

| Aktion | Standard-Taste |
|--------|----------------|
| HUD ein/aus | Strg + H |
| HUD-Mauszeiger ein/aus | Mittlere Maustaste |
| InGame-Menü | ESC → Erweiterte Helfer-Tab |

### HUD

Das HUD-Overlay zeigt alle eingestellten Arbeiter deiner Farm auf einen Blick:

- Arbeitername und drei Attributwerte
- Status: **Frei** oder **Aktiv** (mit Fahrzeugname und Quelle wie CP/AD)
- Play-Button um einen freien Arbeiter auf dem aktuellen Fahrzeug zu starten
- Stop-Button um einen Arbeiter von seiner Arbeit zu entlassen
- Header ziehen um das HUD zu verschieben

### InGame-Menü

Öffne das ESC-Menü und finde den Tab **Erweiterte Helfer**:

- **Bewerber** — Durchsuche verfügbare Arbeiter, stelle sie mit einem Klick ein. Neue Bewerber erscheinen alle 3 Tage
- **Angestellte** — Alle eingestellten Arbeiter mit Attributen und Gehalt. Arbeiter hier entlassen
- Monatliche Gesamtkosten und verfügbare KI-Helfer werden unten angezeigt

### Courseplay & AutoDrive

Funktioniert alongside beiden Mods — keine Konflikte:

- **Courseplay** — Arbeiter werden automatisch CP-Jobs zugewiesen. Wenn CP fertig ist, wird der Arbeiter freigegeben
- **AutoDrive** — Arbeiter werden AD-Fahrzeugen zugewiesen. Wenn AD stoppt, wird der Arbeiter freigegeben
- Beide Integrationen können in der Config-Datei deaktiviert werden

### Einstellen & Gehalt

- Arbeiter erscheinen alle 3 Spieltage als Bewerber (3–5 neue)
- Beim Einstellen wird das erste Monatsgehalt sofort abgezogen
- Das Monatsgehalt wird automatisch bei jedem Periodenwechsel abgezogen
- Wenn das Geld nicht reicht, bekommst du eine Benachrichtigung über den fehlenden Betrag
- Arbeitergehälter erscheinen als separate Zeile in der Finanzübersicht

### Multiplayer

Voll multiplayer-kompatibel. Jede Farm verwaltet ihre eigenen Arbeiter unabhängig. Alle Aktionen (einstellen, entlassen, zuweisen) werden automatisch über den Server synchronisiert.

### Installation

1. Lade die neueste `FS25_AdvancedHelper.zip` von [Releases](https://github.com/meisterjk/FS25_AdvancedHelper/releases) herunter
2. Platziere die ZIP-Datei in deinem `mods/`-Ordner
3. Aktiviere den Mod im FS25-Mod-Menü

### Changelog

**v1.3.0.5:**
- Mod-Icon-Textur aktualisiert
- Changelog zur Mod-Beschreibung hinzugefügt

**v1.3.0.4:**
- Lenkmodus und KI-Einstellungen werden nicht mehr blockiert wenn alle Arbeiter beschäftigt sind
- Arbeiter werden nun korrekt freigegeben wenn ein KI-Job beendet oder abgebrochen wird

**v1.3.0.0:**
- Arbeiternamen passen sich nun der Spielsprache an (Deutsch, Englisch, US)
- Keine doppelten Arbeiternamen mehr
- KI-Dialog-Umgehung behoben

**v1.2.0.0:**
- Verbesserte Effekte für Spritverbrauch, Arbeitsgeschwindigkeit und Fahrzeugverschleiß — wirken jetzt bei allen Tätigkeiten
- Arbeiternamen werden nun lesbar in Benachrichtigungen angezeigt statt als interne IDs
- Bessere Integration mit Courseplay und AutoDrive
- Projektstruktur neu organisiert

**v1.1.0.0:**
- Bessere Courseplay- und AutoDrive-Integration
- Arbeiterzuweisungsprobleme beim Wechsel zwischen KI, Courseplay und AutoDrive behoben
- Übergabe zwischen Courseplay und AutoDrive behoben

**v1.0.0.0:**
- Erste Version mit Einstellen/Entlassen, Attribut-System, HUD, InGame-Menü, Gehaltsabrechnung, Multiplayer

### Lizenz

MIT — siehe [LICENSE](LICENSE) für Details.