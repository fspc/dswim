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


package SWIM::DB_Library;
use strict;  
use SWIM::Conf;
use SWIM::Global;
use SWIM::Library;
use DB_File;
use vars qw(@ISA @EXPORT %EXPORT_TAGS);
  
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ib nib dbi ndb sb exist_sb nsb ping zing nzing ging gb
             ngb sing ram_on version ver nver nping nzing nging nsing);
%EXPORT_TAGS = ( 
                 Search =>  [ qw(ib dbi nib nsb ndb gb ram_on version ngb) ],
                 Db => [ qw(sb ib gb nsb ver dbi zing ging ping sing) ],
                 Md => [ qw(sb ib nsb nzing) ],
                 Deb => [ qw(sb nsb ndb) ],
                 NDb => [ qw(ndb nsb ngb nver nping nzing nging nsing
                          exist_sb sb) ],
                 Groups => [ qw(gb ngb) ],
                 Xyz => [ qw(dbi ndb) ]
               );


# functions which use DB_File


sub ib {

  my ($commands) = @_;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
   if (-e "$main::home$parent$library/fileindex.deb") {
     tie %ib, 'DB_File', "$main::home$parent$library/fileindex.deb" or die "DB_File: $!";
   }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
   if (-e "$main::home$parent$base/fileindex.deb") {
    tie %ib, 'DB_File', "$main::home$parent$base/fileindex.deb" or die "DB_File: $!";
   }
  }
} # end sub ib

sub dbi {

  my ($commands) = @_;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
   if (-e "$main::home$parent$library/packages.deb" ||
      ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
     tie %db, 'DB_File', "$main::home$parent$library/packages.deb" or die "DB_File: $!";
   }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
   if (-e  "$main::home$parent$base/packages.deb" ||
       ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
    tie %db, 'DB_File', "$main::home$parent$base/packages.deb" or die "DB_File: $!";
   }
  }
} # end sub dbi



sub nib {

  my ($commands) = @_;
  my %commands = %$commands;
  
  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     if (!-e "$main::home$parent$library/nfileindex$arch$dist.deb") {
       return;
     }
     tie %ib, 'DB_File', "$main::home$parent$library/nfileindex$arch$dist.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     if (!-e "$main::home$parent$base/nfileindex$arch$dist.deb") {
       return;
     }
    tie %ib, 'DB_File', "$main::home$parent$base/nfileindex$arch$dist.deb" or die "DB_File: $!";
  }
} # end sub nib


sub ndb {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
    if (-e "$main::home$parent$library/npackages$arch$dist.deb" ||
        ($commands->{"initndb"} || $commands->{"rebuildndb"} ||
         $commands->{"ndb"})) {
     tie %db, 'DB_File', "$main::home$parent$library/npackages$arch$dist.deb" 
     or die "swim: use pre-existing databases for this option";
    }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
   if (-e  "$main::home$parent$base/npackages$arch$dist.deb" ||
      ($commands->{"initndb"} || $commands->{"rebuildndb"} ||
       $commands->{"ndb"})) {
     tie %db, 'DB_File', "$main::home$parent$base/npackages$arch$dist.deb" 
     or die "swim: use pre-existing databases for this option";
   }
  }
} # end sub ndb


sub sb {

  my ($commands) = @_;
  my %commands = %$commands;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     if (-e "$main::home$parent$library/statusindex.deb") {
      tie %sb, 'DB_File', "$main::home$parent$library/statusindex.deb" 
      or die "DB_File: $!";
     }
     else {
      return;
    }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    if (-e "$main::home$parent$base/statusindex.deb") {
     tie %sb, 'DB_File', "$main::home$parent$base/statusindex.deb" 
     or die "DB_File: $!";
    }
    else {
     return;
    } 
  }
} # end sub sb

# exist_sb & sb seem to be used primarily in NDB_Init

