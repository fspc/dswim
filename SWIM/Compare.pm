#    Package administration and research tool for Debian
#    Copyright (C) 1999-2000 Jonathan D. Rosenbaum

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


package SWIM::Compare;
use strict; 
use SWIM::Conf qw($dpkg);
use SWIM::Library;
use vars qw(@ISA @EXPORT %EXPORT_TAGS);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(comparison compare_versions);

# comparison function and checking function (-v) for not-installed databases

=pod

DEVELOPMENTAL

This uses the comparison method mentioned in the packaging manual.  It
will look for an epoch *: or the absence, and a revision -* or the
absence.  First the epoch is compared, then the upstream-version, than
the debian-revision.  The sub will stop and return a value as soon as
a difference is found.  A look in the dpkg attic helped out (compare_vnumbers)
here, but lib.pl used separate subs, and doesn't appear to check for
an epoch separately, ofcourse there may have not been an epoch.  This
uses the special variable $&, but apparently this isn't as big a waste
of resources in later versions of Perl, but there will be some
experiments and benchmarks for alternatives in the future for this sub.
There some rules built into comparison() to deal with patch to non-patch,
more than one hyphen (-).  This involves a little transformation.
You can verify that this sub is working by doing perl -e '$five =\
system "dpkg --compare-versions 10 gt 1.0.17";  print "nop\n" if $five\
== 256; print "yes\n" if $five == 0', take a look at the scripts, too.
Also, use -v (compare_versions()) when using --initndb or --rebuildndb
for a report. 

=cut

