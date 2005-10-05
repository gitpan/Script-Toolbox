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

	unlink "/tmp/_tst_.log";
	unlink "_TST_";
	return $rc/256, \@x;
}
#########################


use Test::More;
BEGIN { plan tests => 6 };
use Script::Toolbox qw(:all);

#########################

($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); Exit( 2, "test" );) );
is( $rc, 2, 'Exit' );
like( $x[0], qr/\d{4}:\s+test/, 'Exit' );

($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); ), '-help');
is( $rc, 1, '-help' );
like( $x[0], qr/No documentation found for/, 'Help' );

my $line = sprintf "%s\__END__\n=head Name\ntest\n\n=cut\n", q(use Script::Toolbox qw(:all); Script::Toolbox->new(););
#($rc,$x) = mkTST( q(use Script::Toolbox qw(:all); Script::Toolbox->new(); =head Name ), '-help');
($rc,$x) = mkTST( $line, '-help');
is( $rc, 1, '-help' );
like( $x[0], qr/User Contributed Perl Documentation/, 'Help' );
