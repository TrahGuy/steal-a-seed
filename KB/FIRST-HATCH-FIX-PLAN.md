# First-hatch fix: the funnel's step 4 leak (2026-10-16, BUILT)

## Why

Creator Hub's onboarding funnel on 2026-10-16:
- Since the 10 Oct change (pods hatch in the Bag before they are placed), 280 of 525 new players banked a pod and only 159 hatched one. That is a 43% drop at step 4, "First Plant Hatched", the biggest in the funnel.
- Roughly 55% of bankers reached income after the change, against about 65% before it. Steps 5 and 6 stay near 100%: once the first plant hatches, the loop holds.

The first pod is the FIRST CATCH, always at least Big. Big's rung of the ladder is 60 s.

So, after the bank, a new player had to:
1. wait a minute;
2. open the Bag;
3. hold HATCH ALL.

## The owner's answers (2026-10-16, fourteen in all)

| Question | Answer |
| --- | --- |
| How fast is the first pod? | **Ready 10 s after banking.** Every later pod is unchanged. |
| Which pod gets the 10 s? | **The first pod a player ever banks**, even if the first pod they took was lost on the way home. |
| How is it hatched? | **A one-tap HATCH card for that pod only.** The Bag way still works; later pods use the Bag. |
| When does the card show? | **At the bank, counting down:** "YOUR POD IS GROWING…", "Ready in 0:07", a grey HATCH. |
| What happens at 0:00? | "YOUR POD IS READY!", a green HATCH, and the Mist's pod-ready ping (MistPodReady). |
| What is on the card? | The pod's own picture, its size and name ("BIG Petalpip"), and the words above, in Comic Neue. |
| Where does it stand? | **Lower middle, over the hotbar, no dimmer.** The game goes on round it. Phones get a smaller card clear of the thumbstick and jump. |
| Can it be closed? | **No close.** It stays until the pod hatches (card or Bag), and hides while a menu or reward moment is up. |
| What does HATCH do? | **Takes them home, then hatches.** TELEPORT TO PLOT's rules, onto their plot's spawn, facing the bed the plant comes up in. The hatch follows a moment later, in front of them, with the full reveal. |
| Instant Hatch (Robux) on that pod? | **Hidden.** |
| Who sees the card? | **Anyone whose first pod is unhatched**, including players who banked on an earlier visit and left. |
| The guide's words? | **"Tap HATCH when your pod is ready!"** The guide's hand points at the card from outside it once the pod is ready; there is no hand during the countdown. |
| What's New entry? | **No.** |
| After building? | **Push on the owner's OK, then the owner publishes.** |
| Analytics? | **Two events:** `FirstPodReady` and `FirstHatchCardPressed` (KB/ANALYTICS.md). |

## Where it lives

- **The 10 s:** FirstMinute.FirstHatchSeconds and FirstMinute.bankWait. CarryService's bank stamps it while `bank` is not yet done, and starts the FirstPodReady timer.
- **The flag:** PlayerDataService.PublishFirstHatch sets the player attribute GameConfig.FirstHatch.PendingAttribute. It is true from the first bank until the first hatch, published on load and on those two milestones.
- **The tap:** HatchInBag.FirstHatch calls PlantService.FirstHatch. Guards, in order:
  1. after the first hatch, the Bag's own verb answers;
  2. no pod, a pod not ready, or a pod already asked for: refused before anything moves;
  3. otherwise PlotService.TeleportTo onto FirstHatchCard.landing(spawn, bed);
  4. the Bag's HatchFromBag runs HatchDelaySeconds later, then Metrics.firstHatchCard, and the result goes back to the client.
- **The card:** Shared/FirstHatchCard holds the arithmetic and words; FirstHatchCard.client draws it. The camera's one turn is in ObbyCamera (FirstHatch.AskedAttribute, the server's landing).
- **The guide:** TutorialUI checks the card before a pod in the ground, so a new garden's starter pod hatching by itself never shows a second timer. TutorialData has the new words.
- **The Bag:** LoadoutUI shows no Instant Hatch while the flag is set.

## Tested

- **FirstHatchSpec 28/0**, including the card's rect on 5 desktop sizes and 9 phones.
- **21 mutants, all caught**, plus every neighbouring spec (KB/HANDOFF.md has the list).
- **Two guarded Plays on a brand-new test profile:** banked, a 10 s countdown, ready, HATCH, home facing the bed, the plant hatched in front, the guide on to step 7.

**Not seen on a real phone.** The analytics events are spec-only: the owner's own account is staff, so it is never counted.

## Afterwards

Read funnel step 4 from the publish that carries this, and the two events (KB/ANALYTICS.md says how).
