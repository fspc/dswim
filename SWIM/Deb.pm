#    Package administration and research tool for Debian
#    Copyright (C) 1999-2001 Jonathan D. Rosenbaum

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


package SWIM::Deb;
use strict;
use SWIM::Dir;
use SWIM::Global qw($argument %nsb %db %sb);
use SWIM::Conf qw(:Deb);
use SWIM::Format;
use SWIM::DB_Library qw(:Deb);
use SWIM::Compare;
use vars qw(@ISA @EXPORT);
use Exporter;
no warnings;
@ISA = qw(Exporter);
@EXPORT = qw(deb_package md5sumo);

$| = 1;

# this should be re-written to access the functions differently, because
# it was written to go into every function, then SelfLoader could be used.

# query Debian packages using dpkg-deb and dpkg, or ar for non dpkg
# installations.  
sub deb_package {
 
  my ($commands) = @_; my %commands = %$commands;

  # this routine will read in single or more packages at the command line
  # and/or directories with or without  a wild card, taking into account
  # such weird things as ../dir1/dir2/*. Wild cards - in case a package
  # doesn't end in deb.  rpm has error output when things aren't correct,
  # and STDOUT when thing are, swim doesn't do this..but it could, actually
  # the STDOUT is nicer, well maybe.  Ofcourse, --md5sum won't work here,
  # it's not necessary, actually it will under certain conditions
  # described in swim's manual.

      # This provides the full path of dir/file.  ../ not implemented yet.
      # So, the queries can occur within each situation. 
      if ($#ARGV != -1) {
         foreach (@ARGV) {

          ###############
          # SITUATION 0 #
          ###############
	  if (m,\.\./|^\.\.$,) {
	   #if ($_ !~ m,/[\w-+]+/[\.\$\^\+\?\*\[\]\w-]*$,) {
	   if ($_ !~ m,/(\w-+)+/[\.\$\^\+\?\*\[\]\w-]*$,) {
             my $dd; tr/\/// ? ($dd = tr/\///) : ($dd = 1); 
             my @pwd =  split(m,/,,$pwd);
             s,\.\./,,g;
             my $tpwd = "";
             for (1 .. $#pwd - $dd) {
               $_ == 1  ? ($tpwd = "/$pwd[$_]") 
                        : ($tpwd = $tpwd . "/$pwd[$_]");
             }
            $_ ne ".." ? ($argument = "$tpwd/$_") : ($argument = "$tpwd/");
           }
           else {  print "swim: not implemented yet\n"; exit; }
            dir(\%commands);
            fir(\%commands);
             # we will first check to see if $argument really is a Debian
             # package
             my $real;
             if ($dpkg_deb) {
              $real = system("$dpkg_deb -f $argument Package 2&>/dev/null"); 
             }
             elsif ($ar) {
              $real = system "$ar -p $argument debian-binary 2&>/dev/null";
             }
             # construct the fields to the standard of swim
             if ($real == 0) {
              printme(\%commands);
              scripto(\%commands);
              menuo(\%commands);
              copyrighto(\%commands);
              changelogo(\%commands);
              if ($commands->{"i"}) {         
                shbang(\%commands);
                package_processor(\%commands);
                if ($dpkg_deb) {
                 print "Description: ";
                 system "$dpkg_deb -f $argument Description";
                }
                elsif ($ar) {
                 system "$ar -p $argument control.tar.gz | $tar xOz control |\
                         $grep -E \"Description: \w*|[.]\$|^ [\w-]*\"";
                }
                if (!($commands->{"T"} || $commands->{"pre_depends"} || 
                      $commands->{"depends"} || $commands->{"recommends"} ||
                      $commands->{"suggests"} || $commands->{"provides"} ||
                      $commands->{"replaces"} || $commands->{"conflicts"} ||
                      $commands->{"c"} || $commands->{"l"})) {
                      print "\n";
                 }
              }                  
              shlibso(\%commands);
              md5sumo(\%commands);
              deps(\%commands);
              # nothing fancy here, no md5sums, no indenting.
              if ($commands->{"c"}) {
               if ($dpkg_deb) {
              $real = system "$dpkg_deb -I $argument conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$dpkg_deb --info $argument conffiles";
                  undef $real;
                }
               }             
               elsif ( $ar) {
              $real = system "$ar -p $argument control.tar.gz |\ 
                              $tar tOz conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$ar -p $argument control.tar.gz \|
                          $tar xOz conffiles";
                  undef $real;
                }
               }
              }            
              listing(\%commands);
              print "\n";
              extract(\%commands);
             }
             elsif ($real != 0) {
               $argument =~ m,.*\/(.*$),;
               if (!-d $argument) {
                print "$1 is not a debian package\n\n";
               }
               else {
                print "$1 is a directory\n\n";
               }
             }
          }

          ###############
          # SITUATION I #
          ###############
          elsif ( m,\/,) {
            $argument = $_;
              if ($argument =~ m,^\.\/.*,) {
                  if ($pwd !~ m,^\/$,) {
                    $argument =~ m,^\.([^\.].*$),;
                    $argument = "$pwd$1";
                  }
                  else {
                   $argument =~ m,^\.([^\.].*$),;
                   $argument = "$1";
                  }
              } 
            dir(\%commands);
            fir(\%commands);
             # we will first check to see if $argument really is a Debian
             # package
             my $real;
             if ( $dpkg_deb) {
              $real = system("$dpkg_deb -f $argument Package 2&>/dev/null"); 
             }
             elsif ( $ar) {
              $real = system "$ar -p $argument debian-binary 2&>/dev/null";
             }
             # construct the fields to the standard of swim
             if ($real == 0) {
              printme(\%commands);
              scripto(\%commands);
              menuo(\%commands);
              copyrighto(\%commands);
              changelogo(\%commands);
              if ($commands->{"i"}) {         
                shbang(\%commands);
                package_processor(\%commands);
                if ( $dpkg_deb) {
                 print "Description: ";
                 system "$dpkg_deb -f $argument Description";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz | $tar xOz control |\
                         $grep -E \"Description: \w*|[.]\$|^ [\w-]*\"";
                }
                if (!($commands->{"T"} || $commands->{"pre_depends"} || 
                      $commands->{"depends"} || $commands->{"recommends"} ||
                      $commands->{"suggests"} || $commands->{"provides"} ||
                      $commands->{"replaces"} || $commands->{"conflicts"} ||
                      $commands->{"c"} || $commands->{"l"})) {
                      print "\n";
                 }
              }                  
              shlibso(\%commands);
              md5sumo(\%commands);
              deps(\%commands);
              # nothing fancy here, no md5sums, no indenting.
              if ($commands->{"c"}) {
               if ( $dpkg_deb) {
              $real = system "$dpkg_deb -I $argument conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$dpkg_deb --info $argument conffiles";
                  undef $real;
                }
               }             
               elsif ( $ar) {
              $real = system "$ar -p $argument control.tar.gz |\ 
                              $tar tOz conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$ar -p $argument control.tar.gz \|
                          $tar xOz conffiles";
                  undef $real;
                }
               }
              }            
              listing(\%commands);
              print "\n";
              extract(\%commands);
             }
             elsif ($real != 0) {
               $argument =~ m,.*\/(.*$),;
               if (!-d $argument) {
                print "$1 is not a debian package\n\n";
               }
               else {
                print "$1 is a directory\n\n";
               }
             }
          }

          ################
          # SITUATION II #
          ################
          elsif ($pwd =~ m,^\/$,) {
            $argument = "/$_";
            dir(\%commands);
            fir(\%commands);
             # we will first check to see if $argument really is a Debian
             # package 
             my $real;
             if ( $dpkg_deb) {
              $real = system("$dpkg_deb -f $argument Package 2&>/dev/null"); 
             }
             elsif ( $ar) {
              $real = system "$ar -p $argument debian-binary 2&>/dev/null";
             }
             # construct the fields to the standard of swim
             if ($real == 0) {
              printme(\%commands);
              scripto(\%commands);
              menuo(\%commands);
              copyrighto(\%commands);
              changelogo(\%commands);
              if ($commands->{"i"}) {         
                shbang(\%commands);
                package_processor(\%commands);
                if ( $dpkg_deb) {
                 print "Description: ";
                 system "$dpkg_deb -f $argument Description";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz | $tar xOz control |\
                         $grep -E \"Description: \w*|[.]\$|^ [\w-]*\"";
                }
                if (!($commands->{"T"} || $commands->{"pre_depends"} || 
                      $commands->{"depends"} || $commands->{"recommends"} ||
                      $commands->{"suggests"} || $commands->{"provides"} ||
                      $commands->{"replaces"} || $commands->{"conflicts"} ||
                      $commands->{"c"} || $commands->{"l"})) {
                      print "\n";
                 }
              }
              shlibso(\%commands);
              md5sumo(\%commands);
              deps(\%commands);
              # nothing fancy here, no md5sums, no indenting.
              if ($commands->{"c"}) {
               if ( $dpkg_deb) {
              $real = system "$dpkg_deb -I $argument conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$dpkg_deb --info $argument conffiles";
                  undef $real;
                }
               }             
               elsif ( $ar) {
              $real = system "$ar -p $argument control.tar.gz |\ 
                              $tar tOz conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$ar -p $argument control.tar.gz \|
                          $tar xOz conffiles";
                  undef $real;
                }
               }
              }            
              listing(\%commands);
              print "\n";
              extract(\%commands);
             }
             elsif ($real != 0) {
               $argument =~ m,.*\/(.*$),;
               if (!-d $argument) {
                print "$1 is not a debian package\n\n";
               }
               else {
                print "$1 is a directory\n\n";
               }
             }
          }

          #################
          # SITUATION III #
          #################
          else {
            $argument = "$pwd/$_";
              if ($argument =~ m,\.$,) {
                 $argument =~ m,(.*)\.$,;
                 $argument = $1;
               }
            dir(\%commands);
            fir(\%commands);
             # we will first check to see if $argument really is a Debian
             # package 
             my $real;
             if ( $dpkg_deb) {
              $real = system("$dpkg_deb -f $argument Package 2&>/dev/null"); 
             }
             elsif ( $ar) {
              $real = system "$ar -p $argument debian-binary 2&>/dev/null";
             }
             # construct the fields to the standard of swim
             if ($real == 0) {
              printme(\%commands);
              scripto(\%commands);
              menuo(\%commands);
              copyrighto(\%commands);
              changelogo(\%commands);
              if ($commands->{"i"}) {         
                shbang(\%commands);
                package_processor(\%commands);
                if ( $dpkg_deb) {
                 print "Description: ";
                 system "$dpkg_deb -f $argument Description";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz | $tar xOz control |\
                         $grep -E \"Description: \w*|[.]\$|^ [\w-]*\"";
                }
                if (!($commands->{"T"} || $commands->{"pre_depends"} || 
                      $commands->{"depends"} || $commands->{"recommends"} ||
                      $commands->{"suggests"} || $commands->{"provides"} ||
                      $commands->{"replaces"} || $commands->{"conflicts"} ||
                      $commands->{"c"} || $commands->{"l"})) {
                      print "\n";
                 }
              }
              shlibso(\%commands);
              md5sumo(\%commands);
              deps(\%commands);
              # nothing fancy here, no md5sums, no indenting.
              if ($commands->{"c"}) {
               if ( $dpkg_deb) {
              $real = system "$dpkg_deb -I $argument conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$dpkg_deb --info $argument conffiles";
                  undef $real;
                }
               }             
               elsif ( $ar) {
              $real = system "$ar -p $argument control.tar.gz |\ 
                              $tar tOz conffiles >/dev/null 2>&1";      
                if ($real == 0) {
                  system "$ar -p $argument control.tar.gz \|
                          $tar xOz conffiles";
                  undef $real;
                }
               }
              }            
              listing(\%commands);
              print "\n";
              extract(\%commands);
             }
             elsif ($real != 0) {
               $argument =~ m,.*\/(.*$),;
               if (!-d $argument) {
                print "$1 is not a debian package\n\n";
               }
               else {
                print "$1 is a directory\n\n";
               }
             }
          }
         }
       }

       # NO ARGUMENTS
       else {
         print "swim: no arguments given for query\n";
         exit;
       }

} # end sub deb_package


