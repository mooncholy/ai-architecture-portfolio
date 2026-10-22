# 1. Tracing Implementaton Strategy

Date: 2026-10-22

## Status

Proposed

## Context

The system is transitioning from a synchronous, direct-request architecture to a complex, highly distributed, event-driven ecosystem. The new architecture introduces asynchronous processing (Kafka Event Backbone), stream processing (Debezium CDC, Flink), orchestration (Airflow), and ML infrastructure (Feature Store, Recommendation Engine, Churn Models).

A critical requirement is that AI recommendations must be strictly attributable. When an "Abandoned cart -> Next Best Action (NBA)" or a personalized campaign offer is triggered, we must be able to trace this decision back through the Recommendation Engine, identify the exact features used from the Feast Feature Store, and link it to the originating domain events in Kafka. The tracing mechanism must handle asynchronous event boundaries and provide clear lineage for ML decisions.


## Considered options

**Option 1: Log Aggregation with Distributed Correlation IDs**
- Description: Manually generate a unique Correlation-ID at the API Gateway or CDC level and pass it through Kafka headers, REST payloads, and ML inferences. All services log this ID to a centralized store.
- Tools: ELK Stack (Elasticsearch, Logstash, Kibana), Splunk, fluentd.

**Option 2: Traditional Distributed Tracing (APM)**
- Description: Implement standard distributed tracing to record spans for every service hop. Propagate W3C Trace Context across HTTP headers and Kafka message headers to stitch together the asynchronous flow.
- Tools: Jaeger, Zipkin, Apache SkyWalking.

**Option 3: OpenTelemetry (OTel) + ML Observability Integration**
- Description: Standardize on OpenTelemetry for universal instrumentation across microservices, Flink jobs, and the Recommendation Engine. Append custom ML-specific metadata (e.g., model_version, feast_feature_vector_id, decision_reason) as attributes to the OTel spans. Route traces to an APM backend.
- Tools: OpenTelemetry (Instrumentation/Collector), Datadog/Honeycomb (Trace Backend), Arize AI / MLflow (for dedicated ML model observability linked via trace IDs).

## Trade-offs


| Option | Pros | Cons |
| :--- | :--- | :--- |
| **1. Log Aggregation** | Easiest to implement; familiar to most teams; good for text-heavy debugging. | Lacks visual waterfall views; very difficult to track latency across asynchronous Kafka/Flink hops; does not map relationships well. |
| **2. Traditional APM** | Excellent visual representation of system bottlenecks; native support for HTTP/RPC. | Can struggle with long-running Flink stream jobs; spans are heavily focused on performance latency rather than data payload/attributability. |
| **3. OTel + Custom ML Attributes** | Vendor-agnostic; officially supports asynchronous messaging (Kafka); allows embedding AI explainability data directly into the trace context. | Highest initial setup complexity; requires custom instrumentation for Flink and the Feature Store to ensure AI metadata is attached to spans. |

## Decision

**Proceed with Option 3: OpenTelemetry (OTel) + Custom ML Attributes.**

To achieve true attributability for the AI Recommendation Engine, we must use OpenTelemetry to propagate a unified Trace Context. 
*   **Ingestion:** The trace starts at the API gateway or when Debezium writes a CDC event to Kafka.
*   **Propagation:** The Trace ID is passed via Kafka headers into Flink and the Recommendation Engine. 
*   **Attribution Payload:** When the Recommendation Engine generates an NBA, it will attach specific span attributes (e.g., `ml.model.id`, `ml.feast.snapshot`, `ml.decision.confidence`) to the active span. 
*   **Backend:** Use a compatible backend (like Jaeger for open-source, or Datadog for enterprise) to visualize the entire asynchronous flow from cart abandonment to WhatsApp/Channel notification.

## Consequences

*   **Positive:** Complete visibility into *why* an AI recommendation was made, tracing back to the exact user interaction and feature set. Easier debugging of dropped events in the Kafka/Flink pipeline.
*   **Negative:** Increased development overhead to instrument Kafka producers/consumers, Flink tasks, and ML inference code. 
*   **Operational:** High volume of trace data will require implementing a **Trace Sampling Strategy** (e.g., tail-based sampling) to keep storage costs manageable while ensuring anomalous or specific AI decisions are always captured.

## Revisit when

*   Trace data storage costs exceed the observability budget, necessitating a shift from head-based sampling to intelligent tail-based sampling.
*   The data science team requires deeper model drift and data quality tracking, which might require branching the trace data into a specialized MLOps platform (like Arize or Fiddler) in addition to the standard APM tool.
*   Flink processing latency is noticeably impacted by the tracing instrumentation overhead.