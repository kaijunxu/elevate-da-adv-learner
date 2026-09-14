# Advanced Data Analytics — CE & Cloud Architect Enablement Workshop - Learner Materials

Consolidated learner materials for the four-day **Cymbal Retail Agentic Data Cloud** workshop. Separate repositories (linked below) are available for each individual section.

## Prerequisites:
- A Cloudtop instance with Terraform and `venv` installed.
- An IDE connected to Cloudtop with the Antigravity and Data Agent Kit extensions installed.
  - Learners are free to work in Antigravity or Jetski CLI, but should have an IDE available to review provided and generated code and other files.
  - IDEs tested and known to work are VS Code and (internal) Jetski IDE.
- A fresh, clean Argolis project, with `Owner` or `Project IAM Admin` access.

> [!WARNING]
> The hands-on activities involve using `terraform` commands, which are known to trigger security alerts/blocks on corporate laptops. Learners should perform all deployment steps from a terminal connected to their Cloudtop to minimize issues.

## Day 1 (module 0)
[Folder link](./day_1/) \
[Standalone repo link](https://github.com/kaijunxu/elevate-da-adv-day1)

- To be shared on day 1, after lunch break.
- Learners should deploy base infrastructure from the [deploy](./day_1/deploy/) folder following the [instructions](./day_1/deploy/module0-handson-instructions.md).
- Learners should also read and understand the [BRD](./day_1/brd.md) and use the provided [SDD template](./day_1/sdd-template.md) to prepare their own solution design.

## Day 2 (module 1)
[Folder link](./day_2/) \
[Standalone repo link](https://github.com/kaijunxu/elevate-da-adv-day2-labs)

- To be shared at the start of module 1 labs on day 2.
- Files are numbered according to the order of lab activities.
- Labs 1 and 2 must be completed for the data agent built in module 3 on day 3-4 to function properly.

## Day 3, Morning (module 2)
[Folder link](./day_3_1_streaming/) \
[Standalone repo link](https://github.com/kaijunxu/elevate-da-adv-day3-labs-streaming)

- To be shared at the start of module 2 labs on day 3 morning.
- All activities must be completed for the data agent built in module 3 on day 3-4 to function properly.

## Day 3, Afternoon (module 3)
[Folder link](./day_3_2_agent/) \
[Standalone repo link](https://github.com/kaijunxu/elevate-da-adv-day3-labs-agent)

- To be shared at the start of module 3 labs on day 3, after lunch break.
- Files are numbered according to the order of lab activities.

## Day 4 (module 3)
[Folder link](./day_4_agent/) \
[Standalone repo link](https://github.com/kaijunxu/elevate-da-adv-day4-labs-agent)

- To be shared when module 3 labs continue on day 4.
- The first three guides are identical copies from the previous day, provided for convenience.
- Only [lab 4](./day_4_agent/04-module3-deployment-handson-instructions.md) and the [basic eval dataset](./day_4_agent/basic-dataset.json) are newly added.

