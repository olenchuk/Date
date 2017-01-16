package Date::Range;
use base qw(Class::Accessor);
use strict;
use Date::Calc qw(
                  Today
                  Add_Delta_YMD
                  check_date
                  Day_of_Week
                  Monday_of_Week
                  Week_of_Year
                  );

__PACKAGE__->mk_accessors(qw(
                              type intervals direction span sliding_window
                              start_dow start_dow_name start_dom start_moy
                              today_date error print_format
                            ));

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    $self->_set_default_parameters();
    $self->_set_passed_parameters(\%args);
    return $self;
}

sub get_dates {
    my $self = shift;
    $self->clear_error;
    my %args = @_;
    if (scalar keys %args) {
        $self->_set_passed_parameters(\%args);
    }
    if (!$self->type) {
        $self->set_error("Cannot get dates - no range type specified");
        return ();
    }
    my @start = $self->_get_start_date;
    unless (scalar @start) {
        return ();
    }
    my @end = $self->_get_end_date(@start);
    unless (scalar @end) {
        return ();
    }
    my @last = $self->_get_last_date(@end);
    unless (scalar @last) {
        return ();
    }

    my $start_date = $self->_array_to_date(@start);
    my $end_date = $self->_array_to_date(@end);
    my $last_date = $self->_array_to_date(@last);
    return ($start_date,$end_date,$last_date);
}

sub set_type {
    my ($self, $type) = @_;
    return 0 unless defined $type;
    $type = uc($type);
    my %valid_types = ('DAY' => 1 , 'WEEK' => 1 , 'MONTH' => 1 , 'QUARTER' => 1 , 'YEAR' => 1);
    unless ($valid_types{$type}) {
        $self->set_error("Invalid type $type");
        $self->type('');
        return 0;
    }
    $self->type($type);
    return 1;
}

sub get_type {
    my $self = shift;
    return $self->type;
}

sub set_intervals {
    my ($self, $intervals) = @_;
    return 0 unless defined $intervals;
    if ($intervals =~ /^(?:-)?\d+$/) {
        $self->intervals($intervals);
        return 1;
    }
    else {
        $self->set_error("Invalid intervals, \"$intervals\"");
        return 0;
    }
}

sub get_intervals {
    my $self = shift;
    return $self->intervals;
}

sub set_span {
    my ($self, $span) = @_;
    return 0 unless defined $span;
    if ($span =~ /^\d+$/ and $span > 0) {
        $self->span($span);
        return 1;
    }
    else {
        $self->set_error("Invalid span, \"$span\"");
        return 0;
    }
}

sub get_span {
    my $self = shift;
    return $self->span;
}

sub set_start_day_of_week {
    my ($self, $start_dow) = @_;
    return 0 unless defined $start_dow;
    $start_dow = uc($start_dow);
    my %valid_dow = (
                       'MONDAY'    => 1,
                       'TUESDAY'   => 2,
                       'WEDNESDAY' => 3,
                       'THURSDAY'  => 4,
                       'FRIDAY'    => 5,
                       'SATURDAY'  => 6,
                       'SUNDAY'    => 7,
                    );
    if (exists $valid_dow{$start_dow}) {
        $self->start_dow($valid_dow{$start_dow});
        $self->_set_start_dow_name($start_dow);
        return 1;
    }
    else {
        $self->set_error("Invalid start day of week, \"$start_dow\"");
        return 0;
    }
}

sub get_start_day_of_week {
    my $self = shift;
    return $self->start_dow;
}

sub set_start_day_of_month {
    my ($self, $start_dom) = @_;
    return 0 unless defined $start_dom;
    if ($start_dom =~ /^\d+$/ and $start_dom >= 1 and $start_dom <= 28) {
        $self->start_dom($start_dom);
    } else {
        $self->set_error("Invalid start day of month, \"$start_dom\"");
        return 0;
    }
    return 1;
}

sub get_start_day_of_month {
    my $self = shift;
    return $self->start_dom;
}

sub set_start_month_of_year {
    my ($self, $start_moy) = @_;
    return 0 unless defined $start_moy;
    if ($start_moy =~ /^\d+$/ and $start_moy >= 1 and $start_moy <= 12) {
        $self->start_moy($start_moy);
    } else {
        $self->set_error("Invalid start month of year, \"$start_moy\"");
        return 0;
    }
    return 1;
}

