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


package SWIM::Deps;
use strict;
use SWIM::Global qw(:Info);   
use SWIM::DB_Library qw(:Xyz);
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(character s_character which_character the_character);

# the -T and siblings

# process the database for replaces
sub replaces {
  my ($commands) = @_; 
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "REP";
    if (defined $db{$conf}) {
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub replaces

# process the database for provides
sub provides {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "PRO";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub provides

# process the database for depends
sub depends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "DEP";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub depends

# process the database for replaces
sub pre_depends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "PRE";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub pre_depends

# process the database for replaces
sub recommends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "REC";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub recommends

# process the database for replaces
sub suggests {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "SUG";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub suggests

sub enhances {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "ENH";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub enhances


# process the database for replaces
sub conflicts {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "CON";
    if (defined $db{$conf}) {      
     return $db{$conf};
    }
    else { return ""; }
  }
 untie %db;
} # end sub conflicts

#These subroutines are for cases where only packages related to the
# characteristics are printed out.
# process the database for replaces
sub s_replaces {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "REP";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_replaces

# process the database for provides
sub s_provides {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "PRO";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_provides

# process the database for depends
sub s_depends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "DEP";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_depends

# process the database for replaces
sub s_pre_depends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "PRE";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_pre_depends

# process the database for replaces
sub s_recommends {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "REC";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_recommends

# process the database for replaces
sub s_suggests {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "SUG";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_suggests

sub s_enhances {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "ENH";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_enhances

# process the database for replaces
sub s_conflicts {
  my ($commands) = @_;
  my %commands = %$commands;  
  !$commands->{"n"} ? dbi(\%commands) : ndb(\%commands);
  if (defined $argument) {
    my $conf = $argument . "CON";
    if (defined $db{$conf}) {      
     return "$argument\n$db{$conf}";
    }
    else { return ""; }
  }
 untie %db;
} # end sub s_conflicts


# This figures out which characteristics (Replaces, Provides, etc) the
# options are pointing to.  Isn't choosey, prints all packages
sub character {

  my ($commands) = @_;
  my %commands = %$commands;

  # for singular cases
  if (
      $commands->{"g"} && 

      ($commands->{"T"} || 
       $commands->{"pre_depends"} ||
       $commands->{"depends"} || 
       $commands->{"recommends"} ||
       $commands->{"suggests"} || 
       $commands->{"enhances"} ||
       $commands->{"provides"} ||
       $commands->{"replaces"} || 
       $commands->{"conflicts"}) && 

      !($commands->{"c"} || 
	$commands->{"d"} || 
	$commands->{"l"} ||
	$commands->{"i"})

      ) {
       print "$argument\n";
  }       
 
  # all the characteristics
  if (defined $commands->{"T"}) {
        print pre_depends(\%commands);
        print depends(\%commands);
        print recommends(\%commands);
        print suggests(\%commands);
        print enhances(\%commands);
        print provides(\%commands);
        print replaces(\%commands);
        print conflicts(\%commands);
   }
   else {

    if (defined $commands->{"pre_depends"}) {
        print pre_depends(\%commands);
        delete $commands{"pre_depends"} if !($commands->{"S"} || $commands->{"g"});
     }

    if (defined $commands->{"depends"}) {
        print depends(\%commands);
        delete $commands{"depends"} if !($commands->{"S"} || $commands->{"g"});
     }

    if (defined $commands->{"recommends"}) {
        print recommends(\%commands);
        delete $commands{"recommends"} if !($commands->{"S"} || $commands->{"g"});
     }

    if (defined $commands->{"suggests"}) {
        print suggests(\%commands);
        delete $commands{"suggests"} if !($commands->{"S"} || $commands->{"g"});
     }

    if (defined $commands->{"enhances"}) {
        print enhances(\%commands);
        delete $commands{"enhances"} if !($commands->{"S"} || $commands->{"g"});
     }

    if (defined $commands->{"replaces"}) {
        print replaces(\%commands);
        delete $commands{"replaces"} if !($commands->{"S"} || $commands->{"g"});
     } 

    if (defined $commands->{"provides"}) {
        print provides(\%commands);
        delete $commands{"provides"} if !($commands->{"S"} || $commands->{"g"});
     }
  
    if (defined $commands->{"conflicts"}) {
        print conflicts(\%commands);
        delete $commands{"conflicts"} if !($commands->{"S"} || $commands->{"g"});
    } 
   }
    
} # end sub character

# Prints out the characteristics only for the packages which have them.
sub s_character {

  my ($commands) = @_;
  my %commands = %$commands;

    if ($commands->{"pre_depends"}) {
        print s_pre_depends(\%commands);
        delete $commands{"pre_depends"};
         if (s_pre_depends(\%commands) ne "") {
           character(\%commands);
         }
#        else { s_character(\%commands) } 
     }
    elsif ($commands->{"depends"}) {
        print s_depends(\%commands);
        delete $commands{"depends"};
         if (s_depends(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     }
    elsif ($commands->{"recommends"}) {
        print s_recommends(\%commands);
        delete $commands{"recommends"};
         if (s_recommends(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     }
    elsif ($commands->{"suggests"}) {
        print s_suggests(\%commands);
        delete $commands{"suggests"};
         if (s_suggests(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     }
    elsif ($commands->{"enhances"}) {
        print s_enhances(\%commands);
        delete $commands{"enhances"};
         if (s_enhances(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     }
    elsif ($commands->{"replaces"}) {
        print s_replaces(\%commands);
        delete $commands{"replaces"};
         if (s_replaces(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     } 
    elsif ($commands->{"provides"}) {
        print s_provides(\%commands);
        delete $commands{"provides"};
         if (s_provides(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
     }
    elsif ($commands->{"conflicts"}) {
        print s_conflicts(\%commands);
        delete $commands{"conflicts"};
         if (s_conflicts(\%commands) ne "") {
           character(\%commands);
         }
#         else { s_character(\%commands) } 
    } 

    # all the characteristics
    if ($commands->{"T"}) {
        print s_pre_depends(\%commands);
        print s_depends(\%commands);
        print s_recommends(\%commands);
        print s_suggests(\%commands);
	print s_enhances(\%commands);
        print s_provides(\%commands);
        print s_replaces(\%commands);
        print s_conflicts(\%commands);
     }

    
} # end sub s_character


# helps to determine if character(\%commands) should be used
sub which_character {
  my ($commands) = @_;
      if (
	  $commands->{"pre_depends"} || 
	  $commands->{"depends"} || 
          $commands->{"recommends"} || 
	  $commands->{"suggests"} ||
	  $commands->{"enhances"} ||
          $commands->{"replaces"} || 
	  $commands->{"provides"} ||
          $commands->{"conflicts"}
	  ) {
          return 1;
       }  
} # end sub which_character

# This runs a test to see whether or not the characters being asked for
# apply to this package.
sub the_character {

  my ($commands) = @_; 
  my %commands = %$commands;  

    if (defined $commands->{"pre_depends"}) {
        if (pre_depends(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }

    if (defined $commands->{"depends"}) {
        if (depends(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }

    if (defined $commands->{"recommends"}) {
        if (recommends(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }

    if (defined $commands->{"suggests"}) {
        if (suggests(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }

    if (defined $commands->{"enhances"}) {
        if (enhances(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }

    if (defined $commands->{"replaces"}) {
        if (replaces(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     } 

    if (defined $commands->{"provides"}) {
        if (provides(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
     }
  
    if (defined $commands->{"conflicts"}) {
        if (conflicts(\%commands) eq "") {
          print "";
        }
        else { return "ok"; }
    } 

} # end sub the_character

1;
