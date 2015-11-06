--Add vicious position to path
package.path=package.path..";"..os.getenv("HOME").."/.config/awesome/extern/?/init.lua;./extern/?/init.lua"

return  {
    soundInfo = require("drawer.soundInfo"),
    dateInfo  = require("drawer.dateInfo"),
    memInfo   = require("drawer.memInfo"),
    cpuInfo   = require("drawer.cpuInfo"),
    netInfo   = require("drawer.netInfo"),
}
