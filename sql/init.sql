-- CREATE DATABASE database_name;
-- USE database_name; 


-- To view the triggers, use this command: SHOW TRIGGERS FROM databasename;
-- To view the views, use: SHOW FULL TABLES IN databasename WHERE TABLE_TYPE = 'VIEW';


CREATE TABLE sponsor (
    id_sponsor INT PRIMARY KEY AUTO_INCREMENT,
    nameSponsor VARCHAR(255),
    descriptionSponsor VARCHAR(255),
    descriptionTitle VARCHAR(255),
    exclusiveUrl VARCHAR(255),
    site_web VARCHAR(255),
    facebook VARCHAR(255),
    instagram VARCHAR(255),
    linkedin VARCHAR(255),
    tiktok VARCHAR(255),
    kawai VARCHAR(255),
    whatsapp VARCHAR(255),
    x VARCHAR(255),
    lowSponsorLogo VARCHAR(255),
    highSponsorLogo VARCHAR(255),
    urlSponsor VARCHAR(255)
);

CREATE TABLE planData (
    id_planData INT PRIMARY KEY AUTO_INCREMENT,
    planName VARCHAR(20),
    planActive BOOLEAN,
    productsPerStore INT,
    storeQuantity INT,
    comunityQuantity INT,
    price DECIMAL(10,2),
    duration_months INT
);

CREATE TABLE sponsor_plan (
    id_sponsor_plan INT PRIMARY KEY AUTO_INCREMENT,
    sponsor_id INT NOT NULL,
    planData_id INT NOT NULL,
    quantity_purchased INT NOT NULL,
    purchased_date DATETIME,

    FOREIGN KEY (sponsor_id) REFERENCES sponsor(id_sponsor),
    FOREIGN KEY (planData_id) REFERENCES planData(id_planData)
);

-- Indexes
CREATE INDEX idx_sponsor_plan_sponsor ON sponsor_plan(sponsor_id);
CREATE INDEX idx_sponsor_plan_planData ON sponsor_plan(planData_id);

CREATE TABLE owner (
    id_owner INT PRIMARY KEY AUTO_INCREMENT,
    storeOwnerId VARCHAR(255),
    owner_name VARCHAR(100)
);

CREATE TABLE owner_sponsor_plan (
    id_owner_sponsor_plan INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT NOT NULL,
    sponsor_plan_id INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    observation TEXT,

    FOREIGN KEY (owner_id) REFERENCES owner(id_owner),
    FOREIGN KEY (sponsor_plan_id) REFERENCES sponsor_plan(id_sponsor_plan)
);

-- Index for validating date overlap
CREATE INDEX idx_owner_sponsor_plan_date ON owner_sponsor_plan (owner_id, start_date, end_date);

CREATE TABLE store (
    id_store INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT NOT NULL,
    storeId VARCHAR(255),
    storeCategory VARCHAR(100),
    storeName VARCHAR(100),
    shortDescription VARCHAR(255),
    isActive BOOLEAN,
    affiliatedStore BOOLEAN,
    productLinkStore BOOLEAN,
    storeAffiliatedLink VARCHAR(255),
    storeImage VARCHAR(255),
    store_creation_date DATETIME,

    FOREIGN KEY (owner_id) REFERENCES owner(id_owner)
);

CREATE TABLE users (
    id_user INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT,
    user_date DATETIME,
    FOREIGN KEY (owner_id) REFERENCES owner(id_owner)
);

CREATE TABLE community (
    id_community INT PRIMARY KEY AUTO_INCREMENT,
    placeId INT,
    bairro VARCHAR(100),
    cep VARCHAR(8),
    cidade VARCHAR(100),
    condominio VARCHAR(100),
    endereco VARCHAR(255),
    estado VARCHAR(100),
    geoPoint VARCHAR(255),
    locale VARCHAR(255),
    tipoLocal VARCHAR(100),
    owner_id INT,
    community_creation_date DATETIME,
    FOREIGN KEY (owner_id) REFERENCES owner(id_owner)
);

CREATE TABLE owner_community (
    owner_id INT,
    community_id INT,
    registration_date DATETIME,
    PRIMARY KEY (owner_id, community_id),
    FOREIGN KEY (owner_id) REFERENCES owner(id_owner),
    FOREIGN KEY (community_id) REFERENCES community(id_community)
);

CREATE TABLE users_community (
    user_id INT,
    community_id INT,
    PRIMARY KEY (user_id, community_id),
    FOREIGN KEY (user_id) REFERENCES users(id_user),
    FOREIGN KEY (community_id) REFERENCES community(id_community)
);

-- ------------------------


CREATE TABLE capture_candidate (
    id_cap_candidate INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL,
    birth_date DATE,
    candidate_age INT,
    gender VARCHAR(1),
    street VARCHAR(100),
    number VARCHAR(10),
    complement VARCHAR(255),
    state VARCHAR(50),
    city VARCHAR(50),
    phone VARCHAR(14),
    family_income DECIMAL(10,2),
    email VARCHAR(30),
    education_level VARCHAR(20),
    notification_method VARCHAR(10),
    postal_code VARCHAR(8),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE sponsorship_slot (
    id_slot INT PRIMARY KEY AUTO_INCREMENT,
    sponsor_plan_id INT,
    slot_state VARCHAR(50),
    slot_city VARCHAR(50),
    slot_max_income DECIMAL(10,2),
    slot_min_education_level VARCHAR(20),
    slot_quantity_available INT,
    slot_min_age INT, 
    FOREIGN KEY (sponsor_plan_id) REFERENCES sponsor_plan(id_sponsor_plan)
);


CREATE TABLE sponsorship_selection (
    id_selection INT PRIMARY KEY AUTO_INCREMENT,
    cap_candidate_id INT,
    slot_id INT,
    status_selection ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    selection_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATETIME,
    FOREIGN KEY (cap_candidate_id) REFERENCES capture_candidate(id_cap_candidate),
    FOREIGN KEY (slot_id) REFERENCES sponsorship_slot(id_slot)
);






