1. **Create Configuration File:**
   - Create a JSON file `res://buildings_config.json` that will store the configurable allowed buildings per campaign and mission.
   - Example format:
     ```json
     {
       "0": {
         "0": [
           "Potato Farm",
           "Clay Pit",
           "Pottery House",
           "Warehouse",
           "Cooking Den",
           "House"
         ],
         "1": [
           "Carrot Farm",
           "Potato Farm",
           "Clay Pit",
           "Pottery House",
           "Warehouse",
           "Cooking Den",
           "House"
         ]
       }
     }
     ```
   - The prompt says "on mission 1 all but carrot farm should be available", and "on mission 2 all current buildings should be available". Since by default buildings should be available if not specified, we can configure only mission 0 of campaign 0 in `buildings_config.json`, and if mission 1 isn't configured, it will default to all buildings. Wait, I'll just write both for explicitness, or only write mission 1 without Carrot Farm. Actually, I can just not configure mission 1, so it allows all. Let's write them both.

2. **Update `Global.gd`:**
   - Add `var available_buildings_config: Dictionary = {}`
   - Create `load_buildings_config()` that parses `res://buildings_config.json` into `available_buildings_config`. Call this in `_ready()`.
   - Create `func is_building_available(campaign_idx: int, mission_idx: int, building_name: String) -> bool:`
     - Inside, if the config has an entry for `str(campaign_idx)` -> `str(mission_idx)`, then return `building_name in entry`.
     - Else, return `true` (default available).

3. **Update `scenes/build_ui.gd`:**
   - Add a `_ready()` function.
   - Loop over building buttons. To do this systematically without hardcoding every button name, we can check node names or use an exported dictionary, or just iterate children of `VBoxContainer` that are Buttons but not the "Destroy" button.
   - The buttons are:
     `CarrotFarmButton`, `PotatoFarmButton`, `ClayPitButton`, `PotteryHouseButton`, `WarehouseButton`, `CookingDenButton`, `HouseButton`.
   - Hide buttons where `Global.is_building_available(Global.current_campaign_idx, Global.current_mission_idx, "Building Name")` is false.
   - I can create a mapping of node name or just button text to building name. E.g. Button.text is exactly the building name like "Carrot Farm".

4. **Verify changes:**
   - Check if clicking on Campaign 1, Mission 1 removes the Carrot Farm button.
   - Complete pre-commit steps.
