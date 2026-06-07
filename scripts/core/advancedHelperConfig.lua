advancedHelperConfig = {
    -- Spritverbrauch: Max. Abweichung in Prozent
    -- efficiency 1 = +X% Verbrauch, efficiency 10 = -X% Verbrauch
    FUEL_MAX_PERCENT = 10,

    -- Arbeitsgeschwindigkeit: Max. Reduktion in Prozent
    -- driving 1 = -X% Arbeitstempo, driving 10 = unverändert (kein Bonus)
    SPEED_MAX_PERCENT = 30,

    -- Verschleiß: Max. Abweichung in Prozent
    -- skill 1 = +X% Verschleiß, skill 10 = -X% Verschleiß
    WEAR_MAX_PERCENT = 20,

    -- AutoDrive-Integration: true = AD wird ins Worker-System eingebunden
    -- (AD-Start blockiert wenn keine freien Worker, Worker-Zuweisung, Attribut-Effekte)
    -- false = AD laeuft unabhaengig, keine Hooks, kein AD-Button im HUD
    INFILTRATE_AUTODRIVE = true,

    -- Courseplay-Integration: true = CP wird ins Worker-System eingebunden
    -- (CP-Start blockiert wenn keine freien Worker, Worker-Zuweisung, CP-Button im HUD)
    -- false = CP laeuft unabhaengig, nur CP-Counter fuer maxNumHirables
    INFILTRATE_COURSEPLAY = true,

    DEBUG = false,
}