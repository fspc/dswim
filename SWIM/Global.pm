#    Debian System Wide Information Manager
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


package SWIM::Global;
use vars qw(@ISA @EXPORT %EXPORT_TAGS);
  
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(%db $ping %ndb %ib $zing %gb $ging %sb $sing %nsb %commands
             $argument $save @stuff @PACKAGES @arg_holder $file_now
             $arg_count $aptor_count $aptor_group $main::home);
%EXPORT_TAGS = (
                 Info =>  [ qw($argument %db) ]
               );

=pod

Globals used by all program, which are not related to SWIM::Conf globals.
Most will probably be placed in SWIM::DB_Library.

=cut
# Nothing to be done here.
# these could be put into SWIM::DB_Library
my (%db,$ping); # package.deb
my %ndb;        # npackage.deb 
my (%ib, $zing, %it); # fileindex.deb
my (%gb, $ging); # groupindex.deb
my (%sb, $sing); # statusindex.deb
my %nsb;         # nstatusindex.deb
my %commands; # standard for Getopt::Long, but should usually 
              # be passed from ::*, although it can be global to a module
my $argument; # standard for package name
my $save; #for pager

# Globals related to -xyz
my @stuff; # for -g & x
my @PACKAGES;  # a replacement for @ARGV
my @arg_holder; # helps in tricky situations -> -qxl|d
my $file_now;   # defined flag for -qlcx & -qglx for file()  
$arg_count = 0; # helps in tricky situations
my $aptor_group; # helps when -z is called for groups

1;
