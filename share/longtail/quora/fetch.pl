#!/usr/bin/env perl
# fetch quora data and put in sqlite DB
#

use strict;
use warnings;
use DBI;
use Mojo::DOM;
use Data::Dumper;
use IO::All;
use LWP::Simple;

#my $dbh = DBI->connect("dbi:SQLite:dbname=quora","","");
my $base_url = "http://www.quora.com/sitemap/questions?page_id=1";
my $html = get($base_url);
my $dom = Mojo::DOM->new($html);

# get the links from the sitemap
my @links = get_sitemap_page_links($dom);

foreach my $link (@links){
	my $html = get($link);

	next if $link =~ m/questions\?page_id=/;

}




# returns an array of links for a page on the sitemap
sub get_sitemap_page_links {
	my $page = shift;
	my @links = ();
	
	$page->find('a[href]')->each ( sub{
		push(@links, $_->{href});
	});
	
	return @links;
}
