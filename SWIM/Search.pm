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


package SWIM::Search;
use vars qw(@ISA @EXPORT);
use strict;
use SWIM::Global;
use SWIM::Conf;
use SWIM::DB_Library qw(:Search);
use SWIM::Library;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(search);


# search() and searchdf() = mm --search, --ps --refinesearch --research

=pod

This searches for keyword(s) amongst the descriptions, and then
shows the packages which match, a little more sophisticated than
swim -qait | grep <keyword>, besides you can use perl regexping
notation when you do your search.  By default the description is
automatically presented, but a list of package names which match is kept
which can then be queried using -S in the normal fashion, until the
next search.

=cut

sub search {

  my ($search_mem,$commands,$num,$argv) = @_;

  $argument = "/.";
  my %commands = %$commands;

  my %morethanone;
  my $keyword = $commands->{"search"};
   if ($commands->{"search"}) {
     $keyword = $commands->{"search"};
   }
   elsif ($commands->{"research"}) {
     $keyword = $commands->{"research"};
   }
   elsif ($commands->{"refinesearch"}) {
     $keyword = $commands->{"refinesearch"};
   }
   elsif ($commands->{"powersearch"} || $commands->{"ps"}) {
     if ($commands->{"powersearch"}) {
       $keyword = $commands->{"powersearch"};
     }
     if ($commands->{"ps"}) {
       $keyword = $commands->{"ps"};
     }
   }  
  my $count = 0;
  
  my ($search_file, $search_dir);
  if (!$commands->{"n"}) {
     ib(\%commands);
     dbi(\%commands);
     if ($commands->{"ps"} || $commands->{"powersearch"}) { 
       ($search_file,$search_dir) =  searchdf(\%commands);
       if (-B $search_file && -B $search_dir) {
          $search_file = "$gzip -dc $search_file|";
          $search_dir = "$gzip -dc $search_dir|";
       }
     } 
  }
  #####
  # N #
  #####
  else {
    my $return = nib(\%commands);
     if (!$return) {
        untie %ib;
        nsb(\%commands);
       $ib{"/."} = $nsb{"/."};
     }
     ndb(\%commands);
     if ($commands->{"ps"} || $commands->{"powersearch"}) { 
       ($search_file,$search_dir) =  searchdf(\%commands);
       if (!-e $search_file || !-e $search_dir) {
         delete $commands{"ps"} if defined $commands->{"ps"};
         delete $commands{"powersearch"} if defined $commands->{"powersearch"};
       }
       if (-B $search_file && -B $search_dir) {
          $search_file = "$gzip -dc $search_file|";
          $search_dir = "$gzip -dc $search_dir|";
       }
     }
  } 

 ##########
 #        #
 # SEARCH #
 #        #
 ########## 
 # Here starts --search & optionally -g
 my ($line,@HISTORY);
 if ($commands->{"search"}) {
   my @stuff;
   if ($commands->{"g"}) {
   # check for some errors
   if ($commands->{"a"} || $commands->{"f"} || $commands->{"dir"}) {
     print "swim: one type of query/verify may be performed at a time\n";
     exit;
   }
   # extract the packages related to the group.
   if (!$commands->{"n"}) {
      gb(\%commands);
   }
   else {
      ngb(\%commands)
   }
      if ($#ARGV != -1) {
         foreach (@ARGV) {
           $argument = $_;
           if (defined $gb{$argument}) {
             @stuff = split(/\s/, $gb{$argument});
           }
           else {
             print "group $argument does not contain any packages\n";
           }
          }
       }
       else {
         print "swim: no arguments given for query\n";
       }
  untie %gb;
  } # if ($commands->{"g"})

  # not yet for -g
  if ($commands->{"search"} && !$commands->{"g"}) {
   if ($argument) {
    if ($ib{"$argument"}){
          foreach (split(/\s/, $ib{"$argument"})) {
           if ($keyword =~ /\/i$/) {
            $keyword =~ m,(.*)\/i$,;
            if (defined $db{$_}) {
             if ($db{$_} =~ /$1/i) {
               print "$db{$_}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;              
             } 
            }
           } 
           elsif ($keyword =~ /\/m$/) {
            $keyword =~ m,(.*)\/m$,;
            if (defined $db{$_}) {
             if ($db{$_} =~ /$1/m ) {
              print "$db{$_}\n" if !$commands->{"no"};
              push(@PACKAGES,$_);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
              $count++;              
             } 
            }
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $keyword =~ m,(.*)\/.[im]$,;
            if (defined $db{$_}) {
             if ($db{$_} =~ /$1/im ) {
              print "$db{$_}\n" if !$commands->{"no"};
              push(@PACKAGES,$_);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
              $count++;              
             } 
            }
           }
           else {
            if (defined $db{$_}) {
             if ($db{$_} =~ /$keyword/) {
               print "$db{$_}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;
             }
            } 
           }
          }
    print STDERR "swim: found $count package(s)\n"; 

    }
    if (!$line) {
      $line = "";
    }
    else {
      $line = "$line\n";
    }
    history($line,$search_mem);
   }
  }

  # ok -g
  elsif ($commands->{"search"} && $commands->{"g"}) {
   if (@stuff) {
    #unlink("$search_mem");
    foreach (@stuff) {
       $argument = $_;
       version(\%commands);
       # if we just did a group search we don't want to append it to
       # the .search.deb file.       
           if ($keyword =~ /\/i$/) {
            $keyword =~ m,(.*)\/i$,;
            if (defined $db{$_}) {
             if ($db{$argument} =~ /$1/i) {
               print "$db{$argument}\n" if !$commands->{"no"};
               push(@PACKAGES,$argument);
               if (!defined $line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;              
             } 
            }
           } 
           elsif ($keyword =~ /\/m$/) {
            $keyword =~ m,(.*)\/m$,;
            if (defined $db{$_}) {
             if ($db{$argument} =~ /$1/m ) {
              print "$db{$argument}\n" if !$commands->{"no"};
              push(@PACKAGES,$argument);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
              $count++;              
             } 
            }
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $keyword =~ m,(.*)\/.[im]$,;
            if (defined $db{$_}) {
             if ($db{$argument} =~ /$1/im ) {
              print "$db{$argument}\n" if !$commands->{"no"};
              push(@PACKAGES,$argument);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
              $count++;              
             } 
            }
           }
           else {
            if (defined $db{$_}) {
             if ($db{$argument} =~ /$keyword/) {
               print "$db{$argument}\n" if !$commands->{"no"};
               push(@PACKAGES,$argument);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;
             }
            }
           }
    }
    print STDERR "swim: found $count package(s)\n"; 
    if (!$line) {
      $line = "";
    }
    else {
      $line = "$line\n";
    }
    history($line,$search_mem);
   }
  }
 exit if !($commands->{"stdin"} || $commands->{"x"} || $commands->{"y"} ||
           $commands->{"z"} || $commands->{"ftp"});
 }

 #############################
 #                           #
 # RESEARCH  || REFINESEARCH #
 #                           #
 #############################  
 # research time or refining time
 if ($commands->{"research"} || $commands{"refinesearch"}) {
    if ($commands->{"g"}) {
      print "swim: use -g only with a new search\n";
      exit;
    }
          foreach (@$argv) {
           if ($keyword =~ /\/i$/) {
            $keyword =~ m,(.*)\/i$,;
            if (defined $db{$_}) {
             if ($db{$db{$_}} =~ /$1/i) {
               print "$db{$db{$_}}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;              
             } 
            }
           } 
           elsif ($keyword =~ /\/m$/) {
            $keyword =~ m,(.*)\/m$,;
            if (defined $db{$_}) {
             if ($db{$db{$_}} =~ /$1/m ) {
              print "$db{$db{$_}}\n" if !$commands->{"no"};
              push(@PACKAGES,$_);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
              $count++;              
             }  
            }
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $keyword =~ m,(.*)\/.[im]$,;
            if (defined $db{$_}) {
             if ($db{$db{$_}} =~ /$1/im ) {
              print "$db{$db{$_}}\n" if !$commands->{"no"};
              push(@PACKAGES,$_);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
              $count++;              
             } 
            }
           }
           else {
            if (defined $db{$_}) {
             if ($db{$db{$_}} =~ /$keyword/) {
               print "$db{$db{$_}}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
              if (!$line) {
               $line =  (split(/_/,$_))[0];
              }
              else {
               $line = $line . " " . (split(/_/,$_))[0];
              }
               $count++;
             }
            }
           }
          }
    print STDERR "swim: found $count package(s)\n"; 
    if (!$line) {
      $line = "";
    }
    else {
      $line = "$line\n";
    }
    # refine the search
    if ($commands->{"refinesearch"}) {
      open(HISTORY, "$search_mem") || exit;
      my @HISTORY = reverse <HISTORY>;
      close(HISTORY);
      $HISTORY[$num - 1] = $line;
      open(HISTORY, ">$search_mem") || exit;
      print HISTORY reverse @HISTORY;
      close(HISTORY);
    }  
    exit if !($commands->{"stdin"} || $commands->{"x"} ||
              $commands->{"y"} || $commands->{"z"} || $commands->{"ftp"});
 }


 ################
 #              #
 # POWERSEARCH  #
 #              #
 ################  
 # powersearch with no -g option since this searchs all files.
 if (($commands->{"powersearch"} || $commands->{"ps"}) && !$commands->{"g"}) {
          open(FLATFILE, "$search_file");            
          while (<FLATFILE>) {
            chomp $_;
           if ($keyword =~ /\/i$/) {
            $keyword =~ m,(.*)\/i$,;
            if ($_ =~ /$1/i) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  print  "$db{$ib{$_}}\n" if !$commands->{"no"};
                  push(@PACKAGES,$ib{$_});
                  if (!$line) {
                   $line =  (split(/_/,$ib{$_}))[0];
                  }
                  else {
                   $line = $line . " " . (split(/_/,$ib{$_}))[0];
                  }
               $count++;
               }
             }
            } 
           } 
           elsif ($keyword =~ /\/m$/) {
            $keyword =~ m,(.*)\/m$,;
            if ($_ =~ /$1/m ) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  print  "$db{$ib{$_}}\n" if !$commands->{"no"};
                  push(@PACKAGES,$ib{$_});
                  if (!$line) {
                   $line =  (split(/_/,$ib{$_}))[0];
                  }
                  else {
                   $line = $line . " " . (split(/_/,$ib{$_}))[0];
                  }
               $count++;
               }
             }
            } 
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $keyword =~ m,(.*)\/.[im]$,;
            if ($_ =~ /$1/im ) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  print  "$db{$ib{$_}}\n" if !$commands->{"no"};
                  push(@PACKAGES,$ib{$_});
                  if (!$line) {
                   $line =  (split(/_/,$ib{$_}))[0];
                  }
                  else {
                   $line = $line . " " . (split(/_/,$ib{$_}))[0];
                  }
               $count++;
               }
             }
            } 
           }
           else {
            if ($_ =~ /$keyword/) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  # ofcourse this won't work if a dir filters through.
                  # hummm.
                  #print "HUMM  DIR $_ ", $ib{$_}, "\n"; 
                  print  "$db{$ib{$_}}\n" if !$commands->{"no"};
                  push(@PACKAGES,$ib{$_});
                  if (!$line) {
                   $line =  (split(/_/,$ib{$_}))[0];
                  }
                  else {
                   $line = $line . " " . (split(/_/,$ib{$_}))[0];
                  }
               $count++;
               }
             }
            }
           }
          } # while (<FLATFILE>)  
    close(FLATFILE);

   #######
   # DIR #
   #######
   # Somebody wants to do a rare --dir search, but this is done by default
   # for the n* because often enough more than one package shares one
   # file.
   if ($commands->{"dir"} || $commands{"n"}) {
          open(FLATFILE, "$search_dir");
          while (<FLATFILE>) {
            chomp $_;
           if ($keyword =~ /\/i$/) {
            $keyword =~ m,(.*)\/i$,;
            if ($_ =~ /$1/i) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  my @dir = split(/\s/,$ib{$_});
                  foreach (@dir) {
                   $morethanone{$_}++;
                   if (defined $morethanone{$_}) {
                    if ($morethanone{$_} == 1) {
                       print "$db{$_}\n" if !$commands->{"no"};
                       push(@PACKAGES,$_);
                       if (!$line) {
                        $line =  (split(/_/,$_))[0];
                       }
                       else {
                        $line = $line . " " . (split(/_/,$_))[0];
                       }
                       $count++;
                    }
                   } 
                  }
               }
             }
            } 
           } 
           elsif ($keyword =~ /\/m$/) {
            $keyword =~ m,(.*)\/m$,;
            if ($_ =~ /$1/m ) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  my @dir = split(/\s/,$ib{$_});
                  foreach (@dir) {
                   $morethanone{$_}++;
                   if (defined $morethanone{$_}) {
                    if ($morethanone{$_} == 1) {
                       print "$db{$_}\n" if !$commands->{"no"};
                       push(@PACKAGES,$_);
                       if (!$line) {
                        $line =  (split(/_/,$_))[0];
                       }
                       else {
                        $line = $line . " " . (split(/_/,$_))[0];
                       }
                       $count++;
                    }
                   } 
                  }
               }
             }
            } 
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $keyword =~ m,(.*)\/.[im]$,;
            if ($_ =~ /$1/im ) {
             if (defined $ib{$_}) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  my @dir = split(/\s/,$ib{$_});
                  foreach (@dir) {
                   $morethanone{$_}++;
                   if (defined $morethanone{$_}) {
                    if ($morethanone{$_} == 1) {
                       print "$db{$_}\n" if !$commands->{"no"};
                       push(@PACKAGES,$_);
                       if (!$line) {
                        $line =  (split(/_/,$_))[0];
                       }
                       else {
                        $line = $line . " " . (split(/_/,$_))[0];
                       }
                       $count++;
                    }
                   } 
                  }
               }
             }
            } 
           }
           else {
            if ($_ =~ /$keyword/) {
             if (defined $ib{$_}) {
                  #my @dir = split(/\s/,$ib{$_});
                  #foreach (@dir) {
                $morethanone{$ib{$_}}++;
               if ($morethanone{$ib{$_}} == 1) { 
                  my @dir = split(/\s/,$ib{$_});
                  foreach (@dir) {
                   $morethanone{$_}++;
                   if (defined $morethanone{$_}) {
                    if ($morethanone{$_} == 1) {
                       print "$db{$_}\n" if !$commands->{"no"};
                       push(@PACKAGES,$_);
                       if (!$line) {
                        $line =  (split(/_/,$_))[0];
                       }
                       else {
                        $line = $line . " " . (split(/_/,$_))[0];
                       }
                       $count++;
                    }
                   } 
                  }
               }
             }
            }
           }
          } # while (<FLATFILE>)  
    close(FLATFILE);
    }

   #################
   # NORMAL SEARCH #
   #################
   # now we can do a normal search for the powersearch
   if ($argument) {
    if ($ib{"$argument"}){
          foreach (split(/\s/, $ib{$argument})) {
           if ($keyword =~ /\/i$/) {
            $morethanone{$_}++;
            if ($morethanone{$_} == 1) { 
             $keyword =~ m,(.*)\/i$,;
             if (defined $db{$_}) {
              if ($db{$_} =~ /$1/i) {
                print "$db{$_}\n" if !$commands->{"no"};
                push(@PACKAGES,$_);
                if (!$line) {
                 $line =  (split(/_/,$_))[0];
                }
                else {
                 $line = $line . " " . (split(/_/,$_))[0];
                }
                $count++;              
              } 
             }
            }
           } 
           elsif ($keyword =~ /\/m$/) {
            $morethanone{$_}++;
            if ($morethanone{$_} == 1) { 
             $keyword =~ m,(.*)\/m$,;
             if (defined $db{$_}) {
              if ($db{$_} =~ /$1/m ) {
               print "$db{$_}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;              
              } 
             }
            }
           }
           elsif ($keyword =~ /\/.[im]$/) {
            $morethanone{$_}++;
            if ($morethanone{$_} == 1) { 
             $keyword =~ m,(.*)\/.[im]$,;
             if (defined $db{$_}) {
              if ($db{$_} =~ /$1/im ) {
               print "$db{$_}\n" if !$commands->{"no"};
               push(@PACKAGES,$_);
               if (!$line) {
                $line =  (split(/_/,$_))[0];
               }
               else {
                $line = $line . " " . (split(/_/,$_))[0];
               }
               $count++;              
              } 
             }
            }
           }
           else {
             $morethanone{$_}++;
             if ($morethanone{$_} == 1) { 
              if (defined $db{$_}) {
               if ($db{$_} =~ /$keyword/) {
                 print "$db{$_}\n" if !$commands->{"no"};
                 push(@PACKAGES,$_);
                 if (!$line) {
                  $line =  (split(/_/,$_))[0];
                 }
                 else {
                  $line = $line . " " . (split(/_/,$_))[0];
                 }
               $count++;              
               }
              }
             }
           }
          }
    print STDERR "swim: found $count package(s)\n"; 
    if (!$line) {
      $line = "";
    }
    else {
      $line = "$line\n";
    }
    history($line,$search_mem);
    #exit if !($commands->{"stdin"} || $commands->{"x"} ||
    #          $commands->{"y"} || $commands->{"z"} || $commands->{"ftp"});
    }
  }
 }

  untie %ib;
  untie %db;


} # end sub search

