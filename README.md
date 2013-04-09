timespec
========

Parse time-like phrases into a javascript Date.

Inspired by the unix program [at] [1] which includes a 'timespec' for
parsing time-like phrases into dates. This extends the original scope to
include the **past** and various other changes. It's similar, but not
exactly the same.

usage
-----

```javascript
timespec = require('timespec');

var is_now = timespec.parse('now');
var is_now_last_week = timespec.parse('last week');

var is_noon_today = timespec.parse('noon');
var is_noon_yesterday = timespec.parse('noon yesterday');

var is_12_weeks_ago = timespec.parse('last 12 weeks');
var is_12_weeks_from_now = timespec.parse('next 12 weeks');

var is_2_hour_from_now = timespec.parse('now - 2 hours');
```

  [1]: http://en.wikipedia.org/wiki/At_%28Unix%29 "at"
