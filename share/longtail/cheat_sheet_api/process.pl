#!/usr/bin/env perl

use JSON qw(from_json to_json);
use File::Slurp 'read_file';

my $output_file = 'output.json';
my $pretty_json = 1;

# provide default keywords for each cheat sheet
#my $additional_keywords = join(' ', ' char', 'character', 'cheat sheet', 'cheatsheet', 'command', 'example', 'guide', 'help', 'quick reference', 'shortcut', 'symbol');

MAIN:{

	my @jdocs;
    while(my $f = <json/*.json>){
        my $j = read_file($f, binmode => ':utf8');
        my $cs = from_json($j);
        my $keywords = delete $cs->{keywords};
        die "No keywords specified in $f" unless $keywords;
        #$keywords .= $additional_keywords;
        #my %k; # de-dupe and normalize
        #for my $kw (split /\s+/, $keywords){
        #    ++$k{$kw};
        #}
        #$keywords = join(' ', keys %k);
		my %text_fields;
		my $i = 0;
		while(my ($h, $s) = each %{$cs->{sections}}){
			for my $cheat (@$s){
				my ($k, $v) = @$cheat{qw(key value)};
				if($k){
					$text_fields{++$i . '_text'} = $k;
					$text_fields{++$i . '_text_punctuation_removed'} = $k;
				}
				if($v){
					$text_fields{++$i . '_text'} = $v;
					$text_fields{++$i . '_text_punctuation_removed'} = $v;
				}
			}
		}

		push @jdocs, {
			title => $cs->{name},
			l2_sec_match2 => $keywords,
			%text_fields,
			source => 'cheat_sheet_api',
			meta => to_json({cs => $cs})
		};
    }
    open my $output, '>:utf8', $output_file or die "Failed to open $output_file: $!";
	print $output to_json(\@jdocs, {pretty => $pretty_json});
}