sub get_start_month_of_year {
    my $self = shift;
    return $self->start_moy;
}

sub set_today_date {
    my ($self, @today) = @_;
    return 0 unless @today;
    if (scalar @today) {
        my @verified_date = $self->_date_to_array(@today);
        if (@verified_date) {
            $self->today_date(@verified_date);
            return 1;
        }
        my $temp = join(":",@today);
        $self->set_error("Today override failed validation, \"$temp\"");
        return 0;
    }
    else {
        $self->today_date(Today);
        return 1;
    }
}

sub get_today_date {
    my $self = shift;
    return @{$self->today_date};
}

sub set_sliding_window {
    my ($self, $sliding_window) = @_;
    return 0 unless defined $sliding_window;
    if ($sliding_window == 0 or $sliding_window == 1) {
        $self->sliding_window($sliding_window);
        return 1;
    }
    else {
        $self->set_error("Invalid sliding window, \"$sliding_window\"");
        return 0;
    }
}

sub get_sliding_window {
    my $self = shift;
    return $self->sliding_window;
}

sub set_direction {
    my ($self,$direction) = @_;
    return 0 unless defined $direction;
    if ($direction =~ /^[\+-]$/) {
        $self->direction($direction);
        return 1;
    }
    $self->set_error("Invalid direction argument, \"$direction\"");
    return 0;
}

sub get_direction {
    my $self = shift;
    return $self->direction;
}

sub set_error {
    my ($self, $msg) = @_;
    my @existing = @{$self->error};
    push @existing, $msg;
    $self->error(\@existing);
}

sub get_error {
    my $self = shift;
    return $self->error;
}

sub clear_error {
    my $self = shift;
    $self->error([]);
}

################################################################################
sub _set_default_parameters {
    my $self = shift;
    $self->set_intervals(1);
    $self->set_span(1);
    $self->set_start_day_of_week('MONDAY');
    $self->set_start_day_of_month(1);
    $self->set_start_month_of_year(1);
    $self->_set_print_format('%04d-%02d-%02d');
    $self->set_today_date();
    $self->set_sliding_window(0);
    $self->set_direction('-');
    $self->clear_error();
}

sub _set_passed_parameters {
    my $self = shift;
    my $hash = shift;
    $self->set_type($hash->{type})             if exists $hash->{type};
    $self->set_intervals($hash->{intervals})   if exists $hash->{intervals};
    $self->set_span($hash->{span})             if exists $hash->{span};
    $self->set_today_date($hash->{today_date}) if exists $hash->{today_date};
    $self->set_direction($hash->{direction})   if exists $hash->{direction};
    $self->set_start_day_of_week($hash->{start_day_of_week})
        if exists $hash->{start_day_of_week};
    $self->set_sliding_window($hash->{sliding_window})
        if exists $hash->{sliding_window};
    $self->set_start_day_of_month($hash->{start_day_of_month})
       if exists $hash->{start_day_of_month};
    $self->set_start_month_of_year($hash->{start_month_of_year})
         if exists $hash->{start_month_of_year};
}

sub _get_start_date {
    my $self = shift;
    my $direction = $self->get_direction;
    my @start = $self->_start_reference;
    my $span = $self->get_span;
    my $intervals = $self->get_intervals;
    my @delta = $self->_delta_per_period;
    if ($direction eq '-') {
        @delta = _negate(@delta);
    }
    my $map_factor;
    if ($self->get_sliding_window) {
        $map_factor = ($direction eq '+') ? $intervals
                    :                      ($span + $intervals - 1)
                    ;
    } else {
        $map_factor = $span * $intervals;
    }
    @delta = map { $_ * $map_factor } @delta;
    @start = $self->_add_delta_ymd(@start, @delta);
    return @start;
}

sub _get_end_date {
    my $self = shift;
    my @start = @_;
    my @delta = $self->_delta_ymd;
    my @end = $self->_add_delta_ymd(@start,@delta);
    return @end;
}

sub _get_last_date {
    my $self = shift;
    my @end = @_;
    @end = $self->_add_delta_ymd(@end,(0,0,-1));
    return @end;
}

