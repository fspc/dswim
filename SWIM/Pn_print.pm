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


package SWIM::Pn_print;
use strict;
use SWIM::Global qw($argument);
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(singular);


# There are times when it is good to print out the "package name_version"
# and there are times when it is unecessary.  This sub tries to resolve
# these situations, basically it's printme()
sub singular {

  my ($commands) = @_;
  my %commands = %$commands;

  # for files, dirs, or groups
  if (($commands->{"f"} || $commands->{"dir"} ||  $commands->{"g"} || 
      $commands->{"q"}) && 
      !($commands->{"i"} || $commands->{"l"} ||
      $commands->{"df"} || $commands->{"d"} || $commands->{"c"} ||
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"} || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
        print "$argument\n";
  }
  elsif (($commands->{"f"}  || $commands->{"dir"} ||  $commands->{"g"} ||
      $commands->{"q"}) && 
      $commands {"c"} && !($commands->{"i"} || 
      $commands->{"df"} || $commands->{"d"} || $commands->{"l"} ||
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} &&
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
        print "$argument\n";
  }
  elsif (($commands->{"f"}  || $commands->{"dir"} || $commands->{"g"} ||
      $commands->{"q"}) && 
      $commands {"c"} && $commands->{"d"} &&
      !($commands->{"i"} || $commands->{"df"} || $commands->{"l"} || 
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
        print "$argument\n";
  }
  elsif (($commands->{"f"}  || $commands->{"dir"} ||  $commands->{"g"} ||
      $commands->{"q"}) && 
      $commands {"c"} && ($commands->{"d"} ||
      $commands->{"l"}) && !($commands->{"i"} || $commands->{"df"} || 
      $commands->{"scripts"} || $commands->{"preinst"} || $commands->{"postinst"} || 
      $commands->{"prerm"} || $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"} || $commands->{"T"} ||
      $commands->{"pre_depends"} || $commands->{"depends"} || 
      $commands->{"recommends"} || $commands->{"suggests"} ||
      $commands->{"provides"} || $commands->{"replaces"} ||
      $commands->{"conflicts"} || $commands->{"requires"} ||
      $commands->{"changelog"}  || $commands->{"m"} || $commands->{"menu"} ||
      $commands->{"copyright"})) {
        print "$argument\n";
  }

} # end sub singular


1;
