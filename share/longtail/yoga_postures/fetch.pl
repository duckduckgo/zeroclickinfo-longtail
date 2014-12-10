#!/usr/local/bin/perl
   
use WWW::Mechanize; 
use File::Path 'make_path';
use File::Slurp 'write_file';
use YAML::XS qw(Load DumpFile);
use Data::Dumper;

use strict;

my $data_dir = 'download';

my $ayi_base = 'http://www.ashtangayoga.info/practice';
my @ayi_practices = qw(
	surya-namaskara-a-sun-salutation/opt/info
    surya-namaskara-b-sun-salutation-b/opt/info
    basic-sequence-fundamental-positions 
    the-finishing-sequence 
    primary-series-yoga-chikitsa 
    intermediate-series-nadi-shodhana 
    advanced-a-series-sthira-bhaga 
);
my $ayi_dir = 'ashtanga.info';

my $yc_url = 'https://yoga.com/api/content/feed/?format=json&type=pose&offset=0&limit=500';
my $yc_file = 'yoga.com.yaml';

my (%skip, $verbose);

parse_argv();

my $m = WWW::Mechanize->new(agent => 'Mozilla/5.0 (X11; FreeBSD amd64; rv:30.0) Gecko/20100101 Firefox/30.0');

unless(exists $skip{ayi}){
	my $archive = "$data_dir/$ayi_dir";
	make_path($archive);
	for my $p (@ayi_practices){
		my $url = "$ayi_base/$p/";
		warn "Getting $url\n";
		my $r = $m->get($url);
		unless($r->is_success){
			die "Failed to retrieve $url: " . $r->status_line;
		}
		if($p =~ /^(surya-namaskara-(?:a|b))/o){
			my $file = "$archive/$1.html";	
			unless(-e $file){
				write_file($file, {binmode => ':utf8'}, "<!-- source: $url -->\n", $r->decoded_content);
			}
		}
		my $links = $m->find_all_links(url_regex => qr{practice/$p/item/[^/]+/$}, text_regex => qr{^[^\[]+$});
		for my $l (@$links){
			my $url = $l->url;
			next if $url =~ m{-\d+/$}o; # unnamed transition postures
			unless($url =~ m{/([^/]+)/$}o){
				die "Failed to extract asana from $url";
			}
			my $file = "$archive/$1.html";
			next if -e $file;

			warn "\tGetting ", $l->url, ' (text: ', $l->text, ")\n";	
			my $res = $m->get($l);
			if($res->is_success){
				warn "\tSaving $file\n";
				write_file($file, {binmode => ':utf8'}, "<!-- source: $url -->\n", $res->decoded_content);
			}
			else{
				die "Failed to retrieve $url: " . $res->status_line;
			}
		}
	}
}

unless(exists $skip{yc}){
	my $r = $m->get($yc_url);
	unless($r->is_success){
		die "Failed to retrieve $yc_url: " . $r->status_line;
	}
	my $yc_data = Load($r->decoded_content);
	warn Dumper($yc_data);
	$m->get('https://yoga.com/pose/downward-facing-dog-pose/photo');
	unless($r->is_success){
		die "Failed to retrieve $yc_url: " . $r->status_line;
	}
	my $l = $m->find_link(url_regex => qr{\.cloudfront\.net/static});
	my $iurl = $l->url;
	unless($iurl =~ m{^https?://([^/]+)}i){ # images appear to work both with and without SSL
		die "Failed to extract cloudfront image server from url $iurl";
	}
	my $imgsrv = $1;

	my (%out, $img_verified, $src_verified);
	for my $a (@{$yc_data->{payload}{objects}}){
		my $imgurl = 'http://' . $imgsrv . $a->{photo};
		unless($img_verified){ # basic check that our link composition still works
			my $r = $m->get($imgurl);
			unless($r->is_success){
				die "Failed to retrieve $imgurl: " . $r->status_line. '. Check that images are still begin served from cloudfront.net.';
			}
			++$img_verified;
		}
		my $srcurl = join('/', 'https://yoga.com/pose', $a->{slug}, 'photo');
		unless($src_verified){ # basic check that our source link format still works
			my $r = $m->get($srcurl);
			unless($r->is_success){
				die "Failed to retrieve $srcurl: " . $r->status_line. '. Check that source format for photos is still https://yoga.com/post/[slug]/photo';
			}
			++$src_verified;
		}
		if(exists $out{$a->{sanskrit_name}}){ # should be unique; if not, let's check it out
			warn $a->{sanskrit_name}, " already exists\n";
			next;
		}
		$out{$a->{sanskrit_name}} = {
			src => $srcurl,
			img => $imgurl,
			title => $a->{title}	
		};	
	}
	my $output = join('/', $data_dir, $yc_file);
}

# command-line options
sub parse_argv {
    my $usage = <<ENDOFUSAGE;

    *******************************************************************
        USAGE: fetch.pl [-data path/to/data] [-no_*] [-v]

        -data: (optional) path to the download directory
        -no_*: (optional) turn off download of a site:
           ayi: ashtanga.info 
           yc:  yoga.com
        -v: (optional) Turn on some parse warnings

    *******************************************************************

ENDOFUSAGE

    for(my $i = 0;$i < @ARGV;$i++) {
        if($ARGV[$i] =~ /^-data$/o) { $data_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/o) { $verbose = 1; }
        elsif($ARGV[$i] =~ /^-no_(\w+)$/o) { ++$skip{$1} }
    }
}
