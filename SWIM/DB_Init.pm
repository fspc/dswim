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


package SWIM::DB_Init;
use strict;
use SWIM::Conf qw(:Path $fastswim $imswim $slowswim $sort);
use SWIM::Global;
use SWIM::Format;
use SWIM::MD;
use DB_File;
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(database);


# database() md()  --initdb --rebuilddb 

# Time to get serious and make a database 
sub database {


  my ($commands) = @_;
  my %commands = %$commands;
  print STDERR scalar(localtime), "\n";

  #my whatever that is
  my @dpackage; # passes name_version to md()
  my @Tdescription;
  my @description; 
  my @ldescription;
  my @package;
  my %db;
  my @name;
  my $count = 0;

  my $the_status; 

  my $status; 
  my @essential;
  my $priority; 
  my $section; 
  my $installed_size; 
  my $maintainer; 
  my $source;
  my $version;
  my $ver;

  my %gb;
  my %group;
  my $group;

  # Keeps a package->version database 
  # to save time over using status
  my %sb;
  my @status;

  my ($replaces, @REPLACE, $provides, $depends, $pre_depends,
      $recommends, $suggests, $conflicts);

  my @conffiles;
  my $line_before;
  my @conf;
  my @complete;
  my @form;
  my @formly;
  my $format_deb = "$tmp/format.deb";

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


  if (-e "$parent$base/status" && -e "$parent$base/info") {
      $the_status = "$parent$base/status";
  }
  else {
      print STDERR "swim: crucial file(s)/directories are missing in $parent\n";
      exit;
  }

  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
      if ($commands->{"initdb"}) {  
        if (-e "$main::home$parent$library/packages.deb" &&
            -e "$main::home$parent$library/fileindex.deb") {            
            print STDERR "swim:  use --rebuilddb\n";
            exit;
        }
        else {
          # if a database happens to be missing 
          if (-e "$main::home$parent$library/packages.deb") {
             unlink("$main::home$parent$library/packages.deb");
          }
          if (-e "$main::home$parent$library/fileindex.deb") {
             unlink("$main::home$parent$library/fileindex.deb");
          }
          if (-e "$main::home$parent$library/groupindex.deb") {
             unlink("$main::home$parent$library/groupindex.deb");
          }
          if (-e "$main::home$parent$library/statusindex.deb") {
             unlink("$main::home$parent$library/statusindex.deb");
          }
          if (-e "$main::home$parent$library/searchindex.deb") {
             unlink("$main::home$parent$library/searchindex.deb");
          }
          if (-e "$main::home$parent$library/searchindex.deb.gz") {
             unlink("$main::home$parent$library/searchindex.deb.gz");
          }
          if (-e "$main::home$parent$library/dirindex.deb") {
             unlink("$main::home$parent$library/dirindex.deb");
          }
          if (-e "$main::home$parent$library/dirindex.deb.gz") {
             unlink("$main::home$parent$library/dirindex.deb.gz");
          }
        }
      }
      #  this only works if all databases exist.
      elsif ($commands->{"rebuilddb"}) {
        if (-e "$main::home$parent$library/packages.deb" &&        
            -e "$main::home$parent$library/fileindex.deb") {            
          unlink("$main::home$parent$library/packages.deb");
          unlink("$main::home$parent$library/fileindex.deb");
          unlink("$main::home$parent$library/groupindex.deb");
          unlink("$main::home$parent$library/statusindex.deb");
          unlink("$main::home$parent$library/searchindex.deb");
          unlink("$main::home$parent$library/searchindex.deb")
          if -e "$main::home$parent$library/searchindex.deb";           
          unlink("$main::home$parent$library/dirindex.deb");
          unlink("$main::home$parent$library/dirindex.deb")
          if -e "$main::home$parent$library/dirindex.deb.gz";           
        }
        else {
          print STDERR "swim:  use --initdb to create databases\n";
          exit;
        }
      }  
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
      if ($commands->{"initdb"}) {  
        if (-e "$main::home$parent$base/packages.deb" &&
            -e "$main::home$parent$base/fileindex.deb") {            
            print STDERR "swim:  use --rebuilddb\n";
            exit;
        }
        else {
          # if a database happens to be missing 
          if (-e "$main::home$parent$base/packages.deb") {
             unlink("$main::home$parent$base/packages.deb");
          }
          if (-e "$main::home$parent$base/fileindex.deb") {
             unlink("$main::home$parent$base/fileindex.deb");
          }
          if (-e "$main::home$parent$base/groupindex.deb") {
             unlink("$main::home$parent$base/groupindex.deb");
          }
          if (-e "$main::home$parent$library/statusindex.deb") {
             unlink("$main::home$parent$library/statusindex.deb");
          }
          if (-e "$main::home$parent$library/searchindex.deb") {
             unlink("$main::home$parent$library/searchindex.deb");
          }
          if (-e "$main::home$parent$library/searchindex.deb.gz") {
             unlink("$main::home$parent$library/searchindex.deb.gz");
          }
          if (-e "$main::home$parent$library/dirindex.deb") {
             unlink("$main::home$parent$library/dirindex.deb");
          }
          if (-e "$main::home$parent$library/dirindex.deb.gz") {
             unlink("$main::home$parent$library/dirindex.deb.gz");
          }
        }
      }
      #  this only works if all databases exist.
      elsif ($commands->{"rebuilddb"}) {
        if (-e "$main::home$parent$base/packages.deb" &&        
            -e "$main::home$parent$base/fileindex.deb") {            
          unlink("$main::home$parent$base/packages.deb");
          unlink("$main::home$parent$base/fileindex.deb");
          unlink("$main::home$parent$base/groupindex.deb");
          unlink("$main::home$parent$base/statusindex.deb");
          unlink("$main::home$parent$library/searchindex.deb");
          unlink("$main::home$parent$library/searchindex.deb")
          if -e "$main::home$parent$library/searchindex.deb";           
          unlink("$main::home$parent$library/dirindex.deb");
          unlink("$main::home$parent$library/dirindex.deb")
          if -e "$main::home$parent$library/dirindex.deb.gz";           
        }
        else {
          print STDERR "swim:  use --initdb to create databases\n";
          exit;
        }
      }  
  }

     # This makes a backup of all the *.list files in ./backup.  When
     # --initdb/--rebuilddb runs these files should be built or rebuilt,
     # but if changes have occured and --db(-i wasn't used) wasn't run
     # this won't cause problems because everything is rebuilt, there may 
     # just be some lingering small files in backup.

  # Seems like both approaches are about the same speed.
  #use File::Copy; 
  print STDERR "Making backups of *.list\n";
  if (!-d "$main::home$parent$base/info/backup") {
      system "mkdir $main::home$parent$base/info/backup";
  }

  opendir(COPY,"$parent$base/info") or die "Sorry Charlie: $!\n";
  foreach (sort grep(/\.list$/, readdir(COPY))) {
      open(FILENAME,"$parent$base/info/$_");
      open(CP,">$main::home$parent$base/info/backup/$_.bk");
      while (<FILENAME>) {
	  print CP $_;
      }
  }
  closedir(COPY);

 print STDERR "Description Database is being made\n";

    $| = 1; my $x = 0;
    open(PRETTY, ">$format_deb");
    open(AVAIL, "$the_status");
      while (<AVAIL>) {
       # Package name
        if (/^Package:|^PACKAGE:/) {                                              
          @package = split(/: /,$_);                                                  
          chomp	 $package[1];
          $x = 1 if $x == 6;
          print STDERR "|\r" if $x == 1 || $x == 4; print STDERR "/\r" if $x == 2;
          print STDERR "-\r" if $x == 3 || $x == 6; print STDERR "\\\r" if $x == 5;
          $x++;         
        } 
  # Some other pertinent fields
  # All this stuff can be placed together..since it is generally nice
  # to know these things at one glance, in this order.
  # Package:                    Status: 
  # Version:                    Essential: (yes or no)
  # Section:                    Priority:
  # Installed-Size:
  # Maintainer:
  # Description:

        elsif (/^Status:/) {
            $status = $_;
        }
        elsif (/^Essential/) {
           @essential = split(/: /,$_);                                                  
        }
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
              if (!defined $group{$group}) {
                  $group{$group} = $package[1];
              }
              else {
                  $group{$group} = "$group{$group} $package[1]";
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
            $version = $_;
            chomp($version, $section);
            $col1 = "Package: $package[1]";
            $col2 = $status;
            write PRETTY;
            $col1 = $version;
             $ver = m,Version:\s(.*),;         
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
             my $statusy = substr($status,8);
             chomp $statusy;
             $statusy =~ s/\s/:/g;
             my $thimk = "$package[1] $group $priory $statusy";
             push(@status, $thimk);
            if(defined($essential[1])) {              
             $col2 = "Essential: $essential[1]";
             @essential = ();
            }
            else {
              $col2 = "Essential: no\n";
            }
            write PRETTY;
            if (defined $section) {
             $col1 = $section;
            }
            else {
             $col1 = "Section: unavailable";
            }
            if (defined $priority) {
             $col2 = $priority;
            }
            else {
             $col2 = "Priority: unavailable\n";
            }
            write PRETTY;
            #my $cool = $installed_size . $maintainer;
            $col1 = $installed_size;
            if (defined $source) {
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
               push(@REPLACE, "$package[1]REP");
               push(@REPLACE, $replaces); 
              }
         }
        elsif (/^Provides:/) {
            $provides = $_;
              if (defined($provides)) {
               push(@REPLACE, "$package[1]PRO");
               push(@REPLACE, $provides); 
              }
        }         
        elsif (/^Depends:/) {
            $depends = $_;
              if (defined($depends)) {
               push(@REPLACE, "$package[1]DEP");
               push(@REPLACE, $depends); 
              }
        }
        elsif (/^Pre-Depends:/) {
            $pre_depends = $_;
              if (defined($pre_depends)) {
               push(@REPLACE, "$package[1]PRE");
               push(@REPLACE, $pre_depends); 
              }
        }
        elsif (/^Recommends:/) {
            $recommends = $_;
              if (defined($recommends)) {
               push(@REPLACE, "$package[1]REC");
               push(@REPLACE, $recommends); 
              }
        }
        elsif (/^Suggests:/) {
            $suggests = $_;
              if (defined($suggests)) {
               push(@REPLACE, "$package[1]SUG");
               push(@REPLACE, $suggests); 
              }
        }
        elsif (/^Conflicts:/) {
            $conflicts = $_;
              if (defined($conflicts)) {
               push(@REPLACE, "$package[1]CON");
               push(@REPLACE, $conflicts); 
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
                       #chomp $package[1];
                       push(@conf,"$package[1]CONF");
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
                          push(@conf,$cool);
                   } #if ($line =~ /^Desc 
              }  # while ($line ! /^Desc          
        } # elsif (/^Conffiles 

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
                 push(@dpackage,$package[1]);
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

  # We'll keep databases local so that md() doesn't get confused with
  # database().

  # Put the groups into the groupindex.deb database.
  print STDERR "Group Database is being made\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     tie %gb, 'DB_File', "$main::home$parent$library/groupindex.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    tie %gb, 'DB_File', "$main::home$parent$base/groupindex.deb" or die "DB_File: $!";
  }
  
  %gb = %group;

  untie %gb;
  undef %gb;
  undef %group;

  # Create the important status database.
  print STDERR "Status Database is being made\n";
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
        tie %sb, 'DB_File', "$main::home$parent$library/statusindex.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
        tie %sb, 'DB_File', "$main::home$parent$base/statusindex.deb" or die "DB_File: $!";
  }

  %sb = @status;

  untie %sb;
  undef %sb;
  undef @status;

  # Put everything into the package.deb database.
  if (($commands->{"dbpath"} && $commands->{"root"}) ||
     ($commands->{"dbpath"} && !$commands->{"root"}) ||
     (!$commands->{"dbpath"} && !$commands->{"root"})) {
     tie %db, 'DB_File', "$main::home$parent$library/packages.deb" or die "DB_File: $!";
  }
  elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
    tie %db, 'DB_File', "$main::home$parent$base/packages.deb" or die "DB_File: $!";
  }

  %db = (@name,@Tdescription,@conf,@REPLACE);
  untie %db;
  undef @Tdescription;
  undef @conf; 
  undef @REPLACE;
  undef %db;


  # To the total db thing.
  if ($commands->{"initdb"} || $commands->{"rebuilddb"}) {
     md(\@dpackage,\%commands);
  }


} # end sub database


