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
our %EXPORT_TAGS = ( 'all' => [ qw(Open Log Exit Table Usage Dir File
						           System Now Menue KeyMap Stat) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.26';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Script::Toolbox - Framework for the daily business scripts

=head1 SYNOPSIS

  use Script::Toolbox qw(:all);

  $e = Script::Toolbox->new();

  #---------
  # Logging 
  #---------
  Log( "log message" );           # log to STDERR
  Log( "log message", "STDERR" ); # log to STDERR
  Log( "log message", "STDOUT" ); # log to STDOUT
  Log( "log message", "/tmp/x" ); # log to /tmp/x
  Log( "log message", new IO::File "/tmp/XXX" ); # log to /tmp/XXX

  Script::Toolbox->new(
        { logdir=>{mod=>"=s",
                   desc=>"Log directory",
                   mand=>1,
                   default=>"/var/log"}
        }
	);
  Log( "log message" ); # log to /var/log/<scriptName>.log

  Log( "log message","syslog","severity","tag" ); # log via syslogd


  #--------------------------
  # Formatted tables like:
  #   print join "\n", @{$t};
  #--------------------------

  $t = $e->Table( [ "1;2;3","44;55;66","7.77;8.88;9.99" ] );
  $t = $e->Table( [ "1|2|3","44|55|66","7.77|8.88|9.99" ], "|");
  $t = $e->Table( [ "This is the title",
           [ "--H1--", "--H2--","--H3--"],
           [ "11:11:11",  33.456, "cc  " ],
           [ "12:23:00", 2222222, 3 ],
           [ "11:11", 222, 3333333333333333 ]);
  $t = $e->Table({ "title" => "Hash example",
            "head"  => ["Col1", "Col2", "Col3"],
            "data"  => [[ "11:11:11",  33.456, "cc  " ],
                        [ "12:23:00", 2222222, 3 ],
                        [ "11:11", 222, 3333333333333333 ]]});
  $t = $e->Table({"title"=>"Hash with automatic column heads (F1,F2,F3)",
            "data" =>[{"F1"=>"aaaa","F2"=>"bbb","F3"=>"c"},
                      {"F1"=>"dd  ","F2"=>"ee ","F3"=>"f"}]});
  


  #----------------------
  # Command line options
  #----------------------
  $x    = {file=>{mod=>"=s",desc=>"Description",mand=>1,default=>"/bin/cat"}};
  $tb   = Script::Toolbox->new( $x );
  $file = tb->{"file"};
  $old  = tb->SetOpt("newFile");

  #--------------------------
  # Automatic usage messages
  #--------------------------
  Usage(); # print a usage message for all options
           # if available print also the POD

  Usage("This is additional text for the usage");

  #--------------------
  # Directory handling
  #--------------------
  $arrRef = Dir("/tmp" );            # all except . and ..
  $arrRef = Dir("/tmp", ".*patt" );  # all matching patt
  $arrRef = Dir("/tmp", "!.*patt" ); # all not matching patt

  $stat   = Stat("/bin");   # like Dir() with stat() for each file
  $stat   = Stat("/bin",".*grep"); # grep,egrep,fgrep

  #---------------
  # File handling
  #---------------
  # READ file
  $arrRef = File("path/to/file");              # read file into array
  $arrRef = File("/bin/ps |");                 # read comand STDOUT into array
  $arrRef = File("path/to/file", \&callback ); # filter with callback

  # WRITE file
  File( "> path/to/file", "override the old content" );
  File( "path/to/file",   "append this to the file" );
  File( "path/to/file",   $arrRef );           # append array elements 
  File( "path/to/file",   $arrRef, $recSep );  # append array elements 

                              # append key <$fldSep> value <$recSep>
  File( "path/to/file", $hashRef, $recSep, $fieldSep);
  File( "| /bin/cat", "Hello world.\n" );

  $fileHandle = TmpFile();                     # open new temporary file
  $arrRef     = TmpFile($fileHandle)           # read temp whole file


  #---------------------------------------------
  # Key maps. Key maps are hashs of hashs like:
  # key => key => ... key => value
  #---------------------------------------------
  # fill key map from CSV file
  $keyMap = KeyMap("path/to/file");
  $keyMap = KeyMap("path/to/file", $fieldSep);

  # write the hash to CSV file
  KeyMap("path/to/file", $fieldSep, $hashRef); 


  #---------------
  # Miscelleanous
  #---------------
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

  #------------------------+
  # Date and time handling |
  #------------------------+
  $n   = Now();
  print  $n->{mday},$n->{mon},  $n->{year},$n->{wday}, $n->{yday},
         $n->{isdst},$n->{sec}, $n->{min}, $n->{hour};
  print  Now->{epoch};
  $now = Now({format=>"%A, %B %d, %Y"});      # Monday, October 10, 2005
  $now = Now({offset=>3600});                 # now + 1 hour
  $diff= Now({diff=>time()+86400+3600+60+1}); # time+1d+1h+1min+1sec
  print  $diff->{seconds};                    # 90061 
  print  $diff->{minutes};                    # 1501.016
  print  $diff->{hours};                      # 25.01694
  print  $diff->{days};                       # 1.042373
  print  $diff->{DHMS};                       # "1d 01:01:01"


  #----------------
  # Menue handling
  #----------------
  # using Menue to start subroutines
  my $mainMenue = [{label=>"EXIT", jump=>\&_exit, argv=>0},
                   {label=>"Edit Hosts", jump=>\&editHosts, argv=>$ops},
                   {label=>"Activate Host", jump=>\&activate, argv=>$ops}, ];
  while(( 1 ) { my ($o,$mainMenue) = Menue($mainMenue); }

  # using Menue to display and edit some few data values
  my $dataMene = [{label=>"EXIT"},
                  {label=>"Name",value=>""},
                  {label=>"ZIP", value=>"01468"},
                  {label=>"City",value=>"Templeton"} ];

  while( 1 ) {
    my ($o,$dataMenue) = Menue($dataMenue);
    last if( $o == 0 );
  }
                
  # this is the output:
  # 0 EXIT
  # 1 Name  []
  # 2 ZIP   [01468]
  # 3 City  [Templeton]
  #
  # Select: 

=head1 ABSTRACT

  This module should be a "swiss army knife" for the daily tasks.
  The main goals are command line processing, automatic usage
  messages, signal catching (with logging), simple logging, 
  simple data formatting, simple directory and file processing.
  

=head1 DESCRIPTION

=over 3

=item Dir("/path/to/dir")

This function lists the file names in the directory into an array (without "." and "..").
Return a reference to this array or undef if directory is not readable.

=item Dir("/path/to/dir", "regexp")

This function lists the file names in the directory into an array (without "." and "..").
Skip any file names not matching regexp.
Return a reference to this array or undef if the directory is not readable.

=item Dir("/path/to/dir", "!regexp")

This function lists the file names in the directory into an array (without "." and "..").
Skip any file names matching regexp.
Return a reference to this array or undef if the directory is not readable.








=item Exit(1,"The reason for the exit.")

Exit the script with return value 1. Write the message to the log-channel
via Log().







=item $arrRef = File("/path/to/file")

This function read the file content into an array.
Return a reference to this array or undef if the file is not readable.

=item $arrRef = File("/path/to/file", \&callback)

Read the file into an array. Afterwards call the callback function with
a reference to that array. The return value of File() will be the return
value of the callback function. In case the callback function do not return 
anything, a reference to the input array of the callback function will be
returned. The callback function may return one scalar value.

Example:
 ...
 sub decrypt($) {...}
 $f = File("path/to/encrypted", \&decrypt);


=item File( "> path/to/file", "overwrite the old content" )

Write the string to the file. Overwrite the old content of the file.

=item File( "path/to/file", "append this to the file" )

Append the string to the file.


=item File( "path/to/file", $arrRef )

Append each array element to the end of the file as is (no automatic newline).


=item File( "path/to/file", $arrRef, $recSep )

Concatenate each array element with the record separator and append it to the file. 


=item File( "path/to/file", $hashRef, $recSep, $fieldSep )

Append records like  KEY$fieldSepVALUE$recSep to the file. Default record separator is 
the empty string. Default field separator is ":";







=item KeyMap("path/to/file")

Read a CSV file with the structure 

	key1.1,key1.2,...,value1
	key2.1,key2.2,...,value2

into a hash of the same structure. The default field separator is ",".

=item KeyMap("path/to/file", $fieldSep)

Use $fieldSep as  field separator.

=item KeyMap("path/to/file", \&callback)

Same funtionality as in File().

=item KeyMap("path/to/file", $fieldSep, \&callback)

Same funtionality as in File().
Use $fieldSep as  field separator.



=item KeyMap("path/to/file", $fieldSep, $hashRef)

Write a hash with the structure 

	key1.1 => key1.2 => ... => value1
	key2.1 => key2.2 => ... => value2

into a file of the same structure. Use $fieldSep as  field separator.






=item Log("The message", [channel])

Add a timestamp and write the log message to the channel. 
The channel may be F<"STDERR"> (default), F<"STDOUT">, F</path/to/logfile>
or an IO::File object. Without a channel and using the command
line option -logdir F</path/to/log> the log file will be created 
under F</path/to/log/<scriptName>.log>. ScriptName is the basename
of the perl script using Script::Toolbox.pm;





=item Now({format=><'strftime-format'>, offset=><+-seconds>})

Return the actual date and time. If $format is undef the result is a hash
ref. The keys are: I<sec min hour mday mon year wday yday isdst epoch.> 
Month and year are corrected. Epoch is the time in seconds since 1.1.1970.
If $format is not undef it must be a strftime() format string. The result
of Now() is then the strftime() formated date string. If defined, offset will be 
added to the epoch seconds before any format convertion takes place.

=item Now({diff=><time>})
$diff may be a value in epoch seconds or any string parseable by Time::ParseDate.
If Now() is called with a diff argument it returns a hash ref with following keys
I<seconds minutes hours days DHMS>. Each corresponding value is the 
difference between now and the given time value.

    Example:
    my $d = Now( time()- 1800 );
    print $d->{seconds} ."s"; 	# 1800.0s
    print $d->{minutes} ."min";	# 30.0min
    print $d->{hours}   ."h";	# 0.5h
    print $d->{days}    ."d";	# 0.02083d
    print $d->{DHMS};		# 0d 00:30:00


=item Stat("/path/to/dir", "!regexp")

Read the directory like Dir() and make a stat() call for each matching file.
Skip "."  ".." and any entry matching regexp.
Return a reference to a hash or undef if directory not readable.

=item Stat("/path/to/dir", "regexp")

Read the directory like Dir() and make a stat() call for each matching file.
Skip "."  ".." and any entry not matching regexp.
Return a reference to a hash or undef if directory not readable.

	Example:
	$d = Stat("/bin","echo");
	print $d->{"echo"}{atime};
	print $d->{"echo"}{blksize};
	print $d->{"echo"}{blocks};
	print $d->{"echo"}{ctime};
	print $d->{"echo"}{dev};
	print $d->{"echo"}{gid};
	print $d->{"echo"}{ino};
	print $d->{"echo"}{mode};
	print $d->{"echo"}{mtime};
	print $d->{"echo"}{nlink};
	print $d->{"echo"}{rdev};
	print $d->{"echo"}{size};
	print $d->{"echo"}{uid};


=item  System( "command to execute" )

Execute a program in a new shell. The STDOUT / STDERR of the executed 
program will be logged into the logfile. System() returns 0 if the 
exit code of the program is not 0 otherwise 1;







=item Table($dataRef)

Table can be used for formatting simple data structures into equal
spaced tables. Table knows the folloing input data structures:

=over 4

=item *

Array of CSV lines. Default separator is ";"

=item *

Array of arrays. If the first array element is a SCALAR value, we assume
it is the title and the second array element has the column headers.
Otherwise default title and headers will be generated.

=item *

A hash with the keys "title", "head" and "data". "title" points to a
SCALAR value, "head" points to a array of scalars. "data" points to
an array of arrays or an array of hashes. 

In case of array of hashes, the column heads will be initialized from
the keys of the hash in the first array element. The order of the columns
is the order of the sorted keys of the hash in the first array element.

=back

=back


=head1 SIGNALS

The signals SIGINT, SIGHUP, SIGQUIT and SIGTERM will be catched
by Script::Toolbox and logged as "program aborted by signal SIG$sig."



=head1 EXPORT

None by default. Can export Dir, Exit, File, KeyMap, Log,
Now, Open, Table, Usage, System, Stat or :all.


=head1 SEE ALSO

L<IO::File>, L<Fatal>, L<Script::Toolbox::Util>,
L<Script::Toolbox::Util::Open>, L<Script::Toolbox::Util::Formatter>


=head1 AUTHOR

Matthias Eckardt, E<lt>Matthias.Eckardt@imunixx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2008 by Matthias Eckardt, imunixx GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
