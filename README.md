![hypixel-nim banner](https://knaque.dev/ext/hypixel_banner.png)

A pure-Nim interface for the Hypixel API.

The Friends and Guilds APIs are more or less complete. The Player API still needs work, though.

I think I've alleviated crashes as much as I can, but I'm not making any promises.
However, instead of crashing, the API will either return the type's default value or an empty `Option`.
This headache is because the Hypixel API was designed by monkeys on typewriters, and any given field may or may not exist, may have a duplicate somewhere else, may exist under a completely different name, or so forth. It's miserable, but a default value is better than a crash.

PRs welcome!