# Rethinking the Modern Data Stack

Most teams buy their data stack one tool at a time, then spend two years discovering the tools disagree about what a "customer" is. That disagreement, not the tooling, is what costs money.

Start with ingestion. Batch loads on a six-hour cadence were fine when the only consumer was a Monday morning dashboard. They are not fine when the same table backs a fraud check that has 200 milliseconds to answer. Change-data-capture solves this, and it also doubles your on-call surface: every schema change upstream becomes a page at 3am. Budget for that.

The transformation layer is where most of the disagreement lives. Declarative modeling helps because it forces the definition of "customer" into a file someone can review, rather than into six analysts' SQL. It does not help if nobody owns the file. We tried this at two companies; the one where a named person approved every model change ended up with 140 models, the one without ended up with 900, of which roughly half were unused.

Governance is the part everyone defers. Lineage tooling is worth its price the first time an auditor asks which downstream reports touched a column you dropped. Before that, it looks like overhead.

None of this is a strategy. A strategy would say which three questions the business needs answered this year, and then buy only what answers them.
