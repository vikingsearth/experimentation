# Ground Control deck

Build tooling for a two-minute narrated deck, with a Chatterbox voice-over.

The deck, its narration and every audio file live in `.tmp/groundcontrol-deck/` at the repo root, which git ignores.
They describe an internal app and include a voice-clone reference, so they stay off this public repo.

| file under `.tmp/groundcontrol-deck/` | what |
| --- | --- |
| `groundcontrol-deck.html` | the deck, self-contained with its audio. Open it in any browser, works offline |
| `voice-script.md` | the narration. A `settings:` line, then one `##` heading per slide and one spoken chunk per line |
| `voice-recording-script.md` | what to read aloud for a voice-clone reference |
| `voice-samples/` | the raw voice recording, plus listening tests |
| `build/gc/project/` | the deck source - scenes, script board and per-slide audio |
| `build/me_ref.wav` | the 13 s cut of the recording that Chatterbox clones from |

## Rebuilding

Run from `build/`, inside a Python 3.11 venv with `chatterbox-tts==0.1.7` and `setuptools<80` installed.
Every path resolves against `.tmp/groundcontrol-deck/`.

1. `python cgen.py cbx_out [slides]` - renders slides from `voice-script.md`, for example `1,4,10`. Add `VOICE=me_ref.wav` to use the cloned voice.
2. `python3 sync_build.py` - converts the clips, then syncs scene timings and captions into the deck source.
3. `python3 build_standalone.py ../../../.tmp/groundcontrol-deck/groundcontrol-deck.html` - writes the offline deck.

Each slide renders with the seed `seed + slide number`, so a single slide can be re-rolled without changing the rest.
