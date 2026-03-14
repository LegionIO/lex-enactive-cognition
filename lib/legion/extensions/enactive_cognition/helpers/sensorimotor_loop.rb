# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module EnactiveCognition
      module Helpers
        class SensorimotorLoop
          MAX_COUPLINGS  = 200
          MAX_ACTIONS    = 500
          MAX_PERCEPTIONS = 500
          MAX_HISTORY = 300

          DEFAULT_COUPLING_STRENGTH = 0.5
          COUPLING_FLOOR   = 0.0
          COUPLING_CEILING = 1.0

          REINFORCEMENT_RATE = 0.1
          DECOUPLING_RATE    = 0.15

          PREDICTION_ACCURACY_THRESHOLD = 0.6

          COUPLING_DECAY   = 0.02
          STALE_THRESHOLD  = 120

          COUPLING_LABELS = {
            (0.8..)     => :entrained,
            (0.6...0.8) => :coupled,
            (0.4...0.6) => :forming,
            (0.2...0.4) => :weak,
            (..0.2)     => :decoupled
          }.freeze

          LOOP_TYPES = %i[sensorimotor cognitive social].freeze

          attr_reader :id, :action, :perception, :domain, :loop_type,
                      :coupling_strength, :prediction_accuracy,
                      :execution_count, :accurate_predictions,
                      :created_at, :last_executed_at

          def initialize(action:, perception:, domain:, loop_type: :sensorimotor)
            @id                  = SecureRandom.uuid
            @action              = action
            @perception          = perception
            @domain              = domain
            @loop_type           = LOOP_TYPES.include?(loop_type) ? loop_type : :sensorimotor
            @coupling_strength   = DEFAULT_COUPLING_STRENGTH
            @execution_count     = 0
            @accurate_predictions = 0
            @prediction_accuracy = 0.0
            @created_at          = Time.now.utc
            @last_executed_at    = nil
          end

          def execute!(actual_perception:)
            @execution_count    += 1
            @last_executed_at    = Time.now.utc
            match = actual_perception.to_s == @perception.to_s

            if match
              @accurate_predictions += 1
              @coupling_strength     = (@coupling_strength + REINFORCEMENT_RATE).clamp(COUPLING_FLOOR, COUPLING_CEILING)
            else
              @coupling_strength = (@coupling_strength - DECOUPLING_RATE).clamp(COUPLING_FLOOR, COUPLING_CEILING)
            end

            @prediction_accuracy = @accurate_predictions.to_f / @execution_count
            { match: match, coupling_strength: @coupling_strength, prediction_accuracy: @prediction_accuracy }
          end

          def coupled?
            coupling_strength >= 0.6
          end

          def coupling_label
            COUPLING_LABELS.each do |range, label|
              return label if range.cover?(coupling_strength)
            end
            :decoupled
          end

          def adapt_perception!(new_perception:)
            @perception = new_perception
          end

          def decay!
            @coupling_strength = (@coupling_strength - COUPLING_DECAY).clamp(COUPLING_FLOOR, COUPLING_CEILING)
          end

          def stale?
            return false if @last_executed_at.nil?

            (Time.now.utc - @last_executed_at) > STALE_THRESHOLD
          end

          def to_h
            {
              id:                   @id,
              action:               @action,
              perception:           @perception,
              domain:               @domain,
              loop_type:            @loop_type,
              coupling_strength:    @coupling_strength,
              coupling_label:       coupling_label,
              prediction_accuracy:  @prediction_accuracy,
              execution_count:      @execution_count,
              accurate_predictions: @accurate_predictions,
              coupled:              coupled?,
              created_at:           @created_at,
              last_executed_at:     @last_executed_at
            }
          end
        end
      end
    end
  end
end
