package saas.ai.nist_rmf_guard

# Control LLM-01 (OWASP LLM01 & NIST AI RMF 1.0): Bloquear Prompt Injection, Jailbreak y fuga cross-tenant
default allow_inference = false

forbidden_patterns := [
    "ignore previous instructions",
    "system prompt",
    "drop table",
    "169.254.169.254",
    "bypass row level security"
]

allow_inference {
    input.tenant_id != ""
    input.pii_redacted == true
    not contains_malicious_prompt(lower(input.user_prompt))
}

contains_malicious_prompt(prompt) {
    pattern := forbidden_patterns[_]
    contains(prompt, pattern)
}
