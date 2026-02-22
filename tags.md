# tags.md

## Conventions
- Local tag style: kebab-case (lowercase, hyphens).
- Always include exactly ONE umbrella tag: `security`.
- Typical per-post tags (local): 3–6.
- When syndicating to Hashnode: cap at 5 tags (platform limit).
- Hashnode column: leave blank until you confirm via Hashnode tag autocomplete.

## Tag map
| Local tag             | Purpose / when to use                                               | Hashnode tag slug | Notes                               |
| --------------------- | ------------------------------------------------------------------- | ----------------- | ----------------------------------- |
| security              | Umbrella tag for all security-ish posts                             |                   | Always include                      |
| security-architecture | Architecture decisions, patterns, tradeoffs                         |                   |                                     |
| threat-modeling       | Threat models, abuse cases, design reviews                          |                   |                                     |
| appsec                | Application security, secure design/implementation                  |                   |                                     |
| secure-coding         | Secure coding patterns, guardrails, code review patterns            |                   |                                     |
| devsecops             | CI/CD security, policy-as-code, pipeline guardrails                 |                   |                                     |
| supply-chain          | Dependencies, SBOM, provenance, build integrity                     |                   |                                     |
| secrets-management    | Secrets handling, rotation, vaulting, CI secrets                    |                   |                                     |
| cloud-security        | Cloud posture, guardrails, identity, telemetry                      |                   |                                     |
| iam                   | Identity and access management (general)                            |                   |                                     |
| microsoft-entra       | Entra-specific identity topics                                      |                   | Use with `iam` when relevant        |
| github                | GitHub platform topics                                              |                   |                                     |
| github-actions        | Workflows, CI/CD automation, security patterns                      |                   |                                     |
| gcp                   | Google Cloud Platform specifics                                     |                   |                                     |
| microsoft-365         | M365 platform topics                                                |                   |                                     |
| microsoft-defender    | Defender/XDR topics                                                 |                   |                                     |
| microsoft-sentinel    | Sentinel/SIEM topics                                                |                   |                                     |
| kql                   | Kusto Query Language queries, tips, pitfalls                        |                   | Often paired with Sentinel/Defender |
| siem                  | SIEM concepts, pipelines, content engineering                       |                   |                                     |
| soar                  | Automation/orchestration (playbooks, workflows)                     |                   |                                     |
| edr                   | Endpoint detection and response                                     |                   |                                     |
| detection-engineering | Detection content engineering (rules/analytics, testing, lifecycle) |                   |                                     |
| threat-hunting        | Hunting methodology, hunts, hypotheses, outcomes                    |                   |                                     |
| incident-response     | IR process, playbooks, postmortems, containment/eradication         |                   |                                     |
| telemetry             | Logging, collection, normalization, schemas                         |                   |                                     |
| ai                    | General AI topics                                                   |                   |                                     |
| ai-agents             | Agentic systems, tool-use, orchestration                            |                   |                                     |
| ai-security           | Security of AI/LLM/agentic systems                                  |                   |                                     |
| prompt-injection      | Prompt injection, indirect prompt injection, mitigations            |                   |                                     |
| rag-security          | Retrieval-augmented generation security (poisoning, leakage, etc.)  |                   |                                     |
| llm-evals             | Evaluations, red teaming, benchmarks, guardrail testing             |                   |                                     |
| secure-agent-patterns | Safe patterns for agent-assisted coding / tool use                  |                   |                                     |