sub _start_reference {
    my $self = shift;
    my @start = $self->get_today_date;
    my $type = $self->get_type;
    if ($type eq 'YEAR') {
        my $start_moy = $self->get_start_month_of_year;
        if ($start_moy > $start[1]) {
            @start = $self->_add_delta_ymd(@start,(-1,0,0));
        }
        $start[1] = $start_moy;
        $start[2] = 1;
    } elsif ($type eq 'QUARTER') {
        $start[1] -= ( ( $start[1] - 1 ) % 3 );
        $start[2] = 1;
    } elsif ($type eq 'MONTH') {
        my $start_dom = $self->get_start_day_of_month;
        if ($start_dom > $start[2]) {
            @start = $self->_add_delta_ymd(@start,(0,-1,0));
        }
        $start[2] = $start_dom;
    } elsif ($type eq 'WEEK') {
        ## Calculate the "Monday" of the current week, and add the number of days to get to
        ## desired start date.  If that start day-of-week is "after" the "current" day-of-week,
        ## that start date will be in the future.  Will need to subtract a week.
        my $start_dow = $self->get_start_day_of_week;
        my $today_dow = Day_of_Week(@start);
        @start = $self->_add_delta_ymd(Monday_of_Week(Week_of_Year(@start)),(0,0,$start_dow - 1));
        ## NEED MORE HERE _ this is just "monday" at this point
        if ($today_dow < $start_dow) {
            @start = $self->_add_delta_ymd(@start,(0,0,-7));
        }
    } elsif ($type eq 'DAY') {
        ## No change
    }
    return @start;
}

sub _set_start_dow_name {
    my ($self,$start_dow_name) = @_;
    $self->start_dow_name($start_dow_name);
}

sub _get_start_dow_name {
    my $self = shift;
    return $self->start_dow_name;
}

sub _set_print_format {
    my ($self, $format) = @_;
    ## valid: %s, %d, '/', '-', ' ', ':'
    my $validate = $format;
    $validate =~ s/[\/\- :]//g;
    $validate =~ s/%[0-9]*d//g;
    if ($validate) {
        $self->set_error("Suspect output format: \"$format\"");
        return 0;
    }
    $self->print_format($format);
    return 1;
}

sub _get_print_format {
    my $self = shift;
    return $self->print_format;
}

sub _delta_ymd {
    my $self = shift;
    my $span = $self->get_span;
    my @single_delta = $self->_delta_per_period;
   my @total_delta = map { $span * $_ } @single_delta;
   return @total_delta;
}

sub _delta_per_period {
    my $self = shift;
    my $type = $self->get_type;
    return $type eq 'YEAR'    ? (1,0,0)
         : $type eq 'QUARTER' ? (0,3,0)
         : $type eq 'MONTH'   ? (0,1,0)
         : $type eq 'WEEK'    ? (0,0,7)
         :                      (0,0,1)
}

sub _negate {
    my @negatives = map { -1 * $_ } @_;
    return @negatives;
}

sub _date_to_array {
    my ($self,@date) = @_;
    if (scalar(@date) == 1 and $date[0] =~ /^(\d+)-(\d+)-(\d+)$/) {
        @date = ($1,$2,$3);
    }
    if ((scalar(@date) == 3) and
        ($date[0] =~ /^\d+$/) and
        ($date[1] =~ /^\d+$/) and
        ($date[2] =~ /^\d+$/) and
        (check_date(@date))) {
        return (@date);
    }
    else {
        $self->set_error("Invalid \"today\": " . join("-",@date));
    }
    return ();
}

sub _array_to_date {
    my ($self, @date) = @_;
    my $format = $self->_get_print_format();
    return sprintf $format, @date;
}

sub _add_delta_ymd {
    my ($self,@date_info) = @_;
    my @new_date = ();
    eval {
        @new_date = Add_Delta_YMD(@date_info);
    };
    if ($@) {
        my $errstring = sprintf "Cannot calculate date diff: (%d,%d,%d) + (%d,%d,%d)", @date_info;
        $self->set_error($errstring);
    }
    return @new_date;
}

1;

=head1 NAME

