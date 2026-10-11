# Event ideas backlog — 2026-10-11 (Claude, for the owner; IDEAS ONLY, nothing built)

Brainstormed from the patterns in Grow a Garden's weather/event list (the owner pasted the wiki list). Every name
and design here is our own, adapted to Steal a Sprout's systems: nests and pods, carrying and stealing, bats, the
biomes, the Disco Mill, Dewberry-style pickups, the admin console and the weather. The owner said: "save it, i
might ask in the future". Nothing is queued; ask the owner before building any of it.

## Things fall from the sky

1. **Starfall:** shooting stars crash into the field and biomes, each leaving a rarer-than-usual pod. Everyone
   races to grab them and carry them home, and they can be stolen on the way. This is our stealing loop as an
   event.
2. **Pollen Puffs:** glowing puffs float up from the field, and popping them gives cash or tickets. Cheap to
   build: it reuses the Dewberry pickup code (EnchantedMistBerryService's spawn, claim and notice patterns).

## Boost windows

3. **Golden Hour:** 3 minutes where every plot's income is doubled and plants glow gold. Simple, and every
   player feels it.
4. **Restock Fever:** nests restock instantly with better rarity odds for 2 minutes. Pairs with the paid Server
   Luck product.

## Boss and raid

5. **Crow Raid:** a giant crow circles the map carrying a golden pod and swoops low over the plots. Hit it with
   your bat to make it drop the pod; whoever grabs it and gets it home keeps it. Uses the existing bats and
   stealing. Don't let the crow take players' own pods (frustrating).

## Minigames

6. **Sleeping Guardian:** red light, green light with Grovemaw. Move only while he sleeps; reach the end for a
   reward.
7. **Disco Floor:** on the Disco Mill floor, stand on the right colour each round. The last players standing win
   a disco title or cosmetic.
8. **Lost Sprout:** a lost baby creature hides somewhere on the map, with hints over time. The first to find it
   gets a pod.

## Teamwork

9. **Giant Sprout:** the whole server feeds a giant sprout at the hub with cash or berries. When it's full, it
   bursts and showers pods for everyone.

## Movement

10. **Dandelion Wind:** low gravity and faster running for a few minutes. Chases and escapes get wild.

## The big one: event variants

Grow a Garden's real hook is mutations: weather leaves a lasting mark on plants. Our version: **event variants**
on creatures, for example:

| Variant | Comes from |
|---|---|
| Soaked | Rain |
| Charged | Thunderstorm |
| Glowing | the Enchanted Mist |
| Disco | Disco |

Each variant visibly changes the plant and raises its income, about ×1.5 to ×3. That gives every event a
long-term reward and a reason to collect. It's a big system: it touches saves, income, cards, the hatch and the
Index.

## Claude's picks (2026-10-11)

- **Starfall** and **Crow Raid**: they fit the stealing core best.
- **Event variants**: the most long-term value.

## Rules to keep when building any of these

- Natural events stay separate from the admin console's.
- Admin-started ones get announced (the admin announcements item).
- The Enchanted Mist bans paid luck during the event.
- No real Robux purchases in tests.
- Test stores only; never publish.
