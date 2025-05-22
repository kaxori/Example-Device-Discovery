import .mqttHandler
import log


//MQTT-ADDRESS-BROKER ::= "192.168.178.196"
MQTT-PORT ::= 1883
MQTT-DOMAIN ::= "home/DG-lab"
MQTT-TOPIC-BASE ::= "$(MQTT-DOMAIN)" 
MQTT-LWT-TOPIC ::= "mqttNet/stateDisplay/led"
MQTT-STATUS-COLOR-DEAD ::= [255,0,255]


mqtt-status-led := ?


open-mqtt --host/string --device-label --status-led=null:
  mqtt-status-led = status-led
  MqttHandler.open
      --HOST=host
      --TOPIC-BASE = MQTT-TOPIC-BASE
      --DEVICE-ID = device-label 
      --LWT = [MQTT-LWT-TOPIC, (build-status-led-payload_ MQTT-STATUS-COLOR-DEAD)]
      --logger = log.default.with_name "MQTT"



publish-mqtt --topic/string --payload/string ->none:
  MqttHandler.publish --topic=topic --payload=payload

publish-mqtt topic/string payload/string ->none:
  MqttHandler.publish --topic=topic --payload=payload

subscribe --topic/string --callback/Lambda ->none:
  MqttHandler.subscribe --topic=topic --max-qos=1 --callback=callback


build-status-led-payload_ color/List -> string:
  return "{\"led\":$mqtt-status-led\"rgb\":$color}"


status-display color/List ->none:
  MqttHandler.publish --topic=MQTT-LWT-TOPIC --payload=(build-status-led-payload_ color)



// to save mqtt data item
class MqttData: 
  topic /string := ?
  payload /string := ?
  constructor .topic .payload:


// unsent mqtt data message
class MqttQueue:
  static msgQueue := []

  static add topic payload:
    msgQueue.add (MqttData topic payload)
