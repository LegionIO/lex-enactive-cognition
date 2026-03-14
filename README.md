# lex-enactive-cognition

Enactive cognition modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements the enactivist theory that cognition is active sense-making through agent-environment coupling, not passive information processing. The agent enacts its environment through action-perception loops, building structural coupling over time. Measures environmental affordances (what actions are available), tracks coupling strength (how well the agent is coupled to its environment), and assesses autopoietic viability (whether the coupling is sufficient for healthy functioning).

Based on Varela, Thompson, and Rosch's "The Embodied Mind."

## Usage

```ruby
client = Legion::Extensions::EnactiveCognition::Client.new

# Enact: perform action and perceive the result
client.enact(
  action: :process_request,
  perception: { response_received: true, latency: :low },
  context: { domain: :networking }
)
# => { success: true, loop_id: "...", coupling_strength: 0.6, sense_made: true, viability: 0.6 }

# Detect what actions the environment affords
client.detect_affordances(environment: { compute: :available, network: :stable, memory: :low })
# => { affordances: [:computation, :communication], count: 2, richness_score: 0.4 }

# Check viability
client.assess_viability
# => { viability_score: 0.6, viability_label: :viable, coupling_state: :engaged, at_risk: false }

# Check structural coupling strength
client.structural_coupling
# => { coupling_strength: 0.72, coupling_label: :coupled, loop_count: 47, coupling_state: :engaged }

# Handle a disruptive event
client.disrupt_coupling(source: :network_failure)
# => { coupling_state: :disrupted, previous_strength: 0.72, current_strength: 0.2 }

# Begin recovery
client.restore_coupling

# Periodic maintenance: decay coupling, prune old loops
client.update_enactive_cognition
```

## Viability Labels

| Score | Label |
|---|---|
| 0.8 – 1.0 | `:thriving` |
| 0.6 – 0.8 | `:viable` |
| 0.4 – 0.6 | `:marginal` |
| 0.2 – 0.4 | `:at_risk` |
| 0.0 – 0.2 | `:disrupted` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
