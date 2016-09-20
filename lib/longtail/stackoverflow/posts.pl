#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use Encode qw( is_utf8 encode decode _utf8_off);

no warnings 'uninitialized';

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use DDG::Meta::Data;
use HTML::Entities;
use List::Util 'first';
use JSON::MaybeXS 'encode_json';

my $stack_dir;
my @sources;
my $verbose = 0;

# command-line args
parse_argv();

my $question_re = qr/
    <row\s+Id="(\d+)"\s+
    PostTypeId="1"\s+
    (?:AcceptedAnswerId="(\d+)"\s+)?
    CreationDate="([^"]+)"\s+
    Score="(-?\d+)".+? # allow negative, skip fields
    Body="([^\"]+)".+? # skip fields
    Title="([^\"]+)"\s+
    Tags="([^\"]+)"
/x;

my $answer_re = qr/
    <row\s+Id="(\d+)"\s+
    PostTypeId="2"\s+
    ParentId="(\d+)"\s+
    CreationDate="([^"]+)"\s+
    Score="(-?\d+)"\s+ # allow negative
    Body="([^\"]+)"\s+
    (?:OwnerUserId="(\d+)")?
    (?:OwnerDisplayName="([^"]+)")?
/x;

my $m = DDG::Meta::Data->filter_ias({is_stackexchange => 1});

my %questions;
my %users;
my %post_links;
my %parent_post_score;
my $src_domain;

for my $name (sort keys %$m){
    # Reset between sites
    %parent_post_score = ();
    %questions = ();
    %users = ();
    %post_links = ();

    if(@sources){
        next unless first { $name eq $_ } @sources;
    }

    $src_domain = $m->{$name}{src_domain};
    print qq(\nID: $name\nsource: $src_domain\n\n);

    if (-e "$stack_dir/$src_domain/PostLinks.xml") {
        open(IN, '<:encoding(UTF-8)' , "$stack_dir/$src_domain/PostLinks.xml")
            or die "Failed to open $stack_dir/$src_domain/PostLinks.xml: $!";

        while (my $line = <IN>) {

            if ($line =~ /<row Id="(\d+)".+PostId="(\d+)".+RelatedPostId="(\d+)".+LinkTypeId="(\d+)"/o) {
                # specific to related post table
                my $id = $1;
                # the id of the parent question?
                my $post_id = $2;
                # the id of the linked to post (question)
                my $related_post_id = $3;
                # 1 = question, 2 = answer, 3 might be external
                my $link_type_id = $4;
                #warn "$id -> $post_id -> $related_post_id -> $link_type_id\n";
                ++$post_links{$post_id}{$related_post_id};
                ++$post_links{$related_post_id}{$post_id};
            }
        }
        close(IN);
    }

    unless(-e "$stack_dir/$src_domain/Users.xml"){
        warn "$stack_dir/$src_domain/Users.xml not found...skipping";
        next;
    }

    open(IN, '<:encoding(UTF-8)' , "$stack_dir/$src_domain/Users.xml")
        or die "Failed to open $stack_dir/$src_domain/Users.xml for reading: $!";

    while (my $line = <IN>) {
        if ($line =~ /  <row Id="(\d+)" Reputation="(\d+)".*DisplayName="([^\"]+)"/o) {
            my $id = $1;
            my $karma = $2;
            my $user_name = $3;

            $users{by_id}{$id} = $user_name;
            $users{by_name}{$user_name} = $id;
        }
    }

    close(IN);

    print 'users: ', scalar keys %{$users{by_id}}, "\n\n";
    #print scalar keys %karma, " whitelisted users\n";

    open(IN,  '<:encoding(UTF-8)' , "$stack_dir/$src_domain/Posts.xml")
        or die "Failed to open $stack_dir/$src_domain/Posts.xml for reading: $!";
    open(OUT, '>:encoding(UTF-8)' , "$stack_dir/pre-process.$name.txt")
        or die "Failed to open $stack_dir/pre-process.$name.txt for writing: $!";

    print OUT <<EOH;
<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
EOH

    my (%orphans, %cnts);
    while (my $line = <IN>) {
        print "Processed $. lines (", scalar(localtime), ")\n" unless $. % 100000;

        # Questions
        if ($line =~ $question_re){

            my $id = $1;
            my $accepted_answer = $2;
            my $date = $3;
            my $score = $4;
            my $body = $5;
            #my $last_edit_date = $6;
            my $title = $6;
            my $tags = $7;

            ++$cnts{questions};
            #next if $score<0;

            $parent_post_score{$id} = $score;
            #$body = decode_encode_str($body);
            #decode_entities($body);
            #$body = encode("UTF-8", $body);
            #$body = decode("UTF-8", $body);

            #my $body_pass = '';
            #($body_pass) = $body =~ /^<p>(.*?)<\/p>/sio;

            # For debugging.
            #print qq($title\t$body_pass\n) if $body_pass;
            #print qq($body\n) if $body;

            $questions{$id} = [$title, $tags, $accepted_answer];
            # Take care of orphans here since there may not be another
            # answer to trigger the call to process_answers() below
            if(my $oa = delete $orphans{$id}){
                for my $o (@$oa){
                    # remove original line needed for reporting
                    shift @$o;
                    ++$cnts{'kids reunited'};
                }
                process_answers($name, $oa, $questions{$id});
            }
        } # Answers.
        elsif (my @vals = $line =~ $answer_re){
            my $parent_id = $vals[1];

            # For debugging.
            #print $user, "\n";

            ++$cnts{answers};
            if (exists $questions{$parent_id}) {
                process_answers($name, [\@vals], $questions{$parent_id});
            }
            else{
                ++$cnts{'lost kids'};
                push @{$orphans{$parent_id}}, [$line, @vals];
            }
        }
        else{
            ++$cnts{'unrecognized lines'};
            $verbose && warn "NO LINE: $line\n";
        }
    }

    print "Processed $. lines total (", scalar(localtime), ")\n\n";
    close(IN);

    print OUT <<EOH;
</add>
EOH
    close(OUT);

    if(my @orphans = values %orphans){
        my $logf = "$stack_dir/orphans.$name.txt";
        my $olog;
        open $olog, '>:encoding(UTF-8)' , $logf
            or do{
                warn "Failed to open orphan file $logf for writing: $!. Dumping to STDERR";
                $olog = *STDERR;
            };
        for my $oa (@orphans){
            for (@$oa){
                print $olog $_->[0];
                ++$cnts{orphans};
            }
        }
    }

    for ('questions', 'answers', 'lost kids', 'kids reunited', 'orphans', 'unrecognized lines'){
        print "$_: ", $cnts{$_} || 0, "\n" ;
    }
}

