# Hypothesis 1 - fine-tuning T3 teaches the clone his accent

Date: 2026-10-09
Status: **draft, not started.**
Problem: [problem-statement.md](problem-statement.md)

## The hypothesis

> Fine-tuning Chatterbox's T3 model on recordings of Wikus reading English
> makes the clone sound like him - South African accent, falling intonation on
> statements - without losing clarity, and the improvement grows with the
> amount of training audio up to a point.

Two sub-claims, tested separately because they can fail separately:

| Claim | Fails if |
| --- | --- |
| H1a - accent and intonation improve over the best zero-shot take | listeners cannot tell the fine-tuned clone from zero-shot, or prefer zero-shot |
| H1b - the gain follows a dose-response curve over 10, 30 and 60 minutes | all three amounts sound the same, or more audio makes it worse |

## Why T3 and not S3Gen

The zero-shot clone already gets the timbre right, and timbre is S3Gen's job.
The accent and the pitch shape come from T3's choice of speech tokens. Training
T3 attacks the actual fault. S3Gen fine-tuning is kept as a later arm, in case
the voice quality slips once T3 changes what it feeds it.

## Data

### Many short clips, not one long recording

Training data is a set of utterances, each one a short audio file paired with
its exact transcript. Total duration is what counts, not one continuous take.
That is better, because the clips can cover the range of how he talks:

| Variety | Why it matters |
| --- | --- |
| Statements ending in a full stop | the falling intonation the zero-shot clone gets wrong |
| Questions | so the model learns where rising pitch *does* belong |
| Lists, commas, semicolons, asides in brackets | phrasing and pause length inside a sentence |
| Short punchy lines and long run-on ones | short lines are where Chatterbox invents filler words |
| Technical vocabulary (repo, Kafka, PR, ClickHouse) | the words the narration actually uses |
| Casual and "presenting" registers | the deck register, without it becoming an announcer voice |
| Afrikaans-flavoured English he actually uses ("jip", "lekker", "now now") | the accent lives partly in these |

### Recording

- Same room, same mic, same distance for every session, so the model learns his
  voice and not the room.
- Clips of 2 to 15 seconds of speech.
- The text is written in advance, in batches, for coverage of the table above.
  Because the text is known, there is nothing to transcribe.
- Read it through first, then say it the way you would tell it. Wikus read
  aloud a lot as a kid, at story times, so this is how he naturally reads.
- A few free-talk prompts per batch ("talk about what you did last weekend")
  capture his casual register. Only these need Whisper to write the transcript.
- Record in dose order: batch 1 is the 10-minute set, so the pipeline can be
  tested end to end before the long sessions.
- Target about 75 minutes of usable audio: 60 for training, 15 held back.

### The recorder

A local page, one line at a time. Recording, validating and accepting are three
separate steps, so a failed take comes back with a reason before it counts.

```text
read the line --> space: record --> space: stop, plays back
   --> enter: validate --> pass --> saved, crossed off, next line
                       --> fail --> reasons shown, record again
```

The browser's echo cancellation, noise suppression and auto gain are switched
off. Left on, that processing would be baked into the trained voice.

Each take goes through these gates, cheapest first:

| Gate | Rejects |
| --- | --- |
| Clipping | samples hitting full scale |
| Length | under 2 s or over 15 s of speech, after trimming silence |
| Breathing room | no silence before or after the speech |
| Noise floor | background above -55 dBFS |
| Level | speech quieter than -32 dBFS or hotter than -12 dBFS |
| Signal to noise | speech less than 30 dB above the background |
| Read accuracy | a local Whisper model (`small.en`) transcribes the take; word error rate against the script above 15% |

Whisper runs locally, so no audio leaves the machine. For read accuracy it is
only a check, not a transcriber. A near miss, such as a natural contraction,
can be accepted by hand; the manifest flags it as overridden. Every take, kept
or not, is logged with its metrics, so the rejection rate itself becomes data.

### Preparation

```text
accepted takes --> trim silence, keep a short pad --> loudness-normalise
               --> resample to 24 kHz --> nested subsets
```

Nested subsets keep the dose comparison fair: the 10-minute set sits inside the
30, which sits inside the 60. The only thing that changes between arms is the
amount of audio.

### Held-out evaluation set

Never used for training, recorded in the same sessions:

- the ten deck narration lines
- twenty further sentences: ten statements, five questions, five long sentences
  with commas

Wikus also reads all thirty for real. Those recordings are the ceiling every arm
is measured against.

## Arms

| Arm | What | Role |
| --- | --- | --- |
| R | Wikus's own recording | ceiling |
| Z0 | Chatterbox's stock voice | floor |
| Z1 | zero-shot clone at the best settings found (exaggeration 0.3, cfg 0.7, temperature 0.6) | control |
| C60 | conditioning tuning only, model frozen, 60 min | negative control: shows how much of any gain needs real training |
| L10 | T3 + LoRA, 10 min of audio | dose 1 |
| L30 | T3 + LoRA, 30 min | dose 2 |
| L60 | T3 + LoRA, 60 min | dose 3 |
| F60 | T3 full fine-tune, 60 min | optional: does LoRA leave accent on the table |

