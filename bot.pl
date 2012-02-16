#!/usr/bin/perl -w

use strict;
# use warnings;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind signal_add);
use Irssi::Irc;
use IO::File;
use BerkeleyDB;
use LWP;
use Time::Local;
use Date::Calc qw(Delta_DHMS);
use Time::Format;
use HTTP::Request::Common qw(POST GET);
use HTML::TokeParser;
use XML::Simple;
use Data::Dumper;
use HTML::Entities;

$VERSION = '0.4';

%IRSSI =
(
    author      => 'apalos, eth0, argp, brat3 and the #penguins lurkers',
    contact     => '#penguins at grnet',
    name        => 'tatianna',
    description => '#penguins bot',
    license     => 'GPLv3',
);

my $quotedb = 'irssiq.db';
my @chanops = ();
my %hquote = ();
my $urldb = 'url.db';

our ($server, $data, $nick, $whois, $channel);

sub tiedb
{
    my $dbtotie = $_[0];
    tie %hquote, "BerkeleyDB::Hash",
        -Filename => "$dbtotie",
        -Flags    => 'DB_CREATE',
        -Property => 'DB_DUP',
        or Irssi::print "Cannot open file $dbtotie $! $BerkeleyDB::Error\n";
}

sub checkop
{
    undef @chanops;
    my $c = $server->channel_find($channel);
    
    foreach my $ops ($c->nicks())
    {
        push(@chanops, $ops) if ($ops->{op});
    }
}

sub help
{
    my $srv = shift;
    my $chn = shift;
	
    $srv->command("MSG $chn !add <quote> || !quote || !del <quote number> ||");
    $srv->command("MSG $chn !stats || !stats full || !grouphug || !url ||");
    $srv->command("MSG $chn !fmylife || !cfu || !reload_script");
    
    return;
}

sub foobar
{
    my $srv = shift;
    my $chn = shift;
              
    # my $cmd = "echo foo";
    # system $cmd;

    $srv->command("MSG $nick test");
    return;
}

sub reload_script
{
    my $srv = shift;
    my $chn = shift;
    
    $srv->command("/script load bot.pl");
    $srv->command("MSG $chn bot.pl script reloaded");
    
    return;
}

sub sayquote
{
	my $args  = $_[0] if defined $_[0];
	my @dblist = ();
	my @realentry = ();
	my @personquote = ();
	\&tiedb($quotedb);
	
    my $dbentries = scalar keys %hquote;
		srand;
		my $randno = int( rand($dbentries) );
		foreach my $outtie ( sort keys %hquote ) {
			push( @dblist, $hquote{$outtie} ) if defined $hquote{$outtie};
			push( @realentry, $outtie );
		}
	
    if(defined $args)
    {
			my $nickquote = $args;
			chomp $nickquote;
            # my @personquote = grep ( /(<?@?)$nickquote>/, @dblist );
            $nickquote = lc($nickquote);
            $nickquote =~ s/\*//g;
            my @personquote = grep (/$nickquote/i, @dblist);
			my $specrand = int(rand( scalar @personquote ) );
			$server->command("MSG $channel [$1] $personquote[$specrand]") if defined $personquote[$specrand];
	}
	else
    {
			$server->command("MSG $channel [$realentry[$randno]] $dblist[$randno]");
    }
	
    untie %hquote;
    return 0;
}

sub addquote {
	my $args = $_[0];
	\&checkop();
	\&tiedb($quotedb);
#my $exitflag = 1;
#	foreach my $test (@chanops) {
#		if ( $nick =~ /$test->{nick}/ ) {
#			$exitflag = 0;
#			last;
#		}
#	}
#	if ($exitflag == 1) {
#		$server->command( "MSG $channel Must be OP'ed to add comments." );
#		return 0;
#	}
	my( $command, $insdata ) = split( ' ', $args, 2 );
	chomp $insdata;
	my $dbentries = ( scalar keys %hquote );
	#what was this while meant to do ?????
	while ( defined $hquote{$dbentries} ) {
		$dbentries++;
	}
	$hquote{"$dbentries"} = "$insdata";
	$server->command( "MSG $channel Quote number $dbentries added." );
  untie %hquote;
  return 0;
}

