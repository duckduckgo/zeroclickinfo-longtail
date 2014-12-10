#!/usr/bin/env perl

use File::Slurp 'read_file';
use YAML::XS 'LoadFile';
use Text::Autoformat;
use Data::Dumper;

use strict;

# can be overridden on command-line
my $verbose = 0;
my $data_dir = 'download';
my $ayi_dir = 'ashtanga.info';
my $yc_file = 'yoga.com.yaml';
my $output_file = 'output.xml';

binmode(STDOUT, ":utf8");

my (@docs, %skip);
parse_argv();


unless(exists $skip{ayi}){
	while(my $f = <$data_dir/$ayi_dir/*>){
		next if $f =~ /-\d+\.html$/o;
		my $htm = read_file( $f, binmode => ':utf8' ) ;
		my ($src, $practice, $asana, $sasana, $img, $trans);
		if($f =~ /surya-namaskara/o){
			if(($src, $practice, $asana, $sasana, $trans, $img) = 
				$htm =~ m{
				--\s+source:\s+(\S+/practice/([^/]+)/\S+)\s+--(?s:.+)
				<h1>(?'asana'[^<]+)</h1>.+?
				class="uniHeader">([^<]+)</h3>.+?
				<h2>([^<]+)</h2>(?s:.+)
				<img\s+src="([^"]+)".+<em>\g{asana}
			}ox){
				if($asana =~ /(\s[AB])$/o){
					$trans .= $1;
				}
				else{
					die "Failed to extract variation from $asana";
				}
			}
			else{
				die "Failed to extract information from $f";
			}
		}
		elsif(($src, $practice, $asana, $sasana, $img) = 
			$htm =~ m{
			--\s+source:\s+(\S+/practice/([^/]+)/\S+)\s+--(?s:.+)
			<h1>(?'asana'[^<]+)</h1>(?s:.+)
			class="uniHeader">([^<]+)<(?s:.+)
			<img\s+src="([^"]+)"\s+width="\d+"\s+height="\d+"\s+alt="\g{asana}"\s+> 
		}ox){
			$asana =~ s/\bMukah\b/Mukha/o; # sic
			my @aps = split /\s+/, $asana;
	
			# all of these are to extract the translation
			if($asana =~ /^Baddha\s+Hasta\s+Shirshasana/o){
				$aps[0] = 'Mukta'; # wrong
			}
			elsif($asana =~ /^Dvi\s+Pada\s+Shirshasana/o){
				$aps[0] = 'Eka'; # wrong
			}
			elsif($asana eq 'Kaundinyasana A'){
				$aps[0] = 'Koundinyasana'; # sic
			}
			elsif($asana =~ /^Prasarita\s+Padottanasana/o){
				$aps[0] = 'Parasarita'; # sic
			}
			elsif($asana =~ /^Supta\s+Trivikramasana/o){
				$aps[1] = 'Trivikrimasana'; # sic
			}
			elsif($asana =~ /Urdhva\s+Dandasana/){
				@aps = ('Shirshasana'); # wrong
			}
			elsif($asana eq 'Vatayanasana'){
				$aps[0] = 'Vatayasana'; # sic
			}
			elsif($asana =~ /^Viranchyasana/o){
				$aps[0] = 'Viranchhyasana'; # sic
			}
			
			# Really don't like having to search the document twice but there
			# are inconsistencies in the spacing of the asana, whether it has
			# A/B/C/D for variants, etc.
			my $trans_re;
			if($aps[-1] =~ /^[A-Z]$/o){
				my $var = pop @aps;
				$trans_re = join('\s+', @aps) . "(?:\\s+$var)?";	
			}
			else{
				$trans_re = join('\s+', @aps);
			}
			unless($htm =~ m{<p>.+<b>$trans_re</b>.+\)\s+(?:=\s+)?(.+?)</p>}){
				warn "Failed to extract translation from $src: '<p>.+<b>$trans_re</b>.+\)\s+(?:=\s+)?(.+?)</p>'\n";
			}
			$trans = $1;
			$trans =~ s{<b>([^<]+)</b>\s*\([^,]+,\s*([^)]+)\)}{$1/$2};
		}
		else{
			warn "Failed to extract values from $f";
		}
	
		for ($asana, $sasana, $trans, $practice){ 
			s/-/ /og;
			tr/ //s; 
		}
	
		my $desc = $trans;
		unless($desc =~ /pose|posture/oi){
			$desc .= ' Posture';
		}
	
		push @docs, {
			title => $asana,
			l2sm => "$trans $sasana $practice",
			pp => autoformat($desc, {case => 'title'}),
			img => $img,
			meta => $src
		};
	}
}

unless(exists $skip{yc}){
	my $ycom = LoadFile("$data_dir/$yc_file");
	while(my ($asana, $data) = each %$ycom){
		push @docs, {
			title => $asana,
			l2sm => $data->{title},
			pp => $data->{title},
			img => $data->{img},
			meta => $data->{src}
		};
	}
}

# Output the articles
open my $output, '>:utf8', $output_file or die "Failed to open $output_file: $!";

print $output <<ENDOFXMLHDR;
<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
ENDOFXMLHDR

for my $d (@docs){
		
	my ($title, $l2sm, $pp, $img, $meta) = @$d{qw(title l2sm pp img meta)};
	$l2sm =~ s{/}{ }og;

    print $output "\n", join("\n", 
		qq{<doc>}, 
		qq{<field name="title"><![CDATA[$title]]></field>},
		qq{<field name="l2_sec_match2"><![CDATA[$l2sm]]></field>},
		qq{<field name="paragraph"><![CDATA[$pp<br />[[Image:$img]]]]></field>},
		qq{<field name="source"><![CDATA[YogaPosture]]></field>}, 
		qq{<field name="meta"><![CDATA[{"url":"$meta"}]]></field>},
		qq{</doc>});
}

print $output "\n</add>";

# command-line options
sub parse_argv {
    my $usage = <<ENDOFUSAGE;

    *******************************************************************
        USAGE: parse.pl [-data path/to/data] [-output path/to/output]
               [-v]

        -data: (optional) path to the downloaded zip file
        -output: (optional) path to output.txt file
        -no_ayi/yc: (optional) turn off download of ashtanga.info or 
           yoga.com
        -v: (optional) Turn on some parse warnings

    *******************************************************************

ENDOFUSAGE

    for(my $i = 0;$i < @ARGV;$i++) {
        if($ARGV[$i] =~ /^-data$/o) { $data_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-output$/o) { $output_file = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/o) { $verbose = 1; }
        elsif($ARGV[$i] =~ /^-no_(\w+)$/o) { ++$skip{$1} }
    }
}