Date::Range - Generate start/end dates easily, based on type (year, month,...),
number of consecutive entities ("4 months"), number of intervals from the current date,
and direction (past/future).

=head1 VERSION

1.0

=head1 SYNOPSIS

    use Date::Range;
    
    my $dr = Date::Range->new(%params);
    
    my ($start_date,$end_date,$last_date) = $dr->get_dates();
    
    my ($start_date,$end_date,$last_date) = $dr->get_dates(%params);
    
    $dr->set_type([ YEAR | QUARTER | MONTH | WEEK | DAY ]);
    
    $dr->set_intervals(n);
    
    $dr->set_span(n);
    
    $dr->set_sliding_window([ 0 | 1 ]);
    
    $dr->set_direction([ '+' | '-' ]);
    
    $dr->set_start_day_of_week([ MONDAY | TUESDAY | ...]);
    
    $dr->set_start_day_of_month([ 1, 2, 3, ... 28 ]);
    
    $dr->set_start_month_of_year([ 1, 2, 3, ... 12 ]);
    
    $dr->set_today_date('YYYY-MM-DD');
    
    $dr->get_error();

=head1 DESCRIPTION

Date::Range calculates a start/end date based on a interval type, and a number of intervals from the current date.
This is often required in running scheduled and ad-hoc reports using the same script, where the desired date range
has the requirement of, "7 months ago", or, "5 weeks ago, running Tuesday to Monday".

Three dates are returned for the given interval:

=over 4

=item

First date of the interval

=item

First date of the next interval

=item

Last date of the interval

=back

Two "end" dates are returned for convenience, as a report using a date+time field may require a query from
"2015-10-01 through 2015-11-01", but the title of the report may be, "Output for 2015-10-01 through 2015-10-31".

Date ranges are calculated based on the following parameters:

=over 4

=item 

type - the basic time interval for the report [ YEAR | QUARTER | MONTH | WEEK | DAY ] - no default, must be specified

Note: QUARTER calculates the ranges for (Jan-Mar / Apr-Jun / Jul-Sep / Oct-Dec)

=item

intervals - how many "units in the past" (eq, "4 months ago") - default = 1

=item

span - number of consecutive units (eq, "5 month window") - default = 1

=item

sliding_window - Applicable if span > 1.  If sliding_window is set, each interval back will slide by one
unit of type.  If sliding window is not set, each interval back will slide by (span) units of type. - default = 0

=item

direction - If set to "-", each positive value for "intervals" goes further into the past, and each negative value for "intervals"
goes further into the future.  If set to "+", the opposite applies.

=item

start_day_of_week - For type = WEEK, the day which should be used as the first day of the week (SUNDAY, MONDAY, ...) - default = MONDAY

=item

start_day_of_month - For type = MONTH, the day which should be used as the start date of the month.  Valid values are 1..28.
Date::Calc is used for these calculations.  If adding/subtracting months, and the day component of the start month is greater
than the number of days in the resulting month (ex, "Feb 30"), Date::Calc extends the calculation into the following month ("Mar 2").
To prevent confusion, Date::Range only supports start_dom of 1 to 28.

=item

start_month_of_year - For type = YEAR, the month which should be used as the first day of the year.  Valid values are 1..12.
This would be applicable for fiscal years, which do not always start with I<January>.

=item

today_date - Overrides the current date, typically for development/test purposes.

=back

The current window (intervals = 0) contains the current date.

=head2 Illustrations

The following tables illustrate the effect of various values of direction, sliding window, and interval, assuming
span = 2.  Notice in each case, "interval=1" is one unit away from the one containing the current date (C).

=begin html

<pre>

Direction = "-", sliding window = 0
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |   |   |   |xxx|xxx
 0)    |   |   |xxx|xxx|   |   
 1)    |xxx|xxx|   |   |   |   
<br>
Direction = "-", sliding window = 1
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |   |xxx|xxx|   |   
 0)    |   |xxx|xxx|   |   |   
 1)    |xxx|xxx|   |   |   |   
<br>
Direction = "+", sliding window = 0
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1) xxx|xxx|   |   |   |   |   
 0)    |   |xxx|xxx|   |   |   
 1)    |   |   |   |xxx|xxx|   
