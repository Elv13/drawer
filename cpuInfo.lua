local setmetatable = setmetatable
local io           = io
local ipairs       = ipairs
local loadstring   = loadstring
local print        = print
local tonumber     = tonumber
local beautiful    = require( "beautiful"             )
local button       = require( "awful.button"          )
local widget2      = require( "awful.widget"          )
local config       = require( "forgotten"             )
local vicious      = require( "extern.vicious"        )
local menu         = require( "radical.context"       )
local util         = require( "awful.util"            )
local wibox        = require( "wibox"                 )
local themeutils   = require( "blind.common.drawing"  )
local radtab       = require( "radical.widgets.table" )
local embed        = require( "radical.embed"         )
local radical      = require( "radical"               )
local color        = require( "gears.color"           )
local cairo        = require( "lgi"                   ).cairo
local allinone     = require( "widgets.allinone"      )
local fd_async     = require("utils.fd_async"         )

local data     = {}

--Menus
local procMenu , govMenu = nil, nil

local capi = { screen = screen , client = client ,
    mouse  = mouse  , timer  = timer  }

local module = {}

local function match_icon(arr,name)
    for k2,v2 in ipairs(arr) do
        if k2:find(name) ~= nil then
            return v2
        end
    end
end

local function reload_top(procMenu,data)
    data.process={}

    --Load process information
    fd_async.exec.command(util.getdir("config")..'/drawer/Scripts/topCpu.sh'):connect_signal("new::line",function(content)

            if content ~= nil then
                table.insert(data.process,content:split(","))
            end
            procMenu:clear()
            if data.process then
                local procIcon = {}
                for k2,v2 in ipairs(capi.client.get()) do
                    if v2.icon then
                        procIcon[v2.class:lower()] = v2.icon
                    end
                end
                for i=1,#data.process do
                    local wdg = {}
                    wdg.percent       = wibox.widget.textbox()
                    wdg.percent.fit = function()
                        return 42,procMenu.item_height
                    end
                    wdg.percent.draw = function(self,w, cr, width, height)
                        cr:save()
                        cr:set_source(color(procMenu.bg_alternate))
                        cr:rectangle(0,0,width-height/2,height)
                        cr:fill()
                        cr:set_source_surface(themeutils.get_beg_arrow2({bg_color=procMenu.bg_alternate}),width-height/2,0)
                        cr:paint()
                        cr:restore()
                        wibox.widget.textbox.draw(self,w, cr, width, height)
                    end
                    wdg.kill          = wibox.widget.imagebox()
                    wdg.kill:set_image(config.iconPath .. "kill.png")

                    --Show process and cpu load
                    wdg.percent:set_text((data.process[i][2] or "N/A").."%")
                    procMenu:add_item({text=data.process[i][3],suffix_widget=wdg.kill,prefix_widget=wdg.percent})
                end
            end
        end)
end

