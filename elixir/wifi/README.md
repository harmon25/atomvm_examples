# Wifi

AtomVM Elixir Wifi Examples

## WifiAP

Launches an access point that can be connected to in order to set wifi credentials to be saved in nvs for subsequent boots. If the saved network credentials fail to connect, nvs should be wiped and device rebooted to setup new credentials.

```sh

mix atomvm.esp32.flash --port /dev/tty.usbmodem2101
```
