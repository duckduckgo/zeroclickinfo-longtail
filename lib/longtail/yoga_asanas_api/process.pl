#!/usr/bin/env perl
   
use WWW::Mechanize; 
use File::Path 'make_path';
use File::Slurp qw'read_file write_file';
use YAML::XS 'Load';
use HTML::TableExtract;
use Text::Autoformat;
use JSON qw'to_json';
use Data::Printer;

use strict;

my $data_dir = 'download';

# sources
my $ayi_url = 'http://www.ashtangayoga.info/practice/';
my $ayi_dir = 'ashtanga.info';

my $yc_url = 'https://yoga.com/api/content/feed/?format=json&type=pose&offset=0&limit=500';
my $yc_file = 'yoga.com.yaml';

my $yp_url = 'http://www.theyogaposes.com/';
my $yp_dir = 'theyogaposes';

# Our output file, gets .json or .xml added to it
my $output_file = 'output';

my $pretty_json = 0;
my $xml_output = 0;

# Common variation alternatives
my %variations = (A => 'I', B => 'II', C => 'III', D => 'IV');

# A single http client
my $m = WWW::Mechanize->new(agent => 'Mozilla/5.0 (X11; FreeBSD amd64; rv:30.0) Gecko/20100101 Firefox/30.0');

my (%skip, $verbose, @docs);

MAIN:{
    parse_argv();
    process_ayi() unless $skip{ayi};
    process_yc() unless $skip{yc};
    process_yp() unless $skip{yp};
    #create_xml();
    $xml_output ? create_xml() : create_json();
}


