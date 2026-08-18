FactoryBot.define do
  factory :tag do
    name { Faker::ProgrammingLanguage.name }
    slug { name.parameterize }
  end
end
