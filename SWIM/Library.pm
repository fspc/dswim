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


package SWIM::Library;
use strict;
use SWIM::Conf;
use SWIM::Global;
use vars qw(@ISA @EXPORT);
   
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(which_archdist finddb root compress_contents);


# functions which do not use DB_File  which_archdist() finddb() root()

# which archictecture and distribution does this database involve
sub which_archdist {

  my ($commands) = @_;

     my ($arch,$dist);
     #if ($commands->{"initndb"} || $commands->{"rebuildndb"}) {
      if ($commands->{"arch"}) {
        $arch = "-" . $commands->{"arch"};
      }
      else {
        $arch = "-$architecture";
      }
 
      if ($commands->{"dists"}) {
        $dist = "-" . $commands->{"dists"};
      }
      else {
        $dist = "-$distribution";
      }
     return ($arch,$dist);
    # } 

} # end sub which_archdist


# finding any database
sub finddb {

  my ($commands) = @_;

  my $fileplace;
 
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
    $fileplace = "$parent$library";
    return $fileplace;
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $fileplace = "$parent$base";
    return $fileplace;
  }

} # end sub finddb

# This gives the option to be able to used -d & -l, but not -f, by only
# copying Contents over to contentsindex*.deb.gz.  This the fast way.
sub compress_contents {
 
  my ($Contents,$commands) = @_;
  my %commands = %$commands;
  my $contentsdb = finddb(\%commands);
  my($arch,$dist) = which_archdist(\%commands);
  my $contentsindex = "$contentsdb/ncontentsindex$arch$dist.deb";
  my ($contentsindexgz, $mtime);
  if (-e "$contentsdb/ncontentsindex$arch$dist.deb.gz") {
   $contentsindexgz = "$contentsdb/ncontentsindex$arch$dist.deb.gz";
   $mtime = (stat("$contentsindexgz"))[9];
  }
  else {
      $contentsindexgz = "$contentsdb/ncontentsindex$arch$dist.deb.gz";
  }

  my $ex;
  my $Contents_mtime = (stat("$Contents"))[9];
  my $BContents = $Contents;
  $Contents = -B $Contents || $Contents =~ m,\.(gz|Z)$, ? 
               "$gzip -dc $Contents|" : "cat $Contents|";
  if (defined $mtime) {  
   if ($mtime == $Contents_mtime) {
     print "Same Contents files, won't compress\n";
     exit if !$commands->{"ndb"};
     $ex = "stop";
   }
   else {
      unlink($contentsindexgz);
   }
  }
  if (!defined $ex) {
    print "Copying new Contents\n";
    #system $copy, $BContents, $contentsindexgz;

    # changed for >= 0.2.9
    # changed again >= 0.3.4   
    open(CONTENTS, "$Contents") or die "where is it?\n";
    open(CONTENTSDB,">$contentsindex");
    while (<CONTENTS>) {                                                        
       ##if (/^FILE\s*LOCATION$/) {                                           
          ##while (<CONTENTS>) {                                               
             s,^(\./)+,,;  # filter for Debians altered dir structure
             print CONTENTSDB $_;
          ##}
       ##} 
    }
   print "Compressing Contents\n";                                            
   # added -f just in case
   system "$gzip", "-f", "-9", "$contentsindex";
   utime(time,$Contents_mtime,$contentsindexgz); 
  }

} # end sub compress_contents

# for / files 
sub root {

      if ($argument eq "/") {
          $argument = "/.";
       } 
} # end sub root


1;
