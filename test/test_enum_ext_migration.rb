require 'test_helper'

class EnumExtMigrationTest < ActiveSupport::TestCase
  def run_migration
    ActiveRecord::Base.connection.create_table :enum_migration_checks do |t|
      t.integer :kind, default: EnumMigrationCheck.kinds[:working]
    end
  end

  if ActiveRecord::VERSION::MAJOR >= 7
    class EnumMigrationCheck < ActiveRecord::Base
      extend EnumExt
      enum :kinds, [:working, :broken], ext: :enum_i
    end
  else
    class EnumMigrationCheck < ActiveRecord::Base
      extend EnumExt

      enum kinds: [:working, :broken], ext: :enum_i
    end
  end

  test 'migration will not fail if enum_i helper defined' do
    assert_nothing_raised { run_migration }
  end
end



