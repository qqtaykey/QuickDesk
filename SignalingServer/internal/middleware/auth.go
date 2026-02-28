package middleware

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"quickdesk/signaling/internal/config"
)

type AdminAuth struct {
	config *config.AdminConfig
	mu     sync.RWMutex
	tokens map[string]time.Time // token -> expiry
}

const tokenTTL = 24 * time.Hour

func NewAdminAuth(cfg *config.AdminConfig) *AdminAuth {
	a := &AdminAuth{
		config: cfg,
		tokens: make(map[string]time.Time),
	}
	go a.cleanupLoop()
	return a
}

func (a *AdminAuth) Login(c *gin.Context) {
	var req struct {
		User     string `json:"user" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	if req.User != a.config.User || req.Password != a.config.Password {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	token := generateToken()
	a.mu.Lock()
	a.tokens[token] = time.Now().Add(tokenTTL)
	a.mu.Unlock()

	c.JSON(http.StatusOK, gin.H{"token": token})
}

// AuthRequired is a Gin middleware that verifies the admin token.
func (a *AdminAuth) AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := ""
		auth := c.GetHeader("Authorization")
		if strings.HasPrefix(auth, "Bearer ") {
			token = strings.TrimPrefix(auth, "Bearer ")
		}
		if token == "" {
			token = c.Query("token")
		}

		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}

		a.mu.RLock()
		expiry, ok := a.tokens[token]
		a.mu.RUnlock()

		if !ok || time.Now().After(expiry) {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token expired"})
			return
		}

		c.Next()
	}
}

func (a *AdminAuth) cleanupLoop() {
	ticker := time.NewTicker(time.Hour)
	defer ticker.Stop()
	for range ticker.C {
		a.mu.Lock()
		now := time.Now()
		for t, exp := range a.tokens {
			if now.After(exp) {
				delete(a.tokens, t)
			}
		}
		a.mu.Unlock()
	}
}

func generateToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}
