package Script::Toolbox::Util;

use 5.006;
use strict;
use Script::Toolbox::Util::Opt;
use Script::Toolbox::Util::Formatter;
use IO::File;
use IO::Dir;
use File::stat;
use Data::Dumper;
use Fatal qw(open close);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Script::Toolbox::Util ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(Open Log Exit Table Usage Dir File ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.12';

# Preloaded methods go here.
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub new
{
    my $classname = shift;
    my $optDef    = shift; # options definition
    my $self = {};
    bless( $self, $classname );

    @Script::Toolbox::Util::caller = caller();
    $self->_init( $optDef, \@Script::Toolbox::Util::caller, @_ );

    return $self;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _init($)
{
    my ($self,$ops,$caller,$args) = @_;

    my $log = $caller->[1];
       $log =~ s|^.*/||;
       $log =~ s/[.].*$//;
       $Script::Toolbox::Util{'_logFH'} = undef;	# use default STDERR 

    # Install signal handler
    $self->_installSigHandlers();

    # install options
    $self->_installOps( $ops )	if( defined $ops );
    Exit( 1, "Invalid option definition, 'opsDef' => {} invalid." )
    if( defined $ops && !defined $self->{'ops'});

    # init log file
    my $logdir = $self->GetOpt('logdir');
    if( defined $logdir )
    {
	system( "mkdir -p $logdir" );
	$Script::Toolbox::Util{'_logFH'} = Open( ">> $logdir/$log.log" );
	$Script::Toolbox::Util{'_logFH'}->autoflush();
    }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _installOps($)
{
    my ($self, $opsDef) = @_;

    $self->{'ops'} = Script::Toolbox::Util::Opt->new( $opsDef, \@Script::Toolbox::Util::caller );
    return if( !defined $self->{'ops'} );

    foreach my $key ( keys %{$self->{'ops'}} )
    {
	if( defined $self->{$key} )
	{
	    print STDERR "Script::Toolbox internal error. ";
	    print STDERR "Can't use command line option $key (internal used)\n";
	    next;
	}
	$self->{$key} = $self->{'ops'}->get($key);
    }
    return;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _installSigHandlers()
{
    my ($self) = @_;
    $SIG{'INT'} = '_sigExit';
    $SIG{'HUP'} = '_sigExit';
    $SIG{'QUIT'}= '_sigExit';
    $SIG{'TERM'}= '_sigExit';
}

#------------------------------------------------------------------------------
# Signal handler.
#------------------------------------------------------------------------------
sub _sigExit($)
{
    my ($sig) = @_;
    Exit( 1, "program aborted by signal SIG$sig." );
}

#------------------------------------------------------------------------------
# Log a message and exit the programm with the given error code.
#------------------------------------------------------------------------------
sub Exit($$)
{
    my ($exitCode, $message) = _getParam(@_);

    Log( $message );
    exit $exitCode;
}

#------------------------------------------------------------------------------
# Write 'die' messages via Log().
#------------------------------------------------------------------------------
sub _dieHook
{
    my @y = split /\n/, $_[0];
    map { Log( $_ ); } @y;
    exit 1 if( $#y > -1 );
};
$main::SIG{'__DIE__'} = \&_dieHook;  # install die hook


#------------------------------------------------------------------------------
# Write a log message with time stamp to a channel.
# $severity, $logtag only required for syslog.
#------------------------------------------------------------------------------
sub Log(@)
{
    my ($message, $canal, $severity, $logtag) = _getParam(@_);

    my $msg = sprintf "%s: %s: %s\n", $0, scalar localtime(), $message;

    my $fh;
    my $can = *STDERR;
    
    if ( !defined $canal )
    {
	if( defined $Script::Toolbox::Util{'_logFH'}) { $can = $Script::Toolbox::Util{'_logFH'}; }
    }else{
	# canel is defined here
	if ( ref($canal) eq 'IO::File' ){ $can = $canal;  }
	elsif ( $canal eq 'STDERR') 	{ $can = *STDERR; }
	elsif ( $canal eq 'STDOUT') 	{ $can = *STDOUT; }
	elsif ( $canal eq 'syslog') 	{ $can = new IO::File "| logger -p '$severity' -t '$logtag'"; }
	else  { $can = _openFromString($canal); }
    }
    print $can $msg;
    return $msg;
}

#------------------------------------------------------------------------------
# We got a string like "/tmp/x", ">> /tmp/x" or "| someProgram".
# Try to open it as a log canal. If it fails open STDERR instead.
#------------------------------------------------------------------------------
sub _openFromString($)
{
    my ($canal) = @_;

    if( $canal !~ /^\s*>/ && $canal !~ /^\s*[|]/ ) { $canal = '>>' . $canal; }

    my $can;
    my $fh = new IO::File "$canal";
    if( !defined $fh ) 
    {
	$can = *STDERR;
	printf $can "%s: %s: %s %s\n",
		$0, scalar localtime(), "WARNING: can't write to", $canal;
    }else{
	$can = $fh;
    }
    return $can;
}

#------------------------------------------------------------------------------
# Open a file via IO::File with Fatal handling
#------------------------------------------------------------------------------
sub Open(@)
{
	my ($file) = _getParam(@_);
	my $fh = new IO::File;
	$fh->open( "$file" ) || return undef;
	return $fh;
}
use Fatal qw(Open);


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub Table(@)
{
	my ($self, $param, $separator) = @_;

	return undef	if( _noData( $param ) );
	my $para  = $self->_normParam($param, $separator);

	my $form  = Script::Toolbox::Util::Formatter->new( $para );
	my $result= $form->matrix();
	return $result	if( ref $param eq 'ARRAY' || !defined $param->{'sumCols'} );

	return $form->sumBy($result, $param->{'sumCols'}, $param->{'notGroupBy'});
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _noData($)
{
	my ($param) = @_;

	if( ref $param eq 'HASH' && !defined $param->{'data'}[0] )
	{
	    Log( "WARNING: no input data for Table()." );
	    return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _normParam($$)
{
	my ($self, $param, $separator) = @_;

	if( ref $param eq 'HASH' )
	{
	return _sepHash($param, $separator)	if( _isCSV($param->{'data'}) );
	return $param;
	}
	return _sepTitleHead($param)	if( _isTitleHead($param) );
	return _sepCSV($param, $separator) 	if( _isCSV($param) );

	Log( "ERROR invalid Table() parameter" );
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _sepHash($$)
{
	my ($param,$separator) = @_;

	my $d = _sepCSV($param->{'data'}, $separator);
	$param->{'data'} = $d->{'data'};
	return $param;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _isTitleHead($)
{
	my ($param) = @_;

	return 1	if( ref \$param->[0] eq 'SCALAR' &&
		  	ref $param->[1] eq 'ARRAY' );
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _sepTitleHead($)
{
	my ($param) = @_;

	my $title= splice @{$param}, 0,1;
	my $head = splice @{$param}, 0,1;

	return	{
		'title'	=> $title,
		'head'	=> $head,
		'data'	=> $param
		};
}


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _isCSV($)
{
	my ($param) = @_;

	return 1	if( ref \$param->[0] eq 'SCALAR' &&
		  	ref \$param->[1] eq 'SCALAR' );
	return 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _sepCSV($$)
{
	my ($param, $separator) = @_;

	$separator = ';'	if( !defined $separator);
	my @R;
	foreach my $l ( @{$param} )
	{
	my @r;
	push @r, split /$separator/, $l;
	push @R, \@r;
	}

	return { 'data' => \@R };
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub SetOpsDef($)
{
	my ($self,$opsDef) = @_;
	my $old = $self->{'ops'};
	$self->{'ops'} = Script::Toolbox::Util::Opt->new( $opsDef );
	return ($self->{'ops'}, $old);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub GetOpt($)
{
	my ($self,$opt) = @_;
	return	undef if( ! defined $self->{'ops'} );
	return	$self->{'ops'}->get($opt);
}

#------------------------------------------------------------------------------
# Read the entire file into  an array or write the new content to the file.
# File can be a file name or an IO::File handle.
# Newcontent can be a SCALAR value, an ARRAY reference or a HASH reference.
#------------------------------------------------------------------------------
sub File(@)
{
	my ($filename,$newContent) = _getParam(@_);

	my ($fh,@F);
	if( !defined  $newContent) { return _ReadFile($filename); }
	else			   { _WriteFile($filename,$newContent); }
}

#------------------------------------------------------------------------------
# Open the file in required write mode (default append mode) and write the new
# content to the file.
# Newcontent can be any kind of data structure.
#------------------------------------------------------------------------------
sub _WriteFile($$)
{
	my($file,$newContent) =@_;

	my $fh;
	if( ref $file eq 'IO::File' )
	{
		$fh = $file;
	}else{
		$file =~ s/^\s*<+\s*//;	# write mode only 
		$file = '>>' . $file	if( $file !~ /^\s*>/ );
		$fh = Open( $file ) || return undef;
	}
	   if( ref $newContent eq '' ) 	   {print $fh $newContent;}
	elsif( _simpleArray( $newContent)) {map {print $fh $_;} @{$newContent};}
	elsif( _simpleHash( $newContent )) { _printSimpleHash($newContent, $fh); }
	else 				   { print $fh Dumper $newContent; }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _printSimpleHash($$)
{
    my ($content,$fh) = @_;
    foreach my $key (sort keys %{$content})
    {
	printf $fh "%s:%s",
	$key, $content->{$key}; 
    }
    return;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _simpleHash($)
{
    my ($content) = @_;

    return 0 if( ref $content ne 'HASH');
    foreach my $key ( keys %{$content} )
    {
    	return 0 if( ref $content->{$key} ne '' ); # scalar estimated
    }
    return 1;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _simpleArray($)
{
    my ($content) = @_;

    return 0 if( ref $content ne 'ARRAY');
    foreach my $line ( @{$content} )
    {
    	return 0 if( ref $line ne '' ); # scalar estimated
    }
    return 1;
}

#------------------------------------------------------------------------------
# Read the file content into an array and return a referenz to this array.
# Return undef if the file isn't readable.
# File can be a file name or an IO::File handle.
#------------------------------------------------------------------------------
sub _ReadFile($)
{
	my($file) =@_;

	my ($fh,@F);
	if( ref $file  eq 'IO::File' )
	{
	$fh = $file;
	}else{
	$file =~ s/^\s*>+\s*//; # read only mode
	$fh= Open( $file )  || return undef;
	}
	@F = <$fh>;
	return \@F;
}

#------------------------------------------------------------------------------
# Without an input argument TmpFile() returns an file handle to an new 
# temporary file.
# Otherwise read the tempfile into an array and return a reference to it.
#------------------------------------------------------------------------------
sub TmpFile(@)
{
    my ($file) = _getParam(@_);

	my ($f,@F);
	if( ref $file eq 'IO::File' ) { $file->seek(0,0); @F = <$file>; $f=\@F; }
	else			  { $f = IO::File::new_tmpfile; }
    return $f;
}


#------------------------------------------------------------------------------
# Return the filenames of a directory as array reference.
#------------------------------------------------------------------------------
sub Dir(@)
{
	my ($dirPath,$searchPattern) = _getParam(@_);

	my $d = IO::Dir->new($dirPath);
	return undef if( !defined $d );
	
	my @D;
	while( defined($_ = $d->read))
	{
	    next	if( _toSkip( $_, $searchPattern ));
	    push @D, $_;
	}
	@D = sort @D;
	return \@D;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _toSkip($$)
{
	my ($line,$pattern) = @_;

	return 1    if( $line =~ /^[.]{1,2}$/ ); 
	return 0    if( !defined $pattern );

	if( $pattern =~ /^\s*!/ )
	{
	    $pattern = substr($pattern, 1 );
	    return 1	if( $line =~ /$pattern/ );
	}else{
	    return 1	if( $line !~ /$pattern/ );
	}
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub Usage($$)
{
	my ($self, $add) = @_;

	return	$self->{'ops'}->usage($add);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub SetOpt($)
{
	my ($self,$opt,$value) = @_;
	return	undef unless defined $self->{'ops'};
	return	undef unless ref($self->{'ops'}) eq 'Script::Toolbox::Util::Opt';
	return	$self->{'ops'}->set($opt,$value);
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub _getParam(@)
{
    #if( isa( $_[0], "Script::Toolbox::Util" ))
    my $x = ref $_[0];
    if( $x =~ /Script::Toolbox/  )
    {
	shift @_ if( $_[0]->isa("Script::Toolbox::Util" ));
    }
    return @_;
}

1;
__END__

=head1 NAME

Script::Toolbox::Util - see documentaion of Script::Toolbox

=cut
