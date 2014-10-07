local setmetatable = setmetatable
local tonumber = tonumber
local io = io
local type = type
local print = print
local button = require("awful.button")
local vicious = require("extern.vicious")
local wibox = require("wibox")
local widget2 = require("awful.widget")
local config = require("forgotten")
local beautiful = require("beautiful")
local util = require("awful.util")
local radical      = require( "radical"                  )
local allinone = require("widgets.allinone")
local capi = { screen = screen, mouse = mouse}

local module = {}

local mainMenu = nil

local errcount = 0

local volumewidget2 = nil

function amixer_volume_int(format)
   local f = io.popen('pactl list sinks | grep -A 8 "State: RUNNING" | tail -n 1 | cut -d "/" -f 2 | grep -o -e "[0-9]*"')
   if f then
      local l = f:read()
      f:close()
      local toReturn
      if (not l) or l == "" then
         toReturn = 0
--         errcount = errcount + 1
--         if errcount > 10 then
--            print("Too many amixer failure, stopping listener")
--            vicious.unregister(volumewidget2)
--         end
      else
         toReturn = tonumber(l)
      end
      return {toReturn}
   else
      print("Calling amixer failed")
   end
   return {}
end

function soundInfo()
  local f = io.popen('pactl list sinks | grep "Name:" | rev | cut -d "." -f1 |rev')

  local soundHeader = wibox.widget.textbox()
  soundHeader:set_markup(" <span color='".. beautiful.bg_normal .."'><b><tt>CHANALS</tt></b></span> ")

  local counter = 0
  while true do
    local aChannal = f:read("*line")
    if aChannal == nil then break end

    local f2= io.popen('pactl list sinks | grep -A 7 "' .. aChannal .. '$" | tail -n 1 | cut -d "/" -f 2 | grep -o -e "[0-9]*"')
    local aVolume = (tonumber(f2:read("*line")) or 0) / 100
    f2:close()

        
    f2 = io.popen('pactl list sinks | grep -A 7 "' .. aChannal .. '$" | grep "Mute:" | grep -c "yes"| grep -o -e "[0-9]*"')
    local isMute = (tonumber(f2:read("*line")) or 0);
    f2:close()
        
    local mute = wibox.widget.imagebox()
        if isMute == 1 then mute:set_image(config.iconPath .. "volm.png")
        else mute:set_image(config.iconPath .. "vol1.png") end
    

    local plus = wibox.widget.imagebox()
    plus:set_image(config.iconPath .. "tags/cross2.png")

    local volume = widget2.progressbar()
    volume:set_width(40)
    volume:set_height(20)
    volume:set_background_color(beautiful.bg_normal)
    volume:set_border_color(beautiful.fg_normal)
    volume:set_color(beautiful.fg_normal)
    volume:set_value(aVolume or 0)
    if (widget2.progressbar.set_offset ~= nil) then
      volume:set_offset(1)
    end

    local minus = wibox.widget.imagebox()
    minus:set_image(config.iconPath .. "tags/minus2.png")
    counter = counter +1
    local l2 = wibox.layout.fixed.horizontal()
    l2:add(plus)
    l2:add(volume)
    l2:add(minus)
    mainMenu:add_item({text=aChannal,prefix_widget=mute,suffix_widget=l2,button4= function() util.spawn_with_shell('pactl set-sink-volume `pactl list sinks | grep "Name:.*' .. aChannal .. '" | cut -d ":" -f 2` -- +2%') end, button5= function() util.spawn_with_shell('pactl set-sink-volume `pactl list sinks | grep "Name:.*' .. aChannal .. '" | cut -d ":" -f 2` -- -2%') end })
    
  end
  f:close()
end

local function new(mywibox3,left_margin)
  if volumewidget2 then return volumewidget2 end
  volumewidget2 = allinone()
  volumewidget2:set_icon(config.iconPath .. "vol.png")

  local btn = util.table.join(
     button({ }, 1, function(geo)
        if not mainMenu then
            mainMenu = radical.context({width=200,arrow_type=radical.base.arrow_type.CENTERED})
            soundInfo()
        end
        mainMenu.visible = not mainMenu.visible
        mainMenu.parent_geometry = geo

        if mywibox3 and type(mywibox3) == "wibox" then
            mywibox3.visible = not mywibox3.visible
        end
        musicBarVisibility = true
      end),
        
      button({ }, 3, function()
          util.spawn_with_shell("pactl set-sink-mute `pactl list sinks | grep -A 1 'State: RUNNING' | tail -n 1 | cut -d ' ' -f 2` toggle")
      end),
      button({ }, 4, function()
          util.spawn_with_shell("pactl set-sink-volume `pactl list sinks | grep -A 1 'State: RUNNING' | tail -n 1 | cut -d ' ' -f 2` -- +2%")
      end),
      button({ }, 5, function()
          util.spawn_with_shell('pactl set-sink-volume `pactl list sinks | grep -A 1 "State: RUNNING" | tail -n 1 | cut -d " " -f 2` -- -2%')
      end)
  )

  vicious.register(volumewidget2, amixer_volume_int, '$1')
  volumewidget2:buttons(btn)
  return volumewidget2
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
