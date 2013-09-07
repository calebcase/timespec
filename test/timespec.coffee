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
  periods =
    'minutes': (date, count) ->
      date.setMinutes(date.getMinutes() + count)
    'hours': (date, count) ->
      date.setHours(date.getHours() + count)
    'days': (date, count) ->
      date.setDate(date.getDate() + count)
    'weeks': (date, count) ->
      date.setDate(date.getDate() + 7 * count)
    'months': (date, count) ->
      date.setMonth(date.getMonth() + count)
    'years': (date, count) ->
      date.setFullYear(date.getFullYear() + count)

  directions =
    '-': -1
    '+': 1

  for period, mutate of periods
    for period_count in [0..10]
      for period_direction_string, period_direction_multiplier of directions
        if period_count is 0
          if period_direction_multiplier is -1
            continue # Skip the -0 case.
          period_string = ''
        else
          period_string = " #{period_direction_string} #{period_count} #{period}"

        do (period, mutate, period_count, period_string, period_direction_multiplier) ->
          # start -> timespec -> spec_base -> date -> Various m/d/y Formats
          do () ->
            target = new Date(2040, 0, 2)
            mutate(target, period_direction_multiplier * period_count)

            date_strings = [
              'Jan 2 2040' + period_string
              'Jan 2, 2040' + period_string
              '2040-1-2' + period_string
              '2.1.2040' + period_string
              '2 Jan 2040' + period_string
              '1/2/2040' + period_string
            ]
            
            for date_string in date_strings
              do (date_string) ->
                describe "'#{date_string}'", ->
                  it "should return '#{target.toString()}'", ->
                    equal_to_the_day target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> Various m/d Formats
          do () ->
            target = new Date((new Date()).getFullYear(), 0, 2)
            mutate(target, period_direction_multiplier * period_count)

            date_strings = [
              'Jan 2' + period_string
              '2 Jan' + period_string
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
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'Monday' + period_string
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
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'today' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> TOMORROW
          do () ->
            target = new Date()
            target.setDate(target.getDate() + 1)
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'Tomorrow' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> YESTERDAY
          do () ->
            target = new Date()
            target.setDate(target.getDate() - 1)
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'Yesterday' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> concatenated_date
          do () ->
            targets_pre =
              '20401': new Date(2040, 0, 0)
              '204001': new Date(2040, 0, 0)
              '2040012': new Date(2040, 0, 2)
              '20400102': new Date(2040, 0, 2)
            targets = {}
            for date_string, target of targets
              mutate(target, period_direction_multiplier * period_count)
              targets[date_string + period_string] = target

            for date_string, target of targets
              do (date_string, target) ->
                describe "'#{date_string}'", ->
                  it "should return '#{target.toString()}'", ->
                    equal_to_the_day target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> NEXT inc_dec_period
          do () ->
            target = new Date()
            target.setMonth(target.getMonth() + 1)
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'next month' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> NEXT count inc_dec_period
          do () ->
            for count in [1..24]
              do (count) ->
                target = new Date()
                target.setMonth(target.getMonth() + count)
                mutate(target, period_direction_multiplier * period_count)

                date_string = "next #{count} months" + period_string
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
              mutate(target, period_direction_multiplier * period_count)

              date_string = "NEXT #{name}" + period_string
              describe "'#{date_string}'", ->
                it "should return '#{target.toString()}'", ->
                  equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> LAST inc_dec_period
          do () ->
            target = new Date()
            target.setMonth(target.getMonth() - 1)
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'LAST month' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> date -> LAST count inc_dec_period
          do () ->
            for count in [1..24]
              do (count) ->
                target = new Date()
                target.setMonth(target.getMonth() - count)
                mutate(target, period_direction_multiplier * period_count)

                date_string = "LAST #{count} months" + period_string
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
              mutate(target, period_direction_multiplier * period_count)

              date_string = "last #{name}" + period_string
              describe "'#{date_string}'", ->
                it "should return '#{target.toString()}'", ->
                  equal_to_the_minute target, (ts.parse date_string)

          # start -> timespec -> spec_base -> NOW
          do () ->
            target = new Date()
            mutate(target, period_direction_multiplier * period_count)

            date_string = 'NOW' + period_string
            describe "'#{date_string}'", ->
              it "should return '#{target.toString()}'", ->
                equal_to_the_minute target, (ts.parse date_string)
