# Series

Lessons from one source (a book, a course) form a series with one story world. The series lives outside the session scratchpad, so the next session can continue it:

```
~/personal/lessons/<series-slug>/
  series.md                 the world, the cast, what each lesson fixed, the glossary, the next bug
  01-<lesson-slug>/         1-prose.md, 1-sheet.md, 2-diagram.html, 3-page.html, 4-video/
  02-<lesson-slug>/
```

Read `series.md` first. Update it last. Create it with the first lesson.

## series.md

```markdown
# <series title>
Source: <book, authors, edition>
Audience: <who, what they know>
Language: <lesson language>

## The world
<one paragraph: the setting the reader works in, for example "you are building a phone line">

## Lessons
| # | Lesson | Bug | Fix | Page | Status |
|---|---|---|---|---|---|
| 1 | Sampling and aliasing | your whistle comes out at the wrong pitch | sample faster, or filter first | https://claude.ai/artifact/... | needs rebuild |

## Glossary
<term>: <definition as the lessons define it> (lesson N)

## Next bug
<the cliffhanger the last lesson ended on>
```

- A term keeps the meaning and wording it got in its first lesson. Later lessons reuse it, they do not redefine it.
- The page link is stored so a rebuild republishes to the same URL. The Artifact tool only reads from the scratchpad or the repo, so copy the page and `lesson.css` into the scratchpad, then publish with `url` set to the stored link.
