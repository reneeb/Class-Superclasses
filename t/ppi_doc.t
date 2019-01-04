#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use PPI;
use Class::Superclasses;

my $code = q~package test_expression_isa;

our @ISA = ('expression', 'isa');~;

my $doc    = PPI::Document->new( \$code );
my $parser = Class::Superclasses->new( $doc );

my @expected     = qw'expression isa';
my @superclasses = $parser->superclasses;
my $ref          = $parser->superclasses;

is_deeply \@superclasses, \@expected;
is_deeply $ref, \@expected;

done_testing();
