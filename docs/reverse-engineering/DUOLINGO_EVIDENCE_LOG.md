# Duolingo Evidence Log

Method: user's own signed-in session in Chrome (Claude in Chrome extension), course **Chinese (Simplified) from English**, web (`www.duolingo.com`). Observation only: page text, accessibility tree, screenshots. No authentication bypass, no API calls made by us, no app binaries decompiled. Personal identifiers and other learners' names are deliberately not recorded. Course content (sentences, unit lists) is summarised, not reproduced, beyond a few short illustrative examples.

| ID | Date | Route / surface | Method | Observation |
|---|---|---|---|---|
| E-001 | 2026-11-11 | `/learn` | screenshot, page text | Layout: left nav (Learn, Characters, Practice, Leaderboards, Quests, Shop, Profile, More), centre path, right rail (league card, daily quests). Top bar: course flag + number, streak flame + count (greyed = not extended today), gems + count, Super badge. |
| E-002 | 2026-11-11 | `/learn` header | page text | Sticky unit header "SECTION n, UNIT m" + unit goal title (communicative "can-do", e.g. *Talk about the weather*) + GUIDEBOOK button. |
| E-003 | 2026-11-11 | `/learn` nodes | a11y tree | Node kinds exposed as button labels: **Lesson**, **Story**, **Radio**, **Practice**, plus unlabeled nodes (visually: 字 character node, completed check). Locked nodes rendered grey. |
| E-004 | 2026-11-11 | `/learn` node popover | click + screenshot | Clicking current node opens popover: title ("Personalized practice"), progress "Lesson 2 of 3", CTA "START +10 XP". ⇒ A node contains N lessons; XP reward shown before start. Current node has progress ring + "START" bubble. |
| E-005 | 2026-11-11 | `/learn` | page text | Between units: "JUMP HERE?" affordance (skip ahead via test). End of section: "UP NEXT · Section n · description · JUMP HERE?". |
| E-006 | 2026-11-11 | `/sections` | page text | Course = 8 sections + "Daily Refresh" (6 levels, unlocked after completing course). Each section: CEFR tag (e.g. A1) + "SEE DETAILS", status (COMPLETED / % progress / unit count), CTA (REVIEW / CONTINUE / JUMP TO SECTION n), and a target-language can-do sentence. Unit counts grow sharply in later sections (30 → 60 → 200+). |
| E-007 | 2026-11-11 | `/characters` Pinyin tab | page text | Pinyin reference: 5 tones (mā má mǎ mà ma), initials grid, finals grid, "LEARN PINYIN" course. |
| E-008 | 2026-11-11 | `/characters` Hanzi tab | page text | Per unit: list of characters **"Introduced in this unit"** and **"Used in new words"** (previously learned chars reused), + PRACTICE button. Future units listed without characters (not yet unlocked). ⇒ Character curriculum is derived from unit vocabulary. |
| E-009 | 2026-11-11 | `/practice-hub` | page text | Sections: Today's Review → "Target Practice — tackle weak areas with this customized session, START +20 XP"; Conversation; Listen ("audio-only session"); Your collections → Mistakes ("personalized lesson to practice your mistakes", count badge 30+), Stories ("reread a story to review words in context"). |
| E-010 | 2026-11-11 | `/quests` | page text | Monthly quest ("Complete 70 quests", days remaining, progress n/70, exclusive badge) + Daily Quests (3 items, hours remaining). Daily quests seen: Earn 30 XP; Score ≥80% in 3 lessons; Get 10 in a row correct in 3 lessons. Each quest has a chest reward icon. Past monthly badges listed. |
| E-011 | 2026-11-11 | `/leaderboard` | find | League tier name (e.g. Diamond), "n days" remaining, Demotion Zone label. Rail card: rank, rank change ("moved up 2 ranks"), weekly XP. |
| E-012 | 2026-11-11 | `/shop` | page text | Subscriber view: Power-Ups → Streak Freeze ("allows your streak to remain in place for one full day of inactivity"), up to 3 equipped. |
| E-013 | 2026-11-11 | `/guidebook/zh/{unit}` | page text | Unit guidebook: KEY PHRASES (target sentence + translation, ~5) and TIPS (grammar explanation with pattern table and examples). |
| E-014 | 2026-11-11 | `/settings/*` | page text (labels only) | Settings groups: Account, Preferences, Profile, Notifications, Courses, Privacy, Subscription. Preferences: sound effects, animations, motivational messages, listening exercises toggle, dark mode (system/on/off), course-specific **Show Pinyin: all words / new words**. |
| E-015 | 2026-11-11 | top bar | page text | Gem counter changed 3459 → 3439 between `/practice-hub` and `/quests` with no purchase action by us (only node popover clicks and Escape). Cause unverified (possibly automatic streak-freeze refill). Logged for transparency. |

