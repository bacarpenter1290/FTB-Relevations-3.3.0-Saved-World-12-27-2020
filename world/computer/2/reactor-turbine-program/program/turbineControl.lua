-- Reactor- und Turbine control by Thor_s_Crafter --
-- Version 2.3 --
-- Turbine control --

--Loads the touchpoint API
shell.run("cp /reactor-turbine-program/config/touchpoint.lua /touchpoint")
os.loadAPI("touchpoint")
shell.run("rm touchpoint")

--Loads the input API
shell.run("cp /reactor-turbine-program/config/input.lua /input")
os.loadAPI("input")
shell.run("rm input")

--Some variables
--Touchpoint init
local page = touchpoint.new(touchpointLocation)
--Buttons
local rOn
local rOff
local tOn
local tOff
local aTOn
local aTOff
local aTN = {"  -  ",label="aTurbinesOn"}
local cOn
local cOff
local modeA
local modeM
--Last/Current turbine (for switching)
local lastStat = 0
local currStat = 0

--Button renaming
if lang == "de" then
  rOn = {" Ein ",label = "reactorOn"}
  rOff = {" Aus ",label = "reactorOn"}
  tOn = {" Ein ",label = "turbineOn"}
  tOff = {" Aus ",label = "turbineOn"}
  aTOn = {" Ein ",label = "aTurbinesOn"}
  aTOff = {" Aus ",label = "aTurbinesOn"}
  cOn = {" Ein ",label = "coilsOn"}
  cOff = {" Aus ",label = "coilsOn"}
  modeA = {" Automatisch ",label = "modeSwitch"}
  modeM = {"  Manuell   ",label = "modeSwitch"}
elseif lang == "en" then
  rOn = {" On  ",label = "reactorOn"}
  rOff = {" Off ",label = "reactorOn"}
  tOn = {" On  ",label = "turbineOn"}
  tOff = {" Off ",label = "turbineOn"}
  aTOn = {" On ",label = "aTurbinesOn"}
  aTOff = {" Off ",label = "aTurbinesOn"}
  cOn = {" On  ",label = "coilsOn"}
  cOff = {" Off ",label = "coilsOn"}
  modeA = {" Automatic ",label = "modeSwitch"}
  modeM = {"  Manual   ",label = "modeSwitch"}
end


--Init auto mode
function startAutoMode()
  --Everything setup correctly?
  checkPeripherals()

  --Loads/Calculates the reactor's rod level
  findOptimalFuelRodLevel()

  --Clear display
  term.clear()
  term.setCursorPos(1,1)

  --Display prints
  print("Getting all Turbines to "..turbineTargetSpeed.." RPM...")
  mon.setBackgroundColor(backgroundColor)
  mon.setTextColor(textColor)
  mon.clear()
  mon.setCursorPos(1,1)

  if lang == "de" then
    mon.write("Bringe Turbinen auf "..(input.formatNumber(turbineTargetSpeed)).." RPM. Bitte warten...")
    --In Englisch
  elseif lang == "en" then
    mon.write("Getting Turbines to "..(input.formatNumberComma(turbineTargetSpeed)).." RPM. Please wait...")
  end

  --Gets turbine to target speed
  while not allAtTargetSpeed() do
    getToTargetSpeed()
    sleep(1)
    term.setCursorPos(1,2)
    for i=0,amountTurbines,1 do
      local tSpeed = t[i].getRotorSpeed()

      print("Speed: "..tSpeed.."     ")

      --formatting and printing status
      mon.setTextColor(textColor)
      mon.setCursorPos(1,(i+3))
      if i >= 16 then mon.setCursorPos(28,(i-16+3)) end
      if lang == "de" then
        mon.write("Turbine "..(i+1)..": "..(input.formatNumber(math.floor(tSpeed))).." RPM")
      elseif lang == "en" then
        mon.write("Turbine "..(i+1)..": "..(input.formatNumberComma(math.floor(tSpeed))).." RPM")
      end
      if tSpeed > turbineTargetSpeed then
        mon.setTextColor(colors.green)
        mon.write(" OK ")
      else
        mon.setTextColor(colors.red)
        mon.write(" ...")
      end
    end
  end

  --Enable reactor and turbines
  r.setActive(true)
  allTurbinesOn()

  --Reset terminal
  term.clear()
  term.setCursorPos(1,1)

  --Reset Monitor
  mon.setBackgroundColor(backgroundColor)
  mon.clear()
  mon.setTextColor(textColor)
  mon.setCursorPos(1,1)

  --Creates all buttons
  createAllButtons()

  --Displays first turbine (default)
  printStatsAuto(0)

  --run
  while true do
    clickEvent()
  end
