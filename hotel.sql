-- ============================================================
--  HOTEL MANAGEMENT SYSTEM — Complete SQL Schema + Data
--  70 hotels: 20 India + 50 International
-- ============================================================

-- ─────────────────────────────────────────────
-- LOOKUP / REFERENCE TABLES
-- ─────────────────────────────────────────────
create database Hotel1;
use Hotel1;

CREATE TABLE countries (
    country_id   SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code CHAR(2)      NOT NULL UNIQUE,
    region       VARCHAR(80)
);

CREATE TABLE amenity_types (
    amenity_id   SERIAL PRIMARY KEY,
    amenity_name VARCHAR(80)  NOT NULL,
    category     VARCHAR(50)  -- 'fitness','wellness','dining','tech','services'
);

-- ─────────────────────────────────────────────
-- CORE TABLES
-- ─────────────────────────────────────────────

CREATE TABLE hotels (
    hotel_id            SERIAL PRIMARY KEY,
    hotel_name          VARCHAR(150) NOT NULL,
    country_id          INT          NOT NULL REFERENCES countries(country_id),
    city                VARCHAR(100) NOT NULL,
    address             TEXT,
    latitude            DECIMAL(9,6),
    longitude           DECIMAL(9,6),
    star_rating         SMALLINT     CHECK (star_rating BETWEEN 1 AND 5),
    hotel_type          VARCHAR(50)  DEFAULT 'Hotel',  -- Hotel/Resort/Boutique/Hostel
    check_in_time       TIME         DEFAULT '14:00',
    check_out_time      TIME         DEFAULT '11:00',
    total_rooms         INT,
    website             VARCHAR(200),
    contact_email       VARCHAR(150),
    contact_phone       VARCHAR(30),
    created_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_types (
    room_type_id        SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    room_type_name      VARCHAR(80)  NOT NULL,  -- Standard/Deluxe/Suite/Presidential
    base_price_usd      DECIMAL(10,2) NOT NULL, -- price per night in USD
    base_price_inr      DECIMAL(12,2),           -- price per night in INR
    max_occupancy       SMALLINT,
    room_size_sqft      INT,
    has_ac              BOOLEAN      DEFAULT TRUE,
    ac_price_surcharge  DECIMAL(8,2) DEFAULT 0,  -- extra if AC is add-on
    has_balcony         BOOLEAN      DEFAULT FALSE,
    has_sea_view        BOOLEAN      DEFAULT FALSE,
    has_mountain_view   BOOLEAN      DEFAULT FALSE,
    bed_type            VARCHAR(50),  -- King/Queen/Twin/Double
    is_available        BOOLEAN      DEFAULT TRUE
);

CREATE TABLE meal_plans (
    meal_plan_id        SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    plan_name           VARCHAR(80)  NOT NULL,   -- 'Room Only','Breakfast','Half Board','Full Board','All Inclusive'
    breakfast_included  BOOLEAN      DEFAULT FALSE,
    lunch_included      BOOLEAN      DEFAULT FALSE,
    dinner_included     BOOLEAN      DEFAULT FALSE,
    price_per_night_usd DECIMAL(10,2) DEFAULT 0, -- additional cost per night
    price_per_night_inr DECIMAL(12,2) DEFAULT 0
);

CREATE TABLE discounts (
    discount_id         SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    discount_name       VARCHAR(100) NOT NULL,
    discount_type       VARCHAR(40)  NOT NULL,   -- 'seasonal','early_bird','last_minute','loyalty','promo'
    discount_percent    DECIMAL(5,2),            -- e.g. 20.00 = 20%
    discount_flat_usd   DECIMAL(10,2),           -- flat discount in USD
    min_nights          INT          DEFAULT 1,
    valid_from          DATE,
    valid_to            DATE,
    promo_code          VARCHAR(30),
    is_active           BOOLEAN      DEFAULT TRUE
);

CREATE TABLE nearby_attractions (
    attraction_id       SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    attraction_name     VARCHAR(150) NOT NULL,
    attraction_type     VARCHAR(80),  -- 'monument','beach','park','museum','shopping','temple','heritage'
    distance_km         DECIMAL(6,2),
    travel_time_min     INT,
    description         TEXT
);

CREATE TABLE hotel_amenities (
    id                  SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    amenity_id          INT          NOT NULL REFERENCES amenity_types(amenity_id),
    is_free             BOOLEAN      DEFAULT TRUE,
    extra_charge_usd    DECIMAL(8,2) DEFAULT 0,
    notes               VARCHAR(200)
);

-- ─────────────────────────────────────────────
-- BOOKINGS & REVIEWS (operational)
-- ─────────────────────────────────────────────

CREATE TABLE guests (
    guest_id            SERIAL PRIMARY KEY,
    full_name           VARCHAR(150) NOT NULL,
    email               VARCHAR(150) UNIQUE,
    phone               VARCHAR(30),
    nationality         VARCHAR(80),
    passport_no         VARCHAR(50),
    loyalty_tier        VARCHAR(20)  DEFAULT 'Bronze'  -- Bronze/Silver/Gold/Platinum
);

CREATE TABLE bookings (
    booking_id          SERIAL PRIMARY KEY,
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    room_type_id        INT          NOT NULL REFERENCES room_types(room_type_id),
    meal_plan_id        INT          REFERENCES meal_plans(meal_plan_id),
    guest_id            INT          NOT NULL REFERENCES guests(guest_id),
    discount_id         INT          REFERENCES discounts(discount_id),
    check_in_date       DATE         NOT NULL,
    check_out_date      DATE         NOT NULL,
    num_adults          SMALLINT     DEFAULT 2,
    num_children        SMALLINT     DEFAULT 0,
    room_price_usd      DECIMAL(10,2),
    meal_price_usd      DECIMAL(10,2) DEFAULT 0,
    discount_amount_usd DECIMAL(10,2) DEFAULT 0,
    total_price_usd     DECIMAL(10,2),
    status              VARCHAR(30)  DEFAULT 'Confirmed',  -- Confirmed/Checked-in/Checked-out/Cancelled
    booking_source      VARCHAR(50),  -- 'Direct','OTA','Agent'
    special_requests    TEXT,
    created_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    review_id           SERIAL PRIMARY KEY,
    booking_id          INT          NOT NULL REFERENCES bookings(booking_id),
    hotel_id            INT          NOT NULL REFERENCES hotels(hotel_id),
    guest_id            INT          NOT NULL REFERENCES guests(guest_id),
    overall_rating      DECIMAL(3,1) CHECK (overall_rating BETWEEN 1 AND 10),
    cleanliness_rating  DECIMAL(3,1),
    service_rating      DECIMAL(3,1),
    location_rating     DECIMAL(3,1),
    value_rating        DECIMAL(3,1),
    review_text         TEXT,
    reviewed_at         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────

CREATE INDEX idx_hotels_country   ON hotels(country_id);
CREATE INDEX idx_hotels_city      ON hotels(city);
CREATE INDEX idx_room_hotel       ON room_types(hotel_id);
CREATE INDEX idx_meal_hotel       ON meal_plans(hotel_id);
CREATE INDEX idx_disc_hotel       ON discounts(hotel_id);
CREATE INDEX idx_attr_hotel       ON nearby_attractions(hotel_id);
CREATE INDEX idx_booking_hotel    ON bookings(hotel_id);
CREATE INDEX idx_booking_dates    ON bookings(check_in_date, check_out_date);
CREATE INDEX idx_review_hotel     ON reviews(hotel_id);


-- ============================================================
-- DATA INSERTS
-- ============================================================

-- ─── COUNTRIES ────────────────────────────────────────────

INSERT INTO countries (country_name, country_code, region) VALUES
('India',           'IN', 'South Asia'),
('United States',   'US', 'North America'),
('United Kingdom',  'GB', 'Europe'),
('France',          'FR', 'Europe'),
('Italy',           'IT', 'Europe'),
('Spain',           'ES', 'Europe'),
('Germany',         'DE', 'Europe'),
('Japan',           'JP', 'East Asia'),
('China',           'CN', 'East Asia'),
('Australia',       'AU', 'Oceania'),
('United Arab Emirates', 'AE', 'Middle East'),
('Thailand',        'TH', 'Southeast Asia'),
('Singapore',       'SG', 'Southeast Asia'),
('Switzerland',     'CH', 'Europe'),
('Brazil',          'BR', 'South America'),
('South Africa',    'ZA', 'Africa'),
('Canada',          'CA', 'North America'),
('Greece',          'GR', 'Europe'),
('Turkey',          'TR', 'Middle East/Europe'),
('Mexico',          'MX', 'North America'),
('Indonesia',       'ID', 'Southeast Asia'),
('Morocco',         'MA', 'Africa'),
('Portugal',        'PT', 'Europe'),
('New Zealand',     'NZ', 'Oceania'),
('Egypt',           'EG', 'Africa'),
('Argentina',       'AR', 'South America'),
('Netherlands',     'NL', 'Europe'),
('Sweden',          'SE', 'Europe'),
('Vietnam',         'VN', 'Southeast Asia'),
('Kenya',           'KE', 'Africa');

-- ─── AMENITY TYPES ────────────────────────────────────────

INSERT INTO amenity_types (amenity_name, category) VALUES
('Swimming Pool',          'wellness'),
('Gym / Fitness Center',   'fitness'),
('Spa & Wellness Center',  'wellness'),
('Free Wi-Fi',             'tech'),
('Restaurant',             'dining'),
('Bar / Lounge',           'dining'),
('Room Service (24hr)',     'services'),
('Airport Shuttle',        'services'),
('Concierge Service',      'services'),
('Parking (Free)',         'services'),
('Parking (Paid)',         'services'),
('Business Center',        'tech'),
('Conference Rooms',       'tech'),
('Laundry / Dry Cleaning', 'services'),
('Kids Club',              'services'),
('Water Sports',           'fitness'),
('Tennis Court',           'fitness'),
('Golf Course',            'fitness'),
('Rooftop Terrace',        'wellness'),
('EV Charging Stations',   'services'),
('Pet Friendly',           'services'),
('Casino',                 'services'),
('Nightclub',              'services'),
('Private Beach Access',   'wellness'),
('Yoga / Meditation',      'wellness'),
('Shopping',               'services');

-- ============================================================
-- HOTELS: 20 INDIA  +  50 INTERNATIONAL
-- ============================================================

INSERT INTO hotels
 (hotel_name, country_id, city, address, latitude, longitude,
  star_rating, hotel_type, total_rooms)
VALUES

-- ── INDIA (20) ──────────────────────────────────────────────
-- 1
('Taj Mahal Palace',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Mumbai','Apollo Bunder, Colaba, Mumbai 400001',
  18.9219, 72.8330, 5, 'Hotel', 560),
-- 2
('The Oberoi Udaivilas',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Udaipur','Haridasji Ki Magri, Udaipur 313001',
  24.5722, 73.6750, 5, 'Resort', 87),
-- 3
('ITC Grand Chola',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Chennai','63 Mount Road, Guindy, Chennai 600032',
  13.0035, 80.2162, 5, 'Hotel', 522),
-- 4
('The Leela Palace Bengaluru',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Bengaluru','23 HAL Airport Road, Bengaluru 560008',
  12.9591, 77.6481, 5, 'Hotel', 357),
-- 5
('Rambagh Palace',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Jaipur','Bhawani Singh Rd, Jaipur 302005',
  26.8729, 75.8113, 5, 'Hotel', 79),
-- 6
('Ananda in the Himalayas',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Rishikesh','The Palace Estate, Narendra Nagar, Uttarakhand 249175',
  30.1661, 78.2832, 5, 'Resort', 75),
-- 7
('Wildflower Hall Shimla',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Shimla','Chharabra, Shimla, Himachal Pradesh 171012',
  31.1137, 77.2119, 5, 'Resort', 85),
-- 8
('The Taj Lake Palace',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Udaipur','Lake Pichola, Udaipur 313001',
  24.5758, 73.6808, 5, 'Hotel', 83),
-- 9
('JW Marriott Hotel New Delhi',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'New Delhi','Aerocity, IGI Airport, New Delhi 110037',
  28.5530, 77.0829, 5, 'Hotel', 511),
-- 10
('Taj Falaknuma Palace',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Hyderabad','Engine Bowli, Falaknuma, Hyderabad 500053',
  17.3315, 78.4692, 5, 'Hotel', 60),
-- 11
('The Leela Goa',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Goa','Mobor, Cavelossim, South Goa 403731',
  15.1719, 73.9500, 5, 'Resort', 206),
-- 12
('Kumarakom Lake Resort',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Kumarakom','Kumarakom, Kottayam, Kerala 686563',
  9.6158, 76.4296, 5, 'Resort', 100),
-- 13
('Samode Palace',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Jaipur','Samode, Chomu, Jaipur 303806',
  27.1667, 75.5833, 4, 'Hotel', 43),
-- 14
('The Park Hotel Kolkata',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Kolkata','17 Park Street, Kolkata 700016',
  22.5468, 88.3507, 5, 'Hotel', 154),
-- 15
('Radisson Blu Plaza Delhi',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'New Delhi','National Highway 8, Mahipalpur, New Delhi 110037',
  28.5512, 77.0842, 4, 'Hotel', 261),
-- 16
('Taj Exotica Resort Andaman',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Port Blair','Havelock Island, Andaman 744211',
  11.9784, 92.9967, 5, 'Resort', 63),
-- 17
('Vivanta Dal View Srinagar',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Srinagar','Gupkar Road, Srinagar, J&K 190001',
  34.0836, 74.8048, 5, 'Hotel', 94),
-- 18
('Hotel Clarks Varanasi',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Varanasi','The Mall, Varanasi 221002',
  25.3390, 82.9734, 4, 'Hotel', 127),
-- 19
('Aloft Bengaluru Cessna Business Park',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Bengaluru','Cessna Business Park, Sarjapur Road, Bengaluru 560103',
  12.9081, 77.6967, 4, 'Hotel', 187),
-- 20
('Club Mahindra Coorg',
  (SELECT country_id FROM countries WHERE country_code='IN'),
  'Coorg','Galibeedu, Madikeri, Coorg, Karnataka 571201',
  12.4244, 75.7382, 4, 'Resort', 84),

-- ── INTERNATIONAL (50) ──────────────────────────────────────
-- 21 USA
('The Beverly Hills Hotel',
  (SELECT country_id FROM countries WHERE country_code='US'),
  'Los Angeles','9641 Sunset Blvd, Beverly Hills, CA 90210',
  34.0874, -118.4125, 5, 'Hotel', 210),
-- 22 USA
('The Plaza Hotel New York',
  (SELECT country_id FROM countries WHERE country_code='US'),
  'New York','768 5th Ave, New York, NY 10019',
  40.7644, -73.9740, 5, 'Hotel', 282),
-- 23 USA
('Four Seasons Chicago',
  (SELECT country_id FROM countries WHERE country_code='US'),
  'Chicago','120 E Delaware Pl, Chicago, IL 60611',
  41.8997, -87.6270, 5, 'Hotel', 345),
-- 24 UK
('The Savoy London',
  (SELECT country_id FROM countries WHERE country_code='GB'),
  'London','Strand, London WC2R 0EU',
  51.5102, -0.1208, 5, 'Hotel', 267),
-- 25 UK
('Balmoral Hotel Edinburgh',
  (SELECT country_id FROM countries WHERE country_code='GB'),
  'Edinburgh','1 Princes St, Edinburgh EH2 2EQ',
  55.9516, -3.1920, 5, 'Hotel', 188),
-- 26 France
('Hotel Ritz Paris',
  (SELECT country_id FROM countries WHERE country_code='FR'),
  'Paris','15 Place Vendôme, 75001 Paris',
  48.8682, 2.3297, 5, 'Hotel', 142),
-- 27 France
('Chateau de la Messardiere Saint-Tropez',
  (SELECT country_id FROM countries WHERE country_code='FR'),
  'Saint-Tropez','Route de Tahiti, 83990 Saint-Tropez',
  43.2699, 6.6399, 5, 'Resort', 117),
-- 28 Italy
('Hotel Cipriani Venice',
  (SELECT country_id FROM countries WHERE country_code='IT'),
  'Venice','Giudecca 10, 30133 Venice',
  45.4250, 12.3376, 5, 'Hotel', 95),
-- 29 Italy
('Villa d\'Este Lake Como',
  (SELECT country_id FROM countries WHERE country_code='IT'),
  'Cernobbio','Via Regina 40, 22012 Cernobbio CO',
  45.8417, 9.0757, 5, 'Hotel', 152),
-- 30 Spain
('Hotel Arts Barcelona',
  (SELECT country_id FROM countries WHERE country_code='ES'),
  'Barcelona','Carrer de la Marina 19-21, 08005 Barcelona',
  41.3874, 2.1974, 5, 'Hotel', 483),
-- 31 Spain
('Alhambra Palace Hotel Granada',
  (SELECT country_id FROM countries WHERE country_code='ES'),
  'Granada','Pena Partida 2, 18009 Granada',
  37.1770, -3.5951, 4, 'Hotel', 126),
-- 32 Germany
('Hotel Adlon Kempinski Berlin',
  (SELECT country_id FROM countries WHERE country_code='DE'),
  'Berlin','Unter den Linden 77, 10117 Berlin',
  52.5164, 13.3812, 5, 'Hotel', 382),
-- 33 Japan
('The Ritz-Carlton Tokyo',
  (SELECT country_id FROM countries WHERE country_code='JP'),
  'Tokyo','Tokyo Midtown, 9-7-1 Akasaka, Minato 107-6245',
  35.6665, 139.7306, 5, 'Hotel', 248),
-- 34 Japan
('Aman Kyoto',
  (SELECT country_id FROM countries WHERE country_code='JP'),
  'Kyoto','Oaza Momoyama, Nagaokakyo-shi, Kyoto 617-0826',
  34.9250, 135.6973, 5, 'Resort', 26),
-- 35 UAE
('Burj Al Arab Jumeirah',
  (SELECT country_id FROM countries WHERE country_code='AE'),
  'Dubai','Jumeirah Beach Rd, Umm Suqeim 3, Dubai',
  25.1412, 55.1853, 5, 'Hotel', 202),
-- 36 UAE
('Atlantis The Palm Dubai',
  (SELECT country_id FROM countries WHERE country_code='AE'),
  'Dubai','Crescent Rd, The Palm, Dubai',
  25.1305, 55.1172, 5, 'Resort', 1548),
-- 37 Thailand
('The Peninsula Bangkok',
  (SELECT country_id FROM countries WHERE country_code='TH'),
  'Bangkok','333 Charoennakhon Road, Klongsan, Bangkok 10600',
  13.7239, 100.5108, 5, 'Hotel', 370),
-- 38 Thailand
('Anantara Koh Samui Resort',
  (SELECT country_id FROM countries WHERE country_code='TH'),
  'Koh Samui','99/9 Moo 2, Bophut, Koh Samui, Surat Thani 84320',
  9.5389, 100.0586, 5, 'Resort', 102),
-- 39 Singapore
('Marina Bay Sands Singapore',
  (SELECT country_id FROM countries WHERE country_code='SG'),
  'Singapore','10 Bayfront Ave, Singapore 018956',
  1.2834, 103.8607, 5, 'Hotel', 2561),
-- 40 Switzerland
('Badrutt\'s Palace Hotel St. Moritz',
  (SELECT country_id FROM countries WHERE country_code='CH'),
  'St. Moritz','Via Serlas 27, 7500 St. Moritz',
  46.4985, 9.8415, 5, 'Hotel', 157),
-- 41 Australia
('Park Hyatt Sydney',
  (SELECT country_id FROM countries WHERE country_code='AU'),
  'Sydney','7 Hickson Road, The Rocks, Sydney NSW 2000',
  -33.8568, 151.2094, 5, 'Hotel', 155),
-- 42 Australia
('Qualia Resort Hamilton Island',
  (SELECT country_id FROM countries WHERE country_code='AU'),
  'Hamilton Island','20 Whitsunday Blvd, Hamilton Island QLD 4803',
  -20.3539, 148.9531, 5, 'Resort', 60),
-- 43 South Africa
('Singita Sabi Sand Game Reserve',
  (SELECT country_id FROM countries WHERE country_code='ZA'),
  'Mpumalanga','Sabi Sand Game Reserve, Mpumalanga',
  -24.7940, 31.4756, 5, 'Resort', 16),
-- 44 Brazil
('Copacabana Palace Rio',
  (SELECT country_id FROM countries WHERE country_code='BR'),
  'Rio de Janeiro','Av. Atlântica 1702, Copacabana, Rio de Janeiro 22021-001',
  -22.9701, -43.1823, 5, 'Hotel', 239),
-- 45 Greece
('Mystique Santorini',
  (SELECT country_id FROM countries WHERE country_code='GR'),
  'Santorini','Oia 847 02, Santorini',
  36.4618, 25.3753, 5, 'Boutique', 41),
-- 46 Greece
('Blue Palace Crete',
  (SELECT country_id FROM countries WHERE country_code='GR'),
  'Crete','Plaka, Elounda, Crete 72053',
  35.2650, 25.7480, 5, 'Resort', 251),
-- 47 Turkey
('Çirağan Palace Kempinski Istanbul',
  (SELECT country_id FROM countries WHERE country_code='TR'),
  'Istanbul','Çırağan Cad. No.32, Beşiktaş, Istanbul 34349',
  41.0464, 29.0126, 5, 'Hotel', 310),
-- 48 Canada
('Fairmont Banff Springs',
  (SELECT country_id FROM countries WHERE country_code='CA'),
  'Banff','405 Spray Ave, Banff, AB T1L 1J4',
  51.1673, -115.5550, 5, 'Hotel', 764),
-- 49 Mexico
('One&Only Palmilla Los Cabos',
  (SELECT country_id FROM countries WHERE country_code='MX'),
  'Los Cabos','Km 7.5 Carretera Transpeninsular, San José del Cabo 23400',
  22.9477, -109.8463, 5, 'Resort', 172),
-- 50 Indonesia
('Four Seasons Resort Bali Sayan',
  (SELECT country_id FROM countries WHERE country_code='ID'),
  'Bali','Sayan, Ubud, Gianyar, Bali 80571',
  -8.5082, 115.2566, 5, 'Resort', 60),
-- 51 Indonesia
('Ayana Resort Bali',
  (SELECT country_id FROM countries WHERE country_code='ID'),
  'Bali','Jl. Karang Mas Sejahtera, Jimbaran, Bali 80364',
  -8.7817, 115.1393, 5, 'Resort', 290),
-- 52 Morocco
('La Mamounia Marrakech',
  (SELECT country_id FROM countries WHERE country_code='MA'),
  'Marrakech','Avenue Bab Jdid, 40040 Marrakech',
  31.6238, -7.9994, 5, 'Hotel', 209),
-- 53 Portugal
('Bela Vista Hotel Algarve',
  (SELECT country_id FROM countries WHERE country_code='PT'),
  'Portimão','Av. Tomás Cabreira, 8500-802 Praia da Rocha',
  37.1188, -8.5354, 5, 'Boutique', 36),
-- 54 New Zealand
('Eichardt\'s Private Hotel Queenstown',
  (SELECT country_id FROM countries WHERE country_code='NZ'),
  'Queenstown','2 Marine Parade, Queenstown 9300',
  -45.0302, 168.6616, 5, 'Boutique', 12),
-- 55 Egypt
('Sofitel Legend Old Cataract Aswan',
  (SELECT country_id FROM countries WHERE country_code='EG'),
  'Aswan','Abtal El Tahrir St., Aswan 81511',
  24.0784, 32.8930, 5, 'Hotel', 131),
-- 56 Argentina
('Palacio Duhau Park Hyatt Buenos Aires',
  (SELECT country_id FROM countries WHERE country_code='AR'),
  'Buenos Aires','Av. Alvear 1661, C1014AAD Buenos Aires',
  -34.5879, -58.3889, 5, 'Hotel', 165),
-- 57 Netherlands
('Hotel V Nesplein Amsterdam',
  (SELECT country_id FROM countries WHERE country_code='NL'),
  'Amsterdam','Nes 49, 1012 KD Amsterdam',
  52.3740, 4.8978, 4, 'Boutique', 79),
-- 58 Sweden
('Grand Hôtel Stockholm',
  (SELECT country_id FROM countries WHERE country_code='SE'),
  'Stockholm','S Blasieholmshamnen 8, 103 27 Stockholm',
  59.3301, 18.0731, 5, 'Hotel', 321),
-- 59 Vietnam
('Nam Hai Resort Hoi An',
  (SELECT country_id FROM countries WHERE country_code='VN'),
  'Hoi An','Block Ha My Dong B, Dien Duong, Dien Ban, Quang Nam 560000',
  15.9311, 108.2762, 5, 'Resort', 100),
-- 60 Kenya
('Giraffe Manor Nairobi',
  (SELECT country_id FROM countries WHERE country_code='KE'),
  'Nairobi','Gogo Falls Road, Karen, Nairobi',
  -1.3782, 36.7134, 5, 'Boutique', 12),
-- 61 China
('The Peninsula Shanghai',
  (SELECT country_id FROM countries WHERE country_code='CN'),
  'Shanghai','32 The Bund, 32 Zhongshan E 1st Rd, Huangpu, Shanghai 200002',
  31.2374, 121.4855, 5, 'Hotel', 235),
-- 62 China
('Aman Summer Palace Beijing',
  (SELECT country_id FROM countries WHERE country_code='CN'),
  'Beijing','1 Gongmenqian Street, Summer Palace, Beijing 100091',
  39.9999, 116.2701, 5, 'Hotel', 51),
-- 63 USA
('Amangiri Utah',
  (SELECT country_id FROM countries WHERE country_code='US'),
  'Canyon Point','1 Kayenta Rd, Canyon Point, UT 84741',
  37.0081, -111.6127, 5, 'Resort', 34),
-- 64 South Africa
('The Oyster Box Hotel Umhlanga',
  (SELECT country_id FROM countries WHERE country_code='ZA'),
  'Umhlanga','2 Lighthouse Rd, Umhlanga 4320',
  -29.7180, 31.0915, 5, 'Hotel', 86),
-- 65 France
('Les Airelles Courchevel',
  (SELECT country_id FROM countries WHERE country_code='FR'),
  'Courchevel','Jardin Alpin, 73120 Courchevel',
  45.4157, 6.6351, 5, 'Hotel', 38),
-- 66 Italy
('Belmond Hotel Caruso Ravello',
  (SELECT country_id FROM countries WHERE country_code='IT'),
  'Ravello','Piazza San Giovanni del Toro 2, 84010 Ravello SA',
  40.6481, 14.6134, 5, 'Hotel', 50),
-- 67 Thailand
('Amanpuri Phuket',
  (SELECT country_id FROM countries WHERE country_code='TH'),
  'Phuket','Pansea Beach, 83110 Phuket',
  7.9958, 98.2797, 5, 'Resort', 40),
-- 68 Singapore
('Capella Singapore Sentosa',
  (SELECT country_id FROM countries WHERE country_code='SG'),
  'Sentosa','1 The Knolls, Sentosa Island, Singapore 098297',
  1.2495, 103.8228, 5, 'Resort', 111),
-- 69 Mexico
('Amanyara Turks & Caicos (Mexico)',
  (SELECT country_id FROM countries WHERE country_code='MX'),
  'Cancun','Blvd Kukulcan Km 9.5, Zona Hotelera, Cancun 77500',
  21.1511, -86.8225, 5, 'Resort', 98),
-- 70 UAE
('Jumeirah Al Naseem Dubai',
  (SELECT country_id FROM countries WHERE country_code='AE'),
  'Dubai','Madinat Jumeirah, Umm Suqeim 3, Dubai',
  25.1306, 55.1937, 5, 'Resort', 430);


-- ─────────────────────────────────────────────
-- ROOM TYPES (sample for first 10 hotels)
-- ─────────────────────────────────────────────

INSERT INTO room_types
 (hotel_id, room_type_name, base_price_usd, base_price_inr, max_occupancy,
  room_size_sqft, has_ac, ac_price_surcharge, has_balcony, has_sea_view,
  has_mountain_view, bed_type)
VALUES
-- Taj Mahal Palace (1)
(1,'Standard Room',          350.00, 29150,  2, 380, TRUE,  0,   FALSE, FALSE, FALSE, 'King'),
(1,'Deluxe Room',            480.00, 39984,  2, 480, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(1,'Harbour View Suite',     850.00, 70805,  3, 750, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),
(1,'Presidential Suite',    4500.00,374850,  4,2200, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),

-- The Oberoi Udaivilas (2)
(2,'Premier Room',           550.00, 45815,  2, 530, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(2,'Luxury Suite Lake View', 900.00, 74970,  2, 850, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(2,'Kohinoor Suite',        3200.00,266560,  3,2100, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),

-- ITC Grand Chola (3)
(3,'ITC One Room',           220.00, 18326,  2, 400, TRUE,  0,   FALSE, FALSE, FALSE, 'King'),
(3,'Towers Room',            310.00, 25823,  2, 450, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(3,'Royal Suite',            900.00, 74970,  3, 900, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),

-- Ananda in the Himalayas (6)
(6,'Valley View Room',       420.00, 34986,  2, 400, TRUE,  0,   TRUE,  FALSE, TRUE,  'King'),
(6,'Deluxe Suite',           750.00, 62475,  2, 700, TRUE,  0,   TRUE,  FALSE, TRUE,  'King'),

-- Burj Al Arab (35)
(35,'Deluxe Suite',         2500.00,208250,  2, 780, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),
(35,'Panoramic Suite',      4800.00,399840,  2,1120, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),
(35,'Presidential Suite',  12000.00,999600,  4,8400, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),

-- The Plaza New York (22)
(22,'Classic Room',          800.00, 66640,  2, 420, TRUE,  0,   FALSE, FALSE, FALSE, 'Queen'),
(22,'Deluxe Park View',     1100.00, 91630,  2, 520, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(22,'Royal Plaza Suite',    4000.00,333200,  4,2400, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),

-- Aman Kyoto (34)
(34,'Garden Suite',         2200.00,183260,  2, 990, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(34,'Forest Suite',         3500.00,291550,  2,1400, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),

-- Marina Bay Sands (39)
(39,'Deluxe Room',           500.00, 41650,  2, 480, TRUE,  0,   FALSE, FALSE, FALSE, 'King'),
(39,'Premier Room City View',650.00, 54145,  2, 520, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),
(39,'Bay View Suite',       2200.00,183260,  3,1100, TRUE,  0,   TRUE,  TRUE,  FALSE, 'King'),

-- Samode Palace (13) - AC optional heritage
(13,'Heritage Room',         180.00, 14994,  2, 350, FALSE, 25,  FALSE, FALSE, FALSE, 'Double'),
(13,'Heritage Room with AC', 205.00, 17077,  2, 350, TRUE,  0,   FALSE, FALSE, FALSE, 'Double'),
(13,'Royal Suite',           380.00, 31654,  2, 800, TRUE,  0,   TRUE,  FALSE, FALSE, 'King'),

-- Club Mahindra Coorg (20) - non-AC budget option
(20,'Studio Room Non-AC',     90.00,  7497,  2, 300, FALSE, 15,  FALSE, FALSE, TRUE,  'Double'),
(20,'Studio Room AC',        105.00,  8748,  2, 300, TRUE,  0,   FALSE, FALSE, TRUE,  'Double'),
(20,'One Bedroom Apt AC',    160.00, 13328,  4, 550, TRUE,  0,   TRUE,  FALSE, TRUE,  'King');


-- ─────────────────────────────────────────────
-- MEAL PLANS
-- ─────────────────────────────────────────────

INSERT INTO meal_plans
 (hotel_id, plan_name, breakfast_included, lunch_included,
  dinner_included, price_per_night_usd, price_per_night_inr)
VALUES
(1, 'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(1, 'Breakfast',    TRUE,  FALSE, FALSE,  30,  2499),
(1, 'Half Board',   TRUE,  FALSE, TRUE,   65,  5415),
(1, 'Full Board',   TRUE,  TRUE,  TRUE,   95,  7916),

(2, 'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(2, 'Breakfast',    TRUE,  FALSE, FALSE,  45,  3749),
(2, 'All Inclusive',TRUE,  TRUE,  TRUE,  120,  9996),

(3, 'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(3, 'Breakfast',    TRUE,  FALSE, FALSE,  25,  2083),
(3, 'Half Board',   TRUE,  FALSE, TRUE,   55,  4582),

(6, 'Full Board',   TRUE,  TRUE,  TRUE,  180, 14994),
(6, 'Breakfast',    TRUE,  FALSE, FALSE,  55,  4582),

(35,'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(35,'Breakfast',    TRUE,  FALSE, FALSE,  80,  6664),
(35,'Half Board',   TRUE,  FALSE, TRUE,  180, 14994),

(22,'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(22,'Breakfast',    TRUE,  FALSE, FALSE,  55,  4582),

(39,'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(39,'Breakfast',    TRUE,  FALSE, FALSE,  40,  3332),
(39,'Half Board',   TRUE,  FALSE, TRUE,   90,  7497),

(13,'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(13,'Breakfast',    TRUE,  FALSE, FALSE,  18,  1499),
(13,'Full Board',   TRUE,  TRUE,  TRUE,   55,  4582),

(20,'Room Only',    FALSE, FALSE, FALSE,   0,     0),
(20,'Breakfast',    TRUE,  FALSE, FALSE,  12,   999),
(20,'Half Board',   TRUE,  FALSE, TRUE,   28,  2333);


-- ─────────────────────────────────────────────
-- DISCOUNTS
-- ─────────────────────────────────────────────

INSERT INTO discounts
 (hotel_id, discount_name, discount_type, discount_percent,
  discount_flat_usd, min_nights, valid_from, valid_to,
  promo_code, is_active)
VALUES
(1,'Monsoon Special',    'seasonal',    20.00, NULL, 2, '2025-06-01','2025-09-30','MONSOON25',   TRUE),
(1,'Diwali Offer',       'seasonal',    15.00, NULL, 3, '2025-10-15','2025-11-05','DIWALI25',    TRUE),
(1,'Early Bird 30-day',  'early_bird',  12.00, NULL, 2, '2025-01-01','2025-12-31','EARLY12',     TRUE),
(2,'Summer Escape',      'seasonal',    25.00, NULL, 3, '2025-04-01','2025-06-30','SUMMER25',    TRUE),
(2,'Last Minute Deal',   'last_minute', NULL, 50.00, 1, '2025-01-01','2025-12-31', NULL,         TRUE),
(3,'Loyalty Gold',       'loyalty',     18.00, NULL, 1, '2025-01-01','2025-12-31','GOLD18',      TRUE),
(5,'Heritage Stay',      'promo',       10.00, NULL, 2, '2025-01-01','2025-03-31','HERITAGE10',  FALSE),
(6,'Wellness Week',      'seasonal',    20.00, NULL, 5, '2025-01-01','2025-12-31','WELLNESS5',   TRUE),
(8,'Palace Romance',     'promo',       15.00, NULL, 2, '2025-02-01','2025-02-28','ROMANCE15',   TRUE),
(11,'Goa Summer Save',   'seasonal',    30.00, NULL, 2, '2025-05-01','2025-09-30','GOASAVE30',   TRUE),
(12,'Backwaters Escape', 'seasonal',    20.00, NULL, 3, '2025-07-01','2025-08-31','KERALA20',    TRUE),
(20,'Club Member',       'loyalty',     10.00, NULL, 1, '2025-01-01','2025-12-31','CLUB10',      TRUE),
(35,'Ramadan Special',   'seasonal',    15.00, NULL, 3, '2025-03-01','2025-04-15','RAMADAN15',   TRUE),
(35,'Flash Sale',        'last_minute', 20.00, NULL, 1, '2025-01-01','2025-12-31', NULL,         TRUE),
(22,'NYC Winter',        'seasonal',    25.00, NULL, 2, '2025-12-01','2026-02-28','NYCWIN25',    TRUE),
(26,'Paris Romance',     'promo',       10.00, NULL, 2, '2025-02-10','2025-02-16','PARISLOVE',   TRUE),
(39,'MBS Staycay',       'seasonal',    15.00, NULL, 2, '2025-06-01','2025-08-31','MBSSTAY',     TRUE),
(40,'Ski Season',        'seasonal',    NULL, 200.00,4, '2025-12-15','2026-03-15','SKIPACK',     TRUE),
(48,'Canada Summer',     'seasonal',    20.00, NULL, 3, '2025-06-15','2025-09-15','CANADA20',    TRUE),
(60,'Safari Season',     'seasonal',    25.00, NULL, 4, '2025-07-01','2025-10-31','SAFARI25',    TRUE);


-- ─────────────────────────────────────────────
-- NEARBY ATTRACTIONS
-- ─────────────────────────────────────────────

INSERT INTO nearby_attractions
 (hotel_id, attraction_name, attraction_type, distance_km, travel_time_min, description)
VALUES
-- India
(1,'Gateway of India',          'monument',  0.3,  5,  'Iconic arch monument on Mumbai harbour waterfront'),
(1,'Elephanta Caves',           'heritage',  9.0, 60,  'UNESCO rock-cut cave temples accessible by ferry'),
(1,'Colaba Causeway Market',    'shopping',  0.5,  8,  'Vibrant street market for antiques and fashion'),
(2,'Lake Pichola',              'nature',    1.0, 10,  'Stunning artificial lake with palace islands'),
(2,'City Palace Udaipur',       'heritage',  2.0, 15,  'Largest palace complex in Rajasthan'),
(2,'Monsoon Palace',            'heritage',  5.0, 20,  'Hilltop palace with panoramic sunset views'),
(3,'Marina Beach',              'beach',     4.0, 15,  'World\'s second longest urban beach'),
(3,'Kapaleeshwarar Temple',     'temple',    5.0, 20,  'Ancient 7th century Dravidian architecture temple'),
(5,'Amber Fort',                'heritage',  9.0, 25,  'Majestic Mughal-Rajput hilltop fort'),
(5,'Hawa Mahal',                'monument',  4.0, 15,  'Palace of Winds — iconic Jaipur landmark'),
(5,'Jantar Mantar',             'monument',  4.5, 15,  'UNESCO astronomical observatory built in 1734'),
(6,'Triveni Ghat',              'temple',   12.0, 20,  'Sacred riverside ghat for evening Ganga Aarti'),
(6,'Neelkanth Mahadev Temple',  'temple',   20.0, 45,  'Ancient Shiva temple in dense forest'),
(8,'Lake Pichola Boat Tour',    'nature',    0.1,  2,  'Scenic boat ride around Pichola lake'),
(10,'Charminar',                'monument',  7.0, 20,  'Iconic 1591 mosque and monument'),
(10,'Golconda Fort',            'heritage', 11.0, 30,  'Magnificent medieval fort with echo acoustics'),
(11,'Colva Beach',              'beach',     8.0, 20,  'Popular beach with water sports and shacks'),
(12,'Kumarakom Bird Sanctuary', 'nature',    0.5,  5,  'Rare migratory bird paradise on Vembanad Lake'),
(12,'Houseboat Cruise Alleppey','nature',   10.0, 25,  'Iconic Kerala backwaters houseboat experience'),
(15,'India Gate',               'monument',  8.0, 20,  'World War I memorial and national icon'),
(15,'Qutub Minar',              'heritage', 14.0, 30,  'UNESCO 73m tall minaret from 12th century'),
(16,'Radhanagar Beach',         'beach',     2.0, 10,  'Rated Asia\'s best beach — pristine white sands'),
(17,'Dal Lake Shikara Ride',    'nature',    1.5,  8,  'Traditional wooden boat ride on Dal Lake'),
(17,'Shankaracharya Temple',    'temple',    3.0, 15,  'Ancient hilltop temple with valley views'),
(18,'Kashi Vishwanath Temple',  'temple',    2.0,  8,  'One of Hinduism\'s holiest Shiva temples'),
(18,'Sarnath',                  'heritage',  9.0, 25,  'Where Buddha gave his first sermon — Buddhist site'),

-- International
(22,'Central Park',             'park',      0.5,  5,  'NYC\'s iconic 843-acre green lung'),
(22,'The Met Museum',           'museum',    0.8,  8,  'One of the world\'s largest art museums'),
(24,'Trafalgar Square',         'monument',  0.8, 10,  'London\'s central public square with Nelson\'s Column'),
(24,'National Gallery London',  'museum',    0.9, 10,  'Vast collection of Western European art 1250–1900'),
(26,'Eiffel Tower',             'monument',  2.5, 15,  'Paris\'s 330m tall iron lattice tower'),
(26,'Louvre Museum',            'museum',    1.0,  8,  'World\'s most visited art museum, home of Mona Lisa'),
(28,'St. Mark\'s Basilica',     'heritage',  0.5,  5,  'Stunning Byzantine cathedral on St Mark\'s Square'),
(28,'Grand Canal Venice',       'nature',    0.3,  3,  'Main waterway through Venice, best by gondola'),
(33,'Tokyo Tower',              'monument',  1.5, 10,  'Tokyo\'s 333m communications and observation tower'),
(33,'Tsukiji Outer Market',     'shopping',  2.0, 12,  'World-famous fish market and street food stalls'),
(35,'Dubai Mall',               'shopping',  2.5, 10,  'World\'s largest mall with aquarium & ice rink'),
(35,'Burj Khalifa',             'monument',  2.5, 10,  'World\'s tallest building at 828m'),
(37,'Grand Palace Bangkok',     'heritage',  3.0, 20,  'Former royal residence, ornate Thai architecture'),
(37,'Wat Pho Temple',           'temple',    3.5, 20,  'Giant Reclining Buddha temple complex'),
(39,'Gardens by the Bay',       'park',      0.5,  5,  'Futuristic garden with Supertree Grove'),
(39,'Merlion Park',             'monument',  0.3,  3,  'Singapore\'s iconic half-lion half-fish statue'),
(41,'Sydney Opera House',       'monument',  0.5,  5,  'UNESCO World Heritage performing arts centre'),
(41,'Sydney Harbour Bridge',    'monument',  0.8,  8,  'Iconic steel arch bridge — climb to the top'),
(44,'Copacabana Beach',         'beach',     0.1,  2,  'Rio\'s famous 4km Atlantic beach'),
(44,'Christ the Redeemer',      'monument',  8.0, 30,  'Iconic 38m Art Deco statue atop Corcovado'),
(45,'Caldera View Oia',         'nature',    0.5,  5,  'World-famous Santorini caldera sunset views'),
(45,'Ancient Thera',            'heritage',  5.0, 20,  'Hellenistic and Roman ruins on the cliff top'),
(48,'Banff National Park',      'nature',    0.5,  5,  'UNESCO wilderness with turquoise lakes and glaciers'),
(48,'Lake Louise',              'nature',   55.0, 60,  'Iconic turquoise glacial lake surrounded by peaks'),
(52,'Djemaa el-Fna Square',     'heritage',  1.5,  8,  'Marrakech\'s legendary market square & medina'),
(52,'Bahia Palace',             'heritage',  1.0,  6,  'Magnificent 19th century riad-style palace'),
(55,'Temple of Karnak Luxor',   'heritage', 65.0, 70,  'Largest ancient religious site in the world'),
(55,'Aswan High Dam',           'heritage',  8.0, 20,  'Soviet-built Nile dam, monument to modern Egypt'),
(60,'Giraffe Centre Nairobi',   'nature',    1.0,  5,  'Endangered Rothschild giraffes roaming freely'),
(60,'Nairobi National Park',    'nature',    7.0, 20,  'Africa\'s only game reserve within a capital city');


-- ─────────────────────────────────────────────
-- HOTEL AMENITIES
-- ─────────────────────────────────────────────

INSERT INTO hotel_amenities (hotel_id, amenity_id, is_free, extra_charge_usd, notes)
VALUES
-- Taj Mahal Palace (1)
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'Outdoor infinity pool'),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    '24-hour fitness center'),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  FALSE, 80,   'Jiva Spa'),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    '5 restaurants including Wasabi'),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Bar / Lounge'),           TRUE,  0,    'Harbour Bar'),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Room Service (24hr)'),    TRUE,  0,    NULL),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Airport Shuttle'),        FALSE, 30,   NULL),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Concierge Service'),      TRUE,  0,    NULL),
(1, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Business Center'),        TRUE,  0,    NULL),

-- Ananda in the Himalayas (6)
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'Heated pool with Himalayan views'),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    NULL),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  TRUE,  0,    'Signature Ananda Spa'),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Yoga / Meditation'),      TRUE,  0,    'Daily yoga by Ganges-view pavilion'),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    NULL),
(6, (SELECT amenity_id FROM amenity_types WHERE amenity_name='Tennis Court'),           TRUE,  0,    NULL),

-- Burj Al Arab (35)
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'Private beach pool & leisure pool'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    '24hr club'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  FALSE, 200,  'Talise Spa'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Private Beach Access'),   TRUE,  0,    '300m private beach'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    '7 restaurants including Al Mahara'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Bar / Lounge'),           TRUE,  0,    'Skyview Bar at 200m height'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Room Service (24hr)'),    TRUE,  0,    'Butler service in all suites'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Airport Shuttle'),        TRUE,  0,    'Rolls-Royce fleet & helicopter transfers'),
(35,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Water Sports'),           FALSE, 50,   'Jet ski, parasailing, diving'),

-- Marina Bay Sands (39)
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'World-famous 150m infinity pool on rooftop'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    NULL),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  FALSE, 120,  'Banyan Tree Spa'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Casino'),                 FALSE, 100,  '15,000 sq ft casino floor'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    'CUT by Wolfgang Puck & more'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Rooftop Terrace'),        TRUE,  0,    'SkyPark observation deck'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Business Center'),        TRUE,  0,    'Sands Expo Convention Center'),
(39,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Shopping'),               TRUE,  0,    'The Shoppes at Marina Bay Sands'),

-- The Leela Goa (11)
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    '4 pools including lagoon pool'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Private Beach Access'),   TRUE,  0,    '1.5km private beach'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Water Sports'),           FALSE, 40,   'Parasailing, kayaking, windsurfing'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  FALSE, 90,   'ESPA Spa'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    NULL),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    'Multiple dining options'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Kids Club'),              TRUE,  0,    'Supervised kids activities'),
(11,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Tennis Court'),           TRUE,  0,    'Floodlit courts'),

-- Aman Kyoto (34)
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'Heated indoor pool'),
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  TRUE,  0,    'Onsen-style bathing pavilion'),
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Yoga / Meditation'),      TRUE,  0,    'Forest meditation walks'),
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    'Kaiseki dining room'),
(34,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    NULL),

