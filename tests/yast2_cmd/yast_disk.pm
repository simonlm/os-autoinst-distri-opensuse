# SUSE's openQA tests
#
# Copyright © 2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# All of cases is based on the reference:
# https://documentation.suse.com/sles/15-SP1/single-html/SLES-admin/#id-1.3.3.6.13.6.12

# Tips: This testcase only runs on the sles12 platform.
#   Use the lsblk command to get the valid disk and LVM vg names in the system.
#   Use the lsblk command to obtain the valid partition name and LVM lv name in
#   the system with UUID number and formatted, lv name also needs to analyze and
#   process possible special characters in it to get the normal vg+lv name in the
#   system. Compare the obtained disk and partition name with the information loop
#   listed in the 'yast disk list' command, ensure that all valid disks and
#   partitions identified in the system are exactly the same as those listed
#   in the 'yast disk list' command.
#       LVM vg+lv names with special characters, for example:
#   before: abcd------as-----adfwef------_----------a after: abcd---as--/adfwef---_-----a
#           datavg--c-12312_c5_.3                            datavg-c/12312_c5_.3
#
# Summary: Create regression test for yast disk and verify:
#   Key Steps:
#     - Lists all configured disks in the system.
#     - Lists all partitions in the system.
# Maintainer: Ming Li <mli@suse.com>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;

sub run {
    select_console 'root-console';

    zypper_call "in yast2-storage";

    my @disks = split(/\n+/, script_output(q{lsblk -l|perl -lane 'if ($F[5] eq "lvm" || $F[5] eq "disk") {$F[0] =~ s/(?<=[^-])((?:--)*)-(?=[^-]).*/$1/; $F[0] =~ s/--/-/g; print $F[0]}'|sort -u}));
    my @partitions = split(/\n+/, script_output(q{lsblk -lo NAME,TYPE,UUID,FSTYPE|perl -alne 'if ($.>=2 && $F[3] && $F[3] ne "LVM2_member") {$F[0] =~ s/(?<=[^-])((?:--)*)-(?=[^-])/$1\//; $F[0] =~ s/--/-/g; print "$F[0]"}'}));
    validate_script_output("yast disk list disks 2>&1",      sub { foreach my $dict (@disks) {      if ($_ !~ m/\Q$dict\E/) { return 0; } } return 1; });
    validate_script_output("yast disk list partitions 2>&1", sub { foreach my $pact (@partitions) { if ($_ !~ m/\Q$pact\E/) { return 0; } } return 1; });
}

1;
