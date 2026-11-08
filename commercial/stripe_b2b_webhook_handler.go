package commercial

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// VerifyStripeWebhookSignature valida matematicamente la firma HMAC-SHA256 y previene ataques Replay (300s)
func VerifyStripeWebhookSignature(payload []byte, sigHeader string, webhookSecret string, now time.Time) error {
	if payload == nil || sigHeader == "" || webhookSecret == "" {
		return errors.New("parametros de verificacion HMAC incompletos")
	}

	var timestampStr, signatureHex string
	for _, part := range strings.Split(sigHeader, ",") {
		kv := strings.SplitN(strings.TrimSpace(part), "=", 2)
		if len(kv) != 2 {
			continue
		}
		switch kv[0] {
		case "t":
			timestampStr = kv[1]
		case "v1":
			signatureHex = kv[1]
		}
	}

	ts, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		return errors.New("timestamp de firma invalido")
	}

	if now.Unix()-ts > 300 || ts-now.Unix() > 300 {
		return errors.New("violacion anti-replay PAY-01: webhook fuera de la ventana de 300 segundos")
	}

	mac := hmac.New(sha256.New, []byte(webhookSecret))
	signedPayload := fmt.Sprintf("%d.%s", ts, string(payload))
	mac.Write([]byte(signedPayload))
	expectedMAC := mac.Sum(nil)

	providedMAC, err := hex.DecodeString(signatureHex)
	if err != nil || !hmac.Equal(expectedMAC, providedMAC) {
		return errors.New("violacion criptografica PAY-01: firma HMAC-SHA256 invalida")
	}

	return nil
}
