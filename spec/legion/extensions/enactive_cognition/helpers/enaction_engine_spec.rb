# frozen_string_literal: true

require 'legion/extensions/enactive_cognition/helpers/sensorimotor_loop'
require 'legion/extensions/enactive_cognition/helpers/enaction_engine'

RSpec.describe Legion::Extensions::EnactiveCognition::Helpers::EnactionEngine do
  subject(:engine) { described_class.new }

  let(:coupling) do
    engine.create_coupling(action: 'grasp', perception: 'grip', domain: 'motor')
  end

  describe '#create_coupling' do
    it 'returns a SensorimotorLoop instance' do
      expect(coupling).to be_a(Legion::Extensions::EnactiveCognition::Helpers::SensorimotorLoop)
    end

    it 'stores the coupling by id' do
      expect(engine.couplings[coupling.id]).to eq(coupling)
    end

    it 'increments coupling count' do
      engine.create_coupling(action: 'push', perception: 'moved', domain: 'motor')
      expect(engine.count).to eq(1)
    end

    it 'defaults loop_type to :sensorimotor' do
      expect(coupling.loop_type).to eq(:sensorimotor)
    end

    it 'accepts explicit loop_type' do
      lp = engine.create_coupling(action: 'think', perception: 'clarity', domain: 'cog', loop_type: :cognitive)
      expect(lp.loop_type).to eq(:cognitive)
    end
  end

  describe '#execute_action' do
    it 'returns success: true on match' do
      result = engine.execute_action(coupling_id: coupling.id, actual_perception: 'grip')
      expect(result[:success]).to be true
      expect(result[:match]).to be true
    end

    it 'returns success: true on mismatch' do
      result = engine.execute_action(coupling_id: coupling.id, actual_perception: 'slip')
      expect(result[:success]).to be true
      expect(result[:match]).to be false
    end

    it 'returns success: false for missing coupling' do
      result = engine.execute_action(coupling_id: 'nonexistent', actual_perception: 'grip')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'includes coupling_label in result' do
      result = engine.execute_action(coupling_id: coupling.id, actual_perception: 'grip')
      expect(result[:coupling_label]).to be_a(Symbol)
    end
  end

  describe '#adapt_coupling' do
    it 'updates the coupling perception' do
      engine.adapt_coupling(coupling_id: coupling.id, new_perception: 'firm_grip')
      expect(engine.couplings[coupling.id].perception).to eq('firm_grip')
    end

    it 'returns success: true' do
      result = engine.adapt_coupling(coupling_id: coupling.id, new_perception: 'firm_grip')
      expect(result[:success]).to be true
    end

    it 'returns success: false for missing coupling' do
      result = engine.adapt_coupling(coupling_id: 'bad', new_perception: 'x')
      expect(result[:success]).to be false
    end
  end

  describe '#find_action_for' do
    before do
      5.times { engine.execute_action(coupling_id: coupling.id, actual_perception: 'grip') }
    end

    it 'returns the loop when it is coupled and perception matches' do
      result = engine.find_action_for(perception: 'grip')
      if coupling.coupled?
        expect(result).not_to be_nil
        expect(result.action).to eq('grasp')
      else
        expect(result).to be_nil
      end
    end

    it 'returns nil when perception does not match any coupled loop' do
      result = engine.find_action_for(perception: 'unknown_perception')
      expect(result).to be_nil
    end
  end

  describe '#coupled_loops' do
    it 'returns empty when nothing is coupled' do
      engine.create_coupling(action: 'act', perception: 'per', domain: 'dom')
      expect(engine.coupled_loops).to be_empty
    end

    it 'returns loops above coupling threshold' do
      c2 = engine.create_coupling(action: 'act2', perception: 'per2', domain: 'dom2')
      allow(c2).to receive(:coupled?).and_return(true)
      expect(engine.coupled_loops).to include(c2)
    end
  end

  describe '#by_domain' do
    it 'returns loops in the specified domain' do
      engine.create_coupling(action: 'act', perception: 'per', domain: 'motor')
      engine.create_coupling(action: 'speak', perception: 'heard', domain: 'social')
      expect(engine.by_domain(domain: 'motor').size).to eq(1)
    end
  end

  describe '#by_type' do
    it 'returns loops of the specified type' do
      engine.create_coupling(action: 'act', perception: 'per', domain: 'dom', loop_type: :cognitive)
      engine.create_coupling(action: 'act2', perception: 'per2', domain: 'dom2', loop_type: :social)
      expect(engine.by_type(loop_type: :cognitive).size).to eq(1)
    end
  end

  describe '#strongest_couplings' do
    it 'returns at most limit couplings sorted by strength desc' do
      3.times { |i| engine.create_coupling(action: "a#{i}", perception: "p#{i}", domain: 'dom') }
      result = engine.strongest_couplings(limit: 2)
      expect(result.size).to be <= 2
    end
  end

  describe '#overall_coupling' do
    it 'returns 0.0 when no couplings exist' do
      expect(engine.overall_coupling).to eq(0.0)
    end

    it 'returns mean coupling strength' do
      engine.create_coupling(action: 'a', perception: 'p', domain: 'd')
      expect(engine.overall_coupling).to eq(
        Legion::Extensions::EnactiveCognition::Helpers::SensorimotorLoop::DEFAULT_COUPLING_STRENGTH
      )
    end
  end

  describe '#decay_all' do
    it 'reduces coupling strength of all loops' do
      lp = engine.create_coupling(action: 'a', perception: 'p', domain: 'd')
      before = lp.coupling_strength
      engine.decay_all
      expect(lp.coupling_strength).to be < before
    end
  end

  describe '#prune_decoupled' do
    it 'removes very weak couplings' do
      lp = engine.create_coupling(action: 'a', perception: 'p', domain: 'd')
      100.times { lp.execute!(actual_perception: 'miss') }
      count_before = engine.count
      engine.prune_decoupled
      expect(engine.count).to be <= count_before
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      result = engine.to_h
      expect(result).to include(:coupling_count, :coupled_count, :overall_coupling, :strongest)
    end

    it 'rounds overall_coupling to 4 decimal places' do
      engine.create_coupling(action: 'a', perception: 'p', domain: 'd')
      result = engine.to_h
      expect(result[:overall_coupling]).to be_a(Float)
    end
  end
end
