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


package SWIM::NDB_Init;
use strict;
use DB_File;
use SWIM::Library;
use SWIM::Format;
use SWIM::Conf qw(:Path $default_directory $apt_cache @user_defined_section
                  $distribution $pwd $sort $gzip $architecture $slowswim 
                  $longswim $apt_sources $alt);
use SWIM::Global qw(%sb $argument $main::home);
use SWIM::Dir;
use SWIM::Compare;
use SWIM::MD;
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(initndb);


# initndb() not_installed() exist_sb() sb() compress_contests() nmd()  
# --initndb --rebuildndb  - exist_sb and sb are in DB_Library as well.

# this checks for the @ARG for a not-installed database make and then runs
# not_installed()
sub initndb {

      my($commands) = @_;
      my %commands = %$commands;

      my $one_more_arg = 0;
      my $save_argument;
      my($arch,$dist) = which_archdist(\%commands);
      $dist =~ m,^-(.*)$,; my $dis = $1;  my %what;
      $arch  =~ m,^-(.*)$,; my $arc = $1; my @what;
      my $df = $default_directory; my $contents;
      my $dd = $default_directory;
      if ($#ARGV != -1) {
      $ARGV[0] eq "APT" ? ($default_directory = $apt_sources) 
                        :  ($default_directory = $default_directory);             
      }

      # This provides the full path of dir/file.  ../ not implemented yet.
      # So, the queries can occur within each situation. 
      if ($#ARGV != -1) {


          ######################
          # APT & DF SITUATION #
          ######################
          # this part can also apply to apt
          if ($ARGV[0] eq "DF" || $ARGV[0] eq "APT") {
           if ($ARGV[0] eq "APT" && !defined $apt_cache) {  
             print "swim: this target requires apt\n";
             exit;
           }
            $df = $apt_sources if $ARGV[0] eq "APT";
            shift(@ARGV);
  
            # which section is wanted?  
            my ($main,$contrib,$non_free,$non_us,$experimental,
                $omain,$ocontrib,$onon_free,$onon_us,$oexperimental);  
            $omain = "main" if $commands->{"main"};
            $ocontrib = "contrib" if $commands->{"contrib"};
            $onon_free = "non-free" if $commands->{"non-free"};
            $onon_us = "non-US" if $commands->{"non-us"};
            #$oexperimental = "experimental" 
            # if $commands->{"dists"} eq "experimental";

            # Are we using a traditional debian archive structure from an
            # alternative distribution..or is it debian?
            if ($commands->{"alt"}) {
               $alt = $commands->{"alt"};
            }
     
           if (!defined $main && !defined $contrib && 
                !defined $non_free && !defined $non_us) {
            foreach (@user_defined_section) {
              if ($_ eq "main") {
                 $main = "main";
              }
              elsif ($_ eq "contrib") {
                 $contrib = "contrib";
             } 
             elsif ($_ eq "non-free") {
                 $non_free = "non-free";
             }
             elsif ($_ eq "non-US") {
                 $non_us = "non-US";
             }
            }
             if (defined $commands->{"dists"}) {
               if ($commands->{"dists"} eq "experimental") { 
                $experimental = "experimental";
               }
             }
             elsif ($distribution eq "experimental") {
                $experimental = "experimental"; 
             }
           }

           ################
           # USER DEFINED #
           ################ 
           # use user defined values for sections..if any of these aren't
           # true, options override the default values
           if (!defined $omain && !defined $ocontrib && 
               !defined $onon_free && !defined $onon_us) {
             if (defined $main) {
              my $count = 1;
              my $package = $alt . "_dists_" . "$dis" . "_main_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_main_" .
                            "binary$arch" ."_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"MAIN"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 $count++;
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"MAIN"} }) {
                    if (defined $what{"MAIN"}[$scount]) {
                      my $dsite = (split(/!/,$what{"MAIN"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"MAIN"}[$scount] = 
                       $what{"MAIN"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $contrib) {
              my $count = 1;
              my $package = $alt . "_dists_" . "$dis" . "_contrib_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_contrib_" .
                            "binary$arch" . "_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"CONTRIB"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 $count++; 
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"CONTRIB"} }) {
                    if (defined $what{"CONTRIB"}[$scount]) {
                      my $dsite = (split(/!/,$what{"CONTRIB"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"CONTRIB"}[$scount] = 
                       $what{"CONTRIB"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $non_free) {
              my $count = 1;
              my $package = $alt . "_dists_" . "$dis" . "_non-free_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_non-free_" .
                            "binary$arch" . "_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"NON-FREE"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 #print "$date $dsite $size\n";
                 $count++;
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"NON-FREE"} }) {
                    if (defined $what{"NON-FREE"}[$scount]) {
                      my $dsite = (split(/!/,$what{"NON-FREE"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"NON-FREE"}[$scount] = 
                       $what{"NON-FREE"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $non_us) {
              my $count = 1;
              # on package1 hope $alt is correct?
              my $package1 = $alt . "_" . "non-US" . "_"  . "$dis" .
                             "_" . "binary$arch" . "_Packages";
              my $package2 =  $alt . "_dists_" . "$dis" . "_non-US_" .
                              "binary$arch" . "_Packages";
              opendir(DF,"$df/");
               foreach (sort grep(/$package1|$package2/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"NON-US"}[$count] = 
                 "$date!$mtime!$size!$dsite!$df/$_!none";
                 $count++;
               }
              closedir(DF);
             }
             if (defined $experimental) {
              my $count = 1;
              my $package = $alt ."_project_experimental_Packages";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"EXPERIMENTAL"}[$count] = 
                 "$date!$mtime!$size!$dsite!$df/$_!none";
                 $count++;
               }
              closedir(DF);
             }
           }
           ################
           # COMMAND LINE #
           ################
           else {
             if (defined $omain) {
              my $count = 1; 
              my $package = $alt . "_dists_" . "$dis" . "_main_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_main_" .
                            "binary$arch" . "_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"MAIN"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 $count++;
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"MAIN"} }) {
                    if (defined $what{"MAIN"}[$scount]) {
                      my $dsite = (split(/!/,$what{"MAIN"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"MAIN"}[$scount] = 
                       $what{"MAIN"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $ocontrib) {
              my $count = 1;
              my $package = $alt . "_dists_" . "$dis" . "_contrib_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_contrib_" .
                            "binary$arch" . "_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"CONTRIB"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 $count++;
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"CONTRIB"} }) {
                    if (defined $what{"CONTRIB"}[$scount]) {
                      my $dsite = (split(/!/,$what{"CONTRIB"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"CONTRIB"}[$scount] = 
                       $what{"CONTRIB"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $onon_free) {
              my $count = 1;
              my $package = $alt . "_dists_" . "$dis" . "_non-free_" .
                            "binary$arch" . "_Packages";
              my $release = $alt . "_dists_" . "$dis" . "_non-free_" .
                            "binary$arch" . "_Release";
              opendir(DF,"$df/");
               foreach (sort grep(/$package/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"NON-FREE"}[$count] = "$date!$mtime!$size!$dsite!$df/$_";
                 #print "$date $dsite $size\n";
                 $count++;
               }
              closedir(DF);
              $count = 1;
              opendir(DF,"$default_directory");
               foreach (sort grep(/$release/, readdir(DF))) {
                 my $releasite = (split(/_/,$_))[0];
                 open(RELEASE,"$default_directory/$_");
                 while (<RELEASE>) { 
                  if (m,^Version:,) {
                   m,^Version:\s+(.*),; my $Version = $1;
                   my $scount;
                   foreach $scount (0 .. $#{ $what{"NON-FREE"} }) {
                    if (defined $what{"NON-FREE"}[$scount]) {
                      my $dsite = (split(/!/,$what{"NON-FREE"}[$scount]))[3];
                      if ($dsite eq $releasite) {
                       $what{"NON-FREE"}[$scount] = 
                       $what{"NON-FREE"}[$scount] ."!$Version";
                      }
                    }
                   }
                  }
                 }
                 close(RELEASE);
                 $count++; 
               }
              closedir(DF);
             }
             if (defined $onon_us) {
              my $count = 1;
              my $package1 = $alt . "non-US" . "_"  . "$dis" . "_" .
                             "binary$arch" . "_Packages";
              my $package2 = $alt . "_dists_" . "$dis" . "_non-US_" .
                             "binary$arch" . "_Packages";
              opendir(DF,"$df/");
               foreach (sort grep(/$package1|$package2/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what{"NON-US"}[$count] = 
                 "$date!$mtime!$size!$dsite!$df/$_!none";
                 #print "$date $dsite $size\n";
                 $count++;
               }
              closedir(DF);
             }           
           }

          ####################
          # PACKAGE PRINTOUT #
          ####################
          # check to see that all Packages have a Release file, there is
          # no date check on Release files because it is assumed that they
          # will be kept current.  Versions apt >= 3.2 download *Release. 
          #  "none" if no Release is found, avoids unecessary errors, here.
          # If all the Release versions are the same check against a file
          # to find if there is a change, otherwise check against
          # themselves.
          my ($section,$site,$scount,%CHECK);
          if ( %what ) {
           foreach $section (keys %what) {
            foreach $scount (0 .. $#{ $what{$section} }) {              
              if (defined $what{$section}[$scount]) {
               my @CHECK = split(/!/,$what{$section}[$scount]);
               if ($#CHECK != 5) {
                print  STDERR "swim: Missing Release files.\n"; 
                print STDERR "swim: This can occur when there is no Release file found at the site.\n";
                $what{$section}[$scount] = $what{$section}[$scount] ."!none";
               }
               elsif ($CHECK[$#CHECK] ne "none") {
                $CHECK{$CHECK[$#CHECK]} = "";
               }
              }
            }
           }
          }
          my @AMT = keys %CHECK;

          # Time to store Release version number, if it is the same - no
          # need to, if it has changed, time to make an important warning.
          # Obviously this can occur for stable or unstable.
          my $place = finddb(\%commands); my (@CHANGE,$CHANGE);
          if (-e "$place/.release$arch$dist") {
            open(VERSION,"$place/.release$arch$dist") or exit;
            if ($#AMT == 0) {
             @CHANGE = <VERSION>; chomp $CHANGE[0];
             if ($CHANGE[0] ne $AMT[0]) {
                $CHANGE = $CHANGE[0];
             } 
            }
          }
          else {           
           open(VERSION,">$place/.release$arch$dist") or exit;
            if (!defined <VERSION>) {
              if ($#AMT == 0) {
               print VERSION $AMT[0];
              }
            }
          }

          if (!$commands->{"cron"}) {

          # print out the stuff for analysis
          $~ = "SUBJECT";
          $subsite = "Site"; $subdate = "Date"; $subsize =  "Size (bytes)";
          $number = "###"; $subrelease = "Release";
          my $ex;
          %what ?
            write STDOUT :
            ($ex = 0);
            if (defined $ex) {
              #if ($commands->{"dists"} || $commands->{"arch"}) {
               print "swim: no Packages exist for $dis $arc\n"; 
             exit;
            }
          # Some changed
          if ($#AMT > 0) {
              $~ = "CENTER";
              $section = "WARNING: RELEASE CHANGE";
              $center = $section;
              write STDOUT;
              print "\n";
           }
           # All changed
           if (defined $CHANGE) {
              $~ = "CENTER";
              $section = "WARNING: $AMT[0] to $CHANGE";
              $center = $section;
              write STDOUT;
              print "\n";
           }
          foreach $section (keys %what) {
              $~ = "CENTER";
              #print "CENTER $section\n";
              $center = $section;
              write STDOUT;
           foreach $scount (0 .. $#{ $what{$section} }) {
             if (defined $what{$section}[$scount]) {
               $~ = "SDS";
               my ($date,$size,$site,$release) = 
               (split(/!/,$what{$section}[$scount],))[0,2,3,5];
               $number = $scount; $sdsite = $site; 
               $sdsdate = $date; $sdsize = $size;
               $sdsrelease = $release;
               write STDOUT;
             }
           }
           print "\n";
          }

          #######################
          # PACKAGE INTERACTIVE #
          #######################
          # Let the person decide on one, or none for each section.
          $~ = "STDIN";
          my ($OK,%GOON); 
           my $scal_count = 1;
           my $end = (split(/\//, scalar(%what)))[0];

          AGAIN: while (!defined $OK) {
           foreach $section (keys %what) {
            if (!defined $GOON{$section}) { 
             print "swim: for $section, which ### do you want?: ";
            my $use_num = <STDIN>; chomp $use_num;
               if ($use_num ne "" && $use_num =~ /\b\d+\b/) {
                 if (defined $what{$section}[$use_num]) {
                    push(@ARGV,(split(/!/,$what{$section}[$use_num]))[4]); 
                    $GOON{$section} = $section;
                    if ($scal_count == $end) {
                       $OK = "yes";
                    }
                 }           
                 else {
                    if ($scal_count < $end) {
                    print "swim: do you want to go on to the next section? (yes or no): ";  
                    }
                    else {
                    print "swim: do you want this section? (yes or no): ";
                    $OK = "yes";
                    }
                    my $again = <STDIN>; #chomp $again;
                    while ($again eq "\n" || !($again eq "yes\n" 
                           || $again eq "no\n")) {
                       print "swim: please enter yes or no: ";
                       $again = <STDIN>;
                    } 
                    $GOON{$section} = $section if $again ne "no\n";
                    $scal_count++ if $again eq "yes\n";
                    $end++ if $again eq "yes\n";
                    next AGAIN if $again eq "no\n";
                 }           
               }
               else {
                    if ($scal_count < $end) {
                    print "swim: do you want to go on to the next section? (yes or no): ";  
                    }
                    else {
                    print "swim: do you want this section? (yes or no): ";
                    $OK = "yes";
                    }
                    my $again = <STDIN>; #chomp $again;
                    while ($again eq "\n" || !($again eq "yes\n" 
                           || $again eq "no\n")) {
                       print "swim: please enter yes or no: ";
                       $again = <STDIN>;
                    } 
                    $GOON{$section} = $section if $again ne "no\n";
                    $scal_count++ if $again eq "yes\n";
                    $end++ if $again eq "yes\n";
                    next AGAIN if $again eq "no\n";
               }
            }
            $scal_count++;
           }   # for section
          }
 
          exit if $#ARGV == -1;


          ################################
          # APT || DF CONTENTS SITUATION #
          ################################
         if ($commands->{"Contents"}) {
           if ($commands->{"Contents"} eq "FDBDF" ||
               $commands->{"Contents"} eq "DF") {
               $df = $dd;
           }
     
              my $count = 1;
              $contents = "_" . "$dis" . "_" . "Contents$arch";
              opendir(DF,"$df/");
               foreach (sort grep(/$contents/, readdir(DF))) {
                 my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                 my $date = localtime($mtime);
                 my $dsite = (split(/_/,$_))[0];
                 $what[$count] = "$date!$mtime!$size!$dsite!$df/$_!none";
                 $count++;
               }
              closedir(DF);

          #####################
          # CONTENTS PRINTOUT #
          #####################

          # print out the stuff for analysis
          $~ = "SUBJECT";
          $subsite = "Site"; $subdate = "Date"; $subsize =  "Size (bytes)";
          $number = "###";
	   @what ?
            write STDOUT :
            ($ex = 0);
            if (defined $ex) {
               print "swim: no Contents exist for $dis $arc\n"; 
               # there is a reason to stop ofcourse!
               exit;
            }
              $~ = "CENTER";
              #print "CENTER $section\n";
              $center = "CONTENTS";
              write STDOUT;

           foreach $scount (0 .. $#what) {
             if (defined $what[$scount]) {
               $~ = "SDS";
               my ($date,$size,$site,$release) = 
               (split(/!/,$what[$scount],))[0,2,3,5];
               $number = $scount; $sdsite = $site; 
               $sdsdate = $date; $sdsize = $size;
               $sdsrelease = $release;
               write STDOUT;
             }
           }

          ########################
          # CONTENTS INTERACTIVE #
          ########################
          undef $OK; undef %GOON;
          $~ = "STDIN";
          print "\n";
          AGAIN: while (!defined $OK) {
           foreach $scount (1 .. $#what) { 
             print "swim: for CONTENTS, which ### do you want?: ";
             my $use_num = <STDIN>; chomp $use_num;
                if ($use_num ne "" && $use_num =~ /\b\d+\b/) {
                  if (defined $what[$use_num]) {
                     ($contents) = (split(/!/,$what[$use_num]))[4]; 
                     $OK = "yes";
                     last;
                  } 
                  else {
                     print "swim: do not use CONTENTS? (yes or no): ";
                     my $again = <STDIN>;
                     while ($again eq "\n" || !($again eq "yes\n" 
                           || $again eq "no\n")) {
                       print "swim: please enter yes or no: ";
                       $again = <STDIN>;
                     } 
                     next AGAIN if $again eq "no\n";
                     $OK = "yes" if $again eq "yes\n"; last if $again eq "yes\n";
                  }
                }
                else {
                   print "swim: do not use CONTENTS? (yes or no): ";
                   my $again = <STDIN>;
                   while ($again eq "\n" || !($again eq "yes\n" 
                         || $again eq "no\n")) {
                     print "swim: please enter yes or no: ";
                     $again = <STDIN>;
                   } 
                   next AGAIN if $again eq "no\n";
                   $OK = "yes" if $again eq "yes\n"; last if $again eq "yes\n";
                }
           }
          }
         } # if Contents

          } # if not cron

          ########
          # CRON #
          ########
          # if no user interaction is wanted, this will figure out which
          # Packages for each section and Contents database is the newest
          # and use them.  If the Release has changed --cron will not
          # continue.  This uses APT and/or DF.
          else { 
           if ($#AMT > 0 || defined $CHANGE) {
             print "swim: RELEASE CHANGE\n";
             exit;
           }          

           ############
           # PACKAGES #
           ############
           my ($section,$site,$scount,%TIME);
           if ( %what ) {
            foreach $section (keys %what) {
             foreach $scount (0 .. $#{ $what{$section} }) {              
               if (defined $what{$section}[$scount]) {
                my $time = (split(/!/,$what{$section}[$scount]))[1];
                $TIME{$section}{"$section!$scount"} = $time;
               }
             }
            }
           }
           foreach $section (keys %TIME) {
             my @comparer;
            foreach $site (keys %{ $TIME{$section} }) {
               push(@comparer,$TIME{$section}{$site});
            }
            @comparer = sort { $b <=> $a } @comparer;
            my $newest = shift @comparer;
            my %only_one;
            foreach $site (keys %{ $TIME{$section} }) {
              if ($TIME{$section}{$site} == $newest) {
                $only_one{$newest}++;
                if ($only_one{$newest} == 1) {
                  my($sect,$count) = (split(/!/,$site))[0,1];
                  push(@ARGV,(split(/!/,$what{$sect}[$count]))[4]);
                }
              }
            }
           }
           exit if $#ARGV == -1;
       
           ############
           # CONTENTS #
           ############
           if ($commands->{"Contents"}) {
             if ($commands->{"Contents"} eq "FDBDF" ||
                 $commands->{"Contents"} eq "DF") {
                 $df = $dd;
             }
     
                my $count = 1;
                $contents = "_" . "$dis" . "_" . "Contents$arch";
                opendir(DF,"$df/");
                 foreach (sort grep(/$contents/, readdir(DF))) {
                   my ($size,$mtime) = (stat("$df/$_"))[7,9]; 
                   my $date = localtime($mtime);
                   my $dsite = (split(/_/,$_))[0];
                   $what[$count] = "$date!$mtime!$size!$dsite!$df/$_!none";
                   $count++;
                 }
                closedir(DF);


             my @time;
             foreach (@what) {
               if (defined $_) {
                push(@time,$_);
               }
             }

             @what = map { $_->[1] } 
                     sort { $b->[0] <=> $a->[0] }
                     map { [ (split(/!/,$_))[1], $_ ] } 
                     @time;

             $contents = (split(/!/,$what[0]))[4];

           } # end Contents
          }

         } # end total thing pertaining to APT DF          


         foreach (@ARGV) {
          ###############
          # SITUATION 0 #
          ###############
          if (m,\.\./|^\.\.$,) {
           if ($_ !~ m,/[\w\+-]+/[\.\$\^\+\?\*\[\]\w-]*$,) {
             my $dd; tr/\/// ? ($dd = tr/\///) : ($dd = 1); 
             my @pwd =  split(m,/,,$pwd);
             s,\.\./,,g;
             my $tpwd = "";
             for (1 .. $#pwd - $dd) {
               $_ == 1  ? ($tpwd = "/$pwd[$_]") 
                        : ($tpwd = $tpwd . "/$pwd[$_]");
             }
            $_ ne ".." ? ($argument = "$tpwd/$_") : ($argument = "$tpwd/");
           }
           else {  print "swim: not implemented yet\n"; exit; }
            dir(\%commands);
            fir(\%commands);
            #print "0 $argument\n";
            if ($one_more_arg > 0) {
              $argument = qq($save_argument $argument);  
            }
            $one_more_arg++;
            $save_argument = $argument;
          }

          ###############
          # SITUATION I #
          ###############
          if ( m,\/,) {
            $argument = $_;
              if ($argument =~ m,^\.\/.*,) {
                  if ($pwd !~ m,^\/$,) {
                    $argument =~ m,^\.([^\.].*$),;
                    $argument = "$pwd$1";
                  }
                  else {
                   $argument =~ m,^\.([^\.].*$),;
                   $argument = "$1";
                  }
               } 
            dir(\%commands);
            fir(\%commands);
            #print "I $argument\n";
            if ($one_more_arg > 0) {
              $argument = qq($save_argument $argument);  
            }
            $one_more_arg++;
            $save_argument = $argument;
          }

          ################
          # SITUATION II #
          ################
          elsif ($pwd =~ m,^\/$,) {
            $argument = "/$_";
            dir(\%commands);
            fir(\%commands);
            #print "II $argument\n";
            if ($one_more_arg > 0) {
              $argument = qq($save_argument $argument);  
            }
            $one_more_arg++;
            $save_argument = $argument;
          }

          #################
          # SITUATION III #
          #################
          else {
            $argument = "$pwd/$_";
              if ($argument =~ m,\.$,) {
                 $argument =~ m,(.*)\.$,;
                 $argument = $1;
               }
            dir(\%commands);
            fir(\%commands);
            #print "III $argument\n";
            if ($one_more_arg > 0) {
              $argument = qq($save_argument $argument);  
            }
            $one_more_arg++;
            $save_argument = $argument;
          }
        } # end foreach 
       # this is where SWIM::NDB::update_packages_ndb can be, too.  
       not_installed(\%commands) if $commands->{"initndb"} ||
                                    $commands->{"rebuildndb"};
        if ($commands->{"ndb"}) {
          require SWIM::NDB;
          SWIM::NDB->import(qw(update_packages_ndb));
          update_packages_ndb(\%commands,$contents);
        }
       }

       # NO ARGUMENTS
       else {
         print "swim: no Packages file mentioned\n";
         exit;
       }

       ############
       # CONTENTS #
       ############
       # Figure out where Contents is
       if ($commands->{"Contents"}) {
        my ($Contents,$FDB);
        for ($commands->{"Contents"}) { 
         if ($commands->{"Contents"} =~ /^FDB/) {
            s/FDB//; 
            $FDB = "yes";
          } 
          if ($commands->{"Contents"} eq "FDBDF" ||                               
              $commands->{"Contents"} eq "DF") {                                  
            $Contents = $contents;                            
          } 

          ###############
          # SITUATION 0 #
          ###############
          # this doesn't work to well for anything less simple than ../../
          elsif (m,^\.\./|^\.\.$,) {
           if ($_ !~ m,/[\w\+-]+/[\.\$\^\+\?\*\[\]\w-]*$,) {
             my $dd; tr/\/// ? ($dd = tr/\///) : ($dd = 1); 
             my @pwd =  split(m,/,,$pwd);
             s,\.\./,,g;
             my $tpwd = "";
             for (1 .. $#pwd - $dd) {
               $_ == 1  ? ($tpwd = "/$pwd[$_]") 
                        : ($tpwd = $tpwd . "/$pwd[$_]");
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

     if (!defined $FDB) {
     # To the total db thing.  Will have to find Contents.
      if ($commands->{"initndb"} || $commands->{"rebuildndb"}) {
       nmd($Contents,\%commands);

      # Do the the lowmem approach
      system "$slowswim", $tmp, $sort;

      # has to know --arch and --dist
      process_md(\%commands)
      }
      elsif ($commands->{"ndb"}) {
       exit;
      }
     }
     elsif (defined $FDB) {
       compress_contents($Contents,\%commands);      
     }

   } # if Contents

} # end sub initndb

# This represents one on the most useful features of swim, the ability to
# evauluate a non-installed system by grabbing information from the
# Packages and Contents files.  Ofcourse it is a hypothetical system, because
# lots of packages which wouldn't be able to live with one another are
# presented, and a few of swim's features which would normally be useful on a
# real system are disabled.  But, this is a great way to explore around and
# discover things.  The goal here is to provide information to
# people who don't even have dpkg installed so available won't be used.
# This will include architecture called and all.  frozen, stable, and
# unstable distributions will have separate dbs.  What will be kept will be
# determined by version.  This is set-up so a person can use an indices
# file as well as a specific Packages, and Contents files (obviously, the
# proper Contents file will have to be used). 
sub not_installed {

  my ($commands) = @_;
  my %commands = %$commands;

  #my whatever that is
  my ($arch, $dist);
  my @Tdescription;
  my @description; 
  my @ldescription;
  my @package;
  my %ndb;
  my @name;
  my $count = 0;

  my $the_status; 

  my $status; 
  my @essential;
  my $priority; 
  my $section; 
  my $installed_size; # at the very end 
  my $maintainer; 
  my $source;  # at the very end
  my $version;
  my $ver;

  my %ngb;
  my %group; 
  my $group;

  # Keeps a package->version database 
  # to save time over using status
  my %nsb;
  my @status;
  my $things;  # /.
  my $scount = 0;

  my ($pre_depends, $depends, $replaces, $provides, $recommends, 
      $suggests, $enhances, $conflicts, @REPLACE);

  my @conffiles;
  my @conf;
  my @complete;
  my @form;
  my @formly;
  my $format_deb = "$tmp/format.deb";

  my ($filename,@FILENAME);
  my $size;
  my @MD5SUM;
  my ($ok,$goon); # arch & dist skippers
  my $distro; # the distribution in the Packages

  # when revision: exists this helps md5sumo() since the package is labeled
  # differently than the version number everywhere else.
  my @revision; 

 # Let's determine what architecture and distribution this person is
 # interested in.
 #if (defined $architecture || defined $distribution) {
 #  ($arch,$dist) = which_archdist();
 #}  
      if ($commands->{"arch"}) {
        $architecture = $commands->{"arch"};
      }
      else {
        $architecture = $architecture;
      }
 
      if ($commands->{"dists"}) {
        $distribution = $commands->{"dists"};
        ($arch,$dist) = which_archdist(\%commands);
      }
      else {
        $distribution =  $distribution;
        ($arch,$dist) = which_archdist(\%commands);
      }


 # we only need to clean-up, and decide what to do once.

# Let's decide whether we should even go on.  If it is --initdb, and
# the databases already exist, nothing should be touched, but if it is
# --rebuilddb and they exist, then they are removed and remade from
# scratch. 

   # But first, better clean up any files in $tmp in case of an aborted
   # database formation
    unlink(<$tmp/DEBIAN*>) if -e "$tmp/DEBIANaa";
    unlink("$tmp/transfer.deb") if -e "$tmp/transfer.deb";
    unlink("$tmp/big.debian") if -e "$tmp/big.debian";
    unlink("$tmp/long.debian") if -e "$tmp/long.debian";


  # People may not want to use --Contents for a variety of reasons, so
  # nfileindex-arch-dist.deb may not exist.  If this is the case querying
  # will have to be done a little bit differently.
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
      if ($commands->{"initndb"}) {  
        if (-e "$main::home$parent$library/npackages$arch$dist.deb") {            
            print "swim:  use --rebuildndb\n";
            exit;
        }
        else {
          # if a database happens to be missing 
          if (-e "$main::home$parent$library/npackages$arch$dist.deb") {
             unlink("$main::home$parent$library/npackages$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/nfileindex$arch$dist.deb") {
             unlink("$main::home$parent$library/nfileindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ngroupindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ngroupindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb.gz");
          }
          # might as well delete these to free some room
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb.gz");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb.gz");
          }
          
        }
      }
      #  this only works if all databases exist.
      elsif ($commands->{"rebuildndb"}) {
        if (-e "$main::home$parent$library/npackages$arch$dist.deb") {            
          unlink("$main::home$parent$library/npackages$arch$dist.deb");
          unlink("$main::home$parent$library/nfileindex$arch$dist.deb");
          unlink("$main::home$parent$library/ngroupindex$arch$dist.deb");
          unlink("$main::home$parent$library/nstatusindex$arch$dist.deb");
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb.gz");
          }
          # might as well delete these to free some room
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb.gz");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb.gz");
          }
        }
        else {
          print "swim:  use --initndb to create databases\n";
          exit;
        }
      }  
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
      if ($commands->{"initndb"}) {  
        if (-e "$main::home$parent$base/npackages$arch$dist.deb") {            
            print "swim:  use --rebuildndb\n";
            exit;
        }
        else {
          # if a database happens to be missing 
          if (-e "$main::home$parent$base/npackages$arch$dist.deb") {
             unlink("$main::home$parent$base/npackages$arch$dist.deb");
          }
          if (-e "$main::home$parent$base/nfileindex$arch$dist.deb") {
             unlink("$main::home$parent$base/nfileindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ngroupindex$arch$dist.deb") {
             unlink("$main::home$parent$base/ngroupindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb.gz");
          }
          # might as well delete these to free some room
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb") {
             unlink("$main::home$parent$base/nsearchindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$base/nsearchindex$arch$dist.deb.gz");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb.gz");
          }
        }
      }
      #  this only works if all databases exist.
      elsif ($commands->{"rebuildndb"}) {
        if (-e "$main::home$parent$base/npackages$arch$dist.deb") {            
          unlink("$main::home$parent$base/npackages$arch$dist.deb");
          unlink("$main::home$parent$base/nfileindex$arch$dist.deb");
          unlink("$main::home$parent$base/ngroupindex$arch$dist.deb");
          unlink("$main::home$parent$base/nstatusindex$arch$dist.deb");
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ncontentsindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ncontentsindex$arch$dist.deb.gz");
          }
          # might as well delete these to free some room
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/nsearchindex$arch$dist.deb.gz");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb");
          }
          if (-e "$main::home$parent$library/ndirindex$arch$dist.deb.gz") {
             unlink("$main::home$parent$library/ndirindex$arch$dist.deb.gz");
          }
        }
        else {
          print "swim:  use --initndb to create databases\n";
          exit;
        }
      }  
  }


  # which section is wanted?  
  my ($main,$contrib,$non_free,$non_us);  
  $main = "main" if $commands->{"main"};
  $contrib = "contrib" if $commands->{"contrib"};
  $non_free = "non-free" if $commands->{"non-free"};
  # hopefully US is always capitalized -- watch this
  $non_us = "non-US" if $commands->{"non-us"};
  if (!defined $main && !defined $contrib && !defined $non_free &&
      !defined $non_us) {
     foreach (@user_defined_section) {
        if ($_ eq "main") {
          $main = "main";
        }
        elsif ($_ eq "contrib") {
          $contrib = "contrib";
        } 
        elsif ($_ eq "non-free") {
          $non_free = "non-free";
        }
        elsif ($_ eq "non-US") {
          $non_us = "non-US";
        }
     }
  }


  #!!!
  print scalar(localtime), "\n";  
  
    # remove the version check file
    my $place = finddb(\%commands);
    if ($commands->{"v"}) {
        unlink("$place/.version_compare");
    }

    # will use dir() and fir() to find path to Packages or Package.gz
    # to make things easy, only one or more compressed files, or
    # one or more non-compressed files may be used together in a set.
    print "Data is being gathered\n";
    my @check_arg = split(/\s/,$argument);
    my $ac = 0;
    my $gz;
    foreach (@check_arg) {
     if ($ac == 0) {
      if (-B || m,\.(gz|Z)$,) {
        $argument = "gzip -dc $argument|";
        $gz = "yes";
      }
      else {
        $argument = "cat $argument|";
      }
     }
     else {
      if (-B || m,\.(gz|Z)$,) {
         if (!defined $gz) {
          print "swim: targets must be one set of compressed or uncompressed file(s)\n";
          exit;
         }
      }
      else {
         if (defined $gz) {
          print "swim: targets must be one set of compressed or uncompressed file(s)\n";
          exit;
         }
      }
     }
     $ac++;
    }   

    # I decided to not keep more than one instance of a package if
    # it happens to have more than one version, this means running
    # a check, but if the package exists in another architecture, then
    # it isn't a repeat.

  # 2003 This is my customized approach using "apt-cache dumpavail" rather
  # then lists/packages

  $argument = "apt-cache dumpavail|";

    my (%Package_count,%not_me,$packler,%not_me2,%warch,%arc);
    open(PACKAGE, "$argument");
      while (<PACKAGE>) {
        if (/^Package:/i) {                                              
         $packler = substr($_,9); chomp $packler;
         $Package_count{$packler}++; 
        } 
        elsif (/^Version:/) {       
          # decide who shall rule with the greatest version 
          my $version = substr($_,9); chomp $version;
          $not_me{$packler} = $version if $Package_count{$packler} == 1; 
          if ($Package_count{$packler} > 1) {
           my $answer = comparison($not_me{$packler},$version);
           if ($answer eq "<" || $answer eq "r<" || $answer eq "") {
             delete $not_me{$packler}; delete $Package_count{$packler};
             $not_me{$packler} = $version; $Package_count{$packler} = 1;
             delete $not_me2{$packler}; $not_me2{$packler} = $version;
           }
           else {
             $not_me2{$packler} = $not_me{$packler};
             delete $Package_count{$packler}; $Package_count{$packler} = 1;
           }          
          } 
        } # elsif version
        elsif (/^Architecture:/) {
           my $which_architecture = substr($_,14);
           chomp $which_architecture;
           if (!defined $warch{$packler}) {
              $warch{$packler} = $which_architecture; 
           }
           else {
              $warch{$packler} = $warch{$packler} . " $which_architecture";
           }
           # The assumption here is that there will never be two of the
           # same architecture along with different ones, rather in cases
           # where there are other archs, each will be unique, and where
           # there are two or more of the same arch, a genuine repeat has
           # occurred, this should cover the experimental dist.
           if (defined $not_me2{$packler}) {
            $arch =~ /-(.*)/; my $archi = $1;
            #print "$packler\n";
            foreach (split(/\s/,$warch{$packler})) {
                #print "$_\n";
               if ($_ eq $archi) {
                $arc{"$archi$packler"}++;
                #print  "$archi$packler\n";
               }
            }
            if (defined $arc{"$archi$packler"}) {
              if ($arc{"$archi$packler"} == 1) {
                 delete $not_me2{$packler};
              }
            }
           }
        } # elsif arch
      }
    close(PACKAGE);
    undef %warch; undef %Package_count; undef %not_me; 

   my @hu = keys %not_me2;
   print "REPEATS:" if $#hu != -1;
   for (keys %not_me2) {
   print " $_"; #print  " $_ $not_me2{$_}";
   }
   print "\n" if $#hu != -1;

    my %equalizer; $| = 1; my $x = 0;
    open(PRETTY, ">$format_deb");
    open(PACKAGE, "$argument");
      while (<PACKAGE>) {
       # Package name
        if (/^Package:|^PACKAGE:/) {                                              
          @package = split(/: /,$_);                                                  
          chomp $package[1];
          $x = 1 if $x == 6;                                                    
          print "|\r" if $x == 1 || $x == 4; print "/\r" if $x == 2;            
          print "-\r" if $x == 3 || $x == 6; print "\\\r" if $x == 5;           
          $x++; 
        } 
  # Some other pertinent fields
  # All this stuff can be placed together..since it is generally nice
  # to know these things at one glance, in this order.
  # Package:                    Status: (will check database if it exists ver.) 
  # Version:                    Essential: (yes or no)
  # Section:                    Priority:
  # Installed-Size:             Source: (if different from binary)
  # Size:                       Architecture:                
  # Maintainer:
  # Distribution: (stable, unstable, frozen, experimental - depending on
  #                version.  --latest_version will only keep highest ver.)
  # Description:

        elsif (/^Version:/) {
            $version = $_;
            chomp $version;
            my $vion = substr($version,9);
            my $pv = $package[1] . "_" . $vion; 
            if ($scount == 0) {
             $things = $pv;
            }
            else {
             $things = $things . " $pv";
            }
           $scount++;
        }
        elsif (/^Priority:/) {
            $priority = $_;
        }
        elsif (/^Section:/) {
            $section = $_;
            # make the hash for the groupindex.deb
            $group = substr($section,9);
            chomp $group;
              if (!defined $group{$group}) {
                  $group{$group} = $package[1];
                  #$nping->put($group,$package[1]);  
              }
              else {
                  $group{$group} = "$group{$group} $package[1]";
                  #$nping->put($group,"$group{$group} $package[1]");
              }
        }
        elsif (/^Essential:/) {
           @essential = split(/: /,$_); 
        }
        elsif (/^Maintainer:/) {
            $maintainer = $_;
        }

        # This stuff will be available with seperate query flags or -T
        elsif (/^Pre-Depends:/) {
            $pre_depends = $_;
              if (defined($pre_depends)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "PRE"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $pre_depends); 
              }
        }
        elsif (/^Depends:/) {
            $depends = $_;
              if (defined($depends)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "DEP"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $depends); 
              }
        }
        elsif (/^Recommends:/) {
            $recommends = $_;
              if (defined($recommends)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "REC"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $recommends); 
              }
        }
        elsif (/^Suggests:/) {
            $suggests = $_;
              if (defined($suggests)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "SUG"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $suggests); 
              }
        }
        elsif (/^Enhances:/) {
            $enhances = $_;
              if (defined($enhances)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "ENH"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $enhances); 
              }
        }
        elsif (/^Conflicts:/) {
            $conflicts = $_;
              if (defined($conflicts)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "CON"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $conflicts); 
              }
        }        
        elsif (/^Provides:/) {
            $provides = $_;
              if (defined($provides)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "PRO"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $provides); 
              }
        }         
        elsif (/^Replaces:/) {
            $replaces = $_;
              if (defined($replaces)) {
               my $vion = substr($version,9);
               my $nv = "$package[1]" . "_" . "$vion" . "REP"; 
               push(@REPLACE, "$nv");
               push(@REPLACE, $replaces); 
              }
         }
         # These next two determine whether to skip or keep the data.
         # Filename has the name of the distribution.
         ##############
         # ARCH CHECK #
         ############## 
         elsif (/^Architecture:/) {
            my $which_architecture = substr($_,14);
            chomp $which_architecture;
            $arch =~ /-(.*)/; my $archi = $1;
            ### REPEATERS ###
            my $vion = substr($version,9);
            if (defined $not_me2{$package[1]}) {
              if ($not_me2{$package[1]} ne $vion) {
               #print "Pack $package[1]\n";
               $which_architecture = "FUNNY";
              }
              else {
               $equalizer{$package[1]}++;
               # to with the same version
               if ($equalizer{$package[1]} > 1) {
                 $which_architecture = "FUNNY";
                 #print "$package[1] no need to do it again\n";
               }
              }
            }
            if ($which_architecture ne $archi) {  
             if ($which_architecture ne "all") {
               # erasure time
               ##########
               # GROUPS #
               ##########
               # This keeps the groupindex proper 
               undef $ok;
               (my $moggy = $package[1]) =~ s/\+/\\+/g;
               #print "$distro $group == ", $group{$group}, " == $package[1]\n";
               #print "$group -", $group{$group}, "\n";
               my $check = ($group{$group} =~ m,(^.*)\s$moggy$,);
               if ($check ne "") {
                #print "DIST $disti $1\n"; 
                $group{$group} = $1;
               }
               else {
                delete $group{$group};
               }
               ###########
               # REPLACE #
               ###########
               # this keeps deps correct
               if (defined $pre_depends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $pre_depends;
               }               
               if (defined $depends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $depends;        
               }               
               if (defined $recommends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $recommends;
               }               
               if (defined $suggests) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $suggests;
               }               
               if (defined $enhances) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $enhances;
               }               
               if (defined $conflicts) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $conflicts;
               }               
               if (defined $provides) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $provides
               }               
               if (defined $replaces) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $replaces;
               }               

               ########## 
               # STATUS #
               ##########
               my $vion = substr($version,9);
               $vion =~ s/\+/\\+/g;
               my $pv = $moggy . "_" . $vion; 
               my $scheck = ($things =~ m,(^.*)\s$pv$,);
               if ($scheck ne "") {
                $things = $1;
               }
               else {
                  $things = "";
               }
               ##print "$scheck $things\n\n";
                # some of these things don't need to be undefed because
                # they will be reset, because of the next.
                undef $priority if defined $priority;
                undef $section if defined $section;      
                undef $group if defined $group;
                undef @essential if @essential;
                undef $maintainer if defined $maintainer;
                # undef $version if defined $version;
                # undef @package if @package;
                ###print "GONE $package[1]\n";
                #print "$things\n";
                $goon = "yes";
                next;
             }  
             else {
               #print "HUMM $which_architecture && $archi $package[1]\n";
               undef $goon;
               #$ok = "yes";
             }
            } # wrong architecture
            else {
               undef $goon;
            }
         }

         #########################
         # DIST CHECK & FILENAME #
         #########################
         elsif (/^Filename:/ && !defined $goon) {
           chomp;
           $filename = $_;
            my @fields = split(/\//,$filename);
            $distro = $fields[1];
            my $archo;
            if (defined $fields[3]) {
             my $archos = $fields[3];
             #$archos =~ /^.*-(\w*)$/; 
             $archos =~ /^binary-([-\w]*)$/;
                $archo = $1;
            }
            else {
                # experimental looks like project/experimental/packagename_ver
                # so the architecture will be what is specified.  Right now,
                # the only architectures in experimental is i386 and all.
                # This makes sense because all is the goal of Debian.
                $arch =~ /-(.*)/; my $archi = $1;
                $archo = $archi;
            }          
            $dist =~ /-(.*)/; my $disti = $1;
            $arch =~ /-(.*)/; my $archi = $1;
            my($mainf, $contribf, $non_freef, $non_usf, $experimentalf);
           if (defined $fields[3]) {
             if (defined $main) {
              $mainf = "yes" if $fields[2] eq $main;
             }
             if (defined $contrib) {
              $contribf = "yes" if $fields[2] eq $contrib;
             }
             if (defined $non_free) {
              $non_freef = "yes" if $fields[2] eq $non_free;
             }
             if (defined $non_us) {
              $non_usf = "yes" if $fields[2] eq $non_us;
             }
           }
           # the distribution experimental has no sections.
           elsif ($fields[0] eq "Filename: project")  {
             $experimentalf = "yes" if $fields[1] eq "experimental";
           }
           #print "$filename && $distro && $archo && $fields[0]\n";
           #print "$disti -> $distro && $archi -> $archo\n";
           # project is experimental
           # will determine whether this is right distribution and whether
           # main, non-free, contrib, or non-us (not set up for traditional
           # packages file) have been requested.  options override the
           # default
           if ($disti eq $distro && $archi eq $archo && defined $mainf) {
             my $filen = substr($_,10);
             my $vion = substr($version,9);
             my $nv = "$package[1]" . "_" . "$vion" . "FN"; 
             push(@FILENAME, "$nv");
             push(@FILENAME, $filen); 
             $ok = "yes";
           }
           elsif ($disti eq $distro && $archi eq $archo && defined $contribf) {
             my $filen = substr($_,10);
             my $vion = substr($version,9);
             my $nv = "$package[1]" . "_" . "$vion" . "FN"; 
             push(@FILENAME, "$nv");
             push(@FILENAME, $filen); 
             $ok = "yes";
           }
           elsif ($disti eq $distro && $archi eq $archo && defined $non_freef) {
             my $filen = substr($_,10);
             my $vion = substr($version,9);
             my $nv = "$package[1]" . "_" . "$vion" . "FN"; 
             push(@FILENAME, "$nv");
             push(@FILENAME, $filen); 
             $ok = "yes";
           }
           elsif ($disti eq $distro && $archi eq $archo && defined $non_usf) {
             my $filen = substr($_,10);
             my $vion = substr($version,9);
             my $nv = "$package[1]" . "_" . "$vion" . "FN"; 
             push(@FILENAME, "$nv");
             push(@FILENAME, $filen); 
             $ok = "yes";
           }
           elsif ($disti eq $distro && $archi eq $archo 
                  && defined $experimentalf) {
             my $filen = substr($_,10);
             my $vion = substr($version,9);
             my $nv = "$package[1]" . "_" . "$vion" . "FN"; 
             push(@FILENAME, "$nv");
             push(@FILENAME, $filen); 
             $ok = "yes";
           }
           else {
             # erasure time
               ##########
               # GROUPS #
               ##########
               # This keeps the groupindex proper 
               undef $ok;
              # if (defined $package[1]) {
              #   $ppackage = $package[1];
              # }
               (my $moggy = $package[1]) =~ s/\+/\\+/g;
               ##print "$distro $group == ", $group{$group}, " == $package[1]";
               #print "$group -", $group{$group}, "\n";
               my $check = ($group{$group} =~ m,(^.*)\s$moggy$,);
               if ($check ne "") {
                #print "DIST $disti $1\n"; 
                $group{$group} = $1;
               }
               else {
                #print "JUST ONE", $group{$group}, "\n";
                delete $group{$group};
               }
              # if (defined $group{$group}) {
              # print "$check -> $group: ", $group{$group}, "\n";
              # }
              # print "\n";
               ###########
               # REPLACE #
               ###########
               # this keeps deps correct
               if (defined $pre_depends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $pre_depends;
               }               
               if (defined $depends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $depends;        
               }               
               if (defined $recommends) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $recommends;
               }               
               if (defined $suggests) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $suggests;
               }               
               if (defined $enhances) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $enhances;
               }               
               if (defined $conflicts) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $conflicts;
               }               
               if (defined $provides) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $provides
               }               
               if (defined $replaces) {
                  pop(@REPLACE); pop(@REPLACE);
                  undef $replaces;
               }               

               ########## 
               # STATUS #
               ##########
               my $vion = substr($version,9);
               $vion =~ s/\+/\\+/g;
               my $pv = $moggy . "_" . $vion; 
               my $scheck = ($things =~ m,(^.*)\s$pv$,);
               if ($scheck ne "") {
                $things = $1;
               }
               else {
                  $things = "";
               }
               ###print "$scheck $things\n\n";
                # some of these things don't need to be undefed because
                # they will be reset, because of the next.
                undef $priority if defined $priority;
                undef $section if defined $section ;      
                undef $group if defined $group;
                undef @essential if @essential;
                undef $maintainer if defined $maintainer;
                # undef $version if defined $version;
                # undef @package if @package;
                ###print "GONE $package[1]\n";
                #print "$things\n";
                next;
           } # wrong distribution
         }

       ############
       # ######## #
       # # MAIN # #
       # ######## #
       ############
       elsif (defined $ok) { 
         ##print "KEEP $package[1]\n";
         if (/^Size:/) {
           $size = $_;      
           chomp;
         }
         #  -qp --md5sum can do this
         # this part and the next work together for description.
         elsif (/^MD5sum/) {
           chomp;
           my $md5sum = substr($_,8);
           chomp $md5sum;
           my $vion = substr($version,9);
           my $nv = "$package[1]" . "_" . "$vion" . "MD"; 
           push(@MD5SUM, "$nv");
           push(@MD5SUM, $md5sum); 
         }

        # We only need to go on here if it is the right architecture and
        # distribution.
        # To be combined with first fields.  There are no packages
        # missing this field, unlike a status file. 
       # defined either at architecture or filename.
        elsif (m,Description:|^\s\w*|^\s\.\w*|^installed-size:|^revision:,){ 
          # this solved an annoying problem
          if (/^\n$/) {
                next;
           } 
           #print "$_  && $package[1]\n";
           chomp $version;
           $version =~ m,Version:\s(.*),; my $ending = $1;
           my $many_lines = $_;
           if ($_ !~ /^installed-size:|^revision:/) {
             $count++;
             if ($count == 1) {
               if (defined $package[1]) {
                 #push(@dpackage,"$package[1]_$ending");
                 push(@description,"$package[1]_$ending");
               }
             } 
               if (defined($many_lines)) {
               push(@ldescription,$many_lines);
               }
           } # end if ($_ !~ /^\n$/
           elsif ($_ =~ /^installed-size|^revision:/) {
             $count = 0;
             # let's put each description into one scalar
             my ($c, $cool);
              if ($#ldescription != 0) { 
                for ($c = $#ldescription; $c >= 0; $c--) {
                  if ($c > 0) {
                    $cool = $ldescription[$c-1] .= $ldescription[$c];   
                  }             
               } #end for
              }  # end if ($#ld
              else {
                $cool = $ldescription[0];
              }
              if (defined $cool) {
                 push(@description,$cool);
              } 
                 @ldescription = ();
           } # end else        
        } # end elsif Description 
     
        ####################################### 
        # installed-size: followed by source: #
        #######################################
        # if installed-size is at the end of Description, than source may
        # follow.  revision has been found once in the experimental 
        # distribution, but nothing was following it, this will have to be
        # watched because the order isn't known, and installed-size and source
        # will probably come into picture at some time.
        if (/^installed-size:/ || /^revision:/) {
            $installed_size = $_;
            my $next = <PACKAGE>;
         # source follows  
         if ($next =~ /^source:/) {
            $source = $next;
            chomp $source;
            chomp ($version, $section);
            $col1 = "Package: $package[1]";
             
           # status time   
           my $yep = exist_sb(\%commands);
           if (defined $yep) {
            my($different,$same);
            my $pname = $package[1];
            if (defined $sb{$pname}) {
              my ($vname,$gname,$priorname,$statusname) = 
              split(/\s/,"$sb{$pname}",4);
              $statusname =~ s/:/ /g;
              # a way to test
              #$version = "Version: 1:5.0-2";              
              my $pver = substr($version,9);
              my $cname = $pname . "_" . $pver;
              if ($vname eq $cname) {
               $status = "Status: $statusname\n";
               $same = "yes"; undef($different);
              }
              else {
               # here's where we get to do some comparisons
               # we will have to compare sections. 1). may have changed
               # 2). may be an unfair comparison free vs non-free, on the
               # other-hand this should be in the person's awareness
               # making the check.  1) will provide the answer to both.  
               $vname =~ m,^.*_(.*)$,;
               my $ever = $1;
               # print "$pname:  $pver && $ever\n";
               # $pver = new $ever = installed
               my $oper = comparison($pver,$ever); 
               compare_versions($oper,$pver,$ever,$pname,\%commands) 
               if $commands->{"v"};
               $status = 
               "Status: " . $oper . " $statusname ($ever)\n";
               $different = "yes"; undef($same);  
              }
            }
            else {
              $status = "Status: not-installed\n";
            }
            $col2 = $status;
            untie %sb;
           }
           else {
            $col2 = "Status: not-installed\n";
           }
            write PRETTY;
            $col1 = $version;
             $version =~ m,Version:\s(.*),;         
             # This creates a name -> version index in package.deb,
             # and the statusindex.deb database which will serve to
             #  determine if the status has changed when  --db or -i is
             # ran.
             push(@name, $package[1]);
             push(@status, $package[1]);
             $package[1] = "$package[1]_$1";
             push(@name, $package[1]);
             my $priory = substr($priority,10);
             chomp $priory;
             my $thimk = "$package[1] $group $priory";
             push(@status, $thimk);
            if(defined($essential[1])) {              
             $col2 = "Essential: $essential[1]";
             @essential = ();
            }
            else {
              $col2 = "Essential: no\n";
            }
            write PRETTY;
            $col1 = $section;
            $col2 = $priority;
            write PRETTY;
            #my $cool = $installed_size . $maintainer;
            my $einstalled_size = substr($installed_size,16);
            chomp $einstalled_size;
            $col1 = "Installed-Size: $einstalled_size";
            if (defined $source) {
              my $esource = substr($source,8);
              $col2 = "Source: $esource";
            }
            else {
              $col2 = "";
            } 
            write PRETTY;
            undef $source;
            $col1 = $size;
            $col2 = "Architecture: $architecture\n";
            write PRETTY;           
            if ($distro ne "experimental") {
              $filename =~ m,^Filename: dists\/(\w*)\/.*$,;
              print PRETTY "Distribution: $1\n";
              print PRETTY $maintainer
            }
            else {
              my $exp_dist = "experimental";
              print PRETTY "Distribution: $exp_dist\n";
              print PRETTY $maintainer
            }
         } # if $next =~ source


         ##############################################
         # installed-size: or revision: by themselves #
         ##############################################
         # source doesn't follow
         elsif ($next =~ /^\n$/) {
            chomp($version, $section);
            $col1 = "Package: $package[1]";

           # revision magic
           if (/revision:/) {
            $filename =~ m,.*/(.*)\.deb$,;
            my $rr  = $1 . "MD";
            my $rver = substr($version,9); 
            my $prr = $package[1] . "_"  . "$rver" . "MD REVISION";
            push(@revision,$rr); push(@revision,$prr);  
           }
   
           # status time   
           my $yep = exist_sb(\%commands);
           if (defined $yep) {
            my($different,$same);
            my $pname = $package[1];
            if (defined $sb{$pname}) {
              my ($vname,$gname,$priorname,$statusname) = 
              split(/\s/,"$sb{$pname}",4);
              $statusname =~ s/:/ /g;
              # a way to test
              #$version = "Version: 1:5.0-2";              
              my $pver = substr($version,9); 
              my $cname = $pname . "_" . $pver; 
              if ($vname eq $cname) {
               $status = "Status: $statusname\n";
               $same = "yes"; undef($different);
              }
              else {
               # here's where we get to do some comparisons
               # we will have to compare sections. 1). may have changed
               # 2). may be an unfair comparison free vs non-free, on the
               # other-hand this should be in the person's awareness
               # making the check.  1) will provide the answer to both.  
               $vname =~ m,^.*_(.*)$,;
               my $ever = $1;
               # print "$pname:  $pver && $ever\n";
               # $pver = new $ever = installed
               my $oper = comparison($pver,$ever); 
               compare_versions($oper,$pver,$ever,$pname,\%commands) 
               if $commands->{"v"};
               $status = 
               "Status: " . $oper . " $statusname ($ever)\n";
               $different = "yes"; undef($same);  
              }
            }
            else {
              $status = "Status: not-installed\n";
            }
            $col2 = $status;
            untie %sb;
           } # if defined $yep
           else {
            $col2 = "Status: not-installed\n";
           }
            write PRETTY;
            $col1 = $version;
             $version =~ m,Version:\s(.*),;         
             # This creates a name -> version index in package.deb,
             # and the statusindex.deb database which will serve to
             #  determine if the status has changed when  --db or -i is
             # ran.
             push(@name, $package[1]);
             push(@status, $package[1]);
             $package[1] = "$package[1]_$1";
             push(@name, $package[1]);
             my $priory = substr($priority,10);
             chomp $priory;
             my $thimk = "$package[1] $group $priory";
             push(@status, $thimk);
            if(defined($essential[1])) {              
             $col2 = "Essential: $essential[1]";
             @essential = ();
            }
            else {
              $col2 = "Essential: no\n";
            }
            write PRETTY;
            $col1 = $section;
            $col2 = $priority;
            write PRETTY;
            #my $cool = $installed_size . $maintainer;
            my $einstalled_size = substr($installed_size,16);
            chomp $einstalled_size;
            $col1 = "Installed-Size: $einstalled_size";
            if (defined $source) {
              my $esource = substr($source,8);
              $col2 = "Source: $esource";
            }
            else {
              $col2 = "";
            } 
            write PRETTY;
            undef $source;
            $col1 = $size;
            $col2 = "Architecture: $architecture\n";
            write PRETTY;
            if ($distro ne "experimental") {
              $filename =~ m,^Filename: dists\/(\w*)\/.*$,;
              print PRETTY "Distribution: $1\n";
              print PRETTY $maintainer
            }
            else {
              my $exp_dist = "experimental";
              print PRETTY "Distribution: $exp_dist\n";
              print PRETTY $maintainer
            }
         } # if $next =~ source
       } # elsif installed-size
      } # right arch and dist
      } # end while (<PACKAGE>)
      close(PRETTY);

  # Let's put together the description with the rest of its fields.
  open(FIELDS,"$format_deb");
  while (<FIELDS>) {
     push(@form,$_);
  }
  close(FIELDS);  

  $count = 0;  

  foreach (@form) {
    push(@formly,$_);    
    my ($cool);
    $count++;  
    if ($count == 7) {
             my ($c, $cool);
              if ($#formly != 0) { 
                for ($c = $#formly; $c >= 0; $c--) {
                  if ($c > 0) {
                    $cool = $formly[$c-1] .= $formly[$c];   
                  }             
               } #end for
              }  # end if ($#ld
              else {
                $cool = $formly[0];
              }
   push(@complete,$cool);
    @formly = ();
    $count = 0;
    }
  }
  
  foreach (@description) {
   if ($count == 1) {
     my $lingo = shift(@complete);
     $lingo = $lingo . $_;
     push(@Tdescription, $lingo); 
     $lingo = ();
     $count = 1;
   }
   else {
     push(@Tdescription, $_); 
     $count = 0;
   }
   $count++;

 }

   unlink($format_deb);

   #untie $nping;
   #undef %ngdb;

  # We'll keep databases local so that md() doesn't get confused with
  # database().

  # Put the groups into the groupindex.deb database.
  print "Not-installed Group Database is being made\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     tie %ngb, 'DB_File', "$main::home$parent$library/ngroupindex$arch$dist.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    tie %ngb, 'DB_File', "$main::home$parent$base/ngroupindex$arch$dist.deb" or die "DB_File: $!";
  }

  # assigning to HUMM solves a strange problem.  semi-panic: attempt to dup
  # freed string..internal newSVsv() routine was caused to duplicate a
  # scalar that had been previously marked as free.
  my @HUMM = %group;
  %ngb = @HUMM;
  untie %ngb;
  undef %ngb;	
  undef %group;
  undef @HUMM;

  # Create the important status database.
  print "Not-installed Status Database is being made\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
        tie %nsb, 'DB_File', "$main::home$parent$library/nstatusindex$arch$dist.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
        tie %nsb, 'DB_File', "$main::home$parent$base/nstatusindex$arch$dist.deb" or die "DB_File: $!";
  }

  push(@status,"/.");
  if ($things =~ /^\s.*/) {
    $things =~ s/^\s//;
  }
  push(@status,$things);
  %nsb = @status;

  untie %nsb;
  undef %nsb;
  undef @status;
  undef $scount;

  # Put everything into the package.deb database.
  print "Not-installed Description Database is being made\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     tie %ndb, 'DB_File', "$main::home$parent$library/npackages$arch$dist.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     tie %ndb, 'DB_File', "$main::home$parent$base/npackages$arch$dist.deb" or die "DB_File: $!";
  }

  %ndb = (@name,@Tdescription,@conf,@REPLACE,@FILENAME,@MD5SUM,@revision);
  untie %ndb;
  undef @Tdescription;
  undef @conf; 
  undef @REPLACE;
  undef @FILENAME;
  undef @MD5SUM;
  undef @revision;
  undef %ndb;

  print scalar(localtime), "\n" if !$commands->{"Contents"};  


} # ends sub not_installed


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


