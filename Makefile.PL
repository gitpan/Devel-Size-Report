use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Devel::Size::Report',
    'VERSION_FROM'	=> 'lib/Devel/Size/Report.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Devel::Size => 0.58,
		Test::Simple => 0.47,
	}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);