# Module 3 Lab Guide: Building Semantic Layer & IDE-Native Data Exploration

---

## 📋 Pre-Flight Environment Context

Before starting this lab, verify the infrastructure and datasets provisioned in preceding modules:

- **Google Cloud Project:** `<PROJECT_ID>` (e.g., `da-advanced-elevate`)
- **GCP Region:** `<REGION>` (Default: `us-central1` or `us`)
- **Target BigQuery Datasets:**
  - `<PROJECT_ID>.cymbal_gold` (Structured Gold Serving Layer)
  - `<PROJECT_ID>.module1_unstructureddata` (Extracted Unstructured Document Layer)
  - `<PROJECT_ID>.cymbal-lakehouse.elevate_data` (Cross-Cloud AWS S3 BigLake Federated Layer)
- **Module 3 Comprehensive Table Inventory (7 Tables):**
  1. `<PROJECT_ID>.cymbal_gold.pos_transactions_gold` (Real-time intraday POS checkout ledger)
  2. `<PROJECT_ID>.cymbal_gold.pos_anomaly_alerts` (Real-time anomaly & promo abuse alert ledger)
  3. `<PROJECT_ID>.cymbal_gold.gold_inventory_reconciliation_ledger` (Daily reconciled store inventory & burn-rate ledger)
  4. `<PROJECT_ID>.cymbal_gold.historical_transactional_data` (Historical customer transaction ledger)
  5. `<PROJECT_ID>.cymbal_gold.pos_manual_generic_embeddings` (POS hardware technical manual vector embeddings ledger)
  6. `<PROJECT_ID>.module1_unstructureddata.warranty_generic_sections_extracted` (AI-extracted warranty terms & conditions)
  7. `<PROJECT_ID>.cymbal-lakehouse.elevate_data.silver_pos_transactions` (Cross-cloud AWS S3 checkout ledger)

> [!NOTE]
> **💡 Tables Excluded from Semantic Layer (Module 3-1) Hands-on & Rationale**  
> Of the 7 tables across Module 3, **this Semantic Layer lab focuses strictly on 5 core analytical tables (`pos_transactions_gold`, `pos_anomaly_alerts`, `gold_inventory_reconciliation_ledger`, `historical_transactional_data`, and `warranty_generic_sections_extracted`), excluding the following 2 tables:**  
>  
> 1. **`cymbal-lakehouse.elevate_data.silver_pos_transactions` (Cross-Cloud Federated Table)**  
>    - **Exclusion Rationale:** As an external BigLake federated table pointing directly to AWS S3, BigQuery and Knowledge Catalog have platform limitations such as **inability to generate Data Insights** and **inability to modify table/schema descriptions or metadata directly**.  
>    - **Downstream Usage:** Excluded from catalog metadata authoring in Module 3-1, but directly queried for cross-cloud audit analysis in subsequent labs (**Module 3-2 BQCA** and **Module 3-3 ADK Agent**).  
>  
> 2. **`cymbal_gold.pos_manual_generic_embeddings` (Unstructured Vector Embeddings Table)**  
>    - **Exclusion Rationale:** Originating from Module 1 as vector embeddings of POS hardware manual PDFs, this table is stored specifically for **Vector RAG (retrieval-augmented generation)**. It is not an analytical table requiring statistical profiling, Data Quality rules, or business metric formulas (Glossary).  
>    - **Downstream Usage:** Actively utilized as a semantic search retrieval source in **Module 3-3 ADK Agent**.  

> [!IMPORTANT]
> **Project Parameterization:** Always replace `<PROJECT_ID>` with your assigned GCP Project ID in your commands and queries.

> [!TIP]
> **💡 Hands-on Best Practice: Console Experience & Verification Guide**  
> While the resources in this lab can be provisioned using APIs or CLI scripts, we recommend the following approach to gain firsthand familiarity with Google Cloud's data governance workflows:  
>  
> 1. **Create at least one resource directly in the Console UI:**  
>    - You do not need to build every asset through the UI, but we encourage configuring **at least one item in each challenge** (e.g., a Data Quality rule, an Aspect binding, or a Business Glossary term) directly in the Google Cloud Console to experience the platform interface.  
> 2. **Always perform the 🔍 Console Verification step in your browser:**  
>    - Even if you execute the tasks using API or CLI commands, **always complete the `🔍 Console Verification` step in the browser** for each challenge to inspect how the metadata is linked and visualized in BigQuery Studio and Dataplex Knowledge Catalog.

