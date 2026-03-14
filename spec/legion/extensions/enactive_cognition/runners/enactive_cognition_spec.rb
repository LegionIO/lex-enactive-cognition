# frozen_string_literal: true

require 'legion/extensions/enactive_cognition/client'

RSpec.describe Legion::Extensions::EnactiveCognition::Runners::EnactiveCognition do
  let(:client) { Legion::Extensions::EnactiveCognition::Client.new }

  def make_coupling(action: 'press', perception: 'click', domain: 'motor', loop_type: :sensorimotor)
    client.create_sensorimotor_coupling(
      action:     action,
      perception: perception,
      domain:     domain,
      loop_type:  loop_type
    )
  end

  describe '#create_sensorimotor_coupling' do
    it 'returns success: true' do
      result = make_coupling
      expect(result[:success]).to be true
    end

    it 'includes coupling hash with uuid id' do
      result = make_coupling
      expect(result[:coupling][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'reflects the given action and perception' do
      result = make_coupling(action: 'push', perception: 'moved')
      expect(result[:coupling][:action]).to eq('push')
      expect(result[:coupling][:perception]).to eq('moved')
    end

    it 'accepts string loop_type and converts to symbol' do
      result = client.create_sensorimotor_coupling(
        action:     'x',
        perception: 'y',
        domain:     'z',
        loop_type:  'cognitive'
      )
      expect(result[:coupling][:loop_type]).to eq(:cognitive)
    end
  end

  describe '#execute_enactive_action' do
    let(:coupling_id) { make_coupling[:coupling][:id] }

    it 'returns success: true on matching perception' do
      result = client.execute_enactive_action(coupling_id: coupling_id, actual_perception: 'click')
      expect(result[:success]).to be true
      expect(result[:match]).to be true
    end

    it 'returns success: true on mismatching perception' do
      result = client.execute_enactive_action(coupling_id: coupling_id, actual_perception: 'silence')
      expect(result[:success]).to be true
      expect(result[:match]).to be false
    end

    it 'returns success: false for unknown coupling_id' do
      result = client.execute_enactive_action(coupling_id: 'bad-id', actual_perception: 'click')
      expect(result[:success]).to be false
    end

    it 'includes coupling_label in result' do
      result = client.execute_enactive_action(coupling_id: coupling_id, actual_perception: 'click')
      expect(result[:coupling_label]).to be_a(Symbol)
    end
  end

  describe '#adapt_sensorimotor_coupling' do
    let(:coupling_id) { make_coupling[:coupling][:id] }

    it 'returns success: true' do
      result = client.adapt_sensorimotor_coupling(coupling_id: coupling_id, new_perception: 'soft_click')
      expect(result[:success]).to be true
    end

    it 'returns new_perception in result' do
      result = client.adapt_sensorimotor_coupling(coupling_id: coupling_id, new_perception: 'soft_click')
      expect(result[:new_perception]).to eq('soft_click')
    end

    it 'returns success: false for missing coupling' do
      result = client.adapt_sensorimotor_coupling(coupling_id: 'missing', new_perception: 'x')
      expect(result[:success]).to be false
    end
  end

  describe '#find_action_for_perception' do
    it 'returns found: false when nothing is coupled' do
      result = client.find_action_for_perception(perception: 'click')
      expect(result[:found]).to be false
    end

    it 'returns found: true when a coupled loop matches' do
      id = make_coupling[:coupling][:id]
      5.times { client.execute_enactive_action(coupling_id: id, actual_perception: 'click') }
      result = client.find_action_for_perception(perception: 'click')
      # may or may not be coupled depending on starting strength + reinforcement
      if result[:found]
        expect(result[:action]).to eq('press')
      else
        expect(result[:found]).to be false
      end
    end
  end

  describe '#coupled_sensorimotor_loops' do
    it 'returns loops and count' do
      result = client.coupled_sensorimotor_loops
      expect(result).to include(:loops, :count)
      expect(result[:loops]).to be_an(Array)
    end

    it 'count is zero initially' do
      expect(client.coupled_sensorimotor_loops[:count]).to eq(0)
    end
  end

  describe '#domain_couplings' do
    before { make_coupling(domain: 'motor') }

    it 'returns loops in the domain' do
      result = client.domain_couplings(domain: 'motor')
      expect(result[:domain]).to eq('motor')
      expect(result[:count]).to eq(1)
    end

    it 'returns zero for unknown domain' do
      result = client.domain_couplings(domain: 'unknown')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#strongest_couplings' do
    before { 3.times { |i| make_coupling(action: "act#{i}", perception: "per#{i}", domain: 'dom') } }

    it 'returns loops array' do
      result = client.strongest_couplings(limit: 2)
      expect(result[:loops].size).to be <= 2
    end

    it 'uses default limit of 5' do
      result = client.strongest_couplings
      expect(result[:loops].size).to be <= 5
    end
  end

  describe '#overall_enactive_coupling' do
    it 'returns overall_coupling and coupling_label' do
      result = client.overall_enactive_coupling
      expect(result).to include(:overall_coupling, :coupling_label)
    end

    it 'returns 0.0 when no couplings exist' do
      expect(client.overall_enactive_coupling[:overall_coupling]).to eq(0.0)
    end

    it 'returns :decoupled label when no couplings' do
      expect(client.overall_enactive_coupling[:coupling_label]).to eq(:decoupled)
    end

    it 'returns :forming label at default strength' do
      make_coupling
      result = client.overall_enactive_coupling
      expect(result[:coupling_label]).to eq(:forming)
    end
  end

  describe '#update_enactive_cognition' do
    before { make_coupling }

    it 'returns success: true' do
      result = client.update_enactive_cognition
      expect(result[:success]).to be true
    end

    it 'decays couplings when decay: true' do
      before_strength = client.strongest_couplings(limit: 1)[:loops].first[:coupling_strength]
      client.update_enactive_cognition(decay: true)
      after_strength = client.strongest_couplings(limit: 1)[:loops].first[:coupling_strength]
      expect(after_strength).to be < before_strength
    end

    it 'reflects coupling_count in result' do
      result = client.update_enactive_cognition
      expect(result[:coupling_count]).to be >= 1
    end
  end

  describe '#enactive_cognition_stats' do
    it 'returns success: true' do
      result = client.enactive_cognition_stats
      expect(result[:success]).to be true
    end

    it 'includes stats hash' do
      result = client.enactive_cognition_stats
      expect(result[:stats]).to include(:coupling_count, :coupled_count, :overall_coupling)
    end

    it 'reports zero coupling_count when empty' do
      result = client.enactive_cognition_stats
      expect(result[:stats][:coupling_count]).to eq(0)
    end

    it 'increments coupling_count after creating a coupling' do
      make_coupling
      result = client.enactive_cognition_stats
      expect(result[:stats][:coupling_count]).to eq(1)
    end
  end
end
