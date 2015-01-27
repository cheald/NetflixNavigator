# Netflix Navigator

## About

This is a Chrome extension that uses the HTML5 Gamepad API to provide game controller (and keyboard) navigator and control for Netflix. Chrome 40+ is required. The primary use case is for integration with an HTPC (ie, Kodi with ChromeLauncher).

This has only been tested with XBox 360 controllers so far.

## Features

Currently supported features:

* Profile selection
* Movie navigation with customized movie info pane
* Playback control (pause, mute, seek/scrub, volume, next episode)

To do:

* Subtitle, season, and episode selection from within the player interface
* On-screen controller-driven keyboard for searches
* Configuration interface for remapping controls

## How to use

Install the extension from [the Chrome web store](https://chrome.google.com/webstore/detail/netflix-navigator/baifcdmbdpacahdlfeamhgijijeflmlh). Go to Netflix. Use your controller.

### In navigation mode:

* A selects the current-highlighted item
* B will go back to the previous screen, or exit Netflix if there are no more screens to go back to
* Y will go to the detail page for the currently-selected movie
* The left stick or D-pad navigate movies and menu items
* The left and right shoulder buttons zip forward/back 5 items at a time

### During playback

* Start pauses/unpauses the movie
* Select mutes/unmutes the movie
* D-Pad up/down change volume
* D-Pad right/left scrubs back/forward (5 sec at a time)
* The right analog stick seeks back/forward (30 sec at a time)
* B returns to movie selection

## Contributing

Guidelines:

* The Coffeescript files are canonical; they should be edited, then compiled rather than editing the JS directly

How To:

* Clone this repository
* Make your changes and publish to your own GitHub copy of the repository
* Issue a pull request. More information with the pull request is more likely to end up with a merge.