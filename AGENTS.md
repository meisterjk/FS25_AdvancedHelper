# AGENTS.md - FS25_AdvancedHelper Mod

## Mod-Übersicht

**Name:** FS25_AdvancedHelper
**Typ:** Script-Mod (InGameMenu-Erweiterung)
**FS25 ModDesc Version:** 109
**Pfad:** `mods/FS25_AdvancedHelper/`

### Kern-Mechanik
- Angestellte Arbeiter ersetzen KI-Helfer 1:1 (N angestellte = N verfügbare Helfer)
- Jeder Arbeiter hat 3 Attribute (Skala 1-10): Effizienz (Sprit), Fahrweise (Tempo), Können (Verschleiß)
- Attribut-Wirkung: **Asymmetrisch** (Bereich 1-10, Neutral=5)
  - **Effizienz→Sprit**: positive Abweichung /4, negative /5 → Wert 1=+10%, Wert 10=-10%
  - **Fahrweise→Tempo**: linear `(10 - driving) / 9 * maxPct` → Wert 1=-30%, Wert 10=±0% (nur Reduktion, kein Bonus)
  - **Können→Verschleiß**: positive Abweichung /4, negative /5 → Wert 1=+10%, Wert 10=-10%
- Gehalt basiert auf Attribut-Summe + Schwierigkeitsgrad
- Schwierigkeits-Multiplikator: Einfach=0.7x, Normal=1.0x, Schwer=1.5x
- Gehaltsabrechnung am Periodenwechsel (`MessageType.PERIOD_CHANGED`) automatisch via `advancedHelperPayroll`
- Bewerber erscheinen alle 3 Spieltage (3-5 zufällige)
- Multiplayer: Jeder Arbeiter gehört zu einer Farm (`farmId`), nur diese Farm kann ihn steuern

### Github Repository
- nicht selbst pushen, erst nach einer abgeschlossenen Aufgabe, dann zuerst nachfragen soll gepusht werden?, welcher Versionssprung?, neues Release erstellen?
- username: meisterjk
- token: siehe KeePass "github meisterjk"
- repo name: FS25_AdvancedHelper
- Release conventions:
  - Tag: `v<version>` (z.B. v0.3.1)
  - Release title: `FS25_AdvancedHelper` (immer gleich, kein Version-Suffix)
  - Release asset: die gepackte Mod-ZIP heißt `FS25_AdvancedHelper.zip`
  - ZIP erstellen: `cd FS25_AdvancedHelper && zip -r /tmp/FS25_AdvancedHelper.zip . -x ".git/*" ".gitignore" "AGENTS.md" "README.md" "LICENSE" "images/*"` (flache Struktur, kein umschließender Ordner)
  - Push: `git push -u origin main`
  - Force push: `git push -u origin main --force` (nur bei Bedarf, überschreibt alles)
  - Release erstellen: `gh release create <tag> --title "FS25_AdvancedHelper" --notes "..." --target main /path/to/FS25_AdvancedHelper.zip#FS25_AdvancedHelper.zip`
  - Release löschen: `gh release delete <tag> --yes && git push origin :refs/tags/<tag>`
  - Token in Remote-URL: `git remote set-url origin https://<TOKEN>@github.com/meisterjk/FS25_AdvancedHelper.git`
  - Token aus Remote-URL entfernen: `git remote set-url origin https://github.com/meisterjk/FS25_AdvancedHelper.git`
  - Commit-Messages: Englisch, präzise, z.B. "Fix AD worker stop via HUD button"
  - **modDesc.xml Changelog**: Bei jedem Release muss der Changelog in der `<description>` (en + de) in `modDesc.xml` aktualisiert werden. Neue Version oben einfügen, allgemein und anfängergerecht formulieren, keine Code-Details oder Methodennamen. Ältere Versionen können zusammengefasst werden. Beispiel siehe aktuelle `modDesc.xml`.

### TestRunner ausführen
```
WINEPREFIX=/home/mjk/.steam/debian-installation/steamapps/compatdata/2300320/pfx wine /home/mjk/Downloads/TestRunner_public_0_9_17/TestRunner_public.exe "C:\users\steamuser\Documents\My Games\FarmingSimulator2025\mods\FS25_AdvancedHelper" -g "Z:\home\mjk\.steam\debian-installation\steamapps\common\Farming Simulator 25" -e "Z:\home\mjk\.wine\drive_c\Program Files\GIANTS Software\GIANTS_Editor_10.0.12"
```

### Dateistruktur
```
FS25_AdvancedHelper/
├── modDesc.xml
├── icon_advancedHelper.dds
├── scripts/
│   ├── advancedHelperMain.lua                (Main: EventListener, loadMap, Hook-Installation, Client-Join-Sync)
│   ├── api/
│   │   └── advancedHelperAPI.lua             (Externe API für andere Mods: Query, Actions, Callbacks)
│   ├── core/
│   │   ├── advancedHelperConfig.lua          (Konfiguration: DEBUG, INFILTRATE_AUTODRIVE)
│   │   ├── advancedHelperWorker.lua          (Datenklasse: Name, Attribute, Gehalt, farmId, save/load)
│   │   └── advancedHelperManager.lua         (Hire/Fire, Bewerber, Server-Guards, buildSyncData, applySyncState, Persistenz)
│   ├── hooks/
│   │   ├── advancedHelperFuelHook.lua        (Motorized.updateConsumers Hook: consumer.usage pre-modification)
│   │   ├── advancedHelperSpeedHook.lua       (VehicleMotor.setSpeedLimit Hook + AI_JOB_STARTED/STOPPED: Worker-Zuweisung)
│   │   ├── advancedHelperDamageHook.lua      (Wearable updateDamageAmount + getWearMultiplier Hook)
│   │   ├── advancedHelperSafeguard.lua       (HelperManager + AIJob Hooks, Server-Guard auf aiJobStart)
│   │   └── advancedHelperHotspot.lua         (Minimap-Hotspot-Management für Worker)
│   ├── integration/
│   │   ├── advancedHelperAutoDriveHook.lua   (AutoDrive-Integration: Server-Guards, Sync-Broadcast)
│   │   └── advancedHelperCourseplayHook.lua  (Courseplay-Integration: cpStartStopDriver-Hook, CP-Events, HUD-API)
│   ├── network/
│   │   └── advancedHelperEvents.lua          (5 Netzwerk-Event-Klassen: Hire, Fire, Refresh, StartAI, Sync)
│   ├── lifecycle/
│   │   ├── advancedHelperDebug.lua           (Debug-Logging-Helpers)
│   │   ├── advancedHelperMoneyType.lua        (MoneyType.WORKER_SALARY Registrierung)
│   │   ├── advancedHelperFinanceStats.lua    (FinanceStats-Erweiterung für Arbeiterlohn-Zeile)
│   │   └── advancedHelperPayroll.lua         (Monatsgehalt-Abrechnung per PERIOD_CHANGED, pro Farm)
│   ├── hud/
│   │   └── advancedHelperHud.lua             (Overlay-HUD: Worker-Zuweisung via advancedHelperStartAIEvent)
│   └── gui/
│       ├── advancedHelperInGameMenuIntegration.lua  (InGameMenu Tab-Registrierung)
│       └── advancedHelperPage.lua          (Kombinierte Seite: Hire/Fire/Refresh via Events)
├── config/gui/
│   ├── advancedHelperPage.xml              (Kombiniertes GUI mit Sub-Category Selectors)
│   └── guiProfiles.xml
└── translations/
    ├── translation_en.xml
    └── translation_de.xml
```

