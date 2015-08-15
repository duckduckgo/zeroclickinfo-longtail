#!/usr/bin/env perl

use JSON qw(from_json to_json);
use File::Slurp 'read_file';

my $output_file = 'output.json';
my $pretty_json = 1;

# provide default keywords for each cheat sheet
my $additional_keywords = join(' ', ' char', 'character', 'cheat sheet', 'cheatsheet', 'command', 'example', 'guide', 'help', 'quick reference', 'shortcut', 'symbol');

MAIN:{

	my @jdocs;
    while(my $f = <json/*.json>){
        my $j = read_file($f, binmode => ':utf8');
        my $cs = from_json($j);
        my $keywords = delete $cs->{keywords};
        die "No keywords specified in $f" unless $keywords;
        $keywords .= $additional_keywords;
        my %k; # de-dupe and normalize
        for my $kw (split /\s+/, $keywords){
            ++$k{$kw};
        }
        $keywords = join(' ', keys %k);

		push @jdocs, {
			title => $cs->{name},
			l2_sec_match2 => $keywords,
			paragraph => to_json($cs),
			source => 'cheat_sheet_api'
		};
    }
    open my $output, '>:utf8', $output_file or die "Failed to open $output_file: $!";
	print $output to_json(\@jdocs, {pretty => $pretty_json});
}
