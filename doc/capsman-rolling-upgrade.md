Run rolling CAP upgrades from CAPsMAN
=====================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

CAPsMAN can upgrade CAP devices. This script runs a rolling upgrade for
out-of-date CAP devices. The idea is to have just a fraction of devices
reboot at a time, having the others to serve wireless connectivity.

Note that the script does not wait for the CAPs to reconnect, it just defers
the upgrade commands. The more CAPs you have the more will upgrade in
parallel.

Requirements and installation
-----------------------------

Just install the script on CAPsMAN device. Depending on whether you use
`wifiwave2` package (`/interface/wifiwave2`) or legacy wifi with CAPsMAN
(`/caps-man`) you need to install a different script.

For `wifiwave2`:

    $ScriptInstallUpdate capsman-rolling-upgrade.wifiwave2;

For legacy CAPsMAN:

    $ScriptInstallUpdate capsman-rolling-upgrade.capsman;

Usage and invocation
--------------------

This script is intended as an add-on to
[capsman-download-packages](capsman-download-packages.md), being invoked by
that script when required.

Alternatively run it manually:

    /system/script/run capsman-rolling-upgrade.wifiwave2;

See also
--------

* [Download packages for CAP upgrade from CAPsMAN](capsman-download-packages.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
