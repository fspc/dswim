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


package SWIM::Ag;
use strict;
use SWIM::Global qw(:Info $file_now);   
use SWIM::DB_Library qw(:Xyz);
use SWIM::Info;
use SWIM::Pn_print;
use SWIM::Deps;
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(description q_description);


# stuff to query package names, -a, and groups

# -qi <packages name>  Anotherwards that big thing of info...also
# -c, -l
sub description {

  my ($commands) = @_;
  my %commands = %$commands;

  if ($commands->{"scripts"} || $commands->{"preinst"} ||
      $commands->{"postinst"} || $commands->{"prerm"} ||
      $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}) {
       scripts(\%commands);
  }
  menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
  copyright(\%commands) if $commands->{"copyright"}; 
  changelog(\%commands) if $commands->{"changelog"}; 
 
  if (!$commands->{"n"}) {
   dbi(\%commands);
  }
  else {
   ndb(\%commands);
  }


  if (defined $argument) {
     # We will check for more than two..just in case
     if ($argument !~ /_/) {
       if (defined $db{$argument}) {
         $argument = $db{$argument};
       }
     }
    if ($db{"$argument"}){
       my $package = $db{"$argument"};
       print $package;
    }
      else { 
        print "package $argument is not installed\n"; 
        exit;
      }
  }
  untie %db;


    character(\%commands);
    shlibs(\%commands) if $commands->{"shlibs"};
  
    if ($commands->{"c"} && !($commands->{"l"} || $commands->{"d"})) {
        if (conf(\%commands) ne 0) {
         print conf(\%commands) if !$commands->{"md5sum"};
         # here for a reason
         # if -i because calls from qindexer.
         if ($commands->{"i"}) {
           require SWIM::File;
           SWIM::File->import(qw(file));
           file(\%commands) 
         }
        }
    } 
    if (($commands->{"c"} && ($commands->{"l"} || $commands->{"d"})) ||
        ($commands->{"l"} || $commands->{"d"})) {
         if ($commands->{"c"} && conf(\%commands) ne 0) {
           print conf(\%commands) if !$commands->{"md5sum"};
         }
         require SWIM::File;
         SWIM::File->import(qw(file));
         file(\%commands);
    }

    if (!($commands->{"z"} || $commands->{"ftp"} ||
                   $commands->{"remove"} || $commands->{"r"} ||
                   $commands->{"purge"} || $commands->{"reinstall"})) {
     if ($commands->{"x"} || $commands->{"ftp"} || $commands->{"source"} ||
       $commands->{"source_only"} || $commands->{"remove"} || 
       $commands->{"r"} || $commands->{"purge"} || $commands->{"reinstall"}) {
           require SWIM::Safex;
           SWIM::Safex->import(qw(safex));
           safex(\%commands);
     }
    }

} # end sub description

