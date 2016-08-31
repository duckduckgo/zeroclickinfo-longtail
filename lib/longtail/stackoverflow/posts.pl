#!/usr/bin/env perl

use warnings;
use strict;
use utf8;
use Encode qw( is_utf8 encode decode _utf8_off);
binmode STDOUT, ":utf8";

use DDG::Meta::Data;
use HTML::Entities;
use List::Util 'first';

my $stack_dir;
my @sources;

# command-line args
parse_argv();

my $accepted_answer_re = qr/^\s*
    <row\s+Id="(\d+)"\s+
    PostTypeId="1"\s+
    AcceptedAnswerId="(\d+)"\s+
    CreationDate="([^"]+)".*
    Score="(\d+).*
    Body="([^\"]+)".*
    Title="([^\"]+)"\s+
    Tags="([^\"]+)"/x;

my $no_accepted_answer_re = qr/^\s*
    <row\s+Id="(\d+)"\s+
    PostTypeId="1"\s+
    CreationDate="([^"]+)".*
    Score="(\d+)".*
    Body="([^\"]+)".*
    Title="([^\"]+)"\s+
    Tags="([^\"]+)"/x;

my $answer_re = qr/^\s*
    <row\s+Id="(\d+)"\s+
    PostTypeId="2"\s+
    ParentId="(\d+)"\s+
    CreationDate="([^"]+)".*
    Score="(\d+)".*
    Body="([^\"]+)"\s+
    OwnerUserId="(\d+)"/x;

my $m = DDG::Meta::Data->filter_ias({is_stackexchange => 1});

while( my($name, $data) = each %$m){
    my %answer_ids;
    my %unanswered_ids;
    my %tmp;

    if(@sources){
        next unless first { $name eq $_ } @sources;
    }

    print qq(\nTYPE: $name\t$data->{src_domain}\n);

    my %post_links = ();
    if (-e "$stack_dir/$data->{src_domain}/PostLinks.xml") {
        open(IN ,  "<:encoding(UTF-8)" , "$stack_dir/$data->{src_domain}/PostLinks.xml");

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
                push (@{$post_links{$post_id}} ,$related_post_id);
            }
            # For debugging.
            #    last;
        }
        close(IN)
    };

    my %users = ();
    #my %karma = ();
    #    use Data::Dumper;
    #    warn Dumper $data->{src_domain};
    #next unless -e "$stack_dir/stackexchange/$data->{src_domain}/Users.xml";
    unless(-e "$stack_dir/$data->{src_domain}/Users.xml"){
        warn "$stack_dir/$data->{src_domain}/Users.xml not found...skipping";
        next;
    }

    open(IN ,  "<:encoding(UTF-8)" , "$stack_dir/$data->{src_domain}/Users.xml");
    
    while (my $line = <IN>) {
        if ($line =~ /  <row Id="(\d+)" Reputation="(\d+)".*DisplayName="([^\"]+)"/o) {
            my $id = $1;
            my $karma = $2;
            my $user_name = $3;
    
            # For debugging.
            #print qq($id\t$name\n);
            $users{$id} = $user_name;
            #$karma{$id} = undef if $karma>500;
        }
    
        # For debugging.
        #    last;
    }

    close(IN);
    
    print scalar keys %users, " users\n";
    #print scalar keys %karma, " whitelisted users\n";
    
    open(IN ,  "<:encoding(UTF-8)" , "$stack_dir/$data->{src_domain}/Posts.xml");
    open( OUT , ">:encoding(UTF-8)" , "$stack_dir/pre-process.$name.txt") ;
    open( TMP , ">:encoding(UTF-8)" , "$stack_dir/tmp.txt") ;
    print OUT <<EOH;
