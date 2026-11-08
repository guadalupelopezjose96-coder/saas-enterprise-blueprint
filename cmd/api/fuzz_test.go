package main

import (
	"strings"
	"testing"
)

// FuzzTenantUUIDValidation verifica que ningun payload arbitrario rompa el validador ni permita SQLi (ISO 8.29)
func FuzzTenantUUIDValidation(f *testing.F) {
	f.Add("11111111-2222-3333-4444-555555555555")
	f.Add("'; DROP TABLE core.ledger_transactions; --")
	f.Add("../../../../etc/passwd")
	f.Add("<script>alert(1)</script>")

	f.Fuzz(func(t *testing.T, candidate string) {
		matched := uuidRegex.MatchString(candidate)
		if matched && (strings.ContainsAny(candidate, "';\"\\<> ") || len(candidate) != 36) {
			t.Fatalf("Fallo critico de seguridad: regex acepto entrada maliciosa: %q", candidate)
		}
	})
}
