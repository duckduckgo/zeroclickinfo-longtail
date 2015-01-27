#!/usr/bin/perl

use strict;
use warnings;

use JSON qw/ encode_json /;
use HTML::TreeBuilder::XPath;

my $site = "http://www.thecrag.com";
my $start = "http://www.thecrag.com/climbing/world";
my $data;

crawl($start);

open my $fh, ">", "climbing.json";
print $fh encode_json($data);
close $fh;

sub crawl{
	my $url = @_[0];
	my $tree = HTML::TreeBuilder::XPath->new_from_url($url);
	$tree->eof();
	my $place = $tree->findvalue('//span[@class= "inner" ]');

	$data->{$place}->{"url"}=$url;

	my $type = $tree->findvalue('//a[@href="/article/AreaTypes"]');
	$data->{$place}->{"type"}=$type;
	
	my @breadcrumbs = $tree->findvalues('//div[@id="breadCrumbs"]/ul/li');
	foreach my $i(1..$#breadcrumbs){
		$data->{$place}->{"breadcrumbs"}->[$i-1] = $breadcrumbs[$i];
		}

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
	unless (($type eq 'crag')==1) {
		foreach my $i (0..$#areas){
			my $link = $data->{$place}->{'areas'}->[$i]->{'link'};
			crawl($site . $link);
		}
	}

	$tree->delete();
   };
