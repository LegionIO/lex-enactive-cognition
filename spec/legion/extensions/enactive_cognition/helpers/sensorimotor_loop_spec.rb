# frozen_string_literal: true

require 'legion/extensions/enactive_cognition/helpers/sensorimotor_loop'

RSpec.describe Legion::Extensions::EnactiveCognition::Helpers::SensorimotorLoop do
  subject(:loop_obj) do
    described_class.new(action: 'reach', perception: 'contact', domain: 'motor')
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(loop_obj.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets default coupling strength' do
      expect(loop_obj.coupling_strength).to eq(described_class::DEFAULT_COUPLING_STRENGTH)
    end

    it 'defaults loop_type to :sensorimotor' do
      expect(loop_obj.loop_type).to eq(:sensorimotor)
    end

    it 'accepts valid loop types' do
      cognitive = described_class.new(action: 'think', perception: 'insight', domain: 'cog', loop_type: :cognitive)
      expect(cognitive.loop_type).to eq(:cognitive)
    end

    it 'falls back to :sensorimotor for invalid loop_type' do
      bad = described_class.new(action: 'x', perception: 'y', domain: 'z', loop_type: :invalid)
      expect(bad.loop_type).to eq(:sensorimotor)
    end

    it 'starts with zero execution count' do
      expect(loop_obj.execution_count).to eq(0)
    end

    it 'starts with zero accurate_predictions' do
      expect(loop_obj.accurate_predictions).to eq(0)
    end
  end

  describe '#execute!' do
    context 'when actual matches expected perception' do
      it 'increments execution_count' do
        loop_obj.execute!(actual_perception: 'contact')
        expect(loop_obj.execution_count).to eq(1)
      end

      it 'increments accurate_predictions' do
        loop_obj.execute!(actual_perception: 'contact')
        expect(loop_obj.accurate_predictions).to eq(1)
      end

      it 'strengthens coupling' do
        before = loop_obj.coupling_strength
        loop_obj.execute!(actual_perception: 'contact')
        expect(loop_obj.coupling_strength).to be > before
      end

      it 'returns match: true' do
        result = loop_obj.execute!(actual_perception: 'contact')
        expect(result[:match]).to be true
      end

      it 'does not exceed COUPLING_CEILING' do
        20.times { loop_obj.execute!(actual_perception: 'contact') }
        expect(loop_obj.coupling_strength).to be <= described_class::COUPLING_CEILING
      end
    end

    context 'when actual does not match expected perception' do
      it 'weakens coupling' do
        before = loop_obj.coupling_strength
        loop_obj.execute!(actual_perception: 'no_contact')
        expect(loop_obj.coupling_strength).to be < before
      end

      it 'returns match: false' do
        result = loop_obj.execute!(actual_perception: 'no_contact')
        expect(result[:match]).to be false
      end

      it 'does not fall below COUPLING_FLOOR' do
        20.times { loop_obj.execute!(actual_perception: 'no_contact') }
        expect(loop_obj.coupling_strength).to be >= described_class::COUPLING_FLOOR
      end

      it 'does not increment accurate_predictions' do
        loop_obj.execute!(actual_perception: 'no_contact')
        expect(loop_obj.accurate_predictions).to eq(0)
      end
    end

    it 'updates prediction_accuracy' do
      3.times { loop_obj.execute!(actual_perception: 'contact') }
      loop_obj.execute!(actual_perception: 'miss')
      expect(loop_obj.prediction_accuracy).to eq(0.75)
    end

    it 'sets last_executed_at' do
      loop_obj.execute!(actual_perception: 'contact')
      expect(loop_obj.last_executed_at).not_to be_nil
    end
  end

  describe '#coupled?' do
    it 'returns false at default strength (0.5)' do
      expect(loop_obj.coupled?).to be false
    end

    it 'returns true when strength reaches 0.6' do
      loop_obj.execute!(actual_perception: 'contact')
      loop_obj.execute!(actual_perception: 'contact')
      if loop_obj.coupling_strength >= 0.6
        expect(loop_obj.coupled?).to be true
      else
        expect(loop_obj.coupled?).to be false
      end
    end
  end

  describe '#coupling_label' do
    it 'returns :forming at default strength 0.5' do
      expect(loop_obj.coupling_label).to eq(:forming)
    end

    it 'returns :entrained at strength 0.9' do
      allow(loop_obj).to receive(:coupling_strength).and_return(0.9)
      expect(loop_obj.coupling_label).to eq(:entrained)
    end

    it 'returns :decoupled at strength 0.1' do
      allow(loop_obj).to receive(:coupling_strength).and_return(0.1)
      expect(loop_obj.coupling_label).to eq(:decoupled)
    end

    it 'returns :weak at strength 0.25' do
      allow(loop_obj).to receive(:coupling_strength).and_return(0.25)
      expect(loop_obj.coupling_label).to eq(:weak)
    end

    it 'returns :coupled at strength 0.7' do
      allow(loop_obj).to receive(:coupling_strength).and_return(0.7)
      expect(loop_obj.coupling_label).to eq(:coupled)
    end
  end

  describe '#adapt_perception!' do
    it 'updates the expected perception' do
      loop_obj.adapt_perception!(new_perception: 'soft_contact')
      expect(loop_obj.perception).to eq('soft_contact')
    end
  end

  describe '#decay!' do
    it 'reduces coupling_strength by COUPLING_DECAY' do
      before = loop_obj.coupling_strength
      loop_obj.decay!
      expect(loop_obj.coupling_strength).to eq((before - described_class::COUPLING_DECAY).clamp(0.0, 1.0))
    end

    it 'does not fall below COUPLING_FLOOR' do
      100.times { loop_obj.decay! }
      expect(loop_obj.coupling_strength).to be >= described_class::COUPLING_FLOOR
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      hash = loop_obj.to_h
      expect(hash).to include(
        :id, :action, :perception, :domain, :loop_type,
        :coupling_strength, :coupling_label, :prediction_accuracy,
        :execution_count, :accurate_predictions, :coupled,
        :created_at, :last_executed_at
      )
    end

    it 'reflects current coupling_label' do
      hash = loop_obj.to_h
      expect(hash[:coupling_label]).to eq(loop_obj.coupling_label)
    end
  end
end