-- Park Hyatt Sydney (41)
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool'),          TRUE,  0,    'Outdoor pool with Opera House view'),
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center'),   TRUE,  0,    NULL),
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Spa & Wellness Center'),  FALSE, 100,  'ESPRIT Spa'),
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Free Wi-Fi'),             TRUE,  0,    NULL),
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Restaurant'),             TRUE,  0,    'The Dining Room & Bar Blu'),
(41,(SELECT amenity_id FROM amenity_types WHERE amenity_name='Parking (Paid)'),         FALSE, 60,   'Valet parking per night');


-- ─────────────────────────────────────────────
-- SAMPLE GUESTS + BOOKINGS
-- ─────────────────────────────────────────────

INSERT INTO guests (full_name, email, phone, nationality, loyalty_tier) VALUES
('Arnab Ghosh',       'arnab.ghosh@email.com',   '+91-9800000001', 'Indian',    'Gold'),
('Priya Sharma',      'priya.s@email.com',        '+91-9800000002', 'Indian',    'Silver'),
('James Mitchell',    'james.m@email.com',        '+1-2125550001',  'American',  'Platinum'),
('Sophie Laurent',    'sophie.l@email.com',       '+33-612345678',  'French',    'Bronze'),
('Hiroshi Tanaka',    'h.tanaka@email.com',       '+81-9012345678', 'Japanese',  'Gold'),
('Aisha Al-Rashed',   'aisha.r@email.com',        '+971-501234567', 'Emirati',   'Silver'),
('Carlos Fernandez',  'carlos.f@email.com',       '+34-612345678',  'Spanish',   'Bronze'),
('Emily Chen',        'emily.c@email.com',        '+65-91234567',   'Singaporean','Gold');

