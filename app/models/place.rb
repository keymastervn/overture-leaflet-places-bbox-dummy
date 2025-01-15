# frozen_string_literal: true

class Place < ApplicationRecord
  attribute :geopoint, :st_point, srid: 4326, geographic: true

  scope :by_primary_category, ->(category) { where(primary_categories: category) }

  # Scope for filtering by alternate categories
  scope :by_alternate_category, ->(category) { where("'#{category}' = ANY (alternate_categories)") }

  # overly copy all G types into O
  # because Overture has lower coverage compared to Google
  CATEGORY_MAPPING = {
    'Entertainment and Recreation' => {
      'google' => %w[
        amusement_center
        amusement_park
        aquarium
        banquet_hall
        bowling_alley
        casino
        convention_center
        event_venue
        movie_theater
        night_club
        wedding_venue
        zoo
      ],
      'overture' => %w[
        attractions_and_activities
        arts_and_entertainment
      ]
    },
    'Lodging' => {
      'google' => %w[
        bed_and_breakfast
        campground
        camping_cabin
        cottage
        extended_stay_hotel
        farmstay
        guest_house
        hostel
        hotel
        lodging
        motel
        private_guest_room
        resort_hotel
        rv_park
      ],
      'overture' => %w[
        accommodation
      ]
    },
    'Sports' => {
      'google' => %w[stadium],
      'overture' => %w[active_life]
    },
    'Services' => {
      'google' => %w[
        barber_shop
        beauty_salon
        florist
      ],
      'overture' => %w[beauty_and_spa]
    },
    # https://chatgpt.com/share/67878e3c-898c-800f-923e-4fb09b69b3a1
    'Food and Drink' => {
      'google' => %w[
        american_restaurant
        bakery
        bar
        barbecue_restaurant
        brazilian_restaurant
        breakfast_restaurant
        brunch_restaurant
        cafe
        chinese_restaurant
        coffee_shop
        fast_food_restaurant
        french_restaurant
        greek_restaurant
        hamburger_restaurant
        ice_cream_shop
        indian_restaurant
        indonesian_restaurant
        italian_restaurant
        japanese_restaurant
        korean_restaurant
        lebanese_restaurant
        meal_delivery
        meal_takeaway
        mediterranean_restaurant
        mexican_restaurant
        middle_eastern_restaurant
        pizza_restaurant
        ramen_restaurant
        restaurant
        sandwich_shop
        seafood_restaurant
        spanish_restaurant
        steak_house
        sushi_restaurant
        thai_restaurant
        turkish_restaurant
        vegan_restaurant
        vegetarian_restaurant
        vietnamese_restaurant
      ],
      'overture' => %w[
        eat_and_drink
        american_restaurant
        brazilian_restaurant
        bar
        barbecue_restaurant
        breakfast_and_brunch_restaurant
        cafe
        chinese_restaurant
        coffee_shop
        fast_food_restaurant
        french_restaurant
        greek_restaurant
        hamburger_restaurant
        indian_restaurant
        indonesian_restaurant
        italian_restaurant
        japanese_restaurant
        korean_restaurant
        lebanese_restaurant
        mediterranean_restaurant
        mexican_restaurant
        middle_eastern_restaurant
        pizza_restaurant
        restaurant
        sandwich_shop
        seafood_restaurant
        spanish_restaurant
        steakhouse
        sushi_restaurant
        thai_restaurant
        turkish_restaurant
        vegan_restaurant
        vegetarian_restaurant
        vietnamese_restaurant
      ]
    },
    'Shopping' => {
      'google' => %w[
        bicycle_store
        book_store
        cell_phone_store
        clothing_store
        convenience_store
        department_store
        discount_store
        electronics_store
        furniture_store
        gift_shop
        grocery_store
        hardware_store
        home_goods_store
        home_improvement_store
        jewelry_store
        liquor_store
        market
        pet_store
        shoe_store
        shopping_mall
        sporting_goods_store
        store
        supermarket
        wholesaler
      ],
      'overture' => %w[
        retail
        bicycle_shop
        bookstore
        mobile_phone_store
        clothing_store
        convenience_store
        department_store
        discount_store
        electronics
        furniture_store
        gift_shop
        grocery_store
        hardware_store
        home_goods_store
        home_improvement_store
        jewelry_store
        liquor_store
        farmers_market
        public_market
        pet_store
        shoe_store
        shopping_center
        sporting_goods
        supermarket
        wholesale_store
      ]
    }
  }.freeze
end
