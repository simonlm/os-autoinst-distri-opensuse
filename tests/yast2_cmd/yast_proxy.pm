# SUSE's openQA tests
#
# Copyright © 2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# All of cases is based on the reference:
# https://www.suse.com/documentation/sles-15/singlehtml/book_sle_admin/book_sle_admin.html#id-1.3.3.6.13.6.25

# Tips:The following issues are included in a bsc#1140156, that the testcase runtime needs to validate.
#  (1) yast proxy authentication command does not work.
#  (2) yast proxy commandline interface starts up the ncurses ui.
#  (3) yast proxy authentication clear command does not work.
#  (4) yast proxy set clear command does not work.

# Summary: Create regression test for yast proxy and verify:
#   Key Steps:
#     - Create check bsc#1140156 function.
#     - Set authentication to verify that the command runs successfully.
#     - Change proxy Settings.
#     - Clear the proxy setting.
# Maintainer: Ming Li <mli@suse.com>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;

sub yast_proxy {
    my ($str) = @_;
    type_string("yast proxy $str\n");
    wait_still_screen 2;
    check_screen([qw(yast-proxy_cmd_setting)], 5);
    if (match_has_tag "yast-proxy_cmd_setting") {
        record_soft_failure "bsc#1140156, yast proxy commandline interface starts up the ncurses ui";
        send_key "ret";
    }
    wait_still_screen 2;
    assert_script_run '$(exit $?)', fail_message => "yast command did not run successfully";
}

sub run {

    select_console("root-console");

    zypper_call "in yast2-proxy";

    yast_proxy("enable");

    yast_proxy("set https=proxy.example.com");

    # Displays proxy Settings and verify.
    validate_script_output("yast proxy summary 2>&1", sub { m/Proxy is enabled/; m/HTTPS Proxy: proxy.example.com/; });

    assert_script_run("yast proxy authentication username=tux password=secret");

    # Check that the configuration information is written to the .curlrc file, otherwise the bsc#1140156 is triggered.
    my $bugref = script_run("grep -i 'tux:secret' /root/.curlrc");
    record_soft_failure("bsc#1140156, yast proxy authentication command does not work") if ($bugref != 0);

    assert_script_run("yast proxy authentication clear");

    # Check the .curlrc file clears configuration information, otherwise the bsc#1140156 is triggered.
    $bugref = script_run("grep -i 'tux:secret' /root/.curlrc");
    record_soft_failure("bsc#1140156, yast proxy authentication clear command does not work") if ($bugref == 0);

    assert_script_run("yast proxy set clear");

    # Check the proxy file clears configuration information, otherwise the bsc#1140156 is triggered.
    $bugref = script_run("grep -i 'HTTPS_PROXY=\"proxy.example.com\"' /etc/sysconfig/proxy");
    record_soft_failure("bsc#1140156, yast proxy set clear command does not work") if ($bugref == 0);

    yast_proxy("disable");

    validate_script_output("yast proxy summary 2>&1", sub { m/Proxy is disabled/ });


}

1;
