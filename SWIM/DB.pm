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


package SWIM::DB;
use strict;
use SWIM::DB_Library qw(:Db);
use SWIM::Format;
use SWIM::Conf qw(:Path);
use SWIM::Global;
use vars qw(@ISA @EXPORT_OK);
   
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(db rebuildflatdb);

# --db --rebuildflatdb  db() rebuildflatdb()

# The goal here is to save some time by just updating the database rather
# than rebuilding it.  Generally, though, swim -i <package> would be the
# favorable way of doing this, and ultimately may become the primary way of
# setting up the databases after the required packages for this program are 
# set-up.  This is because --db has to check the status file, whereas -i
# uses statusindex.db, and grabs package information right from the
# package, there are exceptions to this, certain things like the status
# will have to be found from the status file or some other method.
sub db {

  # Well, we better check for any changes in the status file, before we
  # attempt anything. This is made easy by the version reference hash created
  # when --initdb or --rebuilddb is run, and then comparing this to the new
  # results when --db is run.  Only then will we process, add, and remove
  # packages when we know what is gone, and what is new (whether its a 
  # new package name, or a package with a new version or older version).
  # The statusindex.deb could be used for version checking, instead the
  # important status field is compared, so if we have situations like 
  # "deinstall ok config-file" this will be recognized as a CHANGE.  The
  # update takes place so that the status field remain proper.

  my ($commands) = @_;
  my %commands = %$commands;

  # description stuff
  my (@description, @ldescription);
  # my @dpackage; # not needed here
  
  # does status exist
  my $the_status; 

  # Keep track of changes to the status file
  my $rootsky = "/.";
  my @package;
  my @name;
  my $status;
  my @changed_packages;
  my @gone;
  my (@GONE, @CHANGED, @NEW);
  my @before;
  my %compare;

  # The mys for NEW
  my $count = 0;
  # a special one to deal with package[1] version change.
  my $packv; 
  my (@essential,$priority,$section,$installed_size,$maintainer,$source);
  my (%group, $group);

  # Keeps a package->version database 
  # to save time over using status
  my @status;
  my ($replaces, $provides, $depends, $pre_depends, $recommends, $suggests, 
      $conflicts);
  my (@conffiles,$line_before,@conf,@complete,@form,@formly);
  my $format_deb = "$tmp/format.deb";

  dbi(\%commands); ib(\%commands); sb(\%commands);
  # Check differences now.
  print "checking for new, changed, and removed packages\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
      open(DIFFERENCE,"$parent$library/status");
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
      open(DIFFERENCE,"$parent$base/status");
  }
      while (<DIFFERENCE>) {
       # Package name
        if (/^Package:/i) {             
          @package = split(/: /,$_);                                   
          chomp $package[1];
        } 
        elsif (/^Status:/) {
            chomp;
            $status = substr($_,8);
            # a test
            #if ($status eq "purge ok not-installed") {
            #  if (defined $db{$package[1]}) {
            #   print "$db{$package[1]}\n";
            #  }
            #}
        }
        # hold ok not-installed - may want to change this just to
        # non-installed.
        ###########
        # VERSION #
        ###########
        elsif (/^Version:/ && $status !~ /not-installed/) {
             my $version = $_; chomp $version;
             my $ver = m,Version:\s(.*),; my $statusname;
             if (defined $sb{$package[1]}) { 
              $statusname = (split(/\s/,$sb{$package[1]}))[3];
              $statusname =~ s/:/ /g;
             }
              ########
              # GONE #
              ######## 
              if (defined $db{$package[1]}) {
                 push(@gone,"$package[1]_$1");
               if ("$package[1]_$1" ne $db{$package[1]}) {
                  $compare{$package[1]} = "$package[1]_$1";
               }
              # Version remained the same, but status changed
              # even though $statusname may be undefined..this
              # routine is only done when it does exist. 
              ######
              # CR #
              ######
              elsif ("$package[1]_$1" eq $db{$package[1]} &&
                     $statusname ne $status) {
                 push(@changed_packages, "$package[1]");
                 $compare{$package[1]} = "$package[1]_$1";
              }
             }
             #######
             # NEW #
             #######
             elsif (!defined $db{$package[1]}) {
                 push(@NEW,$package[1]);
                 $compare{$package[1]} = "$package[1]_$1";
                 push(@gone,"$package[1]_$1");
             }
        }
      }
      close(DIFFERENCE);
      
    # lets find what existed before, ofcourse mistakes in /. better be
    # taken care of beforehand, because this ignores those here.  Some time
    # may have been saved by using a separate database rather than /., but,
    # this keeps things clean.
    if ($ib{$rootsky}){
      @before  = split(/\s/,$ib{$rootsky});
      my %tracker;
      grep($tracker{$_}++,@gone);
      my @goners = grep(!$tracker{$_},@before);
      foreach (@goners) {
         m,(^.*)_.*$,;
         if (!defined $compare{$1}) {
            push(@GONE,$1);
         }
         else {            
            # these will be process like @GONE for original, and @NEW for
            # new
           push(@CHANGED,$1);
         }
      }      
     }
     else {
       print "swim: missing important database\n"; return "missing";
     }
    
     foreach (@GONE) {
        print "GONE $_\n";
     }
     foreach (@CHANGED) {
       print "CHANGED $_\n";
     }
     foreach (@changed_packages) {
       push(@CHANGED,$_);
       print "CHANGED STATUS $_\n";
     }
     foreach (@NEW) {
      print "NEW $_\n";
     }

      my $new=$#NEW + 1; my $cr=$#changed_packages + 1;
      my $ch=($#CHANGED + 1) - $cr; my $gon= $#GONE + 1;


    if ($commands->{"check"}) {
      print "\n       TOTAL\n       -----\n";
      print "NEW $new\n"; print "GONE $gon\n";
      print "CHANGED $ch\n"; print "CHANGED STATUS $cr\n"; 
      return 1;
    }
      print "\n       TOTAL\n       -----\n";
      print "NEW $new\n"; print "GONE $gon\n";
      print "CHANGED $ch\n"; print "CHANGED STATUS $cr\n";


    @GONE = (@GONE,@CHANGED);
    @NEW = (@NEW,@CHANGED);

    undef @before; # can use below.
    untie %db;
    undef %db;
    untie %ib;
    undef %ib;

    # Going to be adding some stuff to nsearchindex.deb and ndirindex.deb
    # so better remove any compressed versions if they exist
    if (@GONE || @NEW) {
     if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
         if (-e "$main::home$parent$library/searchindex.deb") {
             unlink("$main::home$parent$library/searchindex.deb.gz");
             unlink("$main::home$parent$library/dirindex.deb.gz");
         } 
     }
     elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
         if (-e "$main::home$parent$base/searchindex.deb") {
             unlink("$main::home$parent$base/searchindex.deb.gz");
             unlink("$main::home$parent$base/dirindex.deb.gz");
          }
     }
    }


    # Time for some fun stuff
    # There are three states:  GONE - all information about this package
    # needs to be removed from the databases.  NEW - all information about
    # this package needs to be put in the databases.  CHANGED - a 
    # combination of the two previous, information could be cross
    # referenced and checked for changes, but it's probably no saving of
    # time, so first remove information from the same package of a
    # different version, then add the information about the package of the
    # new version (older or newer) 

    #############
    #           #
    #   GONE    #
    #           #
    #############
    # GONE.  (reverse applies to NEW)
    #  For package.deb - Delete description 
    # (packagename_version), packagenameREP, packagenamePRO, 
    # packagenameDEP, packagenamePRE, packagenameREC,
    # packagenameSUG, packagenameCON, packagenameCONF. delete package ->
    # version.  
    #
    # for fileindex.deb - 
    # Find all files and directories associated with the package. Delete
    # these files (keys). Find all directories where the file
    # exists..delete package name from value, delete whole key if it is the
    # only package name. 
    #
    # for groupindex - delete package name (value) from Section
    # it belonged to..humm, find section package belongs to in
    # statusuindex.deb, and delete whole Section key if only one.  
    #
    # for statusindex.deb -
    # delete package -> version group. 
    #
    # for flat files dirindex and searchindex -
    # the removal of files and/or directories can be put on hold, and
    # done with an option at a later time, since fileindex.deb remembers
    # current state, at a later time the old state of the flat files can be
    # compared to the new state of fileindex, and these files can be
    # rewritten.  This is all o.k. because these extra files or directories 
    # will return undef in search() if the packages don't exist.  
 
    ping(\%commands); # uses $ping for package.deb
    zing(\%commands); # uses $zing for fileindex.deb
    ging(\%commands); # uses $ging for groupindex.deb
    sing(\%commands); # uses $sing for statusindex.deb

   $| = 1; my $x = 1;
   foreach (@GONE) {
     print "G|C|CS $x $_.list\r";
     $x++;
     #first delete keys from package.deb
      # If I kept this the name_version would be remembered.
      $ping->del($_);
      my $orig_argument = $_;
      my $packname_version = (split(/\s/,$sb{$orig_argument}))[0];      
      $packname_version =~ s,\+,\\\+,g;
      $argument = "$_";
      ver(\%commands);
       $ping->del($argument);
      my $conf = $argument . "CONF";
       $ping->del($conf);
      $conf = $argument . "REP";
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
     untie $ping;

    # next let's go into fileindex.deb and hunt down all directories and
    # files associated with this package.  It would be kind of nice to use
    # package_name.list, but it's probably more realistic not to depend on
    # the existence of these file..unless a backup is made.  Now if -i is used
    # this would be a simple matter, but in this case things are different.
    # A database to accomplish this wasn't realistic, so the backup
    # files for *.list are in ./info/backup/*.list.bk.  We will also have to
    # deal with those rare cases that forget /. (smail 2.0v).  We should remove
    # this file as well as the packagename-conf.md5sums file below.
    my $file = "$parent$base/info/backup/$_.list.bk";
    my $md5sum_file = "$parent$base/info/$_-conf.md5sums";
     open(LIST,"$file");
     while (<LIST>) {
       chomp;
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
     }
    close(LIST);  
    unlink("$file");

       #######################  
       # deinstall situation #
       #######################
       my $yit = (split(/\s/,$sb{$orig_argument}))[3];
       if ($yit eq "deinstall:ok:config-files" || 
           $yit eq "purge:ok:config-files") {
        if (defined $ib{"/."}) {
          my $status = ($ib{"/."} =~ s,$packname_version ,,);
          if ($status eq "") {
            $status = ($ib{"/."} =~ s, $packname_version,,);
            if ($status eq "") {
              $ib{"/."} =~ s,$packname_version,,;
            }
          }
          if ($ib{"/."} eq "") {
            $zing->del($_);
          }
        } # if defined        
       } # deinstall situation

    if (-e $md5sum_file) {
     unlink("$md5sum_file");
    }

     # remove from the group, and if only one remove the group.  
     # Let's first find out which group this monster belongs to.
     if (defined $sb{$orig_argument}) {
        (my $oa = $orig_argument) =~ s,\+,\\\+,g;
        my($section) = (split(/\s/,$sb{$orig_argument}))[1];
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
    
     # Now ditch the package->version group in statusindex.deb
     $sing->del($orig_argument);
     untie $sing;

   } # end foreach OLD   

   print "\n" if $#GONE != -1 && $#NEW == -1;

   #############
   #           #
   #   NEW     #
   #           #
   #############
   if (-e "$parent$base/status" && -e "$parent$base/info") {
       $the_status = "$parent$base/status";
   }
   else {
       print "swim: crucial file(s)/directories are missing in $parent\n";
       exit;
   }
   my %exacts;
   my $goon;
   print "\n" if $#NEW != -1; $x = 1;
   foreach (@NEW) {
     $exacts{$_} = "yes";
   } 
     # first let's find the fields to put into packages.deb
     # We'll have to go through the status file again, something we
     # wouldn't have had to do with swim -i.  As it turns out, a good
     # percentage of the information can be processed into the database
     # while going through status.
    open(PRETTY, ">$format_deb");
    open(AVAIL, "$the_status");
      while (<AVAIL>) {
      # here's the difference with database(), we just find the packages
      # which belong to the hash %exacts
       # Package name
        if (/^Package:|^PACKAGE:/) {                                              
          @package = split(/: /,$_);                                                  
          chomp $package[1];
          if (defined $exacts{$package[1]}) {
             print "N|C|CS $x\r"; $x++;
             $goon = "yes";
          }
          else {
             $goon = "no";
             undef @package;
             next;
          }
        } 
       elsif ($goon eq "no") {
         next;
       }
       elsif (/^Status:/) {
            $status = $_;
        }
        elsif (/^Essential/) {
           @essential = split(/: /,$_);                                                  
        }
        # missing priority and section will be dealt with below
        elsif (/^Priority:/) {
            $priority = $_;
        }
        elsif (/^Section:/) {
            $section = $_;
            # make the hash for the groupindex.deb
            $group = substr($section,9);
            chomp $group;
            # we will put not-installed in their own group for reference
            if ($status !~ /not-installed/) {
              if (!defined $gb{$group}) {
                   $ging->put($group,$package[1]);
              }
              else {
                  my $change_group = "$gb{$group} $package[1]";
                  $ging->del($group);
                  $ging->put($group,"$change_group");
              } 
            }
        }
        elsif (/^Installed-Size:/) {
            $installed_size = $_;
        }
        elsif (/^Maintainer:/) {
            $maintainer = $_;
        }
        elsif (/^Source:/) {
            $source = $_;
        }
        # hold ok not-installed - may want to change this just to
        # non-installed.
        elsif (/^Version:/ && $status !~ /not-installed/) {
            my $version = $_;
            chomp $version;
            ###########
            # SECTION #
            ###########
            if ($section) {
              chomp $section;
            }
            else {
              nsb(\%commands);
              if (defined $nsb{$package[1]}) {
                my ($nvname,$ngname,$npriorname) =
                split(/\s/,"$nsb{$package[1]}",3);
                $group = $ngname;
              } 
              else {
                $group = "unavailable";
              }
            }
            $col1 = "Package: $package[1]";
            $col2 = $status;
            write PRETTY;
            $col1 = $version;
            my $ver = m,Version:\s(.*),;         
             # This creates a name -> version index in package.deb,
             # and the statusindex.deb database which will serve to
             #  determine if the status has changed when  --db or -i is
             # run.
             $packv = "$package[1]_$1";
             $ping->put($package[1],$packv);
             my ($priory,$statusy);
             ############
             # PRIORITY #
             ############
             if ($priority) {       
              $priory = substr($priority,10);
             }
             else {
              nsb(\%commands);
              if (defined $nsb{$package[1]}) {
                my ($nvname,$ngname,$npriorname) =
                split(/\s/,"$nsb{$package[1]}",3);
                $priory = $npriorname;
              }
              else {
                $priory = "unavailable";
              }
             }
             chomp $priory;
             $statusy = substr($status,8);
             chomp $statusy;
             $statusy =~ s/\s/:/g;
             my $thimk = "$packv $group $priory $statusy";
             $sing->put($package[1],$thimk);
             $package[1] = "$packv";
            if(defined($essential[1])) {              
             $col2 = "Essential: $essential[1]";
             @essential = ();
            }
            else {
              $col2 = "Essential: no\n";
            }
            write PRETTY;
            ######################
            # SECTION & PRIORITY #
            ######################
            if ($section) {
              $col1 = $section;
            }
            else {
              nsb(\%commands);
              $package[1] =~ m,(.*)_.*,;
              my $packthing = $1;
              if (defined $nsb{$packthing}) {
                my ($nvname,$ngname,$npriorname) =
                split(/\s/,"$nsb{$packthing}",3);
                $col1 = "Section: $ngname";
                # we can put it in now, no deletion needed
                if (!defined $gb{$group}) {
                   $ging->put($group,$packthing);
                }
                else {
                  my $change_group = "$gb{$group} $packthing";
                  $ging->del($group);
                  $ging->put($group,"$change_group");
                } 
              }
              else {
                $col1 = "Section: unavailable";
              }
            }
            if (defined $priority) {
              $col2 = $priority;
            }
            else {
              nsb(\%commands);
              $package[1] =~ m,(.*)_.*,;
              my $packthing = $1;
              if (defined $nsb{$packthing}) {          
                my ($nvname,$ngname,$npriorname) =
                split(/\s/,"$nsb{$packthing}",3);
                $col2 = "Section: $npriorname";
              }
              else {
                 $col2 = "Priority: unavailable\n";
              }
            }
            write PRETTY;
            #my $cool = $installed_size . $maintainer;
            #print PRETTY $cool;
            $col1 = $installed_size;
            if ($source) {
              $col2 = $source;
            }
            else {
              $col2 = "";
            } 
            write PRETTY;
            undef $source;
            print PRETTY $maintainer
        }

        # This stuff will be available with seperate query flags or All
        elsif (/^Replaces:/) {
            $replaces = $_;
              if (defined($replaces)) {
                 $ping->put("$package[1]REP",$replaces);
              }
         }
        elsif (/^Provides:/) {
            $provides = $_;
              if (defined($provides)) {
                 $ping->put("$package[1]PRO",$provides);
              }
        }         
        elsif (/^Depends:/) {
            $depends = $_;
              if (defined($depends)) {
                 $ping->put("$package[1]DEP",$depends);
              }
        }
        elsif (/^Pre-Depends:/) {
            $pre_depends = $_;
              if (defined($pre_depends)) {
                 $ping->put("$package[1]PRE",$pre_depends);
              }
        }
        elsif (/^Recommends:/) {
            $recommends = $_;
              if (defined($recommends)) {
                 $ping->put("$package[1]REC",$recommends);
              }
        }
        elsif (/^Suggests:/) {
            $suggests = $_;
              if (defined($suggests)) {
                 $ping->put("$package[1]SUG",$suggests);
              }
        }
        elsif (/^Conflicts:/) {
            $conflicts = $_;
              if (defined($conflicts)) {
                 $ping->put("$package[1]CON",$conflicts);
              }
        }        
       # Gather the Configuration Files, Description comes after.
       # Available with a single flag.
        elsif (/^Conffiles:/) {
             my $line = <AVAIL>;
             while ($line !~ /^Description:/) {
                 push(@conffiles,$line);
                 $line = <AVAIL>;
                   if ($line =~ /^Description/) {
                         $line_before = $line;
                   # put conffiles into one variable
                     if (defined $package[1]) {
                     }
                       my ($c, $cool);
                         if ($#conffiles != 0) { 
                            for ($c = $#conffiles; $c >= 0; $c--) {
                              if ($c > 0) {
                                $cool = $conffiles[$c-1] .= $conffiles[$c];   
                              }             
                             } #end for
                          }
                          else {
                            $cool = $conffiles[0];
                          }
                          @conffiles = ();
                          $ping->put("$package[1]CONF",$cool);
                   } #if ($line =~ /^Desc 
              }  # while ($line ! /^Desc          
        } # elsif (/^Conffiles 
        untie %nsb;

        # Only interested in available packages..so this is fine.
        # To be combined with first fields.
        if (/Description:|^\s\w*|^\s\.\w*/ || 
            defined($line_before) =~ /^Description/){ 
           my $many_lines;
            if (defined($line_before)) {
                push(@ldescription, $line_before);
                push(@ldescription, $_);
                $line_before = ();
            }
            else {
                 $many_lines = $_;
            } 
           if ($_ !~ /^\n$/) {
             $count++;
             if ($count == 1) {
               if (defined $package[1]) {
                 #chomp $package[1];
                 #push(@dpackage,$package[1]);
                 push(@description,$package[1]);
               }
              } 
               if (defined($many_lines)) {
               push(@ldescription,$many_lines);
               }
           } # end if ($_ !~ /^\n$/
           else {
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
           $line_before = ();
        } 
      untie $ping;
      untie $ging;
      untie $sing;
      } # end while (<AVAIL>)
      close(PRETTY);


  # Let's put together the description with the rest of its fields.
  open(FIELDS,"$format_deb");
  while (<FIELDS>) {
     push(@form,$_);
  }
  close(FIELDS);  

  foreach (@form) {
    push(@formly,$_);    
    my ($cool);
    $count++;  
    if ($count == 5) {
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
     #push(@Tdescription, $lingo); 
     $ping->put($name_version,$lingo);
     $lingo = ();
     $count = 1;
   }
   else {
     # packagename_version
     #push(@Tdescription, $_); 
     $name_version = $_;
     $count = 0;
   }
   $count++;
   untie $ping;
 }
 undef $ping;
 
   unlink($format_deb);

   # Now time to do some file/dir stuff.  A backup of *list needs to be
   # made, might as well use this.  There is a possibility this can be
   # used instead of fastswim for initial fileindex.deb.
     my $package_name;
     if (!-d "$parent$base/info/backup") {
        mkdir("$parent$base/info/backup",0666);
     }
     print "\n" if $#NEW != -1; $x = 1;

  foreach $package_name (@NEW) {
     open(FILENAME,"$parent$base/info/$package_name.list");
     open(CP,">$parent$base/info/backup/$package_name.list.bk");
       while (<FILENAME>) {
         print CP $_;
       }
     close(FILENAME);
     close(CP);

     my $file = "$parent$base/info/backup/$package_name.list.bk";
     print "#$x"; print " N|C $package_name.list             \r";
     $x++;
     open(LIST,"$file");
     while (<LIST>) {
       chomp;

       # Better add the new stuff to the flat files first
       if (!defined $ib{$_}) {
         if (($commands->{"dbpath"} && $commands->{"root"}) ||
             ($commands->{"dbpath"} && !$commands->{"root"}) ||
             (!$commands->{"dbpath"} && !$commands->{"root"})) {
               open(SEARCHINDEX,">>$main::home$parent$library/searchindex.deb");
         }
         elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
               open(SEARCHINDEX,">>$main::home$parent$base/searchindex.deb");
         }
         if (!-d) {
            print SEARCHINDEX "$_\n";
         }
         if (($commands->{"dbpath"} && $commands->{"root"}) ||
             ($commands->{"dbpath"} && !$commands->{"root"}) ||
             (!$commands->{"dbpath"} && !$commands->{"root"})) {
               open(DIRINDEX,">>$main::home$parent$library/dirindex.deb");
         }
         elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
               open(DIRINDEX,">>$main::home$parent$base/dirindex.deb");
         }
         if (-d) {
           print DIRINDEX "$_\n";  
         }
       } # !defined

       # If the directory already exists we can just append 
       # to the end of the value
       if (defined $ib{$_}) {
           dbi(\%commands);
           my $cvalue = $ib{$_} . " $db{$package_name}";
           # put overwrites by default!
           $zing->put($_,$cvalue);   
       } # if defined        
       else {
           dbi(\%commands);
           $zing->put($_,$db{$package_name});    
       }
     untie %db;
     untie $zing;
     }
    close(LIST);  
    close(SEARCHINDEX);
    close(DIRINDEX);

     my $zit; my ($nit,$yit) = (split(/\s/,$sb{$package_name}))[0,3];
     if ($yit eq "deinstall:ok:config-files" ||
         $yit eq "purge:ok:config-files") {
      ($zit = $nit) =~ s,\+,\\\+,;
      if ($ib{"/."} !~ m,$zit,) {
       $ib{"/."} = $ib{"/."} . " $zit"; 
      }
    }

  }  # end foreach NEW   
  print "\n" if $#NEW != -1;

} # end sub db