sub delquote {
	my $args = $_[0];
	my $exitflag = 1;
	\&checkop();
	\&tiedb($quotedb);
	foreach my $test (@chanops) {
		if ( $nick =~ /$test->{nick}/ ) {
			$exitflag = 0;
			last;
		}
	}
	if ($exitflag == 1) {
		$server->command( "MSG $channel Must be OP'ed to delete comments." );
		return 0;
	}
	my $dbentries = scalar keys %hquote;
	my ( $command, $delno ) = split( ' ', $args, 2 );
	chomp $delno;
	if ( $delno > $dbentries ) {
		$server->command("MSG $channel DB has less than $delno entries");
	}
	else {
		delete $hquote{$delno};
		$server->command("MSG $channel deleted quote [$delno]");
	}
	untie %hquote;
  return 0;
}

sub stats {
	\&tiedb($quotedb);
	my $dbentries = scalar keys %hquote;
  my $c         = $server->channel_find($channel);
	my $args = $_[0];
	my %fstats    = ();
	open DB, '> /tmp/tempdb';
	for my $outtie ( keys %hquote ) {
  	print DB "$hquote{$outtie}\n";
  }
  close DB;
  my @nicks = ();
  for my $hash ( $c->nicks() ) {
  	next if ( $hash->{nick} eq $server->{nick} );
  	push @nicks, $hash->{nick};
  }
  
  my @nicks = ('apalos|apal0s|apalol',
               'cyberpunk',
               'invisible|invisibl|argp',
               'sivitos|siv|kyriakos',
               'gus',
               'koki|privekoki|jism',
               'Brat3|brat|brast|kargig',
               'peanut|paeniot|piniot|pasnut|poiois|testify|hciaoxiao',
               'fruit|eth0|fffruit|fruit2u|fruitwerk|fruitay|thefruit',
               'iM',
               'nteminio',
               'comzeradd',
               'eltoots',
               'panto',
               'wtfmejt',
               'blacksoul',
               'kav_|kav',
               'zafos|zafoss|qurashee',
               'kampia');
  
  open SDB, '/tmp/tempdb';
  while (<SDB>) {
  	foreach my $statnick (@nicks) {
    	#if ( $_ =~ /(<?)$statnick>/ ) {
    		if ( $_ =~ /(.*)($statnick)(.*)(>|:)/i ) { #quoted nicks end with > or :
      			$fstats{$statnick}++;
      			next;
     		}
   	}
  }
  if ( defined $args and $args =~ /full$/ ) {
	my $value=0.00;
  	#foreach my $famous ( sort keys %fstats ) {
  	foreach $value ( sort {$fstats{$b} <=> $fstats{$a} } keys %fstats ) {
			#my $percentage = ($fstats{$famous}/$dbentries)*100;
			my $percentage = ($fstats{$value}/$dbentries)*100;
			my $rounded = sprintf("%.1f", $percentage);
    	#$server->command("MSG $channel $famous has $fstats{$famous} [$rounded%]");
    	$server->command("MSG $channel $value has $fstats{$value} [$rounded%]");
			print "$percentage";
  	}
  } else { #assume we want top quoter only
#quick sort
  	my @sorted = sort { $fstats{$b} <=> $fstats{$a} } keys %fstats;
		my $percentage = ($fstats{$sorted[0]}/$dbentries)*100;
		my $rounded = sprintf("%.1f", $percentage);
    $server->command("MSG $channel $sorted[0] has $fstats{$sorted[0]} entries[$rounded%]");
  }
  close SDB;
  untie %hquote;
  unlink('/tmp/tempdb');
}

sub showurl {
	my @realentry;
	\&tiedb($urldb);
	my $dbentries = scalar keys %hquote;
	srand;
	my $randurl = int(rand($dbentries));
	foreach my $outurl ( sort keys %hquote ) {
			push( @realentry, $outurl );
		}
  $server->command("MSG $channel http://$realentry[$randurl]");
}

