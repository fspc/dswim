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


package SWIM::Conf;
use vars qw(@ISA @EXPORT %EXPORT_TAGS);
use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($my_number $tmp $architecture $distribution @user_defined_section
             $default_directory  $default_root_directory $permission $dpkg
             $dpkg_deb $ar $gcc $apt_get $apt_cache $sources @FTP $spl $cat
             $sort $md5sum $zcat $tar $grep $gzip $fastswim $slowswim $longswim
             $mount $umount $mke2fs $copy $pager $base $pwd $parent $library
             $splt $mv $imswim $swim_conf $debug $port $timeout
             $firewall $passive $apt_sources $HISTORY $alt $no_rebuilddb);
%EXPORT_TAGS = (
               Path => [ qw($tmp $parent $base $library $default_directory) ],
               Deb => [ qw($pwd $dpkg_deb $ar $tar $grep $tmp $md5sum $cat $mv) ],
               Qftp => [ qw($default_root_directory $permission @FTP 
                            $default_directory $swim_conf) ],
               Info => [ qw($parent $base $zcat) ]
               );


         
#############################
# DEFAULT PROGRAM VARIABLES #
#############################

# You can change this to how many lines you would like "swim -qf <>" to
# print out, before asking for -t or --total, it will automatically ask
# though, if there is more than one package and you used the option -i.
# Remember -t can be used with --scripts family members to view the
# title of the script file regardless of this setting, and if -t has to be
# used, the titles will be displayed, which makes sense.
$my_number = 23;

# Just like a shell, you can keep a history of whatever length you want.  
$HISTORY = 10;

# Set to 1 if you don't want the swim to automatically rebuild its
# databases everytime there is a change. 
$no_rebuilddb = 0;

# For not-installed:
# This part supplies the default value for --arch.
#
# You can determine the default architecture used when -n is 
# called or a not-installed database is made.  Architectures are always
# being added so check with Debian to find a list.  There is alpha, arm,
# hurd (alternative kernel to linux), i386, m68k, powerpc, sparc.  Just use
# the arch found after the hyphen in the Contents-(arch) file.
$architecture = "i386";

# For not-installed:
# This part supplies the default value for --dists.
#
# The default distribution can be either stable, unstable, frozen, or
# experimental (rare).  These represent the state of development that the
# packages are under.  The unstable distribution can have lot's of changes
# within a very short time period, and frozen may or may not be available.
$distribution = "unstable";


#For not-installed:
#This part supplies the default value for --main, --contrib, --non-free,
#and --non-us.

# Distributions are divided into the sections.  These sections are called
# distributions in the version 2.4.1.0 packaging manual, because they were at
# one time separate distributions, but this has since changed.  You can
# determine which of these sections (main, non-free, contrib or non-US) to
# pull out of the Contents file if you don't want to use --main, --contrib,
# --non-free, and --non-us to selectively pick sections.  Basically, whatever
# you pull out should match the Package(s) file(s) you are targetting, this
# program is friendly if you make a mistake, but it's more effecient to pull
# out just what you want.  If the same package happens to exist in two
# different sections, main and non-us for example (which is really a
# situation that shouldn't exist, yet it does), you will still be able to
# find this package in the non-us group, but its section and locations will be
# the one which main recognizes assuming that you use the order in the example
# below.

# Setting it up:
# Example: You just want to pull out main and contrib every time you run
# --initndb, --rebuildndb, or --ndb.  
# @user_defined_section = qw(main contrib non-US);  
# remember "non-US" not "non-us". 

# untill non-US is fixed the second is better
#@user_defined_section = qw(main contrib non-free non-US); 
@user_defined_section = qw(main contrib non-free);

# Usually, this is 
$alt = "debian";

################
# DF LOCATION  #
################

# A little philosophy:
# swim was developed for maximum versatility, so whether you are just
# interested in researching, and keeping tabs on the newest packages,
# or maintaining a Debian virtual distribution on a non-Debian real
# distribution, or you are a using swim for distribution development, swim
# provides a way.  The default directory (DF - which can also mean
# directory/file) keeps track of Contents and Packages files downloaded
# using --ftp, and gives the files names specific to the distribution and
# architectures they represent.  But, you also have the freedom not to use
# the default directory in this case swim will still do the renaming and
# keeping track of the mtime, but you will have to remember where you put
# the files. On the other hand, if you use apt, you won't even have to use
# the DF directory for Packages files because you can get the ones specific
# to your own systems architecture from apt, but if you want to look at
# other architectures you will need to use the DF directory or one of your
# own choice. 
# Naming Convention: Contents = Contents-dist.gz 
# Packages = Packages-arch-dist-section.gz 
$default_directory = $main::home . "/.swim";


