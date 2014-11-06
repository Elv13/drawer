local setmetatable = setmetatable
local io           = io
local pairs        = pairs
local ipairs       = ipairs
local print        = print
local loadstring   = loadstring
local tonumber     = tonumber
local next         = next
local type         = type
local table        = table
local button       = require( "awful.button"             )
local beautiful    = require( "beautiful"                )
local widget2      = require( "awful.widget"             )
local wibox        = require( "wibox"                    )
local menu         = require( "radical.context"          )
local radtab       = require( "radical.widgets.table"    )
local vicious      = require( "extern.vicious"           )
local config       = require( "forgotten"                )
local util         = require( "awful.util"               )
local radical      = require( "radical"                  )
local themeutils   = require( "blind.common.drawing"     )
local embed        = require( "radical.embed"            )
local color        = require( "gears.color"              )
local cairo        = require( "lgi"                      ).cairo
local allinone     = require( "widgets.allinone"         )
local fd_async     = require("utils.fd_async"         )

local capi = { image  = image  ,
    screen = screen ,
    widget = widget ,
    client = client ,
    mouse  = mouse  ,
    timer  = timer  }

local module = {}

local data = {}

local memInfo = {}

local tabWdg = nil
local tabWdgCol = {
    TOTAL =1,
    FREE  =2,
    USED  =3,
}
local tabWdgRow = {
    RAM =1,
    SWAP=2
}

--MENUS
local usrMenu,typeMenu,topMenu

local function refreshStat()
    data.process={}
    --Load process information
    fd_async.exec.command(util.getdir("config")..'/drawer/Scripts/topMem.sh'):connect_signal("new::line",function(content)

            --Ignore null content
            if content ~= nil then
                a=content:split(",")
                table.insert(data.process,a)
                --print("a:",a[1],a[2],a[3])
            end
            topMenu:clear()
            for i = 0, #(data.process or {}) do
                if data.process[i] ~= nil then
                    --print("Proc",data.process[i][1])
                    local aMem = wibox.widget.textbox()
                    aMem:set_text(data.process[i][2])
                    aMem.fit = function()
                        return 58,topMenu.item_height
                    end

                    for k2,v2 in ipairs(capi.client.get()) do
                        if v2.class:lower() == data.process[i][3]:lower() or v2.name:lower():find(data.process[i][3]:lower()) ~= nil then
                            aMem.bg_image = v2.icon
                            break
                        end
                    end

                    aMem.draw = function(self,w, cr, width, height)
                        cr:save()
                        cr:set_source(color(topMenu.bg_alternate))
                        cr:rectangle(0,0,width-height/2,height)
                        cr:fill()
                        --                 if aMem.bg_image then
                        --                     cr:set_source(aMem.bg_image)
                        --                     cr:paint()
                        --                 end

                        cr:set_source_surface(themeutils.get_beg_arrow2({bg_color=topMenu.bg_alternate}),width-height/2,0)
                        cr:paint()
                        cr:restore()
                        wibox.widget.textbox.draw(self,w, cr, width, height)
                    end

                    testImage2       = wibox.widget.imagebox()
                    testImage2:set_image(config.iconPath .. "kill.png")

                    topMenu:add_item({text=data.process[i][3] or "N/A",prefix_widget=aMem,suffix_widget=testImage2})
                end
            end

        end)
    --Load memory Statistic
    local f;
    pipe0 = io.popen(util.getdir("config")..'/drawer/Scripts/memStatistics.sh')
    if pipe0 ~= nil then
        f=loadstring(pipe0:read("*all"))
        --Load memory statistic data
        f()
    else
        print("Unable to find memStatistics.sh")
    end

    if memStat ~= nil and memStat["users"] then
        data.users = memStat["users"]
    end

    if memStat ~= nil and memStat["state"] ~= nil then
        data.state = memStat["state"]
    end

    if memStat == nil or memStat["ram"] == nil then
        statNotFound = "N/A"
    end

    if tabWdg then
        tabWdg[ tabWdgRow.RAM  ][ tabWdgCol.TOTAL ]:set_text( statNotFound or memStat[ "ram" ][ "total" ])
        tabWdg[ tabWdgRow.RAM  ][ tabWdgCol.FREE  ]:set_text( statNotFound or memStat[ "ram" ][ "free"  ])
        tabWdg[ tabWdgRow.RAM  ][ tabWdgCol.USED  ]:set_text( statNotFound or memStat[ "ram" ][ "used"  ])
        tabWdg[ tabWdgRow.SWAP ][ tabWdgCol.TOTAL ]:set_text( statNotFound or memStat[ "swap"][ "total" ])
        tabWdg[ tabWdgRow.SWAP ][ tabWdgCol.FREE  ]:set_text( statNotFound or memStat[ "swap"][ "free"  ])
        tabWdg[ tabWdgRow.SWAP ][ tabWdgCol.USED  ]:set_text( statNotFound or memStat[ "swap"][ "used"  ])
    end



