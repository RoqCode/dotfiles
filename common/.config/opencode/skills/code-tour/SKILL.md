---
name: code-tour
description: Explains investigation findings, code paths, and code changes as a compact tour with actual code excerpts, their relationships, and important consequences. Use when multiple locations or a non-obvious mechanism need to be understood together, and for explicit tour requests.
---

# Code Tour

Give the developer a reliable picture of the relevant behavior. Structure the explanation around related mechanisms and decisions. Use the tour as a presentation within the ongoing collaboration; an explanation request must not change code or permissions.

## Determine the Subject and Evidence

Use the specified finding, code path, or diff. If no explicit subject is given, use the most recently discussed finding or change. Ask briefly if multiple subjects remain equally plausible.

Check the relevant sources before quoting them. For changes, clarify the intended comparison: working tree, staging area, commit, or branch comparison. Assign before and after excerpts to the actual state. Continue using existing verified findings; do not repeat a complete investigation solely for the presentation.

Show source code as it exists. Mark omissions and separate pseudocode or proposed changes from existing code. Do not invent evidence, paths, line numbers, measurements, or test results. If evidence exists only as a log or trace, show it appropriately and state that code access is missing.

## Build the Relationship

Begin with a brief orientation: which flow is affected, and what central statement should the tour make clear? Name only the system context required for that purpose.

Choose stations along the control flow, data flow, or a causal dependency. File order and the order of your research do not determine the tour. Include unchanged code when a caller, contract, or responsibility would otherwise remain unclear.

Connect the stations explicitly: which information, state, or obligation moves from the previous location to the next? Summarize known or mechanical parts. The number and size of stations should follow the independent relationships; do not use a fixed line or station quota.

## Present a Station

Use the following form by default:

1. **A meaningful heading:** Name the behavior or finding, not just a filename.
2. **Source reference and code excerpt:** Name the verified repository-relative path and relevant symbol, plus checked lines and the version state where needed. Show enough surrounding context to place the condition, call, and effect.
3. **A brief explanation:** Explain the mechanism, its significance for the task, and its connection to the next location. Add meaning that the reader cannot easily infer from the excerpt alone.

Place decisive consequences and uncertainties directly next to the related statement. In particular, distinguish observed behavior, a possibility derived from code, and an unverified assumption.

For changes, explain the behavior difference under the same conditions. For diagnoses, connect observation and conclusion and state what the evidence does not establish. Reproducing a symptom does not automatically confirm its cause in the production environment.

## Control the Level of Detail

Include a detail immediately when omitting it would create a materially false picture of the cause, behavior, intervention point, or consequences. Explain an individual line precisely when it carries the decisive difference.

Omit syntax repetition and irrelevant side paths. Briefly clarify unknown local terms. Make deeper fundamentals or implementation details available on request; do not hide an important limitation behind that offer.

Use a small comparison or flow representation when it makes order, parallelism, or states clearer. It should explain a concrete relationship rather than repeat the entire tour.

Present a manageable tour as one coherent explanation by default. For extensive subjects, give an overview first and group the stations. Proceed one station at a time only when requested. Answer follow-up questions directly, without quizzes, knowledge tests, or required confirmations.

Close with the consequence for the pending decision or the next verification step unless it has already been made clear. Justify the chosen intervention point only with reasons actually supported by the evidence; mark an open architecture question as open.
