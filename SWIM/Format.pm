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


package SWIM::Format;
use vars qw(@ISA @EXPORT);             

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(*PRETTY *ALLGROUPS *SUBJECT *CENTER *SDS $col1 $col2 $ag1
           $ag2 $ag3 $number $subsite $subdate $subsize $subrelease
           $center $number $sdsite $sdsdate $sdsize $sdsrelease);


# A nice format to make things look prettier, hopefully.
format PRETTY =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$col1, $col2
.

# A format for --allgroups, shouldn't run out of room.
format ALLGROUPS  =
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<  
$ag1,                     $ag2,                     $ag3 
.

# center for DF|APT call
format SUBJECT =
@||         @|||                     @|||              @|||||||||||  @||||||
$number,    $subsite,                $subdate,         $subsize, $subrelease

.


format CENTER =
                             @|||||||||||||||||||||||
                                 $center
.


format SDS =
@>> @||||||||||||||||||||| @||||||||||||||||||||||||||| @||||||||    @|||||
$number,       $sdsite,           $sdsdate,              $sdsize,  $sdsrelease
.



1;
