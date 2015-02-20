#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use FindBin;
use lib $FindBin::Dir. "/../../../../../../usr/local/ddg/lib/";
use DDG::Util::Crawl qw( get_url_content );
use Mojo::DOM;
use Data::Dumper;
use IO::All;
use Parallel::ForkManager;

$dbh->do("DROP TABLE IF EXISTS quora");
$dbh->do("CREATE TABLE quora (title text NOT NULL, abstract text NOT NULL, url text NOT NULL, want int NOT NULL, upvote int NOT NULL, date timestamp NOT NULL)");

my $ua_agent = 'DuckDuckBot/1.1; (+http://duckduckgo.com/duckduckbot.html';
my $out = IO::All->new("output.txt");
my $base_url = "http://www.quora.com/sitemap/questions?page_id=";
my $parent_pid = $$;
my $WANT_ANS_CUTOFF = 3;
my $ANS_COUNT_CUTOFF = 1;
my $UPVOTE_CUTOFF = 3;
my $page = 1;
my $last_page = 0; # first child to find the last page sets this flag
# get the links from the sitemap

my $pool = Parallel::ForkManager->new(3);

$out->print(qq(<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">));

while(!$SIG{INT}){

	$pool->start and $page++ and next;
		# child process here
		my $url = $base_url.$page;
		print "getting page $url\n";
		my $html = get_url_content($url, 20, $ua_agent);
		my $dom = Mojo::DOM->new($html);
		my @site_map_links = get_sitemap_page_links($dom);
		#print Dumper @site_map_links;
		process_links(@site_map_links);
		kill 2, $parent_pid if $page > 20;
	$pool->finish;

}
$pool->wait_all_children;

$out->print(qq(</add>));

sub process_links {
	my @links = @_;

	foreach my $link (@links){

		my $html = get_url_content($link, 10, $ua_agent);

		my ($title, $q_text, $abstract, $want_ans, $ans_count, $ans_upvotes) = '';

		my $page = Mojo::DOM->new($html);

		# looks for last page and sets status flag
		$page->find('h1')->each( sub{
			if($_->text && $_->text eq "Page Not Found"){
				kill 2, $parent_pid;
				return;
			}
		});

		$page->find('span.count')->each( sub{
			if($_->parent->text  && $_->parent->text eq "Want Answers"){
				$want_ans = $_->text if $_->text;
			}
		});
	
		next if $want_ans < $WANT_ANS_CUTOFF;

		$page->find('div.answer_count')->each( sub{
			if($_->text && $_->text =~ /(\d+)\sAnswers/){
				$ans_count = $1;	
			}
		});

		next unless $ans_count && $ans_count > $ANS_COUNT_CUTOFF;

		# title for the page (short question text)
		$page->find('h1')->each( sub{
			$title = $_->text if $_->text;
		});

		# get the content of the question
		$page->find('div.question_details_text')->each( sub{
				$q_text = $_->text if $_->text;
		});


		# search inside top Answer
		$page->find('div.Answer')->each( sub{
		
			#get the abstract text	
			$_->find('div[id$=_container]')->each( sub{
				$abstract = $_->text if $_->text;
				last;
			});

			# get upvotes for this post
			$_->find('div.primary_item')->each( sub{
				$_->find('span.count')->each( sub{
					$ans_upvotes = $_->text if $_->text;
				});
			});

		});

		next if $ans_upvotes < $UPVOTE_CUTOFF;

		print "Title: $title Want: $want_ans Score: $ans_count \nAbstract: $abstract\nURL: $link\n\n";

		update_DB($title, $q_text, $abstract, $link, $want_ans, $ans_upvotes);
	}
}

# returns an array of links for a page on the sitemap
sub get_sitemap_page_links {
	my $page = shift;
	my @links = ();
	
	$page->find('a[href]')->each ( sub{
			
		if(my $remainder = $_->{href} =~ m/http:\/\/www\.quora\.com\/(.*?)/){
			next unless $remainder;
			next if $remainder  =~ m/(?:questions\?page_id=)|(?:#)/;
			push(@links, $_->{href});
		}
		
	});
	
	return @links;
}

# print doc to output file
sub update_DB {
	my ($title, $q_text, $abstract, $url, $want, $upvote) = @_;
    $title =~ s/\?//g;

    $dbh->do("INSERT INTO quora (title, abstract, url, want, upvote,  date) VALUES(?,?,?,?,?,?)", undef, $title, $abstract, $url, $want, $upvote, '20120302');

    if($dbh->errstr){
        warn $dbh->errstr;
        warn "$title\t$url";
    }
}