---

## 🏷️ Part 1: Cloud-Native Governance & Metadata Automation

### Challenge 1.1: Configure Data Profile Scan & Resolve Streaming/Security Constraints

#### 🎯 Objective
Utilize BigQuery Studio and Knowledge Catalog to collect statistical profiles (null ratio, distinct values, min/max values, distributions) for tables in the `cymbal_gold` dataset and publish them to the catalog. 

#### ⚙️ Requirements & Constraints
1. **Scan Creation & Execution Method:** Creating and executing the scan via the GCP Console UI is recommended to explore supported options. (Scan type and scan name can be chosen freely)
2. **Target Data:** 4 tables in the `cymbal_gold` dataset (`pos_transactions_gold`, `pos_anomaly_alerts`, `gold_inventory_reconciliation_ledger`, `historical_transactional_data`)  
   *(💡 Note: The extracted document table `module1_unstructureddata.warranty_generic_sections_extracted` is a small static reference table of 26 rows. It is excluded from profile scanning to keep the focus on batch profiling large transactional/inventory ledgers within the `cymbal_gold` dataset.)*
3. **Catalog Publishing:** Enable the option to publish profiling results to Knowledge Catalog.
4. **Export to BigQuery Table:** During profile scan creation, enable **Export scan results to BigQuery table** (specifying the target dataset, e.g., `<PROJECT_ID>.cymbal_governance`) so that profile metrics are saved into BigQuery. Once the scan completes, verify that the profiling results are successfully written to the BigQuery table.
5. **Data Sampling Configuration & Streaming Considerations:**
   - Configure data sampling (default percentage or full scan) according to your preferences. If real-time streaming data is actively ingesting, partial sampling may intermittently encounter engine limitations; adjust the sampling scope if an error arises.

#### 🔍 Console Verification (Data Profile)
Once the profiling scan is complete, verify the generated metadata in the GCP Console:
* First, navigate to **BigQuery** > **Metadata curation** > **Data profile & Quality** and check the scan list to confirm that your profile scan was successfully generated and its execution status is successful.
* Next, navigate to **BigQuery** and open any targeted table (e.g., `pos_transactions_gold`).
* Click the **Profile** tab of the table to verify that statistical profiling metrics (null ratio, min/max, distinct values) are visually displayed.
* Finally, open the exported target BigQuery dataset (e.g., `.cymbal_governance`) and preview the tables to confirm that the profile scan records are persistently stored.

#### 💡 Hints & Clues
- **Batch Multi-Table Profiling:** In BigQuery Console > **Metadata curation** > **Data profiling & Quality** (or Knowledge Catalog Console > **Data profile & quality**), you can create profile scans for multiple tables simultaneously using the **Multiple data profile scans** option. (Note: This feature only supports tables within the same dataset. For tables in different datasets, you must create separate profile scans.)
- **Streaming Table Sampling Considerations:** Depending on whether real-time data is actively writing to the streaming buffer, partial sampling (such as 10%) can intermittently return `TABLESAMPLE is not supported for tables with a streaming buffer`. If you encounter this error, adjust the data sampling option to **`All data` (Full Scan)** and retry.

---

### Challenge 1.2: Build Retail Domain Data Quality Scan

#### 🎯 Objective
Ensure data reliability for `pos_transactions_gold` by building and executing a Data Quality (DQ) scan that combines essential baseline rules with Custom SQL business integrity rules.

#### ⚙️ Requirements & Constraints
1. **Scan Name:** `pos-transactions-quality-scan` (or choose freely)
2. **Target Table:** `<PROJECT_ID>.cymbal_gold.pos_transactions_gold`
3. **3 Core Quality Rules:**
   - **[Completeness] Identifier Missing Value Check:** Mandatory identifier completeness (`transaction_id IS NOT NULL`).
   - **[Business Integrity] Payment Amount Integrity:** Net payment total (`total`) must equal subtotal (`subtotal_amount`) minus discount (`discount`) plus tax (`tax_amount`) (`total = subtotal_amount - discount + tax_amount`).
   - **[Business Integrity] Cart Quantity Integrity:** Distinct SKU count in cart (`item_count`) cannot exceed total units purchased (`total_quantity`) (`item_count <= total_quantity`).
