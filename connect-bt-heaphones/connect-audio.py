#!/usr/bin/env python
#
# Toggles headset connection https://askubuntu.com/questions/48001/connect-to-bluetooth-device-from-command-line
#

from __future__ import print_function
from __future__ import unicode_literals

import dbus
from dbus.mainloop.glib import DBusGMainLoop

def find_headset(bus):
  manager = dbus.Interface(bus.get_object("org.bluez", "/"),
                           "org.freedesktop.DBus.ObjectManager")
  objects = manager.GetManagedObjects()

  for path, ifaces in objects.items():
    if ("org.bluez.Device1" in ifaces and
        "org.freedesktop.DBus.Properties" in ifaces):
      iprops = dbus.Interface(
          bus.get_object("org.bluez", path),
          "org.freedesktop.DBus.Properties")
      props = iprops.GetAll("org.bluez.Device1")
      # Looking for a headset. Could also match on other properties like
      # "Name". See bluez docs for whats available.
      if props.get("Class") == 0x240404:
        if props.get("Connected"):
          print("Found headset {} ({}) but it is already connected"
                .format(props.get("Name"), props.get("Address")))
          continue
        return path

dbus_loop = DBusGMainLoop()
bus = dbus.SystemBus(mainloop=dbus_loop)
hpath = find_headset(bus)

if hpath:
  adapter = dbus.Interface(
      bus.get_object("org.bluez", hpath), "org.bluez.Device1")
  adapter.Connect()
