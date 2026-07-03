use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// An AI Agent registered on the Lyria SKaaS marketplace.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub id: Uuid,
    pub owner: String,
    pub name: String,
    pub skill_name: String,
    pub skill_description: String,
    pub price_per_call: f64,
    pub wallet_balance: f64,
    pub created_at: DateTime<Utc>,
}

/// Payload for registering a new agent.
#[derive(Debug, Deserialize)]
pub struct RegisterAgentRequest {
    pub owner: String,
    pub name: String,
    pub skill_name: String,
    pub skill_description: String,
    pub price_per_call: f64,
    #[serde(default = "default_starting_balance")]
    pub starting_balance: f64,
}

fn default_starting_balance() -> f64 {
    100.0
}

/// A completed (or failed) task/transaction between two agents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub id: Uuid,
    pub requester_agent_id: Uuid,
    pub requester_name: String,
    pub provider_agent_id: Uuid,
    pub provider_name: String,
    pub skill_name: String,
    pub amount: f64,
    pub status: TaskStatus,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum TaskStatus {
    Completed,
    FailedInsufficientFunds,
    FailedAgentNotFound,
}

/// Payload for hiring another agent (creating a task).
#[derive(Debug, Deserialize)]
pub struct HireAgentRequest {
    pub requester_agent_id: Uuid,
    pub provider_agent_id: Uuid,
}

/// A public-facing marketplace listing (skill + price + provider).
#[derive(Debug, Clone, Serialize)]
pub struct MarketplaceListing {
    pub agent_id: Uuid,
    pub agent_name: String,
    pub owner: String,
    pub skill_name: String,
    pub skill_description: String,
    pub price_per_call: f64,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
}

