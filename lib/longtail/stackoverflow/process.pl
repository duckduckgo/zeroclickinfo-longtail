#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use DDG::Meta::Data;

my $all_meta = DDG::Meta::Data->by_id;

while( my($name, $data) = each $all_meta){
    next unless $data->{repo} eq 'longtail';
    system "./posts.pl $name";
}
