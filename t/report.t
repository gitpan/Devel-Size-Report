#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 49;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  use_ok ('Devel::Size::Report');
  }

can_ok('Devel::Size::Report', qw/
  report_size track_size element_type
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
  entries_per_element
  /);

# check that we can import these names
Devel::Size::Report->import(qw/
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
  /);

use Devel::Size qw/size total_size/;
# XXX use this to dump $x before and after and see that it didn't change
#use Devel::Peek;

my $x = "A string";
my $v = "V string";
my $y = "A longer string";
my $z = "Some other text";
my $elems = [ $x,$y,$z ];

# see that track_size works ok with scalars
foreach my $elem (@$elems)
  {
  my @size = track_size ( $elem );
  is ($size[0], 0, 'level is 0');
  is ($size[1], Devel::Size::Report::S_SCALAR(), 'type S_SCALAR');
  is ($size[2], total_size($elem), 'size is ok');
  is ($size[3], 0, 'overhead for scalars is 0');
  is ($size[4], undef, 'not a key');
  }

#############################################################################
# check that track_size generates the correct amount of entries
my @size;

# scalars
@size = track_size ( $x );
is (scalar @size, entries_per_element(), '1 (1 scalar) elements');

@size = track_size ( \$x );
is (scalar @size, entries_per_element(), '1 (1 scalar) elements');

# array ref
@size = track_size ( $elems );

is (scalar @size, entries_per_element() * ( 3 + 1), '4 (3 scalars + 1 array) elements');

# check that nested arrays work
@size = track_size ( [ $x,$y,$z, [ $x, $y, $z] ] );

is (scalar @size, entries_per_element() * ( 6 + 2), '8 (6 scalars + 2 arrays) elements');

# check that nested arrays work
@size = track_size ( { 1 => $x, 2 => $y, 3 => $z, 4 => { 1 => $x, 2 => $y, 3 => $z } } );

is (scalar @size, entries_per_element() * ( 6 + 2), '8 (6 scalars + 2 hashes) elements');

# check that nested arrays/hashes work
@size = track_size ( [ $x,$y,$z, { 1 => $x, 2 => $y, 3 => $z } ] );

is (scalar @size, entries_per_element() * ( 6 + 2), '8 (6 scalars + 1 array + 1 hash) elements');

@size = track_size ( { a => $x, b => $y, c => $z, d => [ $x, $y, $z, $x ] } );
is (scalar @size, entries_per_element() * ( 7 + 2), '9 (7 scalars + 1 array + 1 hash) elements');

#############################################################################
# blessed objects

my $self = [ $x ]; bless $self, 'Foo';
@size = track_size ( $self );

is (scalar @size, entries_per_element() * (1 + 1), '2 (1 scalar + 1 array) elements');

$self = { value => $x }; bless $self, 'Bar';
@size = track_size ( $self );

is (scalar @size, entries_per_element() * (1 + 1), '2 (1 scalar + 1 hash) elements');

#############################################################################
# check that two report with different thingies, but same amount of them are
# equal 

# check that the report does not change the size!
my $old_size = total_size($x);
@size = track_size( $x );
is ($size[2], $old_size, "still $old_size bytes");

my $Z = report_size( $x, { head => '' } );

is (total_size($x), $old_size, "still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

# looking twice shouldn't change anything
@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

# $v should be the same size than $x
@size = track_size( $v );
is ($size[2], $old_size, "\$v is still $old_size bytes");
is (total_size($v), size($v), "size() agrees with total_size()");
is (total_size($v), total_size($x), "\$x and \$v are the same sizes");

# Dump ($x);

# XXX store size of $x
@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

#### XXX TODO

my $A = report_size( $z, { head => '' } );
my $B = report_size( $y, { head => '' } );

is ($A, $B, 'two same-sized scalars reports are the same ');

# XXX looking at $z and $y somehow changed the size of $x!!
TODO: {
  local $TODO = "Looking at \$z and/or \$y changes the size of \$x!";

#  Dump ($x);
  @size = track_size( $x );
  is ($size[2], $old_size, "\$x is still $old_size bytes");

#  Dump ($x);
  @size = track_size( $v );
  is ($size[2], $old_size, "\$v is still $old_size bytes");
  };

is (total_size($x), size($x), "size() agrees with total_size()");

# XXX change this to C<$u = 1> and the prints below will suddenly show 44
# bytes, not 40 bytes! Why?
my $u = "A string";

# XXX Can't use $x due to bug above.
# XXX And $u is also suddenly 40 bytes, not 33. Why?
my $C = report_size( $u, { head => '' } );
my $D = report_size( $y, { head => '' } );

TODO: {
  local $TODO = "Looking at \$z and/or \$y changes the size of \$x and newly created scalars!";

  isnt ($A, $C, 'two different sized scalars reports are different ');
  isnt ($C, $D, 'two different sized scalars reports are different ');
  }

#print report_size( $x, { head => '' } ), "\n";
#print report_size( $y, { head => '' } ), "\n";
#print report_size( $z, { head => '' } ), "\n";

my $code = sub { my $x = 129; $x = 12 if $x < 130; };

#############################################################################
# SCALAR references

$A = report_size( \"1234", { head => '' } );

is ($A =~ /Scalar reference/, 1, 'Scalar ref');

#############################################################################
# CODE 

# see if this does something (XXX TODO: Devel::Size spills some error)
my $CODE = report_size( $code, { head => '' } );

is ( $CODE =~ /Code /, 1, 'Contains code');

#############################################################################
# test for cycles and circular references:

my $a = { a => 1 }; $a->{b} = $a; 

# Output like:
#  Hash 170 bytes (overhead: 138 bytes, 81.18%)
#    'a' => Scalar 16 bytes
#    'b' => Circular reference 16 bytes
#Total: 170 bytes

my $CYCLE = report_size( $a, { head => '' } );

is ($CYCLE =~ /'b' => Circular reference/, 1, 'Contains a cycle');

$a = { a => 1, b => [ 1, 2, { u => 'z' } ] };
$a->{b}->[3] = $a->{b}; 
$a->{b}->[2]->{foo} = $a->{b}; 

$CYCLE = report_size( $a, { head => '' } );

is ($CYCLE =~ /'foo' => Circular reference/, 1, 'Contains a cycle');
$a = 0; $CYCLE =~ s/Circular reference/$a++/eg;
is ($a, 2, 'Contains two cycles');

#############################################################################
# REGEXP

$A = report_size( qr/^(foo|bar)$/, { head => '' } );

is ($A =~ /Regexp/, 1, 'Contains a regexp');

#############################################################################
# LVALUE

# XXX TODO: I have no idea how to create one

#sub lefty : lvalue {
#  my $arg = 9;
#  };
#
#$A = report_size( \&lefty(1), { head => '' } );

#############################################################################
# formatting

$A = report_size( qr/^(foo|bar)$/, { head => '', bytes => '' } );

is ( (scalar $A =~ /bytes/i) || 0, 0, 'No bytes text');

