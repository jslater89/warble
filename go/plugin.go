package warble

import (
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"os"
	"strings"

	"github.com/faiface/beep"
	"github.com/faiface/beep/mp3"
	"github.com/faiface/beep/speaker"
	"github.com/faiface/beep/vorbis"
	"github.com/faiface/beep/wav"
	flutter "github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/google/uuid"
)

const channelName = "warble"

// WarblePlugin implements flutter.Plugin and handles method.
type WarblePlugin struct {
	Streamers map[uuid.UUID]*WarbleEffects
}

func New() *WarblePlugin {
	return &WarblePlugin{
		Streamers: map[uuid.UUID]*WarbleEffects{},
	}
}

var _ flutter.Plugin = &WarblePlugin{} // compile-time type check

func decodeSource(name string, source io.ReadCloser) (s beep.StreamSeekCloser, fmt beep.Format, err error) {
	n := strings.ToLower(name)
	if strings.HasSuffix(n, "mp3") {
		return mp3.Decode(source)
	} else if strings.HasSuffix(n, "wav") {
		return wav.Decode(source)
	} else if strings.HasSuffix(n, "ogg") {
		return vorbis.Decode(source)
	} else {
		return nil, beep.Format{}, errors.New("unsupported stream")
	}
}

// InitPlugin initializes the plugin.
func (p *WarblePlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	speaker.Init(beep.SampleRate(44100), 4410)
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.StandardMethodCodec{})
	channel.HandleFunc("wrapFile", p.handleWrapFile)
	channel.HandleFunc("wrapBuffer", p.handleWrapBuffer)
	channel.HandleFunc("listStreams", p.handleListStreams)
	channel.HandleFunc("closeStream", p.handleCloseStream)
	channel.HandleFunc("pauseStream", p.handlePauseStream)
	channel.HandleFunc("seekStream", p.handleSeekStream)
	channel.HandleFunc("streamInfo", p.handleStreamInfo)
	channel.HandleFunc("playStream", p.handlePlayStream)
	channel.HandleFunc("playBuffered", p.handlePlayBuffered)
	return nil
}

func (p *WarblePlugin) handleWrapFile(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	f, err := os.Open(args["file"].(string))
	name := args["name"].(string)
	buffered := args["buffered"].(bool)

	if err != nil {
		return nil, err
	}
	s, beepFmt, err := decodeSource(args["file"].(string), f)
	if err != nil {
		return nil, err
	}

	var id = uuid.New()
	if buffered {
		buf := beep.NewBuffer(beepFmt)
		buf.Append(s)

		p.Streamers[id] = NewBufferedEffects(id, name, beepFmt.SampleRate, buf)
	} else {
		p.Streamers[id] = NewEffects(id, name, beepFmt.SampleRate, s)
	}

	return p.Streamers[id].Info(), nil
}

func (p *WarblePlugin) handleWrapBuffer(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	f := ioutil.NopCloser(bytes.NewReader(args["buffer"].([]byte)))
	fmt := args["format"].(string)
	name := args["name"].(string)
	buffered := args["buffered"].(bool)

	s, beepFmt, err := decodeSource(fmt, f)
	if err != nil {
		return nil, err
	}

	var id = uuid.New()
	if buffered {
		buf := beep.NewBuffer(beepFmt)
		buf.Append(s)

		p.Streamers[id] = NewBufferedEffects(id, name, beepFmt.SampleRate, buf)
	} else {
		p.Streamers[id] = NewEffects(id, name, beepFmt.SampleRate, s)
	}

	return p.Streamers[id].Info(), nil
}

func (p *WarblePlugin) handleCloseStream(arguments interface{}) (reply interface{}, err error) {
	stream, err := p.getStream(arguments)
	if err != nil {
		return nil, err
	}

	if err := stream.Close(); err != nil {
		return nil, err
	}

	delete(p.Streamers, stream.ID)
	return nil, nil
}

func (p *WarblePlugin) handlePauseStream(arguments interface{}) (reply interface{}, err error) {
	return nil, errors.New("Not implemented")
}