INSERT INTO bookings
 (hotel_id, room_type_id, meal_plan_id, guest_id, discount_id,
  check_in_date, check_out_date, num_adults, num_children,
  room_price_usd, meal_price_usd, discount_amount_usd,
  total_price_usd, status, booking_source)
VALUES
(1,  1,  1,  1, 1,  '2025-08-10','2025-08-13', 2, 0, 1050,  0, 210, 840,  'Confirmed',  'Direct'),
(2,  5,  6,  2, 4,  '2025-05-20','2025-05-24', 2, 1, 2200, 180, 550, 1830, 'Checked-out','OTA'),
(35, 13, 13, 3, 12, '2025-03-15','2025-03-18', 2, 0, 7500,   0,1500, 6000, 'Confirmed',  'Direct'),
(22, 16, 17, 4, 15, '2025-12-20','2025-12-26', 2, 1, 4800, 330,1200, 3930, 'Confirmed',  'Agent'),
(34, 19, NULL,5,NULL,'2025-10-01','2025-10-05', 2, 0, 8800,   0,   0, 8800, 'Confirmed',  'Direct'),
(39, 22, 20, 6, 17, '2025-07-04','2025-07-07', 2, 0, 1950, 120, 293, 1778, 'Confirmed',  'OTA'),
(6,  11, 11, 1, 6,  '2025-04-10','2025-04-17', 2, 0, 2940,1260, 840, 3360, 'Checked-out','Direct'),
(11, 37, 23, 7, 11, '2025-09-15','2025-09-19', 2, 2, 1080, 112, 360, 832,  'Confirmed',  'OTA');

