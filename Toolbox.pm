package Script::Toolbox;

use 5.006;
use strict;
use warnings;
use Script::Toolbox::Util qw(:all);

require Exporter;

our @ISA = qw(Script::Toolbox::Util Script::Toolbox::Util::Opt Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Script::Toolbox ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(Open Log Exit Table Usage Dir File System Now) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.19';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Script::Toolbox - Framework for the daily business scripts

=head1 SYNOPSIS

  use Script::Toolbox qw(:all);
  or
  use Script::Toolbox qw(Open Log Exit Table Usage Dir File System)

  $e = Script::Toolbox->new();
  # 
  # logging 
  #
  Log( "log message" );           # log to STDERR
  Log( "log message", 'STDERR' ); # log to STDERR
  Log( "log message", 'STDOUT' ); # log to STDOUT
  Log( "log message", '/tmp/x' ); # log to /tmp/x
  Log( "log message", new IO::File "/tmp/XXX" ); # log to /tmp/XXX

  Script::Toolbox->new({logdir=>{mod=>'=s',desc=>'Log directory',
            mand=>1,default=>'/var/log'}});
  Log( "log message" ); # log to /var/log/<scriptName>.log

  Log( "log message",'syslog','severity','tag' ); # log via syslogd


  #
  # print formatted tables like:
  #   print join "\n", @{$t};

  $t = $e->Table( [ "1;2;3","44;55;66","7.77;8.88;9.99" ] );
  $t = $e->Table( [ "1|2|3","44|55|66","7.77|8.88|9.99" ], '|');
  $t = $e->Table( [ 'This is the title',
           [ '--H1--', '--H2--','--H3--'],
           [ '11:11:11',  33.456, 'cc  ' ],
           [ '12:23:00', 2222222, 3 ],
           [ '11:11', 222, 3333333333333333 ]);
  $t = $e->Table({ 'title' => 'Hash example',
            'head'  => ['Col1', 'Col2', 'Col3'],
            'data'  => [[ '11:11:11',  33.456, 'cc  ' ],
                        [ '12:23:00', 2222222, 3 ],
                        [ '11:11', 222, 3333333333333333 ]]});
  $t = $e->Table({ 'title' => 'Hash with automatic column heads (F1,F2,F3)',
            'data' =>[{'F1'=>'aaaa','F2'=>'bbb','F3'=>'c'},
                      {'F1'=>'dd  ','F2'=>'ee ','F3'=>'f'}]});
  


  #
  # command line options
  #
  $tb=Script::Toolbox->new({file=>{mod=>'=s',desc=>'Description',
                 mand=>1,default=>'/bin/cat'}});

  $file = tb->GetOpt('file'); # depricated, use the following
  $file = tb->{'file'};

  $old  = tb->SetOpt('newFile');

  Usage(); # print a usage message for all options
           # if available print also the POD

  Usage('This is additional text for the usage');

  #
  # Directory handling
  #
  $arrRef = Dir('/tmp' );            # all except . and ..
  $arrRef = Dir('/tmp', '.*patt' );  # all matching patt
  $arrRef = Dir('/tmp', '!.*patt' ); # all not matching patt

  #
  # File handling
  #
  $arrRef = File('path/to/file'); # read file into array
  $arrRef = File("/bin/ps |"); # read comand STDOUT into array

  File( "> path/to/file", 'override the old content' );
  File( "path/to/file", 'append this to the file' );
  File( "path/to/file", $arrRef ); # append array elements 
  File( "path/to/file", $arrRef, $recSep ); # append array elements 
  File( "path/to/file", $hashRef, $recSep, $fieldSep); # append as key <$fldSep> value lines
  File( "| /bin/cat", "Hello world.\n" );


  $fileHandle = TmpFile(); # open new temporary file
  $arrRef = TmpFile($fileHandle) # read temp whole file


  #
  # Miscelleanous
  #
  Exit( 1, "Exit message" ); # exit with returncode 1, 
                             # write exit message via Log()

  $fh = Open( "> /tmp/xx" ); # return an IO::File object with
                             # /tmp/xx opened for write 
                             # die with logfile entry if failed
  $fh = Open( "/bin/ps |" ); # return an IO::File object
                             # die with logfile entry if failed
  $rc = System("/bin/ls")    # execute a system command and
                             # report it's output into the 
                             # logfile.
  $now = Now();
         printf "Day:%d Mon:%d Year:%d Wday:%d Yday:%d IsDST:%d Sec:%d Min:%d Hour:%d",
	            $now->{mday},
				$now->{mon},
				$now->{year},
				$now->{wday},
				$now->{yday},
				$now->{isdst},
				$now->{sec},
				$now->{min},
				$now->{hour};
  $now = Now('"%A, %B %d, %Y"'); # Monday, October 10, 2005
=head1 ABSTRACT

  This module should be a "swiss army knife" for the daily tasks.
  The main goals are command line processing, automatic usage
  messages, signal catching (with logging), simple logging, 
  simple data formatting, simple directory and file processing.
  

=head1 DESCRIPTION

=over 20

=item Exit(1,'The reason for the exit.')

Exit the script with return value 1. Write the message into
the log file via Log().

=item Log('The message', [channel])

Add a timestamp and write the log message to the channel. 
The channel may be 'STDERR' (default), 'STDOUT', '/path/to/logfile'
or an IO::File object. Without a channel and using the command
line option -logdir </path/to/log> the log file will be created 
under "/path/to/log/<scriptName>.log". ScriptName is the basename
of the perl script using Script::Toolbox.pm;

=item Table($dataRef)

Table can be used for formatting simple data structures into equal
spaced tables. Table knows the folloing input data structures:

=over 4

=item *

Array of CSV lines. Default separator is ';'

=item *

Array of arrays. If the first array element is a SCALAR value, we assume
it is the title and the second array element has the column headers.
Otherwise default title and headers will be generated.

=item *

A hash with the keys 'title', 'head' and 'data'. 'title' points to a
SCALAR value, 'head' points to a array of scalars. 'data' points to
an array of arrays or an array of hashes. 

In case of array of hashes, the column heads will be initialized from
the keys of the hash in the first array element. The order of the columns
is the order of the sorted keys of the hash in the first array element.

=back

=back


=item $arrRef = File('/path/to/file')

This function read the file content into an array.
Return a reference to this array or undef if file is not readable.

=item File( "> path/to/file", 'override the old content' )

Write the string to the file. Overwrite the old content of the file.

=item File( "path/to/file", 'append this to the file' )

Append the string to the file.


=item File( "path/to/file", $arrRef )

Append each array element to the end of the file as is (no automatic newline).


=item File( "path/to/file", $arrRef, $recSep )

Concatenate each array element with the record separator and append it to the file. 


=item File( "path/to/file", $hashRef, $recSep, $fieldSep )

Append records like  KEY$fieldSepVALUE$recSep to the file. Default record separator is 
the empty string. Default field separator is ":";

=item Dir('/path/to/dir')

This function lists the directory entries into an array (without '.' and '..').
Return a reference to this array or undef if directory not readable.

=item Dir('/path/to/dir', 'regexp')

This function lists the directory entries matching regexp into an array (without '.' and '..').
Return a reference to this array or undef if directory not readable.

=item Dir('/path/to/dir', '!regexp')

This function lists the directory entries into an array.
Skip '.'  '..' and any entry matching regexp.
Return a reference to this array or undef if directory not readable.

=item  System( 'command to execute' )

Execute a program in a new shell. The STDOUT / STDERR of the executed 
program will be logged into the logfile. System() returns 0 if the 
exit code of the program is not 0 otherwise 1;

=head1 SIGNALS

The signals SIGINT, SIGHUP, SIGQUIT and SIGTERM will be catched
by Script::Toolbox and logged as "program aborted by signal SIG$sig."



=head1 EXPORT

None by default. Can export Open,Log,Exit,Table,Usage,Dir,System or :all.


=head1 SEE ALSO

IO::File, Fatal, Script::Toolbox::Util, Script::Toolbox::Util::Open, Script::Toolbox::Util::Formatter


=head1 AUTHOR

Matthias Eckardt, E<lt>Matthias.Eckardt@link-up.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Matthias Eckardt, eckardt & braun GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