## Lesson session (user-approved, 1 lesson, 2026-11-11)

Node: "Personalized practice", lesson 2→3 of 3, preview "+10 XP". 15 exercise screens incl. 2 re-queued. One wrong answer was given **deliberately** (E-019) to observe the failure path; one listening item was wrong because audio is not available to the agent.

| ID | Surface | Observation |
|---|---|---|
| E-016 | Lesson chrome | Top: quit ✕, settings ⚙, progress bar, hearts indicator (∞ for Super). Bottom: SKIP (left), CHECK (right, disabled until an answer exists). Enter = CHECK then CONTINUE. |
| E-017 | Translate ZH→EN (word bank) | Prompt "Write this in English"; speaker character + speech bubble with play button; target sentence with dotted underline per word. Bank of English chips incl. distractors. Tapping a chip moves it to the answer line and leaves a grey placeholder (bank layout never reflows). |
| E-018 | Correct feedback | Green bottom sheet: random praise (Amazing!/Good job!/Excellent!/Great!/Nice job!/Correct!), sound, CONTINUE, plus meta-feedback links TOO EASY · TOO DIFFICULT · REPORT. When the user's answer differs from the canonical one: "Another correct solution: …" ⇒ multiple accepted answers, canonical surfaced. Fill-blank/listening also show "Meaning: <translation>". |
| E-019 | Wrong feedback | Red bottom sheet "Correct solution: …", same meta links. Progress bar **does not advance**; "N IN A ROW" counter resets. For Chinese answers the correction is rendered with per-character pinyin ruby (今jīn天tiān…). |
| E-020 | Streak-in-lesson | "N IN A ROW" label above progress bar from 2 correct onward; progress bar turns gold at a high combo (seen at ≥8). |
| E-021 | Word hint | Hover/tap on underlined target word → tooltip gloss (牛奶 → "milk"). |
| E-022 | Fill in the blank | "Fill in the blank": sentence with gap, 3 numbered options (keys 1–3). |
| E-023 | Translate EN→ZH (typed) | "Write this in Chinese (Simplified)": free textarea "Type in Chinese (Simplified)" + toggle **USE WORD BANK ↔ USE KEYBOARD**. Answer without final punctuation accepted; synonym variant (经常/常常) shown as alternative ⇒ normalisation ignores punctuation, accepts lexical variants. |
| E-024 | Word-bank (ZH) | When toggled, Chinese chips are **word-segmented** (他们 / 在 / 玩 / 飞盘), not per character; distractors included. |
| E-025 | Match pairs | "Select the matching pairs": 5 EN (keys 1–5) vs 5 ZH (keys 6–0); select one from each column; matched pair greys out; whole exercise graded once at the end. Requires visible tab (animations paused when hidden). |
| E-026 | Listening | "Tap what you hear": large play button + slow (turtle) button, word-segmented chip bank, USE KEYBOARD toggle, **CAN'T LISTEN NOW** in place of SKIP. Correct sheet shows "Meaning:". |
| E-027 | Mistake re-queue | Every missed exercise reappears at the end of the lesson, labelled **PREVIOUS MISTAKE**, chips reshuffled. Lesson ends only after all re-queued items are answered correctly. |
| E-028 | Lesson results | Headline personalised to a lesson statistic ("Are you a spy? — You completed 3 listening challenges in this lesson"); cards TOTAL XP (13, with odometer count-up) and accuracy (88%, label GOOD!); buttons REVIEW LESSON / CONTINUE. XP earned (13) > XP previewed (10). |
| E-029 | Post-lesson | "Daily Quests update!" screen with animated quest bars, then return to `/learn`; streak flame lit and +1 (745 → 746); node progress ring advanced. No separate streak screen shown this time. |
| E-030 | Unexplained deltas | Quests went 0→30/30 XP and 0→2/3 for both lesson-count quests, and weekly XP 273→331 (+58), while this lesson showed 13 XP. A second Duolingo tab was open in the browser; the source of the extra progress could not be attributed. Not used as evidence for XP rules. |