4. **Publish & Execute:** Publish results to Knowledge Catalog and run the scan immediately to verify rule evaluation.

#### 💡 Hints & Clues
- **Console Navigation:** Knowledge Catalog > **Data profile & quality** > **CREATE DATA QUALITY SCAN** (or BigQuery Studio > target table > **Data Quality** tab > **Create scan**).
- **Rule Type Selection Guide (When clicking `Add rule`):**
  | Verification Rule | Console Rule Type | Column & Parameter Configuration |
  | :--- | :--- | :--- |
  | **Identifier Completeness** (`transaction_id IS NOT NULL`) | **Built-in rule type** ➔ **`Null check`** | • Column: `transaction_id` |
  | **Payment Amount Integrity** (Calculation formula) | **`SQL row check`** | • SQL statement:<br>`total = subtotal_amount - discount + tax_amount` |
  | **Cart Quantity Integrity** (SKU count vs quantity) | **`SQL row check`** | • SQL statement:<br>`item_count <= total_quantity` |

#### 🔍 Console Verification (Data Quality)
Verify that the DQ scan successfully executed and applied your custom rules:
* Navigate to the **Data Quality** tab of the `.cymbal_gold.pos_transactions_gold` table in the BigQuery Console.
* Review the latest scan results to confirm that both the baseline rules and your Custom SQL business integrity rules were evaluated.
* Inspect the rule-level details to see the pass/fail status and row-level quality metrics provided directly in the UI.

---

### Challenge 1.3: Gemini in BigQuery Data Insights & Semantic Table Description Standardization

#### 🎯 Objective
Use BigQuery Studio **Data Insights** and catalog metadata management to persist clear, standardized **Table Descriptions** and column annotations, ensuring AI Data Agents (NL2SQL) accurately route user queries without ambiguity across overlapping transactional and operational tables, and generate dataset/table-level insights.

