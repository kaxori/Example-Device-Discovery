import .blocking
import log


/**
ButtonService provides non blocking button handling.
After the button service is started, the actions of the detected button events are called 
(lambda callbacks).

# Example:
  button := ButtonService --gpio=GPIO-ONBOARD-BOOT-BUTTON --low-active

  button.start-service
  button.set-press-action :: print "PRESS"
  button.set-release-action :: print "RELEASE"

  // event loop: button service calls the defined actions
  30.repeat: 
    sleep --ms=1_000

  button.stop-service
*/
class ButtonService :

  static DEBUG ::= false
  static LONG-PRESS-PERIOD ::= Duration --ms=1_000
  static CLICK-END-PERIOD ::= Duration --ms=400

  logger_ /log.Logger
  button /ButtonHandler
  service /Task? := null

  press-action /Lambda? := null
  release-action /Lambda? := null
  long-press-action /Lambda? := null
  single-click-action /Lambda? := null
  double-click-action /Lambda? := null
  tripple-click-action /Lambda? := null
  many-click-action /Lambda? := null

  /**
  Constructs an instance of ButtonService.
  Uses ButtonHandler for basic button IO functions.
  */
  constructor --gpio 
      --debounce-ms/int=null
      --low_active=null
      --logger /log.Logger = (log.default.with_name "button-service")
      :
    
    logger_ = logger
    button = ButtonHandler --gpio=gpio --low-active=low-active --debounce-ms=120

    if DEBUG:
      log_ """
      ButtonService:
      \t- gpio: $gpio
      \t- debounce: $debounce-ms ms
      \t- low active: $low_active
      """
    else: print "ButtonService: DEBUG off"

  /** Enables action for detected button press. */
  set-press-action action/Lambda? = null: 
    press-action = action 
    log_ "press-action: $press-action"

  /** Enables action for detected button release. */
  set-release-action action/Lambda? = null: 
    release-action = action
    log_ "release-action: $press-action"

  /** Enables action for detected long button press. */
  set-long-press-action  action/Lambda? = null: 
    long-press-action = action
    log_ "long-press-action: $press-action"


  /** Enables action for detected single button click. */
  set-single-click-action action/Lambda? = null: 
    single-click-action = action
    log_ "single-click-action: $press-action"

  /** Enables action for detected double button click. */
  set-double-click-action action/Lambda? = null: 
    double-click-action = action
    log_ "double-click-action: $press-action"

  /** Enables action for detected many button click. */
  set-many-click-action action/Lambda? = null: 
    many-click-action = action
    log_ "many-click-action: $press-action"

  /** Clear all actions. */
  clear-all-actions:
    press-action = release-action = long-press-action = \
    single-click-action = double-click-action = tripple-click-action = \
    many-click-action = null
    log_ "all actions cleared"

  

  /** Return true if service is running. */
  is-service-running -> bool:
    return service != null

  /** Starts the button service task. */
  start-service:
    if service != null: service.cancel
    /*log_ """
      press-action: $press-action
      release-action: $release-action
      single-click-action: $single-click-action
    """*/
    service = task :: while true:

        detect-clicks /bool := true
        click-count := 0
        while detect-clicks:

          // (0) idle state: button not pressed
          log_ "state 0: idle"
          button.wait-for-activation_
          if press-action: task:: press-action.call

          while true:

            // (1) pressed state: button pressed
            // wait for button release, but with long press timeout
            log_ "state 1: pressed"
            duration := button.wait-for-release --timeout=LONG-PRESS-PERIOD
            if duration >= LONG-PRESS-PERIOD: 
              if long-press-action: task:: long-press-action.call
              continue // to state (1)

            // (2) released state
            log_ "state 2: released"
            click-count += 1
            if release-action: task:: release-action.call

            duration = button.wait-for-press --timeout=CLICK-END-PERIOD
            if duration < CLICK-END-PERIOD: 
              if press-action: task:: press-action.call
              continue // to state (1)
            
            if click-count == 1:
              if single-click-action: task :: single-click-action.call
            else if click-count == 2:
              if double-click-action: task :: double-click-action.call
            else:
              if many-click-action: task :: many-click-action.call click-count
            break

          break // to state (0)
    log_ "service started"


  /** Stops the button service task. */
  stop-service:
    if service != null: 
      service.cancel
      service = null
      log_ "service stopped"


  // -----private functions -------------------------------------------
  log_ msg /string:
    if DEBUG: 
      time := Time.now.local
      time-str := "$(%02d time.h):$(%02d time.m):$(%02d time.s).$(%03d time.ns/1000000)"
      logger_.debug "$time-str: $msg"
