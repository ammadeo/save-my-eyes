import shortUrl from "./assets/music/short.mp3";
import longUrl from "./assets/music/long.mp3";
import { settings } from "./settings";
import { log } from "./log";

/** Plays a cue if UI sounds are on; resolves when it ends (or fails). Replaces howler. */
function play(url: string): Promise<void> {
  if (!settings.sounds.ui) return Promise.resolve();
  return new Promise((resolve) => {
    const audio = new Audio(url);
    audio.addEventListener("ended", () => resolve(), { once: true });
    audio.addEventListener("error", () => resolve(), { once: true });
    audio.play().then(
      () => log.info(`sound: playing ${url.split("/").pop()}`),
      (error: unknown) => {
        log.warn("sound: play() rejected", error);
        resolve();
      },
    );
  });
}

export const playBreakSound = (long: boolean) => play(long ? longUrl : shortUrl);
