#!rsc by RouterOS
# RouterOS script: dhcp-to-dns
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: lease-script, order=20
#
# check DHCP leases and add/remove/update DNS entries
# https://git.eworm.de/cgit/routeros-scripts/about/doc/dhcp-to-dns.md

:local 0 "dhcp-to-dns";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Domain;
:global Identity;

:global CharacterReplace;
:global EitherOr;
:global IfThenElse;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0 false 10;

:local Ttl 5m;
:local CommentPrefix ("managed by " . $0 . " for ");
:local CommentString ("--- " . $0 . " above ---");

:if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
  /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled static dns record with name '" . $CommentString . "'.") false;
}
:local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

:foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix) (!type or type=A) ] do={
  :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
  :local MacAddress [ $CharacterReplace ($DnsRecordVal->"comment") $CommentPrefix "" ];
  :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=$MacAddress active-address=($DnsRecordVal->"address") status=bound ] ] > 0) do={
    $LogPrintExit2 debug $0 ("Lease for " . $MacAddress . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting DNS entry.") false;
  } else={
    :local Found false;
    $LogPrintExit2 info $0 ("Lease expired for " . $MacAddress . " (" . $DnsRecordVal->"name" . "), deleting DNS entry.") false;
    /ip/dns/static/remove $DnsRecord;
    /ip/dns/static/remove [ find where type=CNAME comment=($DnsRecordVal->"comment") ];
  }
}

:foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
  :local LeaseVal;
  :do {
    :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
    :local DupMacLeases [ /ip/dhcp-server/lease/find where active-mac-address=($LeaseVal->"active-mac-address") status=bound ];
    :if ([ :len $DupMacLeases ] > 1) do={
      $LogPrintExit2 debug $0 ("Multiple bound leases found for mac-address " . ($LeaseVal->"active-mac-address") . ", using last one.") false;
      :set LeaseVal [ /ip/dhcp-server/lease/get ($DupMacLeases->([ :len $DupMacLeases ] - 1)) ];
    }
  } on-error={
    $LogPrintExit2 debug $0 ("A lease just vanished, ignoring.") false;
  }

  :if ([ :len ($LeaseVal->"active-address") ] > 0) do={
    :local Comment ($CommentPrefix . $LeaseVal->"active-mac-address");
    :local MacDash [ $CharacterReplace ($LeaseVal->"active-mac-address") ":" "-" ];
    :local HostName [ $CharacterReplace [ $EitherOr ([ $ParseKeyValueStore ($LeaseVal->"comment") ]->"hostname") ($LeaseVal->"host-name") ] " " "" ];
    :local Network [ /ip/dhcp-server/network/find where ($LeaseVal->"active-address") in address ];
    :local NetworkVal;
    :if ([ :len $Network ] > 0) do={
      :set NetworkVal [ /ip/dhcp-server/network/get ($Network->0) ];
    }
    :local NetworkInfo [ $ParseKeyValueStore ($NetworkVal->"comment") ];
    :local NetDomain ([ $IfThenElse ([ :len ($NetworkInfo->"name-extra") ] > 0) ($NetworkInfo->"name-extra" . ".") ] . \
      [ $EitherOr [ $EitherOr ($NetworkInfo->"domain") ($NetworkVal->"domain") ] $Domain ]);

    :local DnsRecord [ /ip/dns/static/find where comment=$Comment (!type or type=A) ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];

      :if ($DnsRecordVal->"address" = $LeaseVal->"active-address" && $DnsRecordVal->"name" = ($MacDash . "." . $NetDomain)) do={
        $LogPrintExit2 debug $0 ("DNS entry for " . $LeaseVal->"active-mac-address" . " does not need updating.") false;
      } else={
        $LogPrintExit2 info $0 ("Replacing DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $LeaseVal->"active-address" . ").") false;
        /ip/dns/static/set address=($LeaseVal->"active-address") name=($MacDash . "." . $NetDomain) $DnsRecord;
      }

      :local Cname [ /ip/dns/static/find where comment=$Comment type=CNAME ];
      :if ([ :len $Cname ] = 0 && [ :len $HostName ] > 0) do={
        $LogPrintExit2 info $0 ("Host name appeared, adding CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/add name=($HostName . "." . $NetDomain) type=CNAME cname=($MacDash . "." . $NetDomain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
      :if ([ :len $Cname ] > 0 && [ /ip/dns/static/get $Cname name ] != ($HostName . "." . $NetDomain)) do={
        $LogPrintExit2 info $0 ("Host name or domain changed, updating CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/set name=($HostName . "." . $NetDomain) cname=($MacDash . "." . $NetDomain) $Cname;
      }
    } else={
      $LogPrintExit2 info $0 ("Adding new DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $LeaseVal->"active-address" . ").") false;
      /ip/dns/static/add name=($MacDash . "." . $NetDomain) type=A address=($LeaseVal->"active-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      :if ([ :len $HostName ] > 0) do={
        $LogPrintExit2 info $0 ("Adding new CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/add name=($HostName . "." . $NetDomain) type=CNAME cname=($MacDash . "." . $NetDomain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }
  } else={
    $LogPrintExit2 debug $0 ("No address available... Ignoring.") false;
  }
}
