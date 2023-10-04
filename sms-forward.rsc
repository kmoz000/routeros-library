#!rsc by RouterOS
# RouterOS script: sms-forward
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
#                         Anatoly Bubenkov <bubenkoff@gmail.com>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# forward SMS to e-mail
# https://git.eworm.de/cgit/routeros-scripts/about/doc/sms-forward.md

:local 0 "sms-forward";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Identity;
:global SmsForwardHooks;

:global IfThenElse;
:global LogPrintExit2;
:global ScriptLock;
:global SendNotification2;
:global SymbolForNotification;
:global ValidateSyntax;
:global WaitFullyConnected;

$ScriptLock $0;

:if ([ /tool/sms/get receive-enabled ] = false) do={
  $LogPrintExit2 warning $0 ("Receiving of SMS is not enabled.") true;
}

$WaitFullyConnected;

:local Settings [ /tool/sms/get ];

:if ([ /interface/lte/get ($Settings->"port") running ] != true) do={
  $LogPrintExit2 info $0 ("The LTE interface is not in running state, skipping.") true;
}

# forward SMS in a loop
:while ([ :len [ /tool/sms/inbox/find ] ] > 0) do={
  :local Phone [ /tool/sms/inbox/get ([ find ]->0) phone ];
  :local Messages "";
  :local Delete ({});

  :foreach Sms in=[ /tool/sms/inbox/find where phone=$Phone ] do={
    :local SmsVal [ /tool/sms/inbox/get $Sms ];

    :if ($Phone = $Settings->"allowed-number" && \
        ($SmsVal->"message")~("^:cmd " . $Settings->"secret" . " script ")) do={
      $LogPrintExit2 debug $0 ("Removing SMS, which started a script.") false;
      /tool/sms/inbox/remove $Sms;
    } else={
      :set Messages ($Messages . "\n\nOn " . $SmsVal->"timestamp" . \
          " type " . $SmsVal->"type" . ":\n" . $SmsVal->"message");
      :foreach Hook in=$SmsForwardHooks do={
        :if ($Phone~($Hook->"allowed-number") && ($SmsVal->"message")~($Hook->"match")) do={
          :if ([ $ValidateSyntax ($Hook->"command") ] = true) do={
            $LogPrintExit2 info $0 ("Running hook '" . $Hook->"match" . "': " . \
                $Hook->"command") false;
            :do {
              [ :parse ($Hook->"command") ];
              :set Messages ($Messages . "\n\nRan hook '" . $Hook->"match" . "':\n" . \
                  $Hook->"command");
            } on-error={
              $LogPrintExit2 warning $0 ("The code for hook '" . $Hook->"match" . \
                  "' failed to run!") false;
            }
          } else={
            $LogPrintExit2 warning $0 ("The code for hook '" . $Hook->"match" . \
                "' failed syntax validation!") false;
          }
        }
      }
      :set Delete ($Delete, $Sms);
    }
  }

  :if ([ :len $Messages ] > 0) do={
    :local Count [ :len $Delete ];
    $SendNotification2 ({ origin=$0; \
      subject=([ $SymbolForNotification "incoming-envelope" ] . "SMS Forwarding from " . $Phone); \
      message=("Received " . [ $IfThenElse ($Count = 1) "this message" ("these " . $Count . " messages") ] . \
        " by " . $Identity . " from " . $Phone . ":" . $Messages) });
    :foreach Sms in=$Delete do={
      /tool/sms/inbox/remove $Sms;
    }
  }
}
