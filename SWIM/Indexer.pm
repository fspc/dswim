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


package SWIM::Indexer;
use strict;
use SWIM::Global;
use SWIM::Conf qw($my_number);
use SWIM::DB_Library qw(:Xyz ib nib nsb);
use SWIM::Info;
use SWIM::Pn_print;   
use SWIM::Deps;
use SWIM::Dir;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(indexer);


# The next few subs are provided to shorten indexer
# for -d or -l, but not -c when -T
sub T_indexer {

   my ($alot,$commands) = @_;
   my %commands = %$commands;

   foreach (@$alot) {

       $argument = $_;

       if ($commands->{"scripts"} || 
	   $commands->{"preinst"} ||
	   $commands->{"postinst"} || 
	   $commands->{"config"} || 
	   $commands->{"prerm"} ||
	   $commands->{"postrm"} || 
	   $commands->{"config"} || 
	   $commands->{"templates"}) {
	   scripts(\%commands);
       }
       menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
       copyright(\%commands) if $commands->{"copyright"};
       changelog(\%commands) if $commands->{"changelog"};
       # looks o.k.
       print "$argument\n";
       character(\%commands);
       shlibs(\%commands) if $commands->{"shlibs"};
       if ($commands->{"d"} && !$commands->{"c"}) {
	   require SWIM::File;
	 SWIM::File->import(qw(file));
	   file(\%commands);
       }
       # R 1.10 somehow added a return here
       print "\n";
   }

} # end sub T_indexer


sub which_character_indexer {

          my ($alot,$commands) = @_;
          my %commands = %$commands;

           foreach (@$alot) {
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
             if  (the_character(\%commands) ne "ok") {
               print "$argument\n";
             }
             if (defined s_character(\%commands)) {}
             shlibs(\%commands) if $commands->{"shlibs"};
             if ($commands->{"d"} && !$commands->{"c"}) {
              require SWIM::File;
              SWIM::File->import(qw(file));
              file(\%commands);
             }
             print "\n";
             %commands = %store_commands;
             undef %store_commands;
           }

} # end sub which_character_indexer 

sub noT_indexer {


          my ($alot,$commands) = @_;
          my %commands = %$commands;
          require SWIM::File;
          SWIM::File->import(qw(file));

          foreach (@$alot) {
            $argument = $_;                     
             if ($commands->{"scripts"} || $commands->{"preinst"} ||
                $commands->{"postinst"} || $commands->{"prerm"} ||
                $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}) {
                 scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             if ($argument) {
              # should be o.k., almost everything has documentation
              print "$argument\n";
             }
            shlibs(\%commands) if $commands->{"shlibs"};       
            file(\%commands);
             if ($commands->{"d"} && !$commands->{"T"} && !which_character(\%commands)) { 
               print "\n";
             }
          }

} # end sub noT_indexer

# different enough from noT_indexer, used when -c,-d,-l aren't called.
sub nonoT_indexer {

          my ($alot,$commands) = @_;
          my %commands = %$commands;

           foreach (@$alot) {
              $argument = $_;  
             if ($commands->{"scripts"} || $commands->{"preinst"} ||
                $commands->{"postinst"} || $commands->{"prerm"} ||
                $commands->{"postrm"} || $commands->{"config"} || $commands->{"templates"}) {
                 scripts(\%commands);
             }
             menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
             copyright(\%commands) if $commands->{"copyright"}; 
             changelog(\%commands) if $commands->{"changelog"}; 
             # package name will print out even if there is no script
             # definitely useful here
             singular(\%commands);
             if ($commands->{"scripts"}) {
                 print "\n";
             }
             shlibs(\%commands) if $commands->{"shlibs"}; 
           }
          

} # end sub nonoT_indexer


