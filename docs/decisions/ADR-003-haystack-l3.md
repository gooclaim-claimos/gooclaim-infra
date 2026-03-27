# ADR-003: Haystack + pgvector for L3 Knowledge Layer

**Date:** March 2026
**Status:** Accepted
**Deciders:** Team

---

## Context

L3 Knowledge Layer needs a RAG (Retrieval-Augmented Generation) engine to:
- Store and search policy documents, KB articles, query reason explanations
- Return relevant context to L1 for RW3 (query reason workflow)
- Support Hinglish content
- Meet IRDAI data residency requirements (India only)

## Decision

Use **Haystack** (self-hosted) as the RAG engine with **pgvector** as the vector store for Phase 1.

## Reasons

- Self-hosted = full control over data + IRDAI data residency compliance
- Haystack provides complete RAG pipeline with 8-stage ingestion (chunking, embedding, indexing)
- pgvector reuses existing PostgreSQL 16 — no new infra for Phase 1
- Langfuse (self-hosted, Mumbai) for LLM observability — satisfies IRDAI audit requirements
- Embeddings via Model Gateway only — central governance maintained

## Rejected Alternatives

| Option | Why rejected |
|--------|-------------|
| RAGFlow | Less mature, fewer integrations, IRDAI data residency unclear |
| LlamaIndex | Cloud-first, harder to self-host cleanly |
| Elasticsearch vector | Separate infra, extra cost, overkill for Phase 1 KB size |
| Pinecone / Weaviate cloud | Data residency violation — IRDAI requires India |

## 8-Stage Ingestion Pipeline

Every document entering L3 passes through all 8 stages:

| Stage | Name | What it does |
|-------|------|-------------|
| C0 | Source Auth | Verify document source is authorized |
| C1 | Duplicate check | Reject already-ingested documents |
| C1.5 | Format validation | PDF, DOCX, CSV — supported formats only |
| C2 | Malware scan | Quarantine suspicious files |
| C3 | Integrity check | Checksum validation |
| C4 | Semantic safety | Guardrails AI — shares container with L6 |
| C5 | PHI scrub | Strip PHI before indexing into vector store |
| Index | Haystack index | Chunk → embed → store in pgvector |

## Consequences

- pgvector sufficient for Phase 1 KB size — re-evaluate for Phase 2+ at scale
- Haystack pipeline must be configured for Hinglish chunking strategies
- All embedding calls must go through `ModelGatewayClient` — no direct Azure OAI
- Langfuse self-hosted in Mumbai — required for LLM call audit trail
- **C4 Semantic Safety Gate shares Guardrails AI container with L6** — coordinate deployments