# The default root directory is the key to easy management of packages
# downloaded through --ftp and --file, and provides an easy way to put together
# a personalized distribution.  Future implementations of swim will provide
# a distribution called personal..Packages and Contents files specific to
# this distribution will automatically be made.  This directory can be a
# real ftp site on your computer, or put where ever else you are allowed
# to have directories.  dists/distribution/section/architecture/subject will be
# placed above this directory.  No matter what, debian must be the final
# directory before dists.  Other distributions are placed alongside debian,
# like debian-non-US or personal. 
# Feel free to change the permissions.  This directory is above your default_
# directory.
$default_root_directory = '/pub/debian';

# Because you may be using a real ftp site, this configuration allows you
# to determine what permissions swim will set for directories it creates
# above the default root directory.
$permission = '0755';


###############
# AR or DPKG? #
###############

# NOTE: users set these next two with the $package_tool variable.

# packaging friends dpkg and dpkg-deb come from the essential and
# required dpkg package.  ar from the package binutils can also be used (below).
# This is the archival program used for deb packages, but binutils is just
# a standard non-essential package, and the ar capabilities are built into
# dpkg-deb, and it's better not to assume that the standard packages are
# even established, yet.
$dpkg = ();
$dpkg_deb = ();


# If you don't have the dpkg package on your system then you can use ar
# from the package binutils.  This would be a standard, but not an essential
# package in Debian, but this package is also fairly standard amongst all
# distributions, and can even be found in the free djgpp for M$ Oses.
# Since people who have both dpkg and ar may want to try the ar method,
# rather than creating an automatic check, just assign a value to either
# ($dpkg & $dpkg_deb) or just $ar.
#my $ar = '/usr/bin/ar';  # same for RH
$ar = '/usr/bin/ar';


#######
# APT #
#######

# NOTE: users set apt-get and apt-cache with the $apt variable

# If you have apt you are in luck.
$apt_get = ();
$apt_cache = ();
$sources = '/etc/apt/sources.list';
$apt_sources = '/var/state/apt/lists';

#########
# PAGER #
#########

# less is a nice pager, unless you like more!  There is an option 
# --nopager or -n.   Pager is used for --help and swim called without any
# options.  more comes from the required package util-linux, whereas
# less comes from a standard package called less.  In the future there is
# a possiblity that a large percentage of swim may use an internal pager.
# less, more, or most or...
#$ENV{PAGER} = "/usr/bin/less"; # same RH
$ENV{PAGER} = "less";
$pager = $ENV{PAGER};



#################
# SWIM PROGRAMS #
#################

# This is replaced by the Makefile.
$pre="/usr";

# This is the hash making program fastswim.
$fastswim = "$pre/lib/SWIM/fastswim";

# imswim in an alternative to fastswim for --lowmem
$imswim = "$pre/lib/SWIM/imswim";

#  This is the low memory program slowswim.
$slowswim = "$pre/lib/SWIM/slowswim";

# This is the dir/file making program longswim.
$longswim = "$pre/lib/SWIM/longswim";

############
# TEMP DIR #
############

# If you want to set an alternative directory for the temporary files
# created when the databases are made, change here.  You may want to make
# $tmp a RAM disk.  See package loadlin for initrd documentation and an
# explanation for making such a disk.  There is also
# /usr/src/kernel-source.version/Documentation.  Whether this will speed
# things up is a subject of experimentation.
my $tmp_home = substr($main::home,1,);
$tmp = "/tmp/.gbootroot_$tmp_home";
home_builder($tmp);

##################
# MAIN CONFFILES #
##################

# if configuration files are not kept in /etc change this
# and set up the directories by hand.

$swim_conf = '/etc/swim';


#############
# UTILITIES #
#############


# This probably never will have to be changed.
$pwd = `pwd`;
chomp $pwd;

# If the command split is somewhere else besides /usr/bin change this.
# The required package textutils provides this.
#my $splt = '/usr/bin/split'; # same RH
$splt = 'split';

# cat comes from the essential and required package textutils.
#my $cat = '/bin/cat'; # same RH
$cat = 'cat';

# This command also omes from the required and essential package textutils.
#my $sort = '/usr/bin/sort'; # same RH
$sort = 'sort';

# This program uses md5sum from the dpkg package, it can also use md5sum
# from the RH package.
#my $md5sum = '/usr/bin/md5sum'; # same RH
$md5sum = 'md5sum';

