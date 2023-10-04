Manage DNS and DoH servers from netwatch
========================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script reads server state from netwatch and manages used DNS and
DoH (DNS over HTTPS) servers.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate netwatch-dns;

Then add a scheduler to run it periodically:

    /system/scheduler/add interval=1m name=netwatch-dns on-event="/system/script/run netwatch-dns;" start-time=startup;

Configuration
-------------

The DNS and DoH servers to be checked have to be added to netwatch with
specific comment:

    /tool/netwatch/add comment="doh" host=1.1.1.1;
    /tool/netwatch/add comment="dns" host=8.8.8.8;
    /tool/netwatch/add comment="doh, dns" host=9.9.9.9;

This will configure *cloudflare-dns* for DoH (`https://1.1.1.1/dnsquery`), and
*google-dns* and *quad-nine* for regular DNS (`8.8.8.8,9.9.9.9`) if up.
If *cloudflare-dns* is down the script will fall back to *quad-nine* for DoH.

Giving a specific query url for DoH is possible:

    /tool/netwatch/add comment="doh, doh-url=https://dns.nextdns.io/dns-query" host=199.247.16.158;

Note that using a name in DoH url may introduce a chicken-and-egg issue!

Importing a certificate automatically is possible, at least if available in
the repository (see `certs` sub directory).

    /tool/netwatch/add comment="doh, doh-cert=DigiCert TLS Hybrid ECC SHA384 2020 CA1" host=1.1.1.1;
    /tool/netwatch/add comment="doh, doh-cert=DigiCert TLS Hybrid ECC SHA384 2020 CA1" host=9.9.9.9;
    /tool/netwatch/add comment="doh, doh-cert=GTS CA 1C3" host=8.8.8.8;

Sometimes using just one specific (possibly internal) DNS server may be
desired, with fallback in case it fails. This is possible as well:

    /tool/netwatch/add comment="dns" host=10.0.0.10;
    /tool/netwatch/add comment="dns-fallback" host=1.1.1.1;

Tips & Tricks
-------------

### Use in combination with notifications

Netwatch entries can be created to work with both - this script and
[netwatch-notify](netwatch-notify.md). Just give options for both:

    /tool/netwatch/add comment="doh, notify, name=cloudflare-dns" host=1.1.1.1;

Also this allows to update host address, see option `resolve`.

See also
--------

* [Notify on host up and down](netwatch-notify.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
