# HDMI Defrag v0.1

A tiny macOS menu bar app that fixes the HDMI flicker on Apple silicon Macs
(most notoriously the M4 Mac mini) by turning off GPU-level temporal
dithering.

## What the flicker actually is

Plug an Apple silicon Mac into a lot of HDMI monitors and TVs and the picture
never quite sits still. Flat areas look faintly grainy, like film grain that
won't settle. Solid dark greys and skin tones shimmer. Move a window over a
gradient and you can watch a fine sparkle crawl across it. It is subtle enough
that plenty of people never consciously notice it, and pronounced enough that
others get headaches and eyestrain within an hour.

It is not a bad cable, a failing panel, or a refresh rate problem, which is why
swapping hardware never fixes it. It is the GPU doing something deliberate.

### Temporal dithering

A display can only show so many distinct shades per channel. When the GPU wants
a color that falls between two shades the panel can actually produce, it fakes
the in-between by rapidly alternating the pixel between the shade just below and
the shade just above, frame after frame. Averaged over time by your eye, that
reads as the intermediate color. This is temporal dithering, and it is genuinely
clever: it buys extra apparent color depth for free, smoothing away the banding
you would otherwise see in gradients and dark scenes.

The catch is that it depends on your eye blending the alternating frames into
one steady color. That blending works when the flipping is fast, consistent, and
lands on a panel that changes state cleanly. Over HDMI it often does not:

- Many HDMI displays and TVs add their own processing, motion interpolation, or
  overdrive on top, which amplifies the per frame differences instead of
  averaging them out.
- The link may be carrying a reduced color format such as 8 bit or 4:2:2
  chroma subsampling, so the dithering is working harder, across bigger gaps
  between shades, to fake depth the connection is not carrying.
- Panel response times are uneven, so the two alternating shades do not hold
  for equal amounts of time.

When any of that happens the alternation stops averaging cleanly and starts
reading as what it physically is: pixels visibly changing many times per second.
That is the flicker. It is worst on the M4 Mac mini, whose HDMI output people
complain about constantly, but it shows up across Apple silicon.

macOS gives you no setting for this. The switch exists, but it lives in an IOKit
property called `enableDither` on the per display `IOMobileFramebufferAP`
service, with nothing in System Settings exposing it.

### What this app does

It sets `enableDither` to `No` on every connected display and keeps it that way.
You trade the dithering for the thing it was hiding, so on some displays you may
notice slightly more visible banding in dark gradients. Most people who are
bothered by the flicker find that a very easy trade, and the menu bar toggle
lets you flip it back in a second to compare.

It is a from scratch reimplementation of the technique
[Stillcolor](https://github.com/aiaf/Stillcolor) figured out, restructured with
a few differences:

- **No App Sandbox.** Stillcolor sandboxes itself (presumably for Mac App
  Store distribution) and needs a `iokit-set-properties` sandbox exception
  entitlement to punch a hole in it. Since this isn't going through the App
  Store, it just skips the sandbox entirely. Simpler, and there's nothing to
  work around.
- **Verifies, doesn't just trust.** The menu shows what `ioreg` actually
  reports back after every apply, not just "I sent the command."
- **Reapplies on wake, not just reconnect.** In addition to watching
  `CGDisplayReconfigurationCallback` (display connect/disconnect/enable), it
  also reapplies on `NSWorkspace.didWakeNotification`, since the flag can reset
  across sleep/wake too.
- **Login item via a plain LaunchAgent**, not `SMAppService`, which avoids
  needing a fully Xcode-signed bundle identity for something this small.

## Install

Grab `HDMIDefrag.zip` from the [latest release](https://github.com/totokuku/hdmi-defrag/releases/latest),
unzip it, and drag `HDMIDefrag.app` to `/Applications`.

**Apple silicon only** (arm64). That's not a limitation so much as the point,
since the dithering behaviour this works around is specific to Apple silicon
GPUs. macOS 13 or newer.

### First launch: getting past Gatekeeper

The app is ad-hoc signed, not notarized, because I'm not paying Apple $99/yr
to distribute a 176 KB menu bar utility. macOS will refuse to open it the first
time with *"Apple could not verify..."*. To let it through:

1. Try to open the app once. It gets blocked, and that step is required: it's
   what puts the app in the list.
2. Go to **System Settings -> Privacy & Security**, scroll down, and click
   **Open Anyway** next to HDMIDefrag.
3. Confirm.

On macOS 15 (Sequoia) and later this is the *only* way. The old
right-click, then Open shortcut no longer bypasses Gatekeeper.

Or, from the terminal:

```sh
xattr -d com.apple.quarantine /Applications/HDMIDefrag.app
```

If you'd rather not trust a stranger's binary, that's entirely reasonable.
Build it yourself from source below. It's about 550 lines and takes a few
seconds to compile.

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
uncheck "Fix HDMI Flicker" in the menu before quitting. It resets on the
next reboot regardless.

## Credit

Technique discovered and documented by [Abdullah Arif's Stillcolor](https://github.com/aiaf/Stillcolor)
(MIT licensed). This is an independent reimplementation, not a fork: no code
was copied, but the hard part was knowing which IOKit property to reach for,
and that was Stillcolor's finding. Its license is reproduced in full under
"Third-party notices" in [LICENSE](LICENSE).

## License

MIT. See [LICENSE](LICENSE).
