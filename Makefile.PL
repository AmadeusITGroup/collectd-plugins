#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => "Collectd::Plugins::Amadeus",
	PREREQ_PM => {
		"File::Slurp" => 0,
	},
);