# Basically, this writes @dpackage to transfer.deb, which is processed by
# either fastswim into two files big.debian and long.debian for further 
# processing by process_md() or is processed by imswim, then slowswim into 
# the two files big.debian and long.debian then finished by process_md()
sub md {

     my($dpackage,$commands) = @_; # creates transfer.deb
     my %commands = %$commands; 


     unless (-e "$parent$base/info") {    
      die 'This program requires the $parent$base/info directory set-up by dpkg';                                  
     }    
    
     # Put all file/dir(*.list)->package_name(s) into an massive array.
     # fastswim runs this process separately.
     
      # This enables info files to be used from a different root system
      my $argument2 = "$parent$base/info";

     # This is just for testing purposes, and serves no real purpose.
     if (!defined(@$dpackage)) {
        system("$fastswim");
      }
     # This is what is used.
      else {
        open(TRANSFER, ">$tmp/transfer.deb");
         foreach (@$dpackage) {
          print TRANSFER "$_\n";
         }							
         close(TRANSFER);
         if (!$commands->{"lowmem"}) {
          system $fastswim, "--transfer", $argument2, $tmp, $main::home;
         }
         else {
          print STDERR "Gathering the file(s)/dir(s)\n";
          system $imswim, $argument2, $tmp, $main::home;
          system $slowswim, $tmp, $sort;
         }
     }
     undef @$dpackage;
     process_md(\%commands); 

} # end sub md



1;
