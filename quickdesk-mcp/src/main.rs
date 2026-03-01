mod server;
mod ws_client;

use clap::Parser;
use rmcp::ServiceExt;
use rmcp::transport::stdio;
use tracing_subscriber::EnvFilter;

#[derive(Parser)]
#[command(name = "quickdesk-mcp", about = "MCP bridge for QuickDesk remote desktop")]
struct Cli {
    /// QuickDesk WebSocket server URL
    #[arg(long, default_value = "ws://127.0.0.1:9800")]
    ws_url: String,

    /// Authentication token for WebSocket server
    #[arg(long, env = "QUICKDESK_TOKEN")]
    token: Option<String>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .init();

    let cli = Cli::parse();

    tracing::info!("Connecting to QuickDesk at {}", cli.ws_url);

    let ws = ws_client::WsClient::connect(&cli.ws_url, cli.token.as_deref()).await?;

    tracing::info!("Connected. Starting MCP server on stdio...");

    let mcp_server = server::QuickDeskMcpServer::new(ws);
    let service = mcp_server.serve(stdio()).await?;
    service.waiting().await?;

    Ok(())
}
