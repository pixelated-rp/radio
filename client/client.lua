ESX = nil

-- TODO: Copied from TokoVoip config currently. Make it dynamic.
Channels = {
  {name = "Police Channel 1"},
  {name = "Police Channel 2"},
  {name = "EMS Channel 1"},
  {name = "EMS Channel 2"},
}

local isRadioShowing   = false
local currentIndex     = 0;
local mainMenu         = nil
local menuPool         = nil
local menuItems        = {}
local playerData       = {}
local screenW, screenH = GetScreenResolution()

function InitMenu()
  if (menuPool ~= nil) then
    menuPool.Remove()
  end

  menuPool = NativeUI.CreatePool()
  mainMenu = NativeUI.CreateMenu("Radio Channels", "~b~Select Radio Channel", screenW, 0)
  menuPool:Add(mainMenu)

  local state  = {"Off", "On"}

  for k, v in pairs(Channels) do
    if (playerData.job.name == "police" or playerData.job.name == "ambulance") then
      menuItems[k] = NativeUI.CreateListItem(v.name, state, 0)
      mainMenu:AddItem(menuItems[k])
    end
  end

  mainMenu.OnListChange = function(sender, item, index)
    local currentSelectedIndex = nil

    for k, v in pairs(menuItems) do
      if item == v then
        currentSelectedIndex = item:IndexToItem(index)

        if currentSelectedIndex == "Off" and exports.tokovoip_script:isPlayerInChannel(k) then
          exports.tokovoip_script:removePlayerFromRadio(k)
        elseif currentSelectedIndex == "On" and not exports.tokovoip_script:isPlayerInChannel(k) then
          exports.tokovoip_script:addPlayerToRadio(k)
        end
      end
    end
  end 
end

function ToggleRadio()
  Citizen.Trace("Toggle radio\n")
  isRadioShowing = not isRadioShowing;
  SendNUIMessage({type = "pixelated.radio", display = isRadioShowing})

  if (isRadioShowing) then
    Citizen.CreateThread(function()
      while (isRadioShowing) do
        Citizen.Wait(5)

        local newIndex = currentIndex
        local text

        if (IsControlJustPressed(0, 174)) then
          newIndex = math.max(currentIndex - 1, 0)
        elseif (IsControlJustPressed(0, 175)) then
          newIndex = math.min(currentIndex + 1, #Channels)
        end

        if (newIndex ~= currentIndex) then
          if (newIndex == 0) then
            text = "Off"
            exports.tokovoip_script:removePlayerFromRadio(currentIndex)
          else
            text = Channels[newIndex].name
            exports.tokovoip_script:removePlayerFromRadio(currentIndex)
            exports.tokovoip_script:addPlayerToRadio(newIndex)
          end

          currentIndex = newIndex
          SendNUIMessage({type = "pixelated.radio", text = text})
        end
      end
    end)
  end
end

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end

  ESX.TriggerServerCallback('esx:getPlayerData', function(data)
    playerData = data
    InitMenu()
  end)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  playerData.job = job
  InitMenu()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if menuPool ~= nil then
          menuPool:ProcessMenus()
          if IsControlPressed(0, 21) and IsControlJustPressed(0, 288) then -- shift + f1
              --mainMenu:Visible(not mainMenu:Visible())
              ToggleRadio()
          end
        end
    end
end)