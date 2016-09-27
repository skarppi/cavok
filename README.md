# CAVOK

CAVOK is an aviation weather app for iOS. It visualizes textual aviation weather observations ([METAR](https://en.wikipedia.org/wiki/METAR)) and forecasts ([TAF](https://en.wikipedia.org/wiki/Terminal_aerodrome_forecast)) on a map for quick overlook of weather in selected region.

![screenshot](https://github.com/skarppi/cavok/raw/master/screenshot.jpg "Screenshot")

CAVOK is an abbreviation for Ceiling And Visibility OK, indicating no significant weather (thunderstorms), ceilings are greater than 5,000 ft and visibility 10 km or more.

Data sources include

* METAR/TAF worldwide by [ADDS data server](https://aviationweather.gov/adds/dataserver)
## Requirements

* [Xcode 8](https://developer.apple.com/xcode)
* [Carthage](https://github.com/Carthage/Carthage)

## Initial setup

```sh
carthage bootstrap

git submodule update --init

cd libs/WhirlyGlobe
git submodule update --init

cp CAVOK/CAVOK.template.plist CAVOK/CAVOK.plist
```

Edit `CAVOK/CAVOK.plist` with missing data
* `basemapURL` add [MapBox](https://www.mapbox.com) access token or any other [TileJSON](https://github.com/mapbox/tilejson-spec)
