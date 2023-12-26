CREATE TABLE authentication (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE merchants (
    id SERIAL PRIMARY KEY,
    authentication_id INT UNIQUE NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_category VARCHAR(100),
    /* Other merchant-specific fields */
    FOREIGN KEY (authentication_id) REFERENCES authentication(id)
);

CREATE TABLE iot_devices (
    id SERIAL PRIMARY KEY,
    authentication_id INT UNIQUE NOT NULL,
    device_name VARCHAR(255) NOT NULL,
    device_type VARCHAR(100),
    /* Other IoT device-specific fields */
    FOREIGN KEY (authentication_id) REFERENCES authentication(id)
);

CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    authentication_id INT UNIQUE NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_type VARCHAR(100),
    /* Other user-specific fields */
    
    FOREIGN KEY (authentication_id) REFERENCES authentication(id)
);

/*
 Easily add new entity types if needed by creating additional tables.
 Query and manage entity-specific data independently.

- how will my login & signup work with this?
when we do a sign up, it will create a transaction i.e it will create an entry in authentication table & user table both atomically.
when we do a login, it will check if the username & password from authentication table. if it is correct, it will return the corresponding DTO from table.

- How do we manage mqtt auth with this?
every entry in {user, iot_devices, merchants} tables will trigger a function to create a new entry in vmq_auth_acl table.
vernemq will use this table to authenticate mqtt clients.  
*/

CREATE OR REPLACE FUNCTION make_acl_entry()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO vmq_auth_acl (column1, column2, ...)
    VALUES (NEW.column1, NEW.column2, ...);
    /*
    will add other necessary columns here
    */
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_trigger
AFTER INSERT ON iot_devices
FOR EACH ROW
EXECUTE FUNCTION make_acl_entry();


CREATE EXTENSION pgcrypto;
CREATE TABLE IF NOT EXISTS vmq_auth_acl (
    mountpoint character varying(10) NOT NULL,
    client_id character varying(128) NOT NULL,
    username character varying(128) NOT NULL,
    password character varying(128),
    publish_acl json,
    subscribe_acl json,
    CONSTRAINT vmq_auth_acl_primary_key PRIMARY KEY (mountpoint, client_id, username)
);