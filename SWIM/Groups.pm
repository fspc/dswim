#    Debian System Wide Information Manager
#    Copyright (C) 1999-2001 Jonathan Rosenbaum

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


package SWIM::Groups;
use strict;
use SWIM::DB_Library qw(:Groups);
use SWIM::Format;
use SWIM::Global qw(%gb);
use vars qw(@ISA @EXPORT);   
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(allgroups);


# show all the groups present on this system and exit
sub allgroups {

    my ($commands) = @_;
    my %commands = %$commands; 

    if (!($commands->{"q"} || $commands->{"query"}) && $commands->{"allgroups"}) {
       print "swim: --allgroups may only be used during queries\n";
       exit;
    }
    if ($commands->{"q"} && $commands->{"allgroups"}) {
      $~ = "ALLGROUPS";

     if (!$commands->{"n"}) {
        gb(\%commands);
     }
     else {
        ngb(\%commands);
     }
 
      my @complete = sort keys %gb;
      my $three = 0;
      while ($three <= $#complete) {
        if (defined $complete[$three]) {
          $ag1 = $complete[$three];
        }
        if (defined $complete[$three + 1]) {
          $ag2 = $complete[$three + 1];
        }
        if (defined $complete[$three + 2]) {
          $ag3 = $complete[$three + 2];
        }        
       write STDOUT;
       $ag1 = "";
       $ag2 = "";
       $ag3 = "";
       $three = $three + 3; 
      }
    exit;
    }
}


1;