# This first looks in the immediate directory for statusindex.deb, if it
# isn't found here, it look in the default directory.  It then returns
# undef, or initializes the database based on its findings.
sub exist_sb {

  my ($commands) = @_;
  my %commands = %$commands;

  my $yep; 
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     if (-e "$main::home$parent$library/statusindex.deb") {
         $yep = "yes";
     }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     if (-e "$main::home$parent$base/statusindex.deb") {
         $yep = "yes";
     }
  }

  if (!defined $yep) {
    if (-e "$main::home$parent$base/statusindex.deb") {
     tie %sb, 'DB_File', "$main::home$parent$base/statusindex.deb" 
      or die "DB_File: $!";
      return "yes";
    }
    else {
      return;
    }
  }
  elsif (defined $yep) {
      sb(\%commands);             
      return "yes";
  }

} # end sub exist_sb

sub nsb {

  my ($commands) = @_;
  my %commands = %$commands;

  my($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
    if (-e "$main::home$parent$library/nstatusindex$arch$dist.deb" ||
        ($commands->{"initndb"} || $commands->{"rebuildndb"} ||
         $commands->{"ndb"})) {
     tie %nsb, 'DB_File', "$main::home$parent$library/nstatusindex$arch$dist.deb"
     or die "swim: use pre-existing databases for this option";
    }
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
   if (-e "$main::home$parent$base/nstatusindex$arch$dist.deb" ||
        ($commands->{"initndb"} || $commands->{"rebuildndb"} ||
         $commands->{"ndb"})) {
    tie %nsb, 'DB_File', "$main::home$parent$base/nstatusindex$arch$dist.deb" or die
     or die "swim: use pre-existing databases for this option";
   }
  }
} # end sub nsb

sub ping {

  my ($commands) = @_;

      if (($commands->{"dbpath"} && $commands->{"root"}) ||
         ($commands->{"dbpath"} && !$commands->{"root"}) ||
         (!$commands->{"dbpath"} && !$commands->{"root"})) {
         $ping = tie %db, 'DB_File', "$main::home$parent$library/packages.deb" or die "DB_File: $!";
      }
      elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
         $ping = tie %db, 'DB_File', "$main::home$parent$base/packages.deb" or die "DB_File: $!";
      }
}

sub nping {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $ping = tie %db, 'DB_File', "$main::home$parent$library/npackages$arch$dist.deb"
               or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $ping = tie %db, 'DB_File', "$main::home$parent$base/npackages$arch$dist.deb" 
             or die "DB_File: $!";
  }
} # end sub nping


sub zing {

  my ($commands) = @_;

      if (($commands->{"dbpath"} && $commands->{"root"}) ||
         ($commands->{"dbpath"} && !$commands->{"root"}) ||
         (!$commands->{"dbpath"} && !$commands->{"root"})) {
         $zing = tie %ib, 'DB_File', "$main::home$parent$library/fileindex.deb" 
                 or die "DB_File: $!";
      }
      elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
         $zing = tie %ib, 'DB_File', "$main::home$parent$base/fileindex.deb" 
                 or die "DB_File: $!";
      }
} # end sub zing

sub nzing {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $zing = tie %ib, 'DB_File', "$main::home$parent$library/nfileindex$arch$dist.deb"
               or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $zing = tie %ib, 'DB_File', "$main::home$parent$base/nfileindex$arch$dist.deb" 
             or die "DB_File: $!";
  }
} # end sub nzing


sub ging {

  my ($commands) = @_;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $ging = tie %gb, 'DB_File', "$main::home$parent$library/groupindex.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $ging = tie %gb, 'DB_File', "$main::home$parent$base/groupindex.deb" or die "DB_File: $!";
  }
} #end sub ging


sub nging {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $ging = tie %gb, 'DB_File',"$main::home$parent$library/ngroupindex$arch$dist.deb"
               or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $ging = tie %gb, 'DB_File', "$main::home$parent$base/ngroupindex$arch$dist.deb" 
             or die "DB_File: $!";
  }
} # end sub nging


