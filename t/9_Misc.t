# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Test::More tests => 11;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################

$F = Script::Toolbox->new();
##############################################################################
############################### TEST 2 #####################################

$n = $F->Now();
$nn= $F->Now('%Y%m%d%H%M');
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
ok( $n->{sec}   == $sec );      #2
ok( $n->{min}   == $min );      #3
ok( $n->{hour}  == $hour);      #4
ok( $n->{mday}  == $mday);      #5
ok( $n->{mon}   == $mon+1);     #6
ok( $n->{year}  == $year+1900); #7
ok( $n->{wday}  == $wday);      #8
ok( $n->{yday}  == $yday);      #9
ok( $n->{isdst} == $isdst);     #10

$str = sprintf "%.4d%.2d%.2d%.2d%.2d", $year+1900,$mon+1,$mday,$hour,$min;
ok( $nn eq $str); #11

