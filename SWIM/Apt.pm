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

package SWIM::Apt;
use strict;
use SWIM::Conf;
use vars qw(@ISA @EXPORT_OK);
use Net::FTP;
use SWIM::Library qw(which_archdist);
use SWIM::F;
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(apt ftp);



# this module hands major modes --apt and --ftp

=pod

install is integrated virtually with -q,--search.  update allows the
Packages to be upgraded, and these can be used by initndb, rebuildndb and
ndb. apt appears to run a check every time it runs, so check won't be
included for now.  -d, -download-only is better done by using virtual ftp,
the package(s) can be temporarily flipped into apts domain for
installation. Other than update and clean, upgrade and dist-upgrade are
included with -xyz for control and to avoid unwanted actions.  There are
also the interesting aspects of apt-cache, but this won't be included
presently. 

=cut


sub apt {


 my ($apt_get,$sources,$commands) = @_;
 my %commands = %$commands;
 my @FTP; 


  if ($commands->{"apt"}) {

     ################
     # UPDATE CLEAN #
     ################ 
     # error correcting and handle --update && --clean
     if ($commands->{"update"} &&
        !($commands->{"upgrade"} || $commands->{"dist_upgrade"} ||
        $commands->{"x"} || $commands->{"y"} || $commands->{"z"})) {
         if ($commands->{"update"}) { 
           system "$apt_get update";
           if ($commands->{"clean"}) {
             system "$apt_get clean";
           }
           elsif ($commands->{"autoclean"}) {
             system "$apt_get autoclean";
           }
           if ($commands->{"check"}) {
              system "$apt_get check";
           }
         }
     }
     elsif ($commands->{"clean"} && !($commands->{"upgrade"} ||
         $commands->{"dist_upgrade"} || $commands->{"x"} || $commands->{"y"} 
         || $commands->{"z"} || $commands->{"updatenr"})) {
             system "$apt_get clean";
           if ($commands->{"check"}) {
              system "$apt_get check";
           }
     }
     elsif ($commands->{"autoclean"} && !($commands->{"upgrade"} ||
         $commands->{"dist_upgrade"} || $commands->{"x"} || $commands->{"y"} 
         || $commands->{"z"} || $commands->{"updatenr"})) {
             system "$apt_get autoclean";
           if ($commands->{"check"}) {
              system "$apt_get check";
           }
     }
     elsif ($commands->{"check"} && !($commands->{"upgrade"} ||
         $commands->{"dist_upgrade"} || $commands->{"x"} || $commands->{"y"} 
         || $commands->{"z"} || $commands->{"updatenr"})) {
             system "$apt_get check";
     }
     elsif ($commands->{"clean"} || $commands->{"update"}) {
         print "swim: --update cannot be used with option";
         print " --upgrade" if $commands->{"upgrade"};
         print " --dist_upgrade" if $commands->{"dist_upgrade"};
         print " -x" if $commands->{"x"};
         print " -y" if $commands->{"y"};
         print " -z" if $commands->{"z"};
         print "\n";
         exit;
     }

 
     ########################
     # UPGRADE DIST_UPGRADE #
     ########################
     if ($commands->{"upgrade"} || $commands->{"dist_upgrade"} ||
         $commands->{"x"} || $commands->{"y"} || $commands->{"z"} &&
         !($commands->{"update"} || $commands->{"clean"})) {
          if ($commands->{"upgrade"} && $commands->{"dist_upgrade"}) {
            print "swim: do not use --upgrade and --dist_upgrade together\n";
            exit;
          }
          if (($commands->{"upgrade"} || $commands->{"dist_upgrade"}) &&
              !$commands->{"x"}) {
              if ($commands->{"y"} || $commands->{"z"}) {
                 print "swim: ";
                 print "-";
                 print "y" if $commands->{"y"}; 
                 print "z" if $commands->{"z"};
                 print " require -x\n";
                 exit;
              }
              print "swim: ";
              print "--upgrade" if $commands->{"upgrade"};
              print "--dist_upgrade" if $commands->{"dist_upgrade"};
              print " require at least -x\n"; 
              exit;
          }
 
         #################
         # SAFETY  CHECK #
         #################
         if ($commands->{"upgrade"} || $commands->{"dist_upgrade"}) {
          if ($commands->{"z"}) {
           print "swim:  you are about to install with ";
           print "--upgrade" if $commands->{"upgrade"};
           print "--dist_upgrade" if $commands->{"dist_upgrade"};
           print "\n";
           print "swim: are you sure you want to go on? (yes or no): ";   
           while (<STDIN>) {
             last if $_ eq "yes\n";
             exit if $_ eq "no\n";
             if ($_ eq "\n" || $_ ne "yes\n" || $_ ne "no\n") {
                print "swim: please enter yes or no: ";
             } 
           }
          }
         }
         else {
           print "swim: no options for --apt specified\n";
           exit;
         }

          my $upgrade; 
          if ($commands->{"upgrade"} || $commands->{"dist_upgrade"}) {
             $upgrade = "upgrade" if $commands->{"upgrade"};
             $upgrade = "dist-upgrade" if $commands->{"dist_upgrade"};

            if ($commands->{"x"} && !($commands->{"y"} || $commands->{"z"})) {
               system "$apt_get $upgrade -qs --ignore-hold";
            }
            elsif ($commands->{"y"} && ! $commands->{"z"}) {
               print "swim: use -y with -z\n";
               exit;
            }
            elsif ($commands->{"y"} && $commands->{"z"}) {
               system "$apt_get $upgrade -yq --ignore-hold";
            }
            elsif ($commands->{"z"} && !$commands->{"y"}) {
               system "$apt_get $upgrade -q --ignore-hold";
            }

          }
         
     } # end upgrade dist_upgrade

  } # if apt



} # end sub apt 



