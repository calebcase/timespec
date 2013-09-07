should = require 'should'
ts = require '../timespec.js'

# These aren't perfect, but the likelyhood you'd hit the cutoff is so
# low that it probably won't be a problem worth addressing.
equal_to_the_minute = (left, right) ->
  try
    right.getFullYear().should.equal left.getFullYear()
    right.getMonth().should.equal left.getMonth()
    right.getDay().should.equal left.getDay()
    right.getDate().should.equal left.getDate()
    right.getHours().should.equal left.getHours()
    right.getMinutes().should.equal left.getMinutes()
  catch e
    throw Error "!= '#{right.toString()}' (to the minute)."

equal_to_the_day = (left, right) ->
  try
    right.getFullYear().should.equal left.getFullYear()
    right.getMonth().should.equal left.getMonth()
    right.getDay().should.equal left.getDay()
    right.getDate().should.equal left.getDate()
  catch e
    throw Error "!= '#{right.toString()}' (to the day)."

describe 'Parsing', ->
  # start -> timespec -> spec_base -> date -> Various m/d/y Formats
  do () ->
    target = new Date(2040, 0, 2)

    date_strings = [
      'Jan 2 2040'
      'Jan 2, 2040'
      '2040-1-2'
      '2.1.2040'
      '2 Jan 2040'
      '1/2/2040'
    ]
    
    for date_string in date_strings
      do (date_string) ->
        describe "'#{date_string}'", ->
          it "should return '#{target.toString()}'", ->
            equal_to_the_day target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> Various m/d Formats
  do () ->
    target = new Date((new Date()).getFullYear(), 0, 2)

    date_strings = [
      'Jan 2'
      '2 Jan'
    ]

    for date_string in date_strings
      do (date_string) ->
        describe "'#{date_string}'", ->
          it "should return '#{target.toString()}'", ->
            equal_to_the_day target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> day_of_week
  do () ->
    # Figure out next Monday.
    target = new Date()
    target.setDate target.getDate() + (1 - target.getDay())

    date_string = 'Monday'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_day target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> TODAY
  do () ->
    target = new Date()
    target.setHours(0)
    target.setMinutes(0)
    target.setSeconds(0)
    target.setMilliseconds(0)

    date_string = 'today'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> TOMORROW
  do () ->
    target = new Date()
    target.setDate(target.getDate() + 1)

    date_string = 'Tomorrow'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> YESTERDAY
  do () ->
    target = new Date()
    target.setDate(target.getDate() - 1)

    date_string = 'Yesterday'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> concatenated_date
  do () ->
    targets =
      '20401': new Date(2040, 0, 0)
      '204001': new Date(2040, 0, 0)
      '2040012': new Date(2040, 0, 2)
      '20400102': new Date(2040, 0, 2)

    for date_string, target of targets
      do (date_string, target) ->
        describe "'#{date_string}'", ->
          it "should return '#{target.toString()}'", ->
            equal_to_the_day target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> NEXT inc_dec_period
  do () ->
    target = new Date()
    target.setMonth(target.getMonth() + 1)

    date_string = 'next month'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> NEXT count inc_dec_period
  do () ->
    for count in [1..24]
      do (count) ->
        target = new Date()
        target.setMonth(target.getMonth() + count)

        date_string = "next #{count} months"
        describe "'#{date_string}'", ->
          it "should return '#{target.toString()}'", ->
            equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> NEXT day_of_week
  do () ->
    targets =
      'sun': 0
      'mon': 1
      'tue': 2
      'wed': 3
      'thu': 4
      'fri': 5
      'sat': 6

    for name, day of targets
      target = new Date()
      target.setDate(target.getDate() + (day - target.getDay()) + 7)

      date_string = "NEXT #{name}"
      describe "'#{date_string}'", ->
        it "should return '#{target.toString()}'", ->
          equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> LAST inc_dec_period
  do () ->
    target = new Date()
    target.setMonth(target.getMonth() - 1)

    date_string = 'LAST month'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> LAST count inc_dec_period
  do () ->
    for count in [1..24]
      do (count) ->
        target = new Date()
        target.setMonth(target.getMonth() - count)

        date_string = "LAST #{count} months"
        describe "'#{date_string}'", ->
          it "should return '#{target.toString()}'", ->
            equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> date -> LAST day_of_week
  do () ->
    targets =
      'sun': 0
      'mon': 1
      'tue': 2
      'wed': 3
      'thu': 4
      'fri': 5
      'sat': 6

    for name, day of targets
      target = new Date()
      if target.getDay() is day
        target.setDate(target.getDate() - 7)
      target.setDate(target.getDate() + (day - target.getDay()))

      date_string = "last #{name}"
      describe "'#{date_string}'", ->
        it "should return '#{target.toString()}'", ->
          equal_to_the_minute target, (ts.parse date_string)

  # start -> timespec -> spec_base -> NOW
  do () ->
    target = new Date()

    date_string = 'NOW'
    describe "'#{date_string}'", ->
      it "should return '#{target.toString()}'", ->
        equal_to_the_minute target, (ts.parse date_string)