INSERT INTO reviews
 (booking_id, hotel_id, guest_id, overall_rating,
  cleanliness_rating, service_rating, location_rating,
  value_rating, review_text)
VALUES
(2, 2, 2, 9.5, 9.8, 9.7, 9.2, 8.8,
 'Absolutely stunning views of Lake Pichola. The service was impeccable and the royal heritage feel was beyond expectations.'),
(7, 6, 1, 9.8, 9.5, 9.9, 9.0, 8.5,
 'The Ananda experience is transformative. Yoga sessions overlooking the Himalayas and Ganga Aarti were spiritual highlights.'),
(6, 39, 6, 9.2, 9.0, 9.3, 9.8, 8.7,
 'Infinity pool at 57 floors with views of the bay is absolutely iconic. Best hotel pool experience in the world.');


-- ─────────────────────────────────────────────
-- USEFUL VIEWS FOR COMMON QUERIES
-- ─────────────────────────────────────────────

-- Full hotel summary with country & best room price
-- Full hotel summary with country & best room price
CREATE VIEW vw_hotel_summary AS
SELECT
    h.hotel_id,
    h.hotel_name,
    c.country_name,
    c.region,
    h.city,
    h.star_rating,
    h.hotel_type,
    h.total_rooms,
    MIN(rt.base_price_usd)  AS min_price_usd,
    MAX(rt.base_price_usd)  AS max_price_usd,
    MIN(rt.base_price_inr)  AS min_price_inr,
    MAX(rt.has_ac)          AS has_ac_rooms,     -- Changed from BOOL_OR
    MAX(NOT rt.has_ac)      AS has_non_ac_rooms  -- Changed from BOOL_OR