=pod

Packages and Contents files can be acquired in several fashions.  If apt
is installed on the system, Packages files can automatically be derived
and ordered according to the dist for the particular architecture being
used on the computer system, but other architectures aren't represented.
Hence the ftp method is provided.  This uses information from the
configuration file to update the Contents and Packages file.  Contents
file is updated according to distribution and architecture, and Packages
file is updated according to distribution, architecture and section.  Both
are renamed appropriately and put into the default directory specified by
the configuration file, in fact the same naming structure that apt uses is
used. 

If only one architecture and one distribution are wanted they can be specified
from the command line overridding the defaults in the conf, but if one is
specified, it is assumed the other is also the default value, basically the
conf values are totally overridden, except for the sites.  Likewise the
sections --main, --non-free etc., can also be used to override the defaults..so
use with care since all sites will be visited.  Otherwise everything found in
the conf file for --Contents and/or --Packages is downloaded from an available
ftp site.  The syntax in the conf file is exactly the same as apt's
sources.list file, except that deb can have a hyphen appended and a name of an
architecture (ex: deb-alpha), deb will be the architecture of the local machine
found with dpkg --print-installation-architecture if a hyphen isn't used.  The
ftp, and file method will both be supported at this time, although the cdrom
will need the dist directory for file.

All the sites are visted, and the databases are downloaded. Although the
goal of swim is to have the newest databases, a person may want to
download older or newer databases, so when initndb, rebuildndb, or ndb are
run, swim will interact with a person and allow them to decide which
database to use, this applies to DF,FDBDF, and APT.  If -y is specified
swim will use the newest databases.  Swim will also check that the
databases actually exist.  Also the DF (default directory and naming)
directory can be overridden by specifing an alternative directory on the
command line, the databases will still be named though.  If --ftp is
specified without any options..everything in the conf file is downloaded,
renamed and put into the default directory.  The advantage of the default
directory is that is can be found by --initndb, --rebuildndb, and --ndb.
People with apt will only need to specify "swim --ftp --Contents DF", and
swim --apt --update, and then for instance ... swim --initndb APT
--Contents DF.