> [!IMPORTANT]
> **💡 Core Architecture: Why Table Descriptions are Vital for AI Data Agents**  
> When building natural language data analytics agents, the descriptions of tables and columns are primarily referenced as the most critical signals to identify the tables most relevant to a natural language query. When descriptions are missing or ambiguous across tables with similar schemas or data, the agent may misroute queries to the wrong tables or suffer increased latency due to extended table discovery time. Providing clear and precise descriptions according to intent significantly improves SQL generation accuracy. In addition, rich table and column descriptions substantially enhance the quality of generated Gemini Data Insights. [Reference: BigQuery Best practices for generating data insights](https://docs.cloud.google.com/bigquery/docs/generate-table-insights#best_practices_for_generating_data_insights)

#### ⚙️ Requirements & Constraints
1. **Add Table Descriptions:**
   Ensure each of the 5 core analytics tables (`cymbal_gold` 4 tables + `module1_unstructureddata` 1 table) in BigQuery Studio / Knowledge Catalog has its Table Description set according to the standard specifications below:

| Dataset / Table | Standard Table Description (English) | Primary AI Agent Routing Intent |
| :--- | :--- | :--- |
| `cymbal_gold.pos_transactions_gold` | `Real-time streaming intraday POS sales transactions with customer PII for daily store revenue and sales KPI monitoring. (Use for today's sales and daily revenue KPIs).` | Today's streaming sales, daily store revenue, payment method breakdowns |
| `cymbal_gold.historical_transactional_data` | `Historical customer item purchase transactions used strictly for product warranty claims triage and returns eligibility. (Use for customer purchase verification in warranty workflows).` | Past customer purchases joined with warranty policies |
| `cymbal_gold.pos_anomaly_alerts` | `Historical multi-day cashier anomaly and promo abuse alert ledger (partitioned by alert_ts). Primary table for multi-day trend analysis, 7-day/30-day top offender rankings, and historical override rate calculations. (NOTE: For real-time 1-hour live audit status and streaming flags, query Cloud Bigtable operational cache).` | Multi-day promo abuse trends, 7-day/30-day top offender ranking, promo override rate formulas |
| `cymbal_gold.gold_inventory_reconciliation_ledger` | `Daily reconciled store inventory ledger tracking opening balance, shelf/backroom quantities, intraday revenue, and remaining cover hours for stockout risk analysis.` | Store inventory levels, stockout risk (< 20h), critical burn spikes (< 6h), ATP stock |
| `module1_unstructureddata.warranty_generic_sections_extracted` | `Extracted product warranty policy terms, coverage duration in months, service levels, exclusions, and official support URLs for warranty claim evaluation.` | Warranty duration, claim SLAs, service center policies, support URLs |

2. **Generate Table-Level Data Insights (All 5 Core Tables):**
   - In BigQuery Studio Explorer, open each of the 5 core analytical tables (`pos_transactions_gold`, `gold_inventory_reconciliation_ledger`, `pos_anomaly_alerts`, `historical_transactional_data`, and `warranty_generic_sections_extracted`).
   - Navigate to the **Insights** tab and click **`Generate and publish`**.
   - Review generated column descriptions and click **`Save to details`** and **`Save to schema`** to permanently persist them into catalog schema metadata.
3. **Generate Dataset-Level Data Insights (ERD Relationship Graph):**
   - Click the `cymbal_gold` dataset itself in Explorer and navigate to the top **Insights** tab.
   - Execute **`Generate and publish`** to inspect the Gemini-analyzed dataset overview, **Interactive Relationship Graph (ERD)**, and suggested join queries.

#### 🔍 Console Verification (Data Insights & Metadata Validation)
Verify the generated insights and validate the metadata best practices in BigQuery Studio:
* **Review Recommended Descriptions & Save to Schema:** Open the **Insights** tab for each table to review the Gemini-generated **Table description** and **Column descriptions**. 
* **Inspect Profiling Grounding (Example Values in Descriptions):** Verify that the generated column descriptions include real-world **example values, valid ranges, or format representations**. This confirms that Gemini Data Insights actively grounds its description generation on the **Data Profiling results (null rates, distinct value cardinality, and min/max stats)** produced in Challenge 1.1.
* **Validate Documentation Best Practices:** Confirm firsthand the principles documented in [Google Cloud Best Practices for Generating Data Insights](https://docs.cloud.google.com/bigquery/docs/generate-table-insights#best_practices_for_generating_data_insights): that **(1) providing a comprehensive table description beforehand** and **(2) running data profile scans in advance** are the key prerequisites for generating the highest-quality AI metadata and insights.
* **Inspect Dataset ERD Relationship Graph:** In the `cymbal_gold` dataset **Insights** tab, review the visual Relationship Graph (ERD) and suggested join queries to ensure Gemini accurately identified cross-table transactional relationships.

---

### Challenge 1.4: Define Knowledge Catalog Aspect Type & Bind Governance Schema

#### 🎯 Objective
Overcome the limitations of unstructured text tags by registering a strongly typed **Aspect Type** schema contract to govern data asset architecture, refresh cadence, and PII presence, and bind it to the 5 core tables.

> [!IMPORTANT]
> **💡 Core Architecture: Division of Roles between Aspect Type and Business Glossary**  
> • **Aspect Type (`table-operational-spec`)**: Governs pipeline type (`table_type`), PII presence (`pii_included`), and domain ownership (`data_owner_team`) as a **strongly typed schema contract** for catalog search and governance audits.  
> • **Business Glossary (`cymbal-retail-glossary`)**: Defines natural language business concepts and **SQL calculation formulas (`Formula`)** so that **BigQuery Conversational Agent (BQ CA) directly references them during NL2SQL generation**.

#### ⚙️ Requirements & Constraints
1. **Aspect Type ID:** `table-operational-spec` (Location: `us-central1`)
2. **3 Governance Field Specifications:**

| Field ID | Data Type | Required | Allowed Values (Enum) / Description |
| :--- | :--- | :--- | :--- |
| `table_type` | Enum | Required | `STREAMING_TABLE`, `BATCH_TABLE`<br>*(Distinguishes Module 2 real-time streaming vs batch table architectures)* |
| `pii_included` | Boolean | Required | `true` / `false`<br>*(Audits presence of sensitive customer/payment data)* |
| `data_owner_team` | Enum | Required | `store-ops`, `inventory-mgmt`, `loss-prevention`<br>*(Domain ownership - 1:1 mapping with Business Glossary categories)* |

3. **5 Table Binding Criteria Matrix:**

| Table Name | `table_type` (Enum) | `pii_included` (Bool) | `data_owner_team` (Enum) | Description |
| :--- | :--- | :--- | :--- | :--- |
| `pos_transactions_gold` | `STREAMING_TABLE` | `true` | `store-ops` | Real-time intraday POS checkout ledger |
| `pos_anomaly_alerts` | `STREAMING_TABLE` | `false` | `loss-prevention` | Real-time anomaly alert ledger |
| `gold_inventory_reconciliation_ledger` | `BATCH_TABLE` | `false` | `inventory-mgmt` | Daily reconciled store inventory ledger |
| `historical_transactional_data` | `BATCH_TABLE` | `true` | `store-ops` | Historical transaction ledger |
| `warranty_generic_sections_extracted` | `BATCH_TABLE` | `false` | `store-ops` | AI-extracted unstructured warranty policies |

#### 🔍 Search & Binding Verification
After attaching aspects to tables, verify that resources associated with the Aspect Type and its field values can be retrieved accurately using Knowledge Catalog console UI filtering and search syntax:

1. **Console UI Filtered Search Steps:**
   - Navigate to **Knowledge Catalog** > **Search** in the GCP Console.
   - In the left filter panel under **Filters** > **Aspect types**, check and select `table-operational-spec`.
   - Click **Filter on aspect type values** next to the selected aspect type.
   - Specify the target aspect field and value:
     - E.g., select `table_type = STREAMING_TABLE` ➔ Confirm that only `pos_transactions_gold` and `pos_anomaly_alerts` are returned.
     - E.g., select `data_owner_team = store-ops` ➔ Confirm the 3 store-ops tables are retrieved.
2. **Structured Aspect Search Syntax:**
   - You can also query directly in the search bar using aspect search syntax. Refer to the [Knowledge Catalog Aspect Search Syntax Documentation](https://docs.cloud.google.com/dataplex/docs/search-syntax#aspect-search) for full syntax rules.

---

### Challenge 1.5: Business Glossary Standardization & Related Entries Binding

#### 🎯 Objective
Build an enterprise business glossary containing **standardized calculation formulas (`Formula`) and query filter guardrails** so business analysts and AI agents (BQ CA) can compute metrics unambiguously.

> [!IMPORTANT]
> **💡 Core Principle: BQ CA Term Description Injection Mechanism**  
> BigQuery Conversational Agent injects **ONLY the `Description` text** of Business Terms bound to tables into the model prompt.  
> Therefore, you must write structured descriptions following a consistent template (`[Definition]`, `Target Table`, `Formula`, `Filter/Risk Guardrail`) and bind target tables as **Related Entries**.

#### ⚙️ Requirements & Constraints
1. **Glossary ID:** `cymbal-retail-glossary` (Location: `us-central1`)
2. **3 Categories:** `store-ops`, `inventory-mgmt`, `loss-prevention`
3. **5 Core Business Terms:**

| Term ID | Display Name | Category | Target Resource (Related Entry) | Business Definition & Calculation Requirements |
| :--- | :--- | :--- | :--- | :--- |
| `net-transaction-revenue` | Net Transaction Revenue | `store-ops` | `pos_transactions_gold` (Table) | • **Definition**: Actual net revenue paid by customer after discounts and taxes<br>• **Formula**: `subtotal_amount - discount + tax_amount`<br>• **Filter**: Valid transactions only (`total > 0`) |
| `total-on-hand-inventory` | Total On-Hand Inventory | `inventory-mgmt` | `gold_inventory_reconciliation_ledger` (Table) | • **Definition**: Combined total physical inventory on retail shelves and in backroom storage<br>• **Formula**: `(shelf_qty + backroom_qty)` |
| `inventory-cover-hours` | Estimated Inventory Cover Hours | `inventory-mgmt` | `gold_inventory_reconciliation_ledger` (Table) | • **Definition**: Estimated operational hours remaining until stockout at current sales velocity<br>• **Formula**: `SAFE_DIVIDE((shelf_qty + backroom_qty), (total_units_sold_intraday / 12.0))`<br>• **Risk Flag**: `<= 6.0` ('CRITICAL_BURN_SPIKE'), `<= 12.0` ('MONITOR_VELOCITY') |
| `cashier-override-rate` | Cashier Promo Override Rate | `loss-prevention` | `pos_anomaly_alerts` (Table) | • **Definition**: Proportion of cashier checkouts with promo override abuse alerts<br>• **Formula**: `SAFE_DIVIDE(COUNTIF(alert_type = 'cashier_promo_abuse'), COUNT(*))` |
| `warranty-policy-duration` | Warranty Policy Duration | `store-ops` | `warranty_generic_sections_extracted`'s `warranty_duration_months` (Column-Level Binding 🎯) | • **Definition**: Certified warranty coverage period in months<br>• **Target Column**: `warranty_duration_months` (Evaluation: `DATE_DIFF(CURRENT_DATE(), purchase_date, MONTH) <= warranty_duration_months`) |

> [!TIP]
> **💡 Hint: Column-Level Business Term Binding Steps (GCP Console UI)**  
> In the **Google Cloud Console UI**, the `Related entries` search field in the Glossary Term creation modal only supports searching and selecting table-level entries, not individual columns.  
> Therefore, when configuring this via the Console UI, to link `warranty-policy-duration` directly to a specific column (`warranty_duration_months`), you must initiate the binding from the **Table's Schema tab in the Console**:  
> 1. In **Knowledge Catalog** > **Search**, search for the `warranty_generic_sections_extracted` table and click on it.  
> 2. Click the **Schema** tab.  
> 3. Select the **checkbox** next to the `warranty_duration_months` column.  
> 4. Click the **`Add business term`** button on the top toolbar.  
> 5. Expand `cymbal-retail-glossary`, select `warranty-policy-duration`, and click **Save**.  
> *(Once saved, returning to the `warranty-policy-duration` term details in the UI will display the column explicitly listed under Related entries.)*

#### 🔍 Console Verification (Glossary & Related Entries)
Ensure the business terms and their relationships to physical tables and columns are correctly established:
* Navigate to **Knowledge Catalog** > **Business glossaries** in the GCP Console.
* Open `cymbal-retail-glossary` and verify that all 5 business terms are successfully populated under their respective categories.
* For table-level terms (e.g., `net-transaction-revenue`), click on the term and verify the BigQuery table (`pos_transactions_gold`) is listed under **Related entries**.
* For the column-level term (`warranty-policy-duration`), click on the term and verify that the specific column (`warranty_generic_sections_extracted` > `warranty_duration_months`) is explicitly bound under **Related entries**.

---

## ✅ Part 2: Final Acceptance Criteria (Core Lab)

Verify your core lab completion against the checklist below:

> [!NOTE]
> **Console Verification Verification:** The completion criteria assess not only the successful execution of CLI/API commands, but whether the resulting metadata and scan outcomes are accurately reflected and visually confirmed directly in the Google Cloud Console (BigQuery Studio & Knowledge Catalog).

- [ ] **Data Profile Scan:** Profile scan created/executed via GCP Console UI, profile statistics verified in BigQuery Console under each table's Profile tab, and scan results confirmed in the exported BigQuery table?
- [ ] **Data Quality Scan:** 3 core quality rules executed, validating identifier completeness (Built-in Null check) and net payment / cart quantity integrity (SQL row check)?
- [ ] **Gemini Data Insights & ERD:** Table-level Insights on all 5 core analytical tables and dataset-level Insights published in BigQuery Studio with ERD graph and schema descriptions?
- [ ] **Knowledge Catalog Aspect:** `table-operational-spec` Aspect Type created and bound with operational metadata across all 5 tables?
- [ ] **Aspect Search:** Tables accurately retrieved via Knowledge Catalog UI Search filtering?
- [ ] **Business Glossary:** `cymbal-retail-glossary` populated with 5 core terms using standardized description templates and bound Related Entries (4 tables and 1 column)?

---

## 🎁 [Optional Lab] IDE-Native Exploration & Metadata as Code (Data Agent Kit & MaC)

> [!NOTE]
> **💡 Why is this lab optional?**  
> This section guides you through developer-centric IDE workflows using **Data Agent Kit (DAK)** and **Metadata as Code (MaC)**. Because the subsequent labs (Module 3-2 BQCA and Module 3-3 ADK Agent) interact directly with Google Cloud services, this hands-on exploration of local IDE agents and git-versioned metadata snapshots is provided as an optional advanced module for attendees who complete the core governance lab early.

### Optional Challenge 1: Data Agent Kit (DAK) Schema Exploration & Ungrounded NL2SQL Attempt

#### 🎯 Objective
Explore BigQuery datasets and table schemas via natural language directly inside **your IDE (Agent Chat Panel)** using the Data Agent Kit (DAK), and experience the baseline limitations of ungrounded queries before metadata context is available.

#### ⚙️ Lab Mission
1. **Interactive Schema Exploration:** Open the IDE Agent chat panel and query the agent in natural language:
   - Query for the list of BigQuery datasets in the current project.
   - Query the schema for `pos_transactions_gold` and `gold_inventory_reconciliation_ledger`.
2. **Ungrounded Query Attempt (Before):**
   In the IDE chat panel, execute the following query directly without providing business glossary or metadata context:
   > *"Calculate the cashier promo override rate for store STORE_048 today"*
   > *(Observe how the agent, lacking the Business Term override formula, routes to the wrong table or invents an arbitrary calculation resulting in hallucinations.)*

---

### Optional Challenge 2: Metadata as Code (MaC) Setup & Catalog Snapshot Sync

#### 🎯 Objective
Build the **`kcmd` (Knowledge Catalog Metadata as Code)** tool and configure it as an IDE MCP server (`kc-mac`) to enable version-controlled GitOps workflows for Knowledge Catalog metadata, then synchronize table metadata, schemas, descriptions, and custom Aspect definitions for the `cymbal_gold` dataset into local snapshot files (`catalog.yaml` and `catalog/` directory).

#### ⚙️ Requirements & Constraints
1. **Build mdcode & Set Up Environment:**  
   Refer to the [Knowledge Catalog mdcode Official Guide](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/README.md) to clone the `knowledge-catalog` repository and build the `mdcode` library (`npm run build:libts`) so the `kcmd` CLI tool can be executed.
2. **Google Cloud ADC Authentication:**  
   Ensure Application Default Credentials (`gcloud auth application-default login`) are initialized for local Knowledge Catalog API access.
3. **Register `kc-mac` MCP Server:**  
   Register the `kc-mac` MCP server in the IDE configuration file (`~/.gemini/config/mcp_config.json`) under `mcpServers` (`kcmd mcp --path <MODULE3_DIRECTORY>`) and restart the IDE.
4. **Initialize & Pull Catalog Snapshot:**  
   Initialize and download the catalog snapshot for the `cymbal_gold` dataset:
   - Run in terminal: `kcmd init --bigquery-dataset <PROJECT_ID>.cymbal_gold --pull`
   - (Or prompt the agent: *"Use the kc-mac MCP tool to pull metadata for the cymbal_gold dataset into the local catalog snapshot."*)  
   Verify that local metadata files (`pos_anomaly_alerts.md`, etc.) are generated under `catalog/<PROJECT_ID>.cymbal_gold/`, containing table descriptions, column descriptions, and the bound `table-operational-spec` Aspect configured in Part 1.

#### 💡 Hints & Clues
- `kcmd` runs via `src/tool/main.ts` after building `knowledge-catalog/toolbox/mdcode` (`npm run build:libts`). Consider creating a wrapper script at `$HOME/.local/bin/kcmd` or adding it to your PATH for global invocation.
- When configuring the MCP server, specifying `kcmd mcp --path <MODULE3_DIRECTORY>` allows the agent to inspect table entries via `list-entries` and retrieve specific table schemas and Aspects via `lookup-entry`.

---

### Optional Challenge 3: Grounded NL2SQL with Local Catalog Metadata (Before vs. After Benchmark)

#### 🎯 Objective
Re-run the exact query with the local catalog metadata context synchronized in Optional Challenge 2, and benchmark the resulting **hallucination removal, exact table routing, and metadata-grounded standard formula application**.

#### ⚙️ Lab Mission: ✅ [After] Grounded Query with Local Catalog Metadata
- **Query Prompt:**
  > *"Referencing the table metadata stored under catalog/, calculate the cashier promo override rate for store STORE_048 today"*

#### 🔍 Verification of Improvements (Before vs. After)
Compare against the ungrounded attempt from Optional Challenge 1 and verify the following improvements:
1. **Accurate Table Routing:** Does the agent consult the table metadata stored under `catalog/` to inspect the `pos_anomaly_alerts` table description (`Primary table for ... override rate calculations`) and select the correct table?
2. **Standard Formula Application:** Is the exact standard formula `SAFE_DIVIDE(COUNTIF(alert_type = 'cashier_promo_abuse'), COUNT(*))` (or multiplied by 100.0 for percentage) accurately applied in the query?

##### 🎯 OKF Benchmark Validation Key (Before vs. After Expected Answers)
| Benchmark Metric | ❌ Before (Ungrounded NL2SQL / Challenge 1) | ✅ After (OKF Local Metadata Grounded / Challenge 3) |
| :--- | :--- | :--- |
| **Target Table** | `pos_transactions_gold` (Hallucinated checkout table without anomaly metrics) | **`pos_anomaly_alerts`** (Accurately identified via Catalog Table Description) |
| **Calculation Formula** | Hallucinated formula (`SUM(discount)/SUM(total)` or fabricated logic) | **`SAFE_DIVIDE(COUNTIF(alert_type = 'cashier_promo_abuse'), COUNT(*))`** |
| **Verified GoogleSQL** | Irrelevant transaction aggregation query | `SELECT store_id, ROUND(SAFE_DIVIDE(COUNTIF(alert_type = 'cashier_promo_abuse'), COUNT(*)) * 100.0, 2) AS cashier_promo_override_rate_pct FROM \`<PROJECT_ID>.cymbal_gold.pos_anomaly_alerts\` WHERE store_id = 'STORE_048' AND DATE(alert_ts) = CURRENT_DATE() GROUP BY store_id;` |

---

### 💡 [Architectural Insight] OKF Enterprise Value: Heterogeneous Catalog Migration
> [!NOTE]
> **Google Cloud Engineer Best Practice (Enterprise Catalog Consolidation):**  
> In this hands-on exercise, you experienced the **Export (pull) workflow** by extracting metadata from Knowledge Catalog into local OKF files to ground your IDE coding agent.
> However, in enterprise architecture and Google Cloud engagements, the primary strategic value of **OKF and Metadata as Code (MaC)** is to accelerate enterprise-scale migration and consolidate fragmented data catalogs into Google Cloud.
>  
> Enterprise customers typically possess metadata trapped in legacy or external catalogs such as **Collibra, Alation, Apache Atlas, or AWS Glue Data Catalog**.
> The Google Cloud best practice is to extract these diverse assets into standardized OKF files and leverage kcmd push to seamlessly migrate and centralize all enterprise metadata within Knowledge Catalog.
> This migration approach empowers enterprises to break down legacy metadata silos, establishing Knowledge Catalog as the unified, single source of truth for data governance across the organization.

---

### 🔍 Optional Lab Acceptance Criteria
- [ ] **Data Agent Kit (DAK):** BigQuery dataset inventory and table partition keys explored interactively via IDE chat?
- [ ] **Ungrounded NL2SQL (Before):** Baseline query executed and limitations (hallucinations/wrong table routing) observed without metadata context?
- [ ] **Metadata as Code (MaC):** `kcmd` built and `kc-mac` MCP server configured in IDE?
- [ ] **Catalog Snapshot Sync:** `cymbal_gold` table metadata (descriptions, schemas, and Aspects) successfully pulled into local `catalog/` directory?
- [ ] **Grounded NL2SQL (After):** Verified query generates accurate GoogleSQL using catalog metadata and standard formula?
