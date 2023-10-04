#!rsc by RouterOS
# RouterOS script: mod/bridge-port-to
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# reset bridge ports to default bridge
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/bridge-port-to.md

:global BridgePortTo;

:set BridgePortTo do={
  :local BridgePortTo [ :tostr $1 ];

  :global IfThenElse;
  :global LogPrintExit2;
  :global ParseKeyValueStore;

  :local InterfaceReEnable ({});
  :foreach BridgePort in=[ /interface/bridge/port/find where !(comment=[]) ] do={
    :local BridgePortVal [ /interface/bridge/port/get $BridgePort ];
    :foreach Config,BridgeDefault in=[ $ParseKeyValueStore ($BridgePortVal->"comment") ] do={
      :if ($Config = $BridgePortTo) do={
        :local DHCPClient [ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ];

        :if ($BridgeDefault = "dhcp-client") do={
          :if ([ :len $DHCPClient ] != 1) do={
            $LogPrintExit2 warning $0 ([ $IfThenElse ([ :len $DHCPClient ] = 0) "Missing" "Duplicate" ] . \
                " dhcp client configuration for interface " . $BridgePortVal->"interface" . "!") true;
          }
          :local DHCPClientDisabled [ /ip/dhcp-client/get $DHCPClient disabled ];

          :if ($BridgePortVal->"disabled" = false || $DHCPClientDisabled = true) do={
            $LogPrintExit2 info $0 ("Disabling bridge port for interface " . $BridgePortVal->"interface" . ", enabling dhcp client.") false;
            /interface/bridge/port/disable $BridgePort;
            :delay 200ms;
            /ip/dhcp-client/enable $DHCPClient;
          }
        } else={
          :if ($BridgePortVal->"disabled" = true || $BridgeDefault != $BridgePortVal->"bridge") do={
            $LogPrintExit2 info $0 ("Enabling bridge port for interface " . $BridgePortVal->"interface" . ", changing to " . $BridgePortTo . \
                " bridge " . $BridgeDefault . ", disabling dhcp client.") false;
            :if ([ :len $DHCPClient ] = 1) do={
              /ip/dhcp-client/disable $DHCPClient;
              :delay 200ms;
            }
            :local Disable [ /interface/ethernet/find where name=$BridgePortVal->"interface" ];
            :if ([ :len $Disable ] > 0) do={
              /interface/ethernet/disable $Disable;
              :set InterfaceReEnable ($InterfaceReEnable, $Disable);
            }
            /interface/bridge/port/set disabled=no bridge=$BridgeDefault $BridgePort;
          } else={
            $LogPrintExit2 debug $0 ("Interface " . $BridgePortVal->"interface" . " already connected to " . $BridgePortTo . \
                " bridge " . $BridgeDefault . ".") false;
          }
        }
      }
    }
  }
  :if ([ :len $InterfaceReEnable ] > 0) do={
    :delay 5s;
    $LogPrintExit2 info $0 ("Re-enabling interfaces...") false;
    /interface/ethernet/enable $InterfaceReEnable;
  }
}
