#!/usr/bin/env perl

# Copyright (c) 2015 Amadeus Germany GmbH
#
# License: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

=pod

=head1 Collectd::Plugins::Vmmemctl

A plugin for collectd to read VMware memory ballooning statistics from
F</sys/kernel/debug/vmmemctl>. The plugin requires Linux, the C<vmw_balloon>
module and a C<debugfs> mounted on F</sys/kernel/debug> (the default).

=head2 Tested on

=over

=item * Debian Jessie

=back

It should also work on other systems.

=head2 TODO

=over

=item Expose more metrics
=item Make the status file configurable
=item Better diagnostics (Is debugfs mounted?)

=back

=cut

package Collectd::Plugins::Vmmemctl;

use strict;
use warnings;

use English;
use File::Slurp;
use POSIX;

use Collectd qw( :all );

use constant {
	PAGESIZE => POSIX::sysconf(&POSIX::_SC_PAGESIZE),
	PLUGIN => 'vmmemctl',
	STATUS_FILE => '/sys/kernel/debug/vmmemctl',
	EXTRACT_RE => qr/
		target:\s+(\d+)\spages\n
		current:\s+(\d+)\spages\n
		rateNoSleepAlloc:\s+(\d+)\spages\/sec\n
		rateSleepAlloc:\s+(\d+)\spages\/sec\n
		rateFree:\s+(\d+)\spages\/sec\n
		\n
		timer:\s+(\d+)\n
		start:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		guestType:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		lock:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		unlock:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		target:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		primNoSleepAlloc:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		primCanSleepAlloc:\s+(\d+)\s\(\s+(\d+)\sfailed\)\n
		primFree:\s+(\d+)\n
		errAlloc:\s+(\d+)\n
		errFree:\s+(\d+)\n
		/x,
};

sub vmmemctl_read {
	my $content = read_file(STATUS_FILE, err_mode => 'quiet');

	unless ($content) {
		ERROR(sprintf("Could not read: %s (%s)", STATUS_FILE, $ERRNO));
		return 0;
	}

	my ($target, $current, $rate_no_sleep_alloc, $rate_sleep_alloc,
		$rate_free, $timer, $start, $start_failed, $guest_type, $guest_type_failed,
		$lock, $lock_failed, $unlock, $unlock_failed, $target2, $target2_failed,
		$prim_no_sleep_alloc, $prim_no_sleep_alloc_failed,
		$prim_can_sleep_alloc, $prim_can_sleep_alloc_failed,
		$prim_free, $err_alloc, $err_free) = $content =~ EXTRACT_RE;

	unless (defined($target)) {
		ERROR("Extractor did not match");
		return 0;
	}

	my $vl = { plugin => PLUGIN, type => 'vmmemctl' };
	$vl->{'values'} = [
		PAGESIZE, $target, $current, $rate_no_sleep_alloc, $rate_sleep_alloc, $rate_free,
	];

	plugin_dispatch_values($vl);
	return 1;
}

sub vmmemctl_init {
	plugin_register (TYPE_READ, PLUGIN, 'vmmemctl_read');
}

plugin_register (TYPE_INIT, PLUGIN, 'vmmemctl_init');

1;
