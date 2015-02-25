#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use LWP::UserAgent;

my $site = "http://www.thecrag.com";
my $start = "$site/climbing/world";
my $test = "$site/climbing/australia/grampians";
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

crawl($test, "none", "North West", "$site/climbing/australia/victoria/north-west" );

close OUT;

sub crawl{
	my ($url, $supertype, $parent, $parenturl) = @_;
	my $tree = HTML::TreeBuilder::XPath->new;
	my $response = $ua->get($url);
	if ($response->is_success){
		$tree->parse($response->decoded_content);
	}
	else{
		die $response->status_line;
	}
	
	my $type = $tree->findvalue('//a[@href="/article/AreaTypes"]');
	my $title = ($tree->findnodes('//meta[@property="og:title"]'))[0]->attr('content');
	my ($place, $styleinfo) = split(', ', $title);
	
	unless($type eq "region"){
		
		$styleinfo = lc($styleinfo);
		print "$place: $url \n";
		
		my $lat = ($tree->findnodes('//meta[@property="place:location:latitude"]'))[0]->attr('content');
		my $lon = ($tree->findnodes('//meta[@property="place:location:longitude"]'))[0]->attr('content');
		
		my $kudos = ($tree->findnodes('//body[@data-kudos]'))[0]->attr('data-kudos');
		
		my $numroutes=$tree->findvalue('//a[@title="Search and filter these routes"]');
		$numroutes = substr($numroutes,1,(index($numroutes,'routes')-2));
		
		my $paragraph = "";
		my $generalstyle = $tree->findvalue('//h1[@class="inline"]/small');
		$generalstyle =~ s/^\s+//g;
		my @summaryinfo= $tree->findnodes('//div[@class="node-info summary"]');
		my @descriptioninfo= $tree->findnodes('//div[@class="node-info description"]');
		if($#summaryinfo == 0){
			my @summary= $summaryinfo[0]->findvalues('div/div/p');
			for my $i (0 .. $#summary){
				$paragraph .= ($summary[$i] . "<br>");
			}
		}
		if($#descriptioninfo == 0){
			my @description = $descriptioninfo[0]->findvalues('div/div/p');
			$paragraph .= ($description[0]);
			if($#description>0) {
				$paragraph =~ s/.$//;
				$paragraph .= "...";
			}
		}
		$paragraph =~ s/<br>$//;
		if($paragraph eq "") 
		{
			my $definition = ($tree->findnodes('//meta[@property="og:description"]'))[0]->attr('content');
			$definition = substr($definition, index($definition, $place)+length($place)+2);
			$paragraph = ucfirst($definition);
		}
		$paragraph = "$generalstyle<br>Number of Routes: $numroutes<br>Region: <a href=\"$parenturl\">$parent</a><br><br>$paragraph";
		
		my $typelabel = $type;
		if($supertype eq 'crag')  {$typelabel = "subarea";}
		
		my $mapjs = $response->decoded_content;
		$mapjs =~ s/[ \n]//g;
		my $boundary = "";
		if ($mapjs =~ m/varboundary(.*?);/) {$boundary = $1;}
		if ($boundary =~ m/geometry:(.*?),cen/) {$boundary=$1;}
		
		print MAP <<EOH
//$place
DDG.duckbar.add_map([{"licence":"Data \\u00a9 OpenStreetMap contributors, ODbL 1.0. http:\\\/\\\/www.openstreetmap.org\\\/copyright","osm_type":"relation", "polygonpoints":$boundary, "lat":$lat, "lon":$lon, "class":"boundary", "type":"administrative","importance":0.73982781390695, "icon":"http:\\\/\\\/open.mapquestapi.com\\\/nominatim\\\/v1\\\/images\\\/mapicons\\\/poi_boundary_administrative.p.20.png"}])
EOH
;
		
		
		print OUT <<EOH
<doc>
<field name="title"><![CDATA[$place]]></field>
<field name="l2_sec_match2">climb $styleinfo</field>
<field name="paragraph"><![CDATA[$paragraph]]></field>
<field name="source"><![CDATA[climb]]></field>
<field name="meta"><![CDATA[{"url":"$url", "lat":"$lat", "lon":"$lon", "kudos" ="$kudos", "type"="$typelabel" }]]></field>
</doc>
</add>
EOH
;
		
		my @areas = $tree->findnodes('//div[@class = "area"]' );
		if(($type eq 'crag') and !($supertype eq 'crag')) {
			foreach my $i (0..$#areas){
				my $link  = ($areas[$i]->findnodes('div/a[@href]'))[1]->attr('href');
				crawl($site . $link, $type,$place, $url);
			}
		}
	}
	else{
		my @areas = $tree->findnodes('//div[@class = "area"]' );
		foreach my $i (0..$#areas){
				my $link  = ($areas[$i]->findnodes('div/a[@href]'))[1]->attr('href');
				unless($link eq "/climbing/world/area/11737939"){
					crawl($site . $link, $type,$place, $url);
				}
		}
	}
	
	$tree->delete();
   };
