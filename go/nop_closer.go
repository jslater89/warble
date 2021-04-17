package warble

import (
	"github.com/faiface/beep"
)

type WarbleNopCloser struct {
	streamer beep.StreamSeeker
}

func WrapWithNop(streamer beep.StreamSeeker) WarbleNopCloser {
	return WarbleNopCloser{
		streamer: streamer,
	}
}

func (e *WarbleNopCloser) Len() int {
	return e.streamer.Len()
}

func (e *WarbleNopCloser) Position() int {
	return e.streamer.Position()
}

func (e *WarbleNopCloser) Seek(p int) error {
	err := e.streamer.Seek(p)
	return err
}

func (e *WarbleNopCloser) Stream(samples [][2]float64) (n int, ok bool) {
	return e.streamer.Stream(samples)
}

func (e *WarbleNopCloser) Err() error {
	return e.streamer.Err()
}

func (c *WarbleNopCloser) Close() error {
	return nil
}
