#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 26;
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
my $v = "V string";
my $y = "A longer string";
my $z = "Some other text";
my $elems = [ $x,$y,$z ];

my @size;

#############################################################################
# check that two report with different thingies, but same amount of them are
# equal 

# check that the report does not change the size!
my $old_size = total_size($x);
@size = track_size( $x );
is ($size[2], $old_size, "old size agrees with total_size");

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

# XXX store size of $x
@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");
is (total_size($x), size($x), "size() agrees with total_size()");

my $A = report_size( $z, { head => '' } );
my $B = report_size( $y, { head => '' } );

is ($A, $B, 'two same-sized scalars reports are the same ');

@size = track_size( $x );
is ($size[2], $old_size, "\$x is still $old_size bytes");

@size = track_size( $v );
is ($size[2], $old_size, "\$v is still $old_size bytes");

is (total_size($x), size($x), "size() agrees with total_size()");

my $u = "A string";

my $C = report_size( $x, { head => '' } );
my $D = report_size( $x, { head => '' } );
my $E = report_size( $u, { head => '' } );

isnt ($A, $C, 'two different sized scalars reports are different');
isnt ($A, $E, 'two same-sized scalars reports are equal');
is ($C, $D, 'two different sized scalars reports are different');

my $code = sub { my $x = 129; $x = 12 if $x < 130; };

#############################################################################
# SCALAR 

$A = report_size( "1234", { head => '' } );

is ($A =~ /Scalar /, 1, 'Scalar');

#############################################################################
# HASH 

$A = report_size( { foo => "1234" }, { head => '' } );

is ($A =~ /Hash /, 1, 'Hash');
is ($A =~ /'foo' =>/, 1, 'Hash key is present');

#############################################################################
# ARRAY 

$A = report_size( [ 1, 2 ], { head => '' } );

is ($A =~ /Array /, 1, 'Array');

#############################################################################
# SCALAR references

$A = report_size( \"1234", { head => '' } );

is ($A =~ /Scalar Ref/, 1, 'Scalar ref');

#############################################################################
# ARRAY references

$A = report_size( \ [ 8, 9 ], { head => '' } );

is ($A =~ /Array Ref/, 1, 'Array ref');

#############################################################################
# HASH references

$A = report_size( \ { a => 89 }, { head => '' } );

is ($A =~ /Hash Ref/, 1, 'Hash ref');

#############################################################################
# CODE 

# see if this does something (XXX TODO: Devel::Size spills some error)
my $CODE = report_size( $code, { head => '' } );

is ( $CODE =~ /Code /, 1, 'Contains code');

#############################################################################
# REGEXP

$A = report_size( qr/^(foo|bar)$/, { head => '' } );

is ($A =~ /Regexp/, 1, 'Contains a regexp');

#############################################################################
# LVALUE

# XXX TODO: I have no idea how to create one

sub lefty : lvalue {
  $x;
  };

#use Devel::Peek; print Dump(\&lefty);

$A = report_size( \&lefty, { head => '', class => '' } );

#is ($A =~ /Lvalue/, 1, 'Contains a lvalue');
#
#print "$A\n";
