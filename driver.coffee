window = @window
navigator = @window.navigator
document = window.document

BUTTONS =
  A: 0
  B: 1
  X: 2
  Y: 3
  LEFT_SHOULDER: 4
  RIGHT_SHOULDER: 5
  LEFT_TRIGGER: 6
  RIGHT_TRIGGER: 7
  SELECT: 8
  START: 9
  LEFT_STICK: 10
  RIGHT_STICK: 10
  DPAD_UP: 12
  DPAD_DOWN: 13
  DPAD_LEFT: 14
  DPAD_RIGHT: 15

AXES =
  LEFT_HORIZONTAL: 0
  LEFT_VERTICAL: 1
  RIGHT_HORIZONTAL: 2
  RIGHT_VERTICAL: 3

KEYS =
  LEFT: 37
  UP: 38
  RIGHT: 39
  DOWN: 40

delay = (d, f) -> setTimeout f, d

simulate = (->
  extend = (destination, source) ->
    for property of source
      destination[property] = source[property]
    destination

  eventMatchers =
    HTMLEvents: /^(?:load|unload|abort|error|select|change|submit|reset|focus|blur|resize|scroll)$/
    MouseEvents: /^(?:click|dblclick|mouse(?:down|up|over|move|out|enter))$/

  defaultOptions =
    pointerX: 0
    pointerY: 0
    button: 0
    ctrlKey: false
    altKey: false
    shiftKey: false
    metaKey: false
    bubbles: true
    cancelable: true

  simulate = (element, eventName) ->
    options = extend(defaultOptions, arguments[2] or {})
    oEvent = undefined
    eventType = null
    for name of eventMatchers
      if eventMatchers[name].test(eventName)
        eventType = name
        break
    throw new SyntaxError("Only HTMLEvents and MouseEvents interfaces are supported")  unless eventType
    if document.createEvent
      oEvent = document.createEvent(eventType)
      if eventType is "HTMLEvents"
        oEvent.initEvent eventName, options.bubbles, options.cancelable
      else
        oEvent.initMouseEvent eventName, options.bubbles, options.cancelable, document.defaultView, options.button, options.pointerX, options.pointerY, options.pointerX, options.pointerY, options.ctrlKey, options.altKey, options.shiftKey, options.metaKey, options.button, element
      element.dispatchEvent oEvent
    else
      options.clientX = options.pointerX
      options.clientY = options.pointerY
      evt = document.createEventObject()
      oEvent = extend(evt, options)
      element.fireEvent "on" + eventName, oEvent
    element
)()