# If you want to view compressed files make sure this is correct.
# The required package gzip provides this.
#my $zcat = '/bin/zcat'; # same RH
$zcat = 'zcat';

# tar comes from the essential and required package tar.
#my $tar = '/bin/tar'; # same RH
$tar = 'tar';

# grep comes from the essential and required package grep.  This seems
# to require a path.
$grep = '/bin/grep'; # same RH

# gzip comes from the essential and required package gzip.
#my $gzip = "/bin/gzip"; # same RH
$gzip = "gzip";

# mount comes from the essential and required package mount.
#my $mount = '/bin/mount'; # same RH
#my $umount = '/bin/umount';  # same RH
$mount = 'mount';
$umount = 'umount';

# If your file system isn't an ext2 filesystem, you may want to change
# this.  mke2fs comes from the essential and required package e2fsprogs.
#my $mke2fs = '/sbin/mke2fs'; # same RH
$mke2fs = 'mke2fs';

# cp and mv from the essential and required package fileutils
#my $copy = '/bin/cp'; # same RH
$copy = 'cp';
$mv = 'mv';

# Your system definitely has gcc if you have ar.  gcc is a standard package
# in debian.
$gcc = 'gcc';


######
# FTP #
#######

# Major mode --ftp and --file automates the download of Contents and Packages
# files. Even if you have apt installed, you may still want to download Packages
# from alternative architectures, and the Contents file for your own architecture
# or other architectures.  If you want virtual and/or -ld capabilities you need
# the Contents file.  You specify a list of ftp or file sites using urls (like
# apt). For your system's architecture specify the type deb, for other
# architectures specify deb(hyphen)architecture (ex: deb-alpha).  Regardless of
# whether or not you specify an architecture, deb implies /dist* found under the
# base directory specified by the ftp url, except in the case of experimental,
# and to a degree non-us. minor mode --ftp, and --file will use the sites in this
# configuration as well, on a fifo (first in first out) basis, so choose the
# order of sites based on which are closest, most current, as well as fast.

# IMPORTANT:  It is a BIG MISTAKE to use the distributions name (slink,po,etc) 
# anywhere in the sources list, or in swim's configuration file..in fact swim
# won't work properly, not to mention the fact that someday your favorite name
# will suddenly disappear. This is because swim thinks in terms of the real
# distribution name (stable,unstable,frozen, experimental).  The problem goes
# like this - slink remains slink, but goes from unstable to frozen to stable. 
# At first, using the distributions alias may seem appropriate, but the
# purpose of swim is to keep tabs on the dists, and not to ignore changes in
# the states, this also makes managing swim's databases much easier and
# intuitive...more about this later. 

# Fun experiments:  Swim uses the naming conventions of apt, but leaves the
# Package files compressed in the DF directory.  So you can always decompress
# the databases and move them to /var/state/apt/lists.  This ofcourse assumes
# that the  appropriate changes to the sources.list reflecting these Packages
# (need to be the same architecture as your system) existed before you 
# update. (author needs to do this experiment :*) 

$ftp1 = "deb ftp://localhost/pub/debian unstable main contrib non-free non-US";
$ftp2 = "deb ftp://localhost/pub/debian unstable main contrib non-free"; 
$ftp3 = "deb ftp://localhost/pub/debian  project/experimental/";
@FTP = ($ftp1,$ftp2,$ftp3); 

# These next variables allow some characteristics of the ftp client
# to be altered.  See Net::FTP for ways of altering some of these
# variables through the environment.

$firewall = 0;
$port = 0;
$timeout =  120;
$debug = 0;
$passive = 0;


########################################
# STUFF THAT NEVER NEEDS TO BE CHANGED #
########################################

# You will never need to change this unless for some weird reason all the
# files under dpkg are somewhere else (including /info*) , see --dbpath as
# an alternative if you decide to access or make the databases somewhere
# else.  I should point out that this program was designed to work with only
# one user .. root .. but now I am changing it --freesource
$base = '/var/lib/dpkg';

# --dbpath takes care of this so don't touch.
$parent = '/';
$library = '/var/lib/dpkg';


#############################
# LOAD CUSTOM CONFIGURATION #
#############################


# Here we load in the customized configuration which override the defaults
# Might as well use do, let the world learn Perl ... compare this to apt's 
# configuation file with scopes.  Swim's sources.list file (/etc/swim/swimz.list), 
# will be grabbed at SWIM::Apt and SWIM::Qftp if it exists.