local function new(margin, args)
    local cpuModel
    local spacer1
    local volUsage

    local modelWl
    local cpuWidgetArrayL
    local cpuWidgetArrayL
    local main_table

    --Load initial data
    print("Load initial data")
    --Evaluate core number
    local pipe0 = io.popen("cat /proc/cpuinfo | grep processor | tail -n1 | grep -e'[0-9]*' -o")
    local coreN = pipe0:read("*all") or "0"
    pipe0:close()

    if coreN then
        data.coreN=(coreN+1)
        print("Detected core number: ",data.coreN)
    else
        print("Unable to load core number")    
    end

    local function loadData()
        --Load CPU Information
        --Get cores temperatures
        local pipe0 = io.popen('sensors | grep "Core" | grep -e ": *+[0-9]*" -o| grep -e "[0-9]*" -o')
        local i=0
        for line in pipe0:lines() do
            main_table[i+1][3]:set_text(line)
            i=i+1
        end
        pipe0:close()

    end

    local function createDrawer()
        cpuModel          = wibox.widget.textbox()
        spacer1           = wibox.widget.textbox()
        volUsage          = widget2.graph()

        topCpuW           = {}
        local emptyTable={};
        local tabHeader={};
        for i=1,data.coreN,1 do
            emptyTable[i]= {"","","","",""}
            tabHeader[i]="C"..(i-1)
        end
        local tab,widgets = radtab(emptyTable,
            {row_height=20,v_header = tabHeader,
                h_header = {"GHz","Used","Temp","Cache","Governor"}
            })
        main_table = widgets

        --Register cell table as vicious widgets
        for i=0, (data.coreN-1) do
            --Cpu Speed (Frequency in Ghz
            vicious.register(main_table[i+1][1], vicious.widgets.cpuinf,    function (widget, args)
                    return string.format("%.2f", args['{cpu'..i..' ghz}'])
                end,2)
            --Usage
            vicious.register(main_table[i+1][2], vicious.widgets.cpu,'$'..(i+2)..' %',1)
            --Governor
            vicious.register(main_table[i+1][5], vicious.widgets.cpufreq,'$5',5,"cpu"..i)
        end
        modelWl         = wibox.layout.fixed.horizontal()
        modelWl:add         ( cpuModel      )

        loadData()

        cpuWidgetArrayL = wibox.layout.margin()
        cpuWidgetArrayL:set_margins(3)
        cpuWidgetArrayL:set_bottom(10)
        cpuWidgetArrayL:set_widget(tab)

        --Load Cpu model
        local pipeIn = io.popen('cat /proc/cpuinfo | grep "model name" | cut -d ":" -f2 | head -n 1',"r")
        local cpuName = pipeIn:read("*all") or "N/A"
        pipeIn:close()

        cpuModel:set_text(cpuName)
        cpuModel.width     = 212

        volUsage:set_width        ( 212                                  )
        volUsage:set_height       ( 30                                   )
        volUsage:set_scale        ( true                                 )
        volUsage:set_border_color ( beautiful.fg_normal                  )
        volUsage:set_color        ( beautiful.fg_normal                  )
        vicious.register          ( volUsage, vicious.widgets.cpu,'$1',1 )


    end

    local function refresh()
        loadData()
        reload_top(procMenu,data)
    end

    local function regenMenu()
        local imb = wibox.widget.imagebox()
        imb:set_image(beautiful.path .. "Icon/reload.png")
        imb:buttons(button({ }, 1, function (geo) refresh() end))

        aMenu = menu({item_width=198,width=200,arrow_type=radical.base.arrow_type.CENTERED})
        aMenu:add_widget(radical.widgets.header(aMenu,"INFO")  , {height = 20  , width = 200})
        aMenu:add_widget(modelWl         , {height = 40  , width = 200})
        aMenu:add_widget(radical.widgets.header(aMenu,"USAGE")   , {height = 20  , width = 200})
        aMenu:add_widget(volUsage        , {height = 30  , width = 200})
        aMenu:add_widget(cpuWidgetArrayL         , {width = 200})
        aMenu:add_widget(radical.widgets.header(aMenu,"PROCESS",{suffix_widget=imb}) , {height = 20  , width = 200})
        procMenu = embed({max_items=6})
        aMenu:add_embeded_menu(procMenu)
        return aMenu
    end

    local function show()
        if not data.menu then
            createDrawer()
            data.menu = regenMenu()
        else
        end
        if not data.menu.visible then
            refresh()
        end
        data.menu.visible = not data.menu.visible
    end

    -- Generate governor list menu
    local function generateGovernorMenu(cpuN)
        --if cpuN == nil then cpuN="cpu0" end

        govMenu = menu({item_width=198,width=200,arrow_type=radical.base.arrow_type.CENTERED})
        govMenu:add_item {text="Set global Governor",button1=function(_menu,item,mods) print("Hello World! ") end,sub_menu=function()
                local govList=radical.context{}

                --Load available governor list
                local pipe0 = io.popen('cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors')
                for i,gov in pairs(pipe0:read("*all"):split(" ")) do
                    print("G:",gov)
                    --Generate menu list
                    if cpuN ~= nil then
                        --Specific Cpu
                        --govList:add_item {text=gov,button1=function(_menu,item,mods) util.spawn_with_shell('sudo cpufreq-set -c '..cpuN..' -g '..gov) end}
                    else
                        --All cpu together
                        govList:add_item {text=gov,button1=function(_menu,item,mods) 
                                for cpuI=0,data.coreN do
                                    --util.spawn_with_shell('sudo cpufreq-set -c '..cpuI..' -g '..gov) 
                                end
                            end}
                        --govList:add_item {text="Performance",button1=function(_menu,item,mods) print("Performances") end}
                    end
                end
                pipe0:close()

                return govList
            end
        }
    end

    local function showGovernor()
        if not govMenu then
            generateGovernorMenu()
        else
            govMenu.visible = not govMenu.visible
        end
    end


    local volumewidget2 = allinone()
    volumewidget2:set_icon(config.iconPath .. "brain.png")
    vicious.register(volumewidget2, vicious.widgets.cpu,'$1',1)
    volumewidget2:buttons (util.table.join( button({ }, 1, function (geo) show(); data.menu.parent_geometry = geo end),
                                            button({ }, 3, function (geo) showGovernor(); govMenu.parent_geometry = geo end)))

    --Initial menu loading quick fix
    show()
    show()

    return volumewidget2
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
