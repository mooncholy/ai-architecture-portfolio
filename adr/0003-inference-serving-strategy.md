# 3. Inference Serving Strategy

Date: 2026-10-22

## Status

Proposed

## Context

The business objective is to **replace static homepage offers with offers personalized by customer or segment**. 

In the As-Is architecture, the E-commerce Service simply queries a static "Products" or "Campaigns" database to render homepage banners. This is fast but generic. In the To-Be architecture, the E-commerce Service must interface with a new "Recommendation Engine" to fetch dynamically ranked offers (Next Best Action - NBA). 

Because the homepage is the highest-traffic entry point for the platform, the architecture must guarantee ultra-low latency (typically < 100ms) so as not to degrade the user experience or negatively impact SEO, while simultaneously leveraging complex ML models (RFM, CLV, Segmentation) to deliver the right offer. We must evaluate how to serve these inferences efficiently.

## Considered options

### Option 1: Pre-computed Batch Inference (Lookup Table)

* **Description:** Airflow orchestrates a nightly or hourly DAG that runs the Recommendation Engine over the entire customer base. The engine pre-calculates the top 5 homepage offers for every `User_ID` and writes them to a fast key-value store. The E-commerce Service simply performs an $O(1)$ lookup by `User_ID` when the homepage loads.
* **Tools:** Airflow (Batch orchestration), Spark/Databricks (Batch scoring), Redis (Key-Value store).

### Option 2: Real-Time Online Inference (Synchronous API)

* **Description:** The E-commerce Service makes a synchronous API call to the Recommendation Engine at the exact moment the homepage loads. The Engine instantly queries the Feast Online Store for real-time customer features, runs the model inference on-the-fly, ranks the offers, and returns the personalized payload.
* **Tools:** FastAPI / Seldon Core / KServe (Model serving), Feast (Online feature store), Redis (as Feast backend).

### Option 3: Event-Triggered Near-Real-Time Caching (Stream Processing)

* **Description:** A hybrid approach. Flink monitors the Kafka Event Backbone for significant user actions (e.g., login, added to cart). When an event occurs, Flink triggers the Recommendation Engine to recalculate the offers for that specific user and updates a Redis cache. The E-commerce Service reads from this cache, which is always fresh up to the last user interaction.
* **Tools:** Flink (Stream processing), Kafka, Redis (Cache).


## Trade-offs

| Option | Pros | Cons | Recommendation Freshness | Latency at Request Time |
| ----- | ----- | ----- | ----- | ----- |
| **1. Pre-computed Batch** | Fastest possible response time; lowest infrastructure cost during peak traffic. | Cannot react to in-session behavior; cold-start problem for new or anonymous users. | Stale (Hours/Days) | **Ultra-Low (< 10ms)** |
| **2. Real-Time Online Inference** | Highly personalized; reacts to current session context; simplifies ML pipeline (no massive batch jobs). | Highest latency risk; requires expensive auto-scaling ML infrastructure to handle traffic spikes. | **Real-time (Seconds)** | Medium/High (50ms - 200ms+) |
| **3. Event-Triggered Caching** | Balances low latency reads with near-real-time context; highly efficient use of compute. | Most complex architecture; requires stateful stream processing and cache invalidation logic. | Near-Real-Time (Minutes) | **Ultra-Low (< 10ms)** |

## Decision

**Proceed with Option 2: Real-Time Online Inference (Synchronous API) with a Semantic Fallback.**

To truly leverage the To-Be architecture's investment in the Feature Store (Feast) and real-time Kafka events, we need the Recommendation Engine to be dynamic. 

* **Execution:** When a user hits the homepage, the E-commerce Service calls the Recommendation Engine.
* **Feature Retrieval:** The Engine pulls the latest vector from the Feast Online Store, which is continuously updated by the Kafka/Flink pipelines (e.g., containing data about a cart abandonment that happened 5 minutes ago).
* **Fallback Mechanism:** To protect homepage load times, the API call from the E-commerce Service must have a strict timeout (e.g., $t_{max} = 150ms$). If the Recommendation Engine fails to respond in time, the E-commerce Service falls back to a cached, segment-level or generic top-selling offer.

## Consequences

* **Positive:** The marketing team can define highly dynamic, context-aware campaigns. The homepage will reflect the user's immediate intent, significantly boosting conversion rates.
* **Negative:** The Recommendation Engine becomes a Tier-1 critical service. If it experiences high latency, it risks degrading the entire shopping experience unless the fallback circuit breakers are perfectly tuned.
* **Operational:** DevOps must implement aggressive auto-scaling for the Recommendation Engine pods to handle sudden traffic spikes (e.g., flash sales), and the Feast online store must be provisioned with high IOPS to handle simultaneous feature retrievals.

## Revisit when

* The API timeout fallback is triggered for more than 5% of homepage visits, indicating that real-time inference is too slow for the current infrastructure. At this point, we should pivot to Option 3 (Event-Triggered Caching).
* We need to start personalizing the homepage for anonymous, unauthenticated users based on in-session clickstream data, which will require real-time edge processing rather than server-side inference.