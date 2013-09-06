/* Copyright 2013 Caleb Case
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

start
  = timespec

timespec
  = base:spec_base tail:(_ inc_or_dec)? {
    if (typeof(tail) === 'object') {
      var count = tail[1]['count'];
      var amount = tail[1]['amount'];

      base.setFullYear(base.getFullYear() + (amount.y * count));
      base.setMonth(base.getMonth() + (amount.m * count));
      base.setDate(base.getDate() + (amount.d * count));
      base.setHours(base.getHours() + (amount.h * count));
      base.setMinutes(base.getMinutes() + (amount.i * count));
    }

    return base;
  }

spec_base
  = date
  / t:time tail:(_ date)? {
    if (typeof(tail) === 'object') {
      var d = tail[1];
      t.setFullYear(d.getFullYear());
      t.setMonth(d.getMonth());
      t.setDate(d.getDate());
    }

    return t;
  }
  / 'NOW'i {
    return new Date();
  }

time
  = t:time_base tail:(_ timezone_name)? {
    return t;
  }

time_base
  = hr24clock_hr_min
  / t:time_hour _ offset:am_pm {
    t.setHours(t.getHours() + offset);

    return t;
  }

  / t:time_hour_min tail:(_ am_pm)? {
    if (typeof(tail) === 'object') {
      t.setHours(t.getHours() + tail[1]);
    }

    return t;
  }
  / 'NOON'i {
    var today = new Date();

    today.setHours(12);
    today.setMinutes(0);
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }
  / 'MIDNIGHT'i {
    var today = new Date();

    today.setHours(0);
    today.setMinutes(0);
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }
  / 'TEATIME'i {
    var today = new Date();

    today.setHours(16);
    today.setMinutes(0);
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }

hr24clock_hr_min
  = hour:([0-9][0-9]) minute:([0-9][0-9]) {
    var today = new Date();

    today.setHours(hour);
    today.setMinutes(minute);
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }

time_hour
  = hour:int1_2digit {
    var today = new Date();

    today.setHours(hour);
    today.setMinutes(0);
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }

time_hour_min
  = hour:([012]?[0-9]) [:'h,.] minute:([0-9][0-9]) {
    var today = new Date();

    today.setHours(hour.join(''));
    today.setMinutes(minute.join(''));
    today.setSeconds(0);
    today.setMilliseconds(0);

    return today;
  }

am_pm
  = 'AM'i { return 0; }
  / 'PM'i { return 12; }

timezone_name
  = 'UTC'i

date
  = month:month_name _ day:day_number tail:((_? ',')? _ year_number)? {
    var now = new Date();

    if (typeof(tail) === 'object') {
      now.setFullYear(tail[2]);
    }

    now.setMonth(month);
    now.setDate(day);

    return now;
  }
  / day:day_of_week {
    var now = new Date();

    now.setDate(now.getDate() + (day - now.getDay()));

    return now;
  }
  / 'TODAY'i {
    var now = new Date();

    now.setHours(0);
    now.setMinutes(0);
    now.setSeconds(0);
    now.setMilliseconds(0);

    return now;
  }
  / 'TOMORROW'i {
    var now = new Date();

    now.setDate(now.getDate() + 1);

    return now;
  }
  / 'YESTERDAY'i {
    var now = new Date();

    now.setDate(now.getDate() - 1);

    return now;
  }
  / year:year_number [-] month:int1_2digit [-] date:int1_2digit {
    var now = new Date();

    now.setFullYear(year);
    now.setMonth(month - 1);
    now.setDate(date);

    return now;
  }
  / date:day_number [.] month:month_number [.] year:year_number {
    var now = new Date();

    now.setFullYear(year);
    now.setMonth(month - 1);
    now.setDate(date);

    return now;
  }
  / date:day_number _ month:month_name tail:(_ year_number)? {
    var now = new Date();

    if (typeof(tail) === 'object') {
      now.setFullYear(tail[1]);
    }

    now.setMonth(month);
    now.setDate(date);

    return now;
  }
  / month:month_number '/' date:day_number '/' year:year_number {
    var now = new Date();

    now.setFullYear(year);
    now.setMonth(month - 1);
    now.setDate(date);

    return now;
  }
  / concatenated_date
  / 'NEXT'i c:(_ inc_dec_number)? _ amount:inc_dec_period {
    var now = new Date();
    var count = 1;

    if (typeof(c) === 'object') {
      count = c[1];
    }

    now.setFullYear(now.getFullYear() + (amount.y * count));
    now.setMonth(now.getMonth() + (amount.m * count));
    now.setDate(now.getDate() + (amount.d * count));
    now.setHours(now.getHours() + (amount.h * count));
    now.setMinutes(now.getMinutes() + (amount.i * count));

    return now;
  }
  / 'NEXT'i _ day:day_of_week {
    var now = new Date();

    now.setDate(now.getDate() + (day - now.getDay()) + 7);

    return now;
  }
  / 'LAST'i c:(_ count:inc_dec_number)? _ amount:inc_dec_period {
    var now = new Date();
    var count = 1;

    if (typeof(c) === 'object') {
      count = c[1];
    }

    now.setFullYear(now.getFullYear() + (amount.y * -count));
    now.setMonth(now.getMonth() + (amount.m * -count));
    now.setDate(now.getDate() + (amount.d * -count));
    now.setHours(now.getHours() + (amount.h * -count));
    now.setMinutes(now.getMinutes() + (amount.i * -count));

    return now;
  }
  / 'LAST'i _ day:day_of_week {
    var now = new Date();

    if (now.getDay() === day) {
      now.setDate(now.getDate() - 7);
    }

    now.setDate(now.getDate() + (day - now.getDay()));

    return now;
  }

concatenated_date
  = digits:str5_8digit {
    var year = 0;
    var month = 0;
    var day = 0;

    if (digits.length === 5 || digits.length === 6) { /* YearMonth */
      year = parseInt(digits.slice(0, 4), 10);
      month = parseInt(digits.slice(4), 10) - 1;
    }
    else if (digits.length === 7 || digits.length === 8) { /* YearMonthDay */
      year = parseInt(digits.slice(0, 4), 10);
      month = parseInt(digits.slice(4, 6), 10) - 1;
      day = parseInt(digits.slice(6), 10);
    }

    return new Date(year, month, day);
  }

