use ExtUtils::MakeMaker;

use strict;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, 'make dist' will not override META.yml");
    return $self->SUPER::metafile_target(@_);
  };

  require YAML::Node;
  my $node = YAML::Node->new( {} );

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'perl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

WriteMakefile(
    'NAME'		=> 'Devel::Size::Report',
    'VERSION_FROM'	=> 'lib/Devel/Size/Report.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Devel::Size'	=> 0.59,
		'Test::Simple'	=> 0.47,
		'Scalar::Util'	=> 1.13,
		'Time::HiRes'	=> 1.52,
		'Array::RefElem'=> 1.00,
		'Devel::Peek'	=> 1.00,
	},
    'PREREQ_FATAL'	=> 1,		# can't work w/o them anyway
);