<br>
Direction = "+", sliding window = 1
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |xxx|xxx|   |   |   
 0)    |   |   |xxx|xxx|   |   
 1)    |   |   |   |xxx|xxx|   

</pre>

=end html

=begin text

Direction = "-", sliding window = 0
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |   |   |   |xxx|xxx
 0)    |   |   |xxx|xxx|   |   
 1)    |xxx|xxx|   |   |   |   

Direction = "-", sliding window = 1
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |   |xxx|xxx|   |   
 0)    |   |xxx|xxx|   |   |   
 1)    |xxx|xxx|   |   |   |   

Direction = "+", sliding window = 0
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1) xxx|xxx|   |   |   |   |   
 0)    |   |xxx|xxx|   |   |   
 1)    |   |   |   |xxx|xxx|   

Direction = "+", sliding window = 1
     -3| -2| -1| C | 1 | 2 | 3 
    ---|---|---|---|---|---|---
-1)    |   |xxx|xxx|   |   |   
 0)    |   |   |xxx|xxx|   |   
 1)    |   |   |   |xxx|xxx|   

=end text


=head1 METHODS

=head2 new

Object constructor.  Parameters can be set here, or in get_dates, or by set_I<param> methods.

=over 4

=item Arguments: I<\%parameters>

my ($start, $end, $last) = $dr->new(I<\%parameters>);

=back

=over 4

=item type => [ I<YEAR | QUARTER | MONTH | WEEK | DAY> ]

Interval type.  No default value - must be specified.

=item intervals => I<n>

Number of intervals to move back/forth from the current interval.  Default = 1.

=item span => I<n>

Number of I<type> to include in the range.  Default = 1.

=item start_day_of_week => [ I<MONDAY | TUESDAY | WEDNESDAY | ...> ]

For I<type = WEEK>, the day to denote the first day of the week.  Default = MONDAY.

=item start_day_of_month => [ I<1, 2, 3...28> ]

For I<type = MONTH>, the day to denote the first day of the month.  Default = 1.

=item sliding_window => [ I<O | 1> ]

Applicable when span > 1.  If I<sliding_window=1>, each successive I<intervals>
results in a shift of I<span> (years, months, etc).  If I<sliding_window=0>,
each successive I<intervals> results in a shift of one (year, month, etc).
Default = 0.

=item direction => [ I<"+" | "-"> ]

If I<direction="-">, I<intervals> progresses further into the past.
If I<direction="+">, I<intervals> progresses further into the future.
Default = "-".

=back

=head2 get_dates

Main method.  Returns I<start_date>, I<end_date>, and I<last_date>.

=over 4

=item Arguments: I<\%Parameters>

my ($start, $end, $last) = $dr->get_dates(I<\%parameters>);

Any of the parameters set in I<new> may be set/overridden here.

=back

=head2 Accessors

Each of the parameters may be set/restrieved using set_I<param> / get_I<param> methods.


=head3 set_intervals / get_intervals

Interval type: [ I<YEAR | QUARTER | MONTH | WEEK | DAY> ].  No default - must be specified.

=head3 set_span / get_span

Overrides the ranges running only one year/quarter/month/week/day at a time.  Default = 1.

=head3 set_start_day_of_week / get_start_day_of_week

For weekly ranges, defines the starting day to be used for the week, [ I<MONDAY | TUESDAY | WEDNESDAY | ...> ].
Default = Monday.

=head3 set_start_day_of_month / get_start_day_of_month

For monthly ranges, defines the starting day to be used for the month.  Only supported values are 1-28, as 
months with less than 31 days may yield results unexpected by the end user.  Default = 1.

=head3 set_start_month_of_year / get_start_month_of_year

For yearly ranges, defiens the starting month to be used.  The starting day is fixed at 1.  Default = 1 (January)..

=head3 set_today_date / get_today_date

By default, the current date is used.  This can be overridden, for development/test purposes.
Format must be YYYY-MM-DD.

=head3 set_sliding_window / get_sliding_window

Applicable if span > 1.  Determines whether successive intervals move an entire span, or just a single
amount of type.  For instance, if type = MONTH and span = 5, should each successive value of I<intervals>
advance one month at a time, or five months at a time.  Default = 0 ("five months at a time").

=head3 set_direction / get_direction

