#Awesome radical drawer widgets
Cpu, Memory, Network Sound and Date widget for radical.

To be used inside https://github.com/Elv13/awesome-configs

###Require:
* lm-sensors
* cpufrequtils
    * Add to sudoers the line ALL ALL = NOPASSWD: /usr/bin/cpufreq-set
    
###Status
####CpuInfo:
* Works:
    * CPU Name
    * Core load
    * Process list
    * Update button
    * Set governor with ight click (Require cpufrequtils and Sudo permission without password for the cpufreq-set bin)
* Does not work:
    * Kill processes
    
####MemInfo:
*Works:
    * Ram usage
    * User list
    * Process ist
    * Update button
* Does not work:
    * Kill processes
    
####NetInfo:
*Works:
    * Net Up/down speed sum of all available interfaces
    * IP LAN
    * IP WAN
    * Connection list
    * Application list
    * Update button
* Does not work:
    * Kill processes
    
####soundInfo:
*Works:
    * Volume up down scrolling on widget
    * Mute toggle right click on widget
    * Automatic switch to pulseaudio mode if pactl exists
    * List all available devices (In both alsa or pulseaudio mode)