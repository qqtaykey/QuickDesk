use rmcp::handler::server::tool::ToolRouter;
use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::{
    Annotated, ErrorData, Implementation, ListResourceTemplatesResult, ListResourcesResult,
    PaginatedRequestParams, RawResource, RawResourceTemplate, ReadResourceRequestParams,
    ReadResourceResult, ResourceContents, ServerCapabilities, ServerInfo,
};
use rmcp::service::{RequestContext, RoleServer};
use rmcp::{tool, tool_handler, tool_router, ServerHandler};
use schemars::JsonSchema;
use serde::Deserialize;
use serde_json::json;

use crate::ws_client::WsClient;

fn make_resource(uri: &str, name: &str, description: &str) -> Annotated<RawResource> {
    Annotated {
        raw: RawResource {
            uri: uri.to_string(),
            name: name.to_string(),
            title: None,
            description: Some(description.to_string()),
            mime_type: Some("application/json".to_string()),
            size: None,
            icons: None,
            meta: None,
        },
        annotations: None,
    }
}

// ---- Parameter structs ----

#[derive(Deserialize, JsonSchema)]
struct ConnectionIdParam {
    /// Connection ID
    connection_id: String,
}

#[derive(Deserialize, JsonSchema)]
struct ConnectDeviceParam {
    /// 9-digit device ID of the remote host
    device_id: String,
    /// Access code of the remote host
    access_code: String,
    /// Signaling server URL (optional, uses default if empty)
    server_url: Option<String>,
    /// Whether to show the remote desktop viewer window in QuickDesk UI. Defaults to true so the user can observe AI operations. Set to false for background/batch automation.
    show_window: Option<bool>,
}

#[derive(Deserialize, JsonSchema)]
struct ScreenshotParam {
    /// Connection ID
    connection_id: String,
    /// Maximum width of the screenshot in pixels. Image will be scaled down proportionally if wider than this value. Use this to reduce data transfer size.
    max_width: Option<i32>,
    /// Image format: "jpeg" (default) or "png"
    format: Option<String>,
    /// JPEG quality 1-100 (default: 80)
    quality: Option<i32>,
}

#[derive(Deserialize, JsonSchema)]
struct MouseClickParam {
    /// Connection ID
    connection_id: String,
    /// X coordinate
    x: f64,
    /// Y coordinate
    y: f64,
    /// Mouse button: "left", "right", or "middle". Defaults to "left".
    button: Option<String>,
}

#[derive(Deserialize, JsonSchema)]
struct MousePositionParam {
    /// Connection ID
    connection_id: String,
    /// X coordinate
    x: f64,
    /// Y coordinate
    y: f64,
}

#[derive(Deserialize, JsonSchema)]
struct MouseScrollParam {
    /// Connection ID
    connection_id: String,
    /// X coordinate
    x: f64,
    /// Y coordinate
    y: f64,
    /// Horizontal scroll delta
    delta_x: Option<f64>,
    /// Vertical scroll delta (positive=up, negative=down)
    delta_y: Option<f64>,
}

#[derive(Deserialize, JsonSchema)]
struct KeyboardTypeParam {
    /// Connection ID
    connection_id: String,
    /// Text to type
    text: String,
}

#[derive(Deserialize, JsonSchema)]
struct KeyboardHotkeyParam {
    /// Connection ID
    connection_id: String,
    /// Key names to press together, e.g. ["ctrl","c"], ["win","r"], ["alt","f4"]
    keys: Vec<String>,
}

#[derive(Deserialize, JsonSchema)]
struct SetClipboardParam {
    /// Connection ID
    connection_id: String,
    /// Text to set in remote clipboard
    text: String,
}

// ---- MCP Server ----

#[derive(Clone)]
pub struct QuickDeskMcpServer {
    tool_router: ToolRouter<Self>,
    ws: WsClient,
}

impl QuickDeskMcpServer {
    pub fn new(ws: WsClient) -> Self {
        Self {
            tool_router: Self::tool_router(),
            ws,
        }
    }
}