# when -c is called with or without -l or -d.  This sub got rather huge. 
sub c_indexer {

  my ($alot,$commands) = @_;
  my %commands = %$commands;
  my $arg_save;
  require SWIM::File;
  SWIM::File->import(qw(file));

  foreach (@$alot) {
      $argument = $_;           
      if (conf(\%commands) ne 0) {

	  if ($commands->{"T"}) {
              # covers first argument, but not the rest.
              if (
		  $commands->{"scripts"} || 
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
	      print conf(\%commands) if !$commands->{"md5sum"};
	      file(\%commands);
	      #file(\%commands) if $commands->{"md5sum"};

	      if (
		  ($commands->{"c"} && 

		   (!$commands->{"d"} || 
		    !$commands->{"l"}))

		  ) {
		  print "\n";
	      }
              $arg_save = $argument;
	  } # end "T" 
 
	  elsif (which_character(\%commands)) {
	      my %store_commands = %commands;
	      $argument = $_;           
	      if (
		  $commands->{"scripts"} || 
		  $commands->{"preinst"} ||
		  $commands->{"postinst"} || 
		  $commands->{"prerm"} ||
		  $commands->{"postrm"} || 
		  $commands->{"config"} || 
		  $commands->{"templates"}
		  ) {
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
	      print conf(\%commands) if !$commands->{"md5sum"};
	      file(\%commands);
	      #file(\%commands) if $commands->{"md5sum"};
	      if (
		  ($commands->{"c"} && 

		   (!$commands->{"d"} || 
		    !$commands->{"l"}))

		  ) {
		  print "\n";
	      }
	      %commands = %store_commands;
	      undef %store_commands;
              $arg_save = $argument;
	  }
	  
	  # no Ts.
	  else {
	      if (
		  $commands->{"scripts"} || 
		  $commands->{"preinst"} ||
		  $commands->{"postinst"} || 
		  $commands->{"config"} || 
		  $commands->{"templates"} || 
		  $commands->{"prerm"} ||
		  $commands->{"postrm"}) {
		  scripts(\%commands);
	      }
	      menu(\%commands) if $commands->{"menu"} || $commands->{"m"};
	      copyright(\%commands) if $commands->{"copyright"}; 
	      changelog(\%commands) if $commands->{"changelog"}; 
	      print "$argument\n";
	      shlibs(\%commands) if $commands->{"shlibs"};
	      print conf(\%commands) if !$commands->{"md5sum"};
	      file(\%commands);
	      print "\n";
	  }
	  $arg_save = $argument;
      } # end if (conf(\%commands)   
      
      # this spot here can determine whether or not -c overrides l&d
      # in packages which don't have conf files.  it's nicer to view
      # everything.  watch this..these are packages which don't have
      # conf files 
      if ($commands->{"d"} || $commands->{"l"}) {
	  if ($arg_save) {
	      if ($argument ne $arg_save) { 
		  #if (!$arg_save) {
		  if (conf(\%commands) ne 0) {
		      shlibs(\%commands) if $commands->{"shlibs"};
		      file(\%commands);
		      print "\n";
		  } 
		  
		  # no conf files
		  elsif (conf(\%commands) eq 0) { 
		      if ($commands->{"T"}) {
			  $argument = $_;           
			  if (
			      $commands->{"scripts"} || 
			      $commands->{"preinst"} ||
			      $commands->{"postinst"} || 
			      $commands->{"prerm"} ||
			      $commands->{"postrm"} || 
			      $commands->{"config"} || 
			      $commands->{"templates"}) {
			      scripts(\%commands);
			  }
			  menu(\%commands) if $commands->{"menu"} || 
			      $commands->{"m"};
			  copyright(\%commands) if $commands->{"copyright"}; 
			  changelog(\%commands) if $commands->{"changelog"}; 
			  print "$argument\n"; 
			  character(\%commands);   
			  shlibs(\%commands) if $commands->{"shlibs"};
			  file(\%commands) if $commands->{"md5sum"};
			  print "\n";
		      } # end "T" 
		      
		      elsif (which_character(\%commands)) {
			  my %store_commands = %commands;
			  $argument = $_;           
			  if (
			      $commands->{"scripts"} || 
			      $commands->{"preinst"} ||
			      $commands->{"postinst"} || 
			      $commands->{"prerm"} ||
			      $commands->{"postrm"} || 
			      $commands->{"config"} || 
			      $commands->{"templates"}) {
			      scripts(\%commands);
			  }
			  menu(\%commands) if $commands->{"menu"} || 
			      $commands->{"m"};
			  copyright(\%commands) if $commands->{"copyright"}; 
			  changelog(\%commands) if $commands->{"changelog"}; 
			  if  (the_character(\%commands) ne "ok") {
			      print "$argument\n";
			  }
			  if (defined s_character(\%commands)) {}   
			  shlibs(\%commands) if $commands->{"shlibs"};
			  %commands = %store_commands;
			  undef %store_commands;
			  file(\%commands);
			  print "\n";
		      }
		      
		      # no Ts. 
		      else {
			  if (
			      $commands->{"scripts"} || 
			      $commands->{"preinst"} ||
			      $commands->{"postinst"} || 
			      $commands->{"prerm"} ||
			      $commands->{"postrm"} || 
			      $commands->{"config"} || 
			      $commands->{"templates"} ) {
			      scripts(\%commands);
			  }
			  menu(\%commands) if $commands->{"menu"} || 
			      $commands->{"m"};
			  copyright(\%commands) if $commands->{"copyright"}; 
			  changelog(\%commands) if $commands->{"changelog"}; 
			  singular(\%commands);
			  if ($commands->{"scripts"}) {
			      print "\n";
			  }
			  shlibs(\%commands) if $commands->{"shlibs"}; 
			  file(\%commands);
			  print "\n";
		      }
		  } 
	      }
	  }
      } # end if ($commands->{"d"} || 
  } # end foreach

} # end sub c_indexer


# handles -qf by itself or with -l(-d)&-c or -d by itself, and -qa by itself
# or with -c with -d and/or -l ...essentially not -i. <file> is the
# argument And ofcourse -T or singular capabilities. 
sub indexer {

  my ($commands) = @_;
  my %commands = %$commands;
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

  if ($argument) {
   dir(\%commands);
   fir(\%commands);
    if ($ib{"$argument"}){
       my $package = $ib{"$argument"};
       $package =~ s/\s/\n/g;
        @alot = split(/\s/, $package);
        if (@alot) {
         @PACKAGES = @alot;
        }
        if ($commands->{"z"} || 
	    $commands->{"ftp"}||
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
         # The whole reason for the complicated if/elsif/else routines 
         # below is to allow simultaneous printing of -c & -d|-l.  Other
         # options can just be included within.
          
          ###########
          # -D & -t #
          ###########
         if ($commands->{"d"} && !$commands->{"c"}) {
          if ($commands->{"T"}) {
            T_indexer(\@alot,\%commands);
          }
          elsif (which_character(\%commands)) {
           which_character_indexer(\@alot,\%commands);
          }
          # no -Ts.
           noT_indexer(\@alot,\%commands);
         }

         #######################
         # -t BUT NOT -C,-D,-L #
         #######################
         elsif (!$commands->{"c"} && (!$commands->{"d"} || !$commands->{"l"})) {     


          if ($commands->{"T"}) {
            T_indexer(\@alot,\%commands);
          }
          elsif (which_character(\%commands)) {
            which_character_indexer(\@alot,\%commands);
          }
          # humm smail is missing mysteriously, like it never became part
          # of /.., basically, fastswim isn't placing it in long.debian.
          # no -Ts.
          else {
            nonoT_indexer(\@alot,\%commands);
          }
         }

         #####################        
         # -t -C &| -D || -L #
         #####################
         # conf stuf.  Will only show stuff related to -a or -f with conf.
         elsif (
		($commands->{"c"} && 
		 (!$commands->{"d"} || 
		  !$commands->{"l"})) ||

                ($commands->{"c"} && 
		 ($commands->{"d"} || 
		  $commands->{"l"}))) {
	     c_indexer(\@alot,\%commands);        

         } # end elsif         
        } 

        #########################
        #  > NUMBER FOR -t #
        ##########################
        elsif ($#ARGV > $my_number) {
          my $total = $#ARGV + 1;
          print "use --total or -t to see all $total packages\n";              
          exit;
        }
        elsif ($#alot > $my_number) {
          my $total = $#alot + 1;
          print "use --total or -t to see all $total packages\n";       
        }

       # without -t
        else {

         ######
         # -D #
         ######
         if ($commands->{"d"} && !$commands->{"c"}) {

          if ($commands->{"T"}) {
            T_indexer(\@alot,\%commands);
          }
          elsif (which_character(\%commands)) {
           which_character_indexer(\@alot,\%commands);
          }
          # the noties
          noT_indexer(\@alot,\%commands);
         }

         ################
         # NOT -C,-D,-L  #
         ################
         elsif (!$commands->{"c"} && 
		
		(!$commands->{"d"} || !$commands->{"l"})

		) {     

	     if ($commands->{"T"}) {
             
		 T_indexer(\@alot,\%commands);

          }
          elsif (which_character(\%commands)) {
             which_character_indexer(\@alot,\%commands);
          }
          else {
             nonoT_indexer(\@alot,\%commands); 
          }
         }


         ##################        
         # -C &| -D || -L #
         ##################
         # conf stuf.  Will only show stuff related to -a or -f with conf.
         elsif (
		($commands->{"c"} && 
		 (!$commands->{"d"} || !$commands->{"l"})) ||
                
		($commands->{"c"} && 
		 
		 ($commands->{"d"} || $commands->{"l"}))) {

               c_indexer(\@alot,\%commands);

	   }         
	 
     } # without -t
   }
   else { 
        $argument =~ m,.*\/(.*$),;
         if ($1) {
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
            print "@LINES\n"; indexer(\%commands);
           }
          } 
          else {
           print "file $file is not owned by any package\n"; 
          }
         }
      }
  }
  untie %ib;

  if (@alot) {
   @PACKAGES = @alot;
  }
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
 
} # end sub indexer


1;