# It's nice to be able to quickly extract a file from a package in the
# immediate directory or the path above where swim is being run from.  This
# will be integrated with the DF directory.  Probably the ability to enter just
# filename(s) will replace the PWD\! method.
sub extract {

  my ($commands) = @_; my %commands = %$commands;
 

 if ($commands->{"extract"}) {

   my ($file,$same);
   $commands->{"extract"} =~ /!/  
           ? (($same,$file) = (split(/!/,$commands->{"extract"}))[0,1])
           : ($file = $commands->{"extract"});


   # extract files into the current directory
   if ( $same) { 
    # this is one of these instances where not being precise is o.k.
    print "swim: specify PWD before ! :*}\n" if $same ne "PWD";
    print "swim: PWD is used for extracting files into the current directory\n"
    if $file =~ m,.*/$,; exit if $file  =~ m,.*/$,; 
    chdir($tmp);
    if ( $dpkg_deb) {
     system "$dpkg_deb --fsys-tarfile $argument | $tar x $file 2> fields.deb";
    }
    elsif ( $ar) {
     system "$ar -p $argument data.tar.gz | $tar xz $file 2> fields.deb";   
    }

    if (!-z "fields.deb") {
     print "swim: archive does not exist\n";
     exit;
    }

    $file =~ m,.*/(.*)$,;
    rename("$tmp/$file","$pwd/$1") 
    or system "$mv","$tmp/$file", "$pwd/$1";
    my @ddirs = split(m,/,,$file);
    if ( @ddirs) {
      chdir("$tmp/$ddirs[0]");
      system "rm -rf *";
      chdir($tmp);
      rmdir($ddirs[0]);
    }
    else {
      unlink($file);
    }
   print "swim: $1 has been extracted\n";
   }

   # extract full path of archive above pwd  
    elsif ($file ne "ALL") {

    chdir($pwd);
    if ( $dpkg_deb) {
     system "$dpkg_deb --fsys-tarfile $argument | $tar x $file 2> $tmp/fields.deb";
    }
    elsif ( $ar) {
     system "$ar -p $argument data.tar.gz | $tar xz $file 2> $tmp/fields.deb";   
    }

    if (!-z "$tmp/fields.deb") {
     print "swim: archive does not exist\n";
     exit;
    }
    else {
     print "swim: $file has been extracted\n";
    }

   }
 
   # extract everything
   else   {

      chdir($pwd);
    if ( $dpkg_deb) {
     system "$dpkg_deb --fsys-tarfile $argument | $tar x  2> $tmp/fields.deb";
    }
    elsif ( $ar) {
     system "$ar -p $argument data.tar.gz | $tar xz  2> $tmp/fields.deb";
    }
    $argument =~ m,.*/(.*)$,;
    print "swim: $1 has been extracted\n";
   }

  }

} # end sub extract


