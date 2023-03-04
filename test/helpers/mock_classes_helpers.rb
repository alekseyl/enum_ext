class EnumExtMock < ActiveRecord::Base
  extend EnumExt
  enum test_type: { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}

  has_many :enum_ext_mocks
  belongs_to :enum_ext_mock
end

class EnumExtMockClear < ActiveRecord::Base
  extend EnumExt

  has_many :enum_ext_mocks
  belongs_to :enum_ext_mock
end


module MockClassHelpers

  def build_mock_class
    Class.new(EnumExtMock) { self.table_name = :enum_ext_mocks }
  end

  def build_mock_class_without_enum
    Class.new(EnumExtMockClear) { self.table_name = :enum_ext_mocks }
  end

end
