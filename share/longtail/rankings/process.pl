#!/usr/bin/env perl

use Data::Printer;
use WWW::Mechanize; 
use Mojo::DOM;
use Mojo::URL;
use HTML::TableExtract;
use File::Copy::Recursive 'pathmk';
use PerlIO::gzip;
use JSON 'to_json';

use strict;
no warnings 'uninitialized';

use constant SUCCESS => 1;
use constant FAILURE => 0;

my $data_dir = 'data';
my $output_file = 'output';
my $verbose = 0;
my (@skip, @only);
my $pretty_json = 0;
my $json_output = 1;

# Alphabetical order please!
my %ranking_sites = (
    imdb_top_250 => \&imdb_top_250 # weekly
);

my $mech = WWW::Mechanize->new;

MAIN:{
	parse_argv();
	process_rankings();
}

sub process_rankings{
	my @results;	
	while(my ($rank_name, $ranker) = each %ranking_sites){
		$verbose && warn "Processing $rank_name\n";
		if(my $results = $ranker->($rank_name)){
			push @results, $results;
		}
	}
	if(@results){
		$json_output ? create_json(\@results) : create_xml(\@results);
	}
}

sub imdb_top_250 {
	my $name = shift;
	my $url = 'http://www.imdb.com/chart/top?sort=rk,asc&mode=simple';
	my $htm = mirror_site($name => $url);
	my $t = extract_table($htm, keep_html => 1, headers => ['', 'Rank & Title']);
	my @rankings;
	for my $rank (@$t){
		my $d = Mojo::DOM->new($rank->[0]);
		my $img = $d->at('img')->attr('src');
		unless($img){
			warn "Failed to extract $name img";
			return;
		}
		my $src = $d->at('a')->attr('href');
		my $abs_src = Mojo::URL->new($src)->to_abs(Mojo::URL->new($url))->to_string;
		unless($abs_src){
			warn "Failed to extract $name src url";
			return;
		}
		my $text = $d->parse($rank->[1])->all_text;
		unless($text =~ /^(\d+)\.\s+(\S.+)$/){
			warn "Failed to extract rank and title from $name:\n\n\t$text";
			return;;
		}
		my ($r, $title) = ($1, $2);
		push @rankings, {
			rank => $r,
			item => $title,
			img => $img,
			src => $src
		};
	}
	return {
		title => 'imdb movies 250',
		rankings => \@rankings
	}
}

sub mirror_site {
    my ($name, $url) = @_;
    	
   	my $archive = "$data_dir/$name";
 	my $res = $mech->mirror($url, $archive);
    unless($res->is_success || $res->code == 304){
            $verbose && warn "Failed to download $name ranking: " . $res->status_line;
    }
   
    # if we have a binary file, use gzip (preferred), otherwise a normal read (legacy)
    my $open_arg = -B $archive ? '<:gzip' : '<';
    open my $fh, $open_arg, $archive or die "Failed to open file $archive: $!";
    # slurp into a single string
    my $htm = do { local $/;  <$fh> };
 	return \$htm;
}

sub prime_mech {
	my ($name, $url) = @_;

	my $res = $mech->get($url);
    unless($res->is_success){
            $verbose && warn "Failed to download $name ranking: " . $res->status_line;
			return;
    }
	$mech->save_content($name, qw{binmode :raw decoded_by_headers 1}); 
}

# Extract a table from a page
sub extract_table {
    my ($htm, %opts) = @_;

    my $te = HTML::TableExtract->new(%opts);
    $te->parse($$htm);
    my ($ts) = $te->table_states;
    unless($ts){
       warn 'No table found in document using options: ', join(', ', %opts);
       return FAILURE;
    }
    return [$ts->rows];
}

# Dump the coordinates of all tables to find out which one you need
sub dump_tables {
    my $htm = shift;

    my $te = HTML::TableExtract->new;
    $te->parse($$htm);

	for my $ts ($te->table_states) {
        print "Table (", join(',', $ts->coords), "):\n";
        for my $r ($ts->rows) {
           print join(',', @$r), "\n";
        }
    }
}

sub create_xml {
	my $docs = shift;

    # Output the articles
    open my $output, '>:utf8', "$output_file.xml" or die "Failed to open $output_file: $!";

    print $output qq|<?xml version="1.0" encoding="UTF-8"?>\n<add allowDups="true">|;

    for my $d (@$docs){

        my ($title, $rankings) = @$d{qw(title rankings)};

        print $output "\n", join("\n",
            qq{<doc>},
            qq{<field name="title"><![CDATA[$title]]></field>},
            q{<field name="source"><![CDATA[rankings_api]]></field>},
            q{<field name="meta"><![CDATA[} . to_json($rankings) . q{]]></field>},
            '</doc>');
    }
    print $output "\n</add>";
}

sub create_json {
	my $docs = shift;

    my @jdocs;# = (add => {allowDups => 'true'});

    for my $d (@$docs){

        my ($title, $rankings) = @$d{qw(title rankings)};

        my %doc = (
            title => $title,
            source => 'rankings_api'
        );

        $doc{meta} = to_json($rankings, {pretty => $pretty_json});
        push @jdocs, \%doc;
    }

    # Output the articles
    open my $output, '>:utf8', "$output_file.json" or die "Failed to open $output_file: $!";
    print $output to_json(\@jdocs, {pretty => $pretty_json});
}

# command-line options
sub parse_argv {
    my $usage = <<ENDOFUSAGE;

    *******************************************************************
        USAGE: process.pl [-data path/to/data] [-out] [-skip] [-only]
		           [-v] [-p] [-xml] [-h]

		All arguments below are OPTIONAL:

        -data: Path to the download directory (default: data/)
		-out:  Name of output file.  Extension will be added (default: output)
        -skip: Selectively turn off processing of site(s).
		       Multiple sites can be specified separated by spaces.
		-only: Only process the following site(s). Separate
		       multiple sites with spaces.
        -v:    Turn on some parse warnings (default: off)
        -p:    Output json prettified (defaults: minified)
        -xml:  Output in XML (default: JSON)
        -h:    Print this usage

    *******************************************************************

ENDOFUSAGE

    for(my $i = 0;$i < @ARGV;$i++) {
        if($ARGV[$i] =~ /^-data$/o) { $data_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/o) { $verbose = 1; }
        elsif($ARGV[$i] =~ /^-out$/o) { $output_file = $ARGV[++$i]; }
        elsif($ARGV[$i] =~ /^-skip/o) {
			while(defined $ARGV[$i+1] && $ARGV[$i+1] !~ /^-/){
				push @skip, $ARGV[++$i];
			}
	    }
        elsif($ARGV[$i] =~ /^-only/o) {
			while(defined $ARGV[$i+1] && $ARGV[$i+1] !~ /^-/){
				push @only, $ARGV[++$i];
			}
	    }
        elsif($ARGV[$i] =~ /^-p$/o) { $pretty_json = 1 }
        elsif($ARGV[$i] =~ /^-xml$/o) { $json_output = 0 }
        elsif($ARGV[$i] =~ /^-h$/o) { print $usage; exit; }
    }

	if(@skip && @only){
		die 'Specify either -skip or -only but not both!';
	}
	elsif(@only){
		my %tmp;
		@tmp{@only} = @ranking_sites{@only};
		%ranking_sites = %tmp;
	}
	elsif(@skip){
		delete @ranking_sites{@skip}
	}
	pathmk($data_dir) or die "Failed to mkdir $data_dir: $!";
}
