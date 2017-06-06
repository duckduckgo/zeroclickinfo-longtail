#!/usr/bin/env perl

use LWP::UserAgent;
use DDG::Meta::Data;

my $archive_org = 'http://archive.org/download/stackexchange/';

my ($se_dir, $verbose);
parse_argv();

my $ua = LWP::UserAgent->new;
my %m = %{DDG::Meta::Data->filter_ias({is_stackexchange => 1})};

my $res = $ua->get($archive_org);
my %available_zips;
if($res->is_success){
    my $c = $res->decoded_content;
    my @zips = $c =~ /href="([^"]+\.com\.7z)/g;
    for (@zips){
        next if /^meta\./;
        $available_zips{$_} = 1
    }
}

for my $id (sort keys %m){

    my $ia = $m{$id};
    my $src_dom = $ia->{src_domain};

    my @zips;
    if($src_dom eq 'stackoverflow.com'){
        for my $t (qw(Users Posts PostLinks)){
            push @zips, "$src_dom-$t.7z";
        }
    }
    else{
        push @zips, "$src_dom.7z";
    }

    for my $z (@zips){
        delete $available_zips{$z};
        my $res = $ua->mirror("$archive_org/$z", "$se_dir/$z");
        if($res->is_success){
            warn "Downloaded new version of $z\n";
        }
        elsif($res->code == 304){
            $verbose && warn "$z unchanged\n";
        }
        else{
            warn "Failed to check $z: ", $res->status_line;
        }
    }
}
if(my @unknown = sort keys %available_zips){
    warn join("\n\t", "NEW/UNKNOWN 7Z FILES AVAILABLE:\n", @unknown), "\n";
}

sub parse_argv {
    my $usage = <<ENDOFUSAGE;

     *********************************************************************
       USAGE: mirror_stackexchange.pl -d dir [-v]

       OVERVIEW

       Mirrors the 7z files from https://archive.org/details/stackexchange
       to a local directory. Downloads the files based on the is_stackexchange
       flag in metadata.

       OPTIONS
       
       -d  Directory in which 7z files will be stored.
       -v: (optional) Verbose, will output additional info.


    ***********************************************************************

ENDOFUSAGE

    my $min_args = 2;

    die $usage unless $min_args <= @ARGV;

    for(my $i = 0;$i < @ARGV;$i++) {
        if($ARGV[$i] =~ /^-d$/i ){ $se_dir = $ARGV[++$i] }
        elsif($ARGV[$i] =~ /^-v$/i){ ++$verbose }
    }
}
