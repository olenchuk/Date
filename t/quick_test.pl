use Date::Range;
use Data::Dumper;
use Date::Calc qw(Add_Delta_YMD);

my $dr = Date::Range->new(type => 'YEAR', span => 5, sliding_window => 1, today_date => '2015-10-10');
#my ($start, $end, $last) = $dr->get_dates(intervals => 0);
#print "$start / $end / $last\n";

$dr->set_intervals(300);
my ($start, $end, $last) = $dr->get_dates();
print Dumper $dr->get_error();
print "$start / $end / $last\n";

#my ($start, $end, $last) = $dr->get_dates(intervals => 7);
#print "$start / $end / $last\n";


#my @out = Add_Delta_YMD(Add_Delta_YMD(2016,2,1,0,1,0),(0,0,-1));
my @out = Add_Delta_YMD(2016,2,1,0,1,-1);
print Dumper \@out;

$dr->set_intervals(1);
$dr->set_type('MONTH');
$dr->set_start_dom('l');
print Dumper $dr->get_dates();
