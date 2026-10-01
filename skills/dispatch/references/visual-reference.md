# Visual references — building from an image

Use this when the user gives an image to match: a mock, a screenshot of another site, a
Figma export, a photo of a sketch. Without it, "make it look like this" comes back close but
not exact. There are three reasons:

1. **The sub-agent never sees the image.** A brief is text. An image pasted into the main
   session stays there, and the sub-agent gets your *description* of it. Every spacing, weight
   and colour you did not name is guessed.
2. **Nobody compares the result to the image.** `dispatch-measure.mjs` checked overflow and one
   computed value. "Matches the mock" was judged from memory, by an agent that never had the
   mock.
3. **`DESIGN.md` quietly wins.** The frontend agent snaps every value to a token. When the mock
   uses a spacing or colour that is not a token, the result drifts toward the design system and
   away from the image, and nobody decided that it should.

The fix: the image becomes a **file in the repo**, the brief names it, the sub-agent opens it,
and both the sub-agent and you **compare renders to it** with the measure script.

## 1. Put the image in the repo — before the brief

The reference must be a file both sessions can open:

```
.claude/dispatch/refs/<NNN>-<slug>/<width>.png      e.g. .claude/dispatch/refs/007-pricing/1440.png
```

`<NNN>` is the next ledger number ([context.md](context.md#the-ledger)). Name each file by the
viewport width it shows (`1440.png`, `375.png`). A 2x export is fine; the script scales it.

- **The user gave a path or URL** → copy or download it there yourself.
- **The user pasted it into the chat** → you can see it, but you cannot write its bytes to
  disk. Ask once: *"Save that image as `.claude/dispatch/refs/007-pricing/1440.png` (drag it
  into the folder), then say done. Is it the desktop view, at about 1440px?"* That counts as one
  question toward the ceiling ([responsive.md](responsive.md)). If the user cannot save it, go
  to [§6](#6-when-there-is-no-image-file-or-no-renderer).

Commit reference images with the change. They are the spec, and the next change to this page
will need them.

## 2. Settle the conflicts — one question, only if there is one

Before the brief, look at the image against `DESIGN.md` (tokens, breakpoints, components). If
the image clearly uses values `DESIGN.md` does not have, such as a colour, a radius or a font
size, ask **one** question:

```
The mock uses a teal (#2E8B8B) and 20px card radius; DESIGN.md has neither.
  a) Match the mock exactly (I'll add the two values to DESIGN.md as tokens in the same brief)
  b) Keep DESIGN.md — nearest tokens, accept the visual difference
```

The answer goes into the brief as a **Format** line. Without this question, the frontend agent
stops on the conflict (its template says so), and that costs a full round trip.

## 3. The brief

Add to **Inputs**, beside **Page URL(s)**:

```
Reference image(s) — open each with your Read tool before any edit:
  .claude/dispatch/refs/007-pricing/1440.png   → compare at 1440
  .claude/dispatch/refs/007-pricing/375.png    → compare at 375
Fidelity: exact — match layout, spacing, type sizes, weights, colours, radii, order and copy.
```

`Fidelity` is `exact` (the default when the user gave an image) or `close` (the layout and
hierarchy match, the tokens win). Put in **Verbatim** ([prompt-spec.md](prompt-spec.md)) any
text in the image the user wants used as-is. Text read off an image is otherwise the sub-agent's
guess.

**Steps** — you still write them. Name each block to build, in order, with its file and where it
goes ("1. In `resources/views/pricing.blade.php`, after the header include, add the three-plan
grid section …"). The agent takes the exact values (spacing, sizes, colours) from its reference
spec table, so the steps name blocks and places, not every pixel. The last step is the compare
loop, written out with the files it may touch:

```
N. Run `node .claude/dispatch/dispatch-measure.mjs <page url> 1440 --compare .claude/dispatch/refs/007-pricing/1440.png --shot .claude/dispatch/shots`
   (and at 375). Read each composite. Fix red regions in <the briefed files only>, at most 3
   passes; report any red region that needs another file instead of fixing it.
```

**Done means** carries the comparison, per reference:

```
- [ ] reference spec table written before the first edit
- [ ] `--compare` run at 1440 and 375; composite images read; every remaining red area named in
      the report as intended (content differs) or fixed
- [ ] no overflow at 375, 768, 1280, 1440
```

Do not write a percentage threshold as the pass line. Real content, fonts and image assets make
0 % impossible, so a threshold either passes wrong layouts or fails right ones. The composite
image is the evidence. The percentage only shows whether passes are converging.

## 4. What the frontend agent does (its template carries this)

1. **Reference spec — measuring, not planning.** Open each image and write a short table before
   editing: the
   layout grid (columns, max width, gutters), each block top to bottom, spacing between blocks,
   type (size and weight per text role), colours, radii, borders and shadows, and the icons and
   images used. Measure against the image's own pixels, dividing by the scale factor for a 2x
   export. The table supplies the values; the brief's steps say what to build and where.
2. **Execute the brief's steps**, taking values from the table.
3. **Compare loop — the brief's last step, at most 3 passes:**
   ```bash
   node .claude/dispatch/dispatch-measure.mjs <page url> <width> --compare <ref image> --shot .claude/dispatch/shots
   ```
   Open the composite it writes (`… -compare.png`: reference | render | diff). Name each red
   region, fix it within the files that step allows, and run the comparison again. A region
   that needs another file is reported, not fixed. Stop after 3 passes, or earlier when what stays
   red is content (real data or real images in place of the mock's placeholders).
4. **Report** the percentage for each pass (for example `38 % → 12 % → 4 %`) and the composite
   path, and list each red region still there with its reason.

## 5. Acceptance — yours

Run the same command at each reference width, then **open the composite image**. It is one
image per width, and it is the one image worth its context cost. Judge it against the brief's
Fidelity line:

- Any red block that is **structure** (a section missing, a column count, an order, a size
  difference visible at a glance) → reject. Quote the region, for example *"hero is 64px shorter
  than the reference; CTA sits left, reference centres it"*.
- Red that is **content** (different text length, a real photo, live data) → fine. Say so in the
  verdict.
- Thin red outlines along every edge usually mean an offset of a few pixels in spacing. With
  Fidelity `exact` that is a rejection that names the spacing. With `close` it is fine.

Screenshots in `.claude/dispatch/shots/` are working files. Setup adds that directory to
`.gitignore` ([setup.md](setup.md), step b).

## 6. When there is no image file, or no renderer

- **No file** (the user cannot save it): write the reference spec table **yourself**, from the
  image you can see, into the brief under Inputs. Mark the brief `Fidelity: from description —
  exact match not checkable`, and report it that way at acceptance.
- **No renderer** (*Verification capabilities* → `Rendering: none`): the agent still writes the
  spec table and builds from it. Every comparison is **Not verified: no renderer**. Say so
  plainly; do not describe the result as matching.