# This checks the md5sum for a package if the not-installed database has
# the information.  The --arch --dist can be specified until a match is
# made
sub md5sumo {

  my ($commands) = @_; my %commands = %$commands;

  # first grab the md5sum for this package and put it into a temporary file
  # to be processed by md5sum  
  if ($commands->{"md5sum"}) {

   ndb(\%commands);
   $argument =~ m,^.*/(.*).deb$,;
   my $one = $1;
   my (@underlines, $nv);
   my $underlines = $1;
   my $unc = ($underlines =~ tr/_//);
   if ($unc > 1) {
     @underlines = split(/_/,$underlines);
     $one = $underlines[0] . "_" . $underlines[1];
   }
   my $md = $one . "MD";
   if ( defined $db{"$md"}) {
    # revision: situation 
    if ($db{"$md"} =~ /REVISION/) {
       $md = (split(/\s/,$db{$md}))[0];
    } 
   open(MD5SUM,">$tmp/md5sum.deb") or die "no such place\n";
     print MD5SUM $db{"$md"}, "  $argument\n"; 
     my $numbers = $db{"$md"};
   close(MD5SUM);
   system "$md5sum -c $tmp/md5sum.deb 2> $tmp/md5sumcheck";
    $argument =~ m,^.*/(.*.deb$),;      
    open(MD5SUMCHECK, "$tmp/md5sumcheck");
    if (!defined <MD5SUMCHECK>) {
        print "$one  $numbers  OK\n";
    }
    else {
     while (<MD5SUMCHECK>) {
      if ($_ !~ /no files checked/) {
        if (/failed/) {
          print "$one  $numbers  FAILED\n";
        }
        # just in case
        elsif (/can't open/) {
          print "$one  $numbers  MISSING\n";
        }
      }
     }
    }
    close(MD5SUMCHECK);
   } 


 }


} # end sub md5sumo


# This just shows the name and version of the package if no other options
# are used for -p
sub printme {

  my ($commands) = @_; my %commands = %$commands;

  if ($commands->{"p"} && !($commands->{"i"} || $commands->{"l"} ||
      $commands->{"df"} || $commands->{"d"} || $commands->{"c"} ||
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"}  || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"} || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
      if ( $dpkg_deb) {
       system "$dpkg_deb -f $argument Package > $tmp/temp.deb";
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Package: > $tmp/temp.deb";
       system "perl -pi -e \"s/Package: //\" $tmp/temp.deb";
      }
      open (PRINTME,"$tmp/temp.deb");
      while (<PRINTME>) {
       chomp;
       print;
      }
      print "_";
      if ( $dpkg_deb) {
       system "$dpkg_deb", "-f", "$argument", "Version";   
      } 
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Version: > $tmp/temp.deb";
       system "perl -pi -e \"s/Version: //\" $tmp/temp.deb";       
       system "$cat", "$tmp/temp.deb";
      }
      print "\n";
  }
  elsif ($commands->{"p"} && ($commands->{"l"} || $commands{"d"} ||
         $commands{"c"})
      && !($commands->{"i"} || $commands->{"df"} ||
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}  || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"} || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
      if ( $dpkg_deb) {
       system "$dpkg_deb -f $argument Package > $tmp/temp.deb";
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Package: > $tmp/temp.deb";
       system "perl -pi -e \"s/Package: //\" $tmp/temp.deb";
      }
      open (PRINTME,"$tmp/temp.deb");
      while (<PRINTME>) {
       chomp;
       print;
      }
      print "_";
      if ( $dpkg_deb) {
       system "$dpkg_deb", "-f", "$argument", "Version";   
      } 
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Version: > $tmp/temp.deb";
       system "perl -pi -e \"s/Version: //\" $tmp/temp.deb";       
       system "$cat", "$tmp/temp.deb";
      }
      print "\n";
  }
