# frozen_string_literal: true

require 'legion/extensions/enactive_cognition/version'
require 'legion/extensions/enactive_cognition/helpers/sensorimotor_loop'
require 'legion/extensions/enactive_cognition/helpers/enaction_engine'
require 'legion/extensions/enactive_cognition/runners/enactive_cognition'

module Legion
  module Extensions
    module EnactiveCognition
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