sub IfCases
{
    ($server, $data, $nick, $whois, $channel) = @_;
    
    $_ = $data;
	
    if(/^!help/i)
    {
        \&help($server, $channel);
	}
    elsif(/^!foobar/i)
    {
        \&foobar($server, $nick);
    }
    elsif(/^!reload_script/i)
    {
        \&reload_script($server, $channel);
    }
    elsif(/^!grouphug/i)
    {
        \&getgrouphug($server, $channel, $nick);
    }
    elsif(/^!fmylife/i)
    {
        \&getfmylife($server, $channel, $nick);
    }
    elsif(/^!cfu/i)
    {
        \&getcfu($server, $channel, $nick);
    }
	elsif(/^!add (...+)$/i)
    {
		\&addquote($data);
	}
	elsif(/^!quote (.*?)$|^!quote/i)
    {
		my $innick = $1; 
		\&sayquote($innick);	
	}
    elsif (/^!del (.*?)$/i)
    {
        \&delquote($data);
	}
    elsif (/^!url$/i)
    {
		\&showurl();
	}
    elsif (/^!stats (.*?)$|^!stats$/i)
    {
		my $statsdata = $1;
		\&stats($statsdata);
	}
	else
    {
	    return 0;
	}
}

#HTTP Parsing Function
#
#/////////////////////////////////////////////////////////////////////////////////////
sub Parsehttp {
    my ( $server, $data, $nick, $whois, $channel ) = @_;
    if ( $data =~ /http:\/\/(.*?)( .*|\s?)$/ ) {
        my ( $server, $data, $nick, $whois, $channel ) = @_;
        my $url = $1;
        chomp $url;
        my $ua = LWP::UserAgent->new();
        $ua->agent("Parseheaders");
        $ua->max_size('100000');
        my $req = HTTP::Request->new( GET => "http://$url" );
        my $res = $ua->request($req);
        my $out = $res->title;
        $server->command("MSG $channel [$out]") if defined $out;

        #add url's to a db for use
				\&tiedb($urldb);
        my $stamp = $time{'yy:mm:dd:hh:mm:ss'};
        if ( exists $hquote{$url} ) {
            my ( $cur_yy, $cur_mm, $cur_dd, $cur_hh, $cur_min, $cur_ss ) =
              split( ':', $stamp );
            my ( $when, $who ) = split( '\|', $hquote{$url} );
            my ( $yy, $mm, $dd, $hh, $min, $ss ) = split( ':', $when );
            my ( $Dd, $Dh, $Dm, $Ds ) = Delta_DHMS(
                $yy,     $mm,     $dd,     $hh,     $min,     $ss,
                $cur_yy, $cur_mm, $cur_dd, $cur_hh, $cur_min, $cur_ss
            );
            $server->command(
"MSG $channel OLD! $who mentioned this $Dd days, $Dh hours, $Dm minutes and $Ds seconds ago"
            );
        }
        else {
            #$url{"$url"} = "$stamp|$nick" if defined $url;
            $hquote{"$url"} = "$stamp|$nick" if ($res->is_success); 
        }
        untie %hquote;
        return 0;
    }
    else {
        return 0;
    }
}

#End HTTP Parsing Function
#
#/////////////////////////////////////////////////////////////////////////////////////

#grouphug  Function, provided by kav_
#
#/////////////////////////////////////////////////////////////////////////////////////
sub getgrouphug
{
    my $srv = shift;
    my $chn = shift;
    my $nick = shift;

	my @huggers;
	my $text;
    my $id;
	
    undef @huggers;
    
    my($grouphugurl);
    my $ua = new LWP::UserAgent;
    
    $ua->timeout(60);
    $grouphugurl = 'http://beta.grouphug.us/random';
    
    my $req = GET $grouphugurl ;
    my $response = $ua->request($req);
    
    if($response->is_success)
    {
        my $doc = \$response->content();
        my ($tag,$elem);
        my $p = HTML::TokeParser->new($doc) || print "couldnt parse: $!\n";
		
        while (my $token = $p->get_tag("div"))
        {
		    undef $text;
		    chomp $token->[1]{"class"};
         	if($token->[1]{"class"} eq "node node-confession promoted teaser")
            {
      			$id = $p->get_trimmed_text("/h2");
                $text = $p->get_trimmed_text("/div");
               	
                if(defined $text && length($text) > 254)
                {
                    $text = substr($text, 0, rindex($text," ",254)) . " [-snip-]";
               	}
				
                $text = join(':', $id, $text);
				chomp $text;
				push(@huggers, $text) if defined $text;
            }
        }
    }

	srand;
	
    my $entries = scalar @huggers;
	my $rand = int(rand($entries));
	
    my($no, $say) = split(':', $huggers[$rand], 2);
	
    if ($say =~ /\[-snip-\]/)
    {
        $srv->command("MSG $chn $nick: $say [ http://grouphug.us/confessions/$no ]") if $no =~ /[0-9]/; 
	}
	else
    {
        $srv->command("MSG $chn $nick: $say") if ($no =~ /[0-9]/);
	}
}
#End grouphug Function
#
#/////////////////////////////////////////////////////////////////////////////////////

