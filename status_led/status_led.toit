import gpio show *

/**
A driver for an animated LED. 
Sequences of repeated on- and off-phases are used to animate (blink) LEDs.

A blinking LED is used to indicate the system state. 
The shortest blinking consist of an on- and an off-phase. The duration of the phases in milliseconds are kept in a list.
Longer blink sequences are defined in nested lists.
*/
class StatusLed:

  /** To specify unlimited repetitions. */
  static ENDLESS /int ::= 0
  /** Defines a simulated heartbeat blinking sequence. */
  static HEARTBEAT-SEQUENCE /List ::= [[80, 200], [20, 700]]  // on-off cycle 

  gpio_ := ?
  pin_ := ?
  is-low-active_ /bool := false
  animationTask_ /Task? := null


  // public interface
  /**  */
  constructor --gpio --low-active=null:
    if low-active: is-low-active_ = true
    gpio_ = gpio
    pin_ = Pin gpio --output
    off_

  /** Turns the LED on. */
  on: stop_; on_
  /** Turns the LED off. */
  off: stop_; off_

  /** 
  Starts blinking mode. 
  If the number of repetitions is ommited then 
  the LED will blink endless or until a mode is requested.
  */
  blink --on-ms/int=500 --off-ms/int=500 --repetitions/int=ENDLESS:
    stop_
    endless /bool := repetitions == 0
    animationTask_ = task ::
      while endless or repetitions > 0:
        blink_ on-ms off-ms
        if repetitions > 0: repetitions -= 1

  /**
  A predefined sequence generates a repeated heartbeat blinking.
  */
  heartbeat beatsPerMinute/int=60 --repetitions/int=ENDLESS:
    animate_ HEARTBEAT-SEQUENCE (60.0/beatsPerMinute) repetitions

  /**
  A fast flickering led signal indication an error.
  */
  error: blink --on-ms=1 --off-ms=50


  /** 
  Controls the LED blinking based on the specified $sequence list.
  */
  animate sequence/List --speed-factor/float=1.0 --repetitions/int=ENDLESS:
    animate_ sequence speed-factor repetitions





  // private interface
  on_: pin_.set (is-low-active_ ? 0 : 1)
  off_: pin_.set (is-low-active_ ? 1 : 0)

  /** 
  Stops the animation task.
  */
  stop_: 
    if animationTask_ != null: 
      animationTask_.cancel
      animationTask_ = null

  /**
  A single blink sequence.
  */
  blink_ on-ms off-ms:
    on_; sleep --ms=on-ms
    off_; sleep --ms=off-ms

  /**
  Generates LED blinking according the specified animation $sequence. 
  The animation speed can be modified using the $speed-factor.
  The animation sequence is repeated as specified in $repetitions.

  If a blink cycle is not specified properly an predefined error signal is generated.
  */
  animate_ sequence/List speed-factor/float=1.0 repetitions/int=ENDLESS:
    stop_
    endless /bool := ( repetitions == 0 )
    animationTask_ = task ::
      while endless or repetitions > 0:

        sequence.do: | on-off/List |
        
          //  extract delay periods.
          on-ms /int := 1
          off-ms /int := 1

          if on-off is not List or on-off.size != 2: 
            error
            break

          if on-off[0] > 0: on-ms = (max 10 on-off[0] * speed-factor).to_int
          if on-off[1] > 0: off-ms = (max 10 on-off[1] * speed-factor).to_int
          blink_ on-ms off-ms

        if repetitions > 0: repetitions -= 1

//EOF.