month_name
  = 'JAN'i ('UARY'i)? { return 0; }
  / 'FEB'i ('RUARY'i)? { return 1; }
  / 'MAR'i ('CH'i)? { return 2; }
  / 'APR'i ('IL'i)? { return 3; }
  / 'MAY'i { return 4; }
  / 'JUN'i ('E'i)? { return 5; }
  / 'JUL'i ('Y'i)? { return 6; }
  / 'AUG'i ('UST'i)? { return 7; }
  / 'SEP'i ('TEMBER'i)? { return 8; }
  / 'OCT'i ('OBER'i)? { return 9; }
  / 'NOV'i ('EMBER'i)? { return 10; }
  / 'DEC'i ('EMBER'i)? { return 11; }

month_number
  = int1_2digit

day_number
  = int1_2digit

year_number
  = year:int2_or_4digit {
    if (year < 100) {
      return year + 2000;
    }

    return year;
  }

day_of_week
  = 'SUN'i ('DAY'i)? { return 0; }
  / 'MON'i ('DAY'i)? { return 1; }
  / 'TUE'i ('SDAY'i)? { return 2; }
  / 'WED'i ('NESDAY'i)? { return 3; }
  / 'THU'i ('RSDAY'i)? { return 4; }
  / 'FRI'i ('DAY'i)? { return 5; }
  / 'SAT'i ('URDAY'i)? { return 6; }

inc_or_dec
  = increment
  / decrement

increment
  = '+' _ count:inc_dec_number _ amount:inc_dec_period {
    return { 'count': count, 'amount': amount };
  }

decrement
  = '-' _ count:inc_dec_number _ amount:inc_dec_period {
    return { 'count': count * -1, 'amount': amount };
  }

inc_dec_number
  = integer

inc_dec_period
  = 'MINUTE'i ('S'i)? { return {'y': 0, 'm': 0, 'd': 0, 'h': 0, 'i': 1}; }
  / 'HOUR'i ('S'i)? { return {'y': 0, 'm': 0, 'd': 0, 'h': 1, 'i': 0}; }
  / 'DAY'i ('S'i)? { return {'y': 0, 'm': 0, 'd': 1, 'h': 0, 'i': 0}; }
  / 'WEEK'i ('S'i)? { return {'y': 0, 'm': 0, 'd': 7, 'h': 0, 'i': 0}; }
  / 'MONTH'i ('S'i)? { return {'y': 0, 'm': 1, 'd': 0, 'h': 0, 'i': 0}; }
  / 'YEAR'i ('S'i)? { return {'y': 1, 'm': 0, 'd': 0, 'h': 0, 'i': 0}; }

int1_2digit
  = digits:([0-9][0-9]?) {
    return parseInt(digits.join(''), 10);
  }

int2_or_4digit
  = digits:([0-9][0-9]([0-9][0-9])?) {
    var value = digits.slice(0, 2).join('');

    if (typeof(digits[2]) === 'object') {
      value += digits[2].join('');
    }

    return parseInt(value, 10);
  }

str5_8digit
  = digits:([0-9][0-9][0-9][0-9][0-9]([0-9][0-9][0-9] / [0-9][0-9] / [0-9])?) {
    var value = digits.slice(0, 5).join('');

    if (typeof(digits[5]) === 'object') {
      value += digits[5].join('');
    }
    else {
      value += digits[5];
    }

    return value;
  }

integer
  = digits:[0-9]+ {
    return parseInt(digits.join(''), 10);
  }

_
  = [\t\n\r ]+
