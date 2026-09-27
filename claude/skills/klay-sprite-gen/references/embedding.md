# Embedding a clip on a site

## Markup

HEVC first: Safari only plays alpha from HEVC, and other browsers skip the `hvc1` source and take the WebM.

```html
<video class="gag" muted playsinline preload="none" poster="/img/gag.webp" width="300" height="400">
  <source src="/img/gag.mp4" type='video/mp4; codecs="hvc1"'>
  <source src="/img/gag.webm" type="video/webm">
</video>
```

## Playback rules

- Play once per visitor when it scrolls into view (IntersectionObserver + a localStorage flag wrapped in try/catch). Repeating a gag makes it stale.
- If the video has not reached `canplay` within ~1.5s of entering view, leave the poster; a late gag feels like a glitch.
- Skip entirely for `prefers-reduced-motion: reduce`, `navigator.connection.saveData`, or `effectiveType` of `2g`/`slow-2g`.
- Serve at native encode size; never let CSS upscale it on retina (blurry edges show the matte).

## Verifying

Use headless Playwright, not Claude-in-Chrome: the extension's tab is hidden, and hidden tabs never run the animation, so it will always look broken there. Screenshot mid-clip over the real page background to check the edges.
