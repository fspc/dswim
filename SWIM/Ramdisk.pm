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


package SWIM::Ramdisk;  
use strict;
use SWIM::Conf;
use SWIM::Library;
use vars qw(@ISA @EXPORT);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ramdisk);


=pod

make access a lot faster for contentsindex.deb.gz, alternatively 
searchindex.deb & file/dirindex. Ramdisks don't work well for 
everything like the creation of a database.  The goal is to
automatically determine the size of the disk based on the files 
put into it (which will all be compressed)  This also has a residual 
effect, so when the ramdisk is umounted stuff still stays in
the memory. 

=cut

sub ramdisk {


  my ($commands) = @_;

  # lot's of thing can be put into the ramdisk,  ncontentsindex being the
  # most important, but flat search files, too.  --ramdiskon -n would be
  # the most important application.  
  my $size = 0;  
  my (@storage,@files);
  my $count = 0;
  my %commands = %$commands; 
  my $where = finddb(\%commands);
  my ($arch,$dist) = which_archdist(\%commands);
  my $not = "n" if defined $arch;
     $not = "" if !$commands->{"n"};
     $arch = "" if !$commands->{"n"};
     $dist = "" if !$commands->{"n"};
  my $contentsindex  = "contentsindex";
  my $searchindex = "searchindex";
  my $dirindex = "dirindex";

 if ($commands->{"ramdiskon"}) {

   my  $rambo =  "$cat /proc/mounts|";
   open(RAM, "$rambo"); 
    while (<RAM>) {
      if (/ram/) {
        my($device,$mount) = split(/\s/,$_,2);
          if ($mount =~ /dramdisk/) {
            print "swim: use --ramdiskoff\n";
            exit;
          }
        $storage[$count] = $device;
        $count++;
      }
    }
    close(RAM);

  if (-e "$where/$not$contentsindex$arch$dist.deb.gz" &&
      -B "$where/$not$contentsindex$arch$dist.deb.gz") { 
         $size = (stat("$where/$not$contentsindex$arch$dist.deb.gz"))[7];
          push(@files,"$where/$not$contentsindex$arch$dist.deb.gz");
  }
  
  if ($commands->{"searchfile"}) {
    # stat caused some weirdisms based on the boolean logic
    #if (-e "$where/$not$searchindex$arch$dist.deb" &&
    #    -e "$where/$not$dirindex$arch$dist.deb") {
        # compress the monsters 
        if (!-e "$where/$not$dirindex$arch$dist.deb.gz") {
          print "swim: please wait while dirindex.deb is compressed\n";
        if (-e "$where/$not$dirindex$arch$dist.deb") {
        system "$gzip -c9 $where/$not$dirindex$arch$dist.deb > $where/$not$dirindex$arch$dist.deb.gz";
        }
        }
        if (!-e "$where/$not$searchindex$arch$dist.deb.gz") {        
          print "swim: please wait while searchindex.deb is compressed\n";
        if (-e "$where/$not$searchindex$arch$dist.deb") {
        system "$gzip -c9 $where/$not$searchindex$arch$dist.deb > $where/$not$searchindex$arch$dist.deb.gz";
        }
        }
        push(@files,"$where/$not$dirindex$arch$dist.deb.gz");
        push(@files,"$where/$not$searchindex$arch$dist.deb.gz");
        my $size1 = (stat("$where/$not$searchindex$arch$dist.deb.gz"))[7];
        my $size2 = (stat("$where/$not$dirindex$arch$dist.deb.gz"))[7];
        if (defined $size) {
          $size = $size + $size1 + $size2;
        }
        else {
          $size = $size1 + $size2;
       }
    #}
  }
      
 # it will be assumed that ext2 is used, and hopefully there isn't a mount
 # of the exact same name..hence dramdisk should be unusual
  my $number;
  if (defined @storage) {
    @storage = sort {$a cmp $b} @storage;
    $storage[$#storage] =~ s/\D//g;
    $number = $storage[$#storage] + 1;
  }
  else {
    $number = 0;
  }

    # the size will be the sizes added together/1024 + (.15 of the total)
    if (-e "$where/dramdisk") {
      if (!-d "$where/dramdisk") {
        print "swim: --ramdiskon requires dir dramdisk, but a file named dramdisk already exists\n";
        exit;
      }
    }
    elsif (!-d "$where/dramdisk") {
       mkdir("$where/dramdisk",0666);
    }

    my $increase = $size * 0.15;
    $size = $increase + $size;
    $size = $size/1024;
    $size = sprintf("%.f",$size);
    if ($size > 0) {
     system "$mke2fs", "-m0", "/dev/ram$number", "$size";
     system "$mount", "-t", "ext2", "/dev/ram$number", "$where/dramdisk";
      foreach (@files) {
       system "$copy", "$_", "$where/dramdisk";
      } 
    }
  } # if on
  else {

   my  $rambo =  "$cat /proc/mounts|";
   open(RAM, "$rambo"); 
    while (<RAM>) {
      if (/ram/) {
        my($device,$mount) = split(/\s/,$_,2);
          if ($mount =~ /dramdisk/) {
          system "$umount", "$device";
          exit;
          }
        $storage[$count] = $device;
        $count++;
      }
    }
    close(RAM);


 } # if off
 
 exit;

} # end sub ramdisk





1;