=pod

A little over-kill, but leaving this for now, just in case I figure out
that there was a reason for doing it this way.

  elsif ($commands->{"p"} && $commands {"c"} && !($commands->{"i"} || 
      $commands->{"df"} || $commands->{"d"} || $commands->{"l"} ||
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"}  || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} &&
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
      if ( $dpkg_deb) {
       system "$dpkg_deb -f $argument Package > $tmp/temp.deb";
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Package: > $tmp/temp.deb";
       system "perl -pi -e \"s/Package: //\" $tmp/temp.deb";
      }
      print "\n";
      open (PRINTME,"$tmp/temp.deb");
      while (<PRINTME>) {
       chomp;
       print;
      }
      print "_";
      if ( $dpkg_deb) {
       system "$dpkg_deb", "-f", "$argument", "Version";   
      } 
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Version: > $tmp/temp.deb";
       system "perl -pi -e \"s/Version: //\" $tmp/temp.deb";       
       system "$cat", "$tmp/temp.deb";
      }
  }
  elsif ($commands->{"p"} && $commands {"c"} && $commands->{"d"} &&
      !($commands->{"i"} || $commands->{"df"} || $commands->{"l"} || 
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"}  || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
      if ( $dpkg_deb) {
       system "$dpkg_deb -f $argument Package > $tmp/temp.deb";
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Package: > $tmp/temp.deb";
       system "perl -pi -e \"s/Package: //\" $tmp/temp.deb";
      }
      print "\n";
      open (PRINTME,"$tmp/temp.deb");
      while (<PRINTME>) {
       chomp;
       print;
      }
      print "_";
      if ( $dpkg_deb) {
       system "$dpkg_deb", "-f", "$argument", "Version";   
      } 
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Version: > $tmp/temp.deb";
       system "perl -pi -e \"s/Version: //\" $tmp/temp.deb";       
       system "$cat", "$tmp/temp.deb";
      }
  }
  elsif ($commands->{"p"} && $commands {"c"} && $commands->{"d"} &&
      $commands->{"l"} && !($commands->{"i"} || $commands->{"df"} || 
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
      if ( $dpkg_deb) {
       system "$dpkg_deb -f $argument Package > $tmp/temp.deb";
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Package: > $tmp/temp.deb";
       system "perl -pi -e \"s/Package: //\" $tmp/temp.deb";
      }
      print "\n";
      open (PRINTME,"$tmp/temp.deb");
      while (<PRINTME>) {
       chomp;
       print;
      }
      print "_";
      if ( $dpkg_deb) {
       system "$dpkg_deb", "-f", "$argument", "Version";   
      }
      elsif ( $ar) {
       system "$ar -p $argument control.tar.gz | $tar Oxz |\
               $grep Version: > $tmp/temp.deb";
       system "perl -pi -e \"s/Version: //\" $tmp/temp.deb";       
       system "$cat", "$tmp/temp.deb";
      }
  }
=cut

} # end sub printme


sub copyrighto {

 # maybe
 $argument =~ m,(.*\/)(.*$),;
 my ($commands) = @_; my %commands = %$commands;


 if ($commands->{"copyright"}) {
   # find everything with change
   if ( $dpkg_deb) {
    system "$dpkg_deb --fsys-tarfile $argument | $tar t |\ 
            $grep -E \"usr/doc\|usr/share/doc\" |\ 
            $grep -Ei \"copy|license\" > $tmp/fields.deb";

   # Maybe just do this once, faster.
   # occasionally a changelog is linked to another file..so that file has
   # to be used instead, this routine checks for this situation.
    system "$dpkg_deb --fsys-tarfile $argument | $tar tv |\ 
            $grep -E \"usr/doc\|usr/share/doc\" |\ 
            $grep -Ei \"copy|license\" > $tmp/linkto.deb";
   }
   elsif ( $ar) {
    system "$ar -p $argument data.tar.gz | $tar tz |\ 
            $grep -E \"usr/doc\|usr/share/doc\" |\ 
            $grep -Ei \"copy|license\" > $tmp/fields.deb";

    system "$ar -p $argument data.tar.gz | $tar tvz |\
            $grep -E \"usr/doc\|usr/share/doc\" |\ 
            $grep -Ei \"copy|license\" > $tmp/linkto.deb";
   } 
   
   my @links;
   my $whattodo;
   open (LINKTO,"$tmp/linkto.deb") || die "humm, not created";
     while (<LINKTO>) {
        m,.*[\d|to]\s(.*$),;
        push(@links,$1);  
      if (/link to/) {
       $whattodo = "yes";
      }
     }
   if ( $whattodo) { 
    open(FIELDS, ">$tmp/fields.deb");
    foreach (@links) {
      print FIELDS;
      print FIELDS "\n";
    }
    close(FIELDS);
   }
    

   # extract and read the files
    chdir("$tmp"); 
    open(TAR,"$tmp/fields.deb");
    my $name = $2;
    while (<TAR>) {
     chomp;
     # An easier way - xO, for .gz.. | gzip -d or zcat
          $_ =~ m,.*\/(.*$),;
          my $change = $1;
         if ($_ =~ m,\.gz$,) {
           print "#####$change for $name#####\n\n";
           if ( $dpkg_deb) {
            system "$dpkg_deb --fsys-tarfile $argument |\ 
                    $tar xO $_ | gzip -d";
            print "\n";
           }
           elsif ( $ar) {
            system "$ar -p $argument data.tar.gz |\ 
                    $tar xOz $_ | gzip -d";
            print "\n";
           }
         }
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
           print "#####$change for $name#####\n\n";
           if ( $dpkg_deb) {
            system "$dpkg_deb --fsys-tarfile $argument | $tar xO $_";
            print "\n";
           }
           elsif ( $ar) {
            system "$ar -p $argument data.tar.gz | $tar xOz $_";
            print "\n";
           }
         }
    } 
  }

} # end copyrighto



