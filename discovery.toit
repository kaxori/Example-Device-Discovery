import .mqtt


class HomeAssistantDiscovery:

  static TOPIC-BASE-DISCOVERY ::= "homeassistant/sensor"
  
  model /string
  topc-base-entity /string
  device-full /string
  device-reference /string
  hw-id /string
  is-first-entity /bool := true

  constructor 
      --.model
      --.hw-id
      --.topc-base-entity
      :

    device-full = """"device": {
      "model": "$model",
      "name": "$hw-id",
        "identifiers": ["$hw-id"],
        "manufacturer": "KaxOri",
        "sw_version": "0.0.1"}}"""

    device-reference = """"device":{"identifiers":["$hw-id"]}}"""


  create-sensor-entity 
      --data-label/string
      --data-category/string
      --device-class/string=""
      --data-unit/string=""
      --icon/string=""
      :
    print "create-entity \t: $data-label"

    topic := discovery-topic_ TOPIC-BASE-DISCOVERY data-label
    payload := """{
"name": "$data-label",
"state_topic": "$topc-base-entity/$hw-id/$data-category/$data-label",
"unique_id": "$(hw-id)-$data-label",
  """ \
  + (device-class != "" ? "\"device_class\":\"$device-class\"," : "") \
  + (data-unit != "" ? "\"unit_of_measurement\":\"$data-unit\"," : "") \
  + (icon != "" ? "\"icon\":\"mdi:$icon\"," : "") \
  + (is-first-entity ? device-full : device-reference)

    publish-mqtt topic payload

    is-first-entity = false
    //print



  discovery-topic_ base/string entity/string -> string:
    topic := base + "/" + hw-id + "/" + entity + "/config"
    if false:
      print "discovery topic: $topic\n"
    return topic