func (p *WarblePlugin) handleSeekStream(arguments interface{}) (reply interface{}, err error) {
	stream, err := p.getStream(arguments)

	if err != nil {
		return nil, err
	}

	args := arguments.(map[interface{}]interface{})
	position := int(args["position"].(int32))

	err = stream.Seek(position)
	if err != nil {
		return nil, err
	}
	return nil, nil
}

func (p *WarblePlugin) handlePlayStream(arguments interface{}) (reply interface{}, err error) {
	stream, err := p.getStream(arguments)
	if err != nil {
		return nil, err
	}

	stream.Play()
	return nil, nil
}

func (p *WarblePlugin) handlePlayBuffered(arguments interface{}) (reply interface{}, err error) {
	args := arguments.(map[interface{}]interface{})
	stream, err := p.getStream(arguments)
	if err != nil {
		return nil, err
	}

	from := int(args["from"].(int32))
	to := int(args["to"].(int32))

	stream.PlayBuffer(from, to)
	return nil, nil
}

func (p *WarblePlugin) handleStreamInfo(arguments interface{}) (reply interface{}, err error) {
	stream, err := p.getStream(arguments)
	if err != nil {
		return nil, err
	}

	return stream.Info(), nil
}

func (p *WarblePlugin) getStream(arguments interface{}) (stream *WarbleEffects, err error) {
	args := arguments.(map[interface{}]interface{})
	id, err := uuid.Parse(args["id"].(string))

	if err != nil {
		return nil, err
	}

	if val, ok := p.Streamers[id]; ok {
		return val, nil
	} else {
		return nil, errors.New("stream does not exist")
	}
}

func (p *WarblePlugin) handleListStreams(arguments interface{}) (reply interface{}, err error) {
	streams := map[interface{}]interface{}{}

	for id, streamer := range p.Streamers {
		streams[id.String()] = streamer.Name
	}

	return streams, nil
}

type WarbleEffects struct {
	ID         uuid.UUID
	Name       string
	SampleRate beep.SampleRate
	streamer   beep.StreamSeekCloser
	buffer     *beep.Buffer
}

func NewEffects(id uuid.UUID, name string, sampleRate beep.SampleRate, streamer beep.StreamSeekCloser) *WarbleEffects {
	return &WarbleEffects{
		ID:         id,
		Name:       name,
		SampleRate: sampleRate,
		streamer:   streamer,
	}
}

func NewBufferedEffects(id uuid.UUID, name string, sampleRate beep.SampleRate, buffer *beep.Buffer) *WarbleEffects {
	streamer := WrapWithNop(buffer.Streamer(0, buffer.Len()))
	return &WarbleEffects{
		ID:         id,
		Name:       name,
		SampleRate: sampleRate,
		buffer:     buffer,
		streamer:   streamer,
	}
}

func (e *WarbleEffects) Len() int {
	return e.streamer.Len()
}

func (e *WarbleEffects) Position() int {
	return e.streamer.Position()
}

func (e *WarbleEffects) Play() {
	speaker.Play(e.streamer)
}

// TODO: gain, pan, etc
func (e *WarbleEffects) PlayBuffer(from int, to int) error {
	if e.buffer == nil {
		return errors.New("this stream is not a buffer")
	}

	newStreamer := e.buffer.Streamer(from, to)
	speaker.Play(newStreamer)
	return nil
}

func (e *WarbleEffects) Seek(p int) error {
	speaker.Lock()
	err := e.streamer.Seek(p)
	speaker.Unlock()
	return err
}

func (e *WarbleEffects) Stream(samples [][2]float64) (n int, ok bool) {
	return e.streamer.Stream(samples)
}

func (e *WarbleEffects) Err() error {
	return e.streamer.Err()
}

func (e *WarbleEffects) Close() error {
	return e.streamer.Close()
}

func (e *WarbleEffects) Info() map[interface{}]interface{} {
	response := map[interface{}]interface{}{}
	response["id"] = e.ID.String()
	response["name"] = e.Name
	response["position"] = int64(e.streamer.Position())
	response["length"] = int64(e.streamer.Len())
	response["sampleRate"] = int64(e.SampleRate)
	response["buffered"] = e.buffer != nil
	return response
}