# fmylife function by argp
sub getfmylife
{
    my $srv = shift;
    my $chn = shift;
    my $nick = shift;

    my $fmlurl = "http://api.betacie.com/view/random/nocomment?key=readonly&language=en";
    my $ua = new LWP::UserAgent;
    my $xml = new XML::Simple;

    $ua->agent('Opera/9.10 (X11; Linux i686; U; en)');

    my $req = new HTTP::Request('GET', $fmlurl);
    my $response = $ua->request($req);

    if($response->is_success())
    {
        my $doc = $response->content();
        my $xml_data = $xml->XMLin($doc);
        my $text = $xml_data->{items}->{item}->{text};

        if(defined($text))
        {
            $srv->command("MSG $chn $nick: $text");
        }
    }
}

# function by brat3
sub getcfu($server, $channel, $nick)
{
    my $srv = shift;
    my $chn = shift;
    my $nick = shift;

    my $url = "http://www.commandlinefu.com/commands/random";
    my $ua = LWP::UserAgent->new();
    my $doc = "";
    my $text = "";

    $ua->agent("Parseheaders");
    $ua->max_size('100000');

    my $req = HTTP::Request->new( GET => "$url" );
    my $result= $ua->request($req);

    if ($result->is_success)
    {
        $doc = $result->content();
    }
    else
    {
        return;
    }

    #load the file to @CF so we can move between $line and $line+1
    open my $fh, '<', \$doc or return;
    my @CF = <$fh>;
    close($fh);

    my $size = @CF;

    for(my $i = 0; $i < $size; $i++)
    {
        if ($CF[$i] =~ /<div class=\"command\">/) {
                $CF[$i] =~ s/.*<div class=\"command\">(.*)<\/div>/$1/g;
                $CF[$i] = decode_entities($CF[$i]);
                # print $CF[$i];
                $srv->command("MSG $chn CMD: $CF[$i]");
        }
        if ($CF[$i] =~ /<div class=\"description\">/) {
                $CF[$i+1] =~ s/.*<p>(.*)<\/p>/$1/g;
                $CF[$i+1] = decode_entities($CF[$i+1]);
                # print "Description: $CF[$i+1]";
                if($CF[$i+1] =~ /\w/)
                {
                    $srv->command("MSG $chn Description: $CF[$i+1]");
                }
        }
        if ($CF[$i] =~ /<div class=\"summary\">/) {
                $CF[$i+1] =~ s/.*<a href=\"(.*)\" title=\".*\">(.*)<\/a>/URL=http:\/\/www.commandlinefu.com$1  Title=$2/g;
                $CF[$i+1] = decode_entities($CF[$i+1]);
                # print $CF[$i+1];
                $srv->command("MSG $chn $CF[$i+1]");
        }
    }
 
}

my $CHANNEL  = '#penguins';    # FIXME : move to irssi attrib hash

##########
## Wrapper around MSG

sub say
{
    my $server  = shift;
    my $channel = shift;
    my $msg     = shift;
    
    return unless defined $server && defined $channel && defined $msg;
    $server->command('MSG ' . $channel . ' ' . $msg);
}

#End Karma Function
#
#/////////////////////////////////////////////////////////////////////////////////////

# add commands and public signals
signal_add("message public", \&IfCases);
signal_add("message private", \&IfCases);
signal_add("message public", \&Parsehttp);
# signal_add("message public", \&karma);

# EOF