end

local function reload_user(usrMenu,data)
    local totalUser = 0
    local sorted = {}
    for v, i in pairs(data.users or {}) do
        local tmp = tonumber(i)*10
        while sorted[tmp] do
            tmp = tmp + 1
        end
        sorted[tmp] = {value=v,key=i}
    end
    for i2, v2 in pairs(sorted) do
        local v,i= v2.value,v2.key
        local anUser = wibox.widget.textbox()
        anUser:set_text(i)
        totalUser = totalUser +1
        usrMenu:add_item({text=v,suffix_widget=anUser})
    end
    return totalUser
end

local function reload_top(topMenu,data)

end



local function repaint()
    mainMenu = menu({arrow_x=90,nokeyboardnav=true,item_width=198,width=200,arrow_type=radical.base.arrow_type.CENTERED})
    mainMenu:add_widget(radical.widgets.header(mainMenu,"USAGE"),{height = 20 , width = 200})

    local m3 = wibox.layout.margin()
    m3:set_margins(3)
    m3:set_bottom(10)
    local tab,wdgs = radtab({
            {"","",""},
            {"","",""}},
        {row_height=20,v_header = {"Ram","Swap"},
            h_header = {"Total","Free","Used"}
        })
    tabWdg = wdgs
    m3:set_widget(tab)
    mainMenu:add_widget(m3,{width = 200})
    mainMenu:add_widget(radical.widgets.header(mainMenu,"USERS"),{height = 20, width = 200})
    local memStat

    usrMenu = embed({max_items=5})
    reload_user(usrMenu,data)
    mainMenu:add_embeded_menu(usrMenu)

    mainMenu:add_widget(radical.widgets.header(mainMenu,"STATE"),{height = 20 , width = 200})

    typeMenu = radical.widgets.piechart()
    mainMenu:add_widget(typeMenu,{height = 100 , width = 100})
    typeMenu:set_data(data.state)

    local imb = wibox.widget.imagebox()
    imb:set_image(beautiful.path .. "Icon/reload.png")
    mainMenu:add_widget(radical.widgets.header(mainMenu,"PROCESS",{suffix_widget=imb}),{height = 20 , width = 200})

    topMenu = embed({max_items=3})
    mainMenu:add_embeded_menu(topMenu)

    return mainMenu
end

local function update()
    usrMenu:clear()
    reload_user(usrMenu,data)
    typeMenu:set_data(data.state)
end

local function new(margin, args)
    local function toggle()
        if not data.menu then
            refreshStat()
            data.menu = repaint()
        else
        end
        if not data.menu.visible then
            refreshStat()
            update()
        end
        data.menu.visible = not data.menu.visible
    end

    local buttonclick = util.table.join(button({ }, 1, function (geo) toggle();data.menu.parent_geometry=geo end))

    local volumewidget2 = allinone()
    volumewidget2:set_icon(config.iconPath .. "cpu.png")
    vicious.register(volumewidget2, vicious.widgets.mem, '$1', 1, 'mem')

    volumewidget2:buttons (buttonclick)
    
    --Same old trick to fix first load
    --TODO: Fix first load problem with embed widgets
    toggle()
    toggle()
    return volumewidget2
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;