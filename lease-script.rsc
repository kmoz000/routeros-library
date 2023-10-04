#!rsc by RouterOS
# RouterOS script: lease-script
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# run scripts on DHCP lease
# https://git.eworm.de/cgit/routeros-scripts/about/doc/lease-script.md

:local 0 "lease-script";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Grep;
:global IfThenElse;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

:if ([ :typeof $leaseActIP ] = "nothing" || \
     [ :typeof $leaseActMAC ] = "nothing" || \
     [ :typeof $leaseServerName ] = "nothing" || \
     [ :typeof $leaseBound ] = "nothing") do={
  $LogPrintExit2 error $0 ("This script is supposed to run from ip dhcp-server.") true;
}

$LogPrintExit2 debug $0 ("DHCP Server " . $leaseServerName . " " . [ $IfThenElse ($leaseBound = 0) \
  "de" "" ] . "assigned lease " . $leaseActIP . " to " . $leaseActMAC) false;

$ScriptLock $0 false 10;

:if ([ :len [ /system/script/job/find where script=$0 ] ] > 1) do={
  $LogPrintExit2 debug $0 ("More invocations are waiting, exiting early.") true;
}

:local RunOrder ({});
:foreach Script in=[ /system/script/find where source~("\n# provides: lease-script\\b") ] do={
  :local ScriptVal [ /system/script/get $Script ];
  :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: lease-script, ") ] ];

  :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
}

:foreach Order,Script in=$RunOrder do={
  :do {
    $LogPrintExit2 debug $0 ("Running script with order " . $Order . ": " . $Script) false;
    /system/script/run $Script;
  } on-error={
    $LogPrintExit2 warning $0 ("Running script '" . $Script . "' failed!") false;
  }
}
