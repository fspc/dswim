#    Debian System Wide Information Manager
#    Copyright (C) 1998-2005 Jonathan Rosenbaum

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


package SWIM::Dir;
use strict;
use SWIM::Global qw($argument);
use SWIM::Conf qw($pwd);
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(dir fir);

# dir() fir()

# When --dir is used checks argument (when -f is called) and determines dir
# stuff..is it real or not.
sub dir {

   my ($commands) = @_;

   if ($commands->{"dir"}) {
      if (! -d $argument) {
        if (! -e $argument) {
          print "$argument is not a directory or file\n";
        }
        else {
          print "$argument is not a directory\n";
        }
        exit;
      }
    elsif ($argument =~ m,\/$,) {
      if ($argument !~ m,^\/,) {
        if ($pwd =~ m,^\/$,) {
          $argument =~ m,(.*)\/$,;
          $argument = "$pwd$1";
        }
        else {
          $argument =~ m,(.*)\/$,;
          $argument = "$pwd/$1";
        }
      }
      else {
        $argument =~ m,(.*)\/$,;
        $argument = $1;
      }
    }
    elsif ($argument !~ m,\/$|^\/, && $argument =~ m,\/,) {
        if ($pwd =~ m,^\/$,) {
          $argument = "/$argument";
        }       
        else {
          $argument = "$pwd/$argument";
        }
    }
   }
} # end sub dir

# when --dir isn't called...does the same thing as dir.
sub fir {
    
    my ($commands) = @_;

    if ($argument =~ m,\/$,) {
      # Let's test to see whether it really is a file or directory.
           if (! -d $argument) {
            print "$argument is not a file\n";
            exit;
           }
      if ($argument !~ m,^\/,) {
        if ($pwd =~ m,^\/$,) {
          $argument =~ m,(.*)\/$,;
          $argument = "$pwd$1";          
        }
        else {          
          $argument =~ m,(.*)\/$,;
          $argument = "$pwd/$1";
        }
      }
      else {
        $argument =~ m,(.*)\/$,;
        $argument = $1;
      }
    }
    elsif ($argument !~ m,\/$|^\/, && $argument =~ m,\/,) {
        if ($pwd =~ m,^\/$,) {
          $argument = "/$argument";
        }
        else { 
          $argument = "$pwd/$argument";
       }
    }
} # end sub fir

1;

