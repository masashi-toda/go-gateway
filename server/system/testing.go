package system

import (
	"testing"
	"time"
)

var (
	TestingTime, _ = time.Parse(time.RFC3339, "2022-12-24T00:00:00+09:00")
)

func RunTest(t *testing.T, name string, f func(*testing.T)) bool {
	defer func() {
		CurrentTime = time.Now
	}()
	CurrentTime = func() time.Time { return TestingTime }

	return t.Run(name, f)
}
