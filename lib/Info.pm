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


package SWIM::Info;
use strict;
use SWIM::Conf qw(:Info);
use SWIM::Global qw(:Info);   
use SWIM::DB_Library qw(:Xyz);
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(scripts copyright changelog menu conf shlibs);

# scripts() copyright() changelog() menu() conf() shlibs()
# the text stuff taken out of info for the installed system, though the
# not-installed system in checked for, just in case.

# This shows all the scripts identified with a package(s).  In certain
# cases it is valuable to print a script without the name of the package,
# so if --scripts, -a, or -t isn't called, the pure script will be
# presented.
sub scripts {

  my ($commands) = @_;
  my %commands = %$commands;

  my ($file, $preinst, $postinst, $prerm,
      $postrm, $orig_argument);
      

  if ($commands->{"n"}) {
    print "swim: no scripts for not-installed, consider --diff\n"; exit;
  }

  dbi(\%commands);

    if ($argument =~ /_/) {
       $orig_argument = $argument;
       my $check = $db{"$argument"};
       $argument =~ m,(^.*)_(.*$),;
        if (defined $check) {
         $argument = $1;
         }
        else {};
    }
  untie %db;
      

   # here we will print out whatever we find including the file name.
   if ($commands->{"scripts"} && !($commands->{"preinst"} ||
       $commands->{"postinst"} || $commands->{"prerm"} ||
       $commands->{"postrm"})) {
     if (defined "$parent$base/info/$argument.preinst") {     
         $preinst = "$parent$base/info/$argument.preinst";
     }
     if (defined "$parent$base/info/$argument.postinst") {     
        $postinst = "$parent$base/info/$argument.postinst";
     }
     if (defined "$parent$base/info/$argument.prerm") {     
        $prerm = "$parent$base/info/$argument.prerm";
     }
     if (defined "$parent$base/info/$argument.postrm") {     
        $postrm = "$parent$base/info/$argument.postrm";
     }
     
     if (-e $preinst) {
       print "#####$argument.preinst#####\n\n";
       open (LIST,"$preinst");
       while (<LIST>) {                                           
        print $_;             
       }      
     } 
     if (-e $postinst) {
       print "#####$argument.postinst#####\n\n";
       open (LIST,"$postinst");
       while (<LIST>) {                                           
        print $_;             
       }      
     } 
     if (-e $prerm) {
       open (LIST,"$prerm");
       print "#####$argument.prerm#####\n\n";
       while (<LIST>) {                                           
        print $_;             
       }      
     } 
     if (-e $postrm) {
       open (LIST,"$postrm");
       print "#####$argument.postrm#####\n\n";
       while (<LIST>) {                                           
        print $_;             
       }      
     } 
   } # if scripts


   # from here on we just print out the particular script(s) called
   # literally with no filename, unless -a or -t is called.  This is one
   # situation in which -t has a use apart from the global default.  A

   # title is printed out for singular scripts in this case.
   
   if ($commands->{"preinst"}) {
     if (defined "$parent$base/info/$argument.preinst") {     
         $preinst = "$parent$base/info/$argument.preinst";
     }
     if (-e $preinst) {
      if ($commands->{"a"} || $commands->{"t"}) { 
       print "#####$argument.preinst#####\n\n";
       open (LIST,"$preinst");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
      else {
       open (LIST,"$preinst");
       while (<LIST>) {                                           
        print $_;             
       }      
     } 
     }
   }

   if ($commands->{"postinst"}) { 
     if (defined "$parent$base/info/$argument.postinst") {     
        $postinst = "$parent$base/info/$argument.postinst";
     }
     if (-e $postinst) {
      if ($commands->{"a"} || $commands->{"t"}) { 
       print "#####$argument.postinst#####\n\n";
       open (LIST,"$postinst");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
      else {
       open (LIST,"$postinst");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
     }
   }

   if ($commands->{"prerm"}) {
     if (defined "$parent$base/info/$argument.prerm") {     
        $prerm = "$parent$base/info/$argument.prerm";
     }
     if (-e $prerm) {
      if ($commands->{"a"} || $commands->{"t"}) { 
       print "#####$argument.prerm#####\n\n";
       open (LIST,"$prerm");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
      else {
       open (LIST,"$prerm");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
     } 
   }

   if ($commands->{"postrm"}) {
     if (defined "$parent$base/info/$argument.postrm") {     
        $postrm = "$parent$base/info/$argument.postrm";
     }
     if (-e $postrm) {
      if ($commands->{"a"} || $commands->{"t"}) { 
       print "#####$argument.postrm#####\n\n";
       open (LIST,"$postrm");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
      else {
       open (LIST,"$postrm");
       while (<LIST>) {                                           
        print $_;             
       }      
      }
     } 
   }

     if (!$commands->{"i"}) {
      if (defined $orig_argument) {
       $argument = $orig_argument;
      }
     }

} # end sub scripts

# show the scripts for /usr/lib/menu
sub menu {

  my ($commands) = @_;
  my %commands = %$commands;

  my $filelist;
  my $orig_argument = $argument;
  my %parent;

  if ($commands->{"n"}) {
    print "swim: no menu for not-installed, consider --diff\n"; exit;
  }

  dbi(\%commands);
  

    if ($argument =~ /_/) {
       $orig_argument = $argument;
       my $check = $db{"$argument"};
       $argument =~ m,(^.*)_(.*$),;
        if (defined $check) {
         $argument = $1;
         }
        else {};
    }
  untie %db;
   
   if (defined $argument) {
    if (-e "$parent$base/info/$argument.list") {
        $filelist = "$parent$base/info/$argument.list";
    } 
     if (defined $filelist) { 
      # basically, re-find file/package passed to previous sub
      open(FINDMENU,"$filelist");
       while (<FINDMENU>) {
         chomp;
         if (m,^\/usr\/lib\/menu\/(.*(\w-\+\.)),) {
          if (!-d) { 
           print "#####menu for $orig_argument($1)#####\n";
           open(MENU,"$_");
           while (<MENU>) {
             print;
           }
          print "\n";
          }
         }
       }
       close(FINDMENU);
       close(MENU);
    }
   } # defined

     if (!$commands->{"i"}) {
       $argument = $orig_argument;
     }

} # end sub menu


# Show changelog, default zcat.  This will show all the changelogs in
# the directory /usr/doc/package_name/, there are cases where there is
# a debian.changelog and one provided by the individual(s) working on the
# software, as well as a variety of other cases.
sub changelog {

  my ($commands) = @_;
  my %commands = %$commands;

  my $file;
  my $orig_argument = $argument;

  if ($commands->{"n"}) {
    print "swim: no changelog for not-installed, consider --diff\n"; exit;
  }

    dbi(\%commands);

    if ($argument =~ /_/) {
       $orig_argument = $argument;
       my $check = $db{"$argument"};
       $argument =~ m,(^.*)_(.*$),;
        if (defined $check) {
         $argument = $1;
         }
        else {};
    }
  untie %db;

   
     # Using swim -qadt | grep -i change it looks like all the files which
     # have change in their name are changelogs when in /usr/doc/$argument,
     # sometimes there are more above, but these are the most significant.
     my @fsstnd;
     if (-e "$parent/usr/doc/$argument" &&
         -d "$parent/usr/doc/$argument") {
        my $directory = "$parent/usr/doc/$argument";
        opendir(CHANGE, "$directory") || die "I thought it existed";
          my @change = sort grep(/change/i, readdir(CHANGE));
       closedir(CHANGE);
       foreach (@change) {
         if (m,\.gz$,i) {
           push(@fsstnd,$_);
           print "#####$_ for $argument#####\n\n";
           open(ZCAT,"|$zcat") || die "swim: this option requires zcat";
           open(CHANGELOG, "$directory/$_");
            while (<CHANGELOG>) {
             print ZCAT $_;
            }
           close(ZCAT);
           close(CHANGELOG);
           print "\n";
         } 
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
           push(@fsstnd,$_);
           print "#####$_ for $argument#####\n\n";
           open(CHANGELOG, "$directory/$_");
            while (<CHANGELOG>) {
             print "$_";
            }
           close(CHANGELOG);
           print "\n";
         }
       }
     } 

     if (-e "$parent/usr/share/doc/$argument" &&
         -d "$parent/usr/share/doc/$argument") {
        my $directory = "$parent/usr/share/doc/$argument";
        opendir(CHANGE, "$directory") || die "I thought it existed";
          my @change = sort grep(/change/i, readdir(CHANGE));
       closedir(CHANGE);
       foreach (@change) {
         if (m,\.gz$,i) {
          my $cf = grep(m,^$_$,,@fsstnd);
          if ($cf == 0 ) {
           print "#####$_ for $argument#####\n\n";
           open(ZCAT,"|$zcat") || die "swim: this option requires zcat";
           open(CHANGELOG, "$directory/$_");
            while (<CHANGELOG>) {
             print ZCAT $_;
            }
           close(ZCAT);
           close(CHANGELOG);
           print "\n";
          }
         } 
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
          my $cf = grep(m,^$_$,,@fsstnd);
          if ($cf == 0 ) {
           print "#####$_ for $argument#####\n\n";
           open(CHANGELOG, "$directory/$_");
            while (<CHANGELOG>) {
             print "$_";
            }
           close(CHANGELOG);
           print "\n";
          }
         }
       }
     } 


     if (!$commands->{"i"}) {
       $argument = $orig_argument;
     }

} # end sub changelog

# Show copyright, default zcat.  This will show all the copyrights in
# the directory /usr/doc/package_name/.  Rather than passing the
# greped argument to changelog(), this subroutine was created instead which
# keeps things sensible.
sub copyright {

  my $file;
  my $orig_argument = $argument;

  my ($commands) = @_;
  my %commands = %$commands;
      

  if ($commands->{"n"}) {
    print "swim: no copyright for not-installed, consider --diff\n"; exit;
  }

  dbi(\%commands);


    if ($argument =~ /_/) {
       $orig_argument = $argument;
       my $check = $db{"$argument"};
       $argument =~ m,(^.*)_(.*$),;
        if (defined $check) {
         $argument = $1;
         }
        else {};
    }
  untie %db;

   
     # Using swim -qadt | grep -i copy it looks like all the files which
     # have copy in their name are generally copyrights when in
     # /usr/doc/$argument, sometimes there are more above, but these are
     # the most significant.
     my @fsstnd;
     if (-e "$parent/usr/doc/$argument" &&
         -d "$parent/usr/doc/$argument") {
        my $directory = "$parent/usr/doc/$argument";
        opendir(CHANGE, "$directory") || die "I thought it existed";
          my @change = sort grep(/copy|license/i, readdir(CHANGE));
       closedir(CHANGE);       
       foreach (@change) {
        if (defined $_) {
         if (m,\.gz$,i) {
           push(@fsstnd,$_);
           print "#####$_ for $orig_argument#####\n\n";
           open(ZCAT,"|$zcat") || die "swim: this option requires zcat";
           open(COPYRIGHT, "$directory/$_");
            while (<COPYRIGHT>) {
             print ZCAT $_;
            }
           # Sometimes these next two mysteriously open, and don't close
           # even when no previous gz file was found, causing error output,
           # but doesn't effect what's trying to be accomplished.  Doesn't
           # happen with changelog().
           close(ZCAT);
           close(COPYRIGHT);
           print "\n";
         } 
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
           push(@fsstnd,$_);
           print "#####$_ for $orig_argument#####\n\n";
           open(COPYRIGHT, "$directory/$_");
            while (<COPYRIGHT>) {
             print "$_";
            }
           close(COPYRIGHT);
           print "\n";
         }
        } # if defined
       }
     } 

     if (-e "$parent/usr/share/doc/$argument" &&
         -d "$parent/usr/share/doc/$argument") {
        my $directory = "$parent/usr/share/doc/$argument";
        opendir(CHANGE, "$directory") || die "I thought it existed";
          my @change = sort grep(/copy|license/i, readdir(CHANGE));
       closedir(CHANGE);       
       foreach (@change) {
        if (defined $_) {
         if (m,\.gz$,i) {
          my $cf = grep(m,^$_$,,@fsstnd);
          if ($cf == 0 ) {
           print "#####$_ for $orig_argument#####\n\n";
           open(ZCAT,"|$zcat") || die "swim: this option requires zcat";
           open(COPYRIGHT, "$directory/$_");
            while (<COPYRIGHT>) {
             print ZCAT $_;
            }
           # Sometimes these next two mysteriously open, and don't close
           # even when no previous gz file was found, causing error output,
           # but doesn't effect what's trying to be accomplished.  Doesn't
           # happen with changelog().
           close(ZCAT);
           close(COPYRIGHT);
           print "\n";
          }
         } 
         elsif ($_ !~ m,html$|htm$|ps$|dvi$|sgml$|gs$,) {
          my $cf = grep(m,^$_$,,@fsstnd);
          if ($cf == 0 ) {
           print "#####$_ for $orig_argument#####\n\n";
           open(COPYRIGHT, "$directory/$_");
            while (<COPYRIGHT>) {
             print "$_";
            }
           close(COPYRIGHT);
           print "\n";
          }
         }
        } # if defined
       }
     } 

     if (!$commands->{"i"}) {
       $argument = $orig_argument;
     }

} # end copyright

# process the database for the configuration files
sub conf {

  my ($commands) = @_;
  my %commands = %$commands;

  # added for -xyz, but not necessary
  if (defined $argument) {
     if ($argument !~ /_/) {
       if (defined $db{$argument}) {
         $argument = $db{$argument};
       }
     }
  }
  if (!$commands->{"n"}) {
   dbi(\%commands);
  }
  else {}
  if (defined $argument) {
    my $conf = $argument . "CONF";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return 0; }
  }
 untie %db;
} # end sub conf

# shared libraries provided by the package
sub shlibs {

  my ($commands) = @_;
  my %commands = %$commands;

  my $shlibs;
  my $orig_argument;

  if ($commands->{"n"}) {
    print "catswim: no shlibs for not-installed, consider --diff\n"; exit;
  }


  dbi(\%commands);

  if (defined $argument) {
    if ($argument =~ /_/) {
       $orig_argument = $argument;
       my $check;
       if (defined $db{"$argument"}) {
        $check = $db{"$argument"};
       }
       $argument =~ m,(^.*)_(.*$),;
        if (defined $check) {
         $argument = $1;
         }
         else {}
    }
    else {
       $orig_argument = $argument;
    }
  }
  untie %db;

  if (defined $argument) {
    if (-e "$parent$base/info/$argument.shlibs") {
        $shlibs = "$parent$base/info/$argument.shlibs";
    } 
  }
    
    if (defined $shlibs) {
     print "Shlibs:\n"; 
     open(SHLIBS,"$shlibs");
      while (<SHLIBS>) {
        if ($_ !~ m,^\n$,) {
         print;
        }
      }
     }

   $argument = $orig_argument;
      
} # end sub shlibs


1;