end

--Init manual mode
function startManualMode()
  --Everything setup correctly?
  checkPeripherals()
  --Creates all buttons
  createAllButtons()
  --Creates additional manual buttons
  createManualButtons()

  --Sets all turbine flow rates to maximum (if set different in auto mode)
  for i=0,#t do
    t[i].setFluidFlowRateMax(2000)
  end

  --Displays the first turbine (default)
  printStatsMan(0)

  --run
  while true do
    clickEvent()
  end
end

--Checks if all required peripherals are attached
function checkPeripherals()
  mon.setBackgroundColor(colors.black)
  mon.clear()
  mon.setCursorPos(1,1)
  mon.setTextColor(colors.red)
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.red)
  --No turbine found
  if t[0] == nil then
    if lang == "de" then
      mon.write("Turbinen nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
      error("Turbinen nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
    elseif lang == "en" then
      mon.write("Turbines not found! Please check and reboot the computer (Press and hold Ctrl+R)")
      error("Turbines not found! Please check and reboot the computer (Press and hold Ctrl+R)")
    end
  end
  --No reactor found
  if r == "" then
    if lang == "de" then
      mon.write("Reaktor nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
      error("Reaktor nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
    elseif lang == "en" then
      mon.write("Reactor not found! Please check and reboot the computer (Press and hold Ctrl+R)")
      error("Reactor not found! Please check and reboot the computer (Press and hold Ctrl+R)")
    end
  end
  --No energy storage found
  if v == "" then
    if lang == "de" then
      mon.write("Energiespeicher nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
      error("Energiespeicher nicht gefunden! Bitte pruefen und den Computer neu starten (Strg+R gedrueckt halten)")
    elseif lang == "en" then
      mon.write("Energy Storage not found! Please check and reboot the computer (Press and hold Ctrl+R)")
      error("Energy Storage not found! Please check and reboot the computer (Press and hold Ctrl+R)")
    end
  end
end

function getEnergy()
  return v.getEnergyStored()
end
function getEnergyMax()
  return v.getMaxEnergyStored()
end
function getEnergyPer()
  local en = getEnergy()
  local enMax = getEnergyMax()
  local enPer = math.floor(en/enMax*100)
  return enPer
end

--Toggles the reactor status and the button
function toggleReactor()
  r.setActive(not r.getActive())
  page:toggleButton("reactorOn")
  if r.getActive() then
    page:rename("reactorOn",rOn,true)
  else
    page:rename("reactorOn",rOff,true)
  end
end

--Toggles one turbine status and button
function toggleTurbine(i)
  t[i].setActive(not t[i].getActive())
  page:toggleButton("turbineOn")
  if t[i].getActive() then
    page:rename("turbineOn",tOn,true)
  else
    page:rename("turbineOn",tOff,true)
  end
end

--Toggles one turbine coils and button
function toggleCoils(i)
  t[i].setInductorEngaged(not t[i].getInductorEngaged())
  page:toggleButton("coilsOn")
  if t[i].getInductorEngaged() then
    page:rename("coilsOn",cOn,true)
  else
    page:rename("coilsOn",cOff,true)
  end
end

--Enable all turbines (Coils engaged, FluidRate 2000mb/t)
function allTurbinesOn()
  for i=0,amountTurbines,1 do
    t[i].setActive(true)
    t[i].setInductorEngaged(true)
    t[i].setFluidFlowRateMax(2000)
  end
end

--Disable all turbiens (Coils disengaged, FluidRate 0mb/t)
function allTurbinesOff()
  for i=0,amountTurbines,1 do
    t[i].setInductorEngaged(false)
    t[i].setFluidFlowRateMax(0)
  end
end

--Enable one turbine
function turbineOn(i)
  t[i].setInductorEngaged(true)
  t[i].setFluidFlowRateMax(2000)
end

--Disable one turbine
function turbineOff(i)
  t[i].setInductorEngaged(false)
  t[i].setFluidFlowRateMax(0)
end

--Toggles all turbines (and buttons)
function toggleAllTurbines()
  page:rename("aTurbinesOn",aTOff,true)
  local onOff
  if t[0].getActive() then onOff = "off" else onOff = "on" end
  for i=0,amountTurbines do
    if onOff == "off" then
      t[i].setActive(false)
      if page.buttonList["aTurbinesOn"].active then
        page:toggleButton("aTurbinesOn")
        page:rename("aTurbinesOn",aTOff,true)
      end
    else
      t[i].setActive(true)
      if not page.buttonList["aTurbinesOn"].active then
        page:toggleButton("aTurbinesOn")
        page:rename("aTurbinesOn",aTOn,true)
      end--if
    end--else
  end--for
end--function

--Toggles all turbine coils (and buttons)
function toggleAllCoils()
  local coilsOnOff
  if t[0].getInductorEngaged() then coilsOnOff = "off" else coilsOnOff = "on" end
  for i=0,amountTurbines do
    if coilsOnOff == "off" then
      t[i].setInductorEngaged(false)
      if page.buttonList["Coils"].active then
        page:toggleButton("Coils")
      end
    else
      t[i].setInductorEngaged(true)
      if not page.buttonList["Coils"].active then
        page:toggleButton("Coils")
      end
    end
  end
end

--Calculates/Reads the optiomal reactor rod level
function findOptimalFuelRodLevel()

  --Load config?
  if not (math.floor(rodLevel) == 0)  then
    r.setAllControlRodLevels(rodLevel)

  else
    --Get reactor below 99c
    getTo99c()

    --Enable reactor + turbines
    r.setActive(true)
    allTurbinesOn()

    --Calculation variables
    local controlRodLevel = 99
    local diff = 0
    local targetSteamOutput = 2000*(amountTurbines+1)
    local targetLevel = 99

    --Display
    mon.setBackgroundColor(backgroundColor)
    mon.setTextColor(textColor)
    mon.clear()

    print("TargetSteam: "..targetSteamOutput)

    if lang == "de" then
      mon.setCursorPos(1,1)
      mon.write("Finde optimales FuelRod Level...")
      mon.setCursorPos(1,3)
      mon.write("Berechne Level...")
      mon.setCursorPos(1,5)
      mon.write("Gesuchter Steam-Output: "..(input.formatNumber(math.floor(targetSteamOutput))).."mb/t")
    elseif lang == "en" then
      mon.setCursorPos(1,1)
      mon.write("Finding optimal FuelRod Level...")
      mon.setCursorPos(1,3)
      mon.write("Calculating Level...")
      mon.setCursorPos(1,5)
      mon.write("Target Steam-Output: "..(input.formatNumberComma(math.floor(targetSteamOutput))).."mb/t")
    end

    --Calculate Level based on 2 values
    r.setAllControlRodLevels(controlRodLevel)
    sleep(2)
    local steamOutput1 = r.getHotFluidProducedLastTick()
    print("SO1: "..steamOutput1)
    r.setAllControlRodLevels(controlRodLevel-1)
    sleep(4)
    local steamOutput2 = r.getHotFluidProducedLastTick()
    print("SO2: "..steamOutput2)
    diff = steamOutput2 - steamOutput1
    print("Diff: "..diff)

    targetLevel= 100-math.floor(targetSteamOutput/diff)
    print("Target: "..targetLevel)
    r.setAllControlRodLevels(targetLevel)
    controlRodLevel = targetLevel

    --Find precise level
    while true do
      sleep(5)
      local steamOutput = r.getHotFluidProducedLastTick()

      mon.setCursorPos(1,3)
      mon.write("FuelRod Level: "..controlRodLevel.."  ")

      if lang == "de" then
        mon.setCursorPos(1,6)
        mon.write("Aktueller Steam-Output: "..(input.formatNumber(steamOutput)).."mb/t    ")
      elseif lang == "en" then
        mon.setCursorPos(1,6)
        mon.write("Current Steam-Output: "..(input.formatNumberComma(steamOutput)).."mb/t    ")
      end

      --Level too big
      if steamOutput < targetSteamOutput then
        controlRodLevel = controlRodLevel - 1
        r.setAllControlRodLevels(controlRodLevel)

      else
        r.setAllControlRodLevels(controlRodLevel)
        rodLevel = controlRodLevel
        saveOptionFile()
        print("Target RodLevel: "..controlRodLevel)
        sleep(2)
        break
      end --else

    end --while

  end --else
end --function

--Gets the reactor below 99c
function getTo99c()
  mon.setBackgroundColor(backgroundColor)
  mon.setTextColor(textColor)
  mon.clear()
  mon.setCursorPos(1,1)

  if lang == "de" then
    mon.write("Bringe Reaktor unter 99 Grad...")
  elseif lang == "en" then
    mon.write("Getting Reactor below 99c ...")
  end

  --Disables reactor and turbines
  r.setActive(false)
  allTurbinesOn()

  --Temperature variables
  local fTemp = r.getFuelTemperature()
  local cTemp = r.getCasingTemperature()
  local isNotBelow = true

  --Wait until both values are below 99
  while isNotBelow do
    term.setCursorPos(1,2)
    print("CoreTemp: "..fTemp.."      ")
    print("CasingTemp: "..cTemp.."      ")

    fTemp = r.getFuelTemperature()
    cTemp = r.getCasingTemperature()

    if fTemp < 99 then
      if cTemp < 99 then
        isNotBelow = false
      end
    end

    sleep(1)
  end--while
end--function

--Checks the current energy level and controlls turbines/reactor
--based on user settings (reactorOn, reactorOff)
function checkEnergyLevel()
  --Level > user setting (default: 90%)
  if getEnergyPer() >= reactorOffAt then
    printStatsAuto(currStat)
    print("Energy >= reactorOffAt")
    --Get to target speed
    if not allAtTargetSpeed() then
      for i=0,amountTurbines do
        if t[i].getRotorSpeed() < turbineTargetSpeed then
          t[i].setInductorEngaged(false)
        end
      end
    else
      --Disable reactor and turbines
      print("AllAtTargetSpeed.")
      allTurbinesOff()
      r.setActive(false)
    end
    print("end while")

    --Level < user setting (default: 50%)
  elseif getEnergyPer() < reactorOnAt then
    r.setActive(true)
    for i=0,amountTurbines do
      t[i].setFluidFlowRateMax(2000)
      if t[i].getRotorSpeed() < turbineTargetSpeed then
        t[i].setInductorEngaged(false)
      end
      if t[i].getRotorSpeed() > turbineTargetSpeed*1.02 then
        t[i].setInductorEngaged(true)
      end
    end

  else
    if r.getActive() then
      for i=0,amountTurbines do
        if t[i].getRotorSpeed() < turbineTargetSpeed then
          t[i].setInductorEngaged(false)
        end
        if t[i].getRotorSpeed() > turbineTargetSpeed*1.02 then
          t[i].setInductorEngaged(true)
        end
      end--for
    end--if

  end --else
end --if

--Gets turbines to targetSpeed
function getToTargetSpeed()
  for i=0,amountTurbines,1 do
    if t[i].getRotorSpeed() <= turbineTargetSpeed then
      r.setActive(true)
      t[i].setActive(true)
      t[i].setInductorEngaged(false)
      t[i].setFluidFlowRateMax(2000)
    end
    if t[i].getRotorSpeed() > turbineTargetSpeed then
      turbineOff(i)
    end
  end
end

--Returns true if all turbines are at targetSpeed
function allAtTargetSpeed()
  for i=0,amountTurbines do
    if t[i].getRotorSpeed() < turbineTargetSpeed then
      return false
    end
  end
  return true
end

--Runs another program
function run(program)
  shell.run(program)
  error("end turbineControl")
end

--Switches between auto and manual mode
function switchMode()
  if overallMode == "auto" then
    overallMode = "manual"
    saveOptionFile()
  elseif overallMode == "manual" then
    overallMode = "auto"
    saveOptionFile()
  end
  page = ""
  mon.clear()
  run("/reactor-turbine-program/program/turbineControl.lua")
end

--Creates all required buttons
function createAllButtons()
  local x1 = 40
  local x2 = 47
  local x3 = 54
  local x4 = 61
  local y = 4

  --Turbine buttons
  for i=0,amountTurbines,1 do
    if overallMode == "auto" then
      if i <= 7 then
        page:add("#"..(i+1),function() printStatsAuto(i) end,x1,y,x1+5,y)
      elseif (i > 7 and i <= 15) then
        page:add("#"..(i+1),function() printStatsAuto(i) end,x2,y,x2+5,y)
      elseif (i > 15 and i <= 23) then
        page:add("#"..(i+1),function() printStatsAuto(i) end,x3,y,x3+5,y)
      elseif i > 23 then
        page:add("#"..(i+1),function() printStatsAuto(i) end,x4,y,x4+5,y)
      end
      if (i == 7 or i == 15 or i == 23) then y = 4
      else y = y + 2 end

    elseif overallMode == "manual" then
      if i <= 7 then
        page:add("#"..(i+1),function() printStatsMan(i) end,x1,y,x1+5,y)
      elseif (i > 7 and i <= 15) then
        page:add("#"..(i+1),function() printStatsMan(i) end,x2,y,x2+5,y)
      elseif (i > 15 and i <= 23) then
        page:add("#"..(i+1),function() printStatsMan(i) end,x3,y,x3+5,y)
      elseif i > 23 then
        page:add("#"..(i+1),function() printStatsMan(i) end,x4,y,x4+5,y)
      end
      if (i == 7 or i == 15 or i == 23) then y = 4
      else y = y + 2 end
    end --mode
  end --for

  --Other buttons
  page:add("modeSwitch",switchMode,19,23,33,23)
  if overallMode == "auto" then
    page:rename("modeSwitch",modeA,true)
  elseif overallMode == "manual" then
    page:rename("modeSwitch",modeM,true)
  end

  if lang == "de" then
    page:add("Neu starten",restart,2,19,17,19)
    page:add("Optionen",function() run("/reactor-turbine-program/program/editOptions.lua") end,2,21,17,21)
    page:add("Hauptmenue",function() run("/reactor-turbine-program/start/menu.lua") end,2,23,17,23)
    --In Englisch
  elseif lang == "en" then
    page:add("Reboot",restart,2,19,17,19)
    page:add("Options",function() run("/reactor-turbine-program/program/editOptions.lua") end,2,21,17,21)
    page:add("Main Menu",function() run("/reactor-turbine-program/start/menu.lua") end,2,23,17,23)
  end
  page:draw()
end

--Creates (additional) manual buttons
function createManualButtons()
  page:add("reactorOn",toggleReactor,11,11,15,11)
  page:add("Coils",toggleAllCoils,25,17,31,17)
  page:add("aTurbinesOn",toggleAllTurbines,18,17,23,17)
  page:rename("aTurbinesOn",aTN,true)

  --Switch reactor button?
  if r.getActive() then
    page:rename("reactorOn",rOn,true)
    page:toggleButton("reactorOn")
  else
    page:rename("reactorOn",rOff,true)
  end

  --Turbine buttons on/off
  page:add("turbineOn",function() toggleTurbine(currStat) end,20,13,24,13)
  if t[currStat].getActive() then
    page:rename("turbineOn",tOn,true)
    page:toggleButton("turbineOn")
  else
    page:rename("turbineOn",tOff,true)
  end

  -- Turbinen buttons (Coils)
  page:add("coilsOn",function() toggleCoils(currStat) end,9,15,13,15)
  if t[currStat].getInductorEngaged() then
    page:rename("coilsOn",cOn,true)
  else
    page:rename("coilsOn",cOff,true)
  end
  page:draw()
end

--Checks for events (timer/clicks)
function clickEvent()

  --refresh screen
  if overallMode == "auto" then
    printStatsAuto(currStat)
    checkEnergyLevel()
  elseif overallMode == "manual" then
    printStatsMan(currStat)
  end

  --timer
  local time = os.startTimer(0.5)

  --gets the event
  local event, but = page:handleEvents(os.pullEvent())
  print(event)

  --execute a buttons function if clicked
  if event == "button_click" then
    page:flash(but)
    page.buttonList[but].func()
  end
end

--displays all info on the screen (auto mode)
function printStatsAuto(turbine)
  --refresh current turbine
  currStat = turbine

  --toggles turbine buttons if pressed (old button off, new button on)
  if not page.buttonList["#"..currStat+1].active then
    page:toggleButton("#"..currStat+1)
  end
  if currStat ~= lastStat then
    if page.buttonList["#"..lastStat+1].active then
      page:toggleButton("#"..lastStat+1)
    end
  end

  --gets overall energy production
  local rfGen = 0
  for i=0,amountTurbines,1 do
    rfGen = rfGen + t[i].getEnergyProducedLastTick()
  end

  --prints the energy level (in %)
  mon.setBackgroundColor(tonumber(backgroundColor))
  mon.setTextColor(tonumber(textColor))

  mon.setCursorPos(2,2)
  if lang == "de" then
    mon.write("Energie: "..getEnergyPer().."%  ")
  elseif lang == "en" then
    mon.write("Energy: "..getEnergyPer().."%  ")
  end

  --prints the energy bar
  mon.setCursorPos(2,3)
  mon.setBackgroundColor(colors.green)
  for i=0 ,getEnergyPer(),5 do
    mon.write(" ")
  end

  mon.setBackgroundColor(colors.lightGray)
  local tmpEn = getEnergyPer()/5
  local pos = 22-(19-tmpEn)
  mon.setCursorPos(pos,3)
  for i=0,(19-tmpEn),1 do
    mon.write(" ")
  end

  --prints the overall energy production
  mon.setBackgroundColor(tonumber(backgroundColor))

  mon.setCursorPos(2,5)
  if lang == "de" then
    mon.write("RF-Produktion: "..(input.formatNumber(math.floor(rfGen))).." RF/t      ")
  elseif lang == "en" then
    mon.write("RF-Production: "..(input.formatNumberComma(math.floor(rfGen))).." RF/t      ")
  end

  --Reactor status (on/off)
  mon.setCursorPos(2,7)
  if lang == "de" then
    mon.write("Reaktor: ")
    if r.getActive() then
      mon.setTextColor(colors.green)
      mon.write("an ")
    end
    if not r.getActive() then
      mon.setTextColor(colors.red)
      mon.write("aus")
    end
  elseif lang == "en" then
    mon.write("Reactor: ")
    if r.getActive() then
      mon.setTextColor(colors.green)
      mon.write("on ")
    end
    if not r.getActive() then
      mon.setTextColor(colors.red)
      mon.write("off")
    end
  end

  --Prints all other informations (fuel consumption,steam,turbine amount,mode)
  mon.setTextColor(tonumber(textColor))

  mon.setCursorPos(2,9)
  local fuelCons = tostring(r.getFuelConsumedLastTick())
  local fuelCons2 = string.sub(fuelCons, 0,4)

  if lang == "de" then
    mon.write("Reaktor-Verbrauch: "..fuelCons2.."mb/t     ")
    mon.setCursorPos(2,10)
    mon.write("Steam: "..(input.formatNumber(math.floor(r.getHotFluidProducedLastTick()))).."mb/t    ")
    mon.setCursorPos(40,2)
    mon.write("Turbinen: "..(amountTurbines+1).."  ")
    mon.setCursorPos(19,21)
    mon.write("Modus:")
    mon.setCursorPos(2,12)
    mon.write("-- Turbine "..(turbine+1).." --")
  elseif lang == "en" then
    mon.write("Fuel Consumption: "..fuelCons2.."mb/t     ")
    mon.setCursorPos(2,10)
    mon.write("Steam: "..(input.formatNumberComma(math.floor(r.getHotFluidProducedLastTick()))).."mb/t    ")
    mon.setCursorPos(40,2)
    mon.write("Turbines: "..(amountTurbines+1).."  ")
    mon.setCursorPos(19,21)
    mon.write("Mode:")
    mon.setCursorPos(2,12)
    mon.write("-- Turbine "..(turbine+1).." --")
  end

  --Currently selected turbine details

  --coils
  mon.setCursorPos(2,13)
  mon.write("Coils: ")

  if t[turbine].getInductorEngaged() then
    mon.setTextColor(colors.green)
    if lang == "de" then
      mon.write("eingehaengt   ")
    elseif lang == "en" then
      mon.write("engaged     ")
    end
  end
  if t[turbine].getInductorEngaged() == false  then
    mon.setTextColor(colors.red)
    if lang == "de" then
      mon.write("ausgehaengt   ")
    elseif lang == "en" then
      mon.write("disengaged")
    end
  end
  mon.setTextColor(tonumber(textColor))

  --rotor speed/RF-production
  mon.setCursorPos(2,14)
  if lang == "de" then
    mon.write("Rotor Geschwindigkeit: ")
    mon.write((input.formatNumber(math.floor(t[turbine].getRotorSpeed()))).." RPM   ")
    mon.setCursorPos(2,15)
    mon.write("RF-Produktion: "..(input.formatNumber(math.floor(t[turbine].getEnergyProducedLastTick()))).." RF/t           ")
  elseif lang == "en" then
    mon.write("Rotor Speed: ")
    mon.write((input.formatNumberComma(math.floor(t[turbine].getRotorSpeed()))).." RPM    ")
    mon.setCursorPos(2,15)
    mon.write("RF-Production: "..(input.formatNumberComma(math.floor(t[turbine].getEnergyProducedLastTick()))).." RF/t           ")
  end

  --prints the current program version
  mon.setCursorPos(2,25)
  mon.write("Version "..version)

  --refreshes the last turbine id
  lastStat = turbine
end

--printStats (manual)
function printStatsMan(turbine)
  --refresh current turbine
  currStat = turbine

  --toggles turbine buttons if pressed (old button off, new button on)
  if not page.buttonList["#"..currStat+1].active then
    page:toggleButton("#"..currStat+1)
  end
  if currStat ~= lastStat then
    if page.buttonList["#"..lastStat+1].active then
      page:toggleButton("#"..lastStat+1)
    end
  end

  --On/Off buttons
  if t[currStat].getActive() and not page.buttonList["turbineOn"].active then
    page:rename("turbineOn",tOn,true)
    page:toggleButton("turbineOn")
  end
  if not t[currStat].getActive() and page.buttonList["turbineOn"].active then
    page:rename("turbineOn",tOff,true)
    page:toggleButton("turbineOn")
  end
  if t[currStat].getInductorEngaged() and not page.buttonList["coilsOn"].active then
    page:rename("coilsOn",cOn,true)
    page:toggleButton("coilsOn")
  end
  if not t[currStat].getInductorEngaged() and page.buttonList["coilsOn"].active then
    page:rename("coilsOn",cOff,true)
    page:toggleButton("coilsOn")
  end

  --prints the energy level (in %)
  mon.setBackgroundColor(tonumber(backgroundColor))
  mon.setTextColor(tonumber(textColor))

  mon.setCursorPos(2,2)
  if lang == "de" then
    mon.write("Energie: "..getEnergyPer().."%  ")
  elseif lang == "en" then
    mon.write("Energy: "..getEnergyPer().."%  ")
  end

  --prints the energy bar
  mon.setCursorPos(2,3)
  mon.setBackgroundColor(colors.green)
  for i=0 ,getEnergyPer(),5 do
    mon.write(" ")
  end

  mon.setBackgroundColor(colors.lightGray)
  local tmpEn = getEnergyPer()/5
  local pos = 22-(19-tmpEn)
  mon.setCursorPos(pos,3)
  for i=0,(19-tmpEn),1 do
    mon.write(" ")
  end

  --prints the overall energy production
  local rfGen = 0
  for i=0,amountTurbines,1 do
    rfGen = rfGen + t[i].getEnergyProducedLastTick()
  end

  mon.setBackgroundColor(tonumber(backgroundColor))

  --Other status informations
  if lang == "de" then
    mon.setCursorPos(2,5)
    mon.write("RF-Produktion: "..(input.formatNumber(math.floor(rfGen))).." RF/t      ")
    mon.setCursorPos(2,7)
    local fuelCons = tostring(r.getFuelConsumedLastTick())
    local fuelCons2 = string.sub(fuelCons, 0,4)
    mon.write("Reaktor-Verbrauch: "..fuelCons2.."mb/t     ")
    mon.setCursorPos(2,9)
    mon.write("Rotor Geschwindigkeit: ")
    mon.write((input.formatNumber(math.floor(t[turbine].getRotorSpeed()))).." RPM   ")
    mon.setCursorPos(2,11)
    mon.write("Reaktor: ")
    mon.setCursorPos(19,21)
    mon.write("Modus:")
    mon.setCursorPos(2,13)
    mon.write("Aktuelle Turbine: ")
    mon.setCursorPos(2,17)
    mon.write("Alle Turbinen: ")
  elseif lang == "en" then
    mon.setCursorPos(2,5)
    mon.write("RF-Production: "..(input.formatNumberComma(math.floor(rfGen))).." RF/t      ")
    mon.setCursorPos(2,7)
    local fuelCons = tostring(r.getFuelConsumedLastTick())
    local fuelCons2 = string.sub(fuelCons, 0,4)
    mon.write("Fuel Consumption: "..fuelCons2.."mb/t     ")
    mon.setCursorPos(2,9)
    mon.write("Rotor Speed: ")
    mon.write((input.formatNumberComma(math.floor(t[turbine].getRotorSpeed()))).." RPM     ")
    mon.setCursorPos(2,11)
    mon.write("Reactor: ")
    mon.setCursorPos(19,21)
    mon.write("Mode:")
    mon.setCursorPos(2,13)
    mon.write("Current Turbine: ")
    mon.setCursorPos(2,17)
    mon.write("All Turbines: ")
  end
  mon.setCursorPos(2,15)
  mon.write("Coils: ")

  mon.setCursorPos(40,2)
  if lang == "de" then
    mon.write("Turbinen: "..(amountTurbines+1).."  ")
  elseif lang == "en" then
    mon.write("Turbines: "..(amountTurbines+1).."  ")
  end

  --prints the current program version
  mon.setCursorPos(2,25)
  mon.write("Version "..version)

  --refreshes the last turbine id
  lastStat = turbine
end

--program start
if overallMode == "auto" then
  startAutoMode()
elseif overallMode == "manual" then
  startManualMode()
end