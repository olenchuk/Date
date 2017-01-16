use Date::Range;
use Data::Dumper;
use Date::Calc qw(Add_Delta_YMD);

my $test_date = '2015-10-31';

my $dr = Date::Range->new(
                            type => 'YEAR',
                            intervals =>  0,
                            span => 1,
                            sliding_window => 0,
                            today_date => $test_date,
                            direction => '+',
                            start_day_of_month => 1,
                            start_month_of_year => 9,
                         );
## #my ($start, $end, $last) = $dr->get_dates(intervals => 0);
## #print "$start / $end / $last\n";
## 
## $dr->set_intervals(300);
## my ($start, $end, $last) = $dr->get_dates();
## print Dumper $dr->get_error();
## print "$start / $end / $last\n";
## 
## #my ($start, $end, $last) = $dr->get_dates(intervals => 7);
## #print "$start / $end / $last\n";
## 
## 
## #my @out = Add_Delta_YMD(Add_Delta_YMD(2016,2,1,0,1,0),(0,0,-1));
## my @out = Add_Delta_YMD(2016,2,1,0,1,-1);
## print Dumper \@out;

print "\n\nREF        : $test_date\n";
print "Intervals      : " . $dr->get_intervals . "\n";
print "Span           : " . $dr->get_span . "\n";
print "Sliding Window : " . $dr->get_sliding_window . "\n";
print "Direction      : " . $dr->direction . "\n";
print "Start DOM      : " . $dr->get_start_day_of_month . "\n";
print "Start MOY      : " . $dr->get_start_month_of_year . "\n";
#$dr->set_intervals(1);
#$dr->set_type('MONTH');
#$dr->set_start_day_of_month('l');
#print "Start 1\n";
#print Dumper $dr->get_dates();
#print "Cut 9\n";
#$dr->set_start_day_of_month(9);
#print Dumper $dr->get_dates;
#print "Cut 23\n";
$dr->set_start_day_of_month('L');
#print Dumper $dr->get_dates;
#print "End\n";
#print $dr->get_start_day_of_month . "\n";

#$dr->set_intervals(0);
printf "%-10s     %-10s     %-10s\n", qw(Start End Last);
printf "%s     %s     %s\n", $dr->get_dates();
#print Dumper $dr;
