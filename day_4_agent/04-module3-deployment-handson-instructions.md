# Module 3 Lab Guide: Agent Logging, Evaluation, Cloud Deployment & Operations Monitoring

---

## 📋 Pre-Flight Environment Context

Before starting this lab, verify the development environment and cloud targets configured in the preceding hands-on labs:

- **Google Cloud Project:** `<PROJECT_ID>` (e.g., `da-advanced-elevate`)
- **GCP Region:** `<REGION>` (Default: `us-central1` or `us`)
- **Agent Runtime Deployment Target:** `agent_runtime` (Serverless Vertex AI Reasoning Engine)
- **Agent Service Name:** `cymbal_operations_agent`
- **Reasoning Engine Service Account:** use the dedicated service account `cymbal-sa-data@<PROJECT_ID>.iam.gserviceaccount.com`
- **Telemetry BigQuery Dataset:** `agent_telemetry`

> [!IMPORTANT]
> **Project Parameterization:** Always replace `<PROJECT_ID>` with your assigned GCP Project ID when executing commands.

---

## 🏷️ Part 1: Logging (BigQueryAgentAnalyticsPlugin Configuration)

### Challenge 1.1: Create BigQuery Telemetry Dataset

#### 🎯 Objective
Create a dedicated BigQuery dataset to asynchronously stream and store all session logs (user prompts, LLM responses, tool invocation parameters, execution latency, and errors) generated during agent runs.

#### ⚙️ Requirements & Constraints
1. **Dataset ID:** `agent_telemetry`
2. **Region:** `us-central1`
3. Create the dataset using either the BigQuery command-line tool (`bq mk`) or the Google Cloud Console.

---

### Challenge 1.2: Connect ADK Telemetry Plugin in `app/agent.py`

#### 🎯 Objective
Register the official ADK framework telemetry plugin, `BigQueryAgentAnalyticsPlugin`, into the `App` instance so that all runtime agent interactions are automatically streamed to BigQuery and verified.

#### ⚙️ Requirements & Constraints
1. Import `BigQueryAgentAnalyticsPlugin` from the `google.adk.plugins.bigquery_agent_analytics_plugin` module.
2. Set the required environment variables (`PROJECT_ID`, `BQ_TELEMETRY_DATASET`, `REGION`) and initialize the plugin instance referencing them.
3. Inject the plugin instance into the `plugins` parameter when instantiating the `App` object in `app/agent.py`.

#### 🔍 Verification
- After adding the plugin, execute a natural language query to the agent in your local environment (`adk web app` or CLI).
- Verify in the BigQuery Console that the specified dataset (`agent_telemetry`) and event table (`events`) are created and that query execution and tool invocation logs are streamed in real time.

