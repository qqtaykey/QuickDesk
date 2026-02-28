package service

import (
	"quickdesk/signaling/internal/models"
	"quickdesk/signaling/internal/repository"
)

type PresetService struct {
	repo *repository.PresetRepository
}

func NewPresetService(repo *repository.PresetRepository) *PresetService {
	return &PresetService{repo: repo}
}

func (s *PresetService) GetPreset() (*models.Preset, error) {
	return s.repo.GetPreset()
}

func (s *PresetService) UpsertPreset(preset *models.Preset) error {
	return s.repo.UpsertPreset(preset)
}