sub process_answers{
    my ($name, $answers, $parent) = @_;

    my ($title, $q_tags, $accepted_id) = @$parent;

    my @tags;
    for my $t (split /&[lg]t;/, $q_tags){
        push @tags, $t if $t;
    }

    for my $a (@$answers){
        my ($id, $parent_id, $date, $score, $body, $user_id, $user_name) = @$a;

        my $accepted = $accepted_id eq $id ? 1 : 0;

        # converts xml chars
        $body = decode_encode_str($body,1);
        $title = decode_encode_str($title,1);

        # converts html chars
        decode_entities($body);
        $body = encode("UTF-8", $body);
        $body = decode("UTF-8", $body);
        decode_entities($title);
        $title = encode("UTF-8", $title);
        $title = decode("UTF-8", $title);

        # Spacing for indexing.
        $body =~ s/(<p>)/$1 /isg;
        #  $body =~ s/(<pre><code>)/$1/isg;
        $body =~ s/(<\/p>)/ $1/isg;
        # $body =~ s/(<\/code><\/pre>)/$1/isg;

        my ($uid, $uname);
        if ($user_id){
            if(exists $users{by_id}{$user_id}) {
                ($uid, $uname) = ($user_id, $users{by_id}{$user_id});
            }
        }
        elsif($user_name){
            if(exists $users{by_name}{$user_name}) {
                ($uid, $uname) = ($users{by_name}{$user_name}, $user_name);
            }
        }
        if($uid && $uname){
            $body .= qq( <p>--<a href="http://$src_domain/users/$uid/ddg">$uname</a></p>);
        }

        # This title clean up lets us match more things
        # by dropping irrelvent punctuation.

        $title =~ s/[\.\?\!\:]\s*$//o; # First remove line endings.

        $title =~ s/(?:\A|\s)\(([^\)]+)\)(?:\s|\Z)/ $1 /og; # Then parenthetical expressions.

        # Then quotes.
        $title =~ s/(?:\A|\s)\"([^\"]+)\"(?:\s|\Z)/ $1 /og;
        $title =~ s/(?:\A|\s)\'([^\']+)\'(?:\s|\Z)/ $1 /og;

        # Then colons.
        $title =~ s/\:\s+/ /og;

        $title =~ s/\\/ /og;

        # For debugging.
        #    print qq($title_match\n) if $title_match =~ /\(/o;

        # Convert ctrl+chars to unicode
        map {
            s/[\cA]/^A/ig;
            s/[\cB]/^B/ig;
            s/[\cC]/^C/ig;
            s/[\cD]/^D/ig;
            s/[\cE]/^E/ig;
            s/[\cF]/^F/ig;
            s/[\cG]/^G/ig;
            s/[\cH]/^H/ig;
            s/[\cI]/^I/ig;
            s/[\cK]/^K/ig;
            s/[\cL]/^L/ig;
            s/[\cM]/^M/ig;
            s/[\cN]/^N/ig;
            s/[\cO]/^O/ig;
            s/[\cP]/^P/ig;
            s/[\cQ]/^Q/ig;
            s/[\cR]/^R/ig;
            s/[\cS]/^S/ig;
            s/[\cT]/^T/ig;
            s/[\cU]/^U/ig;
            s/[\cV]/^V/ig;
            s/[\cW]/^W/ig;
            s/[\cX]/^X/ig;
            s/[\cY]/^Y/ig;
            s/[\cZ]/^Z/ig;
            s/[\c_]/^_/ig;
            s/[\c]]/^]/ig;
            s/[\c[]/^[/ig;
            s/[\c\]/^\\/ig;
            s/[\c^]/^\^/ig;
        }($title, $body);

        if (($title . $body) !~ /(?:\]\]|[\cG\cP])/so) {

            my $metaj = encode_json({
                creation_date => $date,
                accepted => int($accepted),
                post_links => $post_links{$parent_id} || {},
                parent_score => int($parent_post_score{$parent_id} || 0),
                tags => \@tags
            });
            my $p_count = $score > 0 ? -1 * $score : $score;

            print OUT <<EOH;
<doc>
<field name="title"><![CDATA[$title]]></field>
<field name="l2_sec"></field>
<field name="popularity">$score</field>
<field name="paragraph"><![CDATA[$body]]></field>
<field name="p_count">$p_count</field>
<field name="id">$parent_id</field>
<field name="id_match">$parent_id</field>
<field name="id2_match">$id</field>
<field name="id2">$id</field>
<field name="meta">$metaj</field>
<field name="source">$name</field>
</doc>
EOH
        }
    }
}
# Page input is multi-line XML.
# This function helps us turn pages into single-line txt.
sub decode_encode_str {
    my ($str,$no_db) = @_;

    return '' unless $str;

    # Decode encoded xml characters.
    $str =~ s/\&lt\;/\</g;
    $str =~ s/\&gt\;/\>/g;
    $str =~ s/\&quot\;/\"/g;
    $str =~ s/\&#xD\;//g;
    #$str =~ s/\&amp\;(?![#\w]+;)/\&/g;

    # Encode special space characters.
    $str =~ s/\\/\\\\/g if !$no_db;
    $str =~ s/\n/\\n/g;

    # UTF non-breaking space https://duckduckgo.com/?q=\x00A0
    # If you do $str =~ s/(?:\x{00C2}|)\x{00A0}/ /g;
    # you get Malformed UTF-8 character (unexpected continuation byte 0xa0, with no preceding start byte) in substitution (s///) at /usr/local/ddg/lib/DDG/Util/Process.pm line 59, <IN> line 51850.
    $str =~ s/\x{00A0}/ /g;

    $str =~ s/[\b\f\r\t]//g;

    return $str;
}

sub parse_argv {
    my $usage = <<ENDOFUSAGE;

     *********************************************************************
       USAGE: posts.pl -d dir  [-s id1,id2,id3...] [-v]

       OVERVIEW

       Process Stack Exchange data, e.g. from archive.org, creating XML
       files to load in Solr

       OPTIONS

       -d (required) Directory in which 7z files are stored and where
          processing will take place.  If processing a lot or all sources,
          should have a lot of space.

       -s (optional) Only process named sources.  Should be a DDG::Meta::Data
          ID.  Separate multiple IDs with commas (no spaces, unless surrounded
          by quotes!) Defaults to all sources.
       -v: (optional) Verbose

    ***********************************************************************

ENDOFUSAGE

    my $min_args = 2;

    die $usage unless $min_args <= @ARGV;

    for(my $i = 0;$i < @ARGV;$i++) {
        if   ($ARGV[$i] =~ /^-d$/i){ $stack_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/i){ $verbose = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-s$/i ){
            my $srcs = $ARGV[++$i];
            for my $s (split /\s*,\s*/, $srcs){
                push @sources, $s;
            }
        }
    }

    die "Must specify 7z directory\n\n$usage" unless $stack_dir;    
}
