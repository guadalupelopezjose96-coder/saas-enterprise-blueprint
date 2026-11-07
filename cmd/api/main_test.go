package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleCreateTransaction_MissingSecurityHeaders(t *testing.T) {
	srv := &Server{db: nil}

	body := bytes.NewBufferString(`{"operation_type":"SUBSCRIPTION","amount_cents":10000,"currency":"USD"}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/transactions", body)
	rec := httptest.NewRecorder()

	srv.handleCreateTransaction(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("Control INT-01 fallido: se esperaba HTTP 400 ante ausencia de X-Tenant-ID / Idempotency-Key, se obtuvo %d", rec.Code)
	}
}

func TestHandleCreateTransaction_MethodNotAllowed(t *testing.T) {
	srv := &Server{db: nil}

	req := httptest.NewRequest(http.MethodGet, "/v1/transactions", nil)
	rec := httptest.NewRecorder()

	srv.handleCreateTransaction(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("Se esperaba HTTP 405 para método GET, se obtuvo %d", rec.Code)
	}
}

func TestUUIDRegexValidation(t *testing.T) {
	validTenant := "11111111-2222-3333-4444-555555555555"
	sqlInjectionAttempt := "11111111-2222-3333-4444-555555555555'; DROP TABLE core.tenants;--"

	if !uuidRegex.MatchString(validTenant) {
		t.Fatalf("Fallo al validar un UUID legítimo: %s", validTenant)
	}
	if uuidRegex.MatchString(sqlInjectionAttempt) {
		t.Fatalf("Vulnerabilidad crítica: el validador UUID permitió una cadena de inyección SQL")
	}
}
