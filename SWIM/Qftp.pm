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


package SWIM::Qftp;
use strict;
use SWIM::Conf;
use SWIM::Global qw(@PACKAGES $argument %db);
use SWIM::DB_Library qw(:Xyz);
use SWIM::Deb qw(md5sumo);
use vars qw(@ISA @EXPORT);
use Net::FTP;
use SWIM::F;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(qftp);


=pod

This is the ftp client when --ftp is called with -q, --search/--ps.  The
downloaded packages are put in the Default directory (DF) in a directory
mirroring (in a way relative to the design of swim) the dists structure
which is standard with Debian. This is desirable if a person wants to mirror
parts of a remote ftp site above the
default_directory/default_root_directory/; this also makes it easy for a
person to make their own distribution if they want, and apt can be used to
install the packages at a later time by temporarily placing them in
/var/cache/apt/archives using --df2apt.  Obviously, this is nicer than using
apt just to download the packages, but the --nz option (apt) is provided
just in case a person is too lazed to do the -T thing, then they can do the
--apt2df thingy to move the packages from /var/cache/apt/archives to the
appropriate place in the DF.  Ofcourse, maybe the -T thing was what the
person didn't want to do, or maybe the person wants to do a combination of
both (like something in the -T apt doesn't care about), this would be an
instance where --ftp would be more useful.  The configuration file presents
a way to set this up so that the directory particular to the local ftpd can
be integrated into the DF.  The DF can be given any unique named
directories, and the permisions of the directories created above can also be
specified. Other options to control the DF will be provided, and -h will be
available for querying the database pertaining to the packages in the DF,
thereby allowing manipulation of the packages in the DF.  The database will
be made from Packages databases updated whenever the DF is called.  There
will be two types of Packages, one pertaining to the state of the local
system, and the other pertaining to the state of the real distribution. 
--file, and --http will also be integrated with DF when they become
available.  

IMPORTANT: Support will only be provided for not-installed databases, use a
not-installed database which reflects the currently installed package you
want to download in binary or source code. This is due to the fact that swim
thinks in terms of distribution states, and your installed system may
represent a combination of these things.  The md5sum is currently checked
for packages, but not for source, if the md5sum data exists (not a new
debian-revision, for instance)  the package will be checked. Whether or not
the package is OK it will be placed in it's appropriate place if it
downloads correctly.  If you get FAILED, examine the package and alert
the
community (download place, what's wrong with the package), then delete the
package. 

=cut
sub qftp {

 my ($arg,$commands) = @_;
 my %commands = %$commands;


    # Although the /dists/... could be found with -i, it's simpler
    # just to use name_versionFILENAME instead.  People shouldn't
    # edit --stdin to combine different distributions when doing --ftp,
    # (note: ofcourse apt-cache dumpavail could be used, and 
    # ncontentsindex could be put together from many dbs)
    # since swim can only figure out what distribution is wanted
    # from the default value or the one provided on the command line.  
    # The same is true of using apt.  Whatever package is
    # provided to --stdin is assumed to be of the specified distribution,
    # anyways.
    if (!$commands->{"n"}) {
      dbi(\%commands);
      @PACKAGES = map($db{$_},(@PACKAGES = split(/\s/,$arg)));
    }
    else {
      ndb(\%commands);
      @PACKAGES = map($db{$_},(@PACKAGES = split(/\s/,$arg))) 
    }


    my @LOCATION;
    for (0 .. $#PACKAGES) {
     if (!defined $PACKAGES[$_]) {
       print "swim: specified package(s) not found in database\n";
       exit;
     } 
    } 
    if (defined $db{$PACKAGES[0] . "FN"}) {  
      @LOCATION = map($db{$_ . "FN"},@PACKAGES);
    }
    else {
     print "swim: incorrect database was specified\n";
     exit;
    }

   # might as well check for a temporary directory for downloads, if it
   # doesn't exist create it.
   mkdir("$default_directory/partial",$permission) 
   if !-d "$default_directory/partial";
   
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

    # let's make unique sites
    my (%site,@sites,$site);
    foreach $site (@FTP) {
      my @parts  = split(' ', $site);
      $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
      $site{$1}++;
      push(@sites,"$1!$site") if $site{$1} == 1;
    }


   foreach $site (@sites) {

       # will provide all kinds of options for ftp..like firewall
       
       my $uri; ($site, $uri) = split(/!/,$site);
       my $ftp = Net::FTP->new($site,
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
         print "swim: connected to $site\n";
        }
       }
       else {
         print "swim: could not find $site\n";
         next;
       }


       #########
       # LOGIN #
       #########
       $ftp->login("anonymous","swim\@the.netpedia.net");
       my $logged  = $ftp->code();
       # we are logged, but what is the time difference.
       if ($logged == 230 || $logged == 332) {
         print "swim: logged in to $site\n";
         $ftp->binary;
       }
       else {
        # 530 "not logged in" will have to test this
        $ftp->code();
        print "swim: not logged in to $site\n";
        next;
       }

     # find the base to the distribution 
     my @parts  = split(' ', $uri);
     $parts[1]  =~ m,^ftp:/+( (?: (?!/). ) *)(.*),sx;
     my $base = $2;

    # this finds the base, but it only needs to be found once, ofcourse
    # a foreach is totally unecessary unless the site has weird symlinks.
    my @tryme_again; my $base_count = 0;
    foreach (@FTP) {
      next if $base_count == 1;

       ############
       #  SETUP   #
       ############
        LOCUS: foreach (@LOCATION) {
        m,(.*)/(.*)$,;
        my $uptopackage = $1;
        my $packagename = $2; my $packagen = $2; 
        $packagename =~ s,\+,\\\+,g;
        my ($source_drd,$drd);
        # make directories with permissions if they don't already exist
        # and also establish standardized (swimy) debian-non-US and the
        # appropriate symlinks
        # if a non-US file is requested.
        if ($uptopackage !~ /non-US/) {
         if (!-d "$default_directory/$default_root_directory/$uptopackage") {
          my $place = "$default_directory/$default_root_directory";
          my @DP = split(m,/,,$uptopackage);
          my $placement = "/";
          for (0 .. $#DP) {  
            $_ == 0 ? ($placement = "/$DP[$_]") 
                    : ($placement = $placement . "/" . $DP[$_]);
            mkdir("$place$placement",$permission); 
                 # will fix this later
                 # or warn "swim: could not create dists directory\n";
                 # Ofcourse there is even a better fix.
          }
         }
        }
        ####################
        # ################ #
        # # NON-US FILES # #
        # ################ #
        ####################
        else {
         (my $above_drd = $uptopackage) =~ s,dists,,;
         $above_drd =~ s,non-US/,,;
         $source_drd = (split(m,/,,$above_drd))[1];    
         ($drd = $default_root_directory) =~ s,/debian,,;
         if (!-e "$default_directory$drd/debian-non-US$above_drd") {
          my $place = "$default_directory";
          my $create = "$drd/debian-non-US$above_drd"; 
          my @DP = split(m,/,,$create);
          my $placement = "/";
          for (0 .. $#DP) {  
            $_ == 0 ? ($placement = "/$DP[$_]") 
                    : ($placement = $placement . "/" . $DP[$_]);
            mkdir("$place$placement",$permission) 
                 or warn "swim: could not create debian-non-US directory\n";
          }
          if (!-d "$default_directory$drd/debian-non-US/$source_drd/source") {
          my $place = "$default_directory";
          my $create = "$drd/debian-non-US/$source_drd/source"; 
          my @DP = split(m,/,,$create);
          my $placement = "/";
          for (0 .. $#DP) {  
            $_ == 0 ? ($placement = "/$DP[$_]") 
                    : ($placement = $placement . "/" . $DP[$_]);
            mkdir("$place$placement",$permission) 
                 or warn "swim: could not create debian-non-US directory\n";
          }
          } 
 
         $place = "$default_directory$drd/debian-non-US";
         my $disty = (split(m,/,))[1]; $create = "/dists/$disty";
         undef @DP;
          @DP = split(m,/,,$create);
          for (0 .. $#DP) {  
            $_ == 0 ? ($placement = "/$DP[$_]") 
                    : ($placement = $placement . "/" . $DP[$_]);
            mkdir("$place$placement",$permission) 
                 or warn "swim: could not create debian-non-US directory\n";
          }

         # make the symlinks
         chdir("$place$placement");
         symlink("../../$disty","non-US");
         symlink("../../$disty/source","source");

         $place = "$default_directory$drd/debian"; $create = "/dists/$disty";
         undef @DP;
          @DP = split(m,/,,$create);
          for (0 .. $#DP) {  
            $_ == 0 ? ($placement = "/$DP[$_]") 
                    : ($placement = $placement . "/" . $DP[$_]);
            mkdir("$place$placement",$permission) 
                 or warn "swim: could not create debian-non-US directory\n";
          }
         chdir("$place$placement");

         # make more symlinks
         symlink
         ("../../../debian-non-US/dists/$disty/non-US","non-US");
         } # if non-US dir !-e
        } # end non-us

 
        #######
        # GET #
        #######
        my $file; 
         ($packagen = $packagename) =~ s,\\\+,\+,g;
         my $localfile =
        "$default_directory/partial/$packagen";
         my $home =
        "$default_directory/$default_root_directory/$_";
         my $size = $ftp->size("$base/$_");
         my $rmtime = $ftp->mdtm("$base/$_");
         my $file_exist = $ftp->code();
         #########################
         # CHECK DEBIAN-REVISION #
         #########################
         # the way this is set up, it is assumed that something exists for
         # the -(debian-revision).
         if ($file_exist == 550) {
           print "swim: $packagen does not exist on the server\n"; 
           print "swim: checking to see if the debian-revision has changed\n";
           $packagename =~ m,^(.*)-[\dA-Za-z\.\+]+\.deb$,;
           my $matcher = $1;
           $_ =~ m,^(.*)/$matcher[-\da-zA-Z\.\+]+\.deb$,;
           my $otherthing = $1;
           my $REVISIONCHANGE = $ftp->ls("$base/$uptopackage");
           my $singfile;
           foreach (@{$REVISIONCHANGE}) {
             m,^.*/($matcher[-\dA-Za-z\.\+]+\.deb)$,           
                ? ($singfile = $1)  
                : ($singfile = $_);
              if ($singfile =~ /^$matcher/) {
                  $file = $singfile;
              }
            }
           my $checkfile;
           defined $file
            ? ($checkfile = $otherthing . "/$file")
            : ($checkfile = "NOFILE");          
           $size = $ftp->size("$base/$checkfile");
           $rmtime = $ftp->mdtm("$base/$checkfile");
           $file_exist = $ftp->code();
           print "swim: could not find $packagen debian-revision\n"
           if $file_exist == 550;
           push(@tryme_again,$_) if $file_exist == 550;
           next if $file_exist == 550;
           $localfile =~ s,$matcher[-\dA-Za-z\.\+]*\.deb$,$file,;
           $home = 
           "$default_directory/$default_root_directory/$uptopackage/$file";
           $packagename = $file; $file = $otherthing . "/$file";
         } # END DEBIAN-REVISION
         else {$file = $_; }
         my ($lsize,$lmtime);


         ########################
         # SAME PACKAGE LOCALLY #
         ########################
         $packagename =~ m,(^[A-Za-z\d\+-\\+]*)_([\\+A-Za-z\d\+\.:]*)
                             [-]?[\dA-Za-z\.\+]*\.deb$,x; 
         my $spackage = $1; my $upstream_revision = $2;
         $spackage =~ s,\+,\\\+,g;
         if (-e $home) {
           ($lsize,$lmtime) = (stat($home))[7,9];
         } 
         # If the upstream-revision has changed and
         # a local package with the same name exists, we want to delete it.
         else {
           opendir(DF,"$default_directory/$default_root_directory/$uptopackage");
           my $grepthing = "^" . $spackage . "_";
           #my $grepthing = $spackage . "_" . $upstream_revision;
           foreach (sort grep(/$grepthing/, readdir(DF))) {
             m,(.*)_([\dA-Za-z\+\.:]+)[-]?[\dA-Za-z\+\.]*\.deb$,;
             my $lupstream_revision = $2;
             if ($lupstream_revision eq $upstream_revision) {               
               print "swim: $_ with different debian-revision exists\n";
               $_ = "";

               ##########
               # SOURCE #
               ##########         
               if ($commands->{"source"} || $commands->{"source_only"}) {
                 my (@SOURCE,$upstream_change); 
                 my ($matcher,$local_source,$remote_source,$base) =
                 source_calc($base,$uptopackage,$packagename,$drd,$source_drd);
                 my $REVISIONCHANGE = $ftp->ls("$base/$remote_source");
                 my $singfile;
                 foreach (@{$REVISIONCHANGE}) {
                   m,^.*/($matcher.*)$,           
                    ? ($singfile = $1)  
                    : ($singfile = $_);
                   if ($singfile =~ /^$matcher/) {
                     $file = $singfile;
                     push(@SOURCE,"$base/$remote_source/$singfile");
                   }
                 }
                 if (!defined @SOURCE) {
                  print "swim: checking for upstream-revsion change\n";
                  ($matcher) =  (split(/_/,$matcher))[0];
                   foreach (@{$REVISIONCHANGE}) {
                     m,^.*/($matcher.*)$,           
                        ? ($singfile = $1)  
                        : ($singfile = $_);
                      if ($singfile =~ /^$matcher/) {
                          $file = $singfile;
                          push(@SOURCE,"$base/$remote_source/$singfile");
                      }
                   }
                  $upstream_change = "yes" if defined @SOURCE;
                 }
                 foreach (@SOURCE) {
                  m,.*/(.*)$,; $packagename = $1;
                  $lmtime = (stat("$local_source/$packagename"))[9];
                  -e "$local_source/$packagename"
                   ? ($lmtime = (stat("$local_source/$packagename"))[9])
                   : ($lmtime = -1);
                  $size = $ftp->size("$_");
                  $rmtime = $ftp->mdtm("$_");
                  $file_exist = $ftp->code();
                  if ($lmtime != $rmtime) {
                   if (!$commands->{"diff"}) {
                      $localfile = "$default_directory/partial/$packagename";
                      !defined $upstream_change
                       ? print "swim: downloading $packagename ($size bytes)\n"
                       : print "swim: downloading upstream-revision $packagename ($size bytes)\n";
                      get($ftp,"$_",$localfile);
                      my $complete = $ftp->code();         
                      $lsize = (stat($localfile))[7];
                      if ($lsize == $size && $complete == 226 && 
                          $lmtime != $rmtime) {
                      print "swim: successful retrieval of $packagename\n"; 
                      rename("$localfile","$local_source/$packagename")
                      or system "$mv","$localfile","$local_source/$packagename";
                     }
                     else {
                      print "swim: unsuccessful retrieval of $packagename\n";   
                     }
                   } 
                   else {
                    if (m,diff\.gz,) {
                     $localfile = "$default_directory/partial/$packagename";
                     !defined $upstream_change
                     ? print "swim: downloading $packagename ($size bytes)\n"
                     : print "swim: downloading upstream-revision $packagename ($size bytes)\n";
                     get($ftp,"$_",$localfile);
                     my $complete = $ftp->code();         
                     $lsize = (stat($localfile))[7];
                     if ($lsize == $size && $complete == 226 && 
                         $lmtime != $rmtime) {
                      print "swim: successful retrieval of $packagename\n"; 
                      rename("$localfile","$local_source/$packagename")
                      or system "$mv","$localfile","$local_source/$packagename";
                     }
                     else {
                      print "swim: unsuccessful retrieval of $packagename\n";   
                     }
                   }
                  }
                   utime(time,$rmtime,"$local_source/$packagename");
                   $_ = "";
                  }
                  else {
                    print "swim: $packagename already exists\n"
                  }
                 } 
               } # source
               next LOCUS;
             }
             elsif  ($lupstream_revision ne $upstream_revision) {
              if (!$commands->{"source_only"}) {
               print "swim: replacing $_ with a different upstream-revision\n";
               unlink
               ("$default_directory/$default_root_directory/$uptopackage/$_");
              } 
               print "swim: $_ exists with a different upstream-revision\n";
             }
           }
           closedir(DF); 
         } 

         ##################
         # EXISTS LOCALLY #
         ################## 
         # got here but localtime was greater.
         if (defined $rmtime && defined $lmtime) {
          # ofcourse if the file does exist locally and has the same name
          # and version, and this exists, something strange is going on.
          if ($lmtime < $rmtime) {
           print "swim: downloading $packagen, strange.........
same upstream version exists in the same package locally\n"; 
           get($ftp,"$base/$file",$localfile);
           my $complete = $ftp->code();          
           $argument = $localfile; 
           $commands{"md5sum"} = 1; 
           md5sumo(\%commands) if $complete == 226;        
           ($packagen = $packagename) =~ s,\\\+,\+,g;
           print "swim: successful retrieval of $packagen\n"               
           if $complete == 226;
           $_ = "" if $complete == 226;
           utime(time,$rmtime,$localfile);
          }
          elsif ($lmtime == $rmtime) {
           $_ = "";
           ($packagen = $packagename) =~ s,\\\+,\+,g;
           print "swim: $packagen already exists\n";
           ##########
           # SOURCE #
           ##########         
            if ($commands->{"source"} || $commands->{"source_only"}) {
             my (@SOURCE,$upstream_change); 
             my ($matcher,$local_source,$remote_source,$base) =
             source_calc($base,$uptopackage,$packagename,$drd,$source_drd);
             my $REVISIONCHANGE = $ftp->ls("$base/$remote_source");
             my $singfile;
             foreach (@{$REVISIONCHANGE}) {
               m,^.*/($matcher.*)$,           
                  ? ($singfile = $1)  
                  : ($singfile = $_);
                if ($singfile =~ /^$matcher/) {
                    $file = $singfile;
                    push(@SOURCE,"$base/$remote_source/$singfile");
                }
             }
             if (!defined @SOURCE) {
              print "swim: checking for upstream-revsion change\n";
              ($matcher) =  (split(/_/,$matcher))[0];
               foreach (@{$REVISIONCHANGE}) {
                 m,^.*/($matcher.*)$,           
                    ? ($singfile = $1)  
                    : ($singfile = $_);
                  if ($singfile =~ /^$matcher/) {
                      $file = $singfile;
                      push(@SOURCE,"$base/$remote_source/$singfile");
                  }
               }
              $upstream_change = "yes" if defined @SOURCE;
             }
             foreach (@SOURCE) {
              m,.*/(.*)$,; $packagename = $1;
              -e "$local_source/$packagename"
               ? ($lmtime = (stat("$local_source/$packagename"))[9])
               : ($lmtime = -1);
              $size = $ftp->size("$_");
              $rmtime = $ftp->mdtm("$_");
              $file_exist = $ftp->code();
              if ($lmtime != $rmtime) {
               if (!$commands->{"diff"}) {
                 $localfile = "$default_directory/partial/$packagename";
                  !defined $upstream_change
                   ? print "swim: downloading $packagename ($size bytes)\n"
                   : print "swim: downloading upstream-revision $packagename ($size bytes)\n"; 
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
               } 
               else {
                if (m,diff\.gz,) {
                 $localfile = "$default_directory/partial/$packagename";
                  !defined $upstream_change
                   ? print "swim: downloading $packagename ($size bytes)\n"
                   : print "swim: downloading upstream-revision $packagename ($size bytes)\n"; 
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
                }
               }
               utime(time,$rmtime,"$local_source/$packagename");
               $_ = "";
              }
              else {
                print "swim: $packagename already exists\n"
              }
             } 
            } # source
          }
         }
         #########################################################
         # DOESN'T EXIST LOCALLY OR DIFFERENT UPSTREAM-REVISION #
         #########################################################
         else {
          ########################
          # BINARY AND/OR SOURCE #
          ########################
          if (!$commands->{"source_only"}) { 
            print "swim: downloading $packagen ($size bytes)\n"; 
            my $upstream_change;
            get($ftp,"$base/$file",$localfile);
            my $complete = $ftp->code();         
            $lsize = (stat($localfile))[7];
            if ($lsize == $size && $complete == 226) {
             $argument = $localfile; 
             $commands{"md5sum"} = 1; md5sumo(\%commands);
             ($packagen = $packagename) =~ s,\\\+,\+,g;
             print "swim: successful retrieval of $packagen\n";               
             rename("$localfile","$home")
             or system "$mv", "$localfile", "$home";
             utime(time,$rmtime,"$home");
            }
            else {
             print "swim: unsuccessful retrieval of $file\n";               
            }
            $_ = "";
            ##########
            # SOURCE #
            ##########
            if ($commands->{"source"}) {
             my (@SOURCE,$upstream_change); 
             my ($matcher,$local_source,$remote_source,$base) =
             source_calc($base,$uptopackage,$packagename,$drd,$source_drd);
             my $REVISIONCHANGE = $ftp->ls("$base/$remote_source");
             my $singfile;
             foreach (@{$REVISIONCHANGE}) {
               m,^.*/($matcher.*)$,           
                  ? ($singfile = $1)  
                  : ($singfile = $_);
                if ($singfile =~ /^$matcher/) {
                    $file = $singfile;
                    push(@SOURCE,"$base/$remote_source/$singfile");
                }
             }
             if (!defined @SOURCE) {
              print "swim: checking for upstream-revsion change\n";
              ($matcher) =  (split(/_/,$matcher))[0];
               foreach (@{$REVISIONCHANGE}) {
                 m,^.*/($matcher.*)$,           
                    ? ($singfile = $1)  
                    : ($singfile = $_);
                  if ($singfile =~ /^$matcher/) {
                      $file = $singfile;
                      push(@SOURCE,"$base/$remote_source/$singfile");
                  }
               }
              $upstream_change = "yes" if defined @SOURCE;
             }
             foreach (@SOURCE) {
              m,.*/(.*)$,; $packagename = $1;
              -e "$local_source/$packagename"
               ? ($lmtime = (stat("$local_source/$packagename"))[9])
               : ($lmtime = -1);
              $size = $ftp->size("$_");
              $rmtime = $ftp->mdtm("$_");
              $file_exist = $ftp->code();
              if ($lmtime != $rmtime) {
               if (!$commands->{"diff"}) {
                 $localfile = "$default_directory/partial/$packagename";
                  !defined $upstream_change
                   ? print "swim: downloading $packagename ($size bytes)\n"
                   : print "swim: downloading upstream-revision $packagename ($size bytes)\n";
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
               } 
               else {
                if (m,diff\.gz,) {
                 $localfile = "$default_directory/partial/$packagename";
                 !defined $upstream_change
                  ? print "swim: downloading $packagename ($size bytes)\n"
                  : print "swim: downloading upstream-revision $packagename ($size bytes)\n"; 
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
                }
               }
               utime(time,$rmtime,"$local_source/$packagename");
               $_ = "";
              }
              else {
                print "swim: $packagename already exists\n"
              }
             } 
            } # source
          }
          ###############
          # SOURCE-ONLY #
          ###############
          else {
             my (@SOURCE,$upstream_change); 
             my ($matcher,$local_source,$remote_source,$base) =
             source_calc($base,$uptopackage,$packagename,$drd,$source_drd);
             my $REVISIONCHANGE = $ftp->ls("$base/$remote_source");
             my $singfile;
             foreach (@{$REVISIONCHANGE}) {
               m,^.*/($matcher.*)$,           
                  ? ($singfile = $1)  
                  : ($singfile = $_);
                if ($singfile =~ /^$matcher/) {
                    $file = $singfile;
                    push(@SOURCE,"$base/$remote_source/$singfile");
                }
             }
             if (!defined @SOURCE) {
              print "swim: checking for upstream-revsion change\n";
              ($matcher) =  (split(/_/,$matcher))[0];
               foreach (@{$REVISIONCHANGE}) {
                 m,^.*/($matcher.*)$,           
                    ? ($singfile = $1)  
                    : ($singfile = $_);
                  if ($singfile =~ /^$matcher/) {
                      $file = $singfile;
                      push(@SOURCE,"$base/$remote_source/$singfile");
                  }
               }
              $upstream_change = "yes" if defined @SOURCE;
             }
             foreach (@SOURCE) {
              m,.*/(.*)$,; $packagename = $1;
              -e "$local_source/$packagename"
               ? ($lmtime = (stat("$local_source/$packagename"))[9])
               : ($lmtime = -1);
              $size = $ftp->size("$_");
              $rmtime = $ftp->mdtm("$_");
              $file_exist = $ftp->code();
              if ($lmtime != $rmtime) {
               if (!$commands->{"diff"}) {
                 $localfile = "$default_directory/partial/$packagename";
                  !defined $upstream_change
                   ? print "swim: downloading $packagename ($size bytes)\n"
                   : print "swim: downloading upstream-revision $packagename ($size bytes)\n"; 
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
               } 
               else {
                if (m,diff\.gz,) {
                 $localfile = "$default_directory/partial/$packagename";
                 !defined $upstream_change
                  ? print "swim: downloading $packagename ($size bytes)\n"
                  : print "swim: downloading upstream-revision $packagename ($size bytes)\n"; 
                 get($ftp,"$_",$localfile);
                 my $complete = $ftp->code();         
                 $lsize = (stat($localfile))[7];
                 if ($lsize == $size && $complete == 226 && $lmtime != $rmtime) {
                  print "swim: successful retrieval of $packagename\n"; 
                  rename("$localfile","$local_source/$packagename")
                  or system "$mv","$localfile","$local_source/$packagename";
                 }
                 else {
                  print "swim: unsuccessful retrieval of $packagename\n";   
                 }
                }
               }
               utime(time,$rmtime,"$local_source/$packagename");
               $_ = "";
              }
              else {
                print "swim: $packagename already exists\n"
              }
             } 
          } # source-only
         }
       } 
    $base_count++;
    } # foreach FTP
       undef @LOCATION;
       @LOCATION = @tryme_again;        
     $ftp->quit() if !defined @LOCATION;
     my $good_bye = $ftp->code();
     print "swim: logged out\n" if $good_bye == 221;
     undef @sites if !defined @LOCATION;  

   } # foreach sites
    untie %db;

} # end sub qftp


# figure out the source stuff, make appropriate directories for sections
# which aren't non-US
sub source_calc {

            my($base,$uptopackage,$packagename,$drd,$source_drd) = @_;


            # if source is empty in %db we can use the package name, need
            # to watch for experimental
            my ($remote_source,$local_source,@SOURCE);
             # NON-US
             if ($uptopackage =~ /non-US/) {
              $local_source =
              "$default_directory$drd/debian-non-US/$source_drd/source";
              $uptopackage =~ m,(.*)/.*$,; $remote_source = $1;
              $remote_source = "$remote_source/source";
              # for safety's sake and because most sites don't have
              # /pub/debian/dists/unstable/non-US/source except for a 
              # site made with swim, convert debian to debian-non-US and
              # hope everything is standard.
              if ($base !~ /debian-non-US/) {
               $base =~ s/debian/debian-non-US/;
              }
             }
             # EVERYTHING ELSE 
             else {
              $uptopackage =~ m,(.*)/(.*)$,; 
              my $subject = $2; $1 =~ m,(.*)/.*$,; $local_source = $1;
              #$remote_source =~  m,(.*)/.*$,; $remote_source = $1;
              $remote_source = $local_source;
              $local_source = "$remote_source/source/$subject";
              $remote_source = $local_source;
              $local_source = 
              "$default_directory$default_root_directory/$local_source";
             }             

             # exciting matcher realities..if it isn't non-US than the
             # %db needs to be searched for anything found in Source:,
             # if it is defined, then vola, herein this section lays the
             # source, otherwise it's probably in the section which pertains
             # to the package being queried..we hope.  Epochs aren't used 
             # fortunately they aren't in package_versionFN, but they can
             # be in the Source: area so they need to be removed.
             $packagename =~ m,(^[A-Za-z\d\+-\\+]*_[\\+A-Za-z\d\+\.:]*)
                               [-]?[\dA-Za-z\.\+]*\.deb$,x;

             # everything, but revision
             my $matcher = $1;               
             $matcher =~ m,^(.*)_(.*)$,; my $mat = $1;
             if (defined $db{$mat}) {
                $mat = $db{$mat}; $mat = $db{$mat};               
                if ($mat =~ m,Installed-Size:\s\d+\s+Source:\s(.*),){
                  $matcher = $1;
                  ##########################################
                  # DIFFERENT VERSION AND DIFFERENT SOURCE #
                  ##########################################
                  if ($matcher =~ m,[\(\)], ) {
                   $matcher =~ /:/  
                    ? $matcher =~ m,^(.*)
                                 \s\([\d]?[:]?
                                 ([A-Za-z0-9\+\.]+)
                                 [-]?[\dA-Za-z\+\.]*\)$,x
                    : $matcher =~ m,^(.*)
                                 \s\(
                                 ([A-Za-z0-9\+\.]+)
                                 [-]?[\dA-Za-z\+\.]*\)$,x;
                    
                     my $mat2 = $1;  my $mat2_ver = $2;
                     $matcher = $mat2 . "_" . $mat2_ver;
                     if (defined $db{$mat2}) {               
                       $matcher = $mat2 . "_" . $mat2_ver;
                       # time to change the $remote_source and $local_source
                       if ($uptopackage !~ /non-US/) {
                         my $change = $db{$mat2};  
                         $change = $db{$change ."FN"}; 
                         $change =~ m,(.*)/(.*)$,;
                         $uptopackage = $1; $uptopackage =~ m,(.*)/(.*)$,; 
                         my $subject = $2;
                         $1 =~ m,(.*)/.*$,; $local_source = $1;
                         $local_source = "$local_source/source/$subject";
                         $remote_source = $local_source;
                         $local_source =
                         "$default_directory$default_root_directory/$local_source";
                       }
                     }
                  }
                  #####################################
                  # SAME VERSION AND DIFFERENT SOURCE #
                  #####################################
                  else {
                      if (defined $db{$matcher}) {
                       # time to change the
                       # $remote_source and $local_source
                       if ($uptopackage !~ /non-US/) {
                         my $change = $db{$matcher};  
                         $change = $db{$change ."FN"}; 
                         $change =~ m,(.*)/(.*)$,;
                         $uptopackage = $1; $uptopackage =~ m,(.*)/(.*)$,; 
                         my $subject = $2;
                         $1 =~ m,(.*)/.*$,; $local_source = $1;
                         $local_source = "$local_source/source/$subject";
                         $remote_source = $local_source;
                         $local_source =
                         "$default_directory$default_root_directory/$local_source";
                       }
                      }
                  }
                } # Source: found
             } # should be defined


             # time to make direcorties if $local_source isn't defined
             # non-US already made, if source if already made, just the 
             # subject above needs to be made
             if (!-e $local_source) {
               my $place;
               my @LS = split(m,/,,$local_source);
               for (1 .. $#LS - 2) {
                 $_ == 1 ? ($place = "/$LS[$_]") 
                         : ($place = $place . "/" . $LS[$_]);
               } 
               my $create = "$LS[$#LS -1]/$LS[$#LS]"; 
               if (-d "$place/$LS[$#LS - 1]") {
                 mkdir("$place/$create",$permission) 
                      or warn "swim: could not create source directory\n";
               }
               else { 
                my @DP = split(m,/,,$create);
                my $placement = "/";
                for (0 .. $#DP) {  
                  $_ == 0 ? ($placement = "/$DP[$_]") 
                          : ($placement = $placement . "/" . $DP[$_]);
                  mkdir("$place$placement",$permission) 
                       or warn "swim: could not create source directory\n";
                }
               }
             }
            
             return($matcher,$local_source,$remote_source,$base); 

} # end source_calc




1;