### Wichtige interne Hooks
| Hook | Ziel-Methode | Datei |
|------|-------------|-------|
| Spritverbrauch | `Motorized.updateConsumers` (consumer.usage pre-mod) | `hooks/advancedHelperFuelHook.lua` |
| Geschwindigkeit | `VehicleMotor.setSpeedLimit` Hook (limit * speedMult) + `AI_JOB_STARTED`/`AI_JOB_STOPPED` für Worker-Zuweisung | `hooks/advancedHelperSpeedHook.lua` |
| Verschleiß | `Wearable.updateDamageAmount` + `Wearable.getWearMultiplier` | `hooks/advancedHelperDamageHook.lua` |
| Helfer-Schutz | `HelperManager.getRandomHelper` + `getRandomHelperStyle` | `hooks/advancedHelperSafeguard.lua` |
| AI starten erlauben | `AIJobVehicle.getCanStartAIVehicle` | `hooks/advancedHelperSafeguard.lua` |
| AI Toggle sichtbar | `AIJobVehicle.getShowAIToggleActionEvent` | `hooks/advancedHelperSafeguard.lua` |
| AI Job Start | `AIJob.start` → `isAssigned=true` + `assignedVehicle=vehicle` (Server-only) | `hooks/advancedHelperSafeguard.lua` |
| Laufkosten entfernen | `AIJob.getPricePerMs`, `AIJobFieldWork.getPricePerMs`, `AIJobConveyor.getPricePerMs` | `hooks/advancedHelperSafeguard.lua` |
| AD Start Event | `onStartAutoDrive` (Vehicle-Event, Server-only) — Observer + Deferred Stop | `integration/advancedHelperAutoDriveHook.lua` |
| AD Stopp Event | `onStopAutoDrive` (Vehicle-Event, Server-only) — Observer | `integration/advancedHelperAutoDriveHook.lua` |
| CP Stop Events | `onCpFinished` / `onCpFuelEmpty` / `onCpBroken` (Vehicle-Event, Server-only) — Observer | `integration/advancedHelperCourseplayHook.lua` |
| Client-Join Sync | `FSBaseMission.onConnectionFinishedLoading` (Utils.appendedFunction) | `advancedHelperMain.lua` |
| InGameMenu | `addIngameMenuPage()` Pattern | `gui/advancedHelperInGameMenuIntegration.lua` |
| Tag-Wechsel | `MessageType.DAY_CHANGED` via `g_messageCenter` | `advancedHelperMain.lua` |
| Monatswechsel | `MessageType.PERIOD_CHANGED` via `g_messageCenter` | `lifecycle/advancedHelperPayroll.lua` |
| Geld-System | `MoneyType.register("statisticWorkerSalary", ...)` | `lifecycle/advancedHelperMoneyType.lua` |
| Finanzübersicht | `FinanceStats.statNames` + `FinanceStats.new` Hook | `lifecycle/advancedHelperFinanceStats.lua` |

### Multiplayer-Architektur

**Strategie: Full-Sync** — Server broadcastet kompletten Zustand bei jeder Änderung. Datenmenge ist klein (~20 Workers + 5 Applicants).

#### Server-Authorität

- **Server ist alleinige Quelle der Wahrheit** für alle Worker-Zustände
- Alle Schreiboperationen (hire, fire, assign, unassign, generateApplicants, updateDay) sind mit `g_server`-Guard geschützt
- Clients senden Event an Server → Server führt Operation aus → Server broadcastet `advancedHelperSyncEvent` an alle Clients
- `maxNumHirables` wird nur auf dem Server gesetzt (`g_server` Guard in `update(dt)`)

#### Netzwerk-Events (`network/advancedHelperEvents.lua`)

| Event | Richtung | Zweck | `sendEvent()` Aufruf von |
|-------|----------|-------|--------------------------|
| `advancedHelperHireEvent` | Client→Server | Bewerber einstellen | `advancedHelperPage:onHireClicked()` |
| `advancedHelperFireEvent` | Client→Server | Arbeiter feuern | `advancedHelperPage:onFireClicked()` |
| `advancedHelperRefreshEvent` | Client→Server | Neue Bewerber generieren | `advancedHelperPage:onRefreshClicked()` |
| `advancedHelperStartAIEvent` | Client→Server | Arbeiter AI-Job starten (assign + startJob) | `advancedHelperHud:startWorker()` |
| `advancedHelperSyncEvent` | Server→Clients | Vollständiger Zustand (Full-Sync) | Nach jeder Zustandsänderung automatisch |

#### Event-Fluss: Beispiel Hire

```
Client: advancedHelperPage:onHireClicked()
  → advancedHelperHireEvent.sendEvent(applicantId, farmId)
  → g_client:getServerConnection():sendEvent(...)

Server: advancedHelperHireEvent:run(connection)
  → advancedHelperManager:hireApplicant(applicantId, farmId)
    → Server-only (isServer Guard)
    → g_helperManager:addHelper() + Worker erstellen
    → advancedHelperSyncEvent.broadcast()

Server: advancedHelperSyncEvent.broadcast()
  → g_server:broadcastEvent(advancedHelperSyncEvent.new(data))

Alle Clients: advancedHelperSyncEvent:run(connection)
  → advancedHelperManager:applySyncState(data)
    → hiredWorkers + applicants neu aufbauen
    → NetworkUtil.getObject() für assignedVehicleId → assignedVehicle
    → advancedHelperWorker._idCounter = max(all IDs)
    → refreshUI() → advancedHelperPage:updateContent()
```

#### `advancedHelperStartAIEvent` (ersetzt altes AIJobStartRequestEvent-Pattern)

Client sendet Worker-ID + Vehicle-ID + Farm-ID an Server. Server führt beides aus:
1. `advancedHelperManager:assignWorkerToVehicle(workerId, vehicle)` — Worker-Zuweisung
2. `vehicle:getStartableAIJob()` + `g_currentMission.aiSystem:startJob(job, farmId)` — AI-Job starten

Falls kein `startableJob` gefunden wird, wird Worker wieder unassigned.

#### Sync-Daten-Format (Stream-Serialisierung)

```
advancedHelperSyncEvent:writeStream:
  lastRefreshDay        — UIntN(16)
  numHiredWorkers       — UIntN(8)
  numApplicants         — UIntN(4)
  pro hiredWorker:
    id, firstName, lastName, gender, efficiency, driving, skill,
    monthlySalary, hireDay, farmId, isAssigned
    if isAssigned: hasAssignedVehicle(bool) + assignedVehicleId(NetworkUtil)
  pro applicant:
    id, firstName, lastName, gender, efficiency, driving, skill, monthlySalary
```

**Wichtig:** `assignedVehicle` wird als `NetworkUtil.getObjectId()` serialisiert und clientseitig via `NetworkUtil.getObject()` aufgelöst. Falls das Vehicle nicht mehr existiert → `isAssigned = false`.

#### Client-Join Sync

Wenn ein Client einem laufenden Spiel beitritt:
- `FSBaseMission.onConnectionFinishedLoading` (via `Utils.appendedFunction`) feuert auf dem Server
- Server sendet `advancedHelperSyncEvent.sendToClient(connection)` — initialer Full-Sync an den neuen Client
- Pattern analog zu Courseplay (`CpJoinEvent`)

#### Server-Guards in Hooks

| Datei | Guard | Grund |
|-------|-------|-------|
| `hooks/advancedHelperSpeedHook.lua` | `onAIJobStarted` / `onAIJobStopped` + `VehicleMotor.setSpeedLimit` Hook | Worker-Zuweisung, Speed-Hook greift automatisch bei jeder KI |
| `hooks/advancedHelperSafeguard.lua` | `aiJobStart` | Worker-Zuweisung nur auf Server (`isAssigned`, `assignedVehicle`) |
| `integration/advancedHelperAutoDriveHook.lua` | `onStartAutoDrive` / `onStopAutoDrive` | AD-Zuweisung nur auf Server |
| `advancedHelperMain.lua` | `update(dt)` für `maxNumHirables` | Nur Server reguliert Helper-Anzahl |

**SP-Kompatibilität:** In Singleplayer sind Client und Server dieselbe Instanz. Events werden lokal gesendet/empfangen — alles funktioniert wie bisher, nur durch die Event-Schicht.

#### Persistenz

- **Server-only Speicherung:** `saveState()` hat `g_server ~= nil` Guard
- Applicants werden zusammen mit hiredWorkers in `advancedHelper.xml` gespeichert
- `assignedVehicle` wird NICHT persistiert (transient, wird nach Load via AI-Job-Hooks wiederhergestellt)
- `loadFromSavegame()` wird via `CURRENT_MISSION_START` aufgerufen (Server-only)

#### farmId-Konzept

- Jeder Arbeiter speichert `farmId` (zugehörige Farm)
- `FarmManager.SINGLEPLAYER_FARM_ID` als Standardwert
- **Payroll**: Iteriert über alle Farms, zieht pro Arbeiter individuell ab (`g_currentMission:addMoney(-salary, farmId, MoneyType.WORKER_SALARY, true, true)`)
- **Balance-Check**: `g_farmManager:getFarmById(farmId):getBalance()` (NICHT `g_currentMission:getBalance()`)
- **GUI**: Filtert Angestellte nach `g_currentMission:getFarmId()` des aktuellen Spielers
- **Hire/Fire**: Übergibt `g_currentMission:getFarmId()` als `farmId` im Event
- **getPricePerMs**: Prüft `self.startedFarmId` (Job-spezifisch), fallback auf global
- **getCanStartAIVehicle**: Prüft `vehicle:getOwnerFarmId()` — nur Farmen mit Workern dürfen AI starten

### Externe API (`api/advancedHelperAPI.lua`)

**Global:** `advancedHelperAPI` — von jedem Mod aus zugänglich.
**Laden:** Via `modDesc.xml <sourceFile>` nach `network/advancedHelperEvents.lua`, vor `advancedHelperMain.lua`.
**Version:** `advancedHelperAPI._version = "1.0.0.0"`

#### Design-Prinzipien