## Second pass — 2026-11-12 (attached browser)

Method: Brave 157 on Windows, **profile copy** in a separate `--user-data-dir` with `--remote-debugging-port`; the account owner logged in themselves. Read-only observation via REA connect mode (`capture_browser_scenario` / `inspect_web_page`) plus DOM-level clicks for elements Playwright refused to click (animated containers time out actionability checks). No API calls made by us, no credentials read, username redacted.

| ID | Surface | Observation |
|---|---|---|
| E-031 | `/learn` | Section 2, Unit 21 "Talk about the weather"; sub-unit headings group nodes by topic ("Express feelings", "Talk about the weather", "Talk about friends"). Node kinds in this unit: Lesson, Radio, Story, Practice, unlabelled (character), **Chest [disabled]**, **Legendary Level**, **Unit Review**. Header links to `/sections`; guidebook `/guidebook/zh/31`. Between units: "Jump to Unit 22" → `/lesson/unit/32/test`; end of section "Up next · Section 3 · … · Jump here?". |
| E-032 | `/practice-hub` | "Today's Review" is now **Unit Rewind** ("Keep your memory fresh with this review of Unit 20!", `Start +20 XP`) — replaces the "Target Practice" card seen in E-009. Then "Conversation" (heading only, no actionable control observed), "Listen" ("audio-only session"), "Your collections" → Mistakes (badge 30+), Stories. |
| E-033 | `/practice-hub/stories` | Featured story card (illustration, title, blurb, `Start +20 XP`) + "Your library" list of ~40 story titles as buttons. Titles are original and short ("Coffee Mix-Up", "Dumpling Duty", …). |
| E-034 | Story intro card | Illustration, title, single `START STORY` button; no text preview before starting. |
| E-035 | Story player | Top bar: quit ✕, settings ⚙, progress bar, hearts (∞ on Super). Beat layout: narration line in English with speaker button, then a character avatar + speech bubble holding the Chinese sentence rendered with **per-word ruby pinyin** above it; words are dotted-underlined (tappable); speaker button inside the bubble. Single `Continue` button bottom-right; progress bar advances per beat. |
| E-036 | `/characters` Pinyin tab | Tone, initial and final tiles each carry a **mastery progress bar** (fractional values, e.g. mā 0.27, d 0.6, a 0.8). Card: "Let's learn Pinyin!" → `/alphabets/zs/pinyin`. |
| E-037 | `/characters` Hanzi tab | "Let's practice Hanzi! — Practice reading words with hanzi characters". Per unit (SECTION n, UNIT m + topic): **Introduced in this unit** character grid and **Used in new words** grid (previously learned characters reused), plus a `Practice` button per unit. |
| E-038 | Hanzi practice | `/alphabets/zs/hanzi/group/0`. Exercise "Select the correct pronunciation": character in a speech bubble beside a character avatar, 3 numbered pinyin options, `SKIP` / `CHECK` (CHECK disabled until selection), same lesson chrome (quit, progress, hearts). |
| E-039 | Legendary Level node | Popover: level title, "Great job! You made this unit Legendary!", `START`. Completed-legendary state offers replay. |
| E-040 | Unit Review node | Popover: "Unit 21 review — Complete all levels above to unlock this!", state **LOCKED** (no CTA). Unit completion gates the review node. |
| E-041 | Radio node | Popover uses a story-like title ("Love for Novels") with "You completed this level!" and `PRACTICE +15 XP` (no plain START once completed). |
| E-042 | Radio session | `PRACTICE +15 XP` → `/lesson/unit/28/level/2`, full-screen audio card reading "LUCY IS LISTENING" with speaker control, lesson chrome (quit, settings, progress, hearts). Audio content itself not available to the agent. |
| E-043 | Listen practice | `/practice-hub/listening-practice` intro: "Put your ears on alert! You'll listen 10 times in this practice session." + `CONTINUE`. |
| E-044 | More menu | Left-nav `More` expands to: Duolingo English Test, Settings, Help, Log out. No friends/notifications entry on web. |
| E-045 | Daily quest set (delta) | Observed: "Earn 30 XP", "Earn 15 Combo Bonus XP", "Score 90% or higher in 3 lessons" — the accuracy threshold is **90%** here, not the ≥80% recorded in E-010. Combo XP is a first-class quest metric. |
| E-046 | Profile route | Nav profile link points to `/profile/{username}` (username deliberately not recorded). |
| E-047 | Top bar (delta) | Streak 746, gems 3439, plus an unlabelled red badge counter (16) left of the streak — purpose unverified. |
| E-048 | `/shop` | Super subscriber view: banner "You're learning on Super Duolingo — Say goodbye to ads and support our mission." Then **Power-Ups**: one item, *Streak Freeze*, "3 equipped", with an `Equipped` button rendered **disabled**. No gems pricing or purchase CTA is exposed to this account. |
| E-049 | `/leaderboard` | Diamond League, "2 days" left. Table of 15 learners: rank, avatar, name, tenure badge ("1+ year", "2+ years", "4+ years"), weekly XP. Own row highlighted at rank 5 (331 XP). **Demotion Zone** separator sits after rank 12, i.e. ranks 13–15 are demotion candidates. Each row links to `/u/{id}?via=leagues`. Above the table: "Set your status" with a `Clear` link and a row of emoji buttons. Names deliberately not recorded. |
| E-050 | `/placement` | Returns the site's **404** page ("Error 404 — Sorry, the page you were looking for doesn't exist"). No placement/onboarding route is reachable for an existing account; placement only exists inside the new-user flow. |
| E-051 | Listen practice (exercise) | After `CONTINUE` on E-043, the first exercise is **"Tap what you hear"**: large play button + turtle (slow) button, a chip bank of *word-segmented* Chinese with pinyin above each chip (e.g. 哪里 / 在 / 上 / 先 / 吧 / 坐地铁 / 我们 / 衣服), `USE KEYBOARD` toggle, `CHECK` disabled until a chip is picked. Progress bar is violet here (not gold). |
| E-052 | Radio session (deeper) | `/lesson/unit/28/level/2` renders a single full-screen card: microphone illustration, caption **"LUCY IS LISTENING"**, lesson chrome (quit ✕, settings ⚙, progress bar, hearts ∞). The DOM exposes **no play/continue control** — the session is audio-driven and advances on its own; the accessibility tree is just the caption. Audio content itself is not available to the agent. |
| E-053 | Tooling limitation | Playwright's `click` times out on path-node and tab elements (strict-mode duplicates, and elements inside continuously animated containers fail actionability). DOM-level `click()` works for tabs, nodes and story controls, but the **Legendary Level `START`** button did not open a session in three attempts (popover closed / click swallowed). Unit-test and Legendary *sessions* therefore remain unobserved. |
| E-054 | Lesson via URL | `/lesson/unit/{unit}/level/{n}` opens a lesson directly (e.g. unit 31 level 1). Exercise types seen: **"Select the correct meaning"** (hanzi + 3 numbered pinyin/meaning options) and **"Complete the chat"** (a two-line dialogue, pick the reply that fits — e.g. 今天下午有风，对不对？ → 对，记得关窗户。). Both use `SKIP` / `CHECK`, and the correct sheet shows "Correct solution" plus "Meaning:" for the chat type. |
| E-055 | Feature routes (availability) | `/video-call`, `/call`, `/speaking`, `/roleplay`, `/lily` → **404**. `/max` → redirects to `/learn`. `/practice-hub/conversation` → renders `LOADING...` then **redirects back to `/practice-hub`**, where "Conversation" is a heading with no control. So conversation / Video Call is not available on this account (Super, web, Chinese course). |
| E-056 | Speaking sweep | Three units (31, 27, 29) × up to 8 exercises each, plus units 24/20/15 attempted: **no speaking exercise and no microphone control** appeared (no `aria-label` or `data-test` matching speak/microphone/record/voice). Several units stalled at "LOADING…" under CDP attach, so absence is evidence of "not seen", not proof that the type is disabled for the course. |