# we get to use --fsys-tarfile in this one, tar and grep.
sub changelogo {

 # maybe
 $argument =~ m,(.*\/)(.*$),;
 my ($commands) = @_; my %commands = %$commands;


 if ($commands->{"changelog"}) {
   # find everything with change
   if ( $dpkg_deb) {
    system "$dpkg_deb --fsys-tarfile $argument | $tar t |\ 
            $grep -E \"usr/doc\|usr/share/doc\" |\
            $grep -i change > $tmp/fields.deb";
   }
   elsif ( $ar) {
    system "$ar -p $argument data.tar.gz | $tar tz |\ 
            $grep -E \"usr/doc\|usr/share/doc\" |\
            $grep -i change > $tmp/fields.deb";
   }

   # Maybe just do this once, faster.
   # occasionally a changelog is linked to another file..so that file has
   # to be used instead, this routine checks for this situation.
   if ( $dpkg_deb) {
    system "$dpkg_deb --fsys-tarfile $argument | $tar tv | $grep usr/doc |\ 
            $grep -i change > $tmp/linkto.deb";
   }
   elsif ( $ar) {
    system "$ar -p $argument data.tar.gz | $tar tvz | $grep usr/doc |\ 
            $grep -i change > $tmp/linkto.deb";
   }  

   my @links;
   my $whattodo;
   open (LINKTO,"$tmp/linkto.deb") || die "humm, not created";
     while (<LINKTO>) {
        m,.*[\d|to]\s(.*$),;
        push(@links,$1);  
      if (/link to/) {
       $whattodo = "yes";
      }
     }
   if ( $whattodo) { 
    open(FIELDS, ">$tmp/fields.deb");
    foreach (@links) {
      print FIELDS;
      print FIELDS "\n";
    }
    close(FIELDS);
   }
    

   # extract and read the files
    chdir("$tmp"); 
    open(TAR,"$tmp/fields.deb");
    my $name = $2;
    while (<TAR>) {
     chomp;
     # An easier way - xO, for .gz.. | gzip -d or zcat
          $_ =~ m,.*\/(.*$),;
          my $change = $1;
         if ($_ =~ m,\.gz$,) {
           print "#####$change for $name#####\n\n";
           if ( $dpkg_deb) {
            system "$dpkg_deb --fsys-tarfile $argument | $tar xO $_ |\
                    gzip -d";
            print "\n";
           }
           elsif ( $ar) {
            system "$ar -p $argument data.tar.gz | $tar xOz $_ |\
                    gzip -d";
            print "\n";
           }
         }
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
           print "#####$change for $name#####\n\n";
           if ( $dpkg_deb) {
            system "$dpkg_deb --fsys-tarfile $argument | $tar xO $_";
            print "\n";
           }
           elsif ( $ar) {
            system "$ar -p $argument data.tar.gz | $tar xOz $_";
            print "\n";
           }
         }
    } 
  }

} # end changelogo

# show the menu script from /usr/lib/menu
sub menuo {

 $argument =~ m,(.*\/)(.*$),;
 my ($commands) = @_; my %commands = %$commands;

 if ($commands->{"menu"} || $commands->{"m"}) {
   # find everything with change
  if ( $dpkg_deb) {
   system "$dpkg_deb --fsys-tarfile $argument | $tar t |\
   $grep -E usr/lib/menu/[0-9A-Za-z\+\.-] > $tmp/fields.deb";

   # extract and read the files
    chdir("$tmp"); 
    open(MENU,"$tmp/fields.deb");
     my $name = $2;
    while (<MENU>) {
      #print "$_\n";
      #if (m,^usr\/lib\/menu\/(.*[\w-\+\.]$),) {
      if (m,^usr\/lib\/menu\/(.*(\w-\+\.)$),) {
       print "#####menu for $name($1)#####\n";
       system "$dpkg_deb --fsys-tarfile $argument | $tar xO $_";
       print "\n";
      }
    }
    close(MENU);
  }
  elsif ( $ar) {
   system "$ar -p $argument data.tar.gz |\ 
           $tar tOz usr/lib/menu/[0-9A-Za-z\+\.-]* 2> $tmp/fields.deb";

   # extract and read the files
    chdir("$tmp"); 
    open(MENU,"$tmp/fields.deb");
     my $name = $2;
    while (<MENU>) {
      #if (m,^usr\/lib\/menu\/(.*[\w-\+\.]$),) {
      if (m,^usr\/lib\/menu\/(.*(\w-\+\.)$),) {
       print "#####menu for $name($1)#####\n";
       system "$ar -p $argument data.tar.gz | $tar xOz $_";
       print "\n";
      }
    }
    close(MENU);
  }
 } 

} # end sub menuo