1. **Kopien statt Referenzen** — alle Query-Funktionen returnen flache Tabellen-Kopien, keine `advancedHelperWorker`-Instanzen oder Vehicle-Referenzen
2. **Aktionen über Events** — `startWorker`, `hireApplicant` etc. senden Network-Events, keine direkten Manager-Aufrufe → MP-safe
3. **`isActive()` als Gate** — fast alle Funktionen prüfen `isActive()` und returnen leere Werte wenn Mod nicht bereit

#### Worker-Daten-Format (returned by all query functions)

```lua
{
    id = 1,                        -- eindeutige Worker-ID
    firstName = "Thomas",
    lastName = "Müller",
    gender = "M",                  -- "M" oder "F"
    efficiency = 7,                 -- 1-10 (Sprit-Effizienz)
    driving = 4,                    -- 1-10 (Tempo-Einfluss)
    skill = 6,                      -- 1-10 (Verschleiß-Einfluss)
    monthlySalary = 2100,           -- monatliche Kosten
    hireDay = 12,                   -- Spieltag der Einstellung
    farmId = 1,                     -- zugehörige Farm
    isHired = true,                 -- immer true für hiredWorkers
    isAssigned = true,              -- aktuell einem Fahrzeug zugewiesen?
    helperIndex = 3,                -- Giants Helper-Index (nil auf Clients)
    assignedVehicleName = "Tractor X" -- Name als String (nil wenn nicht zugewiesen)
}
```

#### Metadaten

| Funktion | Rückgabe | Beschreibung |
|----------|----------|-------------|
| `isLoaded()` | `bool` | Mod geladen und `advancedHelperManager.initialized == true`? |
| `getVersion()` | `string` | z.B. `"1.0.0.0"` |
| `isActive()` | `bool` | Mission läuft + Manager bereit? |

#### Query-Funktionen (nur Lesen)

| Funktion | Rückgabe | Beschreibung |
|----------|----------|-------------|
| `getHiredWorkers([farmId])` | `[{...}]` | Alle angestellten Worker (gefiltert nach Farm) |
| `getFreeWorkers([farmId])` | `[{...}]` | Nur freie (=nicht zugewiesene) Worker |
| `getAssignedWorkers([farmId])` | `[{...}]` | Nur zugewiesene Worker |
| `getApplicants([farmId])` | `[{...}]` | Aktuelle Bewerber |
| `getWorkerById(workerId)` | `table/nil` | Einzelner Worker per ID |
| `getWorkerByHelperIndex(index)` | `table/nil` | Worker per Giants Helper-Index |
| `getWorkerForVehicle(vehicle)` | `table/nil` | Zugewiesener Worker für Fahrzeug-Objekt |
| `getWorkerCount([farmId])` | `int` | Anzahl angestellter Worker |

#### Aktions-Funktionen (MP-safe via Events)

| Funktion | Rückgabe | Beschreibung |
|----------|----------|-------------|
| `startWorker(workerId, vehicle, farmId)` | `bool` | Spezifischen Worker auf Vehicle starten |
| `startFreeWorker(vehicle, farmId)` | `int/nil` | Ersten freien Worker starten → Worker-ID |
| `stopWorkerByVehicle(vehicle)` | `bool` | Worker per Vehicle stoppen |
| `stopWorker(workerId)` | `bool` | Worker per ID stoppen |
| `hireApplicant(applicantId, farmId)` | `bool` | Bewerber einstellen |
| `fireWorker(workerId, farmId)` | `bool` | Arbeiter feuern |
| `refreshApplicants()` | `bool` | Neue Bewerber generieren |
| `startWorkerOnCP(workerId, vehicle, farmId)` | `bool` | Worker auf Vehicle mit Courseplay starten |

**Wichtig:** Stop-Funktionen senden `AIJobStopRequestEvent` (Client) oder rufen `vehicle:stopCurrentAIJob()` (Server).

#### Callback-System

```lua
-- Registrieren:
advancedHelperAPI.subscribe("workerHired", myCallback)

-- Entfernen:
advancedHelperAPI.unsubscribe("workerHired", myCallback)
```

**Verfügbare Events:**

| Event | Argumente | Wann gefeuert | Wo |
|-------|-----------|---------------|-----|
| `"workerHired"` | `(workerData)` | Nach `hireApplicant()` + Sync | `core/advancedHelperManager.lua` |
| `"workerFired"` | `(workerData)` | Nach `fireWorker()` + Sync | `core/advancedHelperManager.lua` |
| `"workerAssigned"` | `(workerData, vehicleName)` | Nach `assignWorkerToVehicle()` + Sync | `core/advancedHelperManager.lua` |
| `"workerUnassigned"` | `(workerData, vehicleName)` | Nach `unassignWorker()` / `unassignWorkerByVehicle()` + Sync | `core/advancedHelperManager.lua` |
| `"applicantsRefreshed"` | `(applicantsList)` | Nach `generateApplicants()` + Sync | `network/advancedHelperEvents.lua` |
| `"syncReceived"` | `(fullState)` | Nach `applySyncState()` (MP-Sync) | `core/advancedHelperManager.lua` |

**`workerData`** = flache Kopie (siehe Format oben). **`vehicleName`** = String. **`applicantsList`** = Array von workerData. **`fullState`** = `{hiredWorkers=[...], applicants=[...], lastRefreshDay=N}`.

#### Nutzung durch andere Mods (Beispiele)

```lua
-- Beispiel: Worker mit bester Effizienz für Sprit-intensive Arbeit wählen
if advancedHelperAPI and advancedHelperAPI.isLoaded() then
    local farmId = g_currentMission:getFarmId()
    local freeWorkers = advancedHelperAPI.getFreeWorkers(farmId)
    table.sort(freeWorkers, function(a, b) return a.efficiency > b.efficiency end)
    if #freeWorkers > 0 then
        advancedHelperAPI.startWorker(freeWorkers[1].id, vehicle, farmId)
    end
end

-- Beispiel: Auf Worker-Zuweisung reagieren
if advancedHelperAPI then
    advancedHelperAPI.subscribe("workerAssigned", function(workerData, vehicleName)
        print(string.format("Worker %s %s assigned to %s (Eff=%d)",
            workerData.firstName, workerData.lastName, vehicleName, workerData.efficiency))
    end)
end

-- Beispiel: Arbeiteranzahl für UI-Anzeige
if advancedHelperAPI and advancedHelperAPI.isActive() then
    local count = advancedHelperAPI.getWorkerCount(g_currentMission:getFarmId())
    local free = #advancedHelperAPI.getFreeWorkers(g_currentMission:getFarmId())
    print(string.format("Workers: %d total, %d free", count, free))
end
```

#### Interne Hilfsfunktionen (nicht für externe Nutzung)

| Funktion | Zweck |
|----------|-------|
| `_copyWorker(worker)` | Flache Kopie eines `advancedHelperWorker`-Objekts → plain table |
| `_fire(eventName, ...)` | pcall aller registrierten Callbacks für Event |

### Gehaltsabrechnung (Payroll)
- **Timing**: `MessageType.PERIOD_CHANGED` (monatlich, von C++ Engine veröffentlicht)
- **MoneyType**: `MoneyType.WORKER_SALARY` (eigener Eintrag in Finanzübersicht)
- **Pro-Farm Logik**: Arbeiter werden nach `farmId` gruppiert; jede Farm bekommt individuelle Notifications
- **Balance-Check vor Abzug**: `farm:getBalance() < totalCosts` → Benachrichtigung mit fehlendem Betrag
- **Individuelle Notifications**: Pro Arbeiter: "Werner Meyer: 2.167 / Monat"
- **Laufende AI-Kosten**: `getPricePerMs` gibt 0 zurück wenn Farm Arbeiter hat → kein Doppelsoll
- **Ingame Notification**: `FSBaseMission.INGAME_NOTIFICATION_CRITICAL`

### MoneyType + FinanceStats (FieldLeasing-Pattern)
- `lifecycle/advancedHelperMoneyType.lua` wird via `modDesc.xml <sourceFile>` geladen (VOR `advancedHelperMain.lua`)
- `lifecycle/advancedHelperFinanceStats.lua` wird via `modDesc.xml <sourceFile>` geladen (VOR `advancedHelperMain.lua`)
- Beide MÜSSEN vor Mission-Start geladen werden, damit `FinanceStats.new` Hook und `MoneyType.register` rechtzeitig greifen
- Nicht via `source()` in `advancedHelperMain.lua` laden — sonst ist `FinanceStats` schon konstruiert und `statNamesI18n` wird nie gesetzt

### Geschwindigkeits-Hook Architektur (SpeedHook)

**`VehicleMotor.setSpeedLimit` Hook** — `Utils.overwrittenFunction` auf `VehicleMotor.setSpeedLimit`. Die KI (Giants, CP, AD) ruft `motor:setSpeedLimit(speed)` jeden Frame auf. Der Hook multipliziert den übergebenen `limit`-Wert mit `speedMult` wenn ein Worker zugewiesen ist.