(($) ->
  class ControllerState
    DEADZONE: 0.40
    INIT_REPEAT_DELAY: 45
    REPEAT_DELAY: 7

    buttonState:
      0: 0
      1: 0, 2: 0, 3: 0, 4: 0
      5: 0, 6: 0, 7: 0, 8: 0
      9: 0, 10: 0, 11: 0, 12: 0
      13: 0, 14: 0, 15: 0, 16: 0
    axisState: {}
    axisRepeating: {}
    axisDelay:
      0: 0, 1: 0, 2: 0
      3: 0, 4: 0, 5: 0
      6: 0, 7: 0, 8: 0
    timestamp: 0
    isActive: false
    active: {}

    constructor: (id) ->
      @id = id

    handleEvents: (callbackObject) ->
      gamepad = navigator.getGamepads()[@id]
      if gamepad.timestamp > @timestamp or @isActive
        @timestamp = gamepad.timestamp
        for own button, state of gamepad.buttons
          unless @buttonState[button] is state.value
            @buttonState[button] = state.value
            callbackObject.button parseInt(button, 10), state.value
            @active["b" + button] = state.value != 0

        for own axis, value of gamepad.axes
          posDeadzone = value > @DEADZONE
          negDeadzone = value < -@DEADZONE
          state = (if posDeadzone then 1 else ((if negDeadzone then -1 else 0)))
          if @axisState[axis] is state
            @axisDelay[axis]++
            if state != 0
              if (@axisRepeating[axis] && @axisDelay[axis] > @REPEAT_DELAY) || @axisDelay[axis] > @INIT_REPEAT_DELAY
                @axisRepeating[axis] = true
                @axisDelay[axis] = 0
                callbackObject.axis parseInt(axis, 10), value, state
          else
            @axisRepeating[axis] = false
            @axisDelay[axis] = 0
            unless state == 0
              callbackObject.axis parseInt(axis, 10), value, state
          @axisState[axis] = state
          @active["ax" + axis] = state != 0

        @isActive = false
        for own _, state of @active
          if state
            @isActive = true
            break


  class JoystickInputController
    constructor: ->
      @controllers = []
      @setupControllers()
      overlay = null
      $ =>

        if @controllers.length == 0
          overlay = new OverlayMessage()
          overlay.show "Please press <img src='#{chrome.extension.getURL "assets/Xbox360_Button_A.png"}' /> to begin"

      window.addEventListener "gamepadconnected", =>
        @setupControllers()
        overlay.hide() if overlay

      window.addEventListener "gamepaddisconnected", => @setupControllers()

    setupControllers: ->
      for index in [0...navigator.getGamepads().length]
        gamepad = navigator.getGamepads()[index]
        if gamepad
          @controllers.push new ControllerState(index)
      cancelAnimationFrame(@animFrame) if @animFrame
      @animFrame = null
      if @controllers.length > 0
        @loop()

    loop: ->
      for controller in @controllers
        controller.handleEvents(@)
      @booted = true
      @animFrame = window.requestAnimationFrame @loop.bind(@)
      return

    button: (buttonId, state) ->
    axis: (axisId, magnitude) ->

  class OverlayMessage
    getElem: ->
      @elem = $(".navigator-overlay")
      if @elem.length == 0
        $("body").append("<div class='navigator-overlay'><span></span></div>")
        @elem = $(".navigator-overlay")
        @elem.on "click", (e) ->
          overlay = $(e.target)
          overlay.css({opacity: 0}).one("transitionend", -> overlay.hide())

    visible: ->
      elem = @getElem()
      return false if !elem
      return elem.visible()

    show: (msg) ->
      elem = @getElem()
      elem.find("span").html(msg)
      elem.show()

    hide: ->
      @elem.hide()

  class GenericGridNavigator extends JoystickInputController
    ACTIVE: "grid-nav-active"

    constructor: (options) ->
      @currentElem = null
      $(window).on "keydown", (e) =>
        switch e.keyCode
          when KEYS.LEFT
            @left()
          when KEYS.UP
            @up()
          when KEYS.RIGHT
            @right()
          when KEYS.DOWN
            @down()
          else
            return true
        return false

      window.addEventListener "message", (e) =>
        if e.data.filter == "NetflixMessage"
          switch e.data.msg 
            when "reset" then @reset()
            when "refresh" then @updateElements()

      @options = options
      $ =>
        elementPoller = setInterval =>
          @updateElements()
          if @elements.length > 0
            clearInterval elementPoller
            @activateFirstElement()
        , 200
      super

    reset: ->
      @updateElements()
      @activateFirstElement()

    activateFirstElement: ->
      if @options.default
        for def in @options.default
          matches = @elements.filter(def)
          if matches.length > 0
            @activate matches[0]
            return
      @activate @elements[0]

    updateElements: ->
      @elements = $([])
      lastPriority = 1
      for selector in @options.selectors
        selector.priority ||= 1
        f = $(selector.selector)
        # console.log selector.selector, "found", f.length, "elements"
        f = f.filter(":visible")
        # console.log selector.selector, "found", f.length, "elements after visible filter"
        @elements = @elements.add f
        break if selector.priority > lastPriority and f.length > 0
        lastPriority = selector.priority

    activate: (elem) ->
      elem = $(elem)
      return unless elem.length > 0
      if @currentElem
        $(@currentElem).removeClass(@currentConfig.class || @ACTIVE)

      @currentConfig = @getConfigFor(elem)
      elem.addClass(@currentConfig.class || @ACTIVE)
      @currentElem = elem
      @focus(elem)
      if @isFixed(elem)
        window.scrollTo(0, 0)
      else
        $(window).scrollTo(elem, duration: 150, offset: {left: 0, top: -200})

    isFixed: (elem) ->
      if elem.css("position") == "fixed"
        return true
      for e in elem.parents()
        if $(e).css("position") == "fixed"
          return true
      return false

    focus: (elem) ->
      anchor = elem.find("a").get(0) || elem
      anchor.focus()
      simulate elem.get(0), "mouseover"

    button: (buttonId, state) ->
      return unless @booted
      if state == 1
        switch buttonId
          when BUTTONS.A              then @select()
          when BUTTONS.B              then @cancel()
          when BUTTONS.Y              then @info()
          when BUTTONS.DPAD_UP        then @up()
          when BUTTONS.DPAD_DOWN      then @down()
          when BUTTONS.DPAD_LEFT      then @left()
          when BUTTONS.DPAD_RIGHT     then @right()
          when BUTTONS.LEFT_SHOULDER  then @left(5)
          when BUTTONS.RIGHT_SHOULDER then @right(5)

    select: ->
      @clickFocus()

    cancel: ->
      if document.activeElement and document.activeElement.tagName == "INPUT"
        @blurFocus()
        true
      else
        false

    info: ->

    clickFocus: ->
      elem = @currentElem
      config = @currentConfig
      if config?.click
        elem = elem.find(config.click)
      simulate $(elem).get(0), "click"

      if config?.selectOnClick
        requestAnimationFrame =>
          @updateElements()
          @activate @elements.filter(config?.selectOnClick).get(0)
      else if config?.refresh
        requestAnimationFrame => @updateElements()

      true

    getConfigFor: (elem) ->
      for selector in @options.selectors
        if elem.is(selector.selector)
          return selector

    blurFocus: ->
      document.activeElement.blur()
      true

    axis: (axisId, magnitude, state) ->
      switch axisId
        when AXES.LEFT_HORIZONTAL
          if magnitude < 0 then @left() else @right()
        when AXES.LEFT_VERTICAL
          if magnitude < 0 then @up() else @down()

    left:  (times = 1) -> @multiNavigate(-1, 0, times); true
    up:    (times = 1) -> @multiNavigate(0, -1, times); true
    down:  (times = 1) -> @multiNavigate(0, 1, times); true
    right: (times = 1) -> @multiNavigate(1, 0, times); true

    coordsFor: (x, y, elem) ->
      rect = elem.getBoundingClientRect()
      rect.top += window.scrollY
      rect.left += window.scrollX
      if x == 1
        return [rect.left, rect.top + rect.height / 2, rect]
      else if x == -1
        return [rect.right, rect.top + rect.height / 2, rect]
      else if y == 1
        return [rect.left, rect.top, rect]
      else if y == -1
        return [rect.left, rect.bottom, rect]
      else if x == 0 and y == 0
        return [rect.left + rect.width / 2, rect.top + rect.height / 2, rect]

    multiNavigate: (x, y, times) ->
      reference = @currentElem
      for i in [1..times]
        reference = $(@navigate(x, y, reference))
        break if reference.length == 0
      @activate reference
      window.requestAnimationFrame => @updateElements()

    navigate: (x, y, reference) ->
      bestOption = null
      if reference and reference.length > 0
        [ox, oy, _origRect] = @coordsFor(-x, -y, reference[0])
        bestScore = null

        for elem in @elements
          [_x, _y, _rect] = @coordsFor(x, y, elem)
          dx = _x - ox
          dy = _y - oy

          a_dx = Math.abs(dx)
          a_dy = Math.abs(dy)

          if x != 0
            origX = (_origRect.top + _origRect.height / 2)
            elemX = (_rect.top + _rect.height / 2)
            isValid = Math.abs(elemX - origX) < 150 # - _origRect.height and elemX < origX + _origRect.height
          else
            isValid = true
          continue unless isValid

          wrongAxisPenalty = 1
          if x == 1 and dx >= 0
            score = (dx * 1) + (a_dy * wrongAxisPenalty)
          else if x == -1 and dx <= 0
            score = (dx * -1) + (a_dy * wrongAxisPenalty)
          else if y == 1 and dy >= 0
            score = (dy * 1) + (a_dx * wrongAxisPenalty)
          else if y == -1 and dy <= 0
            score = (dy * -1) + (a_dx * wrongAxisPenalty)
          else
            score = null

          if score != null
            if bestScore == null or score < bestScore
              bestScore = score
              bestOption = elem
      bestOption

  class NetflixGridNavigator extends GenericGridNavigator
    info: ->
      if @currentElem.is(".agMovie")
        bits = @currentElem.find("a").data("uitrack").split(",")
        window.location.href = "https://www.netflix.com/WiMovie/#{bits[0]}?trkid=#{bits[1]}"

    cancel: ->
      return if super
      if @options.popups
        for popup in @options.popups
          if $(popup.selector).is(":visible")
            simulate $(popup.anchor).get(0), "click"
            return false
      if window.history.length <= 1
        chrome.runtime.sendMessage('closetab')
      else
        window.history.go(-1)

    navigate: (x, y, ref) ->
      $(".sliderButton").remove()
      super x, y, ref

    activate: (elem) ->
      elem = $(elem)
      super(elem)
      if elem.length > 0
        window.postMessage({filter: "NetflixNav", bob_id: elem.find("a.bobbable").attr("id"), action: "enter"}, "*")

        rect = elem[0].getBoundingClientRect()
        if (rect.right > document.body.clientWidth * 0.9)
          elem.parents(".slider").scrollTo(elem, duration: 150, offset: {left: -(document.body.clientWidth * 0.9) + rect.width, top: 0})
        else if (rect.left < document.body.clientWidth * 0.1)
          elem.parents(".slider").scrollTo(elem, duration: 150, offset: {left: -(document.body.clientWidth * 0.1), top: 0})

  class NetflixMovieDriver extends GenericGridNavigator
    ACTIVE: "controls-nav-active"

    constructor: (options) ->
      super options

    activate: (elem) ->
      elem = $(elem)
      super elem
      delay 0, @updateElements()

    message: (msg, args = {}) ->
      args.filter = "NetflixControl"
      args.event = msg
      window.postMessage args, "*"

    axis: (axisId, magnitude, state) ->
      $(".player-controls-wrapper").removeClass("display-none opacity-transparent")
      @updateElements()
      if axisId == AXES.RIGHT_HORIZONTAL
        if magnitude < 0 then @message "seekDelta", amount: -30000
        if magnitude > 0 then @message "seekDelta", amount: 30000
      super axisId, magnitude, state

    button: (buttonId, state) ->
      if state == 1
        switch buttonId
          when BUTTONS.START       then @message "pause"
          when BUTTONS.B           then window.history.back()
          when BUTTONS.A           then $(".postplay-still-container").click()
          when BUTTONS.DPAD_UP     then @message "adjustVolume", amount: 0.15
          when BUTTONS.DPAD_DOWN   then @message "adjustVolume", amount: -0.15
          when BUTTONS.DPAD_LEFT   then @message "seekDelta", amount: -5000
          when BUTTONS.DPAD_RIGHT  then @message "seekDelta", amount: 5000
          when BUTTONS.DPAD_SELECT then @message "mute"

  script = document.createElement("script")
  script.src = chrome.extension.getURL "controller.js"
  document.head.appendChild(script)

  if window.location.pathname.match("/WiPlayer")
    new NetflixMovieDriver
      selectors:
        selector: ".player-control-button:not(.player-hidden), .player-active .episode-list-item, .player-active .player-audio-tracks li, .player-active .player-timed-text-tracks li"
  else
    new NetflixGridNavigator
      default: ["li.profile", ".displayPagePlayable", ".agMovie"]
      popups: [
        {selector: "#seasonsNav", anchor: "#seasonSelector #selectorButton"}
      ]
      selectors: [
        # Profile selector
        { selector: ".profilesGate li.profile, ul.profiles li", click: "a, span", priority: 10 }
        # Nav bar
        { selector: "li.nav-item .content a, #searchTab a" }
        # Detail page
        { selector: ".displayPagePlayable", click: "a" }
        { selector: "#seasonSelector #selectorButton", refresh: true, class: "grid-nav-active-skinny" }
        { selector: "#seasonsNav .seasonItem", selectOnClick: "#seasonSelector #selectorButton", class: "grid-nav-active-skinny" }
        { selector: ".episodeList li"}
        # { selector: ".recommended .boxShot" }
        # General movie grid
        { selector: "div.agMovie", priority: 1 }
      ]

)(window.jQuery)

