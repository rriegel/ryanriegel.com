FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "#{Faker::ProgrammingLanguage.name}-#{n}" }
    slug { name.parameterize }
  end
end
