package Devel::Size::Report;

use Devel::Size qw(size total_size);
use Scalar::Util qw/reftype refaddr blessed/;

require Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/
  report_size track_size element_type entries_per_element
  S_SCALAR S_HASH S_ARRAY S_KEY S_GLOB S_UNKNOWN S_CODE S_REF S_LVALUE S_REGEXP
  /;

use strict;

use vars qw/$VERSION/;

$VERSION = '0.05';

BEGIN
  {
  # disable any warnings Devel::Size might spill
  $Devel::Size::warn = 0;
  }

# for cycles in memory
my %SEEN;

sub S_UNKNOWN () { 0; }
sub S_CYCLE () { 1; }
sub S_SCALAR () { 2; }
sub S_ARRAY () { 3; }
sub S_HASH () { 4; }
sub S_GLOB () { 5; }
sub S_CODE () { 6; }
sub S_REGEXP () { 7; }
sub S_LVALUE () { 8; }
sub S_DOUBLE () { 9; }

sub S_KEY () { 0x100; }
sub S_REF () { 0x200; }

sub entries_per_element () { 7; }

# default mapping
my $TYPE = { 
  S_SCALAR() => 'Scalar', 
  S_UNKNOWN() => 'Unknown', 
  S_HASH() => 'Hash', 
  S_GLOB() => 'Glob', 
  S_ARRAY() => 'Array', 
  S_CODE() => 'Code', 
  S_REGEXP() => 'Regexp', 
  S_LVALUE() => 'Lvalue', 
  S_CYCLE() => 'Circular ref', 
  S_DOUBLE() => 'Double scalar ref', 
  S_REF() => 'Ref', 
  S_KEY() => '', 
  };

# map 'SCALAR' => S_SCALAR
my $NAME_MAP = { 
  SCALAR => S_SCALAR(),
  HASH => S_HASH(),
  GLOB => S_GLOB(),
  ARRAY => S_ARRAY(),
  CODE => S_CODE(),
  REGEXP => S_REGEXP(),
  LVALUE => S_LVALUE(),
  CYCLE => S_CYCLE(),
  DOUBLE => S_DOUBLE(),
  REF => S_REF(),
  KEY => S_KEY(),
  };

sub report_size
  {
  # walk the given reference recursively and return text describing the size
  # of each element
  my ($ref,$options) = @_;
  
  # DONT do track_size($ref) because $ref is a copy of $_[0], reusing some
  # pre-allocated slot and this can have a different total size than $_[0]!!
  my @size = track_size($_[0]);

  my $text = '';
  
  my $indend = $options->{indend};
  $indend = '  ' if !defined $indend;
  
  my $names = $options->{names} || $TYPE;
  
  my $bytes = $options->{bytes}; $bytes = 'bytes' unless defined $bytes;
  $bytes = ' ' . $bytes if $bytes ne '';
  
  my $left = $options->{left}; $left = '' if !defined $left;
  
  my $inner = $options->{inner}; $inner = '  ' if !defined $inner;
  $inner .= $left;
  
  my $total = $options->{total}; $total = 1 if !defined $total;
  
  my $head = $options->{head}; 
  $head = "Size report v$Devel::Size::Report::VERSION for" if !defined $head;
  
  my $foverhead = $options->{overhead};
  $foverhead = " (overhead: %i%s, %0.2f%%)" if !defined $foverhead;
  
  # show class?
  my $class = $options->{class} || 0;
  
  # show addr?
  my $addr = $options->{addr} || 0;

  my $r = ref($ref); $r = '' if $r =~ /^(ARRAY|SCALAR)$/;
  $r = " ($r)" if $r ne '';
  $text = "$left$head '$ref'$r:\n" if $head ne '';
  my $e = entries_per_element();
  for (my $i = 0; $i < @size; $i += $e)
    {
    my $type = element_type( ($size[$i+1] & 0xFF),$names);
    if ( ($size[$i+1] & S_REF) != 0)
      {
      $type .= " " . element_type(S_REF, $names);
      }

    # add addr of element if wanted
    $type .= "(" . $size[$i+5] . ")" if $addr && $size[$i+5];

    # add class of element if wanted
    $type .= " (" . $size[$i+6] . ")" if $class && $size[$i+6];

    my $str = $type;
    if ( ($size[$i+1] & S_KEY) != 0)
      {
      $str = "'$size[$i+4]' => " . $type;
      }
    $str .= " $size[$i+2]$bytes";
    if ($size[$i+3] != 0)
      {
      my $overhead = 
	sprintf($foverhead, $size[$i+3], $bytes, 
	 100 * $size[$i+3] / $size[$i+2]); 
      $overhead = ' (overhead: unknown)' if $size[$i+3] < 0;
      $str .= $overhead;
      }
    $text .= $inner . ($indend x $size[$i]) . "$str\n";
    }
  $text .= $left . "Total: $size[2]$bytes\n" if $total;
  $text;
  }

