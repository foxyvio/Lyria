use crate::models::{Agent, Transaction};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Central in-memory store for the MVP.
/// In production this would be swapped for PostgreSQL (see README for the migration path).
#[derive(Default)]
pub struct Store {
    pub agents: HashMap<Uuid, Agent>,
    pub transactions: Vec<Transaction>,
}

pub type AppState = Arc<RwLock<Store>>;

pub fn new_state() -> AppState {
    Arc::new(RwLock::new(Store::default()))
}

