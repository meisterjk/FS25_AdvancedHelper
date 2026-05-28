# Advanced Helper

A Farming Simulator 25 mod that replaces the default AI helper system with a full employee management system. Hire workers with unique skills that affect fuel consumption, driving speed, and vehicle wear.

## Features

- **Employee Management** — Hire and fire workers with procedurally generated names and attributes
- **3 Skill Attributes** (scale 1–10):
  - **Efficiency** — Affects fuel consumption (±10%)
  - **Driving** — Affects working speed (up to −30%)
  - **Skill** — Affects vehicle wear (±20%)
- **HUD Overlay** — See all hired workers, their assignment status, and vehicle info. Toggle with Ctrl+RightH.
- **Monthly Payroll** — Workers are paid automatically each month, per-farm billing
- **Finance Overview Integration** — Worker salaries appear in the farm finance stats
- **Courseplay Integration** — Optional, enabled by default. CP job starts are blocked when no free workers are available. Workers are automatically assigned to CP jobs.
- **AutoDrive Integration** — Optional, enabled by default. AD starts are blocked when no free workers are available. Workers are automatically assigned to AD vehicles.
- **Multiplayer** — Full sync architecture, server-authoritative, all operations via network events
- **API for other mods** — Query workers, start/stop them, subscribe to events

## Installation

1. Download the latest release from GitHub
2. Copy `FS25_AdvancedHelper` into your `mods/` directory
3. Activate the mod in the FS25 mod menu before loading a savegame

> Requires at least one hired worker to start AI jobs (standard AI, Courseplay, or AutoDrive).

## Controls

| Action | Default Binding |
|--------|----------------|
| Toggle HUD overlay | Ctrl + RightH |
| Toggle HUD cursor | Middle Mouse Button |

## Usage

### HUD

The HUD shows all hired workers for your farm:

- **Status column** — Shows `Active` for assigned workers (with `(CP)` or `(AD)` suffix when driven by Courseplay/AutoDrive), `Free` for available workers
- **Play button** — Start a free worker on a vehicle (opens vehicle selection for Giants AI jobs)
- **Stop button** — Stop and unassign a worker

### InGame Menu

Open the ESC menu and find the "Advanced Helper" tab:

- **Employees tab** — Overview of all hired workers, their attributes, salary, and assignment status. Dismiss workers here.
- **Applicants tab** — Browse available applicants. New applicants appear every 3 days. Click "Refresh" to generate new ones instantly (costs money).

## Configuration

Edit `scripts/advancedHelperConfig.lua` to adjust:

```lua
advancedHelperConfig = {
    FUEL_MAX_PERCENT = 10,       -- Max fuel consumption deviation
    SPEED_MAX_PERCENT = 30,      -- Max speed reduction
    WEAR_MAX_PERCENT = 20,       -- Max wear deviation
    INFILTRATE_AUTODRIVE = true,  -- AutoDrive integration
    INFILTRATE_COURSEPLAY = true, -- Courseplay integration
    DEBUG = true,                 -- Enable debug logging
}
```

## Dependencies

- **Courseplay** (optional) — Download from [courseplay.dev](https://courseplay.dev)
- **AutoDrive** (optional) — Download from GitHub

Both are auto-detected. Integration is fully optional and can be disabled in config.

## Multiplayer

Fully multiplayer-compatible. Architecture:

- **Server-authoritative** — All state changes happen on the server
- **Full Sync** — Complete state broadcast on every change (small data set: ~20 workers + 5 applicants)
- **Client Join** — Initial sync on connection
- **Events** — All actions (hire, fire, start worker, etc.) are sent as network events

## API for other mods

```lua
if advancedHelperAPI and advancedHelperAPI.isLoaded() then
    -- Query workers
    local workers = advancedHelperAPI.getFreeWorkers(farmId)
    
    -- Start a worker
    advancedHelperAPI.startWorker(workerId, vehicle, farmId)
    
    -- Subscribe to events
    advancedHelperAPI.subscribe("workerAssigned", function(data, vehicleName)
        print(data.firstName .. " assigned to " .. vehicleName)
    end)
end
```

See `scripts/advancedHelperAPI.lua` for full documentation.

## Translations

- English (built-in)
- German (built-in)

Add your own translations by creating `translations/translation_XX.xml`.

## Development

This is a script mod — no dedicated SDK required. All source files are in `scripts/`.

### File Structure

```
FS25_AdvancedHelper/
├── modDesc.xml
├── icon_advancedHelper.dds
├── scripts/
│   ├── advancedHelperMain.lua           (Entry point, init, hooks)
│   ├── advancedHelperWorker.lua         (Worker data class)
│   ├── advancedHelperManager.lua        (Hire/fire, persistence, sync)
│   ├── advancedHelperEvents.lua         (Network events)
│   ├── advancedHelperConfig.lua         (Configuration)
│   ├── advancedHelperDebug.lua          (Debug logging)
│   ├── advancedHelperAPI.lua            (External API)
│   ├── advancedHelperPayroll.lua        (Monthly salary)
│   ├── advancedHelperMoneyType.lua      (MoneyType registration)
│   ├── advancedHelperFinanceStats.lua   (Finance stats integration)
│   ├── advancedHelperFuelHook.lua       (Fuel consumption hook)
│   ├── advancedHelperSpeedHook.lua      (Speed limit hook)
│   ├── advancedHelperDamageHook.lua     (Vehicle wear hook)
│   ├── advancedHelperHelperSafeguard.lua (AI helper hooks)
│   ├── advancedHelperCourseplayHook.lua (CP integration)
│   ├── advancedHelperAutoDriveHook.lua  (AD integration)
│   └── hud/
│       └── advancedHelperHud.lua        (HUD overlay)
├── gui/
│   ├── advancedHelperInGameMenuIntegration.lua
│   └── advancedHelperPage.lua
├── config/gui/
│   ├── advancedHelperPage.xml
│   └── guiProfiles.xml
└── translations/
    ├── translation_en.xml
    └── translation_de.xml
```

## Changelog

### 0.3.0
- Full rename from mj_Workers to AdvancedHelper
- Courseplay and AutoDrive integration
- HUD overlay with worker status
- Decoupled HUD/cursor controls
- Multiplayer sync architecture
- External API for other mods

### 0.2.0
- Monthly payroll system
- Finance stats integration
- Bug fixes for multiplayer

### 0.1.0
- Initial release as mj_Workers
- Basic worker hire/fire
- Fuel, speed, wear hooks

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Credits

- **Author:** mj
- Courseplay integration uses the [Courseplay](https://courseplay.dev) API
- AutoDrive integration uses the [FS25_AutoDrive](https://github.com/Stephan-E/FS25_AutoDrive) API