FROM hotels h
JOIN countries c   ON c.country_id  = h.country_id
LEFT JOIN room_types rt ON rt.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name, c.country_name, c.region, h.city,
         h.star_rating, h.hotel_type, h.total_rooms;
         
-- Hotels with amenities as comma-separated list
CREATE VIEW vw_hotel_amenities_summary AS
SELECT
    h.hotel_id,
    h.hotel_name,
    GROUP_CONCAT(at.amenity_name ORDER BY at.category, at.amenity_name SEPARATOR ', ') AS amenities,
    GROUP_CONCAT(CASE WHEN ha.is_free THEN at.amenity_name END ORDER BY at.amenity_name SEPARATOR ', ') AS free_amenities
FROM hotels h
JOIN hotel_amenities ha ON ha.hotel_id  = h.hotel_id
JOIN amenity_types   at ON at.amenity_id = ha.amenity_id
GROUP BY h.hotel_id, h.hotel_name;

-- Active discounts with hotel info
CREATE VIEW vw_active_deals AS
SELECT
    h.hotel_name,
    c.country_name,
    h.city,
    d.discount_name,
    d.discount_type,
    COALESCE(
        CONCAT(CAST(d.discount_percent AS CHAR), '%'), 
        CONCAT('$', CAST(d.discount_flat_usd AS CHAR))
    ) AS discount_value,
    d.valid_from,
    d.valid_to,
    d.promo_code
