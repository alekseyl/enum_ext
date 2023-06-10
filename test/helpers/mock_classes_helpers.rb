class EnumExtMock < ActiveRecord::Base
  extend EnumExt
end

class MassAssignTestClass < EnumExtMock
  has_many :enum_ext_mocks, class_name: :MassAssignTestClass, foreign_key: :enum_ext_mock_id
  belongs_to :enum_ext_mock, class_name: :MassAssignTestClass, foreign_key: :enum_ext_mock_id

  self.table_name = :enum_ext_mocks
  self.enum test_type: { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}
end

module MockClassHelpers

  def build_mock_class
    Class.new(EnumExtMock) do
      self.enum test_type: { unit_test: 0, spec: 1, view: 2, controller: 3, integration: 4}
    end
  end

  def build_mock_class_without_enum
    Class.new(EnumExtMock) { self.table_name = :enum_ext_mocks }
  end

end