sub gb {

  my ($commands) = @_;

      if (($commands->{"dbpath"} && $commands->{"root"}) ||
         ($commands->{"dbpath"} && !$commands->{"root"}) ||
         (!$commands->{"dbpath"} && !$commands->{"root"})) {
         if (-e  "$main::home$parent$library/groupindex.deb" ||
            ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
          tie %gb, 'DB_File', "$main::home$parent$library/groupindex.deb" or die "DB_File: $!";
         }
      }
      elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
         if (-e "$main::home$parent$base/groupindex.deb" ||
            ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
          tie %gb, 'DB_File', "$main::home$parent$base/groupindex.deb" or die "DB_File: $!";
         }
      }
}

sub ngb {

  my ($commands) = @_;
  my %commands = %$commands;

    my ($arch,$dist) = which_archdist(\%commands);
      if (($commands->{"dbpath"} && $commands->{"root"}) ||
         ($commands->{"dbpath"} && !$commands->{"root"}) ||
         (!$commands->{"dbpath"} && !$commands->{"root"})) {
        if (-e "$main::home$parent$library/ngroupindex$arch$dist.deb" ||
           ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
          tie %gb, 'DB_File', "$main::home$parent$library/ngroupindex$arch$dist.deb" 
          or die "DB_File: $!";
        }
      }
      elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
        if (-e "$main::home$parent$base/ngroupindex$arch$dist.deb" ||
           ($commands->{"initndb"} || $commands->{"rebuildndb"})) {
          tie %gb, 'DB_File', "$main::home$parent$base/ngroupindex$arch$dist.deb" 
          or die "DB_File: $!";
        }
      }
}

sub sing {

  my ($commands) = @_;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
       $sing =  tie %sb, 'DB_File', "$main::home$parent$library/statusindex.deb" 
       or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
       $sing = tie %sb, 'DB_File', "$main::home$parent$base/statusindex.deb" or die "DB_File: $!";
  }
} # sub sing

sub nsing {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($arch,$dist) = which_archdist(\%commands);
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $sing = tie %nsb, 'DB_File', "$main::home$parent$library/nstatusindex$arch$dist.deb"
               or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    $sing = tie %nsb, 'DB_File', "$main::home$parent$base/nstatusindex$arch$dist.deb" 
             or die "DB_File: $!";
  }
} # end sub nsing


# This doesn't depend on DB so it can be placed somewhere else if it is used by more
# than SWIM::Search.

# checks to see if ramdisk is on, searchdf() & nfile()-process_nfile()
# (used by file()) uses this
sub ram_on {

   my $ramdisk;

   # this monster runs for every argument
   my  $rambo =  "$cat /proc/mounts|";
   open(RAM, "$rambo"); 
    while (<RAM>) {
      if (/ram/) {
        my($device,$mount) = split(/\s/,$_,2);
          if ($mount =~ /dramdisk/) {
           $ramdisk = "yes";
           return $ramdisk;
          }
      }
    }
    close(RAM);
} # end sub ram_on



# finds package name and version
sub version {
 
  my ($commands) = @_;
  my %commands = %$commands;

  if (!$commands{"n"}) {
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
  }

} # end sub version
# returns version but and then is untied
sub ver {

  my ($commands) = @_;
  my %commands = %$commands;
  dbi(\%commands);

  if (defined $argument) {
     # We will check for more than two..just in case
     if ($argument !~ /_/) {
       if (defined $db{$argument}) {
         $argument = $db{$argument};
       }
     }
  }

  untie %db;

} # end sub ver

sub nver {

  my ($commands) = @_;
  my %commands = %$commands;
  ndb(\%commands);

  if (defined $argument) {
     # We will check for more than two..just in case
     if ($argument !~ /_/) {
       if (defined $db{$argument}) {
         $argument = $db{$argument};
       }
     }
  }

  untie %db;

} # end sub nver