FROM discounts d
JOIN hotels    h ON h.hotel_id  = d.hotel_id
JOIN countries c ON c.country_id = h.country_id
WHERE d.is_active = TRUE
  AND (d.valid_to IS NULL OR d.valid_to >= CURRENT_DATE());
  
-- Nearby attractions per hotel
CREATE VIEW vw_hotel_attractions AS
SELECT
    h.hotel_id,
    h.hotel_name,
    h.city,
    c.country_name,
    na.attraction_name,
    na.attraction_type,
    na.distance_km,
    na.travel_time_min,
    na.description
FROM nearby_attractions na
JOIN hotels    h ON h.hotel_id  = na.hotel_id
JOIN countries c ON c.country_id = h.country_id
ORDER BY h.hotel_id, na.distance_km;

-- Full booking details with guest, hotel, room & discount
CREATE VIEW vw_booking_details AS
SELECT
    b.booking_id,
    g.full_name            AS guest_name,
    g.loyalty_tier,
    h.hotel_name,
    c.country_name,
    h.city,
    rt.room_type_name,
    rt.has_ac,
    mp.plan_name           AS meal_plan,
    mp.breakfast_included,
    mp.dinner_included,
    b.check_in_date,
    b.check_out_date,
    (b.check_out_date - b.check_in_date) AS nights,
    b.room_price_usd,
    b.meal_price_usd,
    b.discount_amount_usd,
    b.total_price_usd,
    b.status,
    d.discount_name,
    d.promo_code