sub process_ayi {

    my $archive = "$data_dir/$ayi_dir";
    make_path($archive);

    my $r = $m->get($ayi_url);

    my $practice_links = $m->find_all_links(url_regex => qr{http://www\..+/practice/\w[^/]+/$});

    my %seen;

    my $order = 0;

    for my $pl (@$practice_links){
        my $url = $pl->url;
        next if $seen{$url}++ || ($url =~ /mp3|pdf/i);

        my $r = $m->get($url);

        unless($url =~ m{/([^/]+)/$}){
            die "Failed to extract practice from $url";
        }
        my $p = $1;

        unless($r->decoded_content =~ m{<h3 class="uniHeader">([^<]+)</h3>}){
            $verbose && warn "Failed to extract Sanskrit practice from $url";
        }
        my $sp = $1;
        $sp = join(' ', $sp, split('-', $sp)) if $sp =~ /-/;
        my $practice = join(' ', split('-', $p), $sp);

        my $links = $m->find_all_links(url_regex => qr{http://www\..+/practice/$p/item/[^/]+/$});

        for my $l (@$links){
            next if $l->text =~ /\[thumb\]/;
            my $url = $l->url;
            #next if $url =~ m{-\d+/$}o; # unnamed transition postures
            unless($url =~ m{/([^/]+)/$}o){
                die "Failed to extract asana from $url";
            }
            my $asana = $1;
            ++$order;
            my $file = "$archive/" . sprintf('%03d', $order) . "-${p}_$asana.html";

            unless(-e $file){
                $verbose && warn "\tGetting ", $l->url, ' (text: ', $l->text, ")\n";
                my $res = eval { $m->get($l) } or do { warn $@; next };
                $verbose && warn "\tSaving $file\n";
                write_file($file, {binmode => ':utf8'}, $res->decoded_content);
            }

            if(my $htm = read_file( $file, binmode => ':utf8' )){
                parse_ayi($practice, $url, $htm, $order);
            }
        }
    }
}

sub process_yc {
    my $r = $m->get($yc_url);
    my $yc_data = Load($r->decoded_content);
    $m->get('https://yoga.com/pose/downward-facing-dog-pose');
    my $l = $m->find_link(url_regex => qr{\.cloudfront\.net/static});
    my $iurl = $l->url;
    unless($iurl =~ m{^https?://([^/]+)}i){ # images appear to work both with and without SSL
        die "Failed to extract cloudfront image server from url $iurl";
    }
    my $imgsrv = $1;

    my (%out, $img_verified, $src_verified);
    for my $a (@{$yc_data->{payload}{objects}}){
        my $imgurl = 'http://' . $imgsrv . $a->{photo};
        unless($img_verified){ # basic check that our link composition still works
            my $r = $m->get($imgurl);
            ++$img_verified;
        }
        my $srcurl = join('/', 'https://yoga.com/pose', $a->{slug});
        unless($src_verified){ # basic check that our source link format still works
            my $r = $m->get($srcurl);
            ++$src_verified;
        }
        if(exists $out{$a->{sanskrit_name}}){ # should be unique; if not, let's check it out
            $verbose && warn $a->{sanskrit_name}, " already exists\n";
            next;
        }
        my $title = $a->{title};
        push @docs, {
            title => $a->{sanskrit_name},
            l2sm => $title,
            pp => $title,
            img => $imgurl,
            src => $srcurl,
            pcount => 1000,
            srcname => 'Yoga.com',
            favicon => 1 
        };
    }
}

sub process_yp {
    my $archive = "$data_dir/$yp_dir";
    make_path($archive);

    my $res = $m->get($yp_url);
    my $h = $res->decoded_content;
    my $te = HTML::TableExtract->new(keep_html => 1,
        headers => [
            'Sanskrit Name for Yoga Poses, Postures and Asanas',
            'English Name for Yoga Poses, Postures and Asanas'
    ])->parse($h);

    my ($url_re, $img_re, $cs_re, $fname_re) = (
        qr{href="(http[^"]+)">([^<]+)<},
        qr{<img\s+src='([^']+.jpg)'},
        qr{cs\.php$},
        qr{input_page=(.+)$}
    );
    for my $r ($te->rows){
        unless($r->[0] =~ $url_re){
            die "Failed to extract source/name from $r->[0]";
        }
        my ($src, $title) = ($1, $2);

        unless($r->[1] =~ $url_re){
            die "Failed to extract translation from $r->[1]";
        }
        my ($alt_src, $trans) = ($1, $2);

        if( ($title eq 'Natarajasana') && ($trans =~ /II$/) ){
            $title = 'Natarajasana II';
        }

        if($src =~ $cs_re){
            unless($alt_src !~ $cs_re){
                warn "Failed to verify src link for $title";
                next;
            }
            $src = $alt_src
        }
        unless($src =~ $fname_re){
            die "Failed to extract asana file name from $src";
        }
        my $file = "$archive/$1.html";

        unless(-e $file){
            $verbose && warn "\tGetting $src\n";
            my $res;
            eval { $res = $m->get($src) } or do {
                $src = $alt_src;
                $res = $m->get($src);
            };

            $verbose && warn "\tSaving $file\n";
            write_file($file, {binmode => ':utf8'}, $res->decoded_content);
        }

        die "Failed to read $file: $!" unless my $htm = read_file( $file, binmode => ':utf8' );

        unless($htm =~ $img_re){
            die "Failed to extract image from $src";
        }

        my $img = $1;

        push @docs, {
            title => $title,
            l2sm => $trans,
            pp => $trans,
            img => $img,
            src => $src,
            pcount => 1000,
            srcname => 'The Yoga Poses',
            favicon => 0
        };
    }
}

# command-line options
sub parse_argv {
    my $usage = <<ENDOFUSAGE;

    *******************************************************************
        USAGE: process.pl [-data path/to/data] [-no_*] [-v]

        -data: (optional) path to the download directory
        -no_*: (optional) turn off download of a site:
          ayi: ashtanga.info 
           yc: yoga.com
           yp: theyogaposes.com 
        -v: (optional) Turn on some parse warnings
        -h: (optional) print this usage
        -p: (optional) output json prettified (default = 0)
        -xml: (optional) output in XML (default is json)

    *******************************************************************

ENDOFUSAGE

    for(my $i = 0;$i < @ARGV;$i++) {
        if($ARGV[$i] =~ /^-data$/o) { $data_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/o) { $verbose = 1; }
        elsif($ARGV[$i] =~ /^-no_(\w+)$/o) { ++$skip{$1} }
        elsif($ARGV[$i] =~ /^-h$/o) { print $usage; exit; }
        elsif($ARGV[$i] =~ /^-p$/o) { $pretty_json = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-xml$/o) { ++$xml_output }
    }
}

# Process ashtangayoga.info
sub parse_ayi {
    my ($practice, $src, $htm, $order) = @_;

    my ($asana, $sasana, $img, $trans);
    # This is for processing the sun salutations as a single entity, e.g
    # http://www.ashtangayoga.info/practice/surya-namaskara-a-sun-salutation/opt/info/
#    if($src =~ m{surya-namaskara.+/opt/info}o){
#        if(($asana, $sasana, $trans, $img) =
#            $htm =~ m{
#            <h1>(?'asana'[^<]+)</h1>.+?
#            class="uniHeader">([^<]+)</h3>.+?
#            <h2>([^<]+)</h2>(?s:.+)
#            <img\s+src="([^"]+)".+<em>\g{asana}
#        }ox){
#            if($asana =~ /(\s[AB])$/o){
#                $trans .= $1;
#            }
#            else{
#                die "Failed to extract variation from $asana";
#            }
#        }
#        else{
#            die "Failed to extract information from $src";
#        }
#    }
    if(($asana, $sasana, $img) =
        $htm =~ m{
        <h1>(?'asana'[^<]+)</h1>.+?
        class="uniHeader">.+?class="tx-sgtransliterator-cakravat-font">([^<]+)<(?s:.+)
        <img\s+src="([^"]+)"\s+width="540"   # \g{asana}"\s+>
    }ox){
        $asana =~ s/\bMukah\b/Mukha/o; # sic
        my @aps = split /\s+/, $asana;

        # all of these are to extract the translation
        if($asana =~ /^Baddha\s+Hasta\s+Shirshasana/o){
            $aps[0] = 'Mukta'; # wrong
        }
        elsif($asana =~ /^Dvi\W+Pada\s+Shirshasana/o){
            $aps[0] = 'Eka-Pada'; # wrong
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
        elsif($asana =~ /^Kaundinyasana\s+\[A\]/){
            $aps[0] = 'Koundinyasana'; # sic
        }

        # Really don't like having to search the document twice but there
        # are inconsistencies in the spacing of the asana, whether it has
        # A/B/C/D for variants, etc.
        my $trans_re;
        if($aps[-1] =~ /^\[?[A-D]\]?$/o){
            my $var = pop @aps;
            $trans_re = join('\W+', @aps) . "(?:\\s+\Q$var\E)?";
        }
        elsif($aps[-1] eq '["]'){
            pop @aps;
        }

        $trans_re //= join('\W+', @aps);

        unless($htm =~ m{<p>.+<b>$trans_re</b>.+\)</span>\s+(?:=\s+)?(.+?)</p>}){
            die "Failed to extract translation from $src";
        }
        $trans = $1;

        $trans =~ s{<b>([^<]+)</b>\s*\([^,]+,\s*([^)]+)\)}{$1/$2};
    }
    elsif((($asana, $img) =
        $htm =~ m{
        <h1>(?'asana'[^<]+)</h1>(?s:.+)
        <img\s+src="([^"]+)"\s+width="\d+"\s+height="\d+"\s+alt="\g{asana}"\s+>
    }ox) || (($img) = $htm =~ m{<img\s+src="([^"]+)"\s+width="\d+"\s+height="\d+"\s+alt=""\s+>})){
        #transitional, unnamed postures that only show up in sequences
        push @docs, {
            title => ' ',
            l2sm => "ashtanga vinyasa $practice",
            pp => '(transitional)',
            img => $img,
            src => $src,
            srcname => 'AYI',
            favicon => 1,
            pcount => $order
        };
        return;
    }
    else{
        die "Failed to extract values from $src";
    }

    my $pcount = $order;

    for ($asana, $trans){
        s/-/ /og;
        tr/ //s;
    }

    # the sanskrit doesn't have the variation usually
    if($asana =~ /\s([A-D])$/o){
        my $var = $1;
        $sasana .= " $var $variations{$var}" unless $sasana =~ /$var$/;
    }

    my $desc = $trans;
    # many will know these as Warrior, not Hero
    $trans =~ s{\bHero\b}{Hero/Warrior};
    unless($desc =~ /pose|posture/oi){
        $desc .= ' Posture';
    }
    # autoformat almost isn't worth using with its newlines
    $desc = autoformat($desc, {case => 'title'});
    $desc =~ s/\n+$//o;

    # We add "ashtanga vinyasa yoga" since it's a specific style
    push @docs, {
        title => $asana,
        l2sm => "ashtanga vinyasa $asana $trans $sasana",
        l3sm => "ashtanga vinyasa $practice",
        pp => $desc,
        img => $img,
        src => $src,
        srcname => 'AYI',
        favicon => 1,
        pcount => $pcount
    };
}

