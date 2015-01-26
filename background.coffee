chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  chrome.tabs.query { currentWindow: true, active: true }, (tabs) ->
    chrome.tabs.remove(tabs[0].id)