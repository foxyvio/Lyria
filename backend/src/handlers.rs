use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use chrono::Utc;
use uuid::Uuid;

use crate::models::*;
use crate::state::AppState;

/// POST /api/agents - register a new agent
pub async fn register_agent(
    State(state): State<AppState>,
    Json(payload): Json<RegisterAgentRequest>,
) -> (StatusCode, Json<Agent>) {
    let agent = Agent {
        id: Uuid::new_v4(),
        owner: payload.owner,
        name: payload.name,
        skill_name: payload.skill_name,
        skill_description: payload.skill_description,
        price_per_call: payload.price_per_call,
        wallet_balance: payload.starting_balance,
        created_at: Utc::now(),
    };

    let mut store = state.write().await;
    store.agents.insert(agent.id, agent.clone());

    (StatusCode::CREATED, Json(agent))
}

/// GET /api/agents - list all agents
pub async fn list_agents(State(state): State<AppState>) -> Json<Vec<Agent>> {
    let store = state.read().await;
    let agents: Vec<Agent> = store.agents.values().cloned().collect();
    Json(agents)
}

/// GET /api/agents/:id - get a single agent
pub async fn get_agent(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Agent>, (StatusCode, Json<ErrorResponse>)> {
    let store = state.read().await;
    store.agents.get(&id).cloned().map(Json).ok_or((
        StatusCode::NOT_FOUND,
        Json(ErrorResponse {
            error: "Agent not found".to_string(),
        }),
    ))
}

/// GET /api/marketplace - list all skills currently for sale
pub async fn list_marketplace(State(state): State<AppState>) -> Json<Vec<MarketplaceListing>> {
    let store = state.read().await;
    let listings: Vec<MarketplaceListing> = store
        .agents
        .values()
        .map(|a| MarketplaceListing {
            agent_id: a.id,
            agent_name: a.name.clone(),
            owner: a.owner.clone(),
            skill_name: a.skill_name.clone(),
            skill_description: a.skill_description.clone(),
            price_per_call: a.price_per_call,
        })
        .collect();
    Json(listings)
}

/// POST /api/tasks - one agent hires another; funds move on success
pub async fn hire_agent(
    State(state): State<AppState>,
    Json(payload): Json<HireAgentRequest>,
) -> (StatusCode, Json<Transaction>) {
    let mut store = state.write().await;

    let requester = store.agents.get(&payload.requester_agent_id).cloned();
    let provider = store.agents.get(&payload.provider_agent_id).cloned();

    let (status, amount, requester_name, provider_name, skill_name) = match (requester, provider)
    {
        (Some(req), Some(prov)) => {
            if req.wallet_balance < prov.price_per_call {
                (
                    TaskStatus::FailedInsufficientFunds,
                    prov.price_per_call,
                    req.name.clone(),
                    prov.name.clone(),
                    prov.skill_name.clone(),
                )
            } else {
                let price = prov.price_per_call;
                // Move funds: requester pays, provider earns.
                if let Some(r) = store.agents.get_mut(&req.id) {
                    r.wallet_balance -= price;
                }
                if let Some(p) = store.agents.get_mut(&prov.id) {
                    p.wallet_balance += price;
                }
                (
                    TaskStatus::Completed,
                    price,
                    req.name.clone(),
                    prov.name.clone(),
                    prov.skill_name.clone(),
                )
            }
        }
        _ => (
            TaskStatus::FailedAgentNotFound,
            0.0,
            "unknown".to_string(),
            "unknown".to_string(),
            "unknown".to_string(),
        ),
    };

    let tx = Transaction {
        id: Uuid::new_v4(),
        requester_agent_id: payload.requester_agent_id,
        requester_name,
        provider_agent_id: payload.provider_agent_id,
        provider_name,
        skill_name,
        amount,
        status: status.clone(),
        created_at: Utc::now(),
    };

    store.transactions.push(tx.clone());

    let http_status = match status {
        TaskStatus::Completed => StatusCode::CREATED,
        _ => StatusCode::UNPROCESSABLE_ENTITY,
    };

    (http_status, Json(tx))
}

/// GET /api/transactions - full transaction log
pub async fn list_transactions(State(state): State<AppState>) -> Json<Vec<Transaction>> {
    let store = state.read().await;
    Json(store.transactions.clone())
}

/// GET /api/agents/:id/wallet - balance + this agent's transaction history
pub async fn agent_wallet(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<ErrorResponse>)> {
    let store = state.read().await;
    let agent = store.agents.get(&id).ok_or((
        StatusCode::NOT_FOUND,
        Json(ErrorResponse {
            error: "Agent not found".to_string(),
        }),
    ))?;

    let history: Vec<&Transaction> = store
        .transactions
        .iter()
        .filter(|t| t.requester_agent_id == id || t.provider_agent_id == id)
        .collect();

    Ok(Json(serde_json::json!({
        "agent_id": agent.id,
        "balance": agent.wallet_balance,
        "history": history,
    })))
}

