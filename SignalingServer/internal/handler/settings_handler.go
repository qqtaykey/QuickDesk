package handler

import (
	"net/http"
	"quickdesk/signaling/internal/models"
	"quickdesk/signaling/internal/service"

	"github.com/gin-gonic/gin"
)

type SettingsHandler struct {
	service *service.SettingsService
}

func NewSettingsHandler(service *service.SettingsService) *SettingsHandler {
	return &SettingsHandler{service: service}
}

// GetPublicSettings returns non-sensitive settings for public access.
func (h *SettingsHandler) GetPublicSettings(c *gin.Context) {
	s := h.service.Get()
	c.JSON(http.StatusOK, gin.H{
		"siteEnabled": s.SiteEnabled,
		"siteName":    s.SiteName,
		"loginLogo":   s.LoginLogo,
		"smallLogo":   s.SmallLogo,
		"favicon":     s.Favicon,
	})
}

// GetSettings returns all settings including sensitive ones (admin only).
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	s := h.service.Get()
	c.JSON(http.StatusOK, s)
}

// UpdateSettings saves settings and refreshes the in-memory cache.
func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	var settings models.Settings
	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.Save(&settings); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}