# Add standard keywords, if necessary, while maintaining original keyword order
sub normalize_l2sm {
    my $l = shift;
    
    $l =~ s|/| |;
    $l .= ' yoga poses postures';

    my (%seen, @l2sm);
    for my $x (split /\s+/, $l){
        next if $seen{lc $x}++;
        push @l2sm, $x;
    }

    return "@l2sm";
}

sub create_xml {

    # Output the articles
    open my $output, '>:utf8', "$output_file.xml" or die "Failed to open $output_file: $!";

    print $output qq|<?xml version="1.0" encoding="UTF-8"?>\n<add allowDups="true">|;

    for my $d (@docs){

        my ($title, $l2sm, $l3sm, $pp, $img, $src, $srcname, $favicon, $pcount) =
            @$d{qw(title l2sm l3sm pp img src srcname favicon pcount)};

        my $source = '<field name="source"><![CDATA[yoga_asanas_api]]></field>';
        $source .= qq{\n<field name="p_count">$pcount</field>} if $pcount;
        $source .= q{<field name="l2_sec_match2"><![CDATA[} . normalize_l2sm($l2sm) . q{]]></field>} if $l2sm;
        $source .= qq{<field name="l3_sec_match2"><![CDATA[$l3sm]]></field>} if $l3sm;

        print $output "\n", join("\n",
            qq{<doc>},
            qq{<field name="title"><![CDATA[$title]]></field>},
            qq{<field name="paragraph"><![CDATA[$pp]]></field>},
            $source,
            qq{<field name="meta"><![CDATA[{"srcUrl":"$src","srcName":"$srcname","img":"$img","favicon":"$favicon","order":$pcount}]]></field>},
            '</doc>');
    }
    print $output "\n</add>";
}

sub create_json {

    my @jdocs;# = (add => {allowDups => 'true'});

    for my $d (@docs){

        my ($title, $l2sm, $l3sm, $pp, $img, $src, $srcname, $favicon, $pcount) =
            @$d{qw(title l2sm l3sm pp img src srcname favicon pcount)};

        my %doc = (
            title => $title,
            paragraph => $pp,
            source => 'yoga_asanas_api',
            p_count => $pcount
        );

        $doc{l2_sec_match2} = normalize_l2sm($l2sm) if $l2sm;
        $doc{l3_sec_match2} = $l3sm if $l3sm;

        $doc{meta} = to_json({srcUrl => $src, srcName => $srcname, img => $img, favicon => $favicon, order => $pcount});
        push @jdocs, \%doc;
    }

    # Output the articles
    open my $output, '>:utf8', "$output_file.json" or die "Failed to open $output_file: $!";
    print $output to_json(\@jdocs, {pretty => $pretty_json});
}
