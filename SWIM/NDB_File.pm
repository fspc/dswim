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

package SWIM::NDB_File;
use strict;
use SWIM::DB_Library qw(ram_on); # nzing nsb
use SWIM::Library;
use SWIM::Global qw($argument); # %ib $zing %nsb
use SWIM::Conf qw($pwd $tmp);
use SWIM::Dir;
use SWIM::Ramdisk;
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(noram ncontents_exist find_contents remove_add_nfile);

# This program handles updating nfileindex-arch-dists.deb

# This checks if the ramdisk is on, we will want to turn it off, if it is.
sub noram {

   my ($commands) = @_;
   my %commands = %$commands;  
   my $ramdisk = ram_on(\%commands);

  if ($ramdisk eq "yes") {
   my $what = "yes";
   $commands{"ramdiskoff"} = 1; 
   ramdisk(\%commands);
  } # if ramdisk

} # end sub nfile

# This will set-up the argument for ncontents if it can be found.
sub ncontents_exist {

   my ($commands) = @_;
   my %commands = %$commands;
   my $contentsdb = finddb(\%commands);
   my ($arch,$dist) = which_archdist(\%commands);


    if (-e "$contentsdb/ncontentsindex$arch$dist.deb.gz") { 
      if (-e "$contentsdb/ndirindex$arch$dist.deb.gz") {
         unlink("$contentsdb/ndirindex$arch$dist.deb.gz");
      }
      if (-e "$contentsdb/nsearchindex$arch$dist.deb.gz") {
         unlink("$contentsdb/nsearchindex$arch$dist.deb.gz");
      }
     return " $contentsdb/ncontentsindex$arch$dist.deb.gz|"; 
    }
   else {
     return "no";
   }

}  # end sub ncontents_exist

# Find where the new Contents is on the on the command line vs the old
# Contents database (when the FDB argument isn't used).
sub find_contents {

   my ($commands) = @_;
   my %commands = %$commands;

       ############
       # CONTENTS #
       ############
       # Figure out where Contents is
       if ($commands->{"Contents"}) {
        my ($Contents,$FDB);
        for ($commands->{"Contents"}) { 

          ###############
          # SITUATION 0 #
          ###############
          # this doesn't work to well for anything less simple than ../../
          if (m,^\.\./|^\.\.$,) {
           if ($_ !~ m,/[\w-+]+/[\.\$\^\+\?\*\[\]\w-]*$,) {
             my $dd; tr/\/// ? ($dd = tr/\///) : ($dd = 1); 
             my @pwd =  split(m,/,,$pwd);
             s,\.\./,,g;
             my $tpwd = "";
             for (1 .. $#pwd - $dd) {
               $_ == 1  ? ($tpwd = "/$pwd[$_]") 
                        : (x$tpwd = $tpwd . "/$pwd[$_]");
             }
            $_ ne ".." ? ($Contents = "$tpwd/$_") : ($Contents = "$tpwd/");
           }
            dir(\%commands);
            fir(\%commands);
          }

          ###############
          # SITUATION I #
          ###############
          elsif ( m,\/,) {
            $Contents = $_;
              if ($Contents =~ m,^\.\/.*,) {
                  if ($pwd !~ m,^\/$,) {
                    $Contents =~ m,^\.([^\.].*$),;
                    $Contents = "$pwd$1";
                  }
                  else {
                   $Contents =~ m,^\.([^\.].*$),;
                   $Contents = "$1";
                  }
               } 
            dir(\%commands);
            fir(\%commands);
          }

          ################
          # SITUATION II #
          ################
          elsif ($pwd =~ m,^\/$,) {
            $Contents = "/$_";
            dir(\%commands);
            fir(\%commands);
          }

          #################
          # SITUATION III #
          #################
          else {
            $Contents = "$pwd/$_";
              if ($Contents =~ m,\.$,) {
                 $Contents =~ m,(.*)\.$,;
                 $Contents = $1;
               }
            dir(\%commands);
            fir(\%commands);
          }
        } 

    return $Contents;

   } # if Contents

} # end sub find_contents

# figure out --df and remove from nfileindex-arch-dists.deb 
sub remove_add_nfile {

   my ($argument,$Contents,$subject,$commands) = @_;
   my %commands = %$commands;
   #my $contentsdb = finddb(\%commands);
   #my ($arch,$dist) = which_archdist(\%commands);
   ##nzing(\%commands);

   # the + solution
   $argument =~ s,\+,\\\\+,g if $argument =~ m,\+,;
   $Contents = "zgrep -E $argument\ $Contents"; 
   
   my($dirfile,$package,@dirfile,%all,%again,
      @package_match,@more_things,@file);
    open(CONTENTSDB, "$Contents"); 
    while (<CONTENTSDB>) {
    # changed for >= 0.2.9
    #if (/^FILE\s*LOCATION$/) {                                             
    #while (<CONTENTSDB>) {  
      ########
      # --DF #
      ########
       $argument =~ s,\\\\+,\\\+,g if $argument =~ m,\+,;                       
       if (m,$subject/$argument,) { 
       #if (m,\b$argument\b,) {

         ######################
         #    ENDS WITH /     #
         ######################
         if (m,.*/\s+\w*,) {
           ($dirfile,$package) = split(/\s+/,$_,2);
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           @dirfile = split(/\//,$dirfile); $dirfile =~ s,/$,,;
         } 
         ######################
         # DOESN'T END WITH / #
         ######################
         else {
           ($dirfile,$package) = split(/\s+/,$_,2);  
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           @dirfile = split(/\//,$dirfile);
         }
         ###########################
         # PROCESS INTO FILES/DIRS #
         ###########################
         my ($count,$holder);
         for ($count = 0; $count <= $#dirfile; $count++) {
              if ($count == 0) {
                $holder = "/$dirfile[$count]";
                my $again = "$dirfile[$count]";
                $again{$again}++;
                #my $all = "/.";
                #$all{$all}++;
                #if ($all{$all} == 1) {
                  #print FILELIST "/.\n";
                #}
                if ($again{$again} == 1) {                 
                  push(@file,"/$dirfile[$count]");
                  #print FILELIST "/$dirfile[$count]\n"; 
                }
              }
              else {  
                $holder =  $holder . "/$dirfile[$count]";
                my $again = "$holder";
                $again{$again}++;
                if ($again{$again} == 1) {
                  push(@file,"$holder");
                  #print FILELIST "$holder\n"; 
                }
              }
         } # end for
       }
    undef @package_match;
    #}
    #}
    } # while
   close(CONTENTSDB);
   undef @more_things; undef @dirfile; undef %again; undef %all;
   return @file;


} # end sub remove_nfile

1;
