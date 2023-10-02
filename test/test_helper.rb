require 'active_record'
require 'minitest/autorun'
require 'enum_ext'
require 'byebug'
require 'stubberry'
require 'rails_sql_prettifier'
require 'amazing_print'

require_relative 'helpers/tally'
require_relative 'helpers/active_record_initializers'
require_relative 'helpers/mock_classes_helpers'

ActiveSupport::TestCase.include MockClassHelpers
Minitest.after_run {  ActiveRecord::Base.connection.drop_table :enum_ext_mocks }