sub sb {

  my ($commands) = @_;

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

# This creates the file filedir.deb using using the program longswim.  The
# options --main, --contrib, non-free, non-us, or the default value is
# taken into consideration.
sub nmd {

  my ($Contents,$commands) = @_;
  my %commands = %$commands;
  my ($dbpath, $root);

  my ($main,$contrib,$non_free,$non_us);  
  $main = "yes" if $commands->{"main"};
  $contrib = "yes" if $commands->{"contrib"};
  $non_free = "yes" if $commands->{"non-free"};
  $non_us = "yes" if $commands->{"non-us"};
  if (!defined $main && !defined $contrib && !defined $non_free &&
      !defined $non_us) {
     foreach (@user_defined_section) {
        if ($_ eq "main") {
          $main = "yes";
        }
        elsif ($_ eq "contrib") {
          $contrib = "yes";
        } 
        elsif ($_ eq "non-free") {
          $non_free = "yes";
        }
        elsif ($_ eq "non-us") {
          $non_us = "yes";
        }
     }
  }

   $main = "no" if !defined($main);
   $contrib = "no" if !defined($contrib);
   $non_free = "no" if !defined($non_free);
   $non_us = "no" if !defined($non_us);

    my $Contents_mtime = (stat($Contents))[9];
    $Contents = -B $Contents || $Contents =~ m,\.(gz|Z)$, ? 
                 "$gzip -dc $Contents|" : "cat $Contents|";
    my $contentsdb = finddb(\%commands);
    my($arch,$dist) = which_archdist(\%commands);
    my $contentsindex = "$contentsdb/ncontentsindex$arch$dist.deb";
    my $npackages = "$contentsdb/npackages$arch$dist.deb"; 

  print "Gathering the file(s)/dir(s) for the arch-dist section(s)\n";

  #     0            1          2       3        4         5      6
  system "$longswim",
  $Contents, $contentsindex, $main, $contrib, $non_free, $non_us, $tmp,
  $npackages, $gzip, $contentsdb, $Contents_mtime;

  # longswim can be tested with something like this:
  # /usr/lib/SWIM/longswim.alt "cat /USE/Contents|" \
  # /test/ncontentsindex-i386-unstable.deb yes yes yes yes \
  # /test /USE/npackages-i386-unstable.deb  gzip /test 11111111

} # end sub nmd





1;
