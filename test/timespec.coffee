should = require 'should'
ts = require '../timespec.js'

equalish = (left, right, period, timezone, time_base, relative = false) ->
  if right is null then return
  if right instanceof Error then throw right

  right_string = if timezone then right.toUTCString() else right.toString()
  if time_base or period is 'minutes' or period is 'hours'
    if relative and not time_base
      if Math.abs(left.getTime() - right.getTime()) > 60000
        throw Error "!= '#{right_string}' (to the minute)."
    else
      try
        right.getFullYear().should.equal left.getFullYear()
        right.getMonth().should.equal left.getMonth()
        right.getDay().should.equal left.getDay()
        right.getDate().should.equal left.getDate()
        right.getHours().should.equal left.getHours()
        right.getMinutes().should.equal left.getMinutes()
      catch
        throw Error "!= '#{right_string}' (to the minute)."
  else
    if relative and not time_base
      if Math.abs(left.getTime() - right.getTime()) > 60000 * 60 * 24
        throw Error "!= '#{right_string}' (to the day)."
    else
      try
        right.getFullYear().should.equal left.getFullYear()
        right.getMonth().should.equal left.getMonth()
        right.getDay().should.equal left.getDay()
        right.getDate().should.equal left.getDate()
      catch
        throw Error "!= '#{right_string}' (to the day)."

