package handler

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

// RegisterWebClientUI serves the QuickDesk WebClient static files from the filesystem.
// It probes several candidate paths relative to the working directory to locate
// the WebClient directory containing remote.html.  If the directory cannot be
// found the route still responds with a minimal placeholder HTML page so the
// server starts cleanly in environments that don't bundle the WebClient.
func RegisterWebClientUI(router *gin.Engine) {
	candidates := []string{
		"web/src/WebClient",
		"../web/src/WebClient",
		"../../web/src/WebClient",
		"WebClient",
	}

	var webClientPath string
	for _, p := range candidates {
		if _, err := os.Stat(filepath.Join(p, "remote.html")); err == nil {
			webClientPath = p
			break
		}
	}

	if webClientPath == "" {
		router.GET("/remote.html", func(c *gin.Context) {
			c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(`<!DOCTYPE html>
<html>
<head><title>QuickDesk Remote</title></head>
<body>
<h1>WebClient Not Found</h1>
<p>Please ensure WebClient files are available at web/src/WebClient.</p>
</body>
</html>`))
		})
		return
	}

	// HTML entry-point files
	htmlFiles := []string{"remote.html", "login.html", "register.html", "user-login.html", "index.html"}
	for _, file := range htmlFiles {
		filePath := filepath.Join(webClientPath, file)
		if _, err := os.Stat(filePath); err != nil {
			continue
		}
		routePath := "/" + file
		capturedPath := filePath // capture loop variable
		router.GET(routePath, func(c *gin.Context) {
			data, err := os.ReadFile(capturedPath)
			if err != nil {
				c.String(http.StatusInternalServerError, "Error reading file: "+err.Error())
				return
			}
			c.Data(http.StatusOK, "text/html; charset=utf-8", data)
		})
	}

	// Helper: serve files from a subdirectory with path-traversal prevention.
	serveSubdir := func(subdir string, defaultContentType string, contentTypeByExt map[string]string) gin.HandlerFunc {
		base := filepath.Clean(filepath.Join(webClientPath, subdir))
		return func(c *gin.Context) {
			rel := strings.TrimPrefix(c.Param("filepath"), "/")
			full := filepath.Clean(filepath.Join(base, rel))

			// Path traversal guard
			if !strings.HasPrefix(full, base) {
				c.String(http.StatusForbidden, "Access denied")
				return
			}

			data, err := os.ReadFile(full)
			if err != nil {
				c.String(http.StatusNotFound, "File not found: "+rel)
				return
			}

			ct := defaultContentType
			for ext, mime := range contentTypeByExt {
				if strings.HasSuffix(rel, ext) {
					ct = mime
					break
				}
			}
			c.Data(http.StatusOK, ct, data)
		}
	}

	router.GET("/js/*filepath", serveSubdir("js", "application/javascript", map[string]string{
		".css":  "text/css",
		".html": "text/html; charset=utf-8",
		".json": "application/json",
	}))

	router.GET("/images/*filepath", serveSubdir("images", "image/png", map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".gif":  "image/gif",
		".svg":  "image/svg+xml",
		".ico":  "image/x-icon",
	}))

	router.GET("/assets/*filepath", serveSubdir("assets", "application/octet-stream", map[string]string{
		".css": "text/css",
		".js":  "application/javascript",
	}))

	// favicon.ico
	router.GET("/favicon.ico", func(c *gin.Context) {
		data, err := os.ReadFile(filepath.Join(webClientPath, "favicon.ico"))
		if err != nil {
			c.String(http.StatusNotFound, "favicon.ico not found")
			return
		}
		c.Data(http.StatusOK, "image/x-icon", data)
	})
}
