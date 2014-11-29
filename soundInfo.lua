local setmetatable = setmetatable
local tonumber = tonumber
local io = io
local type = type
local print = print
local button = require("awful.button")
local vicious = require("vicious")
local wibox = require("wibox")
local widget2 = require("awful.widget")
local config = require("forgotten")
local beautiful = require("beautiful")
local util = require("awful.util")
local radical      = require( "radical"                  )
local allinone = require("widgets.allinone")
local capi = { screen = screen, mouse = mouse}

local moduleSound = {}

local mainMenu = nil

local errcount = 0

local volumewidget2 = nil

--Pulseaudio pid
local pavuId = -1
local pavuSinkN=0


-- Adds a line for a device
-- mainMenu:    menu in wich add item
-- name:        dev name
-- aVolume:     dev volume
-- isMute
-- commArgs:    arguments to be passed to function itemScrollUp and itemScrollDown
function addVolumeDevice(mainMenu,name,aVolume,isMute,commArgs)

    local icon = wibox.widget.imagebox()
    if isMute then icon:set_image(config.iconPath .. "volm.png")
    else icon:set_image(config.iconPath .. "vol3.png") end

    local volume = widget2.progressbar()
    volume:set_width(80)
    volume:set_height(20)
    volume:set_background_color(beautiful.bg_normal)
    volume:set_border_color(beautiful.fg_normal)
    volume:set_color(beautiful.fg_normal)
    volume:set_value(aVolume or 0)
    if (widget2.progressbar.set_offset ~= nil) then
        volume:set_offset(1)
    end

    --Add line and set scroll volume control
    mainMenu:add_item({text=name,prefix_widget=icon,suffix_widget=volume,button4=function(geo,parent) 
                aVolume=aVolume+0.02
                if aVolume>1 then aVolume=1 end
                volume:set_value(aVolume)
                volume:emit_signal("widget::updated")
                moduleSound.itemScrollUp(commArgs)
            end, button5=function(geo,parent)
                aVolume=aVolume-0.02
                if aVolume<0 then aVolume=0 end
                volume:set_value(aVolume)
                volume:emit_signal("widget::updated")
                moduleSound.itemScrollDown(commArgs)
            end})
end