FROM bookings b
JOIN guests     g  ON g.guest_id    = b.guest_id
JOIN hotels     h  ON h.hotel_id    = b.hotel_id
JOIN countries  c  ON c.country_id  = h.country_id
JOIN room_types rt ON rt.room_type_id = b.room_type_id
LEFT JOIN meal_plans mp ON mp.meal_plan_id = b.meal_plan_id
LEFT JOIN discounts  d  ON d.discount_id   = b.discount_id;


-- ─────────────────────────────────────────────
-- EXAMPLE QUERIES TO FETCH DATA
-- ─────────────────────────────────────────────

-- 1. All hotels in India with price range
SELECT hotel_name, city, star_rating, min_price_usd, max_price_usd
FROM vw_hotel_summary
WHERE country_name = 'India'
ORDER BY min_price_usd;

-- 2. Hotels with gym + pool + free wifi
-- SELECT DISTINCT h.hotel_name, h.city, c.country_name
-- FROM hotels h
-- JOIN countries c ON c.country_id = h.country_id
-- WHERE h.hotel_id IN (
--   SELECT hotel_id FROM hotel_amenities WHERE amenity_id =
--     (SELECT amenity_id FROM amenity_types WHERE amenity_name='Gym / Fitness Center')
-- )
-- AND h.hotel_id IN (
--   SELECT hotel_id FROM hotel_amenities WHERE amenity_id =
--     (SELECT amenity_id FROM amenity_types WHERE amenity_name='Swimming Pool')
-- );