Every generated arm uses the same reference clip, the same settings and the same
seeds, so the training is the only variable.

## Training approaches

LoRA is the starting point, not the only option.

| Approach | What it trains | Cost on this machine | Risk |
| --- | --- | --- | --- |
| **LoRA on T3** | small low-rank adapters on the attention layers, a few million parameters | lowest; fits comfortably | may be too light to shift an accent |
| Full fine-tune of T3 | all 0.5B parameters | about 8 GB of weights and optimiser state; fits in 36 GB, slower | forgets general English, overfits to the script |
| Conditioning tuning | only the speaker conditioning vectors, model frozen | cheapest of all | probably too weak for accent, but a cheap negative control |
| S3Gen fine-tune | the decoder, for timbre | moderate | fixes a problem the clone does not really have |
| Best-of-N reranking | nothing; generate several takes, keep the one a speaker-similarity model scores closest to him | no training, N times the render time | polishes the output, cannot teach an accent |

## Measures

| Measure | How | Tests |
| --- | --- | --- |
| Blind "which one is Wikus" | listeners hear the real recording and an arm in random order, pick the real one. 50% means indistinguishable | identity |
| Accent and naturalness rating | listeners rate each clip 1 to 5 for "sounds South African" and "sounds natural", without knowing the arm | accent, clarity |
| Terminal pitch on statements | pitch tracked with librosa's pYIN over the last 500 ms of each statement; the slope should be negative, like R | intonation |
| Speaker similarity | cosine similarity of speaker embeddings, arm against R | identity, objectively |
| Word error rate | Whisper transcribes each clip, compared against the script | clarity, catches invented words |
| Wall clock and memory | per training run | is this practical on a laptop |

Listeners are people who know his voice. The panel can be small; the same
people rate every arm.

The speaker-embedding and pitch tools come from PyPI and get vetted before
install, same as Chatterbox.

## Procedure

1. Record batch 1 with the recorder, then the later batches.
2. Prepare the clips, build the nested 10/30/60 subsets and the held-out set.
3. Render Z0 and Z1 on the held-out set, and score them. This is the baseline
   before any training.
4. Build the trainer. Read the community Chatterbox fine-tuning code first; adapt
   it if it is sound, otherwise write a small LoRA loop over T3 directly.
5. Smoke-run L10 for a few hundred steps and listen. Catch a broken pipeline
   before spending hours on it.
6. Train L10, L30, L60 with identical hyperparameters. Log loss, time and memory.
7. Render every arm on the held-out set with fixed seeds.
8. Score the objective measures, then run the blind listening test.
9. If time allows, run F60 and compare it against L60.
10. Re-render the deck with the winning arm. That deck is the presentation of
    the experiment.

## Predictions

| Prediction | Reasoning |
| --- | --- |
| L10 already beats Z1 on accent | T3 has never heard this accent at all, so even ten minutes is new information |
| The curve flattens between 30 and 60 | adapters saturate before the data runs out |
| Terminal pitch flips from rising to falling by L30 | intonation is a sentence-level habit, and the training set is full of statements |
| WER stays flat or improves | real transcribed speech is cleaner input than a six-second prompt |
| No arm passes the blind test at 50% | an expert listener spots a clone; getting close is the realistic goal |
| Training on the Mac takes hours per run, not days | LoRA on 0.5B parameters over an hour of audio is modest work |

## Time estimate

Guesses, to be replaced by measurements.

| Phase | Hands-on | Machine time |
| --- | --- | --- |
| Reading script | 1 to 2 h | |
| Recording 75 usable minutes | 3 to 4 h across a few sessions | |
| Recorder and reading script | done | |
| Clip prep | under 1 h | minutes |
| Trainer, including reading the community code | 1 to 2 days | |
| Training L10, L30, L60 | | 1 to 4 h each; overnight for all three |
| Optional F60 | | 4 to 10 h |
| Rendering and objective scoring | 1 h | 1 to 2 h |
| Listening test | half a day, mostly waiting on people | |
| Blog post and deck | 1 to 2 days | |

Roughly **5 to 8 working days** of effort, spread over two to three weeks, with
the trainer as the biggest unknown.

## What a result would change

| If | Then |
| --- | --- |
| L10 is clearly better than Z1 | the cheap path works; ten minutes of reading is the recipe worth publishing |
| Only L60 or F60 helps | the recipe is real but costly; the write-up says so |
| No arm beats Z1 | accent is not a T3 problem alone. Next: S3Gen fine-tuning, or a model trained with more accent variety |
| Intonation fixes but accent does not | the two live in different places, which is a finding in itself |
| Training is impractical on the Mac | the write-up becomes "what it takes", with a cloud GPU run as the follow-up |

## Outputs

| Output | Where |
| --- | --- |
| This plan, its results doc and the journey | here, public |
| The training pipeline that worked, with no voice data | here, public |
| Training audio, reference clips, fine-tuned weights | Wikus's machine only, until the experiment ends |
| The final model, pipeline and process | a private repo, once the experiment ends |
| Blog post | method and findings, with audio only where he chooses to share it |
| Deck | narrated by the winning arm |
