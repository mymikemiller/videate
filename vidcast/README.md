# VidCast

A video (and other media) podcast host and RSS feed generator incorporating
consumer feedback to automatically download recommended media.

## Usage

```
cd vidcast
```

### Run VidCast server
```
dart bin/server.dart
```

-or-

### Run VidCast server via automator

Double click vidcast.app in the root vidcast directory on a mac. This app can
be placed in the user's Login Items to launched automatically on startup

### Prerequisites

Get Dart: (https://dart.dev/get-dart)

```
 brew tap dart-lang/dart
 brew install dart
```

Get app dependencies:

```
cd vidcast
pub get
```

Set up environment variables: The machine's environment variables are used as
expected when running the application from the terminal, but VSCode does not
pick up the machine's environment variables when debugging. Values can be
specified in the launch.json file for each configuration, but since we have
that file in source control but need different values per machine, we use the
dotenv package and put the environment variables in a local .env file.

Variable | Definition | Examples
--- | --- | ---
*VIDCAST_BASE_URL* | The base address at which the running server can be found | http://localhost:8080, http://videate.org

## Development (VSCode)
Open the videate/videate.code-workspace workspace in VSCode

### Debug VidCast server
Set Run Configuration to "VidCast (vidcast)"
Start Debugging

### Debug Tests
Set Run Configuration to "VidCast (vidcast)"
Start Debugging

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
