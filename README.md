# CAVOK

CAVOK is an aviation weather app for iOS. It visualizes textual aviation weather observations ([METAR](https://en.wikipedia.org/wiki/METAR)) and forecasts ([TAF](https://en.wikipedia.org/wiki/Terminal_aerodrome_forecast)) on a map for quick overlook of weather in the selected region.

CAVOK is an abbreviation for Ceiling And Visibility OK, indicating no significant weather (thunderstorms), ceilings are greater than 5,000 ft and visibility 10 km or more.

## Requirements

* [Xcode 8](https://developer.apple.com/xcode)
* [Carthage](https://github.com/Carthage/Carthage)

## Initial setup

#### Download dependencies.
```sh
carthage bootstrap

git submodule update --init

cd libs/WhirlyGlobe­Maply
git submodule update --init

```

#### Setup properties
```sh
cp CAVOK/CAVOK.plist.template CAVOK/CAVOK.plist 
```

Edit `CAVOK/CAVOK.plist` with
* `basemapURL` add [MapBox](https://www.mapbox.com) access token or any other [TileJSON layer](https://github.com/mapbox/tilejson-spec).
