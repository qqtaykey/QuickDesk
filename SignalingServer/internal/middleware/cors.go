package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// CORSMiddleware returns a Gin middleware that sets CORS headers for
// requests whose Origin is in the allowed list.  If allowedOrigins is
// empty, CORS headers are not added (same-origin only).
func CORSMiddleware(allowedOrigins []string) gin.HandlerFunc {
	origins := make(map[string]bool, len(allowedOrigins))
	for _, o := range allowedOrigins {
		origins[strings.TrimRight(strings.ToLower(o), "/")] = true
	}

	return func(c *gin.Context) {
		origin := strings.TrimRight(strings.ToLower(c.GetHeader("Origin")), "/")
		if origin == "" || len(origins) == 0 {
			c.Next()
			return
		}

		if !origins[origin] {
			c.Next()
			return
		}

		c.Header("Access-Control-Allow-Origin", c.GetHeader("Origin"))
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "X-API-Key, Content-Type")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