# Generally, it's unecessary to rebuild the flat databases unless major
# changes have occurred to a person's installation, and the database has
# become very repetitive, or a file has changed into a directory.  This
# function has also been tried by tieing the flat file to an array, but
# there doesn't seem to be that much of a speed advantage unless ib()
# happens to be in memory, but more experimentation will be tried in the
# future.
sub rebuildflatdb {

  my($commands) = @_;
  my %commands = %$commands;
  ib(\%commands);

  print scalar(localtime), "\n";
 
  my $file;
  my $dir;

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     !($commands->{"dbpath"} && $commands->{"root"})) {
        if (-e "$main::home$parent$library/searchindex.deb") {
            $dir = "$main::home$parent$library/dirindex.deb";
            $file = "$main::home$parent$library/searchindex.deb";
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
        if (-e "$main::home$parent$base/searchindex.deb") {
            $file = "$main::home$parent$base/searchindex.deb";
            $dir = "$main::home$parent$base/dirindex.deb";
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


  open(DIR,">$dir");
  open(FILE,">$file");
  # We need to reconstruct long.debian & DEBIAN*, but can't take into account
  # weirdisms with the database - NEW packages which aren't NEW.
  foreach (keys %ib) {
   if (defined $ib{$_}) { 
       my $filedir = $_;
       my $package = $ib{$_};
       #$package =~ s/\s/\n/g;
       my @the_amount  = split(/\s/, $package);
     if ($#the_amount > 0) {
       print DIR "$filedir\n";
     }
     elsif ($#the_amount == 0) {
       print FILE "$filedir\n";
    }
   }
  }
  untie %ib;
  print STDERR "swim: searchindex.deb and fileindex.deb have been rebuilt\n";
  print scalar(localtime), "\n";

} # end sub rebuildflatdb



1;
