#!/usr/bin/perl -w

use strict;
use lib '../lib';
use Devel::Size::Report qw(size_report);

use IO::File;
use Math::BigFloat;

my $a = [ 8, 9, 7, [ 1,2,3, { a => 'b', size => 12.2, h => ['a'] }, 'rrr' ] ];

use Data::Dumper; print Dumper($a);

print size_report($a, { indend => "\t", left => '', total => undef,} ), "\n";

print size_report(Math::BigInt->new(1)),"\n";
print size_report(Math::BigFloat->new(1)),"\n";
print size_report(Math::BigFloat->new(1.2)),"\n";

my $FILE;
open($FILE, "size.pl") or die ("Cannot open STDIN: $!");
print size_report( $FILE ), "\n";

print size_report( IO::File->new() ), "\n";

print size_report( "a scalar" ), "\n";
print size_report( \"a scalar" ), "\n";

print size_report( sub { 3 < 5 ? 1 : 0; print "123"; 3; }), "\n";

