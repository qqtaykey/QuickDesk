import { authFetch } from './auth.js'

const BASE_URL = '/api/v1/admin'

export async function getDevices() {
  const res = await authFetch(`${BASE_URL}/devices`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}

export async function getDeviceStatus(deviceId) {
  const res = await authFetch(`/api/v1/devices/${deviceId}/status`)
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res.json()
}
