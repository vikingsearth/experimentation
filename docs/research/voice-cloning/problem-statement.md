# Problem statement - a voice clone that keeps its accent

Date: 2026-10-09
Status: draft, agreed between Wikus and Claude in session
Related: [hypothesis_1.md](hypothesis_1.md)

## The gripe, as originally stated

> I sound like fucked up american with the way the model is twisting my
> afrikaans accent while I'm speaking english

And, once the best zero-shot settings were found:

> a lot of places the genned voice would inflect up in a sentence instead of
> down like it should

## Where this came from

A two-minute narrated slide deck needed a voice-over. The narration was
generated with [Chatterbox](https://github.com/resemble-ai/chatterbox) (Resemble
AI, MIT licence), an open text-to-speech model that can clone a voice from a
short reference recording - "zero-shot", meaning no training, just a sample.

The clone got the *voice* right and the *accent* wrong.

## Why zero-shot cloning drifts American

Chatterbox is two models in a row:

```text
text --> T3 -----------------> S3Gen ---------------> audio
         0.5B language model    flow-matching decoder
         picks speech tokens    turns tokens into sound
         (what is said, and     (what the voice sounds
          how: vowels, rhythm,   like: timbre, pitch
          pitch shape)           range)
```

| Part | Reads from the reference clip | Learned its habits from |
| --- | --- | --- |
| T3 | the first **6 s**, as prompt tokens | its training data, mostly American English |
| S3Gen | the first **10 s**, as a speaker embedding | the reference, strongly |

ELI5: S3Gen is a good mimic of *how your throat sounds*. T3 decides *which
sounds to make*, and it only ever learned to make them the American way. Six
seconds of you is a hint, not a lesson. So the output is your voice doing an
American accent badly, with American question-style rising pitch where a South
African speaker would fall at the end of a statement.

## What was already tried

Four zero-shot settings were rendered on the same sentence and judged by ear.

| Take | Settings | Verdict |
| --- | --- | --- |
| baseline | exaggeration 0.5, cfg 0.4, temperature 0.75 | better than the earlier sped-up take, still American |
| higher cfg | exaggeration 0.4, cfg 0.6, temperature 0.6 | similar |
| **highest cfg, calmest** | **exaggeration 0.3, cfg 0.7, temperature 0.6** | **best of the four, used for the deck** |
| different 10 s of reference | as the higher-cfg take | drifted Australian |

Two dead ends were found on the way:

- **Speeding up the output** (1.1x via librosa time-stretch) made it tinny and
  rushed. The phase vocoder smears the audio. Speed is not a lever.
- **Which slice of the reference** matters more than how long it is, because T3
  only reads 6 s of it.

Settings move the result a little. They cannot teach T3 an accent it never saw.

## What "better" means here

| Dimension | What is measured |
| --- | --- |
| Accent | Does it sound South African, specifically like Wikus, and not American or Australian |
| Intonation | Do statements fall at the end, the way he speaks, instead of rising |
| Identity | Would someone who knows him believe it is him |
| Clarity | Every word intelligible, no invented filler words, no tinniness |

## Constraints

- **Own voice only.** The training audio is Wikus reading, with his consent, for
  his use.
- **The voice stays private.** Training audio, reference clips and fine-tuned
  weights are a better clone than anything public. They never go to a public
  repo. Method and results can be published; the voice itself lives with Wikus
  and in a private repo at most.
- **Keep the watermark.** Chatterbox embeds an inaudible Perth watermark in
  everything it generates. Leave it on, so generated audio stays identifiable as
  generated.
- **Local compute first.** The training runs on a 36 GB Apple Silicon Mac. If
  that proves impractical, that is a finding, not a failure.
- **Vetted dependencies.** New packages come from PyPI and are checked before
  install. A community fine-tuning repo gets read in full before anything of it
  is run.
