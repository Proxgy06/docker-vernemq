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

CREATE OR REPLACE PROCEDURE insert_user(user_ref text)
LANGUAGE SQL AS 
$$ 
  WITH x AS (
    SELECT ''::text AS mountpoint,
    CONCAT('db-', user_ref, '-client-id')::text AS client_id, -- eg: 'db-user1-client-id'
    CONCAT('db-', user_ref)::text AS username, -- eg: 'db-user1'
    CONCAT('db-', user_ref, '-password')::text AS password, -- eg: 'db-user1-password'
    gen_salt('bf')::text AS salt,
    '[{"pattern": "private/db/#"}, {"pattern": "public/#"}]'::json AS publish_acl,
    '[{"pattern": "private/db/#"}, {"pattern": "public/#"}]'::json AS subscribe_acl
  )
  INSERT INTO vmq_auth_acl (
    mountpoint,
    client_id,
    username,
    password,
    publish_acl,
    subscribe_acl
  )
  SELECT
    x.mountpoint,
    x.client_id,
    x.username,
    crypt(x.password, x.salt),
    publish_acl,
    subscribe_acl
  FROM x ON CONFLICT (mountpoint, client_id, username) DO NOTHING;
$$;
--
--
CALL insert_user('user1'); -- inserts row for user 'db-user1'
CALL insert_user('user2'); -- inserts row for user 'db-user2'