**Warum nicht `Vehicle.speedLimit` setzen?**
- Traktoren haben `speedLimit = math.huge` → kein Effekt auf der Straße
- `doCheckSpeedLimit()` ist `false` wenn Gerät nicht abgesenkt → `getSpeedLimit(true)` ignoriert `Vehicle.speedLimit`
- Save/Restore-Komplexität (`originalSpeedLimits`-Table, `restoreAll` vor Save)
- `VehicleMotor.setSpeedLimit` wird von Giants AI, AD (`driveInDirection`) und CP jeden Frame aufgerufen → Hook greift automatisch, kein Save/Restore nötig

**Hook-Logik:**
1. `VehicleMotor.setSpeedLimit(self, superFunc, limit)` wird aufgerufen
2. `self.vehicle` → Worker ermitteln via `getWorkerForVehicle(vehicle)`
3. Wenn Worker zugewiesen UND `limit ~= math.huge` UND `limit > 0`: `limit = limit * speedMult`
4. `superFunc(self, limit)` — Original aufrufen mit modifiziertem Limit
5. Vorteil: Kein Save/Restore nötig — die KI ruft `setSpeedLimit` jeden Frame mit frischen Werten

**`onAIJobStarted` / `onAIJobStopped`** werden weiterhin für Worker-Zuweisung und Hotspot-Management genutzt (nicht mehr für Speed-Manipulation).

**Einheit:** `VehicleMotor.setSpeedLimit` erwartet km/h (wie `Vehicle.speedLimit`). Die KI übergibt z.B. 10 für Feldarbeit oder 50 für Transportfahrt.

### AutoDrive-Integration (`integration/advancedHelperAutoDriveHook.lua`)

**Config:** `advancedHelperConfig.INFILTRATE_AUTODRIVE = true/false`
- `true` (Default): AD wird ins Worker-System eingebunden (Hooks, Events, AD-Button im HUD)
- `false`: AD läuft unabhängig — nur minimale Event-Listener für `activeADCount` (damit `maxNumHirables` korrekt bleibt)

**Wichtig: An AutoDrive wird NICHTS geändert.** Alle Hooks greifen von außen.

#### Architektur (INFILTRATE_AUTODRIVE = true)

| Schicht | Mechanismus | Zweck |
|---------|------------|-------|
| **1. Zuweisen** | Event-Listener `onStartAutoDrive` (Vehicle-Event, `SpecializationUtil.registerEventListener`) | AD hat Helper zugewiesen → Worker über `helperIndex` finden → `isAssigned=true, assignedVehicle=vehicle` |
| **2. Notfall-Stopp** | Event-Listener `onStartAutoDrive` (Vehicle-Event) | Wenn kein Worker gefunden → deferred stop via `vehiclesToStop`-Queue + Counter dekrementieren + Notification |
| **3. Freigeben** | Event-Listener `onStopAutoDrive` (Vehicle-Event) | Worker freigeben (`isAssigned=false`) |

**Keine Blocking-Hooks mehr.** AD wird nicht mehr vornherein blockiert. Stattdessen: Wenn kein freier Worker verfügbar, wird AD nach dem Start per `onStartAutoDrive` Deferred-Stop gestoppt.

#### Worker-Zuweisung bei AD-Start

1. AD-Taste → `startAutoDrive()` aufgerufen (Server) → AD startet, holt Helper via `g_helperManager:getRandomHelper()`
2. **`onStartAutoDrive`** feuert
3. Worker über `vehicle.ad.stateModule:getCurrentHelperIndex()` finden
4. Wenn Worker gefunden → `worker.isAssigned = true, worker.assignedVehicle = vehicle`
5. Wenn kein Worker gefunden → Fahrzeug in `vehiclesToStop`-Queue (Deferred-Stop), Counter dekrementieren, Notification "Alle Arbeiter beschäftigt"
6. **`update(dt)`** ruft `processDeferredStops()` auf → setzt `vehicle.ad.isStoppingWithError = true` → `vehicle:stopAutoDrive()` (verhindert Handoff zu CP/AI)

#### Worker-Freigabe bei AD-Stopp

1. AD stoppt → `stopAutoDrive()` aufgerufen → `AutoDriveStartStopEvent` gesendet
2. **`onStopAutoDrive`** feuert (vor Helper-Release, Index noch verfügbar)
3. Worker über Index finden → `worker.isAssigned = false, worker.assignedVehicle = nil`
4. `advancedHelperHotspot:removeHotspot(vehicle)`

#### Attribut-Effekte bei AD-Fahrten

- **Sprit/Verschleiß/Geschwindigkeit**: Bestehende Hooks (`advancedHelperFuelHook`, `advancedHelperDamageHook`, `advancedHelperSpeedHook`) greifen universell — `getWorkerForVehicle(vehicle)` findet den zugewiesenen Worker. `VehicleMotor.setSpeedLimit` wird von AD jeden Frame aufgerufen.

#### HUD-Integration

- Kein AD-Button im HUD (AD startet nur über ADs eigenes Interface)
- `onStartAutoDrive` stoppt AD (deferred) wenn kein Worker gefunden/zugewiesen werden kann

#### Architektur (INFILTRATE_AUTODRIVE = false)

- Nur `onStartAutoDrive` / `onStopAutoDrive` als Zähler-Events registriert
- `activeADCount` wird hoch- und heruntergezählt
- `update(dt)` setzt `maxNumHirables = #hiredWorkers + activeADCount` (erlaubt AD eigene Helper)
- Kein AD-Button im HUD

#### AutoDrive-Events (unveränderter AD-Code)

| Event | Wann gefeuert | Wie registriert |
|-------|--------------|-----------------|
| `onStartAutoDrive` | Nach `startAutoDrive()` → Helper zugewiesen → `currentHelperIndex` gesetzt | `SpecializationUtil.registerEventListener(vehicleType, "onStartAutoDrive", advancedHelperAutoDriveHook)` |
| `onStopAutoDrive` | Nach `stopAutoDrive()` → vor Helper-Release | `SpecializationUtil.registerEventListener(vehicleType, "onStopAutoDrive", advancedHelperAutoDriveHook)` |

**Wichtig:** `self` im Event-Listener ist das **Vehicle** (SpecializationUtil Event-Listener Pattern). Access via `self.ad.stateModule:getCurrentHelperIndex()`.

#### Bekannte Gotchas

1. **`onStartAutoDrive` feuert NACH dem Start** — zu spät zum Blocken. Daher Deferred-Stop: Wenn kein freier Worker gefunden wird, wird AD nach dem Start per `vehicle:stopAutoDrive()` gestoppt.
2. **`onStopAutoDrive` feuert vor `releaseHelper`** — `currentHelperIndex` noch verfügbar.
3. **AD kann `maxNumHirables` via `checkAddHelper` erhöhen** — wird bei `INFILTRATE=true` durch Deferred-Stop kompensiert (Worker-Zuweisung schlägt fehl → AD wird gestoppt), bei `false` durch `activeADCount`-Zähler unterstützt.
4. **Fehlende Übersetzung für AD-Meldungen**: `advancedHelper_allWorkersBusy` in translations ergänzen.
5. **Keine `AutoDrive`-Klassenreferenz mehr nötig** — Alle Hooks sind Event-Listener (`SpecializationUtil.registerEventListener`), keine `Utils.overwrittenFunction` auf AD-Klassenmethoden. `getADClass()` und `checkAddHelperOverride` wurden entfernt.

### Courseplay-Integration (`integration/advancedHelperCourseplayHook.lua`)

**Config:** `advancedHelperConfig.INFILTRATE_COURSEPLAY = true/false`
- `true` (Default): CP wird ins Worker-System eingebunden (Hooks, Events, CP-Button im HUD)
- `false`: CP läuft unabhängig — nur `onCpFinished`-Zähler für `maxNumHirables`

**Wichtig: An Courseplay wird NICHTS geändert.** Alle Hooks greifen von außen.

#### Architektur (INFILTRATE_COURSEPLAY = true)

| Schicht | Mechanismus | Zweck |
|---------|------------|-------|
| **1. Freigeben** | Event-Listener `onCpFinished` / `onCpFuelEmpty` / `onCpBroken` (Vehicle-Events) | Worker freigeben (`isAssigned=false`) + Sync |
| **2. Programmatischer Start** | `startWorkerOnCP(workerId, vehicle)` | Worker zuweisen + `vehicle:cpStartStopDriver(true)` |

**Keine Blocking-Hooks mehr.** CP startet normal über sein eigenes Interface. Unser `aiJobStart`-Hook im Safeguard weist den Worker bei CP-Jobs zu.

#### CP-Stop Events

| Event | Wann gefeuert | Aktion |
|-------|--------------|--------|
| `onCpFinished` | CP-Job erfolgreich beendet | Worker freigeben + Sync |
| `onCpFuelEmpty` | CP stoppt weil Tank leer | Worker freigeben + Sync |
| `onCpBroken` | CP stoppt weil Fahrzeug beschädigt | Worker freigeben + Sync |