#[tool_router]
impl QuickDeskMcpServer {
    #[tool(description = "Get local host device ID, access code, signaling state, and client count. Use this to get credentials for connecting to the current computer.")]
    async fn get_host_info(&self) -> String {
        match self.ws.request("getHostInfo", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "List clients currently connected to this host machine.")]
    async fn get_host_clients(&self) -> String {
        match self.ws.request("getHostClients", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get overall status including host process, client process, and signaling server state.")]
    async fn get_status(&self) -> String {
        match self.ws.request("getStatus", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get signaling server connection status for both host and client.")]
    async fn get_signaling_status(&self) -> String {
        match self.ws.request("getSignalingStatus", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Refresh the local host access code.")]
    async fn refresh_access_code(&self) -> String {
        match self.ws.request("refreshAccessCode", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "List all active remote desktop connections.")]
    async fn list_connections(&self) -> String {
        match self.ws.request("listConnections", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get detailed info for a specific remote connection.")]
    async fn get_connection_info(&self, params: Parameters<ConnectionIdParam>) -> String {
        match self
            .ws
            .request("getConnectionInfo", json!({ "connectionId": params.0.connection_id }))
            .await
        {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Connect to a remote device. Returns a connection ID. By default, a remote desktop viewer window is shown so the user can observe your operations. Set show_window=false for silent background automation. To control the current computer, first call get_host_info to get the device ID and access code, then pass them here.")]
    async fn connect_device(&self, params: Parameters<ConnectDeviceParam>) -> String {
        let p = params.0;
        let mut req = json!({
            "deviceId": p.device_id,
            "accessCode": p.access_code,
        });
        if let Some(url) = p.server_url {
            req["serverUrl"] = json!(url);
        }
        if let Some(show) = p.show_window {
            req["showWindow"] = json!(show);
        }
        match self.ws.request("connectToHost", req).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Disconnect from a remote device.")]
    async fn disconnect_device(&self, params: Parameters<ConnectionIdParam>) -> String {
        match self
            .ws
            .request("disconnectFromHost", json!({ "connectionId": params.0.connection_id }))
            .await
        {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Disconnect all remote connections.")]
    async fn disconnect_all(&self) -> String {
        match self.ws.request("disconnectAll", json!({})).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Capture a screenshot of the remote desktop. Returns base64 JPEG image data with width and height. Use max_width to reduce image size for faster transfer.")]
    async fn screenshot(&self, params: Parameters<ScreenshotParam>) -> String {
        let p = params.0;
        let mut req = json!({
            "connectionId": p.connection_id,
            "format": p.format.unwrap_or_else(|| "jpeg".to_string()),
            "quality": p.quality.unwrap_or(80),
        });
        if let Some(mw) = p.max_width {
            req["maxWidth"] = json!(mw);
        }
        match self.ws.request("screenshot", req).await {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Click at coordinates on the remote desktop.")]
    async fn mouse_click(&self, params: Parameters<MouseClickParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "mouseClick",
                json!({
                    "connectionId": p.connection_id,
                    "x": p.x, "y": p.y,
                    "button": p.button.unwrap_or_else(|| "left".to_string()),
                }),
            )
            .await
        {
            Ok(_) => format!("Clicked at ({}, {})", p.x, p.y),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Double-click at coordinates on the remote desktop.")]
    async fn mouse_double_click(&self, params: Parameters<MousePositionParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "mouseDoubleClick",
                json!({
                    "connectionId": p.connection_id,
                    "x": p.x, "y": p.y,
                }),
            )
            .await
        {
            Ok(_) => format!("Double-clicked at ({}, {})", p.x, p.y),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Move the mouse cursor to coordinates on the remote desktop.")]
    async fn mouse_move(&self, params: Parameters<MousePositionParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "mouseMove",
                json!({
                    "connectionId": p.connection_id,
                    "x": p.x, "y": p.y,
                }),
            )
            .await
        {
            Ok(_) => format!("Moved to ({}, {})", p.x, p.y),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Scroll the mouse wheel on the remote desktop.")]
    async fn mouse_scroll(&self, params: Parameters<MouseScrollParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "mouseScroll",
                json!({
                    "connectionId": p.connection_id,
                    "x": p.x, "y": p.y,
                    "deltaX": p.delta_x.unwrap_or(0.0),
                    "deltaY": p.delta_y.unwrap_or(0.0),
                }),
            )
            .await
        {
            Ok(_) => "Scrolled".to_string(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Type text on the remote desktop. Uses clipboard paste for reliable unicode input.")]
    async fn keyboard_type(&self, params: Parameters<KeyboardTypeParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "keyboardType",
                json!({
                    "connectionId": p.connection_id,
                    "text": p.text,
                }),
            )
            .await
        {
            Ok(_) => format!("Typed: {}", p.text),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Send a keyboard shortcut (hotkey) on the remote desktop. Keys are pressed in order and released in reverse. Examples: [\"ctrl\",\"c\"], [\"ctrl\",\"shift\",\"esc\"], [\"win\",\"r\"], [\"alt\",\"f4\"]")]
    async fn keyboard_hotkey(&self, params: Parameters<KeyboardHotkeyParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "keyboardHotkey",
                json!({
                    "connectionId": p.connection_id,
                    "keys": p.keys,
                }),
            )
            .await
        {
            Ok(_) => format!("Hotkey sent: {}", p.keys.join("+")),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Set remote clipboard content.")]
    async fn set_clipboard(&self, params: Parameters<SetClipboardParam>) -> String {
        let p = params.0;
        match self
            .ws
            .request(
                "setClipboard",
                json!({
                    "connectionId": p.connection_id,
                    "text": p.text,
                }),
            )
            .await
        {
            Ok(_) => "Clipboard set".to_string(),
            Err(e) => format!("Error: {e}"),
        }
    }

    #[tool(description = "Get the remote screen resolution.")]
    async fn get_screen_size(&self, params: Parameters<ConnectionIdParam>) -> String {
        match self
            .ws
            .request("getScreenSize", json!({ "connectionId": params.0.connection_id }))
            .await
        {
            Ok(v) => serde_json::to_string_pretty(&v).unwrap_or_default(),
            Err(e) => format!("Error: {e}"),
        }
    }
}

#[tool_handler]
impl ServerHandler for QuickDeskMcpServer {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .enable_resources()
                .build(),
            server_info: Implementation {
                name: "quickdesk-mcp".to_string(),
                version: env!("CARGO_PKG_VERSION").to_string(),
                ..Default::default()
            },
            instructions: Some(
                "QuickDesk MCP Server - Control remote desktops via QuickDesk. \
                 Use get_host_info to get the local device credentials, then \
                 connect_device to establish a remote session. After connecting, \
                 use screenshot, mouse_click, keyboard_type, etc. to interact \
                 with the remote desktop. \
                 QuickDesk is a desktop application with a GUI. When you connect \
                 to a device, a remote desktop viewer window is shown by default \
                 so the user can observe your operations in real time. You can \
                 set show_window=false in connect_device for silent batch automation."
                    .to_string(),
            ),
            ..Default::default()
        }
    }

    async fn list_resources(
        &self,
        _request: Option<PaginatedRequestParams>,
        _context: RequestContext<RoleServer>,
    ) -> Result<ListResourcesResult, ErrorData> {
        let mut resources = vec![
            make_resource(
                "quickdesk://host",
                "Host Info",
                "Local device ID, access code, signaling state and connected client count",
            ),
            make_resource(
                "quickdesk://status",
                "System Status",
                "Overall status of host process, client process and signaling server",
            ),
        ];

        if let Ok(v) = self.ws.request("listConnections", json!({})).await {
            if let Some(conns) = v.get("connections").and_then(|c| c.as_array()) {
                for conn in conns {
                    let id = conn
                        .get("connectionId")
                        .and_then(|v| v.as_str())
                        .unwrap_or("unknown");
                    let device_id = conn
                        .get("deviceId")
                        .and_then(|v| v.as_str())
                        .unwrap_or("unknown");
                    resources.push(make_resource(
                        &format!("quickdesk://connection/{id}"),
                        &format!("Connection {id} (device {device_id})"),
                        &format!(
                            "Detailed info for remote connection {id} to device {device_id}"
                        ),
                    ));
                }
            }
        }

        Ok(ListResourcesResult {
            resources,
            next_cursor: None,
            meta: None,
        })
    }

    async fn list_resource_templates(
        &self,
        _request: Option<PaginatedRequestParams>,
        _context: RequestContext<RoleServer>,
    ) -> Result<ListResourceTemplatesResult, ErrorData> {
        Ok(ListResourceTemplatesResult {
            resource_templates: vec![Annotated {
                raw: RawResourceTemplate {
                    uri_template: "quickdesk://connection/{connectionId}".to_string(),
                    name: "Connection Info".to_string(),
                    title: None,
                    description: Some(
                        "Detailed info for a specific remote connection by connection ID"
                            .to_string(),
                    ),
                    mime_type: Some("application/json".to_string()),
                    icons: None,
                },
                annotations: None,
            }],
            next_cursor: None,
            meta: None,
        })
    }

    async fn read_resource(
        &self,
        request: ReadResourceRequestParams,
        _context: RequestContext<RoleServer>,
    ) -> Result<ReadResourceResult, ErrorData> {
        let uri = &request.uri;

        let result = if uri == "quickdesk://host" {
            self.ws.request("getHostInfo", json!({})).await
        } else if uri == "quickdesk://status" {
            self.ws.request("getStatus", json!({})).await
        } else if let Some(conn_id) = uri.strip_prefix("quickdesk://connection/") {
            self.ws
                .request("getConnectionInfo", json!({ "connectionId": conn_id }))
                .await
        } else {
            return Err(ErrorData::invalid_params(
                format!("Unknown resource URI: {uri}"),
                None,
            ));
        };

        match result {
            Ok(v) => {
                let text = serde_json::to_string_pretty(&v).unwrap_or_default();
                Ok(ReadResourceResult {
                    contents: vec![ResourceContents::TextResourceContents {
                        uri: uri.to_string(),
                        mime_type: Some("application/json".to_string()),
                        text,
                        meta: None,
                    }],
                })
            }
            Err(e) => Err(ErrorData::internal_error(e, None)),
        }
    }
}
