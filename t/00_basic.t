#!/usr/bin/perl -w

use Test::More;
use strict;
use Scalar::Util qw/weaken/;

BEGIN
  {
  $| = 1; 
  plan tests => 8;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  use_ok ('Devel::Size::Report');
  }

can_ok('Devel::Size::Report', qw/
  report_size track_size element_type entries_per_element
  S_SCALAR
  S_HASH
  S_ARRAY
  S_GLOB
  S_UNKNOWN
  S_LVALUE
  S_CODE
  S_REGEXP
  S_DOUBLE
  S_CYCLE
  S_VSTRING
  
  SF_KEY
  SF_REF
  SF_RO
  SF_WEAK
  SF_DUAL
  /);

# check that we can import these names
Devel::Size::Report->import(qw/
  report_size track_size element_type entries_per_element
  S_SCALAR
  S_HASH
  S_ARRAY
  S_GLOB
  S_UNKNOWN
  S_LVALUE
  S_CODE
  S_REGEXP
  S_CYCLE
  S_DOUBLE
  S_VSTRING
  
  SF_KEY
  SF_REF
  SF_RO
  SF_WEAK
  SF_DUAL
  /);

#############################################################################
# _flags

print "# _flags:\n";
print "# IS_WEAK   : ", SF_WEAK(),"\n";
print "# IS_RO     : ", SF_RO(),"\n";
print "# IS_DUAL   : ", SF_DUAL(),"\n";

is (Devel::Size::Report::_flags(v1.2.3), SF_RO());

my $a = 123;
my $x = \$a;

is (Devel::Size::Report::_flags($x), 0, 'ref to 123');
weaken ($x);
is (Devel::Size::Report::_flags($x), SF_WEAK(), 'weakened ref');

$x = \"123";

is (Devel::Size::Report::_flags($x), 0, 'ref to 123');
weaken ($x);
is (Devel::Size::Report::_flags($x), SF_WEAK(), 'weakened ref');

is (Devel::Size::Report::_flags("123"), SF_RO(), 'readonly scalar');