**Wichtig:** `self` im Event-Listener ist das Vehicle (SpecializationUtil Event-Listener Pattern).

#### HUD-Integration

- CP-Button pro Worker-Zeile: Grünes Play-Icon (Sprite `advancedHelperIcon.play`, `setColor(0.0, 0.8, 0.2, 0.95)`)
- Position: Links neben AD-Button (falls AD aktiv), sonst rechts neben Status-Text
- Aktiv: Worker frei + Fahrzeug hat CP-Spezialisierung + CP nicht aktiv + Kurs vorhanden
- Inaktiv (grau): Kein CP, CP läuft bereits, oder kein Kurs
- Klick: `advancedHelperCourseplayHook.startWorkerOnCP(workerId, vehicle)`

#### Architektur (INFILTRATE_COURSEPLAY = false)

- Nur `onCpFinished` als Zähler-Event registriert
- `activeCPCount` wird heruntergezählt bei CP-Finish
- `update(dt)` setzt `maxNumHirables = #hiredWorkers + activeADCount + activeCPCount` (erlaubt CP eigene Helper)
- Kein `cpStartStopDriver`-Hook, kein CP-Button im HUD

#### API-Funktion

```lua
advancedHelperAPI.startWorkerOnCP(workerId, vehicle, farmId)
```
Weist Worker zu, startet CP-Driver. Für andere Mods.

#### Bekannte Gotchas

1. **CP nutzt Giants AI-Job-System** — `CpAIJob:start()` holt `helperIndex` via `getRandomHelper()`. Unser `aiJobStart` Hook auf `AIJob.start` fängt CP-Jobs automatisch ein und weist den Worker zu.
2. **CP speichert `helperIndex` auf dem Job, nicht auf dem Vehicle** — im Gegensatz zu AD (`vehicle.ad.stateModule.currentHelperIndex`).
3. **`getCanStartAIVehicle` wird von CP NICHT überschrieben** — kein Konflikt mit unserem Hook.
4. **CP hat eigene `wageModifier` in `getPricePerMs`** — Chain mit unserem Hook funktioniert (beide `Utils.overwrittenFunction`).
5. **CP hat `Wheels.onUpdate`-Hook für Fruit Destruction** — Chain-kompatibel mit `Utils.overwrittenFunction`.
6. **CP ruft `vehicle:cpStartStopDriver(true)` im HUD** — sendet `AIJobStartRequestEvent` an Server → Server wählt zufälligen Helper → `aiJobStart` Hook weist Worker zu.
7. **CP `onCpFinished` feuert auf dem Vehicle** — muss als Vehicle-Event-Listener registriert werden (nicht `g_messageCenter`).
8. **Keine `CpAIWorker`-Klassenreferenz mehr nötig** — Alle Hooks sind Event-Listener (`SpecializationUtil.registerEventListener`), keine `Utils.overwrittenFunction` auf CP-Klassenmethoden. `getCPAIWorkerClass()` und `cpStartStopDriverOverride` wurden entfernt.

### Attribut-Formeln

| Attribut | Formel | Wert 1 | Wert 5 (neutral) | Wert 10 |
|----------|--------|--------|-------------------|---------|
| **Effizienz→Sprit** | `1 + deviation/scale * FUEL_MAX_PCT` (pos /4, neg /5) | +10% | ±0% | -10% |
| **Fahrweise→Tempo** | `1 - ((10-driving)/9) * SPEED_MAX_PCT` | -30% | 0% | 0% |
| **Können→Verschleiß** | `1 + deviation/scale * WEAR_MAX_PCT` (pos /4, neg /5) | +10% | ±0% | -10% |

**Config-Werte:** `FUEL_MAX_PERCENT=10`, `SPEED_MAX_PERCENT=30`, `WEAR_MAX_PERCENT=20`

**Sprit-Hook (`hooks/advancedHelperFuelHook.lua`):** `consumer.usage * fuelMult` vor `superFunc`, dann Original restore — KI-Kauf, Farm-Stats und FillLevel-Schwellen funktionieren korrekt. Greift immer wenn ein Worker zugewiesen ist (kein AI-Job-Check mehr).

**Verschleiß-Hook (`hooks/advancedHelperDamageHook.lua`):** `updateDamageAmount` und `getWearMultiplier` Hooks mit asymmetrischer Formel (gleich wie Sprit, aber WEAR_MAX_PERCENT=20). Greift immer wenn ein Worker zugewiesen ist (kein AI-Job-Check mehr).

### Bekannte Bugs & Fixes (Stand Mai 2026)
1. **ID-Kollision nach Load**: `advancedHelperWorker._idCounter` resetete auf 0 pro Session → neue Bewerber konnten gleiche IDs wie geladene Arbeiter erhalten. **Fix**: Nach `loadState()` wird `_idCounter = max(gespeicherte IDs)` gesetzt.
2. **`farmId` undefiniert im Fuel Hook**: Zeile 41 verwendete `farmId` ohne Definition. **Fix**: `vehicle:getOwnerFarmId()` verwenden.
3. **YesNoDialog Callback-Signatur**: `YesNoDialog.show(callback, target, text)` — Callback bekommt `(clickOk)` oder `(target, clickOk)`. Anonyme Funktionen fangen `self` fälschlich als ersten Parameter. **Fix**: Closure-Variablen statt `self` im Callback verwenden, `target=nil`.
4. **`FSBaseMission.INGAME_NOTIFICATION_CRITICAL`** (nicht `FSCurrentMission`!).
5. **`HelperManager.getRandomHelper()` crash**: Wenn `availableHelpers` leer → `math.random(1, 0)` crash. **Fix**: `advancedHelperHelperSafeguard` hooked `getRandomHelper` und `getRandomHelperStyle` mit Empty-Check.
6. **`maxNumHirables` Enforcement**: `0 >= 0 = true` bei `getAILimitedReached()` → blockiert Helfer korrekt. `update(dt)` setzt `maxNumHirables` jeden Frame zur Sicherheit.
7. **Per-Savegame Speicherung**: `loadMap()` wird VOR Savegame-Load aufgerufen → `savegameDirectory` ist noch `nil`. **Fix**: Daten in `init()` nicht laden; stattdessen `CURRENT_MISSION_START` Event abonnieren und dort `loadFromSavegame()` aufrufen. Speicherung via `saveState()` → `savegameDirectory/advancedHelper.xml`.
8. **`aiJobStart` Parameter-Reihenfolge**: `Utils.overwrittenFunction` übergibt `self` (AIJob-Instanz) als ersten Parameter, dann `superFunc`. **Fix**: Signatur muss `(self, superFunc, farmId)` sein, nicht `(superFunc, self, farmId)`.
9. **`g_currentMission:getBalance(farmId)` existiert NICHT** — Balance-Abfrage muss über `g_farmManager:getFarmById(farmId):getBalance()` erfolgen. `g_currentMission:getBalance()` ist keine gültige Methode.
10. **MoneyType + FinanceStats müssen via modDesc.xml geladen werden** — `source()` in `advancedHelperMain.lua` ist zu spät: `FinanceStats.new` wird vor `loadMap()` aufgerufen. `MoneyType.register()` und `statNamesI18n` müssen vorher gesetzt sein. **Fix**: `<sourceFile>` in `modDesc.xml` VOR `advancedHelperMain.lua`.
11. **Gehaltsabrechnung nicht in `update(dt)`** — `PERIOD_CHANGED` ist der korrekte Message-Typ für monatliche Abzüge (wie FieldLeasing). `update(dt)` wird jeden Frame aufgerufen.
12. **SmoothList 1-based indices**: FS25 `populateCellForItemInSection` übergibt `i` von 1 bis `numItems`.
13. **`doCheckSpeedLimit()` ist `false` bei AI_JOB_STARTED** — Gerät ist noch nicht abgesenkt/eingeschaltet. SpeedHook nutzt stattdessen `VehicleMotor.setSpeedLimit` Hook, der jeden Frame von der KI aufgerufen wird. Kein Save/Restore nötig.
14. **`Vehicle.speedLimit` Einheit ist km/h** — nicht m/s. `Cutter.getDefaultSpeedLimit()` gibt 10 (10 km/h).
15. **Traktoren haben `speedLimit = math.huge`** — kein Problem mehr, da `VehicleMotor.setSpeedLimit` Hook statt `Vehicle.speedLimit` verwendet wird. Der Motor-Hook greift für alle KI-Typen (Giants, AD, CP).
16. **`g_messageCenter:subscribe(MessageType.AI_JOB_STARTED/STOPPED)` feuert nur lokal** — nicht server→client oder client→server. SpeedHook braucht daher Server-Guard.
17. **`FSBaseMission.onConnectionFinishedLoading`** feuert auf dem Server wenn ein Client fertig geladen hat — der richtige Zeitpunkt für Initial-Sync. NICHT `MessageType.PLAYER_JOINED` (existiert nicht in FS25).
18. **`NetworkUtil.getObjectId()` / `NetworkUtil.getObject()`** für Vehicle-Referenzen im Stream — IDs sind nur während der Session gültig, nicht persistierbar.
19. **Clients haben keine `helperIndex`/`helperName`** — `applySyncState()` setzt beide auf nil. Nur der Server verwaltet `g_helperManager`.
20. **SP = Client+Server in einem** — Events werden lokal gesendet/empfangen. Alle Server-Guards funktionieren korrekt da `g_server ~= nil` in SP.
21. **`helper.name` vs `helper.title` auf der Minimap** — C++ `VehicleHotspot` zeigt `helper.name` (GROSSBUCHSTABEN) auf der Minimap, nicht `helper.title`. `AIJob:getHelperName()` und `AIJob:getTitle()` geben `helper.title` zurück (für Notifications/IngameMenu). **Fix**: `advancedHelperManager:formatHelperName(worker)` erzeugt lesbaren Namen im Format `VORNAME_NACHNAME` (Umlaute konvertiert, Duplikate mit Zähler-Suffix `_2`, `_3`). `addHelper(name, title, ...)` erhält `formatHelperName()` als `name` und `worker:getFullName()` als `title`. `ClassUtil.getIsValidIndexName()` validiert `name` — erlaubt Buchstaben, Ziffern, Unterstrich, erster Char kein Ziffer.

