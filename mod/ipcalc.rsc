#!rsc by RouterOS
# RouterOS script: mod/ipcalc
# Copyright (c) 2020-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# ip address calculation
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/ipcalc.md

:global IPCalc;
:global IPCalcReturn;

# print netmask, network, min host, max host and broadcast
:set IPCalc do={
  :local Input [ :tostr $1 ];

  :global FormatLine;
  :global IPCalcReturn;
  :global PrettyPrint;

  :local Values [ $IPCalcReturn $1 ];

  $PrettyPrint ( \
    [ $FormatLine "Address" ($Values->"address") ] . "\n" . \
    [ $FormatLine "Netmask" ($Values->"netmask") ] . "\n" . \
    [ $FormatLine "Network" ($Values->"network") ] . "\n" . \
    [ $FormatLine "HostMin" ($Values->"hostmin") ] . "\n" . \
    [ $FormatLine "HostMax" ($Values->"hostmax") ] . "\n" . \
    [ $FormatLine "Broadcast" ($Values->"broadcast") ]);
}

# calculate and return netmask, network, min host, max host and broadcast
:set IPCalcReturn do={
  :local Input [ :tostr $1 ];
  :local Address [ :toip [ :pick $Input 0 [ :find $Input "/" ] ] ];
  :local Bits [ :tonum [ :pick $Input ([ :find $Input "/" ] + 1) [ :len $Input ] ] ];
  :local Mask ((255.255.255.255 << (32 - $Bits)) & 255.255.255.255);

  :local Return {
    "address"=$Address;
    "netmask"=$Mask;
    "networkaddress"=($Address & $Mask);
    "networkbits"=$Bits;
    "network"=(($Address & $Mask) . "/" . $Bits);
    "hostmin"=(($Address & $Mask) | 0.0.0.1);
    "hostmax"=(($Address | ~$Mask) ^ 0.0.0.1);
    "broadcast"=($Address | ~$Mask);
  }

  :return $Return;
}