--args {
--      pavuSink    =   Default sink number
--      mode        =   "pulse" : Pulseaudio mode (Require pactl)
--                      "alsa"  : Alsa mode
--                      nil     : Search for pactl if not found use alsa
local function new(mywibox3,args)
    --Variables---------------------------------------------------------
    local pavuSink, mode = nil,nil
    local volumes = {}

    --Select mode-------------------------------------------------------
    --Parse args
    if args ~= nil then
        pavuSink    =  args.pavuSink
        mode        =  args.mode
    end

    --Auto working mode selection
    if not mode then
        --Check if pulseaudio is running
        local f = io.popen('whereis pactl | cut -d":" -f2| wc -c')
        local temp = (tonumber(f:read("*all")) or 0)
        if temp > 2 then
            mode    =   "pulse"
            pavuSink=   pavuSink or 0
        else mode="alsa" end
        --
        print("INFO@SoundInfo: Auto mode detected:",mode)
        f:close()
    end


    --Functions------------------------------------------------------------------------
    if mode == "alsa" then 
        -- Alsa mode functions-----------------------------------
        moduleSound.itemScrollUp=function(devId)
            util.spawn_with_shell("amixer sset "..devId.." 2%+ >/dev/null")
        end
        moduleSound.itemScrollDown=function(devId)
            util.spawn_with_shell("amixer sset "..devId.." 2%- >/dev/null")
        end

        moduleSound.drawMenu=function()
            local mainMenu=  radical.context({width=200,arrow_type=radical.base.arrow_type.CENTERED})
            --Add menu header
            mainMenu:add_widget(radical.widgets.header(aMenu,"CHANNEL")  , {height = 20  , width = 200})

            --Parse Devices names
            local f = io.popen("amixer scontrols | awk '{print$4}'| grep -oe '[a-zA-Z]*'")
            while true do
                local aChannal = f:read("*line")
                if aChannal == nil then break end

                local f2= io.popen('amixer sget '.. aChannal ..' 2> /dev/null | tail -n1 |cut -f 7 -d " " | grep -o -e "[0-9]*" 2> /dev/null')
                local aVolume = (tonumber(f2:read("*line")) or 0) / 100
                f2:close()

                --Add device
                addVolumeDevice(mainMenu,aChannal,aVolume,aChannal)
            end
            f:close()
            return mainMenu
        end


    elseif mode == "pulse" then
        --Pulseaudio mode functions------------------------------------
        moduleSound.itemScrollUp= function(dev)
            util.spawn_with_shell("pactl set-"..dev.type.."-volume "..dev.id.." -- +2%")
            --print("pactl set-"..dev.type.."-volume "..dev.id.." -- +2%")
        end
        moduleSound.itemScrollDown=function(dev)
            util.spawn_with_shell("pactl set-"..dev.type.."-volume "..dev.id.." -- -2%")
            --print("pactl set-"..dev.type.."-volume "..dev.id.." -- -2%")
        end

        -- Menu drawer for pulseaudio
        moduleSound.drawMenu=function()
            local mainMenu=  radical.context({width=300,arrow_type=radical.base.arrow_type.CENTERED})
            --Add header
            mainMenu:add_widget(radical.widgets.header(aMenu,"CHANNEL")  , {height = 20  , width = 200})
            --Parse pactl stuff
            local pipe=io.popen("pactl list | awk -f "..util.getdir("config").."/drawer/Scripts/parsePactl.awk")
            for line in pipe:lines() do
                local data=string.split(line,";")
                local aVolume=tonumber(data[3]:match("%d*"))/100
                --Add item to menu
                addVolumeDevice(mainMenu,data[4],aVolume,false,{type=data[1],id=data[2]})
            end
            pipe:close()

            return mainMenu
        end


    end

    --Master Volume parser for widget
    function amixer_volume_int(format)
        local f= io.popen("amixer sget Master | awk '/Front.*Playback/{print $5; exit}'| grep -o -e '[0-9]*'")

        if f then
            local l = tonumber(f:read()) or 0
        else
            print("Calling amixer failed")
        end

        local toReturn
        if (not l) or l == "" then
            toReturn = 0
            errcount = errcount + 1
            if errcount > 10 then
                print("Too many amixer failure, stopping listener")
                vicious.unregister(volumewidget2)
            end
        else
            --Save master volume
            masterVolume = tonumber(l)
            return {masterVolume}
        end
        return {}
    end

    function toggle()
        if not mainMenu then
            mainMenu = moduleSound.drawMenu()
            mainMenu.parent_geometry = geo
            mainMenu.visible = true
        else
            --Close and destroy main menu
            mainMenu.visible = false
            mainMenu = nil
        end


        if mywibox3 and type(mywibox3) == "wibox" then
            mywibox3.visible = not mywibox3.visible
        end
        musicBarVisibility = true
    end
    --Constructor ------------------------------------------------------
    if volumewidget2 then return volumewidget2 end
    volumewidget2 = allinone()
    volumewidget2:set_icon(config.iconPath .. "vol.png")


    local btn
    if mode=="alsa" then
        --Alsa mode (Classic)

        btn = util.table.join(
            button({ }, 1, function(geo)
                    toggle()
                end),
            button({ }, 3, function()
                    util.spawn_with_shell("amixer set Master 1+ toggle")
                end),
            button({ }, 4, function()
                    volumeUp('Master')
                    if volumewidget2.percent > 0.98 then volumewidget2.percent=1
                    else volumewidget2.percent=volumewidget2.percent+0.02 end
                end),
            button({ }, 5, function()
                    volumeDown('Master')
                    if volumewidget2.percent < 0.02 then volumewidget2.percent=0
                    else volumewidget2.percent=volumewidget2.percent-0.02 end
                end)
        )
    else
        --Pulseaudio mode
        btn = util.table.join(
            button({ }, 1, function(geo)
                    toggle()
                end),
            button({ }, 3, function()
                    util.spawn_with_shell("pactl set-sink-mute "..pavuSinkN.." toggle")
                end),
            button({ }, 4, function()
                    if volumewidget2.percent > 1.48 then
                        volumewidget2.percent=1.5
                        util.spawn_with_shell("pactl set-sink-volume "..pavuSinkN.." -- 150%")
                    else
                        volumewidget2.percent=volumewidget2.percent+0.02
                        util.spawn_with_shell("pactl set-sink-volume "..pavuSinkN.." -- +2%")
                    end

                end),
            button({ }, 5, function()
                    util.spawn_with_shell("pactl set-sink-volume "..pavuSinkN.." -- -2%")
                    if volumewidget2.percent < 0.02 then volumewidget2.percent=0
                    else volumewidget2.percent=volumewidget2.percent-0.02 end
                end)
        )
    end

    vicious.register(volumewidget2, amixer_volume_int, '$1',5)
    volumewidget2:buttons(btn)
    return volumewidget2
end

return setmetatable(moduleSound, { __call = function(_, ...) return new(...) end })
