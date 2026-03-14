# frozen_string_literal: true

module Legion
  module Extensions
    module EnactiveCognition
      module Runners
        module EnactiveCognition
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_sensorimotor_coupling(action:, perception:, domain:, loop_type: :sensorimotor, **)
            type = loop_type.is_a?(Symbol) ? loop_type : loop_type.to_sym
            loop = enaction_engine.create_coupling(
              action:     action,
              perception: perception,
              domain:     domain,
              loop_type:  type
            )
            Legion::Logging.debug "[enactive_cognition] created coupling id=#{loop.id[0..7]} " \
                                  "action=#{action} domain=#{domain} type=#{type}"
            { success: true, coupling: loop.to_h }
          end

          def execute_enactive_action(coupling_id:, actual_perception:, **)
            result = enaction_engine.execute_action(
              coupling_id:       coupling_id,
              actual_perception: actual_perception
            )
            unless result[:success]
              Legion::Logging.debug "[enactive_cognition] execute failed: #{coupling_id[0..7]} not found"
              return result
            end

            Legion::Logging.debug "[enactive_cognition] executed #{coupling_id[0..7]} " \
                                  "match=#{result[:match]} label=#{result[:coupling_label]}"
            result
          end

          def adapt_sensorimotor_coupling(coupling_id:, new_perception:, **)
            result = enaction_engine.adapt_coupling(
              coupling_id:    coupling_id,
              new_perception: new_perception
            )
            unless result[:success]
              Legion::Logging.debug "[enactive_cognition] adapt failed: #{coupling_id[0..7]} not found"
              return result
            end

            Legion::Logging.info "[enactive_cognition] adapted #{coupling_id[0..7]} new_perception=#{new_perception}"
            result
          end

          def find_action_for_perception(perception:, **)
            loop = enaction_engine.find_action_for(perception: perception)
            unless loop
              Legion::Logging.debug "[enactive_cognition] no coupled action found for perception=#{perception}"
              return { found: false, perception: perception }
            end

            Legion::Logging.debug "[enactive_cognition] found action=#{loop.action} for perception=#{perception}"
            { found: true, action: loop.action, coupling: loop.to_h }
          end

          def coupled_sensorimotor_loops(**)
            loops = enaction_engine.coupled_loops
            Legion::Logging.debug "[enactive_cognition] coupled loops count=#{loops.size}"
            { loops: loops.map(&:to_h), count: loops.size }
          end

          def domain_couplings(domain:, **)
            loops = enaction_engine.by_domain(domain: domain)
            Legion::Logging.debug "[enactive_cognition] domain=#{domain} loops=#{loops.size}"
            { domain: domain, loops: loops.map(&:to_h), count: loops.size }
          end

          def strongest_couplings(limit: 5, **)
            loops = enaction_engine.strongest_couplings(limit: limit)
            Legion::Logging.debug "[enactive_cognition] strongest couplings limit=#{limit} found=#{loops.size}"
            { loops: loops.map(&:to_h), count: loops.size }
          end

          def overall_enactive_coupling(**)
            strength = enaction_engine.overall_coupling
            label    = coupling_label_for(strength)
            Legion::Logging.debug "[enactive_cognition] overall_coupling=#{strength.round(3)} label=#{label}"
            { overall_coupling: strength, coupling_label: label }
          end

          def update_enactive_cognition(decay: false, prune: false, **)
            enaction_engine.decay_all if decay
            enaction_engine.prune_decoupled if prune
            Legion::Logging.debug "[enactive_cognition] update decay=#{decay} prune=#{prune} " \
                                  "remaining=#{enaction_engine.count}"
            { success: true, decay: decay, prune: prune, coupling_count: enaction_engine.count }
          end

          def enactive_cognition_stats(**)
            stats = enaction_engine.to_h
            Legion::Logging.debug "[enactive_cognition] stats couplings=#{stats[:coupling_count]} " \
                                  "coupled=#{stats[:coupled_count]}"
            { success: true, stats: stats }
          end

          private

          def enaction_engine
            @enaction_engine ||= Helpers::EnactionEngine.new
          end

          def coupling_label_for(strength)
            Helpers::SensorimotorLoop::COUPLING_LABELS.each do |range, label|
              return label if range.cover?(strength)
            end
            :decoupled
          end
        end
      end
    end
  end
end
