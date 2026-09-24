# Local LLM on this machine

ollama + Vulkan on the Radeon 890M (gfx1150). Captured 2026-09-23.

## Two settings without which it is broken or crippled

    Environment="OLLAMA_IGPU_ENABLE=1"      # or it runs CPU-only, silently
    Environment="OLLAMA_CONTEXT_LENGTH=32768"   # default is 4096, too small for code

**ollama drops integrated GPUs by default.** The only sign is one log line:

    dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1

Without it you get no error, just CPU inference. With it: `100% GPU`,
`41/41 layers offloaded to Vulkan0`.

Runs as a **user** systemd service so models live in ~/.ollama and no root is
ever needed. Track the unit FILE, never the directory -- see [[dotfiles]].

## Memory: 32 GB physical is not 32 GB available

    dedicated VRAM (firmware carve-out)  8.00 GiB   invisible to the OS
    GTT (window into system RAM)        11.54 GiB   comes OUT of what the OS sees
                                        ---------
    GPU-addressable total               19.54 GiB

`free` shows ~23 GiB, not 31, because the 8 GiB carve-out is taken before Linux
boots. Consequence: **a model under 8 GiB costs the desktop nothing** (it fits in
the invisible pool); beyond that it eats system RAM. A 17.7 GiB model still
leaves ~13 GiB for the desktop, which is more usable than the naive arithmetic
suggests.

## Measured, not estimated (qwen3:14b, 9.3 GB)

    generation    ~10 tok/s
    prompt eval   ~100 tok/s, decaying as context grows (140 -> 96 by 10K)

## The thing that actually determines latency: prompt size

    comrade (context file only, ~1,300 tokens)     4-14s
    comrade-do (4 terse tool schemas, ~1,000)      7-24s
    crush / opencode (~15,000 tokens of system
      prompt + tool schemas)                       2m27s - 3m36s

**Prompt size, not model quality, is the bottleneck.** Agent frameworks are slow
here because of what they prepend, not because the model is small. A hand-rolled
loop with four tools is an order of magnitude faster and answers just as well.

**Output length matters as much.** Adding "1-3 sentences, no preamble" to
machine.md took one answer from 51s to 7s. Keep that instruction in machine.md.

## Context files are only worth what is in them

An early hypr.md said the panel "needs transform = 3" without saying what 3
*means*. The model guessed 180 degrees. State facts explicitly; do not imply
them. Keep each file topic-scoped and small, because they load wholesale.

## Tools

    comrade "question"          no tools, context profiles, seconds
    comrade -c hypr "..."       force a profile;  -c none for bare
    comrade -l                  list profiles
    comrade-do "task"           agent loop: read_file, list_dir, search
    comrade-do --allow-exec     shell tool, off by default, confirms each command

Both live in ~/.local/bin, profiles in ~/.config/comrade/contexts/.
A local 14B reading a KB entry answers well; it will not do novel diagnosis.
