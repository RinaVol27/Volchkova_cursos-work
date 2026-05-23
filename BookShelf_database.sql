-- 1. Таблица типов объявлений
CREATE TABLE Add_Type(
    add_type_id SERIAL PRIMARY KEY,
    type_name character(50) NOT NULL,
    type_description text NOT NULL,
    add_cost integer NOT NULL
);

--------------------------------------------------------------

-- 2. Таблица публикаций
CREATE TABLE Publication(
    publication_id SERIAL PRIMARY KEY,
    publication_name character(50) NOT NULL,
    add_type_id integer NOT NULL REFERENCES Add_Type(add_type_id) 
	ON UPDATE CASCADE ON DELETE CASCADE
);

--------------------------------------------------------------

-- 3. Таблица менеджеров рекламодателей
CREATE TABLE Advertiser_manager(
    manager_id SERIAL PRIMARY KEY,
    manager_name character(50) NOT NULL,
    manager_surname character(50) NOT NULL,
    manager_lastname character(50) NOT NULL,
    phone character(20) NOT NULL,
    email character(100) NOT NULL
);

--------------------------------------------------------------

-- 4. Таблица рекламодателей
CREATE TABLE Advertiser(
    advertiser_id SERIAL PRIMARY KEY,
    advertiser_name character(50) NOT NULL,
    manager_id integer NOT NULL REFERENCES Advertiser_manager(manager_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    city_town character(50) NOT NULL DEFAULT 'Москва',
    street character(50) NOT NULL,
    house_num integer NOT NULL
);

--------------------------------------------------------------

-- 5. Таблица заявок
CREATE TABLE Request(
    request_id SERIAL PRIMARY KEY,
    advertiser_id integer NOT NULL REFERENCES Advertiser(advertiser_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    add_type_id integer NOT NULL REFERENCES Add_Type(add_type_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    publication_id integer NOT NULL REFERENCES Publication(publication_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    num_publication integer NOT NULL,
    add_text text NOT NULL,
    have_a_photo boolean NOT NULL DEFAULT TRUE,
    additional_info text,
    creation_date date
);

--------------------------------------------------------------

-- 6. Таблица оплат
CREATE TABLE Payment(
    payment_id SERIAL PRIMARY KEY,
    request_id integer NOT NULL REFERENCES Request(request_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    payment_date date NOT NULL,
    amount integer NOT NULL
);

--------------------------------------------------------------

-- 7. Связующая таблица (многие-ко-многим)
CREATE TABLE Publication_Add_Type(
    publication_id INTEGER NOT NULL REFERENCES Publication(publication_id)
        ON DELETE CASCADE,
    add_type_id INTEGER NOT NULL REFERENCES Add_Type(add_type_id)
        ON DELETE CASCADE,
    PRIMARY KEY (publication_id, add_type_id)
);
