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


package SWIM::F;
use Carp;                                                                       
use strict;
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get);


# This is Net::FTP::get with minor modifications.  Not all the features
# are used, but are kept, just in case they will be.

sub get                                                                         
{                                                                               
 my($ftp,$remote,$local,$where) = @_;                                           
                                                                                
 my($loc,$len,$buf,$resp,$localfd,$data);                                       
 local *FD;                                                                     
 $| = 1;                                                                               
 $localfd = ref($local) ? fileno($local)                                        
                        : undef;                                                
                                                                                
 ($local = $remote) =~ s#^.*/##                                                 
        unless(defined $local);                                                 
                                                                                
 ${*$ftp}{'net_ftp_rest'} = $where                                              
        if ($where);                                                            
                                                                                
 delete ${*$ftp}{'net_ftp_port'};                                               
 delete ${*$ftp}{'net_ftp_pasv'};                                               
                                                                                
 $data = $ftp->retr($remote) or                                                 
        return undef;                                                           
                                                                                
 if(defined $localfd)
  {                                                                             
   $loc = $local;                                                               
  }                                                                             
 else                                                                           
  {                                                                             
   $loc = \*FD;                                                                 
                                                                                
   unless(($where) ? open($loc,">>$local") : open($loc,">$local"))              
    {                                                                           
     carp "Cannot open Local file $local: $!\n";                                
     $data->abort;                                                              
     return undef;                                                              
    }                                                                           
  }                                                                             
                                                                                
 if($ftp->type eq 'I' && !binmode($loc))                                        
  {                                                                             
   carp "Cannot binmode Local file $local: $!\n";                               
   $data->abort;                                                                
   return undef;                                                                
  }                                                                             
                                                                                
 $buf = '';  my $amt = 0;                                                                     
 #print "\n";
 do                                                                             
  {                                                                             
   $len = $data->read($buf,1024); 
   $amt = $len + $amt;
   print "[$amt]\r";
  }                                                                             
 while($len > 0 && syswrite($loc,$buf,$len) == $len);                           
                                                                                
 close($loc)                                                                    
        unless defined $localfd;                                                
                                                                                
 $data->close(); # implied $ftp->response                                       
                                                                                
 return $local;                                                                 
}             
