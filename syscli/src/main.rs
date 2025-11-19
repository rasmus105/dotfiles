use clap::{Parser, Subcommand};
use tracing::{debug, trace, Level};

mod prompt;

#[derive(Subcommand, Debug, Clone)]
pub enum Command {
    /// Release a new version
    Release,
    /// Update system configuration
    Update,
}

#[derive(Parser, Debug, Clone)]
#[command(name = "syscli", version, about = "System management CLI")]
pub struct Cli {
    #[command(subcommand)]
    command: Command,
}

fn main() {
    // setup logging
    tracing_subscriber::fmt()
        .with_max_level(Level::TRACE)
        .init();

    trace!("Starting system CLI...");

    // get CLI arguments
    let args = Cli::parse();

    match args.command {
        Command::Release => {
            debug!("Dispatching release command");
            // TODO: call release logic
        }
        Command::Update => {
            debug!("Dispatching update command");
            // TODO: call update logic
        }
    }
}