sub element_type
  {
  my ($type,$TYPE) = @_;

  return 'Unknown' unless exists $TYPE->{$type};
  $TYPE->{$type};
  }

sub type
  {
  # map a typename to a type number
  my ($type) = @_;

  return S_UNKNOWN unless exists $NAME_MAP->{$type};
  $NAME_MAP->{$type};
  }

sub track_size
  {
  undef %SEEN;		# reset cycle memory
  my @sizes = _track_size(@_);
  undef %SEEN;		# save memory, throw away
  @sizes;
  }

sub _addr
  {
  my $adr;
  if (ref($_[0]) && $_[1] ne 'REF')
    {
    $adr = sprintf("0x%x", refaddr($_[0]));
    }
  else
    {
    $adr = sprintf("0x%x", refaddr(\($_[0])));
    }

  $adr;
  }

sub _type
  {
  my $type = uc(reftype($_[0]) || '');
  my $class = blessed($_[0]) || '';

  # blessed "Regexp" and ref to scalar?
  $type ='REGEXP' if $class eq 'Regexp';

  # refs to scalars are tricky
  $type ='REF' 
    if ref($_[0]) && UNIVERSAL::isa($_[0],'SCALAR') && $type ne 'REGEXP';
  $type;
  }

sub _track_size
  {
  # Walk the given reference recursively and store the size, type etc of each
  # element
  my ($ref, $level) = @_;

  $level ||= 0;

  # DONT do total_size($ref) because $ref is a copy of $_[0], reusing some
  # pre-allocated slot and this can have a different total size than $_[0]!!
  my $total_size = total_size($_[0]);
  my $type = _type($_[0]);
  my $blessed = blessed($_[0]) || '';
 
  my $adr = _addr($_[0],$type);

  if (exists $SEEN{$adr})
    {
    # already seen this part of the world, so return
    # XXX TODO: how big is just the reference?
    if (ref($ref))
      {
      return ($level, S_CYCLE, size(\\1), 0, undef, $adr, $blessed);
      }
    # a scalar seen twice
    return ($level, S_DOUBLE, 0, 0, undef, $adr, '');
    }

  # put in the address of $ref in the %SEEN hash
  $SEEN{$adr}++;

  # not a reference, but a plain scalar?
  return ($level, S_SCALAR, $total_size, 0, undef, $adr, $blessed)
    unless ref($ref);

  my @res = ();
  if ($type eq 'ARRAY')
    {
    my @r = ($level, S_ARRAY, $total_size, 0, undef, $adr, $blessed);
    my $sum = 0;
    for (my $i = 0; $i < scalar @$ref; $i++)
      {
      my @rs = _track_size( $ref->[$i], $level+1);
      $sum += $rs[2];
      push @r, @rs;
      }
    $r[3] = $r[2] - $sum;
    push @res, @r;
    }
  elsif ($type eq 'HASH')
    {
    my @r = ($level, S_HASH, $total_size, 0, undef, $adr, $blessed);
    my $sum = 0;
    foreach my $elem ( keys %$ref )
      {
      my $adr = _addr($ref->{$elem}, _type($ref->{$elem}));
      if (ref($ref->{$elem}))
        {
        my @rs = _track_size($ref->{$elem},$level+1);
        $rs[1] += S_KEY;
        $rs[4] = $elem;
        $rs[5] = $adr;
        $rs[6] = blessed($ref->{$elem}) || '';
        $sum += $rs[2];
        push @r, @rs;
        }
      else
        {
        my $size = total_size($ref->{$elem});
        push @r, $level+1, S_KEY + S_SCALAR, $size, 0, $elem, $adr, '';
        $sum += $size;
        }
      }
    $r[3] = $r[2] - $sum;
    push @res, @r;
    }
  elsif ($type eq 'REGEXP')
    {
    return ($level, type($type), $total_size, 0, undef, $adr, $blessed);
    }
  elsif ($type eq 'REF')
    {
    my $type = uc(reftype(${$_[0]}) || '');
    my $blessed = blessed (${$_[0]} ) || '';
    $type ='REGEXP' if $blessed eq 'Regexp';
    $type ='SCALAR' if !ref(${$_[0]});
    my @r = 
     ($level, S_REF + type($type), $total_size, 0, undef, $adr, $blessed);
    push @r, _track_size($$ref,$level+1);
    $r[3] = $r[2] - total_size($$ref);
    push @res, @r;
    }
  # SCALAR reference must come after Regexp, because these are also SCALAR !?
  elsif ($type eq 'SCALAR')
    {
    # XXX TODO total_size($$ref) == total_size($ref) - shouldn't they be
    # different?
    return ($level, S_REF, $total_size, 0, undef, $adr, $blessed);
    }
  else
    {
    my $overhead = 0;
    $overhead = -1 if type($type) == S_UNKNOWN;
    return ($level, type($type), $total_size, $overhead, undef, $adr, $blessed);
    }
  @res;
  }

