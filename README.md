# HDMI Defrag

A tiny macOS menu bar app that fixes the HDMI flicker on Apple silicon Macs
(most notoriously the M4 Mac mini) by turning off GPU-level temporal
dithering.

## Why

Apple silicon GPUs dither the framebuffer (alternate pixel values at the
refresh rate to fake more color depth than the panel/cable actually carries).
A lot of HDMI displays and TVs render that as visible flicker/noise, and some
people get eyestrain from it even when it's subtle. There's no user-facing
setting for it -- it lives in an IOKit property (`enableDither`) on the
per-display `IOMobileFramebufferAP` service.

This app flips that property off and keeps it off. It's a from-scratch
reimplementation of the same technique [Stillcolor](https://github.com/aiaf/Stillcolor)
figured out, restructured with a few differences:

- **No App Sandbox.** Stillcolor sandboxes itself (presumably for Mac App
  Store distribution) and needs a `iokit-set-properties` sandbox exception
  entitlement to punch a hole in it. Since this isn't going through the App
  Store, it just skips the sandbox entirely -- simpler, and there's nothing to
  work around.
- **Verifies, doesn't just trust.** The menu shows what `ioreg` actually
  reports back after every apply, not just "I sent the command."
- **Reapplies on wake, not just reconnect.** In addition to watching
  `CGDisplayReconfigurationCallback` (display connect/disconnect/enable), it
  also reapplies on `NSWorkspace.didWakeNotification`, since the flag can reset
  across sleep/wake too.
- **Login item via a plain LaunchAgent**, not `SMAppService` -- avoids needing
  a fully Xcode-signed bundle identity for something this small.

## Build & run

Requires Xcode Command Line Tools (or Xcode) and macOS 13+.

```sh
./scripts/build-app.sh
open .build/HDMIDefrag.app
```

To install it permanently:

```sh
cp -R .build/HDMIDefrag.app /Applications/
open /Applications/HDMIDefrag.app
```

Then enable "Launch at Login" from the menu bar icon.

## Verify it's working

```sh
ioreg -lw0 | grep -i enableDither
```

Every connected display should report `"enableDither" = No`. The app's menu
also shows this live ("Verified: dithering off").

## Uninstall

Toggle "Launch at Login" off first (or it'll leave a LaunchAgent behind), then:

```sh
rm -rf /Applications/HDMIDefrag.app
```

If dithering was on before you started using this and you want it back,
uncheck "Fix HDMI Flicker" in the menu before quitting -- it resets on the
next reboot regardless.

## Credit

Technique discovered and documented by [Abdullah Arif's Stillcolor](https://github.com/aiaf/Stillcolor)
(MIT licensed). This is an independent reimplementation, not a fork.

## License

MIT -- see [LICENSE](LICENSE).