---

## FS25 Lua Scripting Referenz

### NICHT verfügbar (GIANTS Sandbox)

Standard Lua Libraries sind **nicht** zugänglich:

| Feature | Status | Ersatz |
|---------|--------|--------|
| `io.open` / `io.read` / `io.write` | **UNVERFÜGBAR** | `XMLFile`/`XMLSchema`, `createFile()` |
| `os.execute` / `os.getenv` | **UNVERFÜGBAR** | Kein Ersatz |
| `os.clock` | **UNVERFÜGBAR** | `getTime()` |
| `os.time` / `os.date` | **UNVERFÜGBAR** | `getDate("%Y/%m/%d %H:%M")` |
| `require()` | **UNVERFÜGBAR** | `source(filename, modEnv)` |
| `dofile()` / `loadfile()` | **UNVERFÜGBAR** | `source()` |
| `coroutine` library | **UNVERFÜGBAR** | `g_asyncTaskManager` |
| `package` library | **UNVERFÜGBAR** | - |
| `goto` statement | **UNVERFÜGBAR** | Boolean-Flags/Loops |

### Verfügbare GIANTS Globals

| Global | Zweck |
|--------|-------|
| `g_currentMission` | Aktive Mission - zentraler Zugriffspunkt |
| `g_currentMission.environment` | Zeit/Wetter-System |
| `g_currentMission.missionInfo` | Schwierigkeit, Einstellungen |
| `g_currentMission.aiSystem` | KI/Helfer-System |
| `g_helperManager` | Helfer-Management (addHelper, getRandomHelper) |
| `g_client` | Client-Netzwerk |
| `g_server` | Server-Netzwerk |
| `g_fillTypeManager` | FillType-Verwaltung |
| `g_storeManager` | Shop-Items |
| `g_soundManager` | Audio |
| `g_messageCenter` | Event-Bus (Publish/Subscribe) |
| `g_gameStateManager` | Spielzustand |
| `g_inputBinding` | Eingabe/Aktionen |
| `g_gui` | GUI-Controller (showGui, loadGui, showDialog) |
| `g_i18n` | Lokalisierung (getText, formatMoney) |
| `g_localPlayer` | Lokaler Spieler |
| `g_currentModName` | Name des aktuellen Mods (nur während Laden) |
| `g_currentModDirectory` | Pfad des aktuellen Mods (nur während Laden) |
| `g_modIsLoaded` | Tabelle `{modName=true}` |
| `g_inGameMenu` | Das ESC-InGameMenu (TabbedMenu) |
| `g_farmlandManager` | Landbesitz |
| `g_farmManager` | Farm-Verwaltung (getFarmById, getBalance) |
| `g_terrainNode` | Terrain-Root-Node |
| `g_farmId` | Aktuelle Farm-ID |
| `g_baseUIFilename` | C++ Global — Pfad zur Base-UI-Textur (weißes Pixel) für Overlay.new() |
| `g_colorBgUVs` | C++ Global — UV-Koordinaten des weißen Pixels in g_baseUIFilename |

### Environment/Zeit-System (`g_currentMission.environment`)

| Property | Typ | Beschreibung |
|----------|-----|-------------|
| `currentDay` | int | Aktueller Spieltag |
| `currentHour` | number | Aktuelle Stunde (0-23) |
| `currentMinute` | number | Aktuelle Minute |
| `currentMonth` | int | Aktueller Monat (für Gehaltsabrechnung nutzen) |
| `currentSeason` | Season | Season enum (SPRING/SUMMER/AUTUMN/WINTER) |
| `currentPeriod` | int | Periode innerhalb Saison |
| `dayTime` | number | Tageszeit in ms |
| `isSunOn` | boolean | Sonne auf/untergangen |

**WICHTIG:** `g_currentMission:getCurrentDay()` existiert NICHT! Korrekt: `g_currentMission.environment.currentDay`

### Schwierigkeitsgrade

```lua
g_currentMission.missionInfo.economicDifficulty  -- 1=Einfach, 2=Normal, 3=Schwer
g_currentMission.missionInfo.fuelUsage            -- 1=Niedrig, 2=Mittel, 3=Hoch
```

### Geld-System

```lua
-- Geld abziehen/hinzufügen (pro Farm):
g_currentMission:addMoney(amount, farmId, moneyType, showChange, showNotification)
g_currentMission:addMoney(-500, farmId, MoneyType.WORKER_SALARY, true, true)

-- Farm-Balance abfragen (NICHT g_currentMission:getBalance!):
local farm = g_farmManager:getFarmById(farmId)
if farm ~= nil then
    local balance = farm:getBalance()
end

-- Aktuelle Farm-ID:
local farmId = g_currentMission:getFarmId()

-- WICHTIG: g_currentMission:getBalance() existiert NICHT!
-- Korrekt: g_farmManager:getFarmById(farmId):getBalance()

-- Geld formatieren:
g_i18n:formatMoney(amount)
```

**MoneyType-Werte:** `PROPERTY_MAINTENANCE`, `SHOP_VEHICLE_SELL`, `HARVEST_INCOME`, `AI`, `VEHICLE_RUNNING_COSTS`, `VEHICLE_REPAIR`, `OTHER`, `PURCHASE_FUEL`, `LEASING_COSTS`, `MISSIONS`, **`WORKER_SALARY`** (eigener MoneyType via `MoneyType.register`)

**MoneyType registrieren (NUR via modDesc.xml sourceFile!):**
```lua
-- lifecycle/advancedHelperMoneyType.lua (wird via modDesc.xml VOR advancedHelperMain.lua geladen)
local modName = g_currentModName
MoneyType.WORKER_SALARY = MoneyType.register("statisticWorkerSalary", "moneyTypeWorkerSalary", modName)
```

**FinanceStats erweitern (NUR via modDesc.xml sourceFile!):**
```lua
-- lifecycle/advancedHelperFinanceStats.lua (wird via modDesc.xml VOR advancedHelperMain.lua geladen)
table.insert(FinanceStats.statNames, "statisticWorkerSalary")
FinanceStats.statNameToIndex["statisticWorkerSalary"] = #FinanceStats.statNames

function advancedHelperFinanceStats.new(self, superFunc, customMt)
    local returnValue = superFunc(self, customMt)
    FinanceStats.statNamesI18n["statisticWorkerSalary"] = g_i18n:getText("statisticWorkerSalary")
    return returnValue
end
FinanceStats.new = Utils.overwrittenFunction(FinanceStats.new, advancedHelperFinanceStats.new)
```

### Helper-Manager API

```lua
g_helperManager:addHelper(name, title, color, playerStyle, baseDir, isBaseType)
-- WICHTIG: 'name' wird per string.upper() in GROSSBUCHSTABEN konvertiert und ist der interne Schlüssel.
-- 'name' wird auf der Minimap angezeigt (C++ VehicleHotspot zeigt helper.name, NICHT helper.title).
-- 'title' wird von AIJob:getHelperName()/AIJob:getTitle() für Notifications und IngameMenu zurückgegeben.
-- ClassUtil.getIsValidIndexName(name) validiert 'name' — erlaubt: Buchstaben, Ziffern, Unterstrich.
g_helperManager:getRandomHelper()
g_helperManager.numHelpers              -- Gesamtzahl
g_helperManager.availableHelpers        -- Tabelle der verfügbaren Helfer
g_helperManager.helpers                 -- Alle Helfer (Key: NAME in Grossbuchstaben)
g_helperManager.nameToIndex             -- Name -> Index
```

