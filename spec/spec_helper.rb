$:.unshift(File.expand_path("../../", __FILE__))
require "lib/epub"

def root_folder
  File.expand_path("../../", __FILE__)
end

Dir[ File.join(root_folder, "spec/support/**/*.rb") ].each {|f| require f}

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.include(FixtureHelpers)

end