-- 3. All current active discount deals
-- SELECT * FROM vw_active_deals ORDER BY discount_value DESC;

-- 4. Hotels near famous monuments within 5km
-- SELECT hotel_name, city, country_name, attraction_name, distance_km
-- FROM vw_hotel_attractions
-- WHERE distance_km <= 5
-- ORDER BY distance_km;

-- 5.Price difference AC vs Non-AC (same hotel)
SELECT hotel_id, room_type_name, has_ac, base_price_usd, ac_price_surcharge
FROM room_types
WHERE hotel_id IN (SELECT hotel_id FROM room_types WHERE has_ac = FALSE)
ORDER BY hotel_id, has_ac;

-- 6. Breakfast-included rooms under $300/night
-- SELECT h.hotel_name, h.city, c.country_name,
--        rt.room_type_name, rt.base_price_usd,
--        (rt.base_price_usd + mp.price_per_night_usd) AS total_with_breakfast
-- FROM room_types rt
-- JOIN hotels h ON h.hotel_id = rt.hotel_id
-- JOIN countries c ON c.country_id = h.country_id
-- JOIN meal_plans mp ON mp.hotel_id = h.hotel_id AND mp.breakfast_included = TRUE
-- WHERE rt.base_price_usd + mp.price_per_night_usd < 300
-- ORDER BY total_with_breakfast;

-- 7. Full booking summary
SELECT * FROM vw_booking_details ORDER BY check_in_date;

SELECT * FROM vw_hotel_summary;