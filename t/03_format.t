#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 10;
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

is ($cnt, 7, 'report contains 7 addresses');

$Z = report_size( [  { a => [ 123, 321 ], b => \12 } ], { addr => 1, } );
$cnt = 0; $Z =~ s/\(0x[\da-fA-F]+\)/$cnt++/eg;

is ($cnt, 8, 'report contains 8 addresses');

#############################################################################
# in regexps

$A = report_size( qr/^(foo|bar)$/, { head => '', addr => 1} );

is ( $A =~ /\(0x[a-fA-F0-9]+\)/ || 0, 1, 'Contains addr');

#############################################################################
# class names

$x = { foo => 0 }; bless $x, 'Foo';

$A = report_size( $x, { head => '', class => 1} );
is ( $A =~ /Hash \(Foo\)/ || 0, 1, 'Contains (Foo)');

$y = [ bar => $x ]; bless $y, 'Bar';

$A = report_size( $y, { head => '', class => 1} );

is ( $A =~ /Hash \(Foo\)/ || 0, 1, 'Contains (Foo)');
is ( $A =~ /Array \(Bar\)/ || 0, 1, 'Contains (Bar)');

