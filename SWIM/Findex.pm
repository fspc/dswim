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


package SWIM::Findex;
use strict;
use SWIM::Global;
use SWIM::Conf qw($my_number);
use SWIM::DB_Library qw(:Xyz ib nib nsb);
use SWIM::Info;
use SWIM::Deps;
use SWIM::Dir;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(findexer qindexer);


# findexer(\%commands) and qindexer used for -a -n -f

# query filelist for file name.. -qfl -qal, but not -qfl(d)c ... actually
# yes... -qlfd under certain conditions, but not with -c.  And -T and 
# singular capabilities.
sub findexer {

  my ($commands) = @_;
  my %commands = %$commands;
  my @alot;
  require SWIM::File;
  SWIM::File->import(qw(file));

     
  if (!$commands->{"n"}) {
   ib(\%commands);
  }
  else {
   my $return = nib(\%commands);
   if (!defined $return && $commands->{"a"}) {
       untie %ib;
       nsb(\%commands);
       $ib{"/."} = $nsb{"/."};
   }
  }

  if (defined $argument) {
   if ($commands->{"dir"}) {
     dir(\%commands);
   }
   elsif ($commands->{"f"}) {
     fir(\%commands);
   }
    if ($ib{"$argument"}){
       my $package = $ib{"$argument"};
       @alot = split(/\s/, $package);       
       @PACKAGES = @alot;
       if ($commands->{"z"} || 
	   $commands->{"ftp"} ||
	   $commands->{"remove"} || 
	   $commands->{"r"} ||
	   $commands->{"purge"} || 
	   $commands->{"reinstall"} || 
	   $commands->{"build-dep"} ||
	   $commands->{"source"}
	   ) {

           require SWIM::Safex;
           SWIM::Safex->import(qw(safex));
           safex(\%commands);
       }
       @alot = @PACKAGES;
       if ($commands->{"total"} || $commands->{"t"}) {
        if ($commands->{"T"}) { 
         foreach (@alot) {
          $argument = $_;
            if ($commands->{"scripts"} || 
		$commands->{"preinst"} ||
                $commands->{"postinst"} ||
		$commands->{"prerm"} ||
                $commands->{"postrm"} || 
		$commands->{"config"} || 
		$commands->{"templates"} ) {
             scripts(\%commands);
          }
          menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
          copyright(\%commands) if $commands->{"copyright"}; 
          changelog(\%commands) if $commands->{"changelog"}; 
          # nice to print package names before file listings
          if (!$commands->{"i"} || !$commands->{"d"} || !$commands->{"c"}) {
            print "$argument\n";
          } 
          character(\%commands);
          shlibs(\%commands) if $commands->{"shlibs"};       
          file(\%commands);
          print "\n";
         }
        } # if -T
          elsif (which_character(\%commands)) {
           foreach (@alot) {
             my %store_commands = %commands;
             $argument = $_;           
             if ($commands->{"scripts"} || $commands->{"preinst"} ||
                $commands->{"postinst"} || $commands->{"prerm"} ||
                $commands->{"postrm"}  || $commands->{"config"} || $commands->{"templates"}) {
                 scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             if  (the_character(\%commands) ne "ok") {
               print "$argument\n";
             }             
             if (defined s_character(\%commands)) {}   
             shlibs(\%commands) if $commands->{"shlibs"};
             file(\%commands);
             print "\n";          
             %commands = %store_commands;
             undef %store_commands;
           }
          }
          # no -Ts.
          foreach (@alot) {
             $argument = $_;                     
             if ($commands->{"scripts"} || 
		 $commands->{"preinst"} ||
                $commands->{"postinst"} || 
		 $commands->{"prerm"} ||
                $commands->{"postrm"}  || 
		 $commands->{"config"} || 
		 $commands->{"templates"}) {
                 scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             if (defined $argument) {
             print "\n" if $commands->{"l"};
             print "$argument\n";
             }
            shlibs(\%commands) if $commands->{"shlibs"};       
            file(\%commands);
             if ($commands->{"d"} && !$commands->{"T"} && !which_character(\%commands)) { 
               print "\n" if !$commands->{"l"};
             }
          } # end not's
       } # if -t 


        elsif ($#ARGV > $my_number) {
          my $total = $#ARGV + 1;
          print "use --total or -t to see all $total packages\n";       
          exit;
        }
        elsif ($#alot > $my_number) {
          my $total = $#alot + 1;
          print "use --total or -t to see all $total packages\n";       
        }

        else {
          if ($commands->{"T"}) {
           foreach (@alot) {                                                    
             $argument = $_;                                     
             if ($commands->{"scripts"} || 
		 $commands->{"preinst"} ||
		 $commands->{"postinst"} || 
		 $commands->{"prerm"} ||
		 $commands->{"postrm"} || 
		 $commands->{"config"} || 
		 $commands->{"templates"}) {

                 scripts(\%commands);                                                     
             }                                                                  
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             print "$argument\n";                                               
              character(\%commands); 
              shlibs(\%commands) if $commands->{"shlibs"};       
              file(\%commands);
              print "\n";
           }
          } # end -T
          elsif (which_character(\%commands)) {
           foreach (@alot) {
             my %store_commands = %commands;
             $argument = $_;           
             if ($commands->{"scripts"} || $commands->{"preinst"} ||
                 $commands->{"postinst"} || $commands->{"prerm"} ||
                 $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}) {
                 scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             if  (the_character($argument) ne "ok") {
               print "$argument\n";
             }
             if (defined s_character(\%commands)) {}   
             shlibs(\%commands) if $commands->{"shlibs"};
             file(\%commands);
             print "\n";          
             %commands = %store_commands;
             undef %store_commands;
           }
          } # which_character
          foreach (@alot) {
            $argument = $_;                     
            if ($commands->{"scripts"} || 
		$commands->{"preinst"} ||
                $commands->{"postinst"} || 
		$commands->{"prerm"} ||
                $commands->{"postrm"} || 
		$commands->{"config"} || 
		$commands->{"templates"}) {
                scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             if (defined $argument) {
              print "$argument\n";
             }
            file(\%commands);
             if ($commands->{"d"} && !$commands->{"T"} && !which_character(\%commands)) { 
               print "\n";
             }         
          } # end not's
       } # else
    }
     else {
        $argument =~ m,.*\/(.*$),;
         if (defined $1) {
          my $file = $1; 
          if (!$commands->{"n"} && -e "/usr/sbin/update-alternatives") {
           my $it = "update-alternatives --display $1|";
           open (IT,"$it") or exit;
           if (<IT> =~ /No alternatives/) {
            print "file $file is not owned by any package\n";
           }
           else {
            my @LINES = <IT>;
            print "For $argument ->\n";
            $LINES[0] =~ m,(/.*$),; $argument = $1;
            print "@LINES\n"; findexer(\%commands);
           }
          } 
          else {
           print "file $file is not owned by any package\n"; 
          }
         }
     }
  }
  untie %ib;

  if (!($commands->{"z"} || 
	$commands->{"ftp"} ||
	$commands->{"remove"} || 
	$commands->{"r"} ||
	$commands->{"purge"} || 
	$commands->{"reinstall"} || 
	$commands->{"build-dep"} ||
	$commands->{"source"}
	)) {

      if ($commands->{"x"} || 
	  $commands->{"ftp"} || 
	  $commands->{"source"} ||
	  $commands->{"source_only"} || 
	  $commands->{"remove"} ||
	  $commands->{"r"} || 
	  $commands->{"purge"} || 
	  $commands->{"reinstall"} || 
	  $commands->{"build-dep"} ||
	  $commands->{"source"}
	  ) {

           require SWIM::Safex;

           SWIM::Safex->import(qw(safex));
           safex(\%commands);
    }
  } 

} # end sub findexer


# query description of file name..-i  (-qfi)
sub qindexer {

   my ($commands) = @_;
   my %commands = %$commands;
   require SWIM::Ag;
   SWIM::Ag->import(qw(description));

   if ($commands->{"scripts"} || 
       $commands->{"preinst"} ||
       $commands->{"postinst"} || 
       $commands->{"prerm"} ||
       $commands->{"postrm"} || 
       $commands->{"config"} || 
       $commands->{"templates"}) {

       scripts(\%commands);
   }
   menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
   copyright(\%commands) if $commands->{"copyright"}; 
   changelog(\%commands) if $commands->{"changelog"}; 

   my @alot;
  
  if (!$commands->{"n"}) {
   ib(\%commands);
  }
  else {
   my $return = nib(\%commands);
   if (!defined $return && $commands->{"a"}) {
       untie %ib;
       nsb(\%commands);
       $ib{"/."} = $nsb{"/."};
   }
  }
 
  if (defined $argument) {
    dir(\%commands);
    fir(\%commands);
    
    # this will be moved above for safex(\%commands)
    if ($ib{"$argument"}){
       my $package = $ib{"$argument"};
       @alot = split(/\s/, $package);
       @PACKAGES = @alot;
       if ($commands->{"z"} || 
	   $commands->{"ftp"} ||
	   $commands->{"remove"} || 
	   $commands->{"r"} ||
	   $commands->{"purge"} || 
	   $commands->{"reinstall"} || 
	   $commands->{"build-dep"} ||
	   $commands->{"source"}
	   ) { 

           require SWIM::Safex;
           SWIM::Safex->import(qw(safex));
           safex(\%commands);
       } 
       @alot = @PACKAGES;
        if ($commands->{"total"} || $commands->{"t"}) {
         foreach (@alot) {
          $argument = $_;
          description(\%commands);
          print "\n";
         } 
        } 
        elsif ($#ARGV > 0) {
          my $total = $#ARGV + 1;
          print "use --total or -t to see all $total packages\n";              
          exit;
        }
        elsif ($#alot > 0) {
          my $total = $#alot + 1;
          print "use --total or -t to see all $total packages\n";       
        }
        else {
          $argument = $package;
          description(\%commands);     
        }
    }
    else { 
        $argument =~ m,.*\/(.*$),;
         if (defined $1) {
          my $file = $1; 
          if (!$commands->{"n"} && -e "/usr/sbin/update-alternatives") {
           my $it = "update-alternatives --display $1|";
           open (IT,"$it") or exit;
           if (<IT> =~ /No alternatives/) {
            print "file $file is not owned by any package\n";
           }
           else {
            my @LINES = <IT>;
            print "For $argument ->\n";
            $LINES[0] =~ m,(/.*$),; $argument = $1;
            print "@LINES\n"; qindexer(\%commands);
           }
          } 
          else {
           print "file $file is not owned by any package\n"; 
          }
         }
    }
  }
  untie %ib;
   


} # end sub qindexer


1;
