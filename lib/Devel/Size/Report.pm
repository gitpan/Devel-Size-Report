package Devel::Size::Report;

use Devel::Size qw(size total_size);

sub S_UNKNOWN () { 0; }
sub S_SCALAR () { 1; }
sub S_ARRAY () { 2; }
sub S_HASH () { 3; }
sub S_GLOB () { 4; }

sub S_KEY () { 0x100; }

sub entries_per_element { 5; }

require Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/
  report_size track_size element_type entries_per_element
  S_SCALAR S_HASH S_ARRAY S_KEY S_GLOB S_UNKNOWN
  /;

$VERSION = '0.02';

use strict;

# default mapping
my $TYPE = { 
  S_SCALAR() => 'Scalar', 
  S_UNKNOWN() => 'Unknown', 
  S_HASH() => 'Hash', 
  S_GLOB() => 'Glob', 
  S_ARRAY() => 'Array', 
  S_KEY() => 'Key', 
  };

sub report_size
  {
  # walk the given reference recursively and return text describing the size
  # of each element
  my ($ref,$options) = @_;

  my @size = track_size($ref);

  my $text = '';
  my $indend = $options->{indend};
  $indend = '  ' if !defined $indend;
  my $names = $options->{names} || $TYPE;
  my $bytes = $options->{bytes} || 'bytes';
  my $left = $options->{left}; $left = '' if !defined $left;
  my $inner = $options->{inner}; $inner = '  ' if !defined $inner;
  $inner .= $left;
  my $total = $options->{total}; $total = 1 if !defined $total;
  my $head = $options->{head}; $head = 'Size report for' if !defined $head;
  $bytes = ' ' . $bytes if $bytes ne '';

  my $r = ref($ref); $r = '' if $r =~ /^(ARRAY|SCALAR)$/;
  $r = " ($r)" if $r ne '';
  $text = "$left$head '$ref'$r:\n" if $head ne '';
  my $e = entries_per_element;
  for (my $i = 0; $i < @size; $i += $e)
    {
    my $type = element_type( ($size[$i+1] & 0xFF),$names);
    my $str = $type;
    if ( ($size[$i+1] & S_KEY) != 0)
      {
      $str = element_type( ($size[$i+1] & S_KEY),$names);
      $str .= " '$size[$i+4]' => " . $type;
      }
    $str .= " $size[$i+2]$bytes";
    if ($size[$i+3] != 0)
      {
      my $overhead = $size[$i+3]; $overhead = 'unknown' if $overhead < 0;
      $str .= " ($overhead$bytes overhead)";
      }
    $str .= "\n";
    $text .= $inner . ($indend x $size[$i]) . $str;
    }
  $text .= $left . "Total: " . $size[2] . $bytes . "\n" if $total;
  $text;
  }

sub element_type
  {
  my ($type,$TYPE) = @_;

  return 'Unknown' unless exists $TYPE->{$type};
  $TYPE->{$type};
  }

sub track_size
  {
  # walk the given reference recursively and store the size, type etc of each
  # element
  my ($ref, $level) = @_;

  $level ||= 0;

  return ($level, S_SCALAR, total_size($ref), 0, undef) if !ref($ref);

  my @res = ();
  if (UNIVERSAL::isa($ref, 'ARRAY'))
    {
    my @r = ($level, S_ARRAY, total_size($ref), 0, undef);
    my $sum = 0;
    foreach my $elem ( @$ref )
      {
      my @rs = track_size( $elem, $level+1);
      $sum += $rs[2];
      push @r, @rs;
      }
    $r[3] = $r[2] - $sum;
    push @res, @r;
    }
  elsif (UNIVERSAL::isa($ref, 'HASH'))
    {
    my @r = ($level, S_HASH, total_size($ref), 0, undef);
    my $sum = 0;
    foreach my $elem ( keys %$ref )
      {
      if (ref($ref->{$elem}))
        {
        my @rs = track_size($ref->{$elem},$level+1);
        $rs[1] += S_KEY;
        $rs[4] = $elem;
        $sum += $rs[2];
        push @r, @rs;
        }
      else
        {
        my $size = total_size($ref->{$elem});
        push @r, $level+1, S_KEY + S_SCALAR, $size, 0, $elem;
        $sum += $size;
        }
      }
    $r[3] = $r[2] - $sum;
    push @res, @r;
    }
  elsif (UNIVERSAL::isa($ref, 'GLOB'))
    {
    return ($level, S_GLOB, total_size($ref), 0, undef);
    }
  else
    {
    return ($level, S_UNKNOWN, total_size($ref), -1, undef);
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
		  [ 1, 2, 3, 
		    { a => 'b', 
		      size => 12.2, 
		      h => ['a'] 
		    }, 
		  'rrr' 
		  ] 
		];
	print report_size($a, { indend => "\t" } );

This will print something like this:

	Size report for 'ARRAY(0x8396d7c)':
	  Array 655 bytes (84 bytes overhead)
	        Scalar 16 bytes
	        Scalar 16 bytes
	        Scalar 16 bytes
	        Array 523 bytes (84 bytes overhead)
	                Scalar 16 bytes
	                Scalar 16 bytes
                	Scalar 16 bytes
        	        Hash 359 bytes (206 bytes overhead)
	                        Key 'h' => Array 82 bytes (56 bytes overhead)
                                	Scalar 26 bytes
                        	Key 'a' => Scalar 26 bytes
                	        Key 'size' => Scalar 71 bytes
        	        Scalar 32 bytes
	Total: 655 bytes

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

	names	ref to HASH mapping the types to names
		This should map S_Scalar to something like "Scalar" etc
	indend	string to indend different levels with, default is '  '
	left	indend all text with this at the left side, default is ''
	inner	indend inner text with this at the left side, default is '  '
	total	if true, a total size will be printed as last line
	bytes	name of the size unit, defaults to 'bytes'
	head	header string, default 'Size report for'
		Set to '' to supress header completely	

=head2 entries_per_element

	my $entries = entries_per_element();

Returns the number of entries per element that L<track_size()> will generate.

=head2 track_size

	@elements = track_size( $reference, $level);

Walk the given scalar or reference recursively and returns an array, containing
(currently) 5 entries (see L<entries_per_element> for the exact number) entries
for each element in the structure pointed to byC<$reference>. 

The entries currently are:

	level	  the indend level
	type	  the type of the element, S_SCALAR, S_HASH, S_ARRAY etc
		  if (type & S_KEY) != 0, the element is a member of a hash
	size	  size in bytes of the element
	overhead  if the element is an ARRAY or HASH, contains the overhead
		  in bytes (size - sum(size of all elements)).
	name	  if type & S_KEY != 0, this contains the name of the hash key

C<track_size> calls itself recursively for ARRAY and HASH references. 

=head1 CAVEATS

=over 2

=item *

The limitations of Devel::Size also apply to this module.

=item *

A string representation of the passed argument will be inserted when generating
a report with a header.
 
If the passed argument is an object with overloaded magic, then the routine for
stringification will be triggered. If this routine does actually modify the
object (for instance, Math::String objects cache their string form upon first
call to stringification), the reported size will be different
from a first report without a header.

=back

=head1 BUGS 

=over 2

=item *

C<track_size> and thus C<print_size> do currently not work with circular
references.

=item *

Does only know about HASH, ARRAY and SCALAR. This means that tied thingies,
globs, code references etc might be incomplete or their sizes might be wrong.

=back

=head1 AUTHOR

(c) 2004 by Tels http://bloodgate.com

=cut
