# In-page version fo event simlulation
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

extend = (destination, source) ->
  for property of source
    destination[property] = source[property]
  destination

eventMatchers =
  HTMLEvents: /^(?:load|unload|abort|error|select|change|submit|reset|focus|blur|resize|scroll)$/
  MouseEvents: /^(?:click|dblclick|mouse(?:down|up|over|move|out))$/

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

# Utility method to help keep the control UI visible
lastX = 5
wiggleMouse = (elem = $("netflix-player")) ->
  lastX = (lastX + 1) % 5
  simulate elem, "mousemove", { pointerX: lastX, pointerY: 5 }

# Mechanism used to tell the extension to reset its element list in response to custom events
(($) ->
  msg = (m)->
    window.postMessage {filter: "NetflixMessage", msg: m}, "*"

  reset = -> msg "reset"
  refresh = -> msg "refresh"

  $(document).on "nflxProfiles.hideOverlay", reset
  $(document).on "nflxProfiles.gateOverlay", reset
  $(document).on "nflxProfiles.switch:start", reset
  $(document).ajaxComplete refresh

)(jQuery)

# Respond to control messages from the extension
player = window.netflix?.cadmium?.objects?.videoPlayer()
window.addEventListener "message", (e) ->
  if e.data.filter == "NetflixControl"
    switch e.data.event
      when "seekTo"
        wiggleMouse()
        player.seek e.data.seekTo
      when "seekDelta"
        wiggleMouse()
        player.seek player.getCurrentTime() + e.data.amount
      when "pause"
        if player.getPaused()
          player.play()
        else
          player.pause()
      when "mute"
        player.setMuted(!player.getMuted())
      when "adjustVolume"
        # simulate(jQuery(".player-control-button.volume").get(0), "mouseover", { pointerX: 5, pointerY: 6 })
        # wiggleMouse(jQuery(".player-control-button.volume").get(0))
        player.setVolume player.getVolume() + e.data.amount
      when "setVolume"
        simulate $("netflix-player"), "hover"
        player.setVolume e.data.level
  else if e.data.filter == "NetflixNav"
    switch e.data.action
      when "enter"
        clearTimeout getMovieInfo
        getMovieInfo = setTimeout ->
          jQuery("##{e.data.bob_id}").mouseenter()
        , 250
      when "close"
        window.close()


