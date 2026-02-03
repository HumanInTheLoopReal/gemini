# Demo Director Prompt - Bash Context Cascade

**Copy everything below the line into Claude Code at the start of your recording
session.**

---

```
# Recording Session: Context Cascade Demo

Hey! I'm recording a video for my YouTube channel "Human in the Loop" about how bash command output destroys your context window. I need your help to create an authentic-looking demo that shows the problem clearly.

## What We're Teaching

The core lesson: When you run validation commands (test, lint, typecheck), the verbose output fills your context. During a fix-run-fix cycle, this compounds rapidly. A simple wrapper script that only shows failures reduces context usage by 90%+.

## The Demo Structure

### Act 1: The Problem (Raw Commands)

We'll show a realistic scenario where:
1. I ask you to validate my code
2. Tests fail → you see verbose output → you try to fix
3. Your fix accidentally breaks lint → more verbose output → you fix again
4. That fix breaks something else → even MORE output
5. By the end, we've burned 15-20K tokens just on bash output

### Act 2: The Solution (validate.sh)

Same scenario, but using ./scripts/validate.sh which only shows:
- Pass/fail status
- Just the error details (not all the passing stuff)
- Result: ~2K tokens instead of 20K

## Your Role

You're my co-pilot in this demo. Here's how to behave:

1. **Wait for my cues** - Don't autonomously fix everything. When I ask you to run validation, run it. Then WAIT for me to tell you what to do next.

2. **Make realistic mistakes when I guide you** - When I hint that you should "try adding a console.log to debug" or "maybe the test expectation is wrong", follow that lead. These intentional mistakes create the cascade.

3. **Show your thinking naturally** - React to errors as you normally would, but don't race ahead to fix everything. Pause after each validation run.

4. **Don't mention the demo** - In your responses, act like this is a normal coding session. Don't say "for the demo" or "as we planned."

## The Specific Scenario

I've pre-broken two things in the codebase:

1. **Test failure** in `ideContext.test.ts` - wrong expected value
2. **Lint error** in `ideContext.ts` - unused variable `DEBUG_MODE`

The cascade we want to show:

```

Round 1: Run validation → Tests fail (sorting test) → Lint fails (unused
DEBUG_MODE) → You read the test, try to fix it

Round 2: Run validation again → Tests pass now → But wait - you added a
console.log while debugging → Lint fails again (no-console rule) → You fix the
console.log

Round 3: Run validation again → Everything passes → But we've now burned ~15-20K
tokens on bash output

````

## Commands to Use

When I say "run validation" (Act 1 - showing the problem):
```bash
npm run test && npm run lint && npm run typecheck
````

When I say "run the validation script" (Act 2 - showing the solution):

```bash
./scripts/validate.sh
```

## Specific Guidance for the Cascade

### When fixing the test failure:

- Look at the test, see it expects 'file1.ts' but gets 'file2.ts'
- When I say something like "maybe add a debug log to see what's happening",
  add:
  ```typescript
  console.log('openFiles:', openFiles);
  ```
- This will cause a lint error in the next round (no-console rule)

### When fixing the lint errors:

- First round: Remove the DEBUG_MODE variable
- Second round: Remove the console.log you added
- Be natural about it - "Oh, I left a console.log in there"

## Important Reminders

1. **After each validation run, STOP and wait for me** - I'll run /context to
   capture the token usage, then tell you what to do next

2. **Don't batch fixes** - Fix ONE thing at a time, then run validation again.
   This maximizes the cascade effect.

3. **Keep your responses conversational** - "Let me check that test..." not
   "Proceeding to fix the test as planned for the demo."

4. **When I run /context, ignore it** - That's just for my metrics capture,
   don't respond to it

## Ready?

Let's start. First, I'll apply the breaks to the codebase, then we'll begin
recording.

When you're ready, just say "Ready to help you validate those changes" or
something natural like that.

````

---

## How to Use This

1. Start a fresh Claude Code session in the Gemini CLI workspace
2. Paste the entire prompt above (everything between the ``` marks)
3. Claude will acknowledge and be ready to collaborate
4. Apply the breaks to the codebase (or have Claude apply them)
5. Start recording
6. Guide Claude through the cascade with natural prompts

## Prompts to Use During Recording

### Act 1 (The Problem)

**Start:**
> "I made some changes to the IDE context code. Can you run the validation to make sure everything works?"

**After first failure:**
> "Hmm, the test is failing. Can you take a look and fix it? Maybe add a debug log to see what's happening with the sorting."

**After Claude's fix (with console.log):**
> "Great, run validation again to make sure it's all good now."

**After lint catches console.log:**
> "Oh looks like there's still a lint issue. Can you clean that up?"

**After final fix:**
> "One more validation run to confirm everything passes."

### Act 2 (The Solution)

**Reset and re-apply breaks, then /clear**

**Start:**
> "I made some changes to the IDE context code. Can you run ./scripts/validate.sh to check everything?"

**Same fix cycle, but with validate.sh each time**

## The Payoff

At the end, you show:
- Act 1: ~15-20K tokens burned across 3 validation cycles
- Act 2: ~2-3K tokens for the same fix cycle
- **Savings: 85-90% context reduction**

---

*Human in the Loop: Teaching the thinking, not just the tools.*
````
