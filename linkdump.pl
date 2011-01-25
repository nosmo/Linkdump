#!/usr/bin/perl

# INCLUDES
use strict;

use URI;
use XML::RSS;
use LWP::Simple;
use HTML::Entities;

use vars qw($VERSION %IRSSI);
use Irssi qw(
    settings_get_int settings_get_str                                                                                                         settings_add_int settings_add_str
    signal_add_last
    );

# List of channels to NOT log.
my @nologchannels = ("#testlolol");

# Change these as you see fit
my $user = "nosmo";
my $feedfile = "/home/$user/www/links.rss";
my $site = "http://www.netsoc.tcd.ie/~nosmo/";
my $feeddescription = "Could this be used for something useful in the future?";

$VERSION = '1.01';
%IRSSI = (
    authors     => 'nosmo',
    contact     => 'nosmo@netsoc.tcd.ie',
    name        => 'linkdump',
    description => 'Dump links to an RSS feed for ease of access.',
    license     => 'Public Domain',
    );

settings_add_int('linkdump','do_pms',0);
settings_add_int('linkdump','do_channels',1);

print "THIS PROGRAM DUMPS LINKS INTO A GIVEN FILE - THIS FILE WILL BE VIEWABLE BY ANYONE UNLESS YOU SET UP SOME SAFEGUARDS";

sub sig_public {
    my ($server, $msg, $nick, $address, $channel) = @_;

    if ($channel ~~ @nologchannels) {
        return;
    }

    if (($msg =~ /https?:\/\/\S* /) || ($msg =~ /https?:\/\/\S*$/)) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        my $title = "Message from $nick in $channel at $hour:$min:$sec, $mday, $mon, $year";
        my $link = $&;
        my $urltitle;
        my $content = get $link;
        if($content =~ /<title>(.*)<\/title>/ig) {
            $urltitle = HTML::Entities::encode($1);
        }

        my $description = $urltitle;

        if (! -e $feedfile ) {
            print "Created file";
            my $rss = new XML::RSS( version => '1.0' );
            $rss->channel(
                title => "IRC RSS link dump for " . $user,
                link  => $site,
                description => $feeddescription,
                );
            $rss->save($feedfile);
            $rss->add_item(title => $title, link => $link, description => $description);
            chmod(0755, $feedfile);

        } else {
            my $rss = new XML::RSS( version => '1.0' );
            $rss->parsefile($feedfile);
            $rss->add_item(title => $title, link => $link, description => $description);
            $rss->save($feedfile);
        }
    }
}


if(settings_get_int('do_channels')) {
    Irssi::signal_add_last('message public', 'sig_public');
}

if(settings_get_int('do_pms')) {
    Irssi::signal_add_last('message private', 'sig_public');
}

#&sig_public;

