package vibrato

import (
	"bytes"
	"io/ioutil"
	"os"

	"github.com/faiface/beep"
	"github.com/faiface/beep/mp3"
	"github.com/faiface/beep/speaker"
	flutter "github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
)

const channelName = "vibrato"

// VibratoPlugin implements flutter.Plugin and handles method.
type VibratoPlugin struct {
	// TODO: map streamers to UUIDs for control
}

var _ flutter.Plugin = &VibratoPlugin{} // compile-time type check

// InitPlugin initializes the plugin.
func (p *VibratoPlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	speaker.Init(beep.SampleRate(44100), 4410)
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.StandardMethodCodec{})
	channel.HandleFunc("playFile", p.handlePlayFile)
	channel.HandleFunc("playBuffer", p.handlePlayBuffer)
	return nil
}

// TODO: return stream ID
// TODO: get decoder by filename
func (p *VibratoPlugin) handlePlayFile(arguments interface{}) (reply interface{}, err error) {
	println("Arguments: {}", arguments)
	f, err := os.Open(arguments.(map[interface{}]interface{})["file"].(string))
	if err != nil {
		return nil, err
	}
	s, fmt, err := mp3.Decode(f)
	if err != nil {
		return nil, err
	}

	println("{}", fmt.SampleRate)

	speaker.Play(s)
	return "", nil
}

// TODO: return stream ID
// TODO: accept asset type as argument
func (p *VibratoPlugin) handlePlayBuffer(arguments interface{}) (reply interface{}, err error) {
	println("Arguments: {}", arguments)
	f := ioutil.NopCloser(bytes.NewReader(arguments.(map[interface{}]interface{})["buffer"].([]byte)))
	s, fmt, err := mp3.Decode(f)
	if err != nil {
		return nil, err
	}

	println("{}", fmt.SampleRate)

	speaker.Play(s)
	return "", nil
}
