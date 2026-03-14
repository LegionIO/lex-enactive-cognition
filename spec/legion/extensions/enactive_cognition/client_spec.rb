# frozen_string_literal: true

require 'legion/extensions/enactive_cognition/client'

RSpec.describe Legion::Extensions::EnactiveCognition::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_sensorimotor_coupling)
    expect(client).to respond_to(:execute_enactive_action)
    expect(client).to respond_to(:adapt_sensorimotor_coupling)
    expect(client).to respond_to(:find_action_for_perception)
    expect(client).to respond_to(:coupled_sensorimotor_loops)
    expect(client).to respond_to(:domain_couplings)
    expect(client).to respond_to(:strongest_couplings)
    expect(client).to respond_to(:overall_enactive_coupling)
    expect(client).to respond_to(:update_enactive_cognition)
    expect(client).to respond_to(:enactive_cognition_stats)
  end
end
