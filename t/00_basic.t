#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 2;
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