# grab all the scripts or a particular one
sub scripto {
    
   my ($commands) = @_; my %commands = %$commands;
   $argument =~ m,.*\/(.*)_.*$,;
   my $real;

   # Give a title.
   if ($commands->{"scripts"} && !($commands->{"preinst"} ||
       $commands->{"postinst"} || $commands->{"prerem"} ||
       $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"})) {

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument preinst >/dev/null 2>&1";
         if ($real == 0) {
           print "#####$1.preinst#####\n";
           $real = system "$dpkg_deb -I $argument preinst";
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz preinst >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.preinst#####\n";
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz preinst";
           undef $real;
         }
        }

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument postinst >/dev/null 2>&1";
         if ($real == 0) {
           print "#####$1.postinst#####\n";
           system "$dpkg_deb -I $argument postinst";
           undef $real;
         }
        }
        elsif ( $ar) {         
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz postinst >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.postinst#####\n";
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz postinst";
           undef $real;
         }
        }

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument prerm >/dev/null 2>&1";      
         if ($real == 0) {
           print "#####$1.prerm#####\n";
           $real = system "$dpkg_deb -I $argument prerm";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz prerm >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.prerm#####\n";
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz prerm";
           undef $real;
         }
        }

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument postrm >/dev/null 2>&1";   
         if ($real == 0) {
           print "#####$1.postrm#####\n";
           $real = system "$dpkg_deb -I $argument postrm";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz postrm >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.postrm#####\n";
           $real = system "$dpkg_deb -I $argument postrm";            
           undef $real;
         }
        }

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument config >/dev/null 2>&1";      
         if ($real == 0) {
           print "#####$1.config#####\n";
           $real = system "$dpkg_deb -I $argument config";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz config >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.config#####\n";
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz config";
           undef $real;
         }
        }

        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument templates >/dev/null 2>&1";      
         if ($real == 0) {
           print "#####$1.templates#####\n";
           $real = system "$dpkg_deb -I $argument templates";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz templates >/dev/null 2>&1"; 
         if ($real == 0) {
           print "#####$1.templates#####\n";
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz templates";
           undef $real;
         }
        }

   } 

   # no titles here
   if ($commands->{"preinst"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument preinst >/dev/null 2>&1";
         if ($real == 0) {
           $real = system "$dpkg_deb -I $argument preinst";
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz preinst >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz preinst";
           undef $real;
         }
        }
   }

   if ($commands->{"postinst"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument postinst >/dev/null 2>&1";
         if ($real == 0) {
           system "$dpkg_deb -I $argument postinst";
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz postinst >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz postinst";
           undef $real;
         }
        }
   }

   if ($commands->{"prerm"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument prerm >/dev/null 2>&1";      
         if ($real == 0) {
           $real = system "$dpkg_deb -I $argument prerm";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz prerm >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz prerm";
           undef $real;
         }
        }
   }

   if ($commands->{"postrm"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument postrm >/dev/null 2>&1";   
         if ($real == 0) {
           $real = system "$dpkg_deb -I $argument postrm";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz postrm >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz postrm";
           undef $real;
         }
        }
   }

   if ($commands->{"config"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument config >/dev/null 2>&1";   
         if ($real == 0) {
           $real = system "$dpkg_deb -I $argument config";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz config >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz config";
           undef $real;
         }
        }
   }

   if ($commands->{"templates"}) {
        if ( $dpkg_deb) {
         $real = system "$dpkg_deb -I $argument templates >/dev/null 2>&1";   
         if ($real == 0) {
           $real = system "$dpkg_deb -I $argument templates";            
           undef $real;
         }
        }
        elsif ( $ar) {
         $real = system "$ar -p $argument control.tar.gz |\
                         $tar tOz templates >/dev/null 2>&1"; 
         if ($real == 0) {
           $real = system "$ar -p $argument control.tar.gz |\
                           $tar xOz templates";
           undef $real;
         }
        }
   }

} # end scripto

# this is the format for packages which provide shared libraries.  The
# default form is shown, although it would be posibble to show the
# *.so.digits library depends (what version)
sub shlibso {

  my ($commands) = @_; my %commands = %$commands;

   if ($commands->{"shlibs"}) {
      if ( $dpkg_deb) { 
        my $real = system "$dpkg_deb -I $argument shlibs >/dev/null 2>&1";   
        if ($real == 0) {
          print "Shlibs:\n";
          system "$dpkg_deb", "-I", "$argument", "shlibs";            
          print "\n";
        }
      }
      elsif ( $ar) {
        my $real = system "$ar -p $argument control.tar.gz |\ 
                   $tar tOz shlibs >/dev/null 2>&1";   
        if ($real == 0) {
          print "Shlibs:\n";
          system "$ar -p $argument control.tar.gz |\ 
                   tar xOz shlibs";   
          print "\n";
        }
      }
   }


} # end shlibso


# This presents two types of listings, the default one provided by
# dpkg_deb, and a short listing which equates to what is found in *.list.
# This is important for do it yourself comparison purposes.  There is a
# chance a comparison routine will be built into --db in the near future.
sub listing {

  my ($commands) = @_; my %commands = %$commands;
    
     # These next to print out the verbose ls -la listing when -v is used
     if (($commands->{"l"} && $commands->{"v"}) && !$commands->{"d"}) {
        if ($commands->{"df"}) {
         if ( $dpkg_deb) { 
          system "$dpkg_deb --contents $argument";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\ 
                         $tar tOzv 2> $tmp/fields.deb; \
                         $cat $tmp/fields.deb";
         } 
        }
        elsif (!$commands->{"df"}) {
         if ( $dpkg_deb) { 
          system "$dpkg_deb --contents $argument > $tmp/fields.deb";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\
                   $tar tOzv 2> $tmp/fields.deb";
         }
         open(LISTING,"$tmp/fields.deb");
           while (<LISTING>) {
            if ($_ !~ /drwx/) {
               print;
            }         
           }
         }
     } 
     if (($commands->{"l"} && $commands->{"v"} && $commands->{"d"}) ||
          $commands->{"d"} && $commands->{"v"}) {
         if ( $dpkg_deb) {
          system "$dpkg_deb --contents $argument > $tmp/fields.deb";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\
                   $tar tOzv 2> $tmp/fields.deb";
         }
         open(LISTING,"$tmp/fields.deb");
           while (<LISTING>) {
            if (m,usr\/man|usr\/doc|usr\/info, && $_ !~ /drwx/) {
               print;
            }         
           }
     }

     # These next two print out a short listing
     if (($commands->{"l"} && !$commands->{"v"}) && !$commands->{"d"}) {
        if ($commands->{"df"}) {
         if ( $dpkg_deb) {
          system "$dpkg_deb --fsys-tarfile $argument | $tar t";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\ 
                  $tar tOz 2> $tmp/fields.deb; \
                  $cat $tmp/fields.deb";
         }
        }
        elsif (!$commands->{"df"}) {
         if ( $dpkg_deb) {
          system "$dpkg_deb --fsys-tarfile $argument |\ 
                  $tar t > $tmp/fields.deb";
          system "$dpkg_deb --fsys-tarfile $argument |\ 
                  $tar tv > $tmp/temp.deb";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\ 
                  $tar tOz 2> $tmp/fields.deb";
          system "$ar -p $argument data.tar.gz |\ 
                  $tar tOzv 2> $tmp/temp.deb";
         }
         open(LISTING,"$tmp/fields.deb");
         open(TEMP,"$tmp/temp.deb");           
           my(@list,@temp);
           @list = <LISTING>;
           @temp = <TEMP>;
           my $count = 0;
           foreach (@temp) {
            chomp $list[$count];
            print "$list[$count]\n" if $_ !~ /drwx/;
            $count++;
           }
         }
     } 
     if (($commands->{"l"} && !$commands->{"v"} && $commands->{"d"}) ||
          $commands->{"d"} && !$commands->{"v"}) {
         if ( $dpkg_deb) { 
          system "$dpkg_deb --fsys-tarfile $argument |\ 
                  $tar t > $tmp/fields.deb";
          system "$dpkg_deb --fsys-tarfile $argument |\ 
                  $tar tv > $tmp/temp.deb";
         }
         elsif ( $ar) {
          system "$ar -p $argument data.tar.gz |\ 
                  $tar tOz 2> $tmp/fields.deb";
          system "$ar -p $argument data.tar.gz |\ 
                  $tar tOzv 2> $tmp/temp.deb";
         }         
         open(LISTING,"$tmp/fields.deb");
         open(TEMP,"$tmp/temp.deb");           
           my(@list,@temp);
           @list = <LISTING>;
           @temp = <TEMP>;
           my $count = 0;
           foreach (@temp) {
            chomp $list[$count];
            # the directory check assumes such a directory already exists
            if (m,usr\/man|usr\/share\/man|usr\/doc|usr\/share\/doc|usr\/info|usr\/share\/info,) {
                print "$list[$count]\n" if $_ !~ /drwx/;
            }         
           $count++;
           }
     }


} # end sub listing


