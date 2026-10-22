# 2. LLM hosting

Date: 2026-10-22

## Status

Proposed

## Context
The target marketing automation architecture (To-Be) incorporates LLMs for "AI for security and guardrails" and potentially enhances the Recommendation Engine and Churn detection models. 

A strict regulatory requirement mandates that **all data must stay in-country (KSA) on disk and in transit**. This severely restricts our ability to use global serverless LLM APIs where data routing and at-rest storage locations cannot be guaranteed. The marketing platform uses sensitive Customer Interactions and Profiles (PII) which cannot cross borders. 

Based on the landscape of LLM inference solutions (frameworks, serverless, and GPU hosting) and the strict data localization constraints, we must evaluate hosting mechanisms that natively support geographical fencing.

## Considered options

### Option 1: Global Serverless LLM APIs
* **Description:** Utilizing pay-per-token API endpoints hosted by specialized AI infrastructure companies. The models are fully managed, scaled automatically, and require zero infrastructure maintenance.
* **Tools:** together.ai, OpenRouter, Fireworks AI, Groq (as seen on llm-explorer.com).
* **Location Profile:** Multi-region global routing.

### Option 2: Hyperscaler GPU Cloud Services (KSA Regions)
* **Description:** Renting dedicated GPUs or utilizing Managed Machine Learning Platforms from major cloud providers that have recently opened physical data centers in the KSA region. We deploy open-weights models (e.g., Llama 3, Mistral) on these local nodes.
* **Tools:** Azure AI Machine Learning Studio (Saudi Arabia Central region), Google Vertex AI (Dammam region), AWS SageMaker (if KSA region available/planned). Utilizing inference frameworks like **vLLM** or **TGI (Text Generation Inference)** to serve the models.
* **Location Profile:** Guaranteed KSA (Cloud-based).

### Option 3: Self-Hosted on On-Premise / Local KSA Private Cloud
* **Description:** Procuring bare-metal GPU servers located in a physically controlled KSA data center (e.g., center3, stc, or on-premise racks) and running open-source inference engines. 
* **Tools:** High-performance LLM Inference Frameworks such as **vLLM**, **Ollama**, or **TensorRT-LLM**. 
* **Location Profile:** Guaranteed KSA (Air-gapped / Private Cloud).

## Trade-offs

| Option | Pros | Cons | Data Residency (KSA) |
| ----- | ----- | ----- | ----- |
| **1. Global Serverless APIs** | Lowest setup overhead; extremely cost-effective for variable traffic ("scale to zero"); access to cutting edge proprietary models. | Complete loss of geographic data control; risk of data logging in foreign jurisdictions. | **Fails Requirement** |
| **2. Hyperscaler KSA Regions** | Good balance of managed infrastructure and data compliance; easier integration with existing Kafka/Flink if they are hosted on the same cloud; scalable GPU compute. | Subject to GPU availability in the specific KSA region (can be constrained); requires setting up serving frameworks like vLLM. | **Meets Requirement** |
| **3. Self-Hosted / Local Bare-Metal** | Absolute control over data sovereignty; highest security (can be completely air-gapped); predictable flat-rate costs. | High CapEx for GPU acquisition; heavy operational burden to manage orchestration, cooling, networking, and inference scaling. | **Meets Requirement** |

## Decision

**Proceed with Option 2: Hyperscaler GPU Cloud Services (KSA Regions) using vLLM for inference.**

* **Rejection of Serverless:** Option 1 is immediately discarded due to the absolute constraint regarding KSA data residency. 
* **Model Choice:** We will utilize open-weights models (e.g., Llama-3-8B or Mistral) capable of being self-hosted. 
* **Infrastructure:** Deploy these models on dedicated GPU compute instances within a verified KSA cloud region (e.g., Microsoft Azure Saudi Arabia Central or Google Cloud Dammam). 
* **Inference Engine:** We will utilize **vLLM** (as highlighted on llm-explorer) deployed in a container to serve the model. vLLM's PagedAttention provides high-throughput serving, essential for scanning Kafka event streams for guardrails in near-real-time without astronomical hardware costs.
* **Network:** Traffic between the Kafka Event Backbone / Airflow orchestration and the LLM endpoint will route exclusively over private KSA cloud networks, ensuring in-transit compliance.

## Consequences

* **Positive:** Complete compliance with local KSA data sovereignty laws; no PII exposure to third-party global endpoints. 
* **Negative:** Higher idle costs compared to serverless pay-per-token models. Our MLOps team will have to manage model weights, container deployments, and vLLM configuration rather than just calling a simple API.
* **Operational:** We must implement strict identity and access management (IAM) within the cloud provider to ensure the storage buckets holding the LLM weights and the VMs running inference do not have outbound internet access that could leak data.

## Revisit when

* A major serverless LLM provider (like OpenAI or Anthropic) launches a dedicated, certified, and legally binding KSA-hosted Enterprise endpoint.
* Open-source models become too hardware-intensive for our rented cloud GPU instances, prompting a need to evaluate local bare-metal procurement (Option 3). 
* GPU scarcity in the hyperscaler KSA regions prevents us from scaling the Guardrails agent during peak traffic events (e.g., Black Friday campaigns).