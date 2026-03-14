const API_BASE = '/api/v1'

function getAuthHeaders() {
  return {
    'Authorization': `Bearer ${localStorage.getItem('quickdesk_token')}`,
    'Content-Type': 'application/json'
  }
}

export async function getUserDevices() {
  const response = await fetch(`${API_BASE}/user/devices`, {
    headers: getAuthHeaders()
  })
  return response.json()
}

export async function unbindDevice(data) {
  const response = await fetch(`${API_BASE}/user/devices/unbind`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(data)
  })
  return response.json()
}

export async function quickConnectBind(data) {
  const response = await fetch(`${API_BASE}/user/devices/quick-connect`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(data)
  })
  return response.json()
}

export async function getDeviceLogs() {
  const response = await fetch(`${API_BASE}/user/devices/logs`, {
    headers: getAuthHeaders()
  })
  return response.json()
}
