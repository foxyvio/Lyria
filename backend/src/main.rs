mod handlers;
mod models;
mod state;

use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

#[tokio::main]
async fn main() {
    let app_state = state::new_state();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/api/agents", post(handlers::register_agent).get(handlers::list_agents))
        .route("/api/agents/:id", get(handlers::get_agent))
        .route("/api/agents/:id/wallet", get(handlers::agent_wallet))
        .route("/api/marketplace", get(handlers::list_marketplace))
        .route("/api/tasks", post(handlers::hire_agent).get(handlers::list_transactions))
        .layer(cors)
        .with_state(app_state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Lyria backend running on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