=cut 
sub ftp {

   my ($commands) = @_;
   my %commands = %$commands;

   # Let's find the architecture for the local system, so we know what deb
   # is.  If dpkg is installed we might as well just use it to find the arch
   # otherwise "gcc --print-libgcc-file-name" with a lookup using 
   # information from the archtable found in apt.
   my (@deb,$deb); 
   if (defined $dpkg) {
    system "$dpkg --print-installation-architecture > $tmp/arch.deb";
    open(ARCH, "$tmp/arch.deb") or warn "couldn't find arch\n";
    my @deb = <ARCH>; chomp $deb[0];
    $deb = $deb[0];
   }
   else { 
    if (defined $gcc) {
     my %table = qw(i386 i386 i486 i386 i586 i386 i686 i386 pentium i386
                    sparc sparc alpha alpha m68k m68k arm arm powerpc
                    powerpc ppc powerpc);
     system "$gcc --print-libgcc-file-name > $tmp/arch";
     open(AR,"$tmp/arch") or warn "could not find the arch file\n";
      my @argcc; 
      while(<AR>) {
         @argcc = split(/-/,$_);       
       }    
     close(AR);
     my ($argcc, $arc);
     # this works fine for Debian, but RH has three dashes .. its probably
     # safe to say its at $argcc[1], but why be too sure?
     #$argcc = (split(m,/,,$argcc[$#argcc - 1]))[1];
     for $arc (0 .. $#argcc) {
      $argcc = (split(m,/,,$argcc[$arc]))[1];
      if (defined $table{$argcc}) {
        $deb = $table{$argcc};
        last;
      }     
      elsif ($arc == $#argcc) {
        print "swim: mis-read your machines architecture\n";
	exit;
      }
     }
    }
    else {
     print "swim: will not have much swim fun without gcc\n";
     exit;
    }
   } 

   # Check if there is a sources.list specified
   if (-e "$swim_conf/swimz.list") {
     undef @FTP;
     open(SOURCES,"$swim_conf/swimz.list")
     or warn "swim: could not find swimz.list\n";
       while (<SOURCES>) {
         if ($_ !~ m,#.*|^\s+,) {
            chomp; push(@FTP,$_);
         }     
       }     
      if ($#FTP == -1) { 
       print "swim: no sites specified in swimz.list, quiting\n"; 
       exit;
      }
   }

   # might as well check for a temporary directory for downloads, if it
   # doesn't exist create it.
   mkdir("$default_directory/partial",$permission) 
   if !-d "$default_directory/partial";


   # Let's breakup @FTP, and check for ftp or the file method and
   # provide support for:
   # deb ftp://nonus.debian.org/debian-non-US unstable/binary-i386/ .. although
   # ftp://nonus.debian.org/debian-non-US unstable non-US will work, 
   # ftp://ftp.debian.org/debian project/experimental is the only way to get
   # the experimental distribution.  This situation exists because non-us is
   # essentially a section like contrib in Europe, but it is separated from the
   # US distribution.  Experimental is a distribution unto itself and has
   # no symlinks from dists.
   # And add the appropriate symlinks for non-us

   my($arc,$dists) = which_archdist(\%commands);
   $arc =~ s,-,,; $dists =~ s,-,,;
   if ($commands->{"dists"} || $commands->{"arch"}) {
     $dists = $commands->{"dists"} if defined $commands->{"dists"};
     $arc = $commands->{"arch"} if defined  $commands->{"arch"};
   }
   my %site; my @PLACES; my %plw;
   foreach (@FTP) {
     ################
     # USER DEFINED #
     ################
     # For --dists and --arch just filter out what isn't wanted, sections
     # can be adjusted in swimz.list.
       if (defined $dists) {
        if ((split(/\s/,$_))[2] =~ /\b$dists\b/) {
           if (defined $arc) {
            if ((split(/\s/,$_))[0] eq "deb") {
              if ($deb ne $arc) {
                next;
              }
            }
            elsif ((split(/\s/,$_))[0] !~ /$arc/) {
              next;
            }
           }
        }
        if ((split(/\s/,$_))[2] !~ /\b$dists\b/) {
            next;
        } 
       }
       elsif (defined $arc) {
        if ((split(/\s/,$_))[0] eq "deb") {
          if ($deb ne $arc) {
             next;
           }
        }
        elsif ((split(/\s/,$_))[0] !~ /$arc/) {
           next;
        }
       }
       else {
        next;
       }
     #}
     ######################
     # CONFIGURATION FILE #
     ######################

      my @parts = split(' ', $_);
      # keep things seqential
      $parts[1] =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
      $plw{$1}++; push(@PLACES,$1) if $plw{$1} == 1;
      if ($parts[1] =~ m,^ftp,i) {
        my $count = 3;        
        if ($parts[0] !~ /-/) {
           $parts[0] = $deb;           
           # singlulars
           if ($#parts == 2) {
             $parts[2] =~ m,(.*/.*)/$,;
             my $sdist = "$1";
             $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
             my $place = $1;
             $site{$place}{"$parts[1]!!!!!$deb"}{$sdist}{"single"} =
             $deb;
           }
           else {
            # construct a nice structure
            for (3  .. $#parts) {
              # each site site!!arch -> distributions -> sections  = archs
             $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
             my $place = $1;
              $site{$place}{"$parts[1]!!!!!$deb"}{$parts[2]}{$parts[$count]}
              = $parts[0];
              $count++;
            }
           }
        } 
        else {
            $parts[0] =~ m,^deb-(.*)$,;
            $parts[0] = $1;
           # singlulars experimental
           if ($#parts == 2) {
             $parts[2] =~ m,(.*/.*)/$,;
             my $sdist = "$1";
             $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
             my $place = $1;
             $site{$place}{"$parts[1]!!!!!$parts[0]"}{$sdist}{"single"} =
             $deb;
           }
           else {
            # construct a nice structure
            my $count = 3;
            for (3  .. $#parts) {
              $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
              my $place = $1;
              $site{$place}{"$parts[1]!!!!!$parts[0]"}{$parts[2]}{$parts[$count]} =
              $parts[0];
              $count++;
            }
           }
        }       
      } # ne ftp|http
   } # foreach conf line


   #######
   # FTP #
   #######
   # Now we can ftp to each unique site, and decide whether to go on or
   # not.  If local mtime is the same nothing is downloaded, otherwise if
   # local mtime is less than remote mtime or nothing exists, download will
   # occur.
   my ($the_site,$site,$dist,$section,$arch,$ftp,%complete);
   my $distbase; my $cc = 0;
   foreach $the_site (@PLACES) {

       # will provide all kinds of options for ftp..like firewall
       $ftp = Net::FTP->new($the_site,
                            Debug => $debug,
                            Timeout => $timeout,  
                            Passive => $passive,
                            Firewall => $firewall,
                            Port => $port
                            );

       ###########
       # CONNECT #
       ###########
       if (defined $ftp) {
        my $connected = $ftp->code();
        if ($connected == 220) {
         print "swim: connected to $the_site\n";
        }
       }
       else {
         print "swim: could not find $the_site\n";
         next;
       }

       #########
       # LOGIN #
       #########
       $ftp->login("anonymous","swim\@the.netpedia.net");
       my $logged  = $ftp->code();
       # we are logged, but what is the time difference.
       if ($logged == 230 || $logged == 332) {
         print "swim: logged in to $the_site\n";
         $ftp->binary;
       }
       else {
        # 530 "not logged in" will have to test this
        $ftp->code();
        print "swim: not logged in to $the_site\n";
        next;
       }

    ###################
    # LOOP SITE ARCHS #
    ###################
    foreach $site (keys %{ $site{$the_site} } ) {

      ##################
      # GET THE THINGS #
      ##################
      foreach $dist (keys %{ $site{$the_site}{$site} } ) {
      # We can look for Contents now for each distribution if Contents was
      # specified.
         

       (my $tsite = $site) =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
       $distbase = $2;
       my ($distbe,$distb);
       ($distbe,$arch) = (split(/!!!!!/,$distbase))[0,1]; 
       $distbase = (split(/!/,$distbase))[0];
       my @distb = split(m,/,,$distbe);
       
        for (1 .. $#distb) {
          if ($_ == 1) {
              $distb = $distb[$_];
          }
          else {
              $distb = $distb . "_" .$distb[$_];
          }
        } 

       # figure out experimental's name
       if ($dist =~ /experimental/) {
        my @dist = split(m,/,,$dist);
        my $ddist;
        $dist =~ m,^.*/(.*)$,;
        for (0 .. $#dist) {
          if ($_ == 0) {
              $ddist = $dist[$_];
          }
          else {
              $ddist = $ddist . "_" . $dist[$_];
          }
        } 
        $distb = $distb . "_" . $ddist;
       }
           

           ##############          
           # --CONTENTS #
           ##############
           my @distg = split(m,/,,$dist);
           my $Go_on;
           if (defined $commands->{"Contents"} && 
               !defined $commands->{"Release_only"}) {            
           if ($cc < 1) {
            if ($commands->{"Contents"} eq "DF") {
              # watch for undefined values here when conf file only refers
              # to a non-standard dist.
              my $localfile = "$default_directory/partial/$the_site" . "_" .
              "$distb" . "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              my $main::home = "$default_directory/$the_site" . "_" . "$distb" .
              "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              if (-e "$main::home") {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my ($lmtime) = (stat($main::home))[9];
                my $file_exist = $ftp->code();
                print "swim: $distg[0]/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550  && $distbase !~ /non-US/ && 
                $distg[0] !~ /project/;        
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  print "swim: downloading $dist/Contents-$arch.gz ($size)\n"; 
                 get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  if ($lsize == $size && $complete == 226) {
                    print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                    $cc++ if $commands->{"onec"};
                    rename("$localfile","$main::home")
                    or system "$mv", "$localfile", "$main::home"; 
                  }
                  else {
                    print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                  }
                  utime(time,$rmtime,$main::home); 
                }
                elsif ($lmtime == $rmtime) {
                  $cc++ if $commands->{"onec"};
                }
              }
              else {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my $file_exist = $ftp->code();
                print "swim: $distg[0]/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550  && $distbase !~ /non-US/ &&        
                $distg[0] !~ /project/;        
                if ($file_exist != 550) { 
                 print "swim: downloading $dist/Contents-$arch.gz ($size)\n";
                get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                 my $complete = $ftp->code();          
                 my $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226) {
                   print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                   $cc++ if $commands->{"onec"};
                   rename("$localfile","$main::home")
                   or system "$mv", "$localfile", "$main::home"; 
                 }
                 else {
                   print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                 }
                 if (-e $main::home) {
                  utime(time,$rmtime,$main::home); 
                 }  
                }
              }
            }
            elsif ($commands->{"Contents"} ne "DF") {
              my $place = $commands->{"Contents"};
              make_dir($place);
              my $localfile = "$default_directory/partial/$the_site" . "_" .
              "$distb" . "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              my $main::home = "$place/$the_site" . "_" . "$distb" .
              "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              if (-e "$main::home") {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my ($lmtime) = (stat($main::home))[9];
                my $file_exist = $ftp->code();
                print "swim: $distg[0]/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550  && $distbase !~ /non-US/ &&        
                $distg[0] !~ /project/;        
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  print "swim: downloading $dist/Contents-$arch.gz ($size)\n";
                 get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  if ($lsize == $size && $complete == 226) {
                    print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                    $cc++ if $commands->{"onec"};
                    rename("$localfile","$main::home")
                    or system "$mv", "$localfile", "$main::home"; 
                  }
                  else {
                    print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                  }
                  utime(time,$rmtime,$main::home); 
                }
                else {
                  $cc++ if $commands->{"onec"};
                }
              }
              else {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my $file_exist = $ftp->code();
                print "swim: $distg[0]/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550  && $distbase !~ /non-US/ &&        
                $distg[0] !~ /project/;        
                if ($file_exist != 550) {
                 print "swim: downloading $dist/Contents-$arch.gz ($size)\n";
                 get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                 my $complete = $ftp->code();          
                 my $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226) {
                   print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                   $cc++ if $commands->{"onec"};
                   rename("$localfile","$main::home")
                   or system "$mv", "$localfile", "$main::home"; 
                 }
                 else {
                   print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                 }
                 if (-e $main::home) {
                   utime(time,$rmtime,$main::home); 
                 }
                }
              }
            }
           $Go_on = "yes";
           } # if only 1 Contents wanted
           } # if defined Contents 

           ################################
           # NOT --CONTENTS && --PACKAGES #
           ################################
           if (!defined $commands->{"Contents"} && 
               !defined $commands->{"Packages"} && 
               !defined $commands->{"Release_only"}) {  
              my $localfile = "$default_directory/partial/$the_site" . "_" .
              "$distb" . "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              my $main::home = "$default_directory/$the_site" . "_" . "$distb" .
              "_dists_" . "$dist" . "_" . "Contents-$arch.gz";
              if (-e "$main::home") {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my ($lmtime) = (stat($main::home))[9];
                my $file_exist = $ftp->code();
                print "swim: $dist/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550 && $distbase !~ /non-US/ &&        
                $distg[0] !~ /project/;        
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  print "swim: downloading $dist/Contents-$arch.gz ($size)\n";
                 get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  if ($lsize == $size && $complete == 226) {
                    print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                    $cc++ if $commands->{"onec"};
                    rename("$localfile","$main::home")
                    or system "$mv", "$localfile", "$main::home"; 
                  }
                  else {
                    print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                  }
                  utime(time,$rmtime,$main::home); 
                }
                else {
                  $cc++ if $commands->{"onec"};
                }
              }
              else {
                my $size =
                $ftp->size("$distbase/dists/$dist/Contents-$arch.gz");
                my $rmtime =
                $ftp->mdtm("$distbase/dists/$dist/Contents-$arch.gz");
                my $file_exist = $ftp->code();
                print "swim: $distg[0]/Contents-$arch.gz does not exist on the server\n" 
                if $file_exist == 550 && $distbase !~ /non-US/ &&        
                $distg[0] !~ /project/;        
                if ($file_exist != 550) {
                 print "swim: downloading $dist/Contents-$arch.gz ($size)\n";
                 get($ftp,"$distbase/dists/$dist/Contents-$arch.gz",$localfile);
                 my $complete = $ftp->code();          
                 my $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226) {
                   print "swim: successful retrieval of $dist/Contents-$arch.gz\n"; 
                   $cc++ if $commands->{"onec"};
                   rename("$localfile","$main::home")
                   or system "$mv", "$localfile", "$main::home"; 
                 }
                 else {
                   print "swim: unsuccessful retrieval of $dist/Contents-$arch.gz\n"; 
                 }
                 if (-e $main::home) {
                   utime(time,$rmtime,$main::home); 
                 } 
                }
              }
           } # if !defined Contents && Packages 

       foreach $section (keys %{ $site{$the_site}{$site}{$dist} } ) {
           my $sectcount = 0; 
           $arch = $site{$the_site}{$site}{$dist}{$section};

           ##############
           # --PACKAGES #
           ##############
           if (defined $commands->{"Packages"}) {  
            if ($commands->{"Packages"} eq "DF") {
              my ($main::home,$localfile,$release_home,$release_localfile);
              my $nue = (split(m,/,,$dist))[0];
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($main::home = 
                  "$default_directory/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($main::home = 
                    "$default_directory/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($main::home = 
                    "$default_directory/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($localfile = 
                  "$default_directory/partial/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($localfile = 
                    "$default_directory/partial/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($localfile = 
                    "$default_directory/partial/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
                ($release_home = $main::home) =~ s,Packages.gz,Release,;
                ($release_localfile = $localfile) =~ s,Packages.gz,Release,;
              if (-e "$main::home") {
                my ($lmtime) = (stat($main::home))[9];
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $size = $ftp->size("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);
                next if $file_exist == 550;
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  download($file_exist,$section,$arch,$dist,$distb,$size);
                  get($ftp,$remotefile,$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  two26($complete,$size,$lsize,$main::home,$localfile,
                        $section,$arch,$dist,$distb); 
                  utime(time,$rmtime,$main::home); 
                }
              }
              else {
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $size = $ftp->size("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);
                next if $file_exist == 550;
                download($file_exist,$section,$arch,$dist,$distb,$size);
                get($ftp,$remotefile,$localfile); 
                my $complete = $ftp->code();          
                my $lsize = (stat($localfile))[7];
                two26($complete,$size,$lsize,$main::home,$localfile,
                      $section,$arch,$dist,$distb); 
                if (-e $main::home) {
                  utime(time,$rmtime,$main::home); 
                } 
              }
              ###########
              # RELEASE #
              ###########
              # this will not be very verbose
              if ((-e "$release_home" && $section ne "non-US") &&
                  (-e $release_home && $distb !~ /non-US|experimental/)) {
                my ($lmtime_r) = (stat($release_home))[9];
                my $remotefile = 
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                if ($lmtime_r < $rmtime_r) {
                  get($ftp,$remotefile,$release_localfile);
                  my ($lsize_r) = (stat($release_localfile))[7];
                  my $complete = $ftp->code();          
                  two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                  utime(time,$rmtime_r,$release_home); 
                }
              }
              elsif ((!-e "$release_home" && $section ne "non-US") &&
                     (!-e $release_home && $distb !~ /non-US|experimental/)) {
                my $remotefile =
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                get($ftp,$remotefile,$release_localfile);
                my ($lsize_r) = (stat($release_localfile))[7];
                my $complete = $ftp->code();
                two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                utime(time,$rmtime_r,$release_home) if -e $release_home;
              }
            }
            elsif ($commands->{"Packages"} ne "DF") {
              my $place = $commands->{"Packages"};
              make_dir($place);
              my($main::home,$localfile,$release_home,$release_localfile);
              my $nue = (split(m,/,,$dist))[0];
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($main::home = 
                  "$place/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($main::home = 
                    "$place/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($main::home = 
                    "$place/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($localfile = 
                  "$default_directory/partial/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($localfile = 
                    "$default_directory/partial/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($localfile = 
                    "$default_directory/partial/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
                ($release_home = $main::home) =~ s,Packages.gz,Release,;
                ($release_localfile = $localfile) =~ s,Packages.gz,Release,;
              if (-e "$main::home") {
                my ($lmtime) = (stat($main::home))[9];
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $size = $ftp->size("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);
                next if $file_exist == 550;
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  download($file_exist,$section,$arch,$dist,$distb,$size);
                  get($ftp,$remotefile,$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  two26($complete,$size,$lsize,$main::home,$localfile,
                        $section,$arch,$dist,$distb);
                  utime(time,$rmtime,$main::home); 
                }
              }
              else {
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $size = $ftp->size("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);  
                next if $file_exist == 550;
                download($file_exist,$section,$arch,$dist,$distb,$size);
                get($ftp,$remotefile,$localfile);
                my $complete = $ftp->code();          
                my $lsize = (stat($localfile))[7];
                two26($complete,$size,$lsize,$main::home,$localfile,
                      $section,$arch,$dist,$distb);
                if (-e $main::home) {
                  utime(time,$rmtime,$main::home); 
                }
              }
              ###########
              # RELEASE #
              ###########
              # this will not be very verbose
              if ((-e "$release_home" && $section ne "non-US") &&
                  (-e $release_home && $distb !~ /non-US|experimental/)) {
                my ($lmtime_r) = (stat($release_home))[9];
                my $remotefile = 
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                if ($lmtime_r < $rmtime_r) {
                  get($ftp,$remotefile,$release_localfile);
                  my ($lsize_r) = (stat($release_localfile))[7];
                  my $complete = $ftp->code();          
                  two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                  utime(time,$rmtime_r,$release_home); 
                }
              }
              elsif ((!-e "$release_home" && $section ne "non-US") &&
                     (!-e $release_home && $distb !~ /non-US|experimental/)) {
                my $remotefile =
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                get($ftp,$remotefile,$release_localfile);
                my ($lsize_r) = (stat($release_localfile))[7];
                my $complete = $ftp->code();
                two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                utime(time,$rmtime_r,$release_home) if -e $release_home;
              }
            }
           } # if defined Packages 

           ################################
           # NOT --CONTENTS && --PACKAGES #
           ################################
           if ((!defined $commands->{"Contents"} && 
               !defined $commands->{"Packages"}) || defined $Go_on) {  
              my ($main::home,$localfile,$release_home,$release_localfile);
              my $nue = (split(m,/,,$dist))[0];
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($main::home = 
                  "$default_directory/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($main::home = 
                    "$default_directory/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($main::home = 
                    "$default_directory/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
              $section ne "single" && $distb !~ /non-US|experimental/
               ? ($localfile = 
                  "$default_directory/partial/$the_site" . "_" . "$distb" . "_dists_" .
                  "$dist" . "_" . "$section" . "_" . "binary-$arch" . 
                  "_" . "Packages.gz")
               : $nue eq "project"
                 ? ($localfile = 
                    "$default_directory/partial/$the_site" . "_" . "$distb" .
                     "_" . "Packages.gz")
                 : ($localfile = 
                    "$default_directory/partial/$the_site" .  "_" . "$distb" . "_"  
                    . "$nue" . "_" . "binary-$arch" . "_" . "Packages.gz");
                ($release_home = $main::home) =~ s,Packages.gz,Release,;
                ($release_localfile = $localfile) =~ s,Packages.gz,Release,;
              if (-e "$main::home" && !$commands->{"Release_only"} &&
                  !defined $Go_on) {
                my ($lmtime) = (stat($main::home))[9];
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $size = $ftp->size("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);
                next if $file_exist == 550;
                if ($lmtime < $rmtime || $lmtime > $rmtime) {
                  download($file_exist,$section,$arch,$dist,$distb,$size);
                  get($ftp,$remotefile,$localfile);
                  my $lsize = (stat($localfile))[7];
                  my $complete = $ftp->code();          
                  two26($complete,$size,$lsize,$main::home,$localfile,
                        $section,$arch,$dist,$distb);
                  utime(time,$rmtime,$main::home); 
                }
              }
              elsif (!-e "$main::home" && !$commands->{"Release_only"} &&
                     !defined $Go_on ) {
                my $remotefile;
                $section ne "single"
                  ? ($remotefile = 
                    "$distbase/dists/$dist/$section/binary-$arch/Packages.gz")
                  : ($remotefile = "$distbase/$dist/Packages.gz");
                my $size = $ftp->size("$remotefile");
                my $rmtime = $ftp->mdtm("$remotefile");
                my $file_exist = $ftp->code();
                five50($file_exist,$section,$arch,$dist,$distb);
                next if $file_exist == 550;
                download($file_exist,$section,$arch,$dist,$distb,$size);
                get($ftp,$remotefile,$localfile);
                my $complete = $ftp->code();          
                my $lsize = (stat($localfile))[7];
                two26($complete,$size,$lsize,$main::home,$localfile,
                      $section,$arch,$dist,$distb); 
                if (-e $main::home) {
                  utime(time,$rmtime,$main::home); 
                }
              }
              ###########
              # RELEASE #
              ###########
              # this will not be very verbose
              if ((-e "$release_home" && $section ne "non-US") &&
                  (-e $release_home && $distb !~ /non-US|experimental/)) {
                my ($lmtime_r) = (stat($release_home))[9];
                my $remotefile = 
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                if ($lmtime_r < $rmtime_r) {
                  get($ftp,$remotefile,$release_localfile);
                  my ($lsize_r) = (stat($release_localfile))[7];
                  my $complete = $ftp->code();          
                  two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                  utime(time,$rmtime_r,$release_home); 
                }
              }
              elsif ((!-e "$release_home" && $section ne "non-US") &&
                     (!-e $release_home && $distb !~ /non-US|experimental/)) {
                my $remotefile =
                "$distbase/dists/$dist/$section/binary-$arch/Release";
                my $rmtime_r = $ftp->mdtm("$remotefile");
                my $size_r = $ftp->size("$remotefile");
                my $file_exist_r = $ftp->code();
                five50_r($file_exist_r,$section,$arch,$dist);
                next if $file_exist_r == 550;
                get($ftp,$remotefile,$release_localfile);
                my ($lsize_r) = (stat($release_localfile))[7];
                my $complete = $ftp->code();
                two26_r($complete,$size_r,$lsize_r,$release_home,
                        $release_localfile,$section,$arch,$dist);
                utime(time,$rmtime_r,$release_home) if -e $release_home;
              }
           } # if !defined Contents && Packages 
       $sectcount++; 
       }
      #undef $distb; 
      } 
    } # same site by architecture 
    $ftp->quit();
    my $good_bye = $ftp->code();
    print "swim: logged out\n" if $good_bye == 221;
   } # foreach site 



} # end sub ftp

# Packages printout for ftp 550 error
sub five50 {

  
    my ($file_exist,$section,$arch,$dist,$distb) = @_;
  
   if ($file_exist == 550) {
    my @distp = split(m,/,,$dist);
    print "swim: $dist/$section/binary-$arch/Packages.gz does not exist on the server\n" 
    if $section ne "single";        
    print "swim: $dist/Packages.gz does not exist on the server\n"
    if $section eq "single" && $distb !~ /non-US/;  
    print "swim: $distp[0]/non-US/$distp[1]/Packages.gz does not exist on the server\n" 
    if $distb =~ /non-US/ && $section !~ "non-US";
   }

} #end sub five50

# error check for Release file
sub five50_r {
    
     my ($file_exist,$section,$arch,$dist) = @_;
    
     if ($file_exist == 550) {
      print "swim: $dist/$section/binary-$arch/Release does not exist on the server\n";
     }

} # end sub five50_r


# this marks the beginning of the download
sub download {

    my ($file_exist,$section,$arch,$dist,$distb,$size) = @_;

   if ($file_exist != 550) {
    my @distp = split(m,/,,$dist);
    print "swim: downloading $dist/$section/binary-$arch/Packages.gz ($size)\n" 
    if $section ne "single";        
    print "swim: downloading $dist/Packages.gz ($size)\n"
    if $section eq "single" && $distb !~ /non-US/;  
    print "swim: downloading $distp[0]/non-US/$distp[1]/Packages.gz ($size)\n" 
    if $distb =~ /non-US/ && $section !~ "non-US";
   }

} # end sub download



# Packages printout for ftp 226 success and the correct size
sub two26 {

    my ($complete,$size,$lsize,$main::home,$localfile,$section,$arch,$dist,$distb)
        = @_;

   if ($complete == 226 && $size == $lsize) {
    my @distp = split(m,/,,$dist);
    print "swim: successful retrieval of $dist/$section/binary-$arch/Packages.gz\n" 
    if $section ne "single";        
    print "swim: successful retrieval of $dist/Packages.gz\n"
    if $section eq "single" && $distb !~ /non-US/;  
    print "swim: successful retrieval of $distp[0]/non-US/$distp[1]/Packages.gz\n" 
    if $distb =~ /non-US/ && $section !~ "non-US";
    rename("$localfile","$main::home")
    or system "$mv", "$localfile", "$main::home"; 
   }
   else {
    my @distp = split(m,/,,$dist);
    print "swim: unsuccessful retrieval of $dist/$section/binary-$arch/Packages.gz\n" 
    if $section ne "single";        
    print "swim: unsuccessful retrieval of $dist/Packages.gz\n"
    if $section eq "single" && $distb !~ /non-US/;  
    print "swim: unsuccessful retrieval of $distp[0]/non-US/$distp[1]/Packages.gz\n" 
    if $distb =~ /non-US/ && $section !~ "non-US";
   }

} # end sub two26


# check download of Release file
sub two26_r {

     my ($complete,$size,$lsize,$main::home,$localfile,$section,$arch,$dist) = @_;

   if ($complete == 226 && $size == $lsize) {
    #print "swim: successful retrieval of $dist/$section/binary-$arch/Packages.gz\n"; 
    rename("$localfile","$main::home")
    or system "$mv", "$localfile", "$main::home";   
   }
   else {
    print "swim: unsuccessful retrieval of $dist/$section/binary-$arch/Packages.gz\n"; 
   }

} # end sub two26_r

sub make_dir {                                                                  
                                                                                
  my ($what) = @_;                                                              
                                                                                
  if (!-e $what) {                                                              
      my @DRD = split(m,/,,$what);                                              
      my $placement = "/";                                                      
      for (1 .. $#DRD) {                                                        
       $_ == 1 ? ($placement = "/$DRD[$_]")                                     
               : ($placement = $placement . "/" . $DRD[$_]);                    
       mkdir("$placement",$permission)                                          
           or warn "swim: could not create $what\n";                            
      }                                                                         
  }                                                                             
                                                                                
                                                                                
} # end sub make_dir 

1;
