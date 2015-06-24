#!/usr/bin/env perl

use JSON qw(from_json to_json);
use File::Slurp 'read_file';

my $output_file = 'output.xml';

# provide default keywords for each cheat sheet
my $additional_keywords = join(' ', ' char', 'character', 'cheat sheet', 'cheatsheet', 'command', 'example', 'guide', 'help', 'quick reference', 'shortcut', 'symbol');

MAIN:{
	open my $output, '>:utf8', $output_file or die "Failed to open $output_file: $!";

	print $output qq|<?xml version="1.0" encoding="UTF-8"?>\n<add allowDups="true">|;
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

		print $output "\n", join("\n",
            qq{<doc>},
            qq{<field name="title"><![CDATA[$cs->{name}]]></field>},
            qq{<field name="l2_sec_match2"><![CDATA[$keywords]]></field>},
            q|<field name="meta"><![CDATA[{"cheat_sheet":"| . to_json($cs) . q|"}]]></field>|,
            qq{</doc>});
	}
	print output "\n</add>";
}
