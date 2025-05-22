import .hw-PROTO1         // GPIO devices
import .status-led as LED
import .button_handler show *

import .mqtt
import .discovery as hass // home assistant interface

import gpio
import esp32


// ========================================================
JAG-LABEL ::= "PROTO1"      // set in jaguar flashing
DESCRIPTION ::= JAG-LABEL + ": discovery test"

MQTT-LABEL ::= JAG-LABEL 
MQTT-ADDRESS-BROKER ::= "192.168.178.221"


DEBUG ::= true
MEASUREMENT-PERIOD-S ::= 5


// ========================================================
mqtt-device-label := (unique-device-id MQTT-LABEL)

led-blue := LED.StatusLed --gpio=GPIO-LED-BLUE
button := ButtonService --gpio=GPIO-BUTTON --low-active --debounce-ms=50


button-counter /int := 0
loop-counter /int := 0





// ========================================================
main:
  print "\n"*5
  print "simple example of HomeAssistant Device Discovery"
  print "-"*40
  led-blue.blink --on-ms=50 --off-ms=250

  button.start-service
  button.set-single-click-action ::
    button-counter += 1
    publish-mqtt "?measure/button" "$(%d button-counter)"
    print "single click #$(%d button-counter)."
    task :: 
      led-blue.blink --on-ms=10 --off-ms=200
      sleep --ms=2000
      led-blue.blink --on-ms=200 --off-ms=800
    


  // === MQTT =============================
  open-mqtt --host=MQTT-ADDRESS-BROKER --device-label=mqtt-device-label

  // HASS device discovery
  hass := hass.HomeAssistantDiscovery
      --model=MQTT-LABEL
      --hw-id=mqtt-device-label
      --topc-base-entity=MQTT-DOMAIN

  hass.create-sensor-entity --data-label="time" --data-category="measure"
    --icon="clock-digital"

  hass.create-sensor-entity --data-label="loops" --data-category="measure"
    --device-class=""
    --data-unit="#"

  hass.create-sensor-entity --data-label="button" --data-category="measure"
    --device-class=""
    --data-unit="#"



  // default values
  publish-mqtt "?restart/description" DESCRIPTION

  publish-mqtt "?measure/time" "$getTime"
  publish-mqtt "?measure/button" "$(%d button-counter)"




  // ======================================================
  led-blue.blink --on-ms=1 --off-ms=1_000
  while true:
    loop-counter += 1

    publish-mqtt "?measure/time" "$getTime"
    publish-mqtt "?measure/loops" "$loop-counter"

    msg := "loop-count: $(%5d loop-counter)"
    print msg

    sleep --ms=MEASUREMENT-PERIOD-S*1_000

  unreachable
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


// convert a duration in mm:ss string format
min-sec d/Duration -> string:
  secs := d.in-s
  return "$(%02d secs/60):$(%02d secs%60)"

get_mac_: #primitive.esp32.get_mac_address
mac -> string:
  macBytes := get_mac_
  macString := ""
  macBytes.size.repeat:
    macString += "$(%02X macBytes[it])"
  return macString
getMac6Str -> string: return "$(mac[6..])"
unique-device-id device-model/string -> string: return device-model + "-" + getMac6Str
getTime -> string:
    time := Time.now.local
    return "$(%02d time.h):$(%02d time.m):$(%02d time.s)"
// EOF.  