#!/usr/bin/perl

use warnings;
use strict;
use Encode;
use DBI;

use lib qw(/usr/local/ddg/lib c:/www/files/duckduckgo.com/ddg/lib);
use DDG::Util::Process qw(decode_encode_str);
use DDG::Util::String qw(trim_ws);

use Digest::MD5 qw(md5);

my $testfile = "/tmp2/ddg/lyricsmode.sqlite3";
my $dbh = DBI->connect("dbi:SQLite:dbname=$testfile","","");

#sqlite> .schema
#CREATE TABLE LYRICS(title VARCHAR(300) NOT NULL,
#                artist VARCHAR(200) NOT NULL,
#                album VARCHAR(200) NOT NULL,
#                url VARCHAR(2000) NOT NULL,
#		    lyric_text TEXT NOT NULL);



# ordering by album favors dups with album first.
my $sth = $dbh->prepare("SELECT * FROM lyrics ORDER BY ALBUM DESC");
#my $sth = $dbh->prepare("SELECT * FROM lyrics");
#my $sth = $dbh->prepare("SELECT * FROM lyrics LIMIT 10");
$sth->execute();

open( OUT , ">:encoding(UTF-8)" , "/tmp2/ddg/lyrics.pre-process.txt") ;
print OUT <<EOH
<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
EOH
    ;

my $count = 0;
my %dup = ();
SONG: while (my $row = $sth->fetchrow_hashref) {
    print $count, "\n" if ++$count % 1000 == 0;

    my $artist = $row->{'artist'} || '';
    my $album = $row->{'album'} || '';
    my $song = $row->{'title'} || '';
    my $lyrics = $row->{'lyric_text'} || '';
    my $url = $row->{'url'} || '';

    # Control chars.
    # Also takes care of weird line break issues.
    map {$_ =~ s/[\x01-\x09\x0B-\x1F]//sog} ($artist,$album,$song,$lyrics,$url);

    map {$_ = trim_ws($_)} ($artist,$album,$song,$lyrics,$url);

    $artist =~ s/ Lyrics$//o;
    next SONG if $artist =~ /Various\s*Artists?/io;

    # After clean up.
    next SONG if !$artist || !$song || !$lyrics || !$url;
    next SONG if $artist =~ /^\d+$/o;
    next SONG if length($artist)==1;

    # For debugging.
#    die if length($artist)==1;
#    print $song, "\n" if $song;
#    print $artist, "\n" if $artist =~ /^\d+$/o;
#    print $artist, "\n" if !$song;
#    print "$url\n" if !$album;
#    next if $url ne 'www.lyricsmode.com/lyrics/b/blink_182/whats_my_age_again.html';

    my $dup = $artist . $song;
    if (exists $dup{$dup}) {

	# For debugging.
#	print qq($url\t), $dup{$dup}, "\n";

	next;
    }
    $dup{$dup} = $url;

    my $p_count = 20;
    PARAGRAPH: foreach my $paragraph (split(/\n{2,}/so,$lyrics)) {

	next PARAGRAPH if $paragraph =~ /^\([^\n]+\)$/ios;
	next PARAGRAPH if length($paragraph)<50;
	next PARAGRAPH if $paragraph !~ /\n/os;
	next PARAGRAPH if $paragraph =~ /(?:Written by|\(written by|The lyrics|Lyrics written|All songs written by|track \d+)/os;

	# For debugging.
#	die $paragraph if $paragraph =~ /\n/so;
#	print qq(\n$paragraph\n) if $paragraph =~ /written by/ios;

	my $md5 = md5($artist . $song . $paragraph);
	if (exists $dup{$md5}) {

	    # For debugging.
#	    print qq($artist\t$song\t$paragraph\n);

	    next PARAGRAPH;
	}
	$dup{$md5} = undef;

	# Adding lyrics to title so it doesn't take precendence of wiki articles.
	# 2010.08.29 bad idea because then artist lyrics doesn't take precendence.
	# Instead starting p_count much higher (20) to keep lower precedence.

	# Also making it the l2_sec so that it gets boosted via exact match
	# Breaking out album and songs so exact matches rank higher than embedded ones.
	print OUT <<EOH
<doc>
<field name="title"><![CDATA[$artist]]></field>
<field name="l2_sec">Lyrics</field>
<field name="l3_sec"><![CDATA[$album]]></field>
<field name="l4_sec"><![CDATA[$song]]></field>
<field name="paragraph"><![CDATA[$paragraph]]></field>
<field name="p_count">$p_count</field>
<field name="source">$url</field>
</doc>
EOH
;

	$p_count++;

    }

    # For debugging.
#    last if $count;
#    last if $count>1000;
}

print OUT <<EOH
</add>
EOH
    ;
close(OUT);
