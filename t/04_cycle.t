#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 14;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

# import anything
use Devel::Size::Report qw/
  report_size track_size element_type
  entries_per_element
  /;

use Devel::Size qw/size total_size/;
use Scalar::Util qw/refaddr/;

my $x = "A string";
my $v = \$x;

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

my $elems = [ $x, $v ];
# elems contains [ copy_of($x), $v ], so $x is not seen twice:

$CYCLE = report_size( $elems, { head => '', addr => 1} );

unlike ($CYCLE, qr/Circular/, 'no cycle');

$CYCLE = report_size( [ $x, $v, $v ], { head => '', addr => 1} );

unlike ($CYCLE, qr/Circular/, 'no cycle');

#############################################################################
# double ref

$elems = [ \$x, \$x ];

$CYCLE = report_size( $elems, { head => '', addr => 1} );

like ($CYCLE, qr/Double scalar ref/i, 'double scalar ref e.g. two refs to the same scalar');

#############################################################################
# different hash key (w/ same contents) referenced twice

# get's two times a copy of $x
 
$elems = { foo => $x, bar => $x };

$CYCLE = report_size( $elems, { head => '', addr => 1} );

unlike ($CYCLE, qr/(Circular|Double)/i, 'no cycle or double');

$elems = { foo => 'All Your Ref Are Belong To Us!', bar => 'All Your Ref Are Belong To Us!' };

$CYCLE = report_size( $elems, { head => '', addr => 1} );

unlike ($CYCLE, qr/(Circular|Double)/i, 'no cycle or double');

my $o = 'All Your Ref Are Belong To Us!';
$elems = { foo => $o }; $elems->{baz} = $o;

$CYCLE = report_size( $elems, { head => '', addr => 1} );
unlike ($CYCLE, qr/(Circular|Double)/i, 'no cycle or double');

print $CYCLE;

#############################################################################
# Perl makes a copy of the scalar when assigning it to a hash. See
# t/07_double.t for some tests that create double scalars:

# same hash key (w/ same contents) referenced twice

$elems = { foo => undef, baz => undef };

$CYCLE = report_size( $elems, { head => '', addr => 1} );
unlike ($CYCLE, qr/(Circular|Double)/i, 'no cycle or double');

#print $CYCLE;

#############################################################################
# same hash key (w/ same contents) referenced twice

$elems = [ undef, undef ];

$CYCLE = report_size( $elems, { head => '', addr => 1} );
unlike ($CYCLE, qr/(Circular|Double)/i, 'no cycle or double');

#print $CYCLE;

#############################################################################
##############################################################################
# first element appears in a cycle

$a = { foo => 23, bar => 45, baz => { umpf => 1234 } };
$a->{baz}->{parent} = $a;

$CYCLE = report_size( $a, { head => '', addr => 1} );

#  Hash(0x82add08) 405 bytes (overhead: 183 bytes, 45.19%)
#    'bar' => Scalar(0x82ade10) 16 bytes
#    'baz' => Hash(0x82a0560) 190 bytes (overhead: 158 bytes, 83.16%)
#      'umpf' => Scalar(0x82add38) 16 bytes
#      'parent' => Circular ref(0x82add08) 16 bytes

$CYCLE =~ /Hash\((.*?)\)/;

my $adr = $1;

like ($adr, qr/^0x/, 'address found');
is ($adr, sprintf("0x%x",refaddr($a)), 'right address found');

like ($CYCLE, qr/parent.*Circular.*$adr/, 'circular ref to parent');

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
