# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
sub mkTST(@)
{
	my ($line, $opt) = @_;

	unlink "/tmp/_TST_.log";
	open FH, '> _TST_';
	print FH $line . "\n";
	close \*FH;

	$opt = '' if( !defined $opt);
	my $rc = system( "perl _TST_  $opt >>/tmp/_tst_.log 2>&1" );

	open( FH , "/tmp/_tst_.log" );
	@x = <FH>;

system("cp /tmp/_tst_.log /tmp/_tst_.log.$$");
	unlink "/tmp/_tst_.log";
	unlink "_TST_";
	return $rc/256, \@x;
}
#########################


use Test::More;
BEGIN { plan tests => 10 };
use Script::Toolbox qw(:all);

#########################

($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); Exit( 2, "test" );) );
is( $rc, 2, 'Exit' );
like( $x[0], qr/\d{4}:\s+test/, 'Exit' );

#my $nroff  = !(system("type nroff   >/dev/null 2>&1") / 256);
#my $perldoc= !(system("type perldoc >/dev/null 2>&1") / 256);
my $nroff  = !(system("nroff </dev/null  >/dev/null 2>&1") / 256);
my $perldoc= !(system("perldoc perlfunc </dev/null >/dev/null 2>&1") / 256);
SKIP: {
	skip "nroff or perldoc is not installed.", 4 if ( !($nroff && $perldoc) );

	($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); ), '-help');
	is( $rc, 1, 'help' );
	print ">$x[0]<\n";
	like( $x[0], qr/No documentation found for/, 'Help' );

	my $line = sprintf "%s\__END__\n=head Name\ntest\n\n=cut\n", q(use Script::Toolbox qw(:all); Script::Toolbox->new(););
	($rc,$x) = mkTST( $line, '-help');
	is( $rc, 1, 'help' );
	like( $x[0], qr/User Contributed Perl Documentation/, 'Help' );
}

SKIP: {
	skip "perldoc is installed.", 4 if ( $perldoc );

	($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); ), '-help');
	is( $rc, 2, 'help' );
	like( $x[0], qr/Missing nroff/, 'Help' );

	$line = sprintf "%s\__END__\n=head Name\ntest\n\n=cut\n", q(use Script::Toolbox qw(:all); Script::Toolbox->new(););
	($rc,$x) = mkTST( $line, '-help');
	is( $rc, 2, 'help' );
	like( $x[0], qr/Missing nroff/, 'Help' );
}

system( "rm -f /tmp/_tst_.log.*" );
