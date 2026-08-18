FactoryBot.define do
  factory :category do
    name { Faker::Commerce.department }
    slug { name.parameterize }
  end
end
