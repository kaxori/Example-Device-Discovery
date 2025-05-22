

// to save mqtt data item
class MqttData:
  topic /string := ?
  payload /string := ?

  constructor .topic .payload:




// unsent mqtt data container
class MqttQueue:
  static msgQueue := List 64

  static add topic payload:
    msgQueue.add (MqttData topic payload)