do "$swim_conf/swimrc";
do "$ENV{HOME}/.swim/swimrc";
if ((defined $dpkg && !defined $dpkg_deb) || 
   (!defined $dpkg && defined $dpkg_deb)) {
  print "swim: need to give both \$dpkg and \$dpkg_deb a value if you want dpkg\n";
  exit;
}
if (defined $package_tool) {
 if ($package_tool =~ /ar/) {
   $ar = $ar;
 }
 else {
   $dpkg = 'dpkg';
   $dpkg_deb = 'dpkg-deb';
   undef $ar;
 }
}
if (defined $apt) {
  $apt_get = 'apt-get';
  $apt_cache = 'apt-cache';
}


###############################
# MAKE ANY NEEDED DIRECTORIES #
###############################

# make sure all the appropriate directories are made
if (!-d $default_directory) {  
 if (-e $default_directory) {
   print "swim: can not create default directory because a file exists\n";
   exit;
 }
    my @DRD = split(m,/,,$default_directory);
    my $placement = "/";
    for (1 .. $#DRD) {  
     $_ == 1 ? ($placement = "/$DRD[$_]") 
             : ($placement = $placement . "/" . $DRD[$_]);
     -d $placement or mkdir("$placement",0755);
    }
}

if (!-d "$default_directory$default_root_directory") {
    my @DRD = split(m,/,,$default_root_directory);
    print "swim: debian must be the final directory before dists\n"
    if $DRD[$#DRD] ne "debian";
    exit if $DRD[$#DRD] ne "debian";
    my $placement = "/";
    for (1 .. $#DRD) {  
     $_ == 1 ? ($placement = "/$DRD[$_]") 
             : ($placement = $placement . "/" . $DRD[$_]);
     unless (-d "$default_directory$placement") { 
       mkdir("$default_directory$placement",0755) 
       or die "swim: could not create root default directory\n";
     }
    }
}

# Makefile will make sure these directories exist, unless for some strange
# reason you have to change them.

if (!-d $library) {
    mkdir($library,0755) or die "Couldn't create default directory\n";
}

if (!-d $base) {
    mkdir($base,0755) or die "Couldn't create default directory\n";
}

if (!-d $swim_conf) {
    mkdir($swim_conf,0666) or die "Couldn't create configuration file directory,
                                   please make the directories which are needed.\n";
}


# Pulled this from *_pkg from the gbootroot project.
sub home_builder {

    my ($home_builder) = @_; 

    if (!-d $home_builder) {
	if (-e $home_builder) {
	    print "ERROR: A file exists where $home_builder should be.\n";
	}	 
	else {
	    my @directory_parts = split(m,/,,$home_builder);
	    my $placement = "/";
	    for (1 .. $#directory_parts) {
		$_ == 1 ? ($placement = "/$directory_parts[$_]")
		    : ($placement = $placement . "/" . $directory_parts[$_]);
		-d $placement or mkdir $placement;
	    }
	}
    }

} # end home_builder


1;

__END__

=head1 NAME

swimrc - swim configuration file

=head1 DESCRIPTION

B<swimrc> is the configuartion file for swim allowing many default values
to be set so that they do not have to be mentioned on the command line. 
Swimrc interacts directly with Perl allowing a wide variety of variables
found in B<SWIW::Conf> to be altered.

=cut

=head1 USAGE

Values for variable can be altered for B<swim> by assigning different
values enclosed in quotes or quoted whitespace (qw()), and ended with a
semi-colon.

 $variable = "value";
 $variable = "qw(value1 value2 ..)";

=head1 VARIABLES

This is a list of variables with explanations.  The default values for
B<swim> are shown.

=head2 OUTPUT VARIABLE 

$my_number can be changed to how many lines you would like "swim -qf <>" 
to print out, before the program asks for C<-t> or C<--total>.  Exception: 
If C<-i> is used in the query and there is more than one package then the
total will be presented. 

Hint:  C<-t> can be used with all the various C<--scripts> family members
to view the title of the script file regardless of this variable setting,
and if C<-t> has to be used, the titles will be displayed, which makes
sense. 

B<$my_number = 23;>

=head2 HISTORY

This is a shell-like history kept in relation to searches and the most
recent edit when C<--stdin> is used. 

B<$HISTORY = 10;>

=head2 AR or DPKG?

Debian packages are ar archives.  If you are using a Debian Distribution
assign "dpkg" to $package_tool, otherwise assign "ar" to $package_tool.

B<$package_tool = "/usr/bin/ar";>

=head2 APT

B<Swim> does not assign a value for apt.  To use C<--apt> and C<-xyz>
assign $apt the value "yes". 

Example: B<$apt = "yes";>

=head2 PAGER

less is a nice pager, unless you like more!  Pager is used for C<--help>
and B<swim> called without any options. There is an option C<--nopager> or
C<-n>.  more comes from the required package util-linux, whereas less
comes from a standard package called less.  Values: "less", "more", or
"most" or... 

B<$ENV{PAGER} = "less";>

=head2 NOT-INSTALLED VARIABLES 

Assign values for $architecture and/or $distribution to avoid having to
use C<--arch> and C<--dists> everytime the not-installed databases are
accessed with C<-n> or made or altered.

Architectures are always being added so check with Debian to find a list. 
There is I<alpha, arm, hurd-i386 (alternative kernel to linux), i386,
m68k, powerpc, sparc>.  Just use the arch found after the hyphen in the
Contents-(arch) file.

B<$architecture = "i386";>

The distribution can be either I<stable, unstable, frozen, or experimental
(rare)>.  These represent the state of development that the packages are
under.  The unstable distribution can have lot's of changes within a very
short time period, and frozen may or may not be available.

B<$distribution = "unstable";>

Distributions are divided into sections.  These sections were called
distributions in the version 2.4.1.0 packaging manual, because they were
at one time separate distributions, but this has since changed.  

You can determine which of the sections I<main, non-free, contrib or
non-US> to pull out of the Contents file if you don't want to use
C<--main>, C<--contrib>, C<--non-free>, and C<--non-us> to selectively
pick the sections. 

For efficiency, you should choose the sections which you will be pulling
out of the Packages file(s) being targetted.  

Rule: Use "non-US" not "non-us".

B<@user_defined_section = qw(main contrib non-free non-US);>

=head2 DF LOCATION

A little philosophy:  B<swim> was developed for maximum versatility, so
whether you are just interested in researching, and keeping tabs on the
newest packages, or maintaining a Debian virtual distribution on a
non-Debian distribution, or you are a using B<swim> for distribution
development, B<swim> provides a way.  

The next two variables determine the location of the DF (default
directory/file system)

The default directory keeps track of Contents and/or Packages databases
retrieved with --ftp.  The Contents and Packages databases and Release
file are give names specific to the distribution and architectures they
represent using the naming convention found in apt's sources directory. 
You also have the freedom not to use the default directory, in which case
swim will still do the renaming and keeping track of the mtime, but you
will have to remember where you put the files.

B<$default_directory = '/root/.swim';>

The default root directory (DRD) is the key to easy management of binary
packages, source, dsc, and diff files received from --ftp, and provides an
easy way to put together a personalized distribution. This directory can
be a real ftp site on your computer, or put wherever else you are
allowed to have directories.  The DRD is always placed below the value
assigned to $default_directory.  According to the previous assignment to 
$default_directory, if the DRD is "/pub/a/debian" then the full path
would be "/root/.swim/pub/a/debian". 

Example: When a package is downloaded it will be placed in
dists/distribution/section/architecture/subject below the DRD. 

Rule: debian must be the final directory before dists, this is because
other distributions are placed alongside debian, like debian-non-US or
personal (specialized distribution).

B<$default_root_directory = '/pub/debian';>

Because you may be using a real ftp site, this variable allows you to
determine what permissions B<swim> will assign for directories it creates
below the DRD. 

B<$permission = '0755';>

=head2 TEMPORARY DIRECTORY

If you want to set an alternative directory for the temporary files
created when the databases are made, change here.  You may want to make
$tmp a RAM disk.  See package loadlin for initrd documentation and an
explanation for making such a disk.  There is also documentation in
/usr/src/kernel-source.version/Documentation.  Whether this will speed
things up is a subject of experimentation. 

B<$tmp = "/tmp";>

=head2 FTP

You can alter the Firewall, Port, Timeout, Debug and Passive
characteristics of the ftp client as defined in Net::FTP(3pm) by providing
arguments to these variables. All variables but $timeout are set to untrue
by default.  

 $firewall = 0; (FTP firewall machine name)
 $port = 0;  (defaults to 23)
 $timeout = 120;  (120 seconds)
 $debug = 0;  (1 will turn on STDERR)
 $passive = 0; (1 will enable)

=head1 OTHER VARIABLES

see SWIM::Conf

=head1 FILES

 /etc/swim/swimrc
 ~/.swim/swimrc

=head1 SEE ALSO

swim(8), Net::FTP(3pm)

=head1 BUGS

Send directly to mttrader@access.mountain.net.

=head1 AUTHOR

Jonathan D. Rosenbaum <mttrader@access.mountain.net> 

=head1 COPYRIGHT


Copyright (c) 1999 Jonathan Rosenbaum. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the GPL. 

=cut