Screenshots retained outside the repo (`tools/shots/`, gitignored): `characters_hanzi3.png`, `character_practice3.png`, `story_player.png`, `story_beat.png`, `story_dialog.png`, `learn_legendary.png`, `learn_unitReview.png`, `learn_radio.png`, `radio_session.png`, `listen_session.png`, `more_menu2.png`.

## Documented, not observed (secondary sources)

These are **not** observations of the product; they are Duolingo's own published descriptions, used
only to close the gaps that this account cannot reach. Treat them as weaker evidence than E-IDs.

| ID | Topic | What the source states | Source |
|---|---|---|---|
| D-001 | Video Call (Lily) | Max tier only, **mobile app only** (iOS/Android, app v13+), cannot be bought or used on web. Lives on the path and in the Practice Hub; five sessions per unit plus a dedicated tab. Courses listed in the current help page: English, French, Spanish, Italian, German, Portuguese (Chinese is **not** in that list; an older blog post mentions Chinese for Video Call — conflicting, unresolved). | https://www.duolingo.com/help/what-is-duolingo-max/ · https://blog.duolingo.com/video-call/ |
| D-002 | Video Call behaviour | Lily opens the call, user can talk about anything, may ask her to repeat or slow down, no penalties, she adapts to level and does not correct grammar; transcript available after hanging up; AI feedback on accuracy/complexity. | https://blog.duolingo.com/duolingo-max/ |
| D-003 | Speaking | Speaking exercises appear in lessons "from day one" (repeat, translate aloud, mini-dialogues); many writing exercises have an optional microphone to dictate instead of type; the Practice tab has speaking-only practice sets (free for all learners). Feedback is phoneme-level: correct words highlighted, problem sounds flagged, ~500 ms recognition lag. | https://blog.duolingo.com/covering-all-the-bases-duolingos-approach-to-speaking-skills/ · https://blog.duolingo.com/sneaky-pronunciation-practice/ |

Consequence for this study: speaking and Video Call cannot be observed on a web + Super + Chinese
account, no matter how much of the path is sampled (E-055, E-056 agree). The mechanics above are
enough to spec our own version; the exact UI of those two flows stays unknown.

## Still not observed

- **Speaking exercises** — none surfaced in the sampled sessions (listen, story, radio, hanzi, path nodes).
- **Hearts depletion** — account has unlimited hearts (Super), so the out-of-hearts path cannot be reached.
- **Onboarding / placement** — `/placement` is a 404 for this account (E-050); the flow only exists for a new user.
- **Profile detail page** — skipped: personal data.
- **Friends / notifications** — no entry point on web (E-044).
- **Conversation practice** — heading rendered without an actionable control.
- **Unit test / Legendary session** — popovers observed (E-039–E-041), but the session itself could not be started through the tooling (E-053).
- **Mobile app (Android/iOS)** — untouched. No APK on disk, no device attached.
- **Network/API behaviour** — deliberately not observed (read-only UI evidence only).
