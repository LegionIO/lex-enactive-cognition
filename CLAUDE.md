# lex-enactive-cognition

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Enactive cognition modeling for the LegionIO cognitive architecture. Implements the enactivist theory that cognition is not passive information processing but active sense-making through agent-environment coupling. The agent continually enacts its environment via action-perception loops, building a coupling history. Measures environmental affordances, tracks structural coupling strength, and assesses autopoietic (self-maintaining) viability.

Based on Varela, Thompson, and Rosch's theory from "The Embodied Mind."

## Gem Info

- **Gem name**: `lex-enactive-cognition`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::EnactiveCognition`
- **Location**: `extensions-agentic/lex-enactive-cognition/`

## File Structure

```
lib/legion/extensions/enactive_cognition/
  enactive_cognition.rb         # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # AFFORDANCE_TYPES, COUPLING_STATES, VIABILITY_LABELS, thresholds
    action_perception_loop.rb   # ActionPerceptionLoop value object
    enactive_engine.rb          # Engine: coupling tracking, affordance detection, viability
  runners/
    enactive_cognition.rb       # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `AFFORDANCE_TYPES` | `[:movement, :manipulation, :communication, :computation, :rest]` | Types of environmental opportunities |
| `COUPLING_STATES` | `[:engaged, :transitioning, :disengaged, :disrupted]` | Structural coupling states |
| `COUPLING_DECAY_RATE` | 0.03 | Coupling strength lost per idle cycle |
| `COUPLING_REINFORCEMENT` | 0.1 | Coupling strength gained per action-perception loop |
| `VIABILITY_THRESHOLD` | 0.4 | Minimum coupling for autopoietic viability |
| `MAX_LOOPS` | 500 | Rolling action-perception loop history cap |
| `MAX_AFFORDANCES` | 100 | Affordance detection cap |
| `SENSE_MAKING_DEPTH` | 3 | Layers of sense-making per loop |
| `VIABILITY_LABELS` | range hash | `thriving / viable / marginal / at_risk / disrupted` |
| `STRUCTURAL_COUPLING_LABELS` | range hash | `strongly_coupled / coupled / loosely_coupled / decoupled` |

## Runners

All methods in `Legion::Extensions::EnactiveCognition::Runners::EnactiveCognition`.

| Method | Key Args | Returns |
|---|---|---|
| `enact` | `action:, perception:, context: {}` | `{ success:, loop_id:, coupling_strength:, sense_made:, viability: }` |
| `detect_affordances` | `environment: {}` | `{ success:, affordances:, count:, richness_score: }` |
| `assess_viability` | — | `{ success:, viability_score:, viability_label:, coupling_state:, at_risk: }` |
| `structural_coupling` | — | `{ success:, coupling_strength:, coupling_label:, loop_count:, coupling_state: }` |
| `sense_making_history` | `limit: 10` | `{ success:, loops:, count: }` |
| `disrupt_coupling` | `source:` | `{ success:, previous_strength:, current_strength:, coupling_state: :disrupted }` |
| `restore_coupling` | — | `{ success:, restored:, coupling_strength: }` |
| `update_enactive_cognition` | — | `{ success:, coupling_decayed:, loops_pruned: }` |
| `enactive_cognition_stats` | — | Full stats hash |

## Helpers

### `ActionPerceptionLoop`
Value object. Attributes: `id`, `action`, `perception`, `context`, `sense_made` (boolean), `coupling_delta`, `timestamp`. `to_h`.

### `EnactiveEngine`
Central state: `@loops` (array, rolling), `@affordances` (array), `@coupling_strength` (float 0–1), `@coupling_state`. Key methods:
- `enact(action:, perception:, context:)`: creates loop, updates coupling strength (+ reinforcement), detects sense-making from action-perception alignment, appends to history
- `detect_affordances(environment:)`: maps environment keys/values to affordance types, computes richness score
- `assess_viability`: returns viability score from coupling strength, maps to label, sets `at_risk` flag below `VIABILITY_THRESHOLD`
- `disrupt(source:)`: sets state to `:disrupted`, reduces coupling strength sharply
- `restore`: transitions state toward `:transitioning`, begins gradual recovery
- `decay_coupling`: reduces by `COUPLING_DECAY_RATE` per cycle (called by `update_enactive_cognition`)

## Integration Points

- `enact` called from lex-tick's `sensory_processing` phase on each action-perception pair
- `assess_viability[:at_risk]` triggers lex-emotion stress signal (low coupling = existential anxiety)
- `detect_affordances` informs lex-prediction's opportunity detection
- `structural_coupling[:coupling_strength]` feeds lex-dual-process's grounding calculation
- `disrupt_coupling` called from lex-extinction when containment level is raised

## Development Notes

- Sense-making is determined by action-perception alignment: aligned pairs (action produces expected perception) increment sense_made count
- Coupling strength is bounded [0, 1]; disruption floors it at 0.1 (not 0.0) to allow recovery
- Affordance richness score = count of distinct affordance types / total AFFORDANCE_TYPES
- `restore_coupling` transitions coupling_state: `:disrupted` → `:transitioning` → `:disengaged` (not immediate `:engaged`)
- SENSE_MAKING_DEPTH is informational — current implementation performs single-depth sense-making per loop
