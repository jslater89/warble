# vibrato

This Go package implements the host-side of the Flutter [vibrato](https://github.com/jslater89/vibrato) plugin.

## Usage

Import as:

```go
import vibrato "github.com/jslater89/vibrato/go"
```

Then add the following option to your go-flutter [application options](https://github.com/go-flutter-desktop/go-flutter/wiki/Plugin-info):

```go
flutter.AddPlugin(&vibrato.VibratoPlugin{}),
```