# Access Descriptions, and other stuff for known <packages>.
# This includes -ql(d)c, -qc or plain -q (just the package name and
# version).  Anotherwards if -i isn't used this sub is called.  And
# -ql is handled by file.  Mostly, this was designed for calling a single
# package name on the command line without a known package title except
# when -q is called by itself, but using -T is an exception since this is
# useful.
sub q_description {

  my ($commands) = @_;
  my %commands = %$commands;

  if ($commands->{"scripts"} || $commands->{"preinst"} ||
      $commands->{"postinst"} || $commands->{"prerm"} ||
      $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}) {
      scripts(\%commands);
  }
  menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
  copyright(\%commands) if $commands->{"copyright"}; 
  changelog(\%commands) if $commands->{"changelog"}; 


  if (!$commands->{"n"}) {
   dbi(\%commands);
  }
  else {
   ndb(\%commands);
  }


  if (defined $argument) {
     if ($argument !~ /_/) {
       if (defined $db{$argument}) {
         $argument = $db{$argument};
       }
       if ($commands->{"c"} && $commands->{"d"}) {
           require SWIM::File;
           SWIM::File->import(qw(file));
           print "$argument\n" if $commands->{"g"};
           character(\%commands);
           shlibs(\%commands) if $commands->{"shlibs"};
          if (conf(\%commands) ne 0) {
            print conf(\%commands) if !$commands->{"md5sum"};
          } 
          # it's nice to print out -d with -c, so this was added.
          file(\%commands);
        } 
        elsif ($commands->{"c"}) {
          # this produces annoying spaces
          print "$argument\n" if $commands->{"g"} && conf(\%commands) ne 0;
          character(\%commands);
          shlibs(\%commands) if $commands->{"shlibs"};
          if (conf(\%commands) ne 0) {
            print conf(\%commands) if !$commands->{"md5sum"};
            if ($commands->{"md5sum"}) {
             require SWIM::File;
             SWIM::File->import(qw(file));
             file(\%commands);
            }
          } 
        }
        elsif ($db{$argument} && !$commands->{"c"}) { 
           print "$argument\n" if $commands->{"T"} ||
            $commands->{"depends"} || $commands->{"pre_depends"} ||
            $commands->{"recommends"} || $commands->{"suggests"} ||
            $commands->{"conflicts"} || $commands->{"replaces"} ||
            $commands->{"provides"}; 
           singular(\%commands);
           character(\%commands);
           shlibs(\%commands) if $commands->{"shlibs"};
           print "\n" if $commands->{"T"} ||
            $commands->{"depends"} || $commands->{"pre_depends"} ||
            $commands->{"recommends"} || $commands->{"suggests"} ||
            $commands->{"conflicts"} || $commands->{"replaces"} ||
            $commands->{"provides"}; 
        }  
        else { print "package $argument is not installed\n"; }
     }
     elsif ($argument =~ /_/) {
       if ($commands->{"c"} && $commands->{"d"}) {
           print "$argument\n" if $commands->{"g"};
           character(\%commands);
           shlibs(\%commands) if $commands->{"shlibs"};
           print conf(\%commands) if conf(\%commands) ne 0 && !$commands->{"md5sum"};
           require SWIM::File;
           SWIM::File->import(qw(file));
           file(\%commands);
        } 
        elsif ($commands->{"c"}) {
         my $check = conf(\%commands);
         print "$argument\n" if $commands->{"g"} && $check ne 0 ||
                                $commands->{"l"};
         character(\%commands);
         shlibs(\%commands) if $commands->{"shlibs"};
         if (conf(\%commands) ne 0) {
           print conf(\%commands) if !$commands->{"md5sum"};
           require SWIM::File;
           SWIM::File->import(qw(file));
           file(\%commands);
         }
         elsif (conf(\%commands) == 0) {
           require SWIM::File;
           SWIM::File->import(qw(file));
           file(\%commands);
         }
        }
        elsif ($db{$argument} && !$commands->{"c"}) { 
           # watch this
           ##print "$argument\n" if $commands->{"g"};
           print "$argument\n" if $commands->{"T"} || 
            $commands->{"depends"} || $commands->{"pre_depends"} ||
            $commands->{"recommends"} || $commands->{"suggests"} ||
            $commands->{"conflicts"} || $commands->{"replaces"} ||
            $commands->{"provides"}; 
           singular(\%commands);
           character(\%commands);
           shlibs(\%commands) if $commands->{"shlibs"};
           print "\n" if $commands->{"T"} ||
            $commands->{"depends"} || $commands->{"pre_depends"} ||
            $commands->{"recommends"} || $commands->{"suggests"} ||
            $commands->{"conflicts"} || $commands->{"replaces"} ||
            $commands->{"provides"}; 
        }  
        else { print "package $argument is not installed\n"; }
     }

  }
  untie %db;

  if (!defined $file_now && 
              !($commands->{"z"} || $commands->{"ftp"} ||
                   $commands->{"remove"} || $commands->{"r"} ||
                   $commands->{"purge"} || $commands->{"reinstall"})) {
    if ($commands->{"x"} || $commands->{"ftp"} || $commands->{"source"} ||
       $commands->{"source_only"} || $commands->{"remove"} || 
       $commands->{"r"} || $commands->{"purge"} || $commands->{"reinstall"}) {
           require SWIM::Safex;
           SWIM::Safex->import(qw(safex));
           safex(\%commands);
    }
  } 
} # end sub q_description





1;