# Just to save some room, and handle -T, there is no error returned when a
# field isn't found, so this sub will have to check things out itself.
sub deps {

  my ($commands) = @_; my %commands = %$commands;

        # will print out the .deb part
        $argument =~ m,.*\/(.*$),;
        my %title;

           if (!$commands->{"T"}) {
              if ($commands->{"pre_depends"}) {
                if (! defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Pre-Depends: ";
                 system "$dpkg_deb -f $argument Pre-Depends";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Pre-Depends: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"depends"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Depends: ";
                 system "$dpkg_deb -f $argument Depends";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Depends: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"recommends"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Recommends: ";
                 system "$dpkg_deb -f $argument Recommends";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Recommends: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"suggests"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Suggests: ";
                 system "$dpkg_deb -f $argument Suggests";
                } 
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Suggests: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"provides"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Provides: ";
                 system "$dpkg_deb -f $argument Provides";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Provides: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"replaces"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Replaces: ";
                 system "$dpkg_deb -f $argument Replaces";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Replaces: \w*\"";
                }
                print "\n";
              }
              if ($commands->{"conflicts"}) {
                if (!defined $title{$1}) {
                  print "$1\n";
                }
                $title{$1}++; 
                if ( $dpkg_deb) {
                 print "Conflicts: ";
                 system "$dpkg_deb -f $argument Conflicts";
                }
                elsif ( $ar) {
                 system "$ar -p $argument control.tar.gz |\ 
                         $tar xOz control | $grep \"Conflicts: \w*\"";
                }
                print "\n";
              }
           }
           elsif ($commands->{"T"}) {
        if ( $dpkg_deb) { 
          system "$dpkg_deb -f $argument Pre-Depends 2&> $tmp/fields.deb";
          system "$dpkg_deb -f $argument Depends  2&> $tmp/temp.deb; \ 
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Recommends 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Suggests 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Provides 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Replaces 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Conflicts 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
        }
        elsif ( $ar) {
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Pre-Depends: \w*\" > $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Depends: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Recommends: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Suggests: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Provides: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Replaces: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Conflicts: \w*\" >> $tmp/fields.deb";
        }


          if (-e "$tmp/fields.deb") {
           open (DEPS, "$tmp/fields.deb");
            if (!$commands->{"i"}) {
              print "$1\n";
            }
            while (<DEPS>) {
               print;
            }
          } 
          close(DEPS);
          unlink("$tmp/fields.deb");
          } # elsif T
  
} # end sub deps


# This takes out the pertinent fields and puts them into the PRETTY format.
# There are more shell calls then one would like..but that's the way it
# goes.  An easier way would be to have a extensive available file
# produced from a Packages file, this provides package md5sum.
# This also provides status and section when -f doesn't provide it, and
# already has the right order.
sub shbang {

         # just one call needed here
         if ( $dpkg_deb) {
          system "$dpkg_deb -f $argument Package 2&> $tmp/fields.deb";
          system "$dpkg_deb -f $argument Essential 2&> $tmp/temp.deb; \   
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Priority 2&> $tmp/temp.deb; \           
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Section 2&> $tmp/temp.deb; \            
                  $cat $tmp/temp.deb >> $tmp/fields.deb;";            
          system "$dpkg_deb -f $argument Installed-Size 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb";            
          system "$dpkg_deb -f $argument Maintainer 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb";            
          system "$dpkg_deb -f $argument Source 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb";            
          system "$dpkg_deb -f $argument Version 2&> $tmp/temp.deb; \
                  $cat $tmp/temp.deb >> $tmp/fields.deb";            
         }
         elsif ( $ar) {
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Package: \w*\" > $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Essential: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Priority: \w*\" >> $tmp/fields.deb"; 
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Section: \w*\" >> $tmp/fields.deb"; 
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Installed-Size: \w*\" >> $tmp/fields.deb";
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Maintainer: \w*\" >> $tmp/fields.deb"; 
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Source: \w*\" >> $tmp/fields.deb"; 
          system "$ar -p $argument control.tar.gz | $tar xOz control |\
                  $grep \"Version: \w*\" >> $tmp/fields.deb"; 
         }
} # end sub shbang


