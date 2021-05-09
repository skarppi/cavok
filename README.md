# CAV-OK

CAV-OK is an aviation weather app for iOS. It visualizes textual aviation weather observations ([METAR](https://en.wikipedia.org/wiki/METAR)) and forecasts ([TAF](https://en.wikipedia.org/wiki/Terminal_aerodrome_forecast)) on a map for quick overlook of weather in a selected region.

![screenshot](https://github.com/skarppi/cavok/raw/master/screenshot.jpg "Screenshot")

Word CAVOK is an abbreviation for Ceiling And Visibility OK, indicating no significant weather (thunderstorms), ceilings are greater than 5,000 ft and visibility 10 km or more. In short, it means a great weather for flying.

Data sources include

* METAR/TAF worldwide by [ADDS data server](https://aviationweather.gov/adds/dataserver)
* Finnish unofficial [AWS-METARS](https://ilmailusaa.fi/info.html#info-location-aws) 
* Finnish airspaces [CAVOK-server](https://github.com/skarppi/cavok-server)

In addition to map overlays CAVOK allows you to configure quick links to any website so that all your favorite weather information is available in one app.

## Requirements

* [Xcode 11](https://developer.apple.com/xcode)
* [SwiftLint](https://github.com/realm/SwiftLint)

## Initial setup

```sh
brew install swiftlint

git submodule update --init

cd libs/WhirlyGlobe
git submodule update --init

cp CAVOK/CAVOK.template.plist CAVOK/CAVOK.plist
```

Edit `CAVOK/CAVOK.plist` with missing data
* `basemapURL` add [MapBox](https://www.mapbox.com) access token or any other [TileJSON](https://github.com/mapbox/tilejson-spec)

## Customizations

Application can be customized by editing *CAVOK.plist*.

- modules for observation visualizations
  - steps used for color ramp 
- initial set of external links in webview
  - title
  - url with optional {lat}, {lon} replacements for last known location
  - optional CSS selectors for hiding elements