The direction which successive intervals progresses. This allows for positive values of I<interval>, whether
looking into the past, or into the future.  To get date ranges which are further into the past, recommend
setting direction to "-".  If date ranges in the future are required, recommend setting direction to "+".
Default = "-".  Refer to the Illustrations section for examples.

=head2 get_error

Retrieve any errors detected by the object.

=head2 clear_error

Reset the error stack

=head1 EXAMPLES

Date is 2015-10-10, type = 'MONTH', direction = '-', span = 1.  Such a setup would be used for running monthly reports.

Intervals = 0 would be the current month:

    my $dr = Date::Range->new(type => 'MONTH');
    my ($start, $end, $last) = $dr->get_dates(intervals => 0);
        (2015-10-01, 2015-11-01, 2015-10-31)

Intervals = 4 would be four months prior to this:

    my $dr = Date::Range->new(type => 'MONTH');
    my ($start, $end, $last) = $dr->get_dates(intervals => 4);
        (2015-06-01, 2015-07-01, 2015-06-30)

If "intervals" is a negative number, ranges would be in the future (improbable, but supported):
        
    my $dr = Date::Range->new(type => 'MONTH');
    my ($start, $end, $last) = $dr->get_dates(intervals => -1);
        (2015-11-01, 2015-12-01, 2015-11-30)


Date is 2015-10-10, type = 'MONTH', direction = '-', span = 5. Sliding window now becomes relevant.

Intervals = 1 should still be the most recent, completed period.  If sliding_window = 0:

    my $dr = Date::Range->new(type => 'MONTH', span => 5);
    my ($start, $end, $last) = $dr->get_dates(intervals => 1);
        (2015-05-01, 2015-10-01, 2015-09-30)

Intervals = 0 will be the next period, starting with the current month:

    my $dr = Date::Range->new(type => 'MONTH', span => 5);
    my ($start, $end, $last) = $dr->get_dates(intervals => 0);
        (2015-10-01, 2016-03-01, 2016-02-29)

Now, if sliding window is enabled, intervals = 1 should still be the most recent, completed period:

    my $dr = Date::Range->new(type => 'MONTH', span => 5, sliding_window => 1);
    my ($start, $end, $last) = $dr->get_dates(intervals => 1);
        (2015-05-01, 2015-10-01, 2015-09-30)

This time, intervals = 0 will end with the current month:

    my $dr = Date::Range->new(type => 'MONTH', span => 5, sliding_window => 1);
    my ($start, $end, $last) = $dr->get_dates(intervals => 0);
        (2015-06-01, 2015-11-01, 2015-10-31)

All parameters can be set at instantiation, set distinctly, or passed in with get_dates.

    my $dr = Date::Range->new(type => 'MONTH', intervals => 1);
    my ($start, $end, $last) = $dr->get_dates();
        (2015-09-01, 2015-10-01, 2015-09-30)

    $dr->set_intervals(2);
    my ($start, $end, $last) = $dr->get_dates();
        (2015-08-01, 2015-09-01, 2015-08-31)

    my ($start, $end, $last) = $dr->get_dates(intervals => 3);
        (2015-07-01, 2015-08-01, 2015-07-31)


=head1 DIAGNOSTICS

Any errors detected may be retrieved via I<$dr-E<gt>get_errors>.  Errors are accumulated as they are encountered.
They are cleared only when I<$dr->clear_errors> is invoked.

=head1 DEPENDENCIES

L<Class::Accessor>

L<Date::Calc>

=head1 AUTHOR

T. Olenchuk

=head1 LICENSE / COPYRIGHT / DISCLAIMER

This is free software, you may use it and distribute it under the same terms as Perl itself.
There is no warranty of any kind, either expressed or implied.

=head1 LIMITATIONS

=over 4

=item

The only allowed format for returned dates is 'YYYY-MM-DD'.  

=item

"Start day-of-month" is only valid only for values 1-28.  This was to avoid trying to use last-day-of-month,
which becomes problematic for days with less than 31 days.  Arguments could be made that, "one month after
the last day of January" is Feb 28, or March 3, or even March 4 on a leap year.

=item

Any date calculations not supported by Date::Calc are not supported here, such as "3000 years ago".

=back

=cut