### Fahrzeug-Hooks (Utils.overwrittenFunction)

```lua
-- Funktion überschreiben (Original wird als superFunc übergeben):
SomeClass.methodName = Utils.overwrittenFunction(SomeClass.methodName, myOverride)

-- In der Override-Funktion:
function myOverride.superFunc(self, ...)
    superFunc(self, ...)  -- Original aufrufen
    -- eigener Code
end

-- Angehängt/vorangestellt:
SomeClass.methodName = Utils.appendedFunction(SomeClass.methodName, myFunc)
SomeClass.methodName = Utils.prependedFunction(SomeClass.methodName, myFunc)
```

### Fahrzeug-Spezialisierungen prüfen

```lua
vehicle.spec_aiVehicle          -- KI-Fahrzeug Spezialisierung
vehicle.spec_motorized          -- Motorisiert Spezialisierung
vehicle.spec_wearable           -- Verschleiß Spezialisierung
vehicle:getVehicleDamage()      -- Schadenswert 0-1
vehicle:getIsSynchronized()     -- Netzwerk-Sync-Check
vehicle:getOwnerFarmId()        -- Farm-Zugehörigkeit des Fahrzeugs
```

### AIJob Hooks (wichtig für getPricePerMs)

```lua
-- AIJob hat self.startedFarmId — die Farm die den Job gestartet hat
-- getPricePerMs kann hierauf zugreifen:
function advancedHelperHelperSafeguard.getPricePerMs(self, superFunc)
    if #advancedHelperManager.hiredWorkers > 0 then
        local farmId = self.startedFarmId
        if farmId ~= nil and advancedHelperManager:getWorkerCountForFarm(farmId) > 0 then
            return 0  -- Arbeiter dieser Farm zahlt kein laufendes Geld
        end
    end
    return superFunc(self)  -- Ohne Arbeiter: normale AI-Kosten
end

-- AIJob.updateCost verwendet getPricePerMs:
-- price = self:getPricePerMs() * dt * EconomyManager.getCostMultiplier()
-- Wird von AIJob:updateCost(dt) alle dt ms aufgerufen
```

### Datei I/O

**XML (bevorzugt - XMLFile + XMLSchema):**
```lua
local schema = XMLSchema.new("myMod")
schema:register(XMLValueType.INT, "myMod.data#value", 0)
schema:register(XMLValueType.STRING, "myMod.data#name", "")
schema:register(XMLValueType.BOOL, "myMod.data#enabled", false)

-- Lesen:
local xmlFile = XMLFile.loadIfExists("tag", "path/file.xml", schema)
if xmlFile then
    local val = xmlFile:getInt("myMod.data#value")
    xmlFile:delete()  -- IMMER aufräumen!
end

-- Schreiben:
local xmlFile = XMLFile.create("tag", "path/file.xml", "myMod", schema)
xmlFile:setInt("myMod.data#value", 42)
xmlFile:save()
xmlFile:delete()
```

**Persistenz-Pfade:**
```lua
-- Per-Savegame (bevorzugt - pro Spielstand):
local saveDir = g_currentMission.missionInfo.savegameDirectory .. "/"
-- Datei: saveDir .. "advancedHelper.xml"

-- Fallback (nur wenn savegameDirectory nil ist):
local fallbackDir = getUserProfileAppPath() .. "modSettings/FS25_AdvancedHelper/"
```

**Legacy C-XML API (noch verfügbar, aber veraltet):**
```lua
local xmlFile = loadXMLFile("tag", "path.xml")
local val = getXMLInt(xmlFile, "root.element#attr")
setXMLInt(xmlFile, "root.element#attr", 42)
saveXMLFile(xmlFile)
delete(xmlFile)
```

### GUI-System

**Verfügbare Basis-Klassen:**
| Klasse | Zweck |
|--------|-------|
| `TabbedMenu` | Multi-Tab Vollbildmenü (wie InGameMenu) |
| `TabbedMenuFrameElement` | Einzelner Tab/Seite |
| `ScreenElement` | Vollbild-Ansicht |
| `DialogElement` | Modal-Dialog |
| `FrameElement` | Frame/Panel |
| `TextElement` | Textanzeige |
| `BitmapElement` | Bildanzeige |
| `ButtonElement` | Klick-Button |
| `TextInputElement` | Texteingabe |
| `SliderElement` | Schieberegler |
| `SmoothListElement` | Scroll-Liste |
| `BoxLayoutElement` | Layout-Container |
| `PagingElement` | Seiten-Navigation |
| `FocusManager` | Tastatur/Gamepad-Fokus |
| `BinaryOptionElement` | Ja/Nein-Schalter |
| `MultiTextOptionElement` | Dropdown-Auswahl |

**GUI Laden/Anzeigen:**
```lua
g_gui:loadGui(xmlPath, screenName, controller, isFrame)
g_gui:showGui("ScreenName")
g_gui:showDialog("DialogName")
g_gui:loadProfiles(profilesXmlPath)
```

**InGameMenu Tab hinzufügen (Pattern):**
```lua
-- 1. GUI laden
g_gui:loadGui(modDir.."config/gui/myPage.xml", "myPageName", myPageController, true)

-- 2. Seite zum pagingElement hinzufügen
g_inGameMenu.pagingElement:addElement(myPage)

-- 3. Seite registrieren + Tab hinzufügen
g_inGameMenu:registerPage(myPage, position, enablePredicate)
g_inGameMenu:addPageTab(myPage, iconFilename, iconUVs, sliceId)

-- 4. Tab-Liste neu aufbauen
g_inGameMenu:rebuildTabList()
```

**GUI Profile (fs25_ Prefix):**
FS25 GUI-Profile verwenden den Prefix `fs25_`:
`fs25_fullScreenBackground`, `fs25_menuContainer`, `fs25_menuHeaderPanel`, `fs25_menuHeaderText`, `fs25_tabList`, `fs25_tabListItem`, `fs25_horizontalBoxLayout`, `fs25_buttonBox`, `fs25_bottomPanel`, `fs25_infoText`, `buttonPrimary`, `buttonSecondary`, `buttonBack`

### Netzwerk/Multiplayer Events

```lua
-- Event-Klasse definieren:
MyEvent = {}
MyEvent_mt = Class(MyEvent, Event)
InitEventClass(MyEvent, "MyEvent")

function MyEvent.emptyNew()
    return Event.new(MyEvent_mt)
end

function MyEvent.new(data)
    local self = MyEvent.emptyNew()
    self.data = data
    return self
end

function MyEvent:readStream(streamId, connection)
    self.data = streamReadBool(streamId)
    self:run(connection)
end

function MyEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.data)
end

function MyEvent:run(connection)
    -- Auf Empfängerseite ausführen
end

-- Senden:
if g_server then
    g_server:broadcastEvent(MyEvent.new(data), nil, nil, vehicle)
else
    g_client:getServerConnection():sendEvent(MyEvent.new(data))
end
```

### ModEventListener (für Script-Mods)

```lua
MyMod = {}

function MyMod:loadMap()
    -- Initialisierung
end

function MyMod:deleteMap()
    -- Aufräumen
end

function MyMod:update(dt)
    -- Frame-Update
end

function MyMod:dayChanged()
    -- Wenn ein neuer Spieltag beginnt
end

addModEventListener(MyMod)
```

### GIANTS Engine Extensions (nicht Standard-Lua)

| Funktion | Beschreibung |
|----------|-------------|
| `source(filename, env)` | Lua-Datei laden (statt `require`) |
| `getTime()` | Engine-Zeit (statt `os.clock`) |
| `getDate(format)` | Datum/Zeit (statt `os.date`) |
| `getDateDiffSeconds(...)` | Datumsdifferenz |
| `getMD5(str)` | MD5-Hash |
| `printCallstack()` | Stack-Trace (statt `debug.traceback`) |
| `math.clamp(val, min, max)` | Clamp (GIANTS-Erweiterung) |
| `string.isNilOrWhitespace(s)` | String-Check |
| `table.clone(t)` | Tiefe Kopie |
| `table.removeElement(t, el)` | Element entfernen |
| `MathUtil.round(v)` | Runden |
| `MathUtil.lerp(a, b, t)` | Lineare Interpolation |
| `bitAND`, `bitOR`, `bitXOR`, `bitNOT` | Bit-Operationen |
| `bitShiftLeft`, `bitShiftRight` | Bit-Shift |
| `createFolder(path)` | Ordner erstellen |
| `createFile(path, access)` | Datei erstellen |
| `Files.getFilesRecursive(path)` | Verzeichnis auflisten |

### Bekannte Fehlerquellen (Gotchas)

