---
description: Create a concise German worklog from the day CLI report
---

Führe `day report $ARGUMENTS` aus und fasse den Report als Tageszusammenfassung zusammen.

1. Gruppiere Einträge anhand von Ticket, Repository, Branch, Commit-Nachrichten und vorhandenem Kontext zu Tickets oder Jobs.
2. Fasse Einträge zusammen, wenn der Nutzer ausdrücklich sagt, dass mehrere Branches oder Repositories zum selben Ticket gehören. Überlappende Zeit darf dabei nicht doppelt zählen.
3. Formuliere je Ticket oder Job eine kurze Beschreibung als prägnante Nominalphrasen. Verbinde Themen mit ` | ` und lasse niedrige Implementierungsdetails weg, sofern sie nicht das Hauptergebnis sind.
4. Schätze die Arbeitszeit aus dem sichtbaren Aktivitätsfenster nur grob und gerundet. Kurze Branch-Checks oder Diffs ohne substanzielle Arbeit gelten als Review oder Check. Stelle Schätzungen nie als präzise dar.
5. Antworte auf Deutsch, ausschließlich in diesem Format:

`- **TICKET/JOB – Thema | Thema | Thema** — ca. **X Std.** (HH:MM–HH:MM, optionaler Kontext)`

Bei nur einem Ticket oder Job gib nur einen Bullet aus. Erkläre die Methode nicht.
