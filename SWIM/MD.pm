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


package SWIM::MD;
use strict; 
use SWIM::Conf qw(:Path $splt);
use SWIM::DB_Library qw(:Md);
use SWIM::Library;
use SWIM::Global;
use vars qw(@ISA @EXPORT %EXPORT_TAGS);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(process_md);

# process_md used by both SWIM::DB_Init and SWIM::NDB_Init

=pod

Because many files and directories exist more than once, and it would be
kind of cool to go up to a directory /usr/bin or /usr/bin/ and do a
swim -qf and see all the packages that populate that directory...
multi-dimensional is the way to go.

=cut

sub process_md {

     print "File Database is being made\n";

     my ($commands) = @_;
     my %commands = %$commands;
     my @ppackage;
     my %md;
     my @md;
     my @mi;
     my $thingy;
     my @name;
     my $count = 0;
     my $count1 = 1;

     my($place) = finddb(\%commands);
     $place = "$default_directory$place";
          
     # Let's determine what architecture and distribution this person is
     # interested in.
     my ($arch, $dist, $not);
     if ($commands->{"initndb"} || $commands->{"rebuildndb"}) {  
       ($arch,$dist) = which_archdist(\%commands);
       $not = "n";
     }
     else {
        $arch = "";
        $dist = "";
        $not = "";
     }
     my $fileindex = $not . "fileindex";


     # Now we process the files made from the massive array, and create
     # fileindex.deb or nfileindex.deb    
     # Let's just use split, and will allow for customized line adj.    
     # 25000 is the default
     if ($commands->{"split_data"}) {
      my $split = $commands->{"split_data"};
      system("$splt -l $split $tmp/big.debian $tmp/DEBIAN");
     } 
     else {
      # Seems like a good default
      system("$splt -l 25000 $tmp/big.debian $tmp/DEBIAN");
     }
     @ppackage = <$tmp/DEBIAN*>;
     # It's unlikely this file will ever get too massive.
     push(@ppackage, "$tmp/long.debian");
     print "  Create the database\n";
     foreach $thingy (@ppackage) {  
      open(PARTS, "$thingy"); 
         while (<PARTS>) {
             my @c;
             @md = split(/ -> /,$_); 
             if (defined($md[1])) { 
              chomp $md[0];
              chomp $md[1];
              @c = split(/\s/, $md[1]); 
             }
             push(@mi,$md[0]);
             push(@mi,$md[1]);
        } # while        
       print "    $thingy\n";
       print "    wait a few seconds\n";
       my $zing;
       if (($commands->{"dbpath"} && $commands->{"root"}) ||
         ($commands->{"dbpath"} && !$commands->{"root"}) ||
         (!$commands->{"dbpath"} && !$commands->{"root"})) {
        $zing = tie %md, 'DB_File',"$default_directory$parent$library/$fileindex$arch$dist.deb" 
                or die "DB_File: $!";
       }
       elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
         $zing = tie %md, 'DB_File',"$default_directory$parent$base/$fileindex$arch$dist.deb" 
                 or die "DB_File: $!";
       }
       while ($count <= $#mi) {
         $zing->put($mi[$count], $mi[$count1]); 
         $count = $count + 2;
         $count1 = $count1 + 2;
       }     
      undef $zing;
      untie %md;
      undef %md;
      @mi = ();
      @md = ();
      $count = 0;
      $count1 = 1;
      close(PARTS); 
     } # end foreach  

     # now we get to take into account deinstall:ok:config-files
     # situations for an installed system.
     if ($commands->{"initdb"} || $commands->{"rebuilddb"}) {
       sb(\%$commands); ib(\%commands); my $yich;
        foreach (values %sb) { 
         my $zit; my ($nit,$yit) = (split(/\s/,$_))[0,3]; 
         if ($yit eq "deinstall:ok:config-files" ||
             $yit eq "purge:ok:config-files") { 
          ($zit = $nit) =~ s,\+,\\\+,; 
          if ($ib{"/."} !~ m,$zit,) {
           if (!defined $yich) {
             $yich = $nit;
           } 
           else {
             $yich = $yich . " $nit";
           } 
          }
         } 
        }
        $ib{"/."} = $ib{"/."} . " $yich";
     }

     # after much experimentation it turns out that a flat text file
     # is much faster for this particular application.  This also
     # creates the hash database reference for -db or -i.
     my $searchindex =  $not . "searchindex";
     open(FLATFILE, ">$place/$searchindex$arch$dist.deb");
     print "Create the powersearch flat database\n";
     foreach $thingy (@ppackage) {  
      if ($thingy ne "$tmp/long.debian") {
       open(PARTS, "$thingy");         
          while (<PARTS>) {
              @md = split(/ -> /,$_); 
              if (defined($md[1])) { 
               chomp $md[0];
              }
              push(@mi,$md[0]);
         } # while        
       }
       print "    $thingy\n";
       print "    wait a few seconds\n";
       while ($count <= $#mi) {
          print FLATFILE "$mi[$count]\n";
          $count++;
       }     
      $count = 0;
      @mi = ();
      @md = ();
      close(PARTS); 
    } # end foreach  
    close(FLATFILE);

     # This creates the flatfile with the directories for --powersearch
     # --dir, which is probably a rare match in most cases.  This doesn't
     # create a hash reference database for --db and -i because the only
     # package which could benifit from this is base-files, but it has
     # configuaration files, on the other hand RedHat has at least one 
     # package without directories or files, but this is Debian.
     my $dirindex =  $not . "dirindex";
     open(FLATFILE, ">$place/$dirindex$arch$dist.deb");
     print "Create the powersearch flat directory database\n";
       open(PARTS, "$ppackage[$#ppackage]");         
          while (<PARTS>) {
              @md = split(/ -> /,$_); 
              if (defined($md[1])) { 
               chomp $md[0];
              }
              push(@mi,$md[0]);
         } # while        
       print "    $ppackage[$#ppackage]\n";
       while ($count <= $#mi) {
          print FLATFILE "$mi[$count]\n";
          $count++;
       }     
      $count = 0;
      @mi = ();
      @md = ();
      close(PARTS); 
    close(FLATFILE);

    # compare nstatusindex*.deb to /. from nfileindex*.deb to find out if
    # any of the packages in Packages weren't represented in the Contents
    # file.  This is different than the earlier report which shows packages
    # which weren't in Packages but were in Contents.  This list is kept,
    # and used again in a future --ndb run to make the matches, if they
    # exist.
    if ($commands->{"initndb"} || $commands->{"rebuildndb"}) {
       nsb(\%$commands);
       nzing(\%commands);
       my @fileindex = split(/\s/,$ib{"/."});
       my @statusindex = split(/\s/,$nsb{"/."});
       if ($#fileindex < $#statusindex) {
         my $place = finddb(\%commands);
         $place = "$default_directory$place";
         open(DIFF, ">$place/.packagesdiff$arch$dist.deb") 
             or warn "couldn't create diff file\n";
         my %uniques;
         @uniques{@fileindex} = ();
         foreach (@statusindex) {
           # no sense putting non-US or experimental in here unless this 
           # is what is wanted. Only need to check for group non-us/*
           if (!$commands->{"nue"}) {
              my $name = (split(/_/,$_))[0];
              if (defined $nsb{$name}) {
               next if (split(/\s/,$nsb{$name}))[1] =~ m,non-us,;
              }
              if ($dist eq "experimental") {
                next;
              }
           }
           elsif ($dist eq "experimental") {
            if (!$commands->{"nue"}) {
              my $name = (split(/_/,$_))[0];
              if (defined $nsb{$name}) {
               next if (split(/\s/,$nsb{$name}))[1] =~ m,non-us,;
              }
            }
           }
            print DIFF "$_\n" unless exists $uniques{$_};
         }
        $zing->del("/.");
        $zing->put("/.",$nsb{"/."});
       }
    } # end if

# Will unlink transfer.deb, big.debian, long.debian.
  unlink(<$tmp/DEBIAN*>);
  unlink("$tmp/transfer.deb");
  unlink("$tmp/big.debian");
  unlink("$tmp/long.debian");


  #!!!
   print "    over and out\n";
   print scalar(localtime), "\n";

} # end sub process_md


1;