1. **`g_currentMission:getCurrentDay()` gibt es NICHT** -> `g_currentMission.environment.currentDay`
2. **`io.open` gibt es NICHT** -> `XMLFile`/`XMLSchema` verwenden
3. **`require()` gibt es NICHT** -> `source()` verwenden
4. **XMLFile-Handle IMMER mit `xmlFile:delete()` aufräumen** -> sonst Handle-Leak -> Crash
5. **`g_currentModDirectory` ist nil nach Lade-Phase** -> in lokale Variable speichern
6. **Bei Specialistions ist `self` das Fahrzeug** -> Spezialisierungsdaten via `self.spec_mySpec`
7. **Nur ZIP-Mods funktionieren im Multiplayer** -> Ordner-Mods nur im Singleplayer
8. **Jede Action braucht l10n-Eintrag** -> Format: `input_<ACTIONNAME>` in translations
9. **`goto` ist in FS25 Lua verboten** -> Boolean-Flags/Loops verwenden
10. **XMLSchema-Validierung ist strikt in FS25** -> Schema immer in `initSpecialization()` registrieren
11. **`callbackState == 2` bedeutet Hold-Action** (nicht 1)
12. **`setClipRect`/`removeClipRect` sind nil in der Sandbox**
13. **`YesNoDialog.show(callback, target, text)`** — Callback-Signatur: `function(clickOk)` wenn `target=nil`, oder `function(self, clickOk)` wenn `target=self`. **IMMER `target` explizit setzen!**
14. **Ingame-Notification**: `FSBaseMission.INGAME_NOTIFICATION_CRITICAL` / `INGAME_NOTIFICATION_OK` / `INGAME_NOTIFICATION_INFO` (NICHT `FSCurrentMission`!)
15. **`g_messageCenter:subscribe(MessageType.DAY_CHANGED, callback, target)`** — Zuverlässiger als `addModEventListener` `dayChanged` für Tag-Wechsel
16. **`g_currentMission:getBalance(farmId)` existiert NICHT** — korrekt: `g_farmManager:getFarmById(farmId):getBalance()`
17. **`MoneyType.register()` und `FinanceStats`-Erweiterung müssen via `modDesc.xml <sourceFile>` geladen werden** — `source()` in `advancedHelperMain.lua` ist zu spät, da `FinanceStats.new` beim Mission-Start aufgerufen wird
18. **`MessageType.PERIOD_CHANGED`** für monatliche Abzüge (nicht `update(dt)` oder `MONTH_CHANGED`)
19. **`FarmManager.SINGLEPLAYER_FARM_ID`** ist die Standard-farmId für Singleplayer (Wert: 1)
20. **`g_currentMission:getFarmId()`** gibt die Farm-ID des lokalen Spielers zurück
21. **`Overlay.new(nil, ...)` erzeugt `overlayId = 0`** — `Overlay:render()` überspringt wenn `overlayId == 0`. Statt `nil` muss `g_baseUIFilename` (C++ Global, Base-UI-Textur) verwendet werden, plus `overlay:setUVs(g_colorBgUVs)` für korrekte UV-Koordinaten. Fallback: `'dataS/menu/base/graph_pixel.png'`. Pattern wie Courseplay (`CpBaseHud.lua:107`, `CpHudInfoTexts.lua:53-54`).
22. **`new2DLayer()` MUSS vor HUD-Rendering aufgerufen werden** — AutoDrive und CP rufen `new2DLayer()` auf bevor sie Overlays rendern (AD `Hud.lua:373`, CP `CpInGameMenu.lua:320`). Ohne diesen Aufruf werden Overlays möglicherweise nicht auf der 2D-UI-Layer gezeichnet.
23. **HUD-Overlays in `init()` erstellen, nicht per-Frame** — CP und AD erstellen Overlays einmalig in `init()` und mutieren sie (setPosition, setDimension, setColor, render) jeden Frame. Kein Temp-Overlay-Pool Pattern. Siehe `CpHudInfoTexts:init()` (Zeilen 53-107).
24. **`g_colorBgUVs` Fallback** — C++ Global, kann nil sein in bestimmten Lade-Phasen. Fallback: `{0, 0, 1, 0, 1, 1, 0, 1}` (Standard-UVs für ganzes Bild).
25. **`addModEventListener:draw()` wird VOR `VehicleSystem:draw()` aufgerufen** — Mod-EventListener `draw()` und Vehicle-`onDrawUIInfo()` sind unterschiedliche Rendering-Pipelines. HUD via `addModEventListener` funktioniert auch wenn kein Fahrzeug aktiv.
26. **`renderText(x, y, fontSize, text)` erwartet normalisierte Font-Größe (~0.01-0.02), NICHT Pixel** — CP nutzt `self:scalePixelToScreenHeight()`, AD nutzt `0.011 * uiScale`. Immer `getCorrectTextSize(fontSize * uiScale)` verwenden um UI-Skalierung zu berücksichtigen.
27. **FS25-Font unterstützt keine Unicode-Sonderzeichen** — `▶` (U+25B6) und `■` (U+25A0) produzieren `Character '9654' not found in texture font`. Statt Unicode ASCII nutzen: `>>` für Start, `||` für Stop.
28. **Mauszeiger in FS25 standardmäßig ausgeblendet** — `g_inputBinding:setShowMouseCursor(true)` MUSS aufgerufen werden wenn HUD sichtbar ist, sonst kann der Nutzer keine Buttons klicken. AD prüft zusätzlich `g_inputBinding:getShowMouseCursor()`. In `hide()` muss `setShowMouseCursor(false)` aufgerufen werden.
29. **`g_currentMission.controlledVehicle` existiert NICHT** — Der Spielcode nutzt `g_localPlayer:getCurrentVehicle()` um das aktuell gesteuerte Fahrzeug zu ermitteln. `g_currentMission.controlledVehicle` ist immer `nil`. CP nutzt `CpUtil.getCurrentVehicle()` (die `g_localPlayer:getCurrentVehicle()` aufruft), AD nutzt `AutoDrive.getControlledVehicle()` (die ebenfalls `g_localPlayer:getCurrentVehicle()` aufruft). IMMER `g_localPlayer:getCurrentVehicle()` verwenden!

---

## Offizielle GIANTS Dokumentation

| Ressource | URL |
|-----------|-----|
| GDN Hauptseite | https://gdn.giants-software.com/ |
| Dokumentations-Hub | https://gdn.giants-software.com/documentation.php |
| **FS25 Lua Script API** | https://gdn.giants-software.com/documentation_scripting_fs25.php |
| Scripting Tutorials | https://gdn.giants-software.com/tutorials.php |
| Debugger/Studio Docs | https://gdn.giants-software.com/debugger.php |
| Forum | https://gdn.giants-software.com/forum.php |
| Downloads (Editor, TestRunner, eBooks) | https://gdn.giants-software.com/downloads.php |
| ModDesc Validation Schema | `dataS/schemas/modDesc.xsd` (im Spielverzeichnis) |
| modDesc XSD online | https://validation.gdn.giants-software.com/xml/fs25/modDesc.xsd |

**Hinweis:** Die meisten GDN-Seiten erfordern kostenlose Registrierung.

### Lokale Spielquellen (für Referenz)
- **Game Source:** `dataS/scripts/` (im Spielverzeichnis oder SDK debugger/gameSource.zip)
- **GUI Base Classes:** `dataS/scripts/gui/base/TabbedMenu.lua`, `dataS/scripts/gui/InGameMenu.lua`
- **Vehicle Spec:** `dataS/scripts/vehicles/specializations/Motorized.lua`, `Wearable.lua`, `VehicleMotor.lua`
- **Helper System:** `dataS/scripts/ai/HelperManager.lua`
- **AIJob:** `dataS/scripts/ai/jobs/AIJob.lua` (getPricePerMs, updateCost, startedFarmId)
- **AIJobFieldWork:** `dataS/scripts/ai/jobs/AIJobFieldWork.lua` (getPricePerMs = 0.0005)
- **AIJobConveyor:** `dataS/scripts/ai/jobs/AIJobConveyor.lua` (getPricePerMs = 0.00005)
- **SDK/Debugger:** `steamapps/common/Farming Simulator 25/sdk/debugger/`
- **FieldLeasing Referenz:** mods/FS25_FieldLeasing/ (MoneyType, FinanceStats, PERIOD_CHANGED, farmId)

### FS25 vs FS22 Wichtige Unterschiede

| Feature | FS22 | FS25 |
|---------|------|------|
| ModDesc Version | ~70-77 | **108** |
| XML API | Legacy C-Funktionen | **XMLFile + XMLSchema** (bevorzugt) |
| Engine | 9.x | **10.0.0** |
| GUI Profile Prefix | `ui_` | **`fs25_`** |
| Rendering | DX11 | **DX12** |
| Spezialisierung Laden | Synchron | **Async (g_asyncTaskManager)** |
| `source()` | Verfügbar | Verfügbar (gleich) |
