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

package SWIM::NDB;
use strict;
use SWIM::NDB_File;
use SWIM::Library;
use SWIM::DB_Library qw(:NDb);
use SWIM::Format;
use SWIM::Compare;
use SWIM::Global;
use SWIM::Conf qw(:Path $default_directory @user_defined_section 
                  $distribution $architecture);
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(update_packages_ndb rebuildflatndb);

=pod

This is one of the most powerful functions of swim because besides
rebuilding the not-installed databases averting a long wait, it creates
a report which can compare changes within one distribution, or this
function can be tricked into comparing the differences between two
distributions.  This also quickly updates the DF databases or
not-installed databases when a new package(s) are installed or downloaded. 

=cut

sub update_packages_ndb {

=pod

This function differs from SWIM::DB::db because rather then checking
the status file, it compares the Packages file(s) to the status
database created by swim.

For normal upadating (not ndb ran automatically) SWIM::NDB_Init is used to
figure out what Packages databases to use for comparison.  --ndb run
automatically will also be dealt with.

=cut
 
  my ($commands,$contents) = @_;  my %commands = %$commands;

  my($arch,$dist);

  # which architecture and distribution?
  $commands->{"arch"} ? ($architecture = $commands->{"arch"})
                      : ($architecture = $architecture);
 
  if ($commands->{"dists"}) {
      $distribution = $commands->{"dists"};
      ($arch,$dist) = which_archdist(\%commands);
  }
  else {
      $distribution =  $distribution;
      ($arch,$dist) = which_archdist(\%commands);
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

    # remove the version check file ..not the Release code
    my $place = finddb(\%commands);
    if ($commands->{"v"}) {
        unlink("$place/.version_compare");
    }

    # Use dir() and fir() in NDB_Init to find path to Packages or
    # Package.gz to make things easy, only one or more compressed files,
    # or one or more non-compressed files may be used together in a set.
    #print "Data is being gathered\n";
    my $begin = scalar(localtime);
    print "checking for new, changed, and removed packages\n";
    my @check_arg = split(/\s/,$argument);
    my $ac = 0; my $gz;
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


  #ndb(\%commands); nsb(\%commands); 

  # now we can find the differences

=pod

Basically, if a package is new its information can be placed into the
specified databases.  If a package already exists and the version has
changed, then this package will be updated, and specific information like
group and status will be compared.  The version change will also be
compared..is it older, newer, debian-revision change?  Packages which are
gone will have their information removed from the specified databases.

# REPORT #

A report will be kept, this allows changes within a distribution to be
recorded, or alternatively two different distributions can be compared by
tricking swim into thinking that the same distribution is being looked at.

The format is something like a passwd file, except that it is divided
by ! (exclamations) - fortunately no packages have this - though sometimes
files do (very rare), exclamations in the Description field will be
coverted to a pound #. Control fields are stripped of their Field:.

(this all on one line)

GONE or CHANGED or NEW or SAME!                                          
packagename!Description!                                                        
current_version!old_version!                                          
current_group!old_group!                                                
current_status!old_status! # Both for installed and not-installed (r<>=)
current_arch!old_arch!                                                    
current_dist!old_dist!                                                   
current_priority!old_priority!                                        
present_maintainer!old_maintainer!                                              
current_essential!old_essential!                                  
current_source!old_source!  # Weird if it changes                      
current_IS!old_IS!  # Installed_Size                                  
current_size!old_size!
 
As you can see this format provides lots of information with 25 fields,
even more information than is needed, and the report can be read into a
hash of hashes quite easily, other ways can be used, too.  Fields without
a value will just be empty (!!).  The report will be available with the
--report option and will be dated, since it will be made new for each
dist-dist comparison.  It's not necessary to use a Contents database, so
these reports can be generated very fast.  But, it would be interesting to
see file differences in two distinct Distributions..Suse versus Debian,
this may come in the future .. although the author has already written
such a program (which doesn't use databases). 

Important:
Existing databases are used and updated, so for research purposes copies
of the databases in the default directory should be placed in an
alternative directory and --dbpath and/or --root used.

=cut

    $| = 1; my @NEW; 
    # uses $ping for npackages-arch-dists.deb - %db
    nping(\%commands) if !$commands->{"status_only"};
    # uses $zing for nfileindex-arch-dists.deb - %ib
    nzing(\%commands) if $commands->{"Contents"}; 
    nging(\%commands); # uses $ging for ngroupindex-arch-dists.deb - %gb
    nsing(\%commands); # uses $sing for nstatusindex-arch-dists.deb - %nsb
    sb(\%commands);    # uses %sb vs %nsb for nsing

   # no sense going through this if we just want to update n* status
   if (!$commands->{"status_only"}) {


      # First we have to sort out repeaters, it's annoying to have
      # to have another loop, but repeats (not Debian Policy) are known
      # to occur, and can wreck havoc in the databases.  This loop can
      # be skipped to check for changes when a ni has become in.

      # grab the ruler
      my (%Package_count,%not_me,$packler,%not_me2,%warch,%arc);
      open(PACKAGE, "$argument");
      while (<PACKAGE>) {
        if (/^Package:/i) {                                              
         $packler = substr($_,9); chomp $packler;
         $Package_count{$packler}++; 
        } 
        elsif (/^Version:/) {       
          # decide who shall rule with the greatest version, 
          # order matters in the way the Packages are processed.
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
    print STDERR "REPEATS:" if $#hu != -1;
    for (keys %not_me2) {
    print STDERR " $_"; #print  " $_ $not_me2{$_}";
    }
    print STDERR "\n" if $#hu != -1;

     
      my (@old_report,@new_report,$packagename,@New_packages,
          @CHANGED,@CHANGED_REV,%CR,%two_timers);
      my $packagesgz = $argument; 
      my %equalizer;

      # this will have a similiar setup to SWIM::NDB_Init but with the
      # option not to check all fields.  new and old status will be
      # figured out, too.  Even though almost everything could be done in
      # one loop, we will keep it simple for now to stablize everything 
      # and maybe in the future integrate this all into one loop.  We will
      # grab all the report info from this loop, Gone packages can have
      # their report info grabbed separately below.  
      open (DIFFERENCE, "$argument");
      while (<DIFFERENCE>) {
       # Package name
        if (/^Package:/i) {             
          $packagename = (split(/: /,$_))[1]; chomp $packagename;
          push(@New_packages,$packagename);
        } 
        elsif (/^Version:/) {
             my $new_version =  substr($_,9); chomp $new_version;        
             my $packagen = (split(/_/,$packagename))[0];  
             if (defined $not_me2{$packagen}) {
              if ($not_me2{$packagen} ne $new_version) {
               pop(@New_packages); undef $new_version; undef $packagename; 
               next;
              }
              else {
               $equalizer{$packagename}++;
               # two with the same version
               if ($equalizer{$packagename} > 1) {
                pop(@New_packages); undef $new_version; undef $packagename; 
                next;
               }
              }
             }
             if (defined $nsb{$packagename}) { 
              # just an example 
              if ($commands->{"report"}) {
                my $old_priority = (split(/\s/,$nsb{$packagename}))[2];
                push(@old_report,$old_priority);
              }
             }
             # humm, never seen this package before
             # NEW #
             if (! defined $nsb{$packagename}) {
               print STDERR "NEW $packagename\n"; 
               push(@NEW,$packagename);
             }
             # guess I've seen it before!  But has its version changed?
             # CHANGED #  
             else {
               my $old_version = 
               (split(/_/,((split(/\s/,$nsb{$packagename}))[0])))[1];
               my $operand;
               if ($new_version ne $old_version) {
                 $operand = comparison($new_version,$old_version);
                 compare_versions($operand,$new_version,$old_version,
                                  $packagename,\%commands) if $commands->{"v"};
                 if ($operand eq "r>" || $operand eq "r<") {
                    push(@CHANGED_REV,$packagename);
                    $CR{$packagename} = "yes";
                    print STDERR "CHANGED-REVISION $packagename\n";
                 } 
                 else {
                    push(@CHANGED,$packagename);
                    print STDERR "CHANGED $packagename\n";
                 }
               #print "$packagename  $new_version $operand $old_version\n";
               }
               #$operand = "=" if !defined $operand;
             }          
        }
      }
      close(DIFFERENCE);

      # GONE #

      # for some reason the value for "/." gets corrupted sometimes after
      # going through the @GONE loop .. so we will just carry it down, and
      # this seems to work fine.  As though that wasn't enough, sometimes
      # the same monster exists in both non-us and main, so we will have
      # to make provisions for this situation, otherwise the packages
      # relationship to changes will be incorrectly recognized.  This
      # means -qan will provide a strange listing with two packages with
      # the same name and then will be altered after
      # --ndb.  This causes all kinds of complications because nstatus is
      # indexed with the name not the name_version, but /. can include
      # both.  So for these two timers or more, we will watch for them,
      # and always use the newest version or the lack of it from both to
      # determine whether the package(s) is gone, new, changed, and
      # rewrite the entry for the two timer to be the newest, actually
      # they should be handled in the initial creation.  What this all
      # means is that the databases as well as querying capabilities will
      #  be designed to handle multiple versions of the same package.
      #
      # Actually, the best solution is to provide no provisions for
      # packages which exist with more than one version, just
      # use the newest version of the package getting rid of all
      # references to the packages for both --initndb & --ndb.  This
      # situation can also occur when swim fails to notice that two dists
      # are unique (i.e. personal vs Debian)  - a problem soon to be
      # resolved.
 
      my (@Old_packages,%OP);
      my @OLD_packages = split(" ",$nsb{"/."});
      foreach (@OLD_packages) {
        my $hinge = (split(/_/,$_))[0];
        push(@Old_packages,$hinge);
        $OP{$hinge}++;
        #print "$hinge\n" if $OP{$hinge} > 1;
      }

      my %tracker;
      grep($tracker{$_}++,@New_packages);
      my @GONE = grep(!$tracker{$_},@Old_packages);
      my @sgone = @GONE;
      foreach (@GONE) {
        print STDERR "GONE $_\n";
      }

      my $new=$#NEW + 1; my $cr=$#CHANGED_REV + 1; my $ch=$#CHANGED + 1; 
      my $gon= $#GONE + 1;
    if ($commands->{"check"}) {
      print "\n       TOTAL\n       -----\n";
      print "NEW $new\n"; print "GONE $gon\n";
      print "CHANGED $ch\n"; print "CHANGED REVISION $cr\n"; exit;
    }
      print "\n       TOTAL\n       -----\n";
      print "NEW $new\n"; print "GONE $gon\n";
      print "CHANGED $ch\n"; print "CHANGED REVISION $cr\n";


    my %BS; # Before State for .packagesdiff*
    my @BS = (@GONE,@NEW,@CHANGED,@CHANGED_REV) if $commands->{"Contents"};
    foreach (@BS) {
      $BS{$_} = "ok";
    }
    @GONE = (@GONE,@CHANGED,@CHANGED_REV);
    ##undef @GONE;
    @NEW = (@NEW,@CHANGED,@CHANGED_REV);    
    my @KGONE = @GONE if $commands->{"Contents"}; 
    #untie %db;
    #undef %db;
    #untie %nsb;
    #undef %nsb;

    # Remember to remove ndirindex..gz and nsearchindex..gz and r> r< do
    # not have to be completely updated in ncontentsindex*.deb, but
    # packagename_version will need to be removed


    # Time for some fun stuff
    # There are four states:  GONE - all information about this package
    # needs to be removed from the databases.  NEW - all information about
    # this package needs to be put in the databases.  CHANGED - a 
    # combination of the two previous, information could be cross
    # referenced and checked for changes, but it's probably no saving of
    # time, so first remove information from the same package of a
    # different version, then add the information about the package of the
    # new version (older or newer) CHANGED REVISION doesn't have to be run
    # through the nfile database (debian-revision). 

    #############
    #           #
    #   GONE    #
    #           #
    #############
    # GONE.  (reverse applies to NEW)
    #  For npackage-arch-dists.deb - Delete description 
    # (packagename_version), packagenameREP, packagenamePRO, 
    # packagenameDEP, packagenamePRE, packagenameREC,
    # packagenameSUG, packagenameCON, packagenameCONF. delete package ->
    # version.  
    #
    # for ncontentsindex-arch-dists.deb - 
    # Find all files and directories associated with the package. Delete
    # these files (keys). Find all directories where the file
    # exists..delete package name from value, delete whole key if it is the
    # only package name. 
    #
    # for ngroupindex - delete package name (value) from Section
    # it belonged to..humm, find section package belongs to in
    # nstatusuindex-arch-dists.deb, and delete whole Section key if only one.  
    #
    # for nstatusindex-arch-dists.deb -
    # delete package -> version group. 
    #
    # for flat files dirindex and searchindex -
    # the removal of files and/or directories can be put on hold, and
    # done with an option at a later time, since fileindex.deb remembers
    # current state, at a later time the old state of the flat files can be
    # compared to the new state of fileindex, and these files can be
    # rewritten.  This is all o.k. because these extra files or directories 
    # will return undef in search() if the packages don't exist.  
 
   # calling noram to turn off the ramdisk, don't want this on
   noram(\%commands);

   # might as well check to see it ncontentsindex-arch-dists-old.deb.gz
   # exits, if it doesn't and --Contents is called will give a
   # warning and quit, if it does time to remove ndirindex-arch-dists.gz
   # and nsearchindex-arch-dists.gz
   my ($ncontents,%packagediff);
   $ncontents = "no";
   if ($commands->{"Contents"}) {
      $ncontents = ncontents_exist(\%commands);
      if ($ncontents eq "no") {
        print "swim: database implied for --Contents does not exist\n";
        exit;
      }
    my $contentsdb = finddb(\%commands);
      if (-e "$contentsdb/.packagesdiff$arch$dist.deb") {
       open(PACKAGEDIFF,"$contentsdb/.packagesdiff$arch$dist.deb");
        while (<PACKAGEDIFF>) { 
         chomp; $packagediff{(split(m,_,,$_))[0]} = $_;
        }
       close(PACKAGEDIFF);
      }       
   }

   my $x = 1; 
   foreach (@GONE) {     
     print "G|C|CR $x\r";
     $x++;
     #next if $_ eq "/." || $_ eq "/.."; 
     #first delete keys from package.deb
      # If I kept this the name_version would be remembered.
      $ping->del($_); 
      my $orig_argument = $_;
      #my $packname_version = (split(/\s/,$nsb{$orig_argument}))[0];      
      # apache-common in .diff
      #print "1 $orig_argument\n" if !defined $packname_version;
      #print "2 $packname_version\n" if !defined $orig_argument;
      untie $sing;
      $argument = "$_";
      nver(\%commands);
       $ping->del($argument);
       my $conf = $argument . "REP";
       $ping->del($conf);
      $conf = $argument . "PRO";
       $ping->del($conf);
      $conf = $argument . "DEP";
       $ping->del($conf);
      $conf = $argument . "PRE";
       $ping->del($conf);
      $conf = $argument . "REC";
       $ping->del($conf);
      $conf = $argument . "SUG";
       $ping->del($conf);
      $conf = $argument . "CON";
       $ping->del($conf);
      $conf = $argument . "MD";
       $ping->del($conf);
      $conf = $argument . "FN";
       $ping->del($conf);
     untie $ping;

     # remove from the group, and if only one remove the group.  
     # Let's first find out which group this monster belongs to.
     if (defined $nsb{$orig_argument}) {
       (my $oa = $orig_argument) =~ s,\+,\\\+,g; 
       my($section) = (split(/\s/,$nsb{$orig_argument}))[1];
        if (defined $gb{$section}) {
          my $status = ($gb{$section} =~ s,$oa ,,);
          if ($status eq "") {
            $status = ($gb{$section} =~ s, $oa,,);
            if ($status eq "") {
              $gb{$section} =~ s,$oa,,;
            }
          }
          if ($gb{$section} eq "") {
            $ging->del($section);
          }
        }
     } 
    
   } # end foreach OLD   


    # Time to use ncontentsindex-arch-dists.deb.gz and hunt down all
    # directories and files, the trick would be doing this in one loop which
    # would speed things up.  We better umount dramdisk if it is mounted
    # and delete ndirindex-arch-dists.deb.gz and nsearchindex-arch-dists.deb.gz
    # Moreover, this operation shouldn't be performed unless  --Contents
    # was called, and only if ncontentsindex-arch-dists.deb exists - in this 
    # case it will just skip on, otherwise the other databases will get
    # corrupted.  
    # The new ncontents-arch-dists.deb.gz can be copied over the argument
    # to --Contents or its location in DF.
    # we will do the checks and removals here .. better be --Contents.

	    print "\n" if $#GONE != -1;
    $x = 1; 
    foreach (@GONE) {     
      my $orig_argument = $_;
      my $packname_version = (split(/\s/,$nsb{$orig_argument}))[0];      
      $packname_version =~ s,\+,\\\+,g; 
    ################################
    # NFILEINDEX-ARCH-DISTS.DEB.GZ #
    ################################
    if ($commands->{"Contents"}) {
     if ($commands->{"Contents"} !~ /^FDB/) {
      if (!defined $packagediff{$orig_argument}) {
       my $subject = (split(/\s/,$nsb{$orig_argument}))[1];
       my (@file) =
       remove_add_nfile($orig_argument,$ncontents,$subject,\%commands);
       my $file = "$orig_argument.list";
       print "#$x VIRTUAL G|C|CR $file            \r";
       $x++;
       foreach (@file) {
         if (defined $ib{$_}) {
          my $status = ($ib{$_} =~ s,$packname_version ,,);
          if ($status eq "") {
            $status = ($ib{$_} =~ s, $packname_version,,);
            if ($status eq "") {
              $ib{$_} =~ s,$packname_version,,;
            }
          }
          if ($ib{$_} eq "") {
            $zing->del($_);
          }
         } # if defined        
       } # foreach
      }
     }
    }
     # Now ditch the package->version group in nstatusindex-arch-dist.deb
     # And redo /.
     $sing->del($orig_argument);
     untie $sing;
    } 

  # constantly deleting /. didn't work too well, so will do a one time
  # thing.  I found out that this value needs to be put in twice before
  # it sticks which would indicate that "/." already exists and
  # doesn't want to be removed (now you can delete it the first time),
  # basically something weird is going on because /.. is being
  # created at the very top of this module, and
  # it is being mistaken for /.  When --Contents is ran GONE and
  # CHANGED in @GONE are being chomped somewhere in a way that they still
  # exist in @GONE but aren't ""..in fact /[\w\.\+-] matches.

  if ($#GONE != -1) {   
   @GONE = @KGONE if $commands->{"Contents"}; 
  foreach (@GONE) {
    if (defined $OP{$_}) {
       delete $OP{$_};
    }
  }
  my @Orig_packages = sort keys %OP; my $rs;
  #print "AFTER GONE $#Orig_packages\n"; 
  foreach (@Orig_packages) {
    if ($_ ne "/." && $_ ne "/..") {
     my $pv = (split(/\s/,$nsb{$_}))[0];      
     !defined $rs ? ($rs = $pv) : ($rs = $rs . " $pv");
    }
  }
  $sing->del("/."); $sing->del("/.");  # no thing
  $sing->put("/.","$rs"); $sing->put("/.","$rs");
  }

  # the new ncontentsindex-arch-dists.deb.gz needs to be set-up now.
  if ($ncontents ne "no") {
   if ($commands->{"Contents"} !~ /^FDB/) {
     print "\n";
     defined $contents ?    
     compress_contents($contents,\%commands) :
     compress_contents(find_contents(\%commands),\%commands);     
   }
  }


   #############
   #           #
   #   NEW     #
   #           #
   #############


   my ($ok,$goon1,$goon,$filename,@FILENAME,$distro);
   my (%exacts,@package,$essential,$version,$maintainer,$things,
       $priority,%group,$group,$section); 
   my ($pre_depends,$depends,$replaces,$provides,$recommends, 
       $suggests, $conflicts, @REPLACE);
   my (@ldescription,@description,$installed_size,$source,$size,$status);
   my $scount = 0; my $count = 0;
   undef %equalizer;

   my $format_deb = "$tmp/format.deb";
   my @NEW_AND_REV = (@NEW,@CHANGED_REV);
   foreach (@NEW_AND_REV) {
     $exacts{$_} = "yes";
   } 

    $x = 1;
    open(PRETTY, ">$format_deb");
    open(PACKAGE, "$packagesgz");
     while (<PACKAGE>) {
       # Package name
        if (/^Package:/i) {                                              
          @package = split(/: /,$_);                                                  
          chomp $package[1];
          if (defined $exacts{$package[1]}) {
             print "N|C|CR $x\r"; 
             $x++; $goon1 = "yes";
          }
          else {
             $goon1 = "no";
             undef @package;
             next;
          }
       }         
       elsif ($goon1 eq "no") {
         next;
       }
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
              }
              else {
                  $group{$group} = "$group{$group} $package[1]";
              }
       }
       elsif (/^Essential/) {
           ($essential) = (split(/: /,$_))[1];                                                  
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
         # It can't be assumed that the right database is being used.
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
                 #print "no need to do it again\n";
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
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $pre_depends;
               }               
               if (defined $depends) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $depends;        
               }               
               if (defined $recommends) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $recommends;
               }               
               if (defined $suggests) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $suggests;
               }               
               if (defined $conflicts) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $conflicts;
               }               
               if (defined $provides) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $provides
               }               
               if (defined $replaces) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
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
                # some of these things don't need to be undefed because
                # they will be reset, because of the next.
                undef $priority if defined $priority;
                undef $section if defined $section;      
                undef $group if defined $group;
                undef $essential if defined $essential;
                undef $maintainer if defined $maintainer;
                $goon = "yes";
                next;
             }  
             else {
               undef $goon;
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
               ###########
               # REPLACE #
               ###########
               # this keeps deps correct
               if (defined $pre_depends) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $pre_depends;
               }               
               if (defined $depends) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $depends;        
               }               
               if (defined $recommends) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $recommends;
               }               
               if (defined $suggests) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $suggests;
               }               
               if (defined $conflicts) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $conflicts;
               }               
               if (defined $provides) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
                  undef $provides
               }               
               if (defined $replaces) {
                  undef @REPLACE;
                  #pop(@REPLACE); pop(@REPLACE);
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
                # some of these things don't need to be undefed because
                # they will be reset, because of the next.
                undef $priority if defined $priority;
                undef $section if defined $section ;      
                undef $group if defined $group;
                undef $essential if defined $essential;
                undef $maintainer if defined $maintainer;
                next;
           } # wrong distribution
         }

       ############
       # ######## #
       # # MAIN # #
       # ######## #
       ############
       # From here on we can start putting stuff in the databases
       elsif (defined $ok) { 
         # first the package relationships
         if (defined @REPLACE) {
           my %relationship = @REPLACE;
           foreach (keys %relationship) {
              $ping->put($_,$relationship{$_});  
           } 
           undef @REPLACE; 
         }
         # second the groups
         if (defined %group) {
            if (!defined $gb{$group}) {
              $ging->put($group,$package[1]);
            }
            else {
              my $change_group = "$gb{$group} $package[1]";
              $ging->del($group);
              $ging->put($group,"$change_group");
            }
            undef %group;
         }
         # third Filename
         if (defined @FILENAME) {
           my %filename = @FILENAME;
           foreach (keys %filename) {
            $ping->put($_,$filename{$_});  
           }
           undef @FILENAME;
         }  
         if (/^Size:/) {
           $size = $_;      
           chomp;
         }
         # fourth the MD5
         elsif (/^MD5sum/) {
           chomp;
           my $md5sum = substr($_,8);
           chomp $md5sum;
           my $vion = substr($version,9);
           my $nv = "$package[1]" . "_" . "$vion" . "MD"; 
           $ping->put($nv,$md5sum);  
         }

        # To be combined with first fields.  There are no packages
        # missing this field, unlike a status file. 
        # defined either at architecture or filename.
        elsif (m,Description:|^\s\w*|^\s\.\w*|^installed-size:|^revision:,){ 
          # this solved an annoying problem
          if (/^\n$/) {
                next;
           } 
           chomp $version;
           $version =~ m,Version:\s(.*),; my $ending = $1;
           my $many_lines = $_;
           if ($_ !~ /^installed-size:|^revision:/) {
             $count++;
             if ($count == 1) {
               if (defined $package[1]) {
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
             my $name = $package[1]; my $name_ver = "$package[1]_$1";
             $ping->put($name,$name_ver);
             #$package[1] = "$package[1]_$1";
             my $priory = substr($priority,10); chomp $priory;
             my $thimk = "$name_ver $group $priory";
             $sing->put($name,$thimk);
            if(defined($essential)) {              
             $col2 = "Essential: $essential";
             $essential = ();
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
            $ping->put($rr,$prr);
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
             my $name = $package[1]; my $name_ver = "$package[1]_$1";
             $ping->put($name,$name_ver);
             #$package[1] = "$package[1]_$1";
             my $priory = substr($priority,10); chomp $priory;
             my $thimk = "$name_ver $group $priory";
             $sing->put($name,$thimk);
            if(defined($essential)) {              
             $col2 = "Essential: $essential";
             $essential = ();
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
     } # end while PACKAGE

    close(PRETTY);
    close(PACKAGE); 

  # put /. in nstatus
  if (defined $things) {
   if ($things =~ /^\s.*/) {
     $things =~ s/^\s//;
   }
   $things = $nsb{"/."} . " $things";
   $sing->del("/.");
   $sing->put("/.",$things);
  }

  # Let's put together the description with the rest of its fields.
  my(@form,@formly,@complete);
  open(FIELDS,"$format_deb");
  while (<FIELDS>) {
     push(@form,$_);
  }
  close(FIELDS);  
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
  
  my $name_version;
  foreach (@description) {
   if ($count == 1) {
     # -i
     my $lingo = shift(@complete);
     $lingo = $lingo . $_;
     $ping->put($name_version,$lingo);
     $lingo = ();
     $count = 1;
   }
   else {
     # packagename_version
     $name_version = $_;
     $count = 0;
   }
   $count++;
   untie $ping;
 }
 undef $ping;
 unlink($format_deb);

   ###########################################
   # NEW FILE/DIR  NFILEINDEX-ARCH-DISTS.DEB #
   ###########################################
   # add the files/dirs
   if ($commands->{"Contents"}) {
    if ($commands->{"Contents"} !~ /^FDB/) {
     my $package_name;

     # we have come this far so we get to do the three steps.
     #
     # a). remove GONE (not CHANGED) from %packagediff
     # b). if find in @NEW it is CHANGED so remove from %packagediff
     # c). throw whats left into @NEW because files/dirs probably exist
     #     now.
     # Any files returning 0 bytes will be dealt with below, first by
     # creating a new .packagesdiff-arch-dist.deb, and second by being
     # recorded in %ib.  If the old .packagesdiff is
     # still 0 (it isn't GONE) it will be placed in .packagesdiff again.
     # No double dipping allowing in %ib if an old fellow exists from .pd.
     # so $zing->del("/."); $zing->put("/.",$nsb{"/."});  
     # Everything is in %nsb now, anyways. No .contentsdiff-arch-dist.deb
     # is created for --ndb
   
     if ($#NEW != -1) {

     foreach (@sgone) {
      delete $packagediff{$_};
     }
     foreach (@NEW) {
      delete $packagediff{$_};
     }
     foreach (keys %packagediff) {
        push(@NEW,$_);
     }
 
     print "\n" if $#NEW != -1;
     ndb(\%commands);  $x = 1;
     unlink("$tmp/nsearchindex.deb") if -e "$tmp/nsearchindex.deb";
     foreach $package_name (@NEW) {
      # And a good place to set-up /. properly for CR as well as
      # anything found in $packagediff if files aren't found, yet. 
      if (!defined $packagediff{$package_name}) {
        my $subject = (split(/\s/,$nsb{$package_name}))[1];
        my (@file) =
        remove_add_nfile($package_name,$ncontents,$subject,\%commands);
        my $file = "$package_name.list";
        print "#$x"; print " VIRTUAL N|C|CR $file             \r";
        $x++;

        if ($#file != -1) {
        foreach (@file) {
        #open(LIST,"$file"); 
        #while (<LIST>) {
          #chomp;

          # This all looks nice, except for one thing we need to know
          # whether an element pertains to one or more packages.  Knowing
          # something isn't a directory doesn't cut it, this differs
          # greatly from SWIM::DB::db.  That's why we create one big file
          # here, and stick everything in the search db's after nfile* is
          # updated.
          if (!defined $ib{$_}) {
             open(SEARCHINDEX,">>$tmp/nsearchindex.deb");
             print SEARCHINDEX "$_\n";
             close(SEARCHINDEX);
          } # !defined

          # If the directory already exists we can just append 
          # to the end of the value
          if (defined $ib{$_}) {
              my $cvalue = $ib{$_} . " $db{$package_name}";
              #my $status = $zing->del($_);
              $zing->put($_,$cvalue);   
          } # if defined        
          else {
              $zing->put($_,$db{$package_name});    
          }
        }
       #close(LIST);  
       #unlink("$file") if -e $file;
        } # if file is 0 size
        else {
           # no sense putting non-US or experimental in here unless this 
           # is what is wanted. Only need to check for group non-us/*
           # This is suppose to work, but not always.
           if (!$commands->{"nue"}) {
              if (defined $nsb{$package_name}) {
               next if (split(/\s/,$nsb{$package_name}))[1] =~ m,non-us,;
              }
              if ($dist eq "experimental") {
                next;
              }
           }
           elsif ($dist eq "experimental") {
            if (!$commands->{"nue"}) {
              if (defined $nsb{$package_name}) {
               next if (split(/\s/,$nsb{$package_name}))[1] =~ m,non-us,;
              }
            }
           }
          open(PACKAGEDIFF,">>$place/.packagesdiff$arch$dist.deb.bk")
          or warn "Couldn't create packagediff\n";
          print PACKAGEDIFF "$db{$package_name}\n" 
           if $db{$package_name} ne ""; 
          close(PACKAGEDIFF);
          #unlink("$file") if -e $file;
        }
      }
     }  # end foreach NEW 

   ############################################
   # CHECKING CONTENTS FOR UNCHANGED PACKAGES #
   ############################################  
   my @PDbk;
   if (-e "$place/.packagesdiff$arch$dist.deb") { 
    open(PD, "$place/.packagesdiff$arch$dist.deb");
     while (<PD>) {
       my $package_name = (split(/_/,$_))[0];
       if (!defined $BS{$package_name}) {
         push(@PDbk,$_);
       }
     }
    close(PD);
   } 
   !-e "$place/.packagesdiff$arch$dist.deb" or
   unlink("$place/.packagesdiff$arch$dist.deb");
   rename("$place/.packagesdiff$arch$dist.deb.bk",
          "$place/.packagesdiff$arch$dist.deb");
   if (defined @PDbk) {
     print "\n"; $x = 1;  
     # now we get to add a few more seconds checking to see if packages
     # which haven't changed can now be found in Contents, so
     # .packagesdiff* and nfile* can be proper. It's good to remember not
     # changed as not CR or G. A little accounting would be nice.
     foreach (@PDbk) {
      my $o_name = $_;
      my $package_name = (split(/_/,$_))[0];
      my $subject = (split(/\s/,$nsb{$package_name}))[1];
      my (@file) =
      remove_add_nfile($package_name,$ncontents,$subject,\%commands);
      my $file = "$package_name.list";
      print "#$x"; print " NO-C $file             \r";
      $x++;
        if ($#file != -1) {
        foreach (@file) {

          # This all looks nice, except for one thing we need to know
          # whether an element pertains to one or more packages.  Knowing
          # something isn't a directory doesn't cut it, this differs
          # greatly from SWIM::DB::db.  That's why we create one big file
          # here, and stick everything in the search db's after nfile* is
          # updated.
          if (!defined $ib{$_}) {
             open(SEARCHINDEX,">>$tmp/nsearchindex.deb");
             print SEARCHINDEX "$_\n";
             close(SEARCHINDEX);
          } # !defined

          # If the directory already exists we can just append 
          # to the end of the value
          if (defined $ib{$_}) {
              my $cvalue = $ib{$_} . " $db{$package_name}";
              #my $status = $zing->del($_);
              $zing->put($_,$cvalue);   
          } # if defined        
          else {
              $zing->put($_,$db{$package_name});    
          }
        }
        } # if file is not 0 size
        else {
           # no sense putting non-US or experimental in here unless this 
           # is what is wanted. Only need to check for group non-us/*
           # This is suppose to work, but not always.
           if (!$commands->{"nue"}) {
              my $name = (split(/_/,$o_name))[0];
              if (defined $nsb{$name}) {
               next if (split(/\s/,$nsb{$name}))[1] =~ m,non-us,;
              }
              if ($dist eq "experimental") {
                next;
              }
           }
           elsif ($dist eq "experimental") {
            if (!$commands->{"nue"}) {
              my $name = (split(/_/,$o_name))[0];
              if (defined $nsb{$name}) {
               next if (split(/\s/,$nsb{$name}))[1] =~ m,^non-us/.*$,;
              }
            }
           }
         open(PD, ">>$place/.packagesdiff$arch$dist.deb");
         print PD "$o_name" if $o_name ne "";
         close(PD);
        }
     }    
   }   
  $zing->del("/."); $zing->put("/.",$nsb{"/."}); 

   # now nsearch* and ndir* can be updated search() style
   ##############################
   # APPENDING SEARCH DATABASES #
   ##############################
   print "\nAppending search databases\n";
   open(SEARCH,"$tmp/nsearchindex.deb");
   open(SEARCHINDEX,">>$place/nsearchindex$arch$dist.deb");            
   open(DIRINDEX,">>$place/ndirindex$arch$dist.deb");                  
    while (<SEARCH>) {
     chomp;
     if (defined $ib{$_}) {
      my @dir = split(/\s/,$ib{$_});
      $#dir == 0 ? print SEARCHINDEX "$_\n" : print DIRINDEX "$_\n";
     }
    }
     untie %db; untie $zing;
     } # prevents loop being entered in $#NEW is -1 
       # and --check isn't called.   
    }
   }

   
   ############
   # N STATUS #
   ############
   } # status_only
   if (!$commands->{"check"}) {
   my $yep = exist_sb(\%commands);
   if (defined $yep) {
   # now we update the status for N|G|CR|C packages.  We will use
   # statusindex.deb since all the figuring has already been done here,
   # at first I was thinking of going through status, but this is
   # unecessary, although it would alow n* to be updated before --db is
   # used.  Next, edit the status field in the description in npac*
   # This checks everything in sb, it would be nice just to do an
   # individual change or --db, but the issue of which n* should be used
   # arises.
   nping(\%commands); # because undefed before loop and ndb is used    
   print "Updating status\n"; my $x = 0;
    foreach (keys %nsb) {
    if (defined $sb{$_}) { 
     my ($veri,$stati) = (split(/\s/,$sb{$_}))[0,3]; $stati =~ s,:, ,g; 
     $veri = (split(/_/,$veri))[1]; my $vern;
     if (defined $nsb{$_}) {
      $vern = (split(/_/,((split(/\s/,$nsb{$_}))[0])))[1]; 
      $x++;
     }
     else { next; }
     my $operand = comparison($vern,$veri);
     compare_versions($operand,$vern,$veri,$_,\%commands) if
       $commands->{"v"} && $operand ne "";     
     if (defined $db{$db{$_}}) {
      if ($db{$db{$_}} !~ m,Package:.+Status: $operand $stati \($veri\)|
                            Package:.+Status: $stati,x) { 
       $operand ne "" ? 
         ($db{$db{$_}} =~ s,Status:.*,Status: $operand $stati \($veri\),) :
         ($db{$db{$_}} =~ s,Status:.*,Status: $stati,);
      }
     }
    } # if found in statusindex
    elsif (defined $db{$_}) {
     if ($db{$db{$_}} =~ m,Package:.+Status:\s.*[^not-]+installed|
                             Package:.+Status:\s.*unpacked|
                             Package:.+Status:\s.*half-configured|
                             Package:.+Status:\s.*config-files,x) {
       $db{$db{$_}} =~ s,Status:.*,Status: not-installed,;
     }
    }
    } # foreach
   print STDERR "$x installed packages found in n*\n" if defined $x;
   }
   }


   unlink("$tmp/nsearchindex.deb") if -e "$tmp/nsearchindex.deb";
   print "\n" if $#NEW != -1;
   print "$begin  to  ", scalar(localtime), "\n";

} # end sub update_packages_ndb

# Generally, it's unecessary to rebuild the flat databases unless major
# changes have occurred to a person's installation, and the database has
# become very repetitive, or a file has changed into a directory.  This
# function has also been tried by tieing the flat file to an array, but
# there doesn't seem to be that much of a speed advantage unless ib()
# happens to be in memory, but more experimentation will be tried in the
# future.  Unfortunately for ni..keys %ib is not giving the proper amt. of
# elements unless used with DB_File compiled with libdb2.
sub rebuildflatndb {

  my($commands) = @_;
  my %commands = %$commands;
  nzing(\%commands);

  print scalar(localtime), "\n";
 
  my ($arch,$dist) = which_archdist(\%commands);
  my ($file,$dir);

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     !($commands->{"dbpath"} && $commands->{"root"})) {
        if (-e "$main::home$parent$library/nsearchindex$arch$dist.deb") {
            $dir = "$main::home$parent$library/ndirindex$arch$dist.deb";
            $file = "$main::home$parent$library/nsearchindex$arch$dist.deb";
            unlink($file);
            unlink("$file.gz") if -e "$file.gz";
            unlink($dir);
            unlink("$dir.gz") if -e "$dir.gz";
        } 
        else {
	    print "swim: operation only implemented for installed system\n";
	    exit;
       	}
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
        if (-e "$main::home$parent$base/nsearchindex$arch$dist.deb") {
            $file = "$main::home$parent$base/nsearchindex$arch$dist.deb";
            $dir = "$main::home$parent$base/ndirindex$arch$dist.deb";
            unlink($file);
            unlink("$file.gz") if -e "$file.gz";
            unlink($dir);
            unlink("$dir.gz") if -e "$dir.gz";
         }
        else {
	    print "swim: operation only implemented for installed system\n";
	    exit;
        }
  }

  # HERE'S where it all happens
  # We need to reconstruct long.debian & DEBIAN*, but can't take into account
  # weirdisms with the database - NEW packages which aren't NEW.
  open(DIR,">$dir");
  open(FILE,">$file");
  foreach (keys %ib) {
   if (defined $ib{$_}) { 
       my $filedir = $_;
       my $package = $ib{$_};
       my @the_amount  = split(/\s/, $package);
     if ($#the_amount > 0) {
       print DIR "$filedir\n";
     }
     elsif ($#the_amount == 0) {
       print FILE "$filedir\n";
    }
   }
  }
  #untie %ib;
  print scalar(localtime), "\n";

} # end sub rebuildflatndb


1;
