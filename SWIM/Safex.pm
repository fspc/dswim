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


package SWIM::Safex;
use strict;
use Term::ReadLine;
use SWIM::Conf qw($apt_get $dpkg $tmp $HISTORY);
use SWIM::Global qw(@PACKAGES $argument $aptor_group %db);
use SWIM::DB_Library qw(:Xyz);
use SWIM::Library;  
use vars qw(@ISA @EXPORT %EXPORT_TAGS);   
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(safex);


# when x is called
sub safex {

 my ($commands) = @_;
 my %commands = %$commands;

 if ($commands->{"x"} || 
     $commands->{"ftp"} ||
     $commands->{"remove"} || 
     $commands->{"r"} ||
     $commands->{"purge"} || 
     $commands->{"reinstall"} || 
     $commands->{"build-dep"} ||
     $commands->{"source"}
     ) {
 
  
     if (!defined @PACKAGES) {
	 if ($commands->{"search"} || 
	     $commands->{"ps"} || 
	     $commands->{"research"} || 
	     $commands->{"refinesearch"}) {
	     @PACKAGES = "NOPACKAGES";
	 }
	 else {
	     @PACKAGES = @ARGV;
	 }
     }
 
     #print "PACKAGES @PACKAGES $argument\n";

     my ($aptor,$arg);
     if (defined $argument) {
	 if ($argument =~ /_/) {
	     $argument =~ m,(.*)_.*,; 
	     $aptor = $1;
	 }
	 else {
	     if (($argument =~ m,/, && ($commands->{"y"} || 
					$commands->{"z"} ||
					$commands->{"ftp"} || 
					$commands->{"download-only"})) || 
		 defined $aptor_group ||
		 $commands->{"ftp"} || 
		 $commands->{"purge"} || 
		 $commands->{"remove"} ||
		 $commands->{"r"}  || 
		 $commands->{"reinstall"} ||
		 $commands->{"build-dep"} ||
		 $commands->{"source"}
		 ) {

		 if ($PACKAGES[$#PACKAGES] =~ /_/) {
		     $PACKAGES[$#PACKAGES] =~ m,(.*)_.*,; 
		     $aptor = $1;
		 }
		 else {
		     $aptor = $PACKAGES[$#PACKAGES];
		 }
	     }
	     else { 
		 $aptor = $argument;    
	     }
	 }
     }
     else {
	 if ($commands->{"y"} || 
	     $commands->{"z"} || 
	     $commands->{"ftp"} ||
	     $commands->{"download-only"} || 
	     $commands->{"purge"} || 
	     $commands->{"remove"} ||
	     $commands->{"r"}  || 
	     $commands->{"reinstall"} || 
	     $commands->{"build-dep"} ||
	     $commands->{"source"}
	     ) {

	     if ($PACKAGES[$#PACKAGES] =~ /_/) {
		 $PACKAGES[$#PACKAGES] =~ m,(.*)_.*,; 
		 $aptor = $1;
	     }
	     else {
		 $aptor = $PACKAGES[$#PACKAGES];
	     }
	 }
     }
     
     if ($PACKAGES[$#PACKAGES] =~ m,/,) {
	 $PACKAGES[$#PACKAGES] =~ m,.*/(.*)$,;
	 $arg = $1;
	 foreach (@PACKAGES) {
	     $_  =~ m,.*/(.*)$,;
	     shift @PACKAGES;
	     push(@PACKAGES,$1);
	 }
     }
     else {
	 if ($PACKAGES[$#PACKAGES] =~ /_/) {
	     $PACKAGES[$#PACKAGES] =~ m,(.*)_.*,; 
	     $arg = $1;
	     foreach (0 .. $#PACKAGES) {
		 if ($PACKAGES[$_] =~ /_/) {
		     $PACKAGES[$_]  =~ m,^(.*)_.*$,;
		     $PACKAGES[$_] = $1; 
		 }
		 else {
		     $PACKAGES[$_] = $PACKAGES[$_];
		 }
	     }
	 }
	 else {
	     $arg = $PACKAGES[$#PACKAGES];
	     foreach (0 .. $#PACKAGES) {
		 if ($PACKAGES[$_] =~ /_/) {
		     $PACKAGES[$_]  =~ m,^(.*)_.*$,;
		     $PACKAGES[$_] = $1; 
		 }
		 else {
		     $PACKAGES[$_] = $PACKAGES[$_];
		 }
	     }
	 }
     }  
     
     $aptor = "DEFINEDONE" if !defined $aptor;
     if (($aptor eq  $arg) || 

	 ($commands->{"search"} ||
	  $commands->{"ps"} || 
	  $commands->{"research"} ||
	  $commands->{"refinesearch"} || 
	  $aptor eq "/.") && 

	 $PACKAGES[0] ne "NOPACKAGES") {

	 xyz(\%commands);
     }
 }
 
 
}


# swim provides a great interface to apt.  The trick is to not actually
# run apt-get until all the arguments are stored in an array.  This is
# done easily for xy and for for xyz which provides virtual installation
# and querying completion after --db && --ndb updates.  Obviously, the
# package virtually installed needs to be the same architecture as the
# machine running, since this is how apt works, but the databases can be
# in any specified directory.  This function also provides an interface for
# ftp, as well as dpkg's --remove & --purge.
sub xyz {

  my ($commands) = @_;
  my %commands = %$commands;

  if (!$commands->{"ftp"}) {
   if (!defined $apt_get) {
     print "swim: configure swimrc\n";
     exit;
   }
  }   

  # error correcting  
  if ($commands->{"ftp"} && 
      ($commands->{"r"} || 
       $commands->{"remove"} ||
       $commands->{"purge"}  || 
       $commands->{"reinstall"} || 
       $commands->{"build-dep"} ||
       $commands->{"source"}
       ) ) {

    print "swim: --ftp cannot be used with ";  
    print "-r " if defined $commands->{"r"};
    print "--remove " if defined $commands->{"remove"};
    print "--purge " if defined $commands->{"purge"};
    print "--reinstall " if defined $commands->{"reinstall"};
    print "--build-dep " if defined $commands->{"build-dep"};
    print "--source " if defined $commands->{"source"};
    print "\n";
    exit;
  }
  if (

      (($commands->{"r"} || 
	$commands->{"remove"}) && 
       ($commands->{"purge"} ||
       $commands->{"reinstall"} || 
       $commands->{"build-dep"} ||
	$commands->{"source"})) ||

      ($commands->{"reinstall"} && 
       (($commands->{"r"} || 
	 $commands->{"remove"}) || 
	$commands->{"purge"} ||
       $commands->{"build-dep"} ||
       $commands->{"source"})) ||

      ($commands->{"purge"} && 
       (($commands->{"r"} || 
	 $commands->{"remove"}) || 
	$commands->{"reinstall"} ||
       $commands->{"build-dep"} ||
       $commands->{"source"})) ||

      ($commands->{"build-dep"} && 
       (($commands->{"r"} || 
	 $commands->{"remove"}) || 
	$commands->{"reinstall"} ||
       $commands->{"purge"} ||
       $commands->{"source"})) ||

      ($commands->{"source"} && 
       (($commands->{"r"} || 
	 $commands->{"remove"}) || 
	$commands->{"reinstall"} ||
       $commands->{"build-dep"} ||
       $commands->{"purge"})) 

	   ) {

    print "swim: ";
    print "-r " if defined $commands->{"r"};
    print "--remove " if defined $commands->{"remove"};
    print "--purge " if defined $commands->{"purge"};
    print "--reinstall " if defined $commands->{"reinstall"};
    print "--build-dep " if defined $commands->{"build-dep"};
    print "--source " if defined $commands->{"source"};
    print "cannot be used together\n";
    exit;
  }
  if (($commands->{"y"} || 
       $commands->{"z"} || 
       $commands->{"x"} ||
       $commands->{"download-only"}) && 
 
      ($commands->{"ftp"})) {

    print "swim: -";
    print "x" if $commands->{"x"};
    print "y" if $commands->{"y"};
    print "z" if $commands->{"z"};
    print " --download-only" if $commands->{"download-only"};
    print " cannot be used with ";
    #print "--purge " if defined $commands->{"purge"};
    print "--ftp " if defined $commands->{"ftp"};
    print "\n";
    exit;
  }

  #if (($commands->{"source"} && $commands->{"source_only"})) {
  #  print "swim: --source and --source_only cannot be used together\n";
  #  exit;
  #}
  #if (($commands->{"source"} || 
  #     $commands->{"source_only"}) &&

  #    !$commands->{"ftp"}) {

  # print "swim: --";
  #  print "source" if $commands->{"source"};
  #  print "source_only" if $commands->{"source_only"};
  #  print " cannot be used without --ftp\n";
  #  exit;
  #}  

  if (($commands->{"y"} || $commands->{"z"} || $commands->{"download-only"}) &&
       !$commands->{"x"}) {
    print "swim: requires -x option\n";
    exit;
  }

  if ($commands->{"x"}) {
   # There's no sense in doing this if the wrong architecture is called.
   if (defined $dpkg) {
    system "$dpkg --print-installation-architecture > $tmp/arch.deb";
    open(ARCH, "$tmp/arch.deb") or warn "couldn't find arch\n";
    my @arch = <ARCH>; chomp $arch[0];
    my($arch,$dist) = which_archdist(\%commands); $arch =~ m,^-(.*),;
    if ($1 ne $arch[0]) {
       print "swim: apt uses the $arch[0] architecture\n";
       exit;   
    }
   }
  }


  ###############
  # SAFETY MODE #
  ###############
  if ( (

       $commands->{"x"} || 

	($commands->{"x"} && 
	 $commands->{"y"}) || 

       ($commands->{"x"} && 

	($commands->{"r"} || 
	 $commands->{"remove"})) ||

	($commands->{"x"} && 
	 $commands->{"y"} && 
	 ($commands->{"r"} ||
	  $commands->{"remove"}))
	
	) && 
       
       !($commands->{"z"} || $commands->{"download-only"}) ) {

      my $arg;
      my $count = 0;
      foreach (@PACKAGES) {
	  if ($count == 0) {  
	      $arg = "$_";
	  }
	  else {
	      $arg = $arg . " " . "$_";
	  }  
	  $count++;
      }
      #########
      # STDIN #
      #########
      if ($commands->{"stdin"}) {
	  my $term = Term::ReadLine->new("Simple Shell");
	  my @HISTORY = history(\%commands);
	  $term->addhistory(@HISTORY);
	  my @history; push(@history,"$arg");
	  print "swim: type exit to finish --stdin\n";
	  my $termcount = 0;
	  while ($termcount < 1 ) {
	      $_ = $term->readline('swim: ',"$arg");
	      push (@history,$_);
	      $termcount++;
	  } do { $_ = $term->readline('swim: '); 
		 push (@history,$_);
	     } while  $_ ne "exit";
	  $arg = $history[$#history - 1];
	  if ($arg ne $HISTORY[$#HISTORY]) {
	      if ($arg =~ m,^[^\w],) {
		  $arg =~ s,^\s+(\w+),$1,;
	      }
	      history_print($arg,\%commands);
	  }
      } 
      
      if ( $commands->{"r"} || $commands{"remove"} ) {
	  system "$apt_get remove -qs $arg";
      }
      elsif ( $commands->{"purge"} ) {
	  system "$apt_get --purge remove -qs $arg";
      }
      elsif ( $commands->{"reinstall"} ) {
	  system "$apt_get --reinstall install -qs $arg";
      }
      elsif ( $commands->{"build-dep"} ) {
	  system "$apt_get build-dep -qs $arg";
      }
      elsif ( $commands->{"source"} ) {

	  if ( $commands->{"tar-only"} || 
	       $commands->{"diff-only"} ||
	       
	       ($commands->{"tar-only"} &&
		$commands->{"diff-only"})
	       ) {
	      if ( $commands->{"tar-only"} ) {
		  system "$apt_get source --tar-only -qs $arg";
	      }
	      if ( $commands->{"diff-only"} ) {
		  system "$apt_get source --diff-only -qs $arg";
	      }
	  }	      
	  else {
	      if ( $commands->{"b"} ) {
		  system "$apt_get source -qbs $arg";
	      }
	      else {
		  system "$apt_get source -qs $arg";
	      }
	  }

      }
      else {
	  system "$apt_get install -qs $arg";
      }
      
  }


  #############################
  # SAFETY MODE DOWNLOAD-ONLY #
  #############################
  # --download-only and simulate
  elsif ($commands->{"download-only"} && !$commands->{"z"} ) {

      my $arg;
      my $count = 0;
      foreach (@PACKAGES) {
	  if ($count == 0) {  
	      $arg = "$_";
	  }
	  else {
	      $arg = $arg . " " . "$_";
	  }  
	  $count++;
      }
      #########
      # STDIN #
      #########
      if ($commands->{"stdin"}) {
	  my $term = Term::ReadLine->new("Simple Shell");
	  my @HISTORY = history(\%commands);
	  $term->addhistory(@HISTORY);
	  my @history; push(@history,"$arg");
	  print "swim: type exit to finish --stdin\n";
	  my $termcount = 0;
	  while ($termcount < 1 ) {
	      $_ = $term->readline('swim: ',"$arg");
	      push (@history,$_);
	      $termcount++;
	  } do { $_ = $term->readline('swim: '); 
		 push (@history,$_);
	     } while  $_ ne "exit";
	  $arg = $history[$#history - 1];
	  if ($arg ne $HISTORY[$#HISTORY]) {
	      if ($arg =~ m,^[^\w],) {
		  $arg =~ s,^\s+(\w+),$1,;
	      }
	      history_print($arg,\%commands);
	  }
      } 
      
      if ( $commands->{"r"} || $commands{"remove"} ) {
	  system "$apt_get remove -qds $arg";
      }
      elsif ( $commands->{"purge"} ) {
	  system "$apt_get --purge remove -qds $arg";
      }
      elsif ( $commands->{"reinstall"} ) {
	  system "$apt_get --reinstall install -qds $arg";
      }
      elsif ( $commands->{"source"} ) {
	  if ( $commands->{"tar-only"} ) {
	      system "$apt_get source --tar-only -qds $arg";
	  }
	  elsif ( $commands->{"diff-only"} ) {
	      system "$apt_get source --diff-only -qds $arg";
	  }
	  else {
	      system "$apt_get source -qds $arg";
	  }
      }
      elsif ( $commands->{"source"} ) {

	  if ( $commands->{"tar-only"} || 
	       $commands->{"diff-only"} ||
	       
	       ($commands->{"tar-only"} &&
		$commands->{"diff-only"})
	       ) {
	      if ( $commands->{"tar-only"} ) {
		  system "$apt_get source --tar-only -qds $arg";
	      }
	      if ( $commands->{"diff-only"} ) {
		  system "$apt_get source --diff-only -qds $arg";
	      }
	  }	      
	  else {
	      if ( $commands->{"b"} ) {
		  system "$apt_get source -qdbs $arg";
	      }
	      else {
		  system "$apt_get source -qds $arg";
	      }
	  }
      }
      elsif ( $commands->{"build-dep"} ) {
	  system "$apt_get build-dep -qds $arg";
      }
      else {
	  system "$apt_get install -qds $arg";
      }

  }

  #####################
  # INSTALLATION MODE #
  #####################
  # provides optional --stdin to change packages to be installed 
  # from the command line
  else {
    my $arg;
    my $count = 0;
    foreach (@PACKAGES) {
     if ($count == 0) {  
       $arg = "$_";
     }
     else {
       $arg = $arg . " " . "$_";
     }  
      $count++;
    }
    #########
    # STDIN #
    #########
    if ($commands->{"stdin"}) {
     my $term = Term::ReadLine->new("Simple Shell");
     my @HISTORY = history(\%commands);
     $term->addhistory(@HISTORY);
     my @history; push(@history,"$arg");
     print "swim: type exit to finish --stdin\n";
     my $termcount = 0;
     while ($termcount < 1 ) {
       $_ = $term->readline('swim: ',"$arg");
       push (@history,$_);
       $termcount++;
     } do { $_ = $term->readline('swim: '); 
            push (@history,$_);
           } while  $_ ne "exit";
      $arg = $history[$#history - 1];
      if ("$arg" ne "$HISTORY[$#HISTORY]") {
        if ($arg =~ m,^[^\w],) {
          $arg =~ s,^\s+(\w+),$1,;
        }
         history_print($arg,\%commands);
      }
    } 
    #######
    # XYZ #
    #######
    if (
	!($commands->{"ftp"} || 
	  $commands->{"purge"} || 
	  $commands->{"reinstall"} ||
	  $commands->{"build-dep"} ||
	  $commands->{"remove"} ||
	  $commands->{"r"} )

	) {

	################################
	# INSTALL SOURCE DOWNLOAD-ONLY #
        ################################
	if ( $commands->{"x"} ) {
	    if (!$commands->{"y"}) {
		if (!$commands->{"download-only"}) {

		    if ( !$commands->{"source"} ) {
			system "$apt_get install $arg";
		    }
		    elsif ( $commands->{"source"} ) {

			if ( $commands->{"tar-only"} || 
			     $commands->{"diff-only"} ||
	       
			     ($commands->{"tar-only"} &&
			      $commands->{"diff-only"})
			     ) {
			    if ( $commands->{"tar-only"} ) {
				system "$apt_get source --tar-only $arg";
			    }
			    if ( $commands->{"diff-only"} ) {
				system "$apt_get source --diff-only $arg";
			    }
			}	      
			else {
			    if ( $commands->{"b"} ) {
				system "$apt_get source -b $arg";
			    }
			    else {
				system "$apt_get source $arg";
			    }
			}
			
		    }
		}
		else {

		    if ( !$commands->{"source"} ) {
			system "$apt_get -d install $arg";
		    }
		    elsif ( $commands->{"source"} ) {
			
			if ( $commands->{"tar-only"} || 
			     $commands->{"diff-only"} ||
			     
			     ($commands->{"tar-only"} &&
			      $commands->{"diff-only"})
			     ) {
			    if ( $commands->{"tar-only"} ) {
				system "$apt_get source -d --tar-only $arg";
			    }
			    if ( $commands->{"diff-only"} ) {
				system "$apt_get source -d --diff-only $arg";
			    }
			}	      
			else {
			    if ( $commands->{"b"} ) {
				system "$apt_get source -bd $arg";
			    }
			    else {
				system "$apt_get source -d $arg";
			    }
			}
			
		    }
		} 
	    }
	    #####
	    # Y #
	    #####
	    else {
		if (!$commands->{"download-only"}) {
		    
		    if ( !$commands->{"source"} ) {
			system "$apt_get install -y $arg";
		    }
		    elsif ( $commands->{"source"} ) {
			
			if ( $commands->{"tar-only"} || 
			     $commands->{"diff-only"} ||
			     
			     ($commands->{"tar-only"} &&
			      $commands->{"diff-only"})
			     ) {
			    if ( $commands->{"tar-only"} ) {
				system "$apt_get source -y --tar-only $arg";
			    }
			    if ( $commands->{"diff-only"} ) {
				system "$apt_get source -y --diff-only $arg";
			    }
			}	      
			else {
			    if ( $commands->{"b"} ) {
				system "$apt_get source -by $arg";
			    }
			    else {
				system "$apt_get source -y $arg";
			    }
			}
			
		    }
		}
		else {

		    if ( !$commands->{"source"} ) {
			system "$apt_get install -y -d $arg";
		    }
		    elsif ( $commands->{"source"} ) {
			
			if ( $commands->{"tar-only"} || 
			     $commands->{"diff-only"} ||
			     
			     ($commands->{"tar-only"} &&
			      $commands->{"diff-only"})
			     ) {
			    if ( $commands->{"tar-only"} ) {
				system "$apt_get source -yd --tar-only $arg";
			    }
			    if ( $commands->{"diff-only"} ) {
				system "$apt_get source -yd --diff-only $arg";
			    }
			}	      
			else {
			    if ( $commands->{"b"} ) {
				system "$apt_get source -byd $arg";
			    }
			    else {
				system "$apt_get source -y -d $arg";
			    }
			}

		    }

		}
	    }
	} # if -x
	
    }
    #######
    # FTP #
    #######
    elsif ($commands->{"ftp"}) {
      require SWIM::Qftp;
      SWIM::Qftp->import(qw(qftp));
      qftp($arg,\%commands);
    }
  
    ########################################################
    # PURGE & REMOVE & REINSTALL & BUILD-DEP DOWNLOAD-ONLY #
    ########################################################
    elsif ($commands->{"purge"} || 
	   $commands->{"remove"} || 
	   $commands->{"r"} ||
	   $commands->{"reinstall"} ||
	   $commands->{"build-dep"}
	   ){        

      purge($arg,\%commands);

    }

    # this is a good time to return the versions, too, as well as
    # including any NEW packages from --db and --ndb.  We'll assume $arg
    # from qftp will never be too large
    if (!$commands->{"n"}) {
      dbi(\%commands);
      @PACKAGES = map($db{$_},(@PACKAGES = split(/\s/,$arg)));
    }
    else {
      ndb(\%commands);
      @PACKAGES = map($db{$_},(@PACKAGES = split(/\s/,$arg)));
    }
    untie %db;
  } 

} # end sub xyz


# Remove (keep configuration files) or purge everything for each package.
sub purge {

 my ($arg,$commands) = @_;


 if (!$commands->{"n"}) {

     # not yes 
     if (!$commands->{"y"}) {
	 # not download-only
	 if (!$commands->{"download-only"}) {

	     if ($commands->{"purge"}) {
		 system "$apt_get --purge remove $arg";  
	     }
	     elsif ($commands->{"remove"} || $commands->{"r"}) {
		 system "$apt_get remove $arg";  
	     }
	     elsif ($commands->{"reinstall"}) {
		 system "$apt_get --reinstall install $arg";
	     }
	     elsif ($commands->{"build-dep"}) {
		 system "$apt_get build-dep $arg";
	     }

	 }
	 # download-only
	 else {

	     if ($commands->{"purge"}) {
		 system "$apt_get --purge -d remove $arg";  
	     }
	     elsif ($commands->{"remove"} || $commands->{"r"}) {
		 system "$apt_get -d remove $arg";  
	     }
	     elsif ($commands->{"reinstall"}) {
		 system "$apt_get -d --reinstall install $arg";
	     }
	     elsif ($commands->{"build-dep"}) {
		 system "$apt_get -d build-dep $arg";
	     }

	 }
	  
     }
     # yes
     else {
	 # not download-only
	 if (!$commands->{"download-only"}) {

	     if ($commands->{"purge"}) {
		 system "$apt_get -y --purge remove $arg";  
	     }
	     elsif ($commands->{"remove"} || $commands->{"r"}) {
		 system "$apt_get -y remove $arg";  
	     }
	     elsif ($commands->{"reinstall"}) {
		 system "$apt_get -y --reinstall install $arg";
	     }
	     elsif ($commands->{"build-dep"}) {
		 system "$apt_get -y build-dep $arg";
	     }

	 }
	 # download
	 else {

	     if ($commands->{"purge"}) {
		 system "$apt_get -yd --purge remove $arg";  
	     }
	     elsif ($commands->{"remove"} || $commands->{"r"}) {
		 system "$apt_get -yd remove $arg";  
	     }
	     elsif ($commands->{"reinstall"}) {
		 system "$apt_get -yd --reinstall install $arg";
	     }
	     elsif ($commands->{"build-dep"}) {
		 system "$apt_get -yd build-dep $arg";
	     }

	 }

     }

 }
 # if commands = -n
 else {
     print "swim: ";
     print "-r " if defined $commands->{"r"};
     print "--remove " if defined $commands->{"remove"};
     print "--purge " if defined $commands->{"purge"};
     print "--reinstall " if defined $commands->{"reinstall"};
     print "--build-dep " if defined $commands->{"build-dep"};
     print "can only be used with installed packages\n";
 }


} # end sub purge


# find the history file and return proper output
sub history {

    my($commands) = @_;
    my %commands = %$commands;

    my($arch,$dist) = which_archdist(\%commands);
    my($place) = finddb(\%commands);
    my $swim_history;
    if ($commands->{"n"}) {
     $swim_history = "$place/.nswim$arch$dist" . "_history";
    }
    else {
     $swim_history = "$place/.swim" . "_history";
    }
    open(HISTORY,"$swim_history") or exit;
    my (@HISTORY,$line);
    while (<HISTORY>) {
     chomp;
     foreach (split(/\s/,$_)) {
       if (!defined $line) {
         $line =  (split(/_/,$_))[0];
       }
       else {
         $line = $line . " " . (split(/_/,$_))[0];
       }
     }
      push(@HISTORY,$line); undef $line;
    }


    return @HISTORY;
 
} # end sub history

# append history if it has changed
sub history_print {

    my($arg,$commands) = @_;
    my %commands = %$commands;
    my($arch,$dist) = which_archdist(\%commands);
    my($place) = finddb(\%commands);
    my $swim_history;
    if ($commands->{"n"}) {
     $swim_history = "$place/.nswim$arch$dist" . "_history";
    }
    else {
     $swim_history = "$place/.swim" . "_history";
    }
   open(HISTORY,"$swim_history") or exit;
   my @HISTORY = <HISTORY>;
   close(HISTORY);
   if ($#HISTORY < $HISTORY - 1) {
     push(@HISTORY,"$arg\n") if $arg;
   }
   else {
    shift(@HISTORY);
    push(@HISTORY,"$arg\n") if $arg;
   } 
    open(HISTORY,">$swim_history") or exit;
    print HISTORY @HISTORY;
 
} # end sub history_print

1;