<?xml version="1.0" encoding="UTF-8"?>
<add allowDups="true">
EOH
    
    my $count = 0;
    my $count_q = 0;
    my $count_q2 = 0;
    my $count_a = 0;
    my $count_a2 = 0;
    my $count_a3 = 0;

    my %parent_post_score = ();
    while (my $line = <IN>) {
        print qq($count\n) if ++$count % 100000 == 0;
    
        # For debugging.
    #    next if $count<820950;
    #    last if $count>821020;
    #    print $line if $count==9312;
    
    
        # Post with accepted answer.
        if ($line =~ $accepted_answer_re){
            
            $count_q++;
    
            my $id = $1;
            my $accepted_answer = $2;
            my $date = $3;
            my $score = $4;
            my $body = $5;
            #my $last_edit_date = $6;
            my $title = $6;
            my $tags = $7;
    
            next if $score<0;
            $count_q2++;
    
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
    
    
            $answer_ids{$accepted_answer} = qq($title~|~$tags);
            $unanswered_ids{$id} = qq($title~|~$tags);
    
        # Post without accepted answer.
        }
        elsif ($line =~ $no_accepted_answer_re){
            $count_q++;
    
            # For debugging.
            #print qq(test\n);
    
            my $id = $1;
            my $date = $2;
            my $score = $3;
            my $body = $4;
            #        my $last_edit_date = $5;
            my $title = $5;
            my $tags = $6;
    
    #        next if $score<3;
            next if $score<0;
            $count_q2++;
    
            $parent_post_score{$id} = $score;
            # For debugging.
            #print qq(test\n);
    
            $unanswered_ids{$id} = qq($title~|~$tags);
    
        # Answers.
        }
        elsif ($line =~ $answer_re){
            $count_a++;
    
            my $id = $1;
            my $parent_id = $2;
            my $date = $3;
            my $score = $4;
            my $body = $5;
            my $user = $6;
            # my $last_edit_date = $7;
            my $accepted = exists $answer_ids{$id} ? 1 : 0;
    
            # For debugging.
            #print $user, "\n";
    
    #       if ( (exists $answer_ids{$id} && $score>=0) || (exists $unanswered_ids{$parent_id} && $score>=3) ) {
            # allow more answers through
            if ( (exists $answer_ids{$id} && $score>=0) || (exists $unanswered_ids{$parent_id} && $score>=1) ) {
                $count_a2++;
    
                # For debugging.
                #    print qq(test\n) if exists $unanswered_ids{$parent_id};
    
                my $q = $answer_ids{$id} || $unanswered_ids{$parent_id};
                my @q = split(/\~\|\~/o,$q);
   
                my $title = $q[0];
                my $q_tags = $q[1];
    
                # converts xml chars
                $body = decode_encode_str($body,1);
                $title = decode_encode_str($title,1);
    
                #    print qq($body\n);
                #    print $body if $count==9312;
                #    print TMP $body if $count==51850;
    
                # converts html chars
                decode_entities($body);
                $body = encode("UTF-8", $body);
                $body = decode("UTF-8", $body);
                decode_entities($title);
                $title = encode("UTF-8", $title);
                $title = decode("UTF-8", $title);
 
                #    print $body if $count==9312;
    
                # Spacing for indexing.
                $body =~ s/(<p>)/$1 /isg;
                #  $body =~ s/(<pre><code>)/$1/isg;
                $body =~ s/(<\/p>)/ $1/isg;
                # $body =~ s/(<\/code><\/pre>)/$1/isg;
    
                if (exists $users{$user}) {
                    $body .= qq( <p>--<a href="http://$data->{src_domain}/users/$user/ddg">$users{$user}</a></p>);
                }

                # Debug count.
                #    $count_a3++ if $body =~ /<a /osi;
                #    print qq($count_a3\n) if $count_a3;
                #    die $body if $body =~ /\sCDATA\s/os && $body =~ /[\s\'\"]<\/[\s\'\"]/os;
                #    print qq($title\n) if $title =~ /\s\"[^\"]+\"\s/o;
                #    print qq($title\n) if $title =~ /\s\'[^\']+\'\s/o;
   
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
    
                    my $post_links = '';
                    my $parent_post_score = '';
                    $post_links = join(',',@{$post_links{$parent_id}}) if $post_links{$parent_id};
                    $parent_post_score = $parent_post_score{$parent_id} if $parent_post_score{$parent_id};
                # For debugging.
                #print $body if $body =~ /\\/;
    
                print OUT <<EOH;
<doc>
<field name="title"><![CDATA[$title]]></field>
<field name="l2_sec"></field>
<field name="popularity">$score</field>
<field name="paragraph"><![CDATA[$body]]></field>
<field name="p_count">-$score</field>
<field name="id">$parent_id</field>
<field name="id_match">$parent_id</field>
<field name="id2_match">$id</field>
<field name="id2">$id</field>
<field name="meta">{"creation_date":"$date","accepted":"$accepted","post_links":"$post_links","parent_score","$parent_post_score"}</field>
<field name="source">$name</field>
</doc>
EOH
                }
            }
        }
    
    #    last if $count;
    #    last if $count>10;
    }

    close(IN);
    
    print OUT <<EOH;
</add>
EOH
    close(OUT);
    close(TMP);
    
    print qq($count\n);
    print qq(q: $count_q\n);
    print qq(q2: $count_q2\n);
    print qq(a: $count_a\n);
    print qq(a2: $count_a2\n);
    print qq(a3: $count_a3\n);
    
    # For debugging.
    #$count = 0;
    #for my $tmp (sort {$tmp{$b}<=>$tmp{$a}} keys %tmp) {
    #    print $tmp{$tmp}, "\t", $tmp, "\n";
    #    last if ++$count>50;
    #}
}

# Page input is multi-line XML.
# This function helps us turn pages into single-line txt.
sub decode_encode_str {
    my ($str,$no_db) = @_;

    # If no string assign it.
    $str = '' if !(defined $str);

    # Decode encoded xml characters.
    $str =~ s/\&lt\;/\</g;
    $str =~ s/\&gt\;/\>/g;
    $str =~ s/\&quot\;/\"/g;
    $str =~ s/\&amp\;/\&/g;

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
       USAGE: posts.pl -d dir  [-s id1,id2,id3...]

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

    ***********************************************************************

ENDOFUSAGE

    my $min_args = 2;

    die $usage unless $min_args <= @ARGV;

    for(my $i = 0;$i < @ARGV;$i++) {
        if   ($ARGV[$i] =~ /^-d$/i){ $stack_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-s$/i ){
            my $srcs = $ARGV[++$i];
            for my $s (split /\s*,\s*/, $srcs){
                push @sources, $s;
            }
        }
    }

    die "Must specify 7z directory\n\n$usage" unless $stack_dir;    

}
