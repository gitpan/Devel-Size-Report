#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 6;
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
my $y = "A longer string";

#############################################################################
# formatting

my $A = report_size( qr/^(foo|bar)$/, { head => '', bytes => '' } );

is ( (scalar $A =~ /bytes/i) || 0, 0, 'No bytes text');

my $Z = report_size( $x );
is ($Z =~ /v$Devel::Size::Report::VERSION/, 1, 'report contains version');
is ($Z =~ /Total: \d+ bytes/, 1, 'report contains total sum');

$Z = report_size( { foo => $x, bar => $y }, { addr => 1, } );

is ($Z =~ /Hash\(0x[\da-fA-F]+\) /, 1, 'report contains address');

#############################################################################
# multiple addresses, especially in sub-arrays and hash keys

$Z = report_size( [  [ 123, 321 ], \12 ], { addr => 1, } );
my $cnt = 0; $Z =~ s/\(0x[\da-fA-F]+\)/$cnt++/eg;

is ($cnt, 4, 'report contains 4 addresses');

$Z = report_size( [  { a => [ 123, 321 ], b => \12 } ], { addr => 1, } );
$cnt = 0; $Z =~ s/\(0x[\da-fA-F]+\)/$cnt++/eg;

is ($cnt, 5, 'report contains 5 addresses');

