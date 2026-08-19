FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "#{Faker::Lorem.sentence(word_count: 3)}-#{n}" }
    slug { title.parameterize }
    body { Faker::Lorem.paragraph(sentence_count: 5) }
    excerpt { Faker::Lorem.paragraph(sentence_count: 2) }
    status { :draft }
    published_at { nil }
    association :category

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :draft do
      status { :draft }
      published_at { nil }
    end
  end
end