# for finding the search flatfiles
sub searchdf {

 my ($commands) = @_;

 my($sfile,$sdir);
 if (!$commands->{"n"}) {
  my ($ramdisk) = ram_on();
  if ($ramdisk eq 1) {
   if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $sfile = "$main::home$parent$library/searchindex.deb";
     $sdir = "$main::home$parent$library/dirindex.deb";
     return ($sfile,$sdir);
   }
   elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     $sfile = "$main::home$parent$base/searchindex.deb";
     $sdir = "$main::home$parent$base/dirindex.deb";
     return ($sfile,$sdir);
   }
  }
  elsif ($ramdisk eq "yes") {
   if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $sfile = "$main::home$parent$library/dramdisk/searchindex.deb.gz";
     $sdir = "$main::home$parent$library/dramdisk/dirindex.deb.gz";
     if (!-e $sdir && !-e $sfile) {
       print "swim: found wrong database(s), use --ramdiskoff\n";
       exit;
     }
     return ($sfile,$sdir);
   }
   elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     $sfile = "$main::home$parent$base/dramdisk/searchindex.deb.gz";
     $sdir = "$main::home$parent$base/dramdisk/dirindex.deb.gz";
     if (!-e $sdir && !-e $sfile) {
       print "swim: found wrong database(s), use --ramdiskoff\n";
       exit;
     }
     return ($sfile,$sdir);
   }
  }
 }
 else {
  my ($ramdisk) = ram_on();
  my($arch,$dist) = which_archdist(\%commands);
  if ($ramdisk eq 1) {
   if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $sfile = "$main::home$parent$library/nsearchindex$arch$dist.deb";
     $sdir = "$main::home$parent$library/ndirindex$arch$dist.deb";
     return ($sfile,$sdir);
   }
   elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     $sfile = "$main::home$parent$base/nsearchindex$arch$dist.deb";
     $sdir = "$main::home$parent$base/ndirindex$arch$dist.deb";
     return ($sfile,$sdir);
   }
  }
  elsif ($ramdisk eq "yes") {
   if (($commands->{"dbpath"} && $commands->{"root"}) ||
      ($commands->{"dbpath"} && !$commands->{"root"}) ||
      (!$commands->{"dbpath"} && !$commands->{"root"})) {
     $sfile = "$main::home$parent$library/dramdisk/nsearchindex$arch$dist.deb.gz";
     $sdir = "$main::home$parent$library/dramdisk/ndirindex$arch$dist.deb.gz";
     if (!-e $sdir && !-e $sfile) {
      print "swim: found wrong database(s), use --ramdiskoff\n";
       exit;
     }
     return ($sfile,$sdir);
   }
   elsif  (!$commands->{"dbpath"} && $commands->{"root"}) {
     $sfile = "$main::home$parent$base/dramdisk/nsearchindex$arch$dist.deb.gz";
     $sdir = "$main::home$parent$base/dramdisk/ndirindex$arch$dist.deb.gz";
     if (!-e $sdir && !-e $sfile) {
       print "swim: found wrong database(s), use --ramdiskoff\n";
       exit;
     }
     return ($sfile,$sdir);
   }
  }
 }

} # end sub searchdf

# print the search out to the right spot on the HISTORY
# this is just shift and push
sub history {

  my($line,$file) = @_;
  my @HISTORY;

  if (-e "$file") {
   open(HISTORY,"$file");
   @HISTORY = <HISTORY>;
   close(HISTORY);
   if ($#HISTORY < $HISTORY - 1) {
     push(@HISTORY,$line);
   }  
   else {
    shift(@HISTORY);
    push(@HISTORY,$line);
   }
  }
  else {
   @HISTORY = $line;
  }

  open(HISTORY,">$file") or exit;
    print HISTORY @HISTORY;
  close(HISTORY);

} # end sub history


1;