describe 'Parsing', ->
  garbages = ['', 'n\'t']

  whitespaces = [' ', '_']

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

  period_counts = [0..5]

  directions =
    '-': -1
    '+': 1

  timezones = ['', 'UTC ']

  time_bases =
    '': null
    '1234 ':
      h: 12
      m: 34
    '12 am ':
      h: 0
      m: 0
    '12 pm ':
      h: 12
      m: 0
    '12:34 ':
      h: 12
      m: 34
    '12:34 am ':
      h: 0
      m: 34
    '12:34 pm ':
      h: 12
      m: 34
    'NOON ':
      h: 12
      m: 0
    'midnight ':
      h: 0
      m: 0
    'TeaTime ':
      h: 16
      m: 0

  counts = [1..12]

  parse = (garbage, string) ->
    parsed = null

    if garbage
      failed = false

      try
        parsed = ts.parse string
      catch
        failed = true
      if not failed
        return Error "Garbage '#{string}' parsed when it shouldn't have."
      return null
    else
      try
        parsed = ts.parse string
      catch e
        return e

    return parsed

  # Thank you MDN:
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
  rand = (min, max) ->
    return Math.floor(Math.random() * (max - min + 1) + min)

  replace = (string, index, char) ->
    return (string.substr 0, index) + char + (string.substr index + 1)

  garburate = (garbage, string) ->
    copy = string
    if garbage
      positions = {}
      for change in [0..rand 1, string.length - 1]
        positions["#{(rand 0, string.length - 1)}"] = true
      for istr of positions
        i = parseInt(istr, 10)

        # Random (new) lowercase letter at a random position.
        c = String.fromCharCode 97 + (rand 0, 25)
        while c is string[i].toLowerCase()
          c = String.fromCharCode 97 + (rand 0, 25)
        string = replace string, i, c
    return string

  rebase = (time, timezone, time_base) ->
    if timezone
      if time_base
        rebased = new Date(Date.UTC time.getFullYear(), time.getMonth(), time.getDate(), time_base.h, time_base.m)
      else
        rebased = new Date(Date.UTC time.getFullYear(), time.getMonth(), time.getDate())
    else
      rebased = time
      if time_base
        time.setHours time_base.h
        time.setMinutes time_base.m
    return rebased

  for garbage in garbages
    do (garbage) ->
      for whitespace in whitespaces
        w = (string) ->
          return string.replace /[ ]/g, whitespace
        do (w) ->
          for period, mutate of periods
            for period_count in period_counts
              do (period_count) ->
                for period_direction_string, period_direction_multiplier of directions
                  if period_count is 0
                    if period_direction_multiplier is -1
                      continue # Skip the -0 case.
                    period_string = ''
                  else
                    period_string = " #{period_direction_string} #{period_count} #{period}"

                  do (period_string) ->
                    # start -> timespec -> spec_base -> NOW
                    do () ->
                      target = new Date()
                      mutate(target, period_direction_multiplier * period_count)

                      date_string = w(garburate garbage, 'NOW' + period_string)
                      result = parse garbage, date_string
                      describe "'#{date_string}'", ->
                        it "should#{garbage} return '#{target.toString()}'", ->
                          equalish target, result, period, '', null, true

                    for timezone in timezones
                      do (timezone) ->
                        for time_base_string, time_base of time_bases
                          time_base_string = time_base_string + timezone
                          if time_base_string is 'UTC '
                            continue

                          # start -> timespec -> spec_base -> date -> Various m/d/y Formats
                          do () ->
                            target = new Date(2040, 0, 2)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_strings = [
                              w(garburate garbage, time_base_string + 'Jan 2 2040' + period_string)
                              w(garburate garbage, time_base_string + 'Jan 2, 2040' + period_string)
                              w(garburate garbage, time_base_string + '2040-1-2' + period_string)
                              w(garburate garbage, time_base_string + '2.1.2040' + period_string)
                              w(garburate garbage, time_base_string + '2 Jan 2040' + period_string)
                              w(garburate garbage, time_base_string + '1/2/2040' + period_string)
                            ]

                            for date_string in date_strings
                              do (date_string) ->
                                result = parse garbage, date_string
                                describe "'#{date_string}'", ->
                                  target_string = if timezone then target.toUTCString() else target.toString()
                                  it "should#{garbage} return '#{target_string}'", ->
                                    equalish target, result, period, timezone, time_base

                          # start -> timespec -> spec_base -> date -> Various m/d Formats
                          do () ->
                            target = new Date((new Date()).getFullYear(), 0, 2)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_strings = [
                              w(garburate garbage, time_base_string + 'Jan 2' + period_string)
                              w(garburate garbage, time_base_string + '2 Jan' + period_string)
                            ]

                            for date_string in date_strings
                              do (date_string) ->
                                result = parse garbage, date_string
                                describe "'#{date_string}'", ->
                                  target_string = if timezone then target.toUTCString() else target.toString()
                                  it "should#{garbage} return '#{target_string}'", ->
                                    equalish target, result, period, timezone, time_base

                          # start -> timespec -> spec_base -> date -> day_of_week
                          do () ->
                            # Figure out next Monday.
                            target = new Date()
                            target.setDate target.getDate() + (1 - target.getDay())
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'Monday' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> TODAY
                          do () ->
                            target = new Date()
                            target.setHours(0)
                            target.setMinutes(0)
                            target.setSeconds(0)
                            target.setMilliseconds(0)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'today' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> TOMORROW
                          do () ->
                            target = new Date()
                            target.setDate(target.getDate() + 1)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'Tomorrow' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> YESTERDAY
                          do () ->
                            target = new Date()
                            target.setDate(target.getDate() - 1)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'Yesterday' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> concatenated_date
                          do () ->
                            targets_pre =
                              '20401': new Date(2040, 0, 0)
                              '204001': new Date(2040, 0, 0)
                              '2040012': new Date(2040, 0, 2)
                              '20400102': new Date(2040, 0, 2)
                            targets = {}
                            for date_string, target of targets
                              target = rebase target, timezone, time_base
                              mutate(target, period_direction_multiplier * period_count)
                              targets[w(garburate garbage, time_base_string + date_string + period_string)] = target

                            for date_string, target of targets
                              do (date_string, target) ->
                                result = parse garbage, date_string
                                describe "'#{date_string}'", ->
                                  target_string = if timezone then target.toUTCString() else target.toString()
                                  it "should#{garbage} return '#{target_string}'", ->
                                    equalish target, result, period, timezone, time_base

                          # start -> timespec -> spec_base -> date -> NEXT inc_dec_period
                          do () ->
                            target = new Date()
                            target.setMonth(target.getMonth() + 1)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'next month' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> NEXT count inc_dec_period
                          do () ->
                            for count in counts
                              do (count) ->
                                target = new Date()
                                target.setMonth(target.getMonth() + count)
                                target = rebase target, timezone, time_base
                                mutate(target, period_direction_multiplier * period_count)

                                date_string = w(garburate garbage, time_base_string + "next #{count} months" + period_string)
                                result = parse garbage, date_string
                                describe "'#{date_string}'", ->
                                  target_string = if timezone then target.toUTCString() else target.toString()
                                  it "should#{garbage} return '#{target_string}'", ->
                                    equalish target, result, period, timezone, time_base, true

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
                              target = rebase target, timezone, time_base
                              mutate(target, period_direction_multiplier * period_count)

                              date_string = w(garburate garbage, time_base_string + "NEXT #{name}" + period_string)
                              result = parse garbage, date_string
                              describe "'#{date_string}'", ->
                                target_string = if timezone then target.toUTCString() else target.toString()
                                it "should#{garbage} return '#{target_string}'", ->
                                  equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> LAST inc_dec_period
                          do () ->
                            target = new Date()
                            target.setMonth(target.getMonth() - 1)
                            target = rebase target, timezone, time_base
                            mutate(target, period_direction_multiplier * period_count)

                            date_string = w(garburate garbage, time_base_string + 'LAST month' + period_string)
                            result = parse garbage, date_string
                            describe "'#{date_string}'", ->
                              target_string = if timezone then target.toUTCString() else target.toString()
                              it "should#{garbage} return '#{target_string}'", ->
                                equalish target, result, period, timezone, time_base, true

                          # start -> timespec -> spec_base -> date -> LAST count inc_dec_period
                          do () ->
                            for count in counts
                              do (count) ->
                                target = new Date()
                                target.setMonth(target.getMonth() - count)
                                target = rebase target, timezone, time_base
                                mutate(target, period_direction_multiplier * period_count)

                                date_string = w(garburate garbage, time_base_string + "LAST #{count} months" + period_string)
                                result = parse garbage, date_string
                                describe "'#{date_string}'", ->
                                  target_string = if timezone then target.toUTCString() else target.toString()
                                  it "should#{garbage} return '#{target_string}'", ->
                                    equalish target, result, period, timezone, time_base, true

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
                              target = rebase target, timezone, time_base
                              mutate(target, period_direction_multiplier * period_count)

                              date_string = w(garburate garbage, time_base_string + "last #{name}" + period_string)
                              result = parse garbage, date_string
                              describe "'#{date_string}'", ->
                                target_string = if timezone then target.toUTCString() else target.toString()
                                it "should#{garbage} return '#{target_string}'", ->
                                  equalish target, result, period, timezone, time_base, true