#### 💡 Hints & Clues
- *(Reference: [ADK BigQuery Agent Analytics Integration Guide](https://adk.dev/integrations/bigquery-agent-analytics/))*

---

## 🏷️ Part 2: Evaluation (Local Quality Evaluation & Quality Gate)

### Challenge 2.1: Execute Baseline Evaluation with Provided `basic-dataset.json` & Pass Quality Gate

#### 🎯 Objective
Use the provided benchmark dataset (`basic-dataset.json`) containing representative use-case prompts to automatically evaluate tool selection accuracy (`tool_use_quality`) and response factual consistency (`grounding`) via `agents-cli eval run`, and verify that your agent satisfies the deployment Quality Gate threshold (>= 4.0 / 5.0).

#### ⚙️ Requirements & Constraints
1. Copy the provided dataset file (`basic-dataset.json`) into your evaluation datasets directory (`tests/eval/datasets/basic-dataset.json`).
2. Execute `agents-cli eval run` against `tests/eval/datasets/basic-dataset.json` specifying evaluation metrics: `tool_use_quality` and `grounding`.
3. Verify the evaluation scores and achieve an overall score of **4.0 or higher** to pass the Quality Gate.

#### 💡 Hints & Clues
- Use `agents-cli eval run --help` to check dataset path (`--dataset`) and metric specification (`--metrics`) flags.

---

### Challenge 2.2: Design Custom Evaluation Suite & Submit to Feedback Server

#### 🎯 Objective
Design your own comprehensive evaluation pipeline—including test datasets, metric configuration, and a structured 2-section evaluation report—and submit your repository to the **Feedback Server** for automated architectural and quality grading.

#### ⚙️ Requirements & Constraints
1. **Mandatory Evaluation Directory Structure:**
   Prepare your evaluation assets under `tests/eval/` adhering strictly to the following folder structure:
   ```text
   ├── tests/
   │   ├── eval/                         # Evaluation pipeline
   │   │   ├── datasets/                 # JSON datasets
   │   │   │   ├── eval-data.json
   │   │   │   └── eval-data2.json
   │   │   ├── eval_config.yaml          # Metrics and scoring configs
   │   │   └── evaluation_report.md      # Evaluation report & approach document
   ```
2. **Evaluation Datasets (`tests/eval/datasets/*.json`):**
   - Referring to the format of `basic-dataset.json`, design your own single-turn and **multi-turn conversation scenarios** (`eval-data.json`, `eval-data2.json`, etc.) grounded in the **BRD** specifications.
   - Beyond basic single-turn queries, ensure your datasets test **multi-turn context retention / intent switching** as well as **safety guardrails** (e.g., 0.70 RAG threshold refusal, PII card masking, mandatory date range clarification).
   - Ensure every `eval_case` contains a clear, non-empty `description`.
3. **Evaluation Configuration (`tests/eval/eval_config.yaml`):**
   - Define target evaluation metrics and scoring configurations (e.g., custom LLM-as-a-judge functions or ADK evaluation metrics).
   - Refer to the [agents-cli Evaluation Guide](https://google.github.io/agents-cli/guide/evaluation/?utm_source=gemini#evaluation-guide) for details on configuring metrics and custom evaluators.
4. **Evaluation Report (`tests/eval/evaluation_report.md`):**
   - Write a markdown report documenting your **Evaluation Approach** across the 4 core evaluation domains:
     1. **BRD Relevance**: How your test cases align with Cymbal Retail's core use cases and operational scope.
     2. **Metric & Configuration Rigor**: Rationale for selecting specific metrics and custom evaluators in `eval_config.yaml`.
     3. **Cost & Time Efficiency**: Strategies for managing token budgets and execution latency across single-turn and multi-turn runs.
     4. **Guardrail & Edge-Case Validation**: How your evaluation suite verifies safety guardrails and fault tolerance.
5. **Submit to Feedback Server:**
   - Commit and push your `tests/eval/` folder to your GitHub repository.
   - Access the **Feedback Server** at [go/da-advanced-eval-server](http://goto.google.com/da-advanced-eval-server), connect your GitHub account, and submit your repository to run automated validation and receive detailed rubric feedback.

#### 💡 Hints & Clues
- Refer to the official [agents-cli Evaluation Guide](https://google.github.io/agents-cli/guide/evaluation/?utm_source=gemini#evaluation-guide) to learn how to structure datasets, define `eval_config.yaml`, and run evaluation commands.

---

## 🏷️ Part 3: Deployment (Cloud Deployment & Enterprise Service Publication)

### Challenge 3.1: Deploy to Agent Runtime via `agents-cli deploy` & Playground Verification

#### 🎯 Objective
Package and deploy your locally validated ADK agent into Google Cloud's serverless container environment, **Vertex AI Agent Runtime (Reasoning Engine)**, and verify execution in the Cloud Console Playground.

#### ⚙️ Requirements & Constraints
1. **Deployment Target:** `agent_runtime`
2. **Service Name:** `cymbal_operations_agent`
3. **Region:** `us-central1`
4. **Service Account:** use the dedicated service account `cymbal-sa-data@<PROJECT_ID>.iam.gserviceaccount.com`
5. **Deployment & Playground Verification:** After deployment finishes, verify the created agent in the Google Cloud Console under **Vertex AI ➔ Agent Engines**, open the **Playground**, submit natural language queries, and confirm that the agent responds accurately just as validated locally.

#### 💡 Hints & Clues
- **Build Dependency Management:** Ensure the lockfile references the public PyPI index before initiating deployment to prevent build failures. Refer to the [Codelab Guide](https://codelabs.developers.google.com/enterprise-cloud-scale-deploying-the-expense-agent-to-agent-runtime-on-google-cloud) for detailed deployment workflows.
- **Service Account Permissions Check:** When the deployed Agent Runtime invokes backend resources (BigQuery, BigLake, Cloud Run MCP, Vertex AI, etc.), authorization errors (`403 Forbidden`) may occur. Ensure the specified Service Account `cymbal-sa-data@<PROJECT_ID>.iam.gserviceaccount.com` has sufficient IAM roles granted.

---

### Challenge 3.2: Register Agent to Gemini Enterprise & Configure Access Permissions

#### 🎯 Objective
Register the deployed Agent Runtime agent as an enterprise-wide tool in **Gemini Enterprise** and enable user access permissions so team members can interact with it in their workspace chat.

#### ⚙️ Requirements & Constraints
1. **Gemini Enterprise App:** Register the agent into the `da-adv-elevate-ge` application (create the app in the console if it does not already exist).
2. **Agent Registration:** Register the deployed `cymbal_operations_agent` (choose freely between the Cloud Console UI or `agents-cli publish gemini-enterprise`).
3. **User Access Permissions:** Configure permissions after registration so standard users can discover and converse with the agent in Gemini Enterprise chat.

#### 💡 Hints & Clues
- Newly registered agents may default to a private state. Review the **User permissions** settings in the agent configuration to ensure visibility for other users.
- After registration, test mentioning the agent in the Gemini Enterprise web chat interface to verify real-time responses.

---

## 🏷️ Part 4: Operations & Monitoring (BigQuery Agent Analytics Operational Monitoring & Telemetry)

> [!NOTE]
> **💡 BigQuery Agent Analytics Architecture & Operational Observability**  
> **[BigQuery Agent Analytics](https://docs.cloud.google.com/bigquery/docs/bigquery-agent-analytics)** is Google Cloud's official open-source observability solution that captures, streams, analyzes, and visualizes multimodal agent telemetry (prompts, LLM responses, tool arguments, latency, token usage, errors) at scale via the high-throughput [BigQuery Storage Write API (gRPC)](https://cloud.google.com/bigquery/docs/write-api) without blocking agent execution.  
> In this part, you will analyze your agent's operational metrics across: **1) Interactive exploration via BigQuery Conversational Agent** and **2) Comprehensive visual monitoring via the official open-source analytics dashboard notebook ([`dashboard_v2.ipynb`](https://github.com/GoogleCloudPlatform/BigQuery-Agent-Analytics-SDK/blob/main/examples/dashboard_v2.ipynb))**.

### Challenge 4.1: Interactive Telemetry Analysis via BigQuery Conversational Agent (Query Recipes)

#### 🎯 Objective
Use BigQuery Conversational Agent (BQ CA) to interactively explore and analyze operational logs (tool latencies, system errors, token consumption) across telemetry tables and views in the `agent_telemetry` dataset, without writing complex SQL manually.

#### ⚙️ Requirements & Constraints
1. **Data Agent Creation:** Create a Data Agent in BigQuery Studio scoped to all tables in the `agent_telemetry` dataset.
2. **Interactive Queries Based on Core Query Recipes:**
   - **[Cost & Token Analysis]** *"Aggregate total input tokens and output tokens and request count grouped by model (`model`)."*
   - **[Tool Performance & Latency]** *"Calculate the average and maximum execution latency per tool, sorted by the slowest tools first."*
   - **[Reliability & Error Analysis]** *"Find all failed tool calls or sessions with errors, showing the session ID, tool name, and error message."*
   - **[Tool Invocations Distribution]** *"Show the top 3 most frequently invoked tools and their percentage distribution."*
3. Verify that GoogleSQL generated by BQ CA properly references the auto-generated views (`v_tool_completed`, `v_llm_response`) or the `events` table.

#### 💡 Hints & Clues
- *(Reference: [Google Cloud BigQuery Agent Analytics](https://docs.cloud.google.com/bigquery/docs/bigquery-agent-analytics) | [ADK BigQuery Agent Analytics Query Recipes](https://adk.dev/integrations/bigquery-agent-analytics/#query-recipes))*

---

### Challenge 4.2: (Optional) Comprehensive Operational Monitoring via BigQuery Agent Analytics Dashboard Notebook (`dashboard_v2.ipynb`)

#### 🎯 Objective
Execute the official BigQuery Agent Analytics open-source dashboard notebook ([dashboard_v2.ipynb](https://github.com/GoogleCloudPlatform/BigQuery-Agent-Analytics-SDK/blob/main/examples/dashboard_v2.ipynb)) against telemetry streamed to `agent_telemetry.events` to visualize and analyze cost, usage volume, latency, and reliability metrics across 5 core operational panels.

#### ⚙️ Requirements & Constraints
1. Open the [dashboard_v2.ipynb](https://github.com/GoogleCloudPlatform/BigQuery-Agent-Analytics-SDK/blob/main/examples/dashboard_v2.ipynb) sample notebook in the BigQuery **Notebooks** environment.
2. In the configuration cell (Cell 1), specify `PROJECT_ID`, `DATASET_ID="agent_telemetry"`, `TABLE_ID="events"`, and `LOCATION="us-central1"`.
3. Run all notebook cells and interpret the **5 Core Monitoring Panels**:
   - **Panel 1 (Cost & Token):** Cumulative token consumption and cost trends by model
   - **Panel 2 (Usage Volume):** Session/turn counts and Top 3 tool call distribution
   - **Panel 3 (Reliability):** System error rates and tool failure breakdown
   - **Panel 4 (Performance Latency):** Tool-level P50 / P95 execution latency (ms)
   - **Panel 5 (TTFT):** User-perceived response latency (Time To First Token)

---

## ✅ Part 5: Final Acceptance Criteria

Verify your lab completion against the checklist below:

- [ ] **Telemetry Logging:** `BigQueryAgentAnalyticsPlugin` configured in `app/agent.py` with interaction events streaming to `agent_telemetry.events` upon query execution?
- [ ] **Local Quality Gate:** `agents-cli eval run` executed with `tool_use_quality` and `grounding` scores both meeting or exceeding 4.0?
- [ ] **Cloud Deployment & Playground:** `cymbal_operations_agent` deployed to Vertex AI Agent Runtime and verified responding correctly in Playground?
- [ ] **Gemini Enterprise Publication:** Agent registered in Gemini Enterprise with `User permissions` enabled for `All Users`?
- [ ] **Interactive Telemetry Analysis:** BigQuery Conversational Agent utilized to analyze latency, errors, and token consumption over `agent_telemetry` dataset tables?
- [ ] **Operational Analytics Dashboard:** 5 monitoring panels visualized and interpreted in BigQuery Notebook using `dashboard_v2.ipynb`?
