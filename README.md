DesktopSwitch
=============

This is getting really long in the tooth, but there still doesn't seem to be a good working desktop app out there for the Wemo outlets. It's clunky as all hell. It forms the XML requests without an actual UPnP library, and likely some day an update's going to break things enough that someone would actually have to do a proper UPnP implementation. A side effect is that after various restarts, etc. the switch can change IP address and/or port. If this happens, delete the entry for the switch and scan again. Push requests for fixing this clunkiness are welcome. It works on Sierra as of this commit.
