#!/usr/bin/perl

use strict;
use warnings;

use JSON qw/ encode_json /;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;

my $site = "http://www.thecrag.com";
my $start = "http://www.thecrag.com/climbing/world";
my $test = "http://www.thecrag.com/climbing/australia/grampians";
my $data;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->agent('DuckDuckBot/1.1');

open (MAP, ">:encoding(UTF-8)", "maps.js");

open( OUT , ">:encoding(UTF-8)" , "processed-climb.txt") ;
print OUT <<EOH
<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
EOH
;

crawl($test, "none" );

close OUT;
open my $fh, ">", "climbing.json";
print $fh encode_json($data);
close $fh;

sub crawl{
	my ($url, $supertype) = @_;
	my $tree = HTML::TreeBuilder::XPath->new;
	my $response = $ua->get($url);
	if ($response->is_success){
		$tree->parse($response->decoded_content);
	}
	else{
		die $response->status_line;
	}
	
	my $type = $tree->findvalue('//a[@href="/article/AreaTypes"]');
	
	unless($type eq "region"){
		my $title = $tree->findvalue('//title');
		$title =~ s/ \| theCrag//;
		my ($place, $styleinfo) = split(', ', $title);
		$data->{$place}->{"url"}=$url;
		print "$place: $url \n";
		$data->{$place}->{"type"}=$type;
		
		my @latmeta = $tree->findnodes('//meta[@property="place:location:latitude"]');
		my @lonmeta = $tree->findnodes('//meta[@property="place:location:longitude"]');
		my $lat = $latmeta[0]->attr('content');
		my $lon = $lonmeta[0]->attr('content');
		$data->{$place}->{"longitude"} = $lon;
		$data->{$place}->{"latitude"} = $lat;
		
		my @breadcrumbs = $tree->findvalues('//div[@id="breadCrumbs"]/ul/li');
		my $crumbs = "";
		foreach my $i(1..$#breadcrumbs){
			$data->{$place}->{"breadcrumbs"}->[$i-1] = $breadcrumbs[$i];
			$crumbs = $breadcrumbs[$i] . "," . $crumbs;
			}
		$crumbs =~ s/,$//;
		my $numroutes=$tree->findvalue('//a[@title="Search and filter these routes"]');
		$numroutes = substr($numroutes,1,(index($numroutes,'routes')-2));
		$data->{$place}->{"number of routes"}=$numroutes;

		my @styles = $tree->findvalues('//span[@class= "style-breakdown" ]/a');
		foreach my $i(0..$#styles){
			my $style = $styles[$i];
			my $percent = substr($style,1,index($style,"%"));
			my $type = substr ($style,index($style,"%")+1);
			$type =~ s/^\s+//g;
			$data->{$place}->{'styles'}->{$type} = $percent; 
			}

		my @areas = $tree->findnodes('//div[@class = "area"]' );
		foreach my $i (0..$#areas){
			$data->{$place}->{'areas'}->[$i]->{'name'} = substr($areas[$i]->findvalue('div[@class="name"]'),0,-5);
			$data->{$place}->{'areas'}->[$i]->{'routes'} = $areas[$i]->findvalue('div/div[@class="routes"]');
			$data->{$place}->{'areas'}->[$i]->{'ticks'} = $areas[$i]->findvalue('div/div[@class="ticks"]');
			$data->{$place}->{'areas'}->[$i]->{'height'} = $areas[$i]->findvalue('div/div[@class="height"]');
			my @links= $areas[$i]->findnodes('div/a[@href]');
			$data->{$place}->{'areas'}->[$i]->{'link'} = $links[1]->attr('href');
		}
		
		my $paragraph = "";
		my @summaryinfo= $tree->findnodes('//div[@class="node-info summary"]');
		my @descriptioninfo= $tree->findnodes('//div[@class="node-info description"]');
		if($#summaryinfo == 0){
			my @summary= $summaryinfo[0]->findvalues('div/div/p');
			for my $i (0 .. $#summary){
				$paragraph = ($summary[$i] . "\n\n");
			}
		}
		if($#descriptioninfo == 0){
			my @description = $descriptioninfo[0]->findvalues('div/div/p');
			$paragraph = $paragraph . $description[0];
		}
		if(($paragraph eq "") == 1)
		{
			my @defmeta = $tree->findnodes('//meta[@property="og:description"]');
			my $definition = $defmeta[0]->attr('content');
			$definition = substr($definition, index($definition, $place)+length($place)+2);
			$paragraph = $definition;
		}
		
		my $mapjs = $response->decoded_content;
		$mapjs =~ s/[ \n]//g;
		my $boundary = "";
		if ($mapjs =~ m/varboundary(.*?);/) {$boundary = $1;}
		if ($boundary =~ m/geometry:(.*?),cen/) {$boundary=$1;}
		print MAP <<EOH
//$place
DDG.duckbar.add_map([{"licence":"Data \\u00a9 OpenStreetMap contributors, ODbL 1.0. http:\\\/\\\/www.openstreetmap.org\\\/copyright","osm_type":"relation", "polygonpoints":$boundary, "display_name":"$crumbs", "lat":$lat, "lon":$lon, "class":"boundary", "type":"administrative","importance":0.73982781390695, "icon":"http:\\\/\\\/open.mapquestapi.com\\\/nominatim\\\/v1\\\/images\\\/mapicons\\\/poi_boundary_administrative.p.20.png"}])
EOH
;
		
		
		print OUT <<EOH
<doc>
<field name="title"><![CDATA[$place $styleinfo]]></field>
<field name="12_sec_match2">climb climbing</field>
<field name="paragraph"><![CDATA[$paragraph]]></field>
<field name="source"><![CDATA[climb]]></field>
<field name="meta"><![CDATA[{"url":"$url"}]]></field>
<field name="geo">$lat, $lon</field>
</doc>
EOH
;

		if(($type eq 'crag')==1 and ($supertype eq 'crag')!=1) {
			foreach my $i (0..$#areas){
				my $link = $data->{$place}->{'areas'}->[$i]->{'link'};
				crawl($site . $link, $type);
			}
		}
	}
	else{
		my @areas = $tree->findnodes('//div[@class = "area"]' );
		foreach my $i (0..$#areas){
				my @links= $areas[$i]->findnodes('div/a[@href]');
				my $link  = $links[1]->attr('href');
				crawl($site . $link, $type);
		}
	}
	
	$tree->delete();
   };
