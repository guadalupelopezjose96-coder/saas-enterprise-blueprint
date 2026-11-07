package main

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"regexp"
	"time"

	_ "github.com/lib/pq"
)

var uuidRegex = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

type Server struct {
	db *sql.DB
}

type TransactionRequest struct {
	OperationType string `json:"operation_type"`
	AmountCents   int64  `json:"amount_cents"`
	Currency      string `json:"currency"`
	Payload       string `json:"payload"`
	UserID        string `json:"user_id"`
}

type TransactionResponse struct {
	TransactionID  string    `json:"transaction_id"`
	TenantID       string    `json:"tenant_id"`
	IdempotencyKey string    `json:"idempotency_key"`
	Status         string    `json:"status"`
	ProcessedAtUTC time.Time `json:"processed_at_utc"`
}

// executeInTenantTx abre una transacción atómica e inyecta el tenant_id en la sesión PostgreSQL
// forzando el cumplimiento de Row-Level Security (Control TEN-01 / ISO 8.3).
func (s *Server) executeInTenantTx(ctx context.Context, tenantID string, fn func(*sql.Tx) error) error {
	if !uuidRegex.MatchString(tenantID) {
		return errors.New("formato de tenant_id inválido")
	}

	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, "SELECT set_config('app.current_tenant_id', $1, true)", tenantID); err != nil {
		return err
	}

	if err := fn(tx); err != nil {
		return err
	}

	return tx.Commit()
}

func (s *Server) handleCreateTransaction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	tenantID := r.Header.Get("X-Tenant-ID")
	idempotencyKey := r.Header.Get("Idempotency-Key")
	if tenantID == "" || idempotencyKey == "" {
		http.Error(w, "Cabeceras X-Tenant-ID e Idempotency-Key son obligatorias (Control INT-01)", http.StatusBadRequest)
		return
	}

	var req TransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "JSON malformado", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	var txID string
	err := s.executeInTenantTx(ctx, tenantID, func(tx *sql.Tx) error {
		payloadHash := sha256.Sum256([]byte(req.Payload))

		query := `
			INSERT INTO core.ledger_transactions 
				(tenant_id, idempotency_key, operation_type, amount_cents, currency, encrypted_payload, created_by_user_id)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (tenant_id, idempotency_key) 
			DO UPDATE SET operation_type = EXCLUDED.operation_type
			RETURNING transaction_id`

		err := tx.QueryRowContext(
			ctx, query,
			tenantID, idempotencyKey, req.OperationType, req.AmountCents, req.Currency, payloadHash[:], req.UserID,
		).Scan(&txID)
		if err != nil {
			return err
		}

		// Patrón Transactional Outbox en la misma transacción atómica
		outboxPayload, _ := json.Marshal(map[string]interface{}{
			"transaction_id": txID,
			"amount_cents":   req.AmountCents,
			"currency":       req.Currency,
			"sha256_digest":  hex.EncodeToString(payloadHash[:]),
		})

		outboxQuery := `
			INSERT INTO core.transactional_outbox (tenant_id, aggregate_type, aggregate_id, event_type, payload)
			VALUES ($1, 'LEDGER_TRANSACTION', $2, 'TRANSACTION_RECORDED', $3)`
		_, err = tx.ExecContext(ctx, outboxQuery, tenantID, txID, outboxPayload)
		return err
	})

	if err != nil {
		http.Error(w, "Error procesando transacción aislada por RLS: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(TransactionResponse{
		TransactionID:  txID,
		TenantID:       tenantID,
		IdempotencyKey: idempotencyKey,
		Status:         "COMMITTED_WITH_RLS_AND_OUTBOX",
		ProcessedAtUTC: time.Now().UTC(),
	})
}

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://saas_app_runtime:CHANGE_VIA_VAULT_DYNAMIC_SECRET_ROTATION@localhost:5432/saas_prod?sslmode=require"
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Fallo al inicializar conexión PostgreSQL: %v", err)
	}
	db.SetMaxOpenConns(50)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(30 * time.Minute)

	srv := &Server{db: db}
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/transactions", srv.handleCreateTransaction)

	httpServer := &http.Server{
		Addr:              ":8443",
		Handler:           mux,
		ReadHeaderTimeout: 3 * time.Second,
		ReadTimeout:       5 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Println("Servidor SaaS Multi-Tenant iniciado en :8443 con aislamiento RLS estricto")
	log.Fatal(httpServer.ListenAndServe())
}
