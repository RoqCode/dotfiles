---
name: system-context
description: Clarifies the system context, responsibilities, and contracts relevant to a finding or change. Use when callers, shared state, or component boundaries influence the cause, consequences, or choice of intervention point, and when explaining why a change belongs in a specific location.
---

# System Context and Intervention Point

Build a task-focused picture of the affected system. The developer should be able to assess why behavior occurs, which component owns a guarantee, and what consequences an intervention there has. Use the skill for investigation and decision-making. It neither expands the assignment or permissions nor requires a complete architectural overview.

## Start from Concrete Behavior

Start from the finding or desired behavior change. Formulate the question for which you need context: for example, who determines a deadline, who handles an error, or who releases a shared resource. Continue using sources that have already been checked.

Trace the relevant control or data flow from the trigger through the decisive processing to the visible effect. Read the callers, interfaces, and implementations actually involved. Filenames, directory structure, and type names are clues about responsibilities, not evidence of them.

Investigate additional surroundings only when they could change the diagnosis, intervention point, or a relevant consequence. Stop expanding the scope when these questions are sufficiently resolved; name remaining uncertainty specifically.

## Check Guarantees and Responsibilities

Choose only the questions below that are decisive for the case:

- What inputs and states does a component expect, and what does it actually guarantee to its callers?
- Who owns state or resources, and who controls their lifetime?
- Where do errors originate, and who decides about aborting, retrying, or fallback behavior?
- Does the behavior apply only to this caller or to all users of a shared component?
- Which ordering, concurrency, or system boundary influences the effect?

Separate requirements, documented guarantees, observed implementation, and open assumptions. If they conflict, make the conflict visible instead of silently assuming one version is correct. Do not infer the authors' original intent from the existing code alone.

## Evaluate the Intervention Point

Distinguish the location where a symptom becomes visible, the established cause, and the location where a solution can sensibly be enforced. These may coincide, but they do not have to.

Evaluate an intervention based on whether the component has the necessary information and control, whether the desired guarantee matches its responsibility, and which other callers would be affected. A general guarantee may belong in a shared component; a caller-specific decision may have unwanted side effects there. Decide based on the actual case, not on a preferred architectural layer.

Compare alternative intervention points only when they lead to a different significant consequence. Name the decisive benefit and cost of a recommendation. If a missing product requirement determines the choice, formulate that open decision concretely. A larger redesign needs an established need in the current assignment.

## Convey the Relevant Picture

Condense the findings into the flow, the decisive responsibility, and its consequence for the finding or change. Support key statements with verified paths and symbols as well as the decisive actual code excerpts. Mark suggestions as suggestions.

When `code-tour` is used, this context flows into the appropriate stations. This skill provides the content foundation; an additional complete explanation is unnecessary. Without a tour, a brief justification supported by the code is sufficient. A small flow representation is useful when order or boundaries would otherwise be difficult to follow.

Also explain the limit of the conclusion: what can be derived from the code, and which claim still requires a measurement, reproduction, or domain decision? Show only details whose omission would materially distort the picture of cause, responsibility, or consequences.

Example of a relevant distinction: a completed wait does not automatically mean that the underlying work was cancelled. Check the concrete code to determine which component controls the wait and which controls the operation. Apply such distinctions only when they fit the case under investigation.
