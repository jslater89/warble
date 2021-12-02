package warble

import (
	"errors"

	"github.com/faiface/beep"
	"github.com/faiface/beep/effects"
	"github.com/faiface/beep/speaker"
	"github.com/google/uuid"
)

// Plugin code should only lock in WarbleEffects methods.
type WarbleEffects struct {
	ID            uuid.UUID
	Name          string
	SampleRate    beep.SampleRate
	baseStreamer  beep.StreamSeekCloser
	panStreamer   *effects.Pan
	gainStreamer  *effects.Gain
	pauseStreamer *beep.Ctrl
	buffer        *beep.Buffer
}

func NewEffects(id uuid.UUID, name string, sampleRate beep.SampleRate, streamer beep.StreamSeekCloser) *WarbleEffects {
	panStreamer := effects.Pan{
		Streamer: streamer,
		Pan:      0,
	}
	gainStreamer := effects.Gain{
		Streamer: &panStreamer,
		Gain:     0,
	}
	pauseStreamer := beep.Ctrl{
		Streamer: &gainStreamer,
		Paused:   false,
	}
	return &WarbleEffects{
		ID:            id,
		Name:          name,
		SampleRate:    sampleRate,
		baseStreamer:  streamer,
		panStreamer:   &panStreamer,
		gainStreamer:  &gainStreamer,
		pauseStreamer: &pauseStreamer,
	}
}

func NewBufferedEffects(id uuid.UUID, name string, sampleRate beep.SampleRate, buffer *beep.Buffer) *WarbleEffects {
	streamer := WrapWithNop(buffer.Streamer(0, buffer.Len()))
	panStreamer := effects.Pan{
		Streamer: &streamer,
		Pan:      0,
	}
	gainStreamer := effects.Gain{
		Streamer: &panStreamer,
		Gain:     0,
	}
	pauseStreamer := beep.Ctrl{
		Streamer: &gainStreamer,
		Paused:   false,
	}
	return &WarbleEffects{
		ID:            id,
		Name:          name,
		SampleRate:    sampleRate,
		buffer:        buffer,
		baseStreamer:  &streamer,
		panStreamer:   &panStreamer,
		gainStreamer:  &gainStreamer,
		pauseStreamer: &pauseStreamer,
	}
}

func (e *WarbleEffects) Len() int {
	if e.Buffered() {
		return e.buffer.Len()
	}
	return e.baseStreamer.Len()
}

func (e *WarbleEffects) Position() int {
	return e.baseStreamer.Position()
}

func (e *WarbleEffects) Play() {
	if e.Len() == e.Position() {
		e.Seek(0)
	}

	speaker.Play(e.pauseStreamer)
}

// TODO: gain, pan, etc
func (e *WarbleEffects) PlayBuffer(from int, to int) error {
	if e.buffer == nil {
		return errors.New("this stream is not a buffer")
	}

	newStreamer := effects.Gain{
		Gain: e.gainStreamer.Gain,
		Streamer: &effects.Pan{
			Pan:      e.panStreamer.Pan,
			Streamer: e.buffer.Streamer(from, to),
		},
	}
	speaker.Play(&newStreamer)
	return nil
}

func (e *WarbleEffects) Pan(pan float64) error {
	speaker.Lock()
	e.panStreamer.Pan = pan
	speaker.Unlock()
	println("Pan: {}", pan)
	return nil
}

func (e *WarbleEffects) Gain(gain float64) error {
	speaker.Lock()
	e.gainStreamer.Gain = gain
	speaker.Unlock()
	println("Gain: {}", gain)
	return nil
}

func (e *WarbleEffects) Seek(p int) error {
	speaker.Lock()
	err := e.baseStreamer.Seek(p)
	speaker.Unlock()
	return err
}

func (e *WarbleEffects) Pause(pause bool) error {
	speaker.Lock()
	e.pauseStreamer.Paused = pause
	speaker.Unlock()

	return nil
}

func (e *WarbleEffects) Stream(samples [][2]float64) (n int, ok bool) {
	return e.baseStreamer.Stream(samples)
}

func (e *WarbleEffects) Err() error {
	return e.baseStreamer.Err()
}

func (e *WarbleEffects) Close() error {
	return e.baseStreamer.Close()
}

func (e *WarbleEffects) Info() map[interface{}]interface{} {
	response := map[interface{}]interface{}{}
	response["id"] = e.ID.String()
	response["name"] = e.Name
	response["position"] = int64(e.baseStreamer.Position())
	response["length"] = int64(e.baseStreamer.Len())
	response["sampleRate"] = int64(e.SampleRate)
	response["buffered"] = e.Buffered()
	return response
}

func (e *WarbleEffects) Buffered() bool {
	return e.buffer != nil
}
