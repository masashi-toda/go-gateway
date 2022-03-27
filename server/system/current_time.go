package system

import "time"

var _ = func() *time.Location {
	loc, err := time.LoadLocation("Asia/Tokyo")
	if err != nil {
		loc = time.FixedZone("Asia/Tokyo", 9*60*60)
	}
	time.Local = loc
	return loc
}()

// CurrentTime - server current time
var CurrentTime = time.Now
