# Governance Pack for Marketing Automation with AI & Agents system
Session 01 - Architecture Views, Steps and Process
## Context
*<sub>This fictional setting is inspired by the as-is architecture and it's described function in the lecture</sub>*

### 01. Company Background
Namaa Market, a fictional Saudi e-commerce retailer selling consumer goods via website and app, currently operates on a generic, manual marketing model that presents identical homepage offers to all shoppers and sends untargeted promotional campaigns via WhatsApp and app notifications. Although the company collects rich data, including product information, customer profiles, shopping activity, and cart history. it does not yet leverage these insights to personalize offers or optimize communication timing.

### 02. Business Goals
1. Replace static homepage offers with offers personalized by customer or segment
2. Respond to abandoned carts and customers at risk of churn
3. Serve useful offers to new users despite limited history
4. Improve customer satisfaction

## Scope & KPIs
### 01. Scope
1. Homepage personalization
2. Next-based action
    - Abandoned cart
    - Potential churn
3. Cold start (new user)

### 02. Out-od-scope
1. Reducng Refunds 
2. Acquiring customers through new sales channels

### KPIs
1. Raise CSAT by 6%

## Architecture Principles and Business Constraints
| Business Constraints | Principle | Prespective |
| :--- | :--- | :--- |
| PDPL compliance reguations for Saudi-based companies | All data stays in-country (KSA), on disk and in transit. | Regulation |
| Data retention follows PDPL compliance reguations for Saudi-based companies | Zero-Data-Retention policy for LLM providers used in campaign personalization actions |Regulation |
| Transparency and consent rules | An opt-out removes the customer from campaign audiences and from the feature store, not just from the WhatsApp list. |Regulation |
| CSAT KPI requirement| Every action the user takes based on the recommendation we send a customer must be traceable to the data and rule that produced it|Performance |
| NCA protocols | Internal services sit behind the VPN, external ones use HTTPS with authentication.| Security |
| Transparency and Reliability | AI recomendation is linked to it's traces throughout the workflow and is attributable | Explainability |

# Architecture Review Board (ARB) Checklist

| Area | Check (yes / no / N/A + evidence link) |
| :--- | :--- |
| **Security** | Threat model complete, including prompt injection for the Offer Generation Agent?<br>Least-privilege IAM roles enforced for Airflow, Flink, and the E-commerce service?<br>Secrets (Kafka credentials, DB passwords, LLM API keys) secured in a vault?<br>mTLS configured internally between Kafka, Flink, Feast, and databases? |
| **Privacy (PDPL)** | Data classified (PII vs. operational)?<br>Consent validated before campaign targeting?<br>Zero PII included in LLM prompts (for offer generation) or LLM logs?<br>Data residency physically confined to KSA (in-transit and on-disk) for all components?<br>Distributed RTBF/Opt-out successfully propagated across Kafka, Flink, and Feast within SLA? |
| **Evals** | Offline metrics established for the recommendation ranker?<br>A/B test design configured for offer uplift?<br>LLM copy evaluated (LLM-as-judge + human sample) for Arabic tone, accuracy, and brand safety?<br>Regression set passed before each Airflow DAG or ML model release? |
| **Cost** | Token cost per campaign (for LLM offer generation) estimated?<br>GPU utilization target tracked (for churn and segmentation models)?<br>Budget alerts configured for LLM inference and hosting resources?<br>Cost per incremental sale tracked and tied to the CSAT/Tracing mechanism? |
| **Human Oversight** | Approval gate configured before LLM-generated campaigns reach WhatsApp or the Web?<br>Kill switch implemented per campaign and per agent?<br>Clear owner defined for the Recommendation Engine?<br>Audit log of all manual approvals maintained and queryable? |
| **Operability** | Dashboards and alerts defined (Kafka lag, Flink latency, API error rates, Feature Store freshness)?<br>Rollback path defined for models (via MLflow) and LLM prompts?<br>Runbook exists for trace/provenance failures and data synchronization issues? |
