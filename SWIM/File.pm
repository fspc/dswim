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


package SWIM::File;
use strict;
use SWIM::Global;   
use SWIM::DB_Library qw(:Xyz ram_on nsb);
use SWIM::Library;
use SWIM::Conf qw(:Path $md5sum);
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(file);


#=pod
#
#This provides the list of files belonging to a package.  Although a
#database could be used..it's probably faster, and cheaper on space
#accessing from the /var/lib/dpkg/info* files.  And if --md5sum is
#called, the md5sums are shown for the -d ,-l, or -c files they exist for.
#md5sums are checked for, and reported back as OK or FAILED. -l or
#-d(overrides l). -qd(l)  md5sum from RH has a slightly different
#output.. filepath/filename: file OK before swim's output..this can be
#altered
#
#=end

sub file {


  my ($commands) = @_;
  my %commands = %$commands;

  my $file;
  my $md5;
  my @md5;
  my $path;
  my @path;
  my $md5sums;
  my $md5sums_conf;
  my %md5sums = ();
  my $orig_argument;
  my $count = 0;


  if (!$commands->{"n"}) {
    dbi(\%commands);
  }
  # files/dirs will be found from contents.deb (compressed)
  else {
    ndb(\%commands);
  }

  if (defined $argument) {
    if ($argument =~ /_/) {
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
  }



  if (defined $argument) {
   if (!$commands->{"n"}) {
    $file = "$parent$base/info/$argument.list";  
    if (-e "$parent$base/info/$argument.md5sums") {
        $md5sums = "$parent$base/info/$argument.md5sums";
    } 
    if (-e "$parent$base/info/$argument-conf.md5sums" && $commands->{"c"}) {
        $md5sums_conf = "$parent$base/info/$argument-conf.md5sums";
    } 


       ##################
       # MD5SUMS FOR -C #
       ##################
       if ($commands->{"md5sum"} && $commands->{"c"} && !($commands->{"d"} ||
           $commands->{"l"})) {
       if (!defined $md5sums_conf && $commands->{"c"}) { 
         $md5sums_conf = make_conf(\%commands);
       }
       # now we can process $md5sums and $md5sums_conf assuming one or
       # both actually exist
     if (defined $md5sums_conf) {
       chdir("/"); 
       my %path;
       open (MD5SUM, "$md5sums_conf");
       open (MD5SUMCHECK, "|$md5sum -c 2>$tmp/md5sumcheck");
       while (<MD5SUM>) {                                           
          if ($_ =~ /newconffile/) {
            $path = substr($_, 13);  
            push(@path,$path);
            $md5 = substr($_, 0, 11);
            push(@md5,$md5);
            chomp $path;
            chomp $md5;
            $path{"$path"} = $md5;
            print MD5SUMCHECK $_;
            next;
          } 
          $path = substr($_, 34);  
          push(@path,$path);
          $md5 = substr($_, 0, 32);
          push(@md5,$md5);
          chomp $path;
          chomp $md5;
          $path{"$path"} = $md5;
          print MD5SUMCHECK $_;
        } 
        close(MD5SUMCHECK);
        close(MD5SUM);  
           #now check with md5sum from the dpkg package
           my $check_md5sum;
           # won't bother going into this while unless there is a reason
           if (defined "$tmp/md5sumcheck" && $md5 ne "newconffile") {
            open(MD5SUMFILE, "$tmp/md5sumcheck");
            while (<MD5SUMFILE>) {
             if ($_ !~ /no files checked/) {
              if (/failed/) {
               # Humm may be two situations watch or due to coding change
               #$check_md5sum = substr($_,39);
               $check_md5sum = substr($_,30);
               $check_md5sum =~ s/'//;           
               chomp $check_md5sum;
               $md5sums{"$check_md5sum"} = "FAILED";
              }
              elsif (/can't open/) {
               # Humm may be two situations watch or due to coding change
               #$check_md5sum = substr($_,28);
               $check_md5sum = substr($_,19);
               chomp $check_md5sum;
               $md5sums{"$check_md5sum"} = "MISSING";
              }
             }
            }
           }
          close(MD5SUMCHECK);
          unlink("$tmp/md5sumcheck");        
       # This finishes everything
       open (LIST,"$md5sums_conf");
       while (<LIST>) {                                           
          if ($_ =~ /newconffile/) {
            $_ = substr($_, 13);  
            chomp;
          } 
          else {
            $_ = substr($_, 34);  
            chomp;
          }
           if (defined $path{$_}) {
               # humm  file_now() not necessary here
               if (defined $md5sums{$_}) {
                 print " /$_  $path{$_}  $md5sums{$_}\n";
               }
               elsif ($path{$_} ne "newconffile") {
                 print " /$_  $path{$_}  OK";
                 print "\n"; 
              }            
               else {
                 print " /$_  $path{$_}\n";
               }
           }
       } # last while
       close(LIST);
       %md5sums = ();
       %path = ();
       @path = ();
       @md5 = ();
     } # do the md5sum files even exist?
     }

     ########################
     # MD5SUMS FOR -C &| -L #
     ########################
     # checking for -e $md5sums is a questionable practice because it
     # may not exist, but the conf files do.
     if ($commands->{"md5sum"} && !$commands->{"d"} && 
         (($commands->{"l"} && $commands->{"c"}) || $commands->{"l"}))  {
       # I decided on three while loops, because it was the most practical
       # way to handle STDERR from md5sum, and all types of
       # experimentation didn't yield a better way of doing it, but there
       # is probably a better way.  
       # first do things normally, and no chomping
       # but, first grab conf info.
       if (!defined $md5sums_conf && $commands->{"c"}) { 
         $md5sums_conf = make_conf(\%commands); 
       }
       # now we can process $md5sums and $md5sums_conf assuming one or
       # both actually exist
     if (defined $md5sums || defined $md5sums_conf) {
     #if ($md5sums_conf ne 1) {    
       chdir("/"); 
       my %path;
       if ($commands->{"c"} && $md5sums_conf) {
         open (MD5SUM,"$md5sums_conf");       
       }
       else {
        open (MD5SUM,"$md5sums");
        $count = 1;
       }
      while ($count <= 1) {
      if (($count == 1 && defined $md5sums) || $count == 0) {
       open (MD5SUMCHECK, "|$md5sum -c 2>$tmp/md5sumcheck");
       while (<MD5SUM>) {                                           
          if ($_ =~ /newconffile/) {
            $path = substr($_, 13);  
            push(@path,$path);
            $md5 = substr($_, 0, 11);
            push(@md5,$md5);
            chomp $path;
            chomp $md5;
            $path{"/$path"} = $md5;
            print MD5SUMCHECK $_;
            next;
          } 
          $path = substr($_, 34);  
          push(@path,$path);
          $md5 = substr($_, 0, 32);
          push(@md5,$md5);
          chomp $path;
          chomp $md5;
          $path{"/$path"} = $md5;
          print MD5SUMCHECK $_;
        } 
        close(MD5SUMCHECK);
        close(MD5SUM);  
           #now check with md5sum from the dpkg package
           my $check_md5sum;
           #my $count = 0;
           # won't bother going into this while unless there is a reason
           if (defined "$tmp/md5sumcheck" && $md5 ne "newconffile") {
            open(MD5SUMFILE, "$tmp/md5sumcheck");
            while (<MD5SUMFILE>) {        
             if ($_ !~ /no files checked/) {
              if (/failed/) {
               $check_md5sum = substr($_,30);
               $check_md5sum =~ s/'//;           
               chomp $check_md5sum;
               $md5sums{"/$check_md5sum"} = "FAILED";
              }
              elsif (/can't open/) {
               $check_md5sum = substr($_,19);
               #$check_md5sum =~ s/'//;           
               chomp $check_md5sum;
               $md5sums{"/$check_md5sum"} = "MISSING";
              }
             }
            }
           }
          close(MD5SUMCHECK);
          unlink("$tmp/md5sumcheck");        
      }
       # This finishes everything
       # This prunes stuff out and assumes that *.list and *.md5sums
       # overlap.
       open (LIST,"$file");
      ######
      # -L #
      ######
      if ($commands->{"l"}  && !$commands->{"df"}) {
       while (<LIST>) {                                           
         chomp;
         if (!-d $_ && $argument ne "base-files") {       
          my $line = $_;
          file_now(\%commands);
          md5_print(\%path,\%md5sums,$line,$count);
         } 
         ##############
         # BASE-FILES #
         ##############
         elsif ($argument eq "base-files") {
          my $line = $_;
          md5_print(\%path,\%md5sums,$line,$count);
         }      
       } # last while
      }
      #############
      # -L & --DF #
      #############
      elsif ($commands->{"l"} && $commands->{"df"}) {
       while (<LIST>) {                                           
         chomp;
          my $line = $_;
          file_now(\%commands);
          md5_print(\%path,\%md5sums,$line,$count);
       } # last while
      }
       close(LIST);
       %md5sums = ();
       %path = ();
       @path = ();
       @md5 = ();
      $count++;
       if ($count == 1) {
        open (MD5SUM,"$md5sums") if $md5sums;
       }
      } # loop through -c or not
     } # do the md5sum files even exist?
     #}
     }
     #@@  got to watch this for -l's called directly, will allow -l to
     # be seen whether or not --md5sum is used, changed elsif to if.
     # if already found above don't use below here.
     # && ||'s tricky here
     if (-e $file && !$commands->{"d"} && (!defined $md5sums &&
         !defined $md5sums_conf) || -e $file &&
         (!$commands->{"md5sum"} && !$commands->{"d"})) {
       file_now(\%commands) if !$commands->{"f"};
       open (LIST,"$file");
       while (<LIST>) {                                           
        chomp;
        if ($commands->{"l"} && !$commands->{"df"}) {
         if (!-d $_ && $argument ne "base-files") {       
          print "$_\n";             
         }
         elsif ($argument eq "base-files") {
          print "$_\n";
         }      
        }
        elsif ($commands->{"l"} && $commands->{"df"}) {
         if ($argument ne "base-files") {       
          print "$_\n";             
         }
         elsif ($argument eq "base-files") {
          print "$_\n";
         }      
        }
     }
     } 
       
     ########################
     # MD5SUMS FOR -C &| -D #
     ########################
     # for Documentation.
     elsif ($commands->{"md5sum"} && ($commands->{"d"} || ($commands->{"d"} &&
            $commands->{"c"}))) {
       if (!defined $md5sums_conf && $commands->{"c"}) { 
         $md5sums_conf = make_conf(\%commands);
       }
       # now we can process $md5sums and $md5sums_conf assuming one or
       # both actually exist
     if (defined $md5sums || defined $md5sums_conf) {
       chdir("/"); 
       my %path;
       if ($commands->{"c"} && $md5sums_conf) {
         open (MD5SUM,"$md5sums_conf");       
       }
       else {
        open (MD5SUM,"$md5sums");
        $count = 1;
       }
      while ($count <= 1) {
      if (($count == 1 && defined $md5sums) || $count == 0) {
       open (MD5SUMCHECK, "|$md5sum -c 2>$tmp/md5sumcheck");
       while (<MD5SUM>) {                                           
          if ($_ =~ /newconffile/) {
            $path = substr($_, 13);  
            push(@path,$path);
            $md5 = substr($_, 0, 11);
            push(@md5,$md5);
            chomp $path;
            chomp $md5;
            $path{"/$path"} = $md5;
            print MD5SUMCHECK $_;
            next;
          }
          $path = substr($_, 34);  
          push(@path,$path);
          $md5 = substr($_, 0, 32);
          push(@md5,$md5);
          chomp $path;
          chomp $md5;
          $path{"/$path"} = $md5;
          print MD5SUMCHECK $_;
        } 
        close(MD5SUMCHECK);
        close(MD5SUM); 
           #now check with md5sum from the dpkg package
           my $check_md5sum;
           # won't bother going into this while unless there is a reason
           if (defined "$tmp/md5sumcheck") {
            open(MD5SUMFILE, "$tmp/md5sumcheck");
            while (<MD5SUMFILE>) {
             if ($_ !~ /no files checked/) {
              if (/failed/) {
               $check_md5sum = substr($_,30);
               $check_md5sum =~ s/'//;           
               chomp $check_md5sum;
               $md5sums{"/$check_md5sum"} = "FAILED";
              }
              elsif (/can't open/) {
               $check_md5sum = substr($_,19);
               chomp $check_md5sum;
               $md5sums{"/$check_md5sum"} = "MISSING";
              }
             }
            }
           }
          close(MD5SUMCHECK);
          unlink("$tmp/md5sumcheck");
       }
       # This finishes everything
       open (LIST,"$file");
       while (<LIST>) {                                           
         chomp;
        # humm, checking for existence?
        #if (-e $_ && $argument ne "base-files") {       
        if ($argument ne "base-files") {       
            #@@
            ######
            # -D #
            ######
            if (defined $path{$_}) {
              if (defined $md5sums{$_}) {
                if ($count == 0) {  
                  print " $_  $path{$_}  $md5sums{$_}" if $count == 0;
                  print "$_  $path{$_}  $md5sums{$_}" if $count == 1;
                  print "\n";
                }
                elsif (m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, &&
                      $count == 1) {                      
                  print " $_  $path{$_}  $md5sums{$_}" if $count == 0;
                  print "$_  $path{$_}  $md5sums{$_}" if $count == 1;
                  print "\n";
                }
              }
              elsif ($path{$_} ne "newconffile") {
                if ($count == 0) {
                  print " $_  $path{$_}  OK" if $count == 0;
                  print "$_  $path{$_}  OK" if $count == 1;
                  print "\n";
                }
                elsif (m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, &&
                      $count == 1) {                      
                  print " $_  $path{$_}  OK" if $count == 0;
                  print "$_  $path{$_}  OK" if $count == 1;
                  print "\n";
                }
              } 
              else {
                if ($count == 0) {
                  print " $_  $path{$_}\n" if $count == 0;
                  print "$_  $path{$_}\n" if $count == 1;
                  print "\n";
                }
                elsif (m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, &&
                      $count == 1) {                      
                  print " $_  $path{$_}  OK" if $count == 0;
                  print "$_  $path{$_}  OK" if $count == 1;
                  print "\n";
                }
              }
            }
          elsif ($count == 1) {
            if (m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, && !-d) {                      
              file_now(\%commands);
              print "$_\n";
            }
          } 
        }
        # humm? treated specially, hopefully.
        ######################
        # BASE-FILES PACKAGE #
        ###################### 
        elsif ($argument eq "base-files") {
          my $line = $_;
          if ($line =~ m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, ||
              defined $path{$line}) {
            md5_print(\%path,\%md5sums,$line,$count);
          }
        }      
       } # another while
       close(LIST);
       %md5sums = ();
       %path = ();
       @path = ();
       @md5 = ();
      $count++;
       if ($count == 1) {
        open (MD5SUM,"$md5sums") if $md5sums;
       }
      } # loop through -c or not
     } # do the md5sum files even exist?
     }
     #@@ another important change, print --md5sum and -l together
     if (-e $file && $commands->{"d"} && (!defined $md5sums &&
         !defined $md5sums_conf) || -e $file &&
         (!$commands->{"md5sum"} && $commands->{"d"})) {
       file_now(\%commands) if !$commands->{"f"};
     #if (-e $file && $commands->{"d"}) {
       open (LIST,"$file");
       while (<LIST>) {
         chomp;
          if (m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/, && !-d) { 
              print "$_\n";
          }
       }
     }
     else {
       #if (!defined $md5sums || !defined $md5sums_conf) {
        if (!-e $file) {
         print "package $argument is not installed\n";
       }
     }
   } # if !--n
   else {
     # Let's check first if this package actually exists, files are checked
     # earlier.
     if (defined $argument) {
        if (!defined $db{"$argument"}) {
         print "package $argument is not installed\n";          
         return "not installed";
        }
     }
     nfile(\%commands);
   } 
  } # if defined $argument 

 untie %db;
 

         if (defined $file_now && !($commands->{"z"} ||
                                    $commands->{"ftp"} ||
                   $commands->{"remove"} || $commands->{"r"} ||
                   $commands->{"purge"} || $commands->{"reinstall"})) {
          if ($commands{"x"} || $commands{"ftp"} || $commands{"source"} ||
              $commands{"source_only"} || $commands{"remove"} ||
              $commands{"r"} || $commands{"purge"} || $commands->{"reinstall"} ) {
            require SWIM::Safex;
            SWIM::Safex->import(qw(safex));
            safex(\%commands);
          } 
         }


} # end sub file

# this manages situation involving -qlcx & -qglx
sub file_now {

       my ($commands) = @_;
       my %commands = %$commands;

       #if (!$commands->{"g"} && !defined $file_now) {
       if (!$commands->{"g"}) {
        if ($arg_count < $#ARGV) {
           push(@arg_holder,$argument);
           # humm
           #@PACKAGES = "DEFINEDONE";
           #@PACKAGES = "$ARGV[$#ARGV]";
           $arg_count++;
        }
        else { 
         @PACKAGES = @arg_holder;
         push(@PACKAGES,$argument);
        }
       }
       else {
        if ($arg_count < $#stuff) {
           push(@arg_holder,$argument);
           #$arg_count++;
        }
        else { 
         @PACKAGES = @arg_holder;
         push(@PACKAGES,$argument);
        }
       }

} # end file_now

# In order to run a md5sum test on configuration files directly recognized
# by dpkg, a file with package_name-conf.md5sums is created, in addition to
# any existing package_name.md5sums file.
sub make_conf {

       my ($commands) = @_;
       my %commands = %$commands;

        my $md5sums_conf;
        if (!$commands->{"n"}) {
         dbi(\%commands);
        }
        # humm, just a trap
        else {
         ndb(\%commands);
        }

        if ($argument !~ /_/ ) {
         # I guess we can stop here here is there are no configuration
         # files
         if (defined $db{$argument}) {
           require SWIM::Info;
           SWIM::Info->import(qw(conf));
           my $orig_argument = $argument;
           $argument = $db{$argument};
           my ($conf, @conf, %conf);
           my ($m5, $dir, $thing);
            if (conf(\%commands) ne 0) {
              $conf = conf(\%commands);
              @conf = split(/\n/, $conf);
              open(PACKCONF,">$main::home$parent$base/info/$orig_argument-conf.md5sums");
              foreach (@conf) {
               $_ =~ m,( \/)(.*$),;
               ($dir, $m5)  = split(/ /, $2, 2);
                $thing = "$m5  $dir\n";
                print PACKCONF $thing; 
              }
              close(PACKCONF);
              $md5sums_conf =
              "$main::home$parent$base/info/$orig_argument-conf.md5sums";
              return $md5sums_conf;
            } 
            else {
             return;
            }
          }
        }       
        untie %db;

}  # end sub make_conf


# prints out the results from the md5sum test for -l & -l --df
sub md5_print {

 my ($path, $md5sums, $line, $count) = @_;
  
           if (defined $path->{$line}) {
               if (defined $md5sums->{$line}) {
                  print " $line  $path->{$line}  $md5sums->{$line}" if $count == 0;
                  print "$line  $path->{$line}  $md5sums->{$line}" if $count == 1;
                  print "\n";
               }
               elsif ($path->{$line} ne "newconffile") {
                 print " $line  $path->{$line}  OK" if $count == 0;
                 print "$line  $path->{$line}  OK" if $count == 1;
                 print "\n";
               }            
               else {
                 print " $line  $path->{$line}\n" if $count == 0;
                 print "$line  $path->{$line}\n" if $count == 1;
               }
           }
           elsif ($count == 1) {
             print "$line\n";
           }

} # end md5_print


# -n The list of files/dirs belonging to a package.  No md5sum here.
sub nfile {

   my ($commands) = @_;
   my %commands = %$commands;  
   my $ramdisk = ram_on(\%commands);

  # Here's a case where gnu grep is faster than using open. 
  if ($ramdisk eq "yes") {
   my $what = "yes";
   process_nfile($what,\%commands);
  } # if ramdisk

  elsif ($ramdisk eq 1) {
    my $what = "no";
    process_nfile($what,\%commands);
  }

} # end sub nfile

# -n figure out --df, -d & -l using the contents db 
sub process_nfile {

   my ($what,$commands) = @_;
   my %commands = %$commands;
   my $contentsdb = finddb(\%commands);
   my ($arch,$dist) = which_archdist(\%commands);
   my ($Contents,$subject);


   # the + solution
   nsb(\%commands);
   $subject = (split(/\s/,$nsb{$argument}))[1];
   $argument =~ s,\+,\\\\+,g if $argument =~ m,\+,;
   untie %nsb;

   if ($what eq "no") { 
    if (-e "$contentsdb/ncontentsindex$arch$dist.deb.gz") {
     $Contents = "zgrep -E $argument\ $contentsdb/ncontentsindex$arch$dist.deb.gz|"; 
    }
   else {
      print "swim: stopping, cannot perform this operation without contents\n";
      exit;
   }
   }
   elsif ($what eq "yes") {
    if (-e "$contentsdb/dramdisk/ncontentsindex$arch$dist.deb.gz") {
     $Contents = "zgrep -E $argument\ $contentsdb/dramdisk/ncontentsindex$arch$dist.deb.gz|";
    }
    else {
      print "swim: stopping, cannot perform this operation without contents\n";
      exit;
    }
   }


   my($dirfile,$package,@dirfile,@comma,%all,%again);
    open(CONTENTSDB, "$Contents"); 
    while (<CONTENTSDB>) {
    # changed for >= 0.2.9 - will have to watch for these
    # guys net/sendfile, x11/xscreensaver, x11/xscreensaver,
    # graphics/ucbmpeg, admin/cfengine .. there is a space before them
    #if (/^FILE\s*LOCATION$/) {                                             
    #while (<CONTENTSDB>) {  
      if (!$commands->{"df"}) {
        # this isn't acurate for groups of packages ,,, so will use the
        # subject section instead of \b and $
        $argument =~ s,\\\\+,\\\+,g if $argument =~ m,\+,;
        if (m,$subject/$argument,) {
         ######################
         # DOESN'T END WITH / #
         ######################
         if ($_ !~ m,.*/\s+\w*,) {
           ($dirfile,$package) = split(/\s+/,$_,2);  
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           $dirfile = "/$dirfile";
           ######
           # -L #
           ######
           if (!$commands->{"d"} && $commands->{"l"}) { 
             print "$dirfile\n";
           }
           ######
           # -D #
           ######
           elsif ($commands->{"d"}) {
            if ($dirfile =~ m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/,) {
             print "$dirfile\n";
            } 
           }
         }
        }
      }
      ########
      # --DF #
      ########
      elsif ($commands->{"df"} && $commands->{"l"} && !$commands->{"d"}) {
        $argument =~ s,\\\\+,\\\+,g if $argument =~ m,\+,;
        if (m,$subject/$argument,) {
        #if (m,\b$argument\b,) {

         ######################
         #    ENDS WITH /     #
         ######################
         if (m,.*/\s+\w*,) {
           ($dirfile,$package) = split(/\s+/,$_,2);
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           @dirfile = split(/\//,$dirfile); $dirfile =~ s,/$,,;
         } 
         ######################
         # DOESN'T END WITH / #
         ######################
         else {
           ($dirfile,$package) = split(/\s+/,$_,2);  
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           @dirfile = split(/\//,$dirfile);
         }
         ###########################
         # PROCESS INTO FILES/DIRS #
         ###########################
         my ($count,$holder);
         for ($count = 0; $count <= $#dirfile; $count++) {
              if ($count == 0) {
                $holder = "/$dirfile[$count]";
                my $again = "$dirfile[$count]";
                my $all = "/.";
                $again{$again}++;
                $all{$all}++;
                if ($all{$all} == 1) {
                  print "/.\n";
                }
                if ($again{$again} == 1) {
                  print "/$dirfile[$count]\n";
                }
              }
              else {  
                $holder =  $holder . "/$dirfile[$count]";
                my $again = "$holder";
                $again{$again}++;
                if ($again{$again} == 1) {
                   print "$holder\n";
                }
              }
         } # end for
       }
      }
      ###################
      # -D & --DF &| -L #
      ###################
      elsif (($commands->{"d"} && $commands->{"df"}) || 
              $commands->{"d"} && $commands->{"df"} && $commands->{"l"}) {
         $argument =~ s,\\\\+,\\\+,g if $argument =~ m,\+,;
         if (m,$subject/$argument,) {
         #if (m,\b$argument$,) {

         ######################
         # DOESN'T END WITH / #
         ######################
         if ($_ !~ m,.*/\s+\w*,) {
           ($dirfile,$package) = split(/\s+/,$_,2);  
           if ($package !~ m,^[a-z0-9-]*/.*$|^[a-z0-9-]*/.*/.*$,) {
           my @more_things = split(/\s+/,$package);
           $package = $more_things[$#more_things];
           (my $backpackage = $package) =~ s,\+,\\+,g;
           my @dirfile = split(/\s+$backpackage/,$_);
           $dirfile = $dirfile[0];
           }
           $dirfile = "/$dirfile";
           ######
           # -D #
           ######
           if ($dirfile =~ m,/usr/doc/|/usr/share/doc/|/man[\d]/|/usr/info/|/usr/share/info/,) {
            print "$dirfile\n";
           } 
         }
        }
     }
    #}
    #}
    } # while
   close(CONTENTSDB);

}


1;
