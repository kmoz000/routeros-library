Download, import and update firewall address-lists
==================================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script downloads, imports and updates firewall address-lists. Its main
purpose is to block attacking ip addresses, spam hosts, command-and-control
servers and similar malicious entities. The default configuration contains
lists from [abuse.ch](https://abuse.ch/) and
[dshield.org](https://dshield.org/), and
lists from [spamhaus.org](https://spamhaus.org/) are prepared.

The address-lists are updated in place, so after initial import you will not
see situation when the lists are not populated.

To mitigate man-in-the-middle attacks with altered lists the server's
certificate is checked.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate fw-addr-lists;

And add two schedulers, first one for initial import after startup, second
one for subsequent updates:

    /system/scheduler/add name="fw-addr-lists@startup" start-time=startup on-event="/system/script/run fw-addr-lists;";
    /system/scheduler/add name="fw-addr-lists" start-time=startup interval=2h on-event="/system/script/run fw-addr-lists;";

> ℹ️ **Info**: Modify the interval to your needs, but it is recommended to
> use less than half of the configured timeout for expiration.

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `FwAddrLists`: a list of firewall address-lists to download and import
* `FwAddrListTimeOut`: the timeout for expiration without renew

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Naming a certificate for a list makes the script verify the server
certificate, so you should add that if possible. Some certificates are
available in my repository and downloaded automatically. Import it manually
(menu `/certificate/`) if missing.

Create firewall rules to process the packets that are related to addresses
from address-lists. This rejects the packets from and to ip addresses listed
in address-list `block`.

    /ip/firewall/filter/add chain=input src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=forward src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=forward dst-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=output dst-address-list=block action=reject reject-with=icmp-admin-prohibited;

You may want to have an address-list to allow specific addresses, as prepared
with a list `allow`. In fact you can use any list name, just change the
default ones or add your own - matching in configuration and firewall rules.

    /ip/firewall/filter/add chain=input src-address-list=allow action=accept;
    /ip/firewall/filter/add chain=forward src-address-list=allow action=accept;
    /ip/firewall/filter/add chain=forward dst-address-list=allow action=accept;
    /ip/firewall/filter/add chain=output dst-address-list=allow action=accept;

Modify these for your needs, but **most important**: Move the rules up in
chains and make sure they actually take effect as expected!

Alternatively handle the packets in firewall's raw section if you prefer:

    /ip/firewall/raw/add chain=prerouting src-address-list=block action=drop;
    /ip/firewall/raw/add chain=prerouting dst-address-list=block action=drop;
    /ip/firewall/raw/add chain=output dst-address-list=block action=drop;

> ⚠️ **Warning**: Just again... The order of firewall rules is important. Make
> sure they actually take effect as expected!

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