1;
__END__

=pod

=head1 NAME

Devel::Size::Report - generate a size report for all elements in a structure

=head1 SYNOPSIS

	use Devel::Size::Report qw/report_size/;

        my $a = [ 8, 9, 7,
                  [ \"12",
                    2, 3,
                    { a => 'b',
                      size => 12.2,
                      h => ['a']
                    },
                    sub { 42; },
                  'rrr'
                  ] ];
	print report_size($a, { indend => "   " } );

This will print something like this:

	Size report v0.04 for 'ARRAY(0x815a430)':
	  Array 743 bytes (overhead: 84 bytes, 11.31%)
	     Scalar 16 bytes
	     Scalar 16 bytes
	     Scalar 16 bytes
	     Array 611 bytes (overhead: 96 bytes, 15.71%)
	        Scalar reference 27 bytes
	        Scalar 28 bytes
	        Scalar 28 bytes
        	Hash 308 bytes (overhead: 180 bytes, 58.44%)
	           'h' => Array 82 bytes (overhead: 56 bytes, 68.29%)
	              Scalar 26 bytes
	           'a' => Scalar 26 bytes
        	   'size' => Scalar 20 bytes
	        Code 92 bytes
        	Scalar 32 bytes
	Total: 743 bytes

=head1 DESCRIPTION

Devel::Size can only report the size of a single element or the total size of
a structure (array, hash etc). This module enhances Devel::Size by giving you
the ability to generate a full size report for each element in a structure.

You have full control over how the generated text report looks like, and where
you want to output it. In addition, the method C<track_size> allows you to get
at the raw data that is used to generate the report for even more flexibility.

=head1 METHODS

=head2 report_size

	my $record = report_size( $reference, $options ) . "\n";
	print $record;

Walks the given reference recursively and returns text tree describing
the size of each element.  C<$options> is a hash, containing the following
optional keys:

	names	  ref to HASH mapping the types to names
		  This should map S_Scalar to something like "Scalar" etc
	indend	  string to indend different levels with, default is '  '
	left	  indend all text with this at the left side, default is ''
	inner	  indend inner text with this at the left side, default is '  '
	total	  if true, a total size will be printed as last line
	bytes	  name of the size unit, defaults to 'bytes'
	head	  header string, default 'Size report for'
		  Set to '' to supress header completely	
  	overhead  Format string for the overhead, first size in bytes, then
		  the bytes string (see above) and then the percentage.
		  The default is:
		  " (overhead: %i%s, %0.2f%%)"
	addr 	  if true, for each element the memory address will be output
	class	  if true, show the class each element was blessed in

=head2 entries_per_element

	my $entries = entries_per_element();

Returns the number of entries per element that L<track_size()> will generate.

=head2 track_size

	@elements = track_size( $reference, $level);

Walk the given scalar or reference recursively and returns an array, containing
L<entries_per_element> entries for each element in the structure pointed to by
C<$reference>. C<$reference> can also be a plain scalar.  

The entries currently are:

	level	  the indend level
	type	  the type of the element, S_SCALAR, S_HASH, S_ARRAY etc
		  if (type & S_KEY) != 0, the element is a member of a hash
	size	  size in bytes of the element
	overhead  if the element is an ARRAY or HASH, contains the overhead
		  in bytes (size - sum(size of all elements)).
	name	  if type & S_KEY != 0, this contains the name of the hash key
	addr	  memory address of the element
	class	  classname that the element was blessed into, or ''

C<track_size> calls itself recursively for ARRAY and HASH references. 

=head2 type_name

	$type_number = type($type_name);

Maps a type name (like 'SCALAR') to a type number (lilke S_SCALAR).

=head1 WRAP YOUR OWN

If you want to create your own report with different formattings, please
use L<track_size> and create a report out of the data you get. Look at the
source code for L<report_size> how to do this - it is easy!

=head1 CAVEATS

=over 2

=item *

The limitations of Devel::Size also apply to this module. This means that
CODE refs and other "obscure" things might show wrong sizes, or unknown
overhead. In addition, some sizes might be reported wrong.

=item *

A string representation of the passed argument will be inserted when generating
a report with a header.
 
If the passed argument is an object with overloaded magic, then the routine for
stringification will be triggered. If this routine does actually modify the
object (for instance, Math::String objects cache their string form upon first
call to stringification, thus modifying themselves), the reported size will be
different from a first report without a header.

=back

=head1 BUGS 

Apart from the problems with Devel::Size, none known so far.

=head1 AUTHOR

(c) 2004 by Tels http://bloodgate.com

=cut
