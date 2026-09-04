# Design — Citizen Mode

Visual system for the Citizen feed and report composer (SIH PS 26043). Material 3, light theme only.

## Color palette

| Token | Hex | Use |
| --- | --- | --- |
| Banner / FAB / play / submit | `#4A62AD` | Primary actions, header accent, submit button |
| Page background | `#F4F6FB` | Scaffold behind cards |
| Surface | `#FFFFFF` | Problem cards, sheets, inputs |
| Ink | `#1C2333` | Titles, username |
| Secondary text | `#6B7280` | Mode label, location · time |
| Muted meta | `#8A93A6` | “5 reports” |
| Waveform idle | `#9AA6C3` | Audio bars when paused |
| Chip wash | `#EEF1F8` | Audio pill + empty camera well |
| Upvote wash | `#F3F5FA` | Upvote pill |
| Verified / success | `#4CAF50` | Verified label, success check, GPS ready |
| Verified wash | `#E8F5E9` | Verified pill background |
| Avatar wash | `#D7DEF2` | Header circle |
| Recording / remove | `#C62828` | Live mic, recording waveform, Remove |
| Input border | `#D9DEEA` | Title field + location pill |
| Disabled submit | `#B7C0D8` | Submit when form empty |

## Type scale

| Role | Size | Weight |
| --- | --- | --- |
| Banner title | 22 | 800 |
| Username | 17 | 700 |
| Report header / success | 18 | 800 |
| Submit label | 17 | 800 |
| Card title | 16 | 700 |
| Camera CTA / title field | 16 | 700 / 500 |
| Voice helper | 15 | 700 |
| Feed title | 16 | 700 |
| FAB label | 15 | 700 |
| Section label | 14 | 700 |
| Location pill | 14.5 | 600 |
| Timer | 16 | 700, tabular |
| Body / location | 12.5–13.5 | 500 |
| Mode label | 13 | 500 |
| Verified / duration | 12 | 600–700 |

System font (Material `ThemeData` default). No custom font family yet.

## Chips and pills

- **Verified:** 20px radius, `#E8F5E9` fill, `#4CAF50` 12px bold label, horizontal padding 10, vertical 5.
- **Audio player:** 28px radius, `#EEF1F8` fill, 32px circular play in `#4A62AD`, duration at 12px / w600.
- **Upvote:** 22px radius, `#F3F5FA` fill, `keyboard_arrow_up` + count, ink `#2D3A5F`.
- **Bottom FAB:** 32px radius pill, `#4A62AD`, camera icon + “Report Problem”, elevation 8.
- **GPS pill:** 28px radius, white fill, `#D9DEEA` border, pin + label, 14/12 padding, spinner while detecting.

## Layout (feed)

- Horizontal page margin: **20**
- Header: top 12, avatar radius **24**, settings icon 26
- Banner: radius **22**, inner padding **22 / 20**
- Card: radius **20**, image height **168**, content padding **16 / 14 / 16 / 16**
- Feed card gap: **16**
- Scroll bottom inset under FAB: **108**
- FAB bottom safe padding: **16**
- Mode sheet: top radius **24**, padding 24 / 32

## Report composer (submission modal)

- Full-screen dialog route (`fullscreenDialog: true`), page bg `#F4F6FB`.
- Header: centered “Report a Problem”, **28px** close (`Icons.close_rounded`) on the right, 48px left spacer for optical balance.
- Horizontal padding **20**.
- **Camera box:** height **188**, corner radius **20**, dashed stroke 2px `#4A62AD` (dash 8 / gap 6) on `#EEF1F8`. Camera icon **48**. Preview uses the same 188×full-width well; Remove / Retake outlined row with **10** gap.
- **Mic:** **96×96** circle, `#4A62AD` idle / `#C62828` recording, icon 44, shadow blur 18. Waveform canvas **220×36**, stroke 3.2, 22 bars. Timer `#4A62AD`.
- **Title field:** fill white, content padding **16 / 16**, radius **14**, 16px text. Hint: “What is the issue?”
- **Submit:** full width, height **56**, radius **16**, fill `#4A62AD`, label `🚀 Submit Report`.
- **Success overlay:** 20px dialog radius, 64px `#4CAF50` check, 18/800 copy “Report Submitted Successfully!”, primary “Back to feed”.

## Placeholder art

When `imageUrl` is null on feed cards (and on a mocked camera capture), paint asphalt + oval pothole so the UI works without bundled assets.