# This processes fields from individual Debian packages
sub package_processor {

  my ($commands) = @_;
  my %commands = %$commands;
  my $count = 0;
  my @package;
  my $status;
  my @essential;
  my $priority; 
  my $section; 
  my $installed_size; 
  my $maintainer; 
  my $source;

  my $format_deb = "$tmp/format.deb";
  my $fields = "$tmp/fields.deb";

    $~ = "PRETTY";
    #open(PRETTY, ">$format_deb");
    open(AVAIL, "$fields");
      while (<AVAIL>) {
      # here's the difference with database(\%commands), we just find the packages
      # which belong to the hash %exacts
       # Package name
        if (/^Package:|^PACKAGE:/) {                                              
          @package = split(/: /,$_);                                                  
          chomp $package[1];
        } 
        # no Status: yet
        elsif (/^Essential/) {
           @essential = split(/: /,$_);                                                  
        }
        elsif (/^Priority:/) {
            $priority = $_;
        }
        elsif (/^Section:/) {
            $section = $_;
        }
        elsif (/^Installed-Size:/) {
            $installed_size = $_;
        }
        elsif (/^Maintainer:/) {
            $maintainer = $_;
        }
        elsif (/^Source:/) {
            $source = $_;
        }
        # hold ok not-installed - may want to change this just to
        # non-installed.
        elsif (/^Version:/) {            
            my $version = $_;
            my ($same, $different);
            my ($vname, $gname, $priorname, $statusname);
            chomp $version;
            if ( $section) {
              chomp $section;
            }
            $col1 = "Package: $package[1]";
            # to be made pc, we need to look in sb(\%commands) or nsb(\%commands).
            sb(\%commands);    
            $argument =~ m,.*\/(.*)_[\d\+\.].*$,;
            my $pname = $1;

            ############### 
            # STATUSINDEX #
            ###############
            # if statusindex is around we will check here, and in
            # nstatus* if the version is different, or the information
            # is unavailable. 
            if ( $pname) { 
            if (defined $sb{$pname}) {
              ($vname,$gname,$priorname,$statusname) = 
              split(/\s/,"$sb{$pname}",4);
              $statusname =~ s/:/ /g;
              # a way to test
              #$version = "Version: 1:5.0-2";              
              my $pver = substr($version,9);
              my $cname = $pname . "_" . $pver;
              if ($vname eq $cname) {
               $status = "Status: $statusname\n";
               $same = "yes"; undef($different);
              }
              else {
               # here's where we get to do some comparisons
               # we will have to compare sections. 1). may have changed
               # 2). may be an unfair comparison free vs non-free, on the
               # other-hand this should be in the person's awareness
               # making the check.  1) will provide the answer to both.  
               $vname =~ m,^.*_(.*)$,;
               my $ever = $1;
               $status = 
               "Status: " . comparison($pver,$ever) . " $statusname ($ever)\n";
               $different = "yes"; undef($same);  
              }
            }
            else {
              $status = "Status: not-installed\n";
            }
            }
            $col2 = $status;
            write STDOUT;
            $col1 = $version;
            my $ver = m,Version:\s(.*),;         
            my $verzion = $1;
            $package[1] = "$package[1]_$1";
            if(defined($essential[1])) {              
             $col2 = "Essential: $essential[1]";
             @essential = (\%commands);
            }
            else {
              $col2 = "Essential: no\n";
            }
            write STDOUT;
            # We will try to fill things in for Section: and Priority:
            if ( $section) {  
             $col1 = $section;
            }
            else {
              if ( $same) {
                if ($gname eq "unavailable") {
                   nsb(\%commands);
                   if (defined $nsb{$pname}) {
                    my ($nvname,$ngname,$npriorname) =
                    split(/\s/,"$nsb{$pname}",3);
                    $col1 = "Section: $ngname";
                   }
                }
                else {
                   $col1 = "Section: $gname";
                }
              }
              elsif ( $different) {
               # look first in available, and next in a specified Packages
               # file, we will also compare this to the existing Section, 
               # because this is known to change.
                nsb(\%commands);
                if (defined $nsb{$pname}) {
                  my ($nvname,$ngname,$npriorname) =
                  split(/\s/,"$nsb{$pname}",3);
                  $col1 = "Section: $ngname";
                }
                else {
                    $col1 = "Section: unavailable";       
                }
              }  
              else {
              # This may be in available or Packages
                nsb(\%commands);
              if ( $pname) {
              if (defined $nsb{$pname}) {
                my ($nvname,$ngname,$npriorname) =
                split(/\s/,"$nsb{$pname}",3);
                $col1 = "Section: $ngname";
              }
              else {
                $col1 = "Section: unknown";
              } 
              }
             }
            } 
            if ( $priority) {  
              $col2 = $priority;             
            }
            else {
              if ( $same ) {
                if ($gname eq "unavailable") {
                   nsb(\%commands);
                   if (defined $nsb{$pname}) {
                    my ($nvname,$ngname,$npriorname) =
                    split(/\s/,"$nsb{$pname}",3);
                    $col2 = "Priority: $npriorname";
                   }
                }
                else {
                    $col2 = "Priority: $priorname\n";
                }
              }
              elsif ( $different) {
               # look first in available, and next in a specified Packages
               # file
                nsb(\%commands);
                if (defined $nsb{$pname}) {
                  my ($nvname,$ngname,$npriorname) =
                  split(/\s/,"$nsb{$pname}",3);
                  $col2 = "Priority: $npriorname";
                }
                else {
                  $col2 = "Priority: unavailable\n";
                }
              }  
              else {
               # This is not in available or Packages
               nsb(\%commands);
               if ( $pname) {
               if (defined $nsb{$pname}) {
                 my ($nvname,$ngname,$npriorname) =
                 split(/\s/,"$nsb{$pname}",3);
                 $col2 = "Priority: $npriorname";
               }
               else {
                $col2 = "Priority: unknown\n";
               }
               }
              }
 
            } 
            write STDOUT;
            #my $cool = $installed_size . $maintainer;
            $col1 = $installed_size;
            if ( $source) {
              $col2 = $source;
            }
            else {
              $col2 = "";
            } 
            write STDOUT;
            undef $source;
            print STDOUT $maintainer;
        }
      } # end while AVAIL
      close(PRETTY);

   unlink($format_deb);

} # end sub package_processor


1;

