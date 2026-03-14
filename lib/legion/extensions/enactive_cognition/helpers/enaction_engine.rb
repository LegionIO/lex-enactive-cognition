# frozen_string_literal: true

module Legion
  module Extensions
    module EnactiveCognition
      module Helpers
        class EnactionEngine
          attr_reader :couplings

          def initialize
            @couplings = {}
          end

          def create_coupling(action:, perception:, domain:, loop_type: :sensorimotor)
            prune_to_limit

            loop = SensorimotorLoop.new(
              action:     action,
              perception: perception,
              domain:     domain,
              loop_type:  loop_type
            )
            @couplings[loop.id] = loop
            loop
          end

          def execute_action(coupling_id:, actual_perception:)
            loop = @couplings[coupling_id]
            return { success: false, reason: :not_found } unless loop

            result = loop.execute!(actual_perception: actual_perception)
            {
              success:             true,
              coupling_id:         coupling_id,
              match:               result[:match],
              coupling_strength:   result[:coupling_strength],
              prediction_accuracy: result[:prediction_accuracy],
              coupling_label:      loop.coupling_label
            }
          end

          def adapt_coupling(coupling_id:, new_perception:)
            loop = @couplings[coupling_id]
            return { success: false, reason: :not_found } unless loop

            loop.adapt_perception!(new_perception: new_perception)
            { success: true, coupling_id: coupling_id, new_perception: new_perception }
          end

          def find_action_for(perception:)
            best = @couplings.values
                             .select(&:coupled?)
                             .select { |lp| lp.perception.to_s == perception.to_s }
                             .max_by(&:coupling_strength)
            return nil unless best

            best
          end

          def coupled_loops
            @couplings.values.select(&:coupled?)
          end

          def by_domain(domain:)
            @couplings.values.select { |lp| lp.domain.to_s == domain.to_s }
          end

          def by_type(loop_type:)
            @couplings.values.select { |lp| lp.loop_type == loop_type }
          end

          def strongest_couplings(limit: 5)
            @couplings.values.sort_by { |lp| -lp.coupling_strength }.first(limit)
          end

          def overall_coupling
            return 0.0 if @couplings.empty?

            total = @couplings.values.sum(&:coupling_strength)
            total / @couplings.size
          end

          def decay_all
            @couplings.each_value(&:decay!)
          end

          def prune_decoupled
            @couplings.delete_if { |_id, lp| lp.coupling_strength < SensorimotorLoop::COUPLING_FLOOR + 0.05 }
          end

          def count
            @couplings.size
          end

          def to_h
            {
              coupling_count:   @couplings.size,
              coupled_count:    coupled_loops.size,
              overall_coupling: overall_coupling.round(4),
              strongest:        strongest_couplings(limit: 3).map(&:to_h)
            }
          end

          private

          def prune_to_limit
            return unless @couplings.size >= SensorimotorLoop::MAX_COUPLINGS

            weakest = @couplings.values.sort_by(&:coupling_strength).first(10)
            weakest.each { |lp| @couplings.delete(lp.id) }
          end
        end
      end
    end
  end
end
