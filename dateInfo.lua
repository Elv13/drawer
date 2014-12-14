local setmetatable = setmetatable
local io           = io
local os           = os
local string       = string
local print        = print
local tonumber     = tonumber
local util         = require( "awful.util"               )
local wibox        = require( "wibox"                    )
local button       = require( "awful.button"             )
local vicious      = require( "extern.vicious"           )
local menu         = require( "radical.context"          )
local widget       = require( "awful.widget"             )
local themeutils   = require( "blind.common.drawing"     )
local radical      = require( "radical"                  )
local beautiful    = require( "beautiful"                )

local capi = { screen = screen , mouse  = mouse  , timer  = timer  }

local dateModule = {}
local mainMenu = nil
local month = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}

local function getHour(input)
  local toReturn
  if input < 0 then
    toReturn = 24 + input
  elseif input > 24 then
    toReturn = input - 24
  else
    toReturn = input
  end
  return toReturn
end

local function testFunc()
  local dateInfo = ""
  local pipe=io.popen(util.getdir("config")..'/drawer/Scripts/worldTime.sh')
  dateInfo=pipe:read("*a")
  pipe:close()
  return {dateInfo}
end



local function createDrawer()
  local calInfo = wibox.widget.textbox()
  local timeInfo = wibox.widget.textbox()

  --Weather stuff
  local weatherInfo2=wibox.widget.textbox()
  function updateWeater()
    local f=io.popen(util.getdir("config") .."/drawer/Scripts/curWeather.sh Torino")
    local weatherInfo = nil
    if f ~= nil then
      weatherInfo = f:read("*all")
      f:close()
--      weatherInfo = string.gsub(weatherInfo, "@cloud", "☁" )
--      weatherInfo = string.gsub(weatherInfo, "@sun", "✸"   )
--      weatherInfo = string.gsub(weatherInfo, "@moon", "☪"  )
--      weatherInfo = string.gsub(weatherInfo, "@rain", "☔"  )--☂
--      weatherInfo = string.gsub(weatherInfo, "@snow", "❄"  )
      weatherInfo = string.gsub(weatherInfo, "&amp;deg;", "°")
      weatherInfo = string.gsub(weatherInfo, "%(.+%)", "")
      weatherInfo = string.gsub(weatherInfo, "%.", "\n")
      weatherInfo2:set_markup(weatherInfo or "N/A")
    end
  end
  mytimer2 = capi.timer({ timeout = 5 })
  mytimer2:connect_signal("timeout", updateWeater)
  mytimer2:start()
  updateWeater()

  function updateCalendar()
    local f = io.popen('/usr/bin/cal -h',"r")
    local someText3 = "<tt><b><i>" .. f:read() .. "</i></b><u>" .. "\n" .. f:read() .. '</u>\n' .. f:read("*all") .. "</tt>"
    f:close()
    local day = tonumber(os.date('%d'))
    someText3 = someText3:gsub("(%D)"..day.."(%D)","%1<b><u>"..day.."</u></b>%2")
    local month = os.date('%m')
    local year = os.date('%Y')
    --Display the next month
    if month == '12' then
      month = 1
      year = year + 1
    else
      month = month + 1
    end
    f = io.popen('/usr/bin/cal ' .. month .. ' ' .. year ,"r")
    someText3 = someText3 .. "<tt><b><i>" .. f:read() .. "</i></b><u>" .. "\n" .. f:read() .. '</u>\n' .. f:read("*all") .. "</tt>"
    f:close()
    calInfo:set_markup(someText3)
  end

  --Calendar stuff

  updateCalendar()
  local camImage       = wibox.widget.imagebox()
  --local testImage3                       = wibox.widget.imagebox()
  camImage:set_image("/tmp/cam")

  --local spacer96                   = wibox.widget.textbox()
  --spacer96:set_text("\n\n")

  vicious.register(timeInfo,  testFunc, '$1',1)
  mainMenu:add_widget(weatherInfo2)
  mainMenu:add_widget(radical.widgets.header(mainMenu, "CALENDAR"     ),{height = 20 , width = 200})
  mainMenu:add_widget(calInfo)
  mainMenu:add_widget(radical.widgets.header(mainMenu, "INTERNATIONAL"),{height = 20 , width = 200})
  mainMenu:add_widget(timeInfo)
  mainMenu:add_widget(radical.widgets.header(mainMenu, "SATELLITE"    ),{height = 20 , width = 200})
  mainMenu:add_widget(camImage)
  --mainMenu:add_widget(testImage3)
  --mainMenu:add_widget(spacer96)
  --mainMenu:add_widget(radical.widgets.header(mainMenu, "FORCAST"      ),{height = 20 , width = 200})
  return calInfo:fit(9999,9999)
end

--Widget stuff
local ib2 = nil
dateModule.update_date_widget=function()
  ib2:set_image(themeutils.draw_underlay(month[tonumber(os.date('%m'))].." "..os.date('%d'),
      {
        bg=beautiful.fg_normal,
        fg=beautiful.bg_alternate,
        --       height=beautiful.default_height,
        margins=beautiful.default_height*.2,
        padding=2,
        padding_right=3
      }))
end



local function new(screen, args)
  local camUrl,camTimeout = nil,nil
  --Arg parsing
  if args ~= nil then
    camUrl=args.camUrl
    camTimeout=args.camTimeout or 1800
  end

  --Functions-------------------------------------------------
  --Toggles date menu and returns visibility
  dateModule.toggle = function (geo)
    if not  mainMenu then
      mainMenu = menu({arrow_type=radical.base.arrow_type.CENTERED})
      min_width = createDrawer()
      mainMenu.width = min_width + 2*mainMenu.border_width + 150
      mainMenu._internal.width = min_width

      if geo then
        mainMenu.parent_geometry = geo
      end

      mainMenu.visible = true
      return true
    else
      mainMenu.visible = false
      mainMenu=nil
      return false
    end

  end

  --Constructor---------------------------------------------
  if camUrl then
    --Download new image every camTimeout
    local timerCam = capi.timer({ timeout = camTimeout })
    timerCam:connect_signal("timeout", function() util.spawn_with_shell("wget -q "..camUrl.." -O /tmp/cam") end)
    timerCam:start()
  end

  local mytextclock = widget.textclock(" %H:%M ")

  --Date widget
  ib2 = wibox.widget.imagebox()
  local mytimer5 = capi.timer({ timeout = 1800 }) -- 30 mins
  dateModule.update_date_widget()
  mytimer5:connect_signal("timeout", dateModule.update_date_widget)
  mytimer5:start()


  local right_layout = wibox.layout.fixed.horizontal()

  right_layout:add(mytextclock)
  right_layout:add(ib2)

  right_layout:buttons (util.table.join(button({ }, 1, dateModule.toggle )))

  return right_layout
end

return setmetatable(dateModule, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
