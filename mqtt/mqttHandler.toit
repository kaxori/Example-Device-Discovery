import net
import log

import mqtt
import mqtt.last_will as mqtt
import encoding.json as json

import .mqtt  // local mqtt interface 


// ========================================================
class MqttHandler:

  //=====SINGLETON====
  static theOne_ /MqttHandler? := null
  static DEBUG /bool ::= false
  static connectTask := null


  logger_ /log.Logger? := ?
  DEVICE_ID /string ::= ?
  TOPIC_BASE /string ::= ?
  LWT/List/*<string>*/ ::= ?
  host /string 

  client_ /mqtt.Client? := null
  isConnected /bool := false
  connectedAction_ /Lambda? := null



  static open 
      --logger /log.Logger = (log.default.with_name "MQTT")
      //--.statusLed /StatusLed? = null
      --HOST /string
      --TOPIC_BASE /string 
      --DEVICE_ID /string
      --connectedAction /Lambda?=null
      --LWT/List/*<string>*/
    :
    if theOne_ == null:
      theOne_ = MqttHandler.private_
        --host=HOST
        --logger=logger
        --TOPIC-BASE= TOPIC_BASE
        --DEVICE-ID= DEVICE-ID
        --connectedAction= connectedAction
        //--statusLed= connectionLed
        --LWT=LWT

      waitUntilConnected
      print "MqttHandler connected"

    else:
      throw "MqttHandler already opened"



  static publish --topic --payload: 

    // if publish not possible now
    if theOne_ == null:
      MqttQueue.msgQueue.add (MqttData topic payload)
      theOne_.log_ "# MQTT queue: $MqttQueue.msgQueue.size $topic = $payload"

      // TODO: timeout to send this message
      return


    // if outstanding data
    if MqttQueue.msgQueue.size > 0:
      theOne_.log_ "publish queued first"
      theOne_.publishQueuedMessages_
  
    theOne_.publish_ topic payload


  static subscribe --topic/string --max-qos/int=1 --callback/Lambda:
    if theOne_ == null:
      //MqttQueue.msgQueue.add (MqttData topic payload)
      //theOne_.log_ "# MQTT queue: $MqttQueue.msgQueue.size $topic = $payload"
      return


    theOne_.subscribe_ topic --max-qos=max-qos callback



  static waitUntilConnected:
    if theOne_ == null:
      throw "MqttHandler not  opened"
    theOne_.waitUntilConnected_



  connect:
    log_ "connect"
    if isConnected: 
      log_ "... already connected"
      return

    // stop running task
    if connectTask: connectTask.cancel
    client_ = null

    // start connection task
    connectTask = task ::
      client_ =  mqtt.Client --host=this.host 
      client_.start 
        --options= mqtt.SessionOptions
            --client_id=DEVICE_ID
            --last-will= ( mqtt.LastWill 
                LWT[0] 
                LWT[1].to-byte-array
                --qos=1
                --retain=true )

        //--keep_alive = (Duration --s=15)
        //--on_error= :: log_ "client error: $it"


      //client_.publish (makeFullTopic_ LWT_TOPIC) LWT-PAYLOAD[1].to-byte-array 
      log_ "connected: topic base: $(makeFullTopic_ "") "
      isConnected = true


      log_ "connected - flushing queue ..."
      publishQueuedMessages_

      if connectedAction_ != null: 
        connectedAction_.call


  disconnect:
    if not isConnected: return
    logger_.fatal "disconnect not implmented"

  close:
    client_.close
    log_ "closed"




  //==========================================================
  // PRIVATE
  constructor.private_
      --.host /string
      --logger /log.Logger 
      --.TOPIC_BASE /string 
      --.DEVICE_ID /string
      --.LWT/List/*<string>*/
      --connectedAction/Lambda?
      :
    logger_ = logger
    if not DEBUG: logger_.debug "log is DISABLED"
    connectedAction_ = connectedAction
    log_ "MqttHandler created"
    



  waitUntilConnected_:
    connect 
    while not isConnected:
      sleep --ms=500
      log_ "MQTT no connect ?"





  // 
  publish_ topic/string payload/string:

    // complete topic
    full-topic := makeFullTopic_ topic[1..]

    // ?????????????? Problem here ?????????????????
    //if topic[0] == '?': topic = makeFullTopic_ topic[1..]
    if topic[0] != '?': 
      full-topic = topic

    client_.publish full-topic payload.to_byte_array

    //log_ "published |$topic|$payload"
    /*if DEBUG==true: 
      print "published |$topic|$payload"
      */


  publishQueuedMessages_:
    if MqttQueue.msgQueue.size > 0:

      log_ "publishQueuedMessages_ size:$ MqttQueue.msgQueue.size"
    
      MqttQueue.msgQueue.do:
        log_ "queued: |$it.topic|$it.payload|"
        publish_ it.topic it.payload

      MqttQueue.msgQueue = []


  subscribe_ topic/string --max-qos/int=1 callback/Lambda:
    if topic[0] == '?':
      topic = makeFullTopic_ topic[1..]

    client_.subscribe topic --max-qos=max-qos callback
    
    /*
    log_ "subscribed |$topic|"
    print "subscribe $topic"
    callback.call "test-topic" "test-payload"
    */


  log_ msg /string:
    if DEBUG==true: 
      logger_.debug "$msg"
      sleep --ms=1

  // 
  makeFullTopic_ topic/string -> string:
    return TOPIC_BASE + "/" + DEVICE_ID +"/" + topic