sub comparison {

  # $pversion = version from Packages.gz   
  # $eversion = version from nstatusindex-arch-dist.deb 

  my($pversion,$eversion) = @_;  
  my($epoch, $upstream, $revision);
  my($eepoch, $eupstream, $erevision);
  my($revisiond,$erevisiond);
  my $result;

 # If the two versions "eq" one another no reason to go on
 if ($pversion ne $eversion) {

 # check epoch first, go on if the same
 #########
 # EPOCH #
 #########
 if ($pversion =~ /:/ || $eversion =~ /:/) {
    if ($pversion =~ /:/) {
     ($epoch,$upstream) = split(/:/,$pversion,2);
    }
    else {
      $epoch = 0; $upstream = $pversion;
    }
    if ($eversion =~ /:/) {
     ($eepoch,$eupstream) = split(/:/,$eversion,2);
    }
    else {
      $eepoch = 0; $eupstream = $eversion;
    }      
  do {

   $epoch =~ s/^\d*//; my $epochd = $&;
   $eepoch =~ s/^\d*//; my $eepochd = $&;
   $result = $epochd <=> $eepochd; 
   return "<" if $result == -1;
   return ">" if $result == 1;

  } while (length ($epoch) && length ($eepoch));
    #return length ($a) cmp length ($b);
 } # end if epoch
 else {
      $epoch = 0; $upstream = $pversion;
      $eepoch = 0; $eupstream = $eversion;
 }

 # Check the upstream-revision next
 #####################
 # UPSTREAM-REVISION #
 #####################
 if ($upstream || $eupstream) {
    # we need to run a little test in case hyphens exists more than once
    if ($upstream =~ /-/) {
      my $hyphen = ($upstream =~ tr/-//);
      if ($hyphen > 1) {
        $upstream =~ m,(^.*)-(.*$),;
        $upstream = $1;
        $revision = $2;
      }
      else  {  
        ($upstream,$revision) = split(/-/,$upstream,2); 
      }
    }
    else {
      # because the absence is considered earlier, and the convention
      # is to use -1.
      $revision = 0;
    }
    # we need to run a little test in case hyphens exists more than once
    if ($eupstream =~ /-/) {
      my $hyphen = ($eupstream =~ tr/-//);
      if ($hyphen > 1) {
        $eupstream =~ m,(^.*)-(.*$),;
        $eupstream = $1;
        $erevision = $2;
      }
      else {  
      ($eupstream,$erevision) = split(/-/,$eupstream,2); 
      }
    }
    else {
      # because the absence is considered earlier, and the convention
      # is to use -1.
      $erevision = 0;
    }
  do {
   # letters
   $upstream =~ s/^\D*//; my $upstreamd = $&;
   $eupstream =~ s/^\D*//; my $eupstreamd = $&; 

   # hopefully this handles nasty beta situations
   if ($upstreamd eq "b" and $eupstreamd eq "." ) {
    return "<";
   }
   elsif ($upstreamd eq "." and $eupstreamd eq "b" ) {
    return ">";
   }
   elsif ($upstreamd eq "beta" and $eupstreamd eq "." ) {                       
    return "<";                                                                 
   }                                                                            
   elsif ($upstreamd eq "." and $eupstreamd eq "beta" ) {                       
    return ">";                                                                 
   } 
   elsif ($upstreamd eq "." and $eupstreamd eq "-pre-") {
    return ">";
   }
   elsif ($eupstreamd eq "." and $upstreamd eq "-pre-") {
    return "<";
   }

   # solves problems when "." is compared to letters, and also a weird
   #  case involving a patched version changing to a non-patched version.
   if ($upstreamd =~  /\./) {
     if ($eupstreamd =~ /\w/) {
       if ($eupstreamd =~ /pl/ && $upstreamd !~ /pl/) {
          $eupstreamd = "";          
       }
       elsif ($upstreamd !~ /\.\w{2,10}/) {
          $eupstreamd = ".";
       }
     }
     elsif ($eupstreamd eq "") {
       $eupstreamd = ".";
     }
   } 
  # the weird -pre situation
  elsif ($upstreamd =~ /-pre/ || $eupstreamd =~ /-pre/) {
      $upstreamd = ""; $eupstreamd = "";
  }

   if ( $eupstreamd =~ /\./) {
     if ($upstreamd =~ /\w/) {
       if ($upstreamd =~ /pl/ && $eupstreamd !~ /pl/) {
          $upstreamd = "";          
       }
       elsif ($upstreamd !~ /\.\w{2,10}/) {
          $upstreamd = ".";
       }  
     }
     elsif ($upstreamd eq "") {
       $upstreamd = ".";
     }
   } 
   # the weird -pre situation
   elsif ($upstreamd =~ /-pre/ || $eupstreamd =~ /-pre/) {
      $upstreamd = ""; $eupstreamd = "";
   }

   $result = $upstreamd cmp $eupstreamd; 
   return "<" if $result == -1;
   return ">" if $result == 1;
   # it's importantant to realize that . & + are being checked for
   # above. : and - have already been dealt with. cmp seems to deal with
   # these characters with no problems.


   # numbers
 
   # found a little problem with <=> when number's eq "",
   # but this doesn't effect cmp.  
   if ($upstream eq "") {
     if ($eupstream eq ".") {
       $upstream = ".";
     }
     else {
       $upstream = 0;
     } 
   } 
   if ( $eupstream eq "") {
     if ($upstream eq ".") {
       $eupstream = ".";
     }
     else {
       $eupstream = 0;
     } 
   } 

   $upstream =~ s/^\d*//; $upstreamd = $&;
   $eupstream =~ s/^\d*//; $eupstreamd = $&;
   $result = $upstreamd <=> $eupstreamd; 
   return "<" if $result == -1;
   return ">" if $result == 1;
  } while (length ($upstream) || length ($eupstream))
 } # end if upstream
 else {
      $revision = 0;
      $erevision = 0;
 }

 # Finally, check the revision
 ############
 # REVISION #
 ############
 if ($revision || $erevision) {
  do {
   # letters
   $revision =~ s/^\D*//;  $revisiond = $&; #$revisiond =~ s/\W/ /g;
   $erevision =~ s/^\D*//; $erevisiond = $&; #$erevisiond =~ s/\W/ /g;

   # pre in the revision
   if ($revisiond eq "." and $erevisiond eq "pre") {
    return "r>";
   }
   elsif ($erevisiond eq "." and $revisiond eq "pre") {
    return "r<";
   }
   $result = $revisiond cmp $erevisiond; 
   return "r<" if $result == -1;
   return "r>" if $result == 1;
   # it's importantant to realize that . & + are being checked for
   # above. : and - have already been dealt with. cmp seems to deal with
   # these characters with no problems.

   # numbers
   # found a little problem with <=> when number's eq "",
   # but this doesn't effect cmp.  
   if ($revision eq "") {
     if ($erevision eq ".") {
       $revision = ".";
     }
     else {
       $revision = 0;
     } 
   } 
   if ( $erevision eq "") {
     if ($revision eq ".") {
       $erevision = ".";
     }
     else {
       $erevision = 0;
     } 
   }

   $revision =~ s/^\d*//; $revisiond = $&;
   $erevision =~ s/^\d*//; $erevisiond = $&;
   $result = $revisiond <=> $erevisiond; 
   return "r<" if $result == -1;
   return "r>" if $result == 1;
  } while (length ($revision) && length ($erevision));
 } # end if revision

  # still 0? check the remainder..this is just for letters which may have
  # been mulled over because they looked like words \w.
 if ($result == 0) {
    $result = $epoch cmp $eepoch || $upstream cmp $eupstream || 
              $revision cmp $erevision; 
    return "<" if $result == -1;
    return ">" if $result == 1;
 }
 }

} # end sub comparison


# This produces a report to make sure that comparison() is up to par, and
# is called with -v.  It uses dpkg's --compare-versions.  The advantage of
# not normally running --compare-versions is portability.  People using
# other distribution's don't need dpkg installed, and people using weird
# Oses who can't use dpkg can still explore a virtual installation.
sub compare_versions {

  # The test result is put in .version_compare

  # $result = operand (result from comparison)
  # $virtual = version from Packages.gz   
  # $installed = version from nstatusindex-arch-dist.deb 
  # $name = packagename
  # $commands = options
  
   my ($result, $virtual, $installed, $name, $commands) = @_;
   my %commands = %$commands;
   my ($cv, $cv_result, $cresult);
   my $place = finddb(\%commands);

   # usually it will be greater
   if (defined $dpkg) {
   $cv = system "$dpkg", "--compare-versions", "$virtual", "gt", "$installed"; 

   $cv_result = "no" if $cv == 256;
   $cv_result = "yes" if $cv == 0;
   #$cresult = "no" if $result =~ m,[r]?<,;
   #$cresult = "yes" if $result =~ m,[r]?>,;
   $cresult = "no" if $result eq "<" || $result eq "r<";
   $cresult = "yes" if $result eq ">" || $result eq "r>";

  open(CV,">>$place/.version_compare") 
  or warn "couldn't create version compare report\n";
      if ($cresult eq "yes" && $cv_result eq "no") {
  print CV "$name:\ndpkg - $virtual < $installed\nswim - $virtual > $installed\n\n";
      }  
      elsif ($cresult eq "no" && $cv_result eq "yes") {
  print CV "$name:\ndpkg - $virtual > $installed\nswim - $virtual < $installed\n\n";
      }
      else {
       return;
      }
  close(CV);
  }

} # end sub compare_versions



1;
