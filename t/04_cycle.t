#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 5;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

# import anything
use Devel::Size::Report qw/
  report_size track_size element_type
  entries_per_element
  S_SCALAR
  S_HASH
  S_ARRAY
  S_GLOB
  S_UNKNOWN
  S_KEY
  S_LVALUE
  S_CODE
  S_REGEXP
  S_REF
  /;

use Devel::Size qw/size total_size/;

my $x = "A string";
my $v = \$x;
my $elems = [ $x, $v ];

my @size;

#############################################################################
# test for cycles and circular references:

my $a = { a => 1 }; $a->{b} = $a; 

# Output like:
#  Hash 170 bytes (overhead: 138 bytes, 81.18%)
#    'a' => Scalar 16 bytes
#    'b' => Circular ref 16 bytes
#Total: 170 bytes

my $CYCLE = report_size( $a, { head => '' } );

is ($CYCLE =~ /'b' => Circular.+ref/, 1, 'Contains a cycle');

$a = { a => 1, b => [ 1, 2, { u => 'z' } ] };
$a->{b}->[3] = $a->{b}; 
$a->{b}->[2]->{foo} = $a->{b}; 

$CYCLE = report_size( $a, { head => '' } );

is ($CYCLE =~ /'foo' => Circular.+ref/, 1, 'Contains a cycle');
$a = 0; $CYCLE =~ s/Circular.+ref/$a++/eg;
is ($a, 2, 'Contains two cycles');

#############################################################################
# Same scalar references twice 

# elems contains [ copy_of($x), $v ], so $x is not seen twice:

$CYCLE = report_size( $elems, { head => '', addr => 1} );

is (($CYCLE =~ /Cycle/) ||  0, 0, 'no cycle');

$CYCLE = report_size( [ $x, $v, $v ], { head => '', addr => 1} );

is (($CYCLE =~ /Cycle/) ||  0, 0, 'no cycle');

exit;

##############################################################################
##############################################################################

my $array = [ 8, 9 ];
my $b = \$array;
my $c = \$array;

$CYCLE = report_size( [ $b, $c ], { head => '', addr => 1} );

is (($CYCLE =~ /Cycle/) ||  0, 0, 'no cycle');

print "$CYCLE\n";
use Devel::Peek; print Dump($elems);

#output (showing wrong total size, and wrong size for second array)
#ok 6 - no cycle
#  Array(0x8248c70) 200 bytes (overhead: unknown)
#    Array Ref(0x8248c7c) 108 bytes (overhead: 16 bytes, 14.81%)
#      Array(0x8248cc4) 92 bytes (overhead: 60 bytes, 65.22%)
#        Scalar(0x8249ac4) 16 bytes
#        Scalar(0x815a5e4) 16 bytes
#    Array Ref(0x8249ab8) 108 bytes (overhead: 16 bytes, 14.81%)
#      Circular ref(0x8248cc4) 16 bytes
