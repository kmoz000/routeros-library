#!rsc by RouterOS
# RouterOS script: telegram-chat
# Copyright (c) 2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# use Telegram to chat with your Router and send commands
# https://git.eworm.de/cgit/routeros-scripts/about/doc/telegram-chat.md

:local 0 "telegram-chat";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Identity;
:global TelegramChatActive;
:global TelegramChatGroups;
:global TelegramChatId;
:global TelegramChatIdsTrusted;
:global TelegramChatOffset;
:global TelegramChatRunTime;
:global TelegramTokenId;

:global CertificateAvailable;
:global EitherOr;
:global EscapeForRegEx;
:global GetRandom20CharAlNum;
:global IfThenElse;
:global LogPrintExit2;
:global MkDir;
:global ScriptLock;
:global SendTelegram2;
:global SymbolForNotification;
:global ValidateSyntax;
:global WaitForFile;
:global WaitFullyConnected;

$ScriptLock $0;

$WaitFullyConnected;

:if ([ :typeof $TelegramChatOffset ] != "array") do={
  :set TelegramChatOffset { 0; 0; 0 };
}

:if ([ $CertificateAvailable "Go Daddy Secure Certificate Authority - G2" ] = false) do={
  $LogPrintExit2 warning $0 ("Downloading required certificate failed.") true;
}

:local JsonGetKey do={
  :local Array [ :toarray $1 ];
  :local Key   [ :tostr $2 ];

  :for I from=0 to=([ :len $Array ] - 1) do={
    :if (($Array->$I) = $Key) do={
      :if ($Array->($I + 1) = ":") do={
        :return ($Array->($I + 2));
      }
      :return [ :pick ($Array->($I + 1)) 1 [ :len ($Array->($I + 1)) ] ];
    }
  }

  :return false;
}

:local Data;
:do {
  :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
    ("https://api.telegram.org/bot" . $TelegramTokenId . "/getUpdates?offset=" . \
    $TelegramChatOffset->0 . "&allowed_updates=%5B%22message%22%5D") as-value ]->"data");
  :set Data [ :pick $Data ([ :find $Data "[" ] + 1) ([ :len $Data ] - 2) ];
} on-error={
  $LogPrintExit2 debug $0 ("Failed getting updates from Telegram.") true;
}

:local UpdateID 0;
:local Uptime [ /system/resource/get uptime ];
:foreach Update in=[ :toarray $Data ] do={
  :set UpdateID [ $JsonGetKey $Update "update_id" ];
  :if (($TelegramChatOffset->0 > 0 || $Uptime > 5m) && $UpdateID >= $TelegramChatOffset->2) do={
    :local Trusted false;
    :local Message [ $JsonGetKey $Update "message" ];
    :local MessageId [ $JsonGetKey $Message "message_id" ];
    :local From [ $JsonGetKey $Message "from" ];
    :local FromID [ $JsonGetKey $From "id" ];
    :local FromUserName [ $JsonGetKey $From "username" ];
    :local ChatID [ $JsonGetKey [ $JsonGetKey $Message "chat" ] "id" ];
    :local Text [ $JsonGetKey $Message "text" ];
    :foreach IdsTrusted in=($TelegramChatId, $TelegramChatIdsTrusted) do={
      :if ($FromID = $IdsTrusted || $FromUserName = $IdsTrusted) do={
        :set Trusted true;
      }
    }

    :if ($Trusted = true) do={
      :if ([ :pick $Text 0 1 ] = "!") do={
        :if ($Text ~ ("^! *(" . [ $EscapeForRegEx $Identity ] . "|@" . $TelegramChatGroups . ")\$")) do={
          :set TelegramChatActive true;
        } else={
          :set TelegramChatActive false;
        }
        $LogPrintExit2 info $0 ("Now " . [ $IfThenElse $TelegramChatActive "active" "passive" ] . \
          " from update " . $UpdateID . "!") false;
      } else={
        :if ($TelegramChatActive = true && $Text != false && [ :len $Text ] > 0) do={
          :if ([ $ValidateSyntax $Text ] = true) do={
            :local State "";
            :local File ("tmpfs/telegram-chat/" . [ $GetRandom20CharAlNum 6 ]);
            $MkDir "tmpfs/telegram-chat";
            $LogPrintExit2 info $0 ("Running command from update " . $UpdateID . ": " . $Text) false;
            :execute script=(":do {\n" . $Text . "\n} on-error={ /file/add name=\"" . $File . ".failed\" };" . \
              "/file/add name=\"" . $File . ".done\"") file=$File;
            :if ([ $WaitForFile ($File . ".done") [ $EitherOr $TelegramChatRunTime 20s ] ] = false) do={
              :set State "The command did not finish, still running in background.\n\n";
            }
            :if ([ :len [ /file/find where name=($File . ".failed") ] ] > 0) do={
              :set State "The command failed with an error!\n\n";
            }
            :local Content [ /file/get ($File . ".txt") contents ];
            $SendTelegram2 ({ origin=$0; chatid=$ChatID; silent=false; replyto=$MessageId; \
              subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
              message=("Command:\n" . $Text . "\n\n" . $State . [ $IfThenElse ([ :len $Content ] > 0) \
                ("Output:\n" . $Content) [ $IfThenElse ([ /file/get ($File . ".txt") size ] > 0) \
                ("Output exceeds file read size.") ("No output.") ] ]) });
            /file/remove "tmpfs/telegram-chat";
          } else={
            $LogPrintExit2 info $0 ("The command from update " . $UpdateID . " failed syntax validation!") false;
            $SendTelegram2 ({ origin=$0; chatid=$ChatID; silent=false; replyto=$MessageId; \
              subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
              message=("Command:\n" . $Text . "\n\nThe command failed syntax validation!") });
          }
        }
      }
    } else={
      :local Message ("Received a message from untrusted contact " . \
        [ $IfThenElse ($FromUserName = false) "without username" ("'" . $FromUserName . "'") ] . \
        " (ID " . $FromID . ") in update " . $UpdateID . "!");
      :if ($Text ~ ("^! *" . [ $EscapeForRegEx $Identity ] . "\$")) do={
        $LogPrintExit2 warning $0 $Message false;
        $SendTelegram2 ({ origin=$0; chatid=$ChatID; silent=false; replyto=$MessageId; \
          subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
          message=("You are not trusted.") });
      } else={
        $LogPrintExit2 info $0 $Message false;
      }
    }
  } else={
    $LogPrintExit2 debug $0 ("Already handled update " . $UpdateID . ".") false;
  }
}
:set TelegramChatOffset ([ :pick $TelegramChatOffset 1 3 ], \
  [ $IfThenElse ($UpdateID >= $TelegramChatOffset->2) ($UpdateID + 1) ($TelegramChatOffset->2) ]);
