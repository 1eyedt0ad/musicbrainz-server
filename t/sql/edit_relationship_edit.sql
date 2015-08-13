SET client_min_messages TO 'warning';

INSERT INTO artist (id, gid, name, sort_name) VALUES
    (3, '945c079d-374e-4436-9448-da92dedef3cf', 'Artist 1', 'Artist 1'),
    (4, '75a40343-ff6e-45d6-a5d2-110388d34858', 'Artist 2', 'Artist 2'),
    (5, '15a40343-ff6e-45d6-a5d2-110388d34858', 'Artist 3', 'Artist 3');

INSERT INTO artist_credit (id, name, artist_count) VALUES (1, 'Artist 1', 1);

INSERT INTO link_type (id, gid, entity_type0, entity_type1, name, link_phrase, reverse_link_phrase, long_link_phrase, description)
    VALUES
        (1, '7610b0e9-40c1-48b3-b06c-2c1d30d9dc3e', 'artist', 'artist', 'member', 'member', 'oof', 'f', '-'),
        (2, '254815bb-390a-4eed-bc50-1f25ba66fa68', 'artist', 'artist', 'support', 'support', 'oof', 'f', '-'),
        (3, 'd2ae508c-c9a0-4e5f-89b7-fff3ea5e9e7e', 'artist', 'artist', 'collaborator', 'collaborator', 'oof', 'f', '-'),
        (84, '2476be45-3090-43b3-a948-a8f972b4065c', 'release', 'url', 'cover art link', '-', '-', '-', '-'),
        (83, '4f2e710d-166c-480c-a293-2e2c8d658d87', 'release', 'url', 'amazon asin', '', '', '', '-');

INSERT INTO link_attribute_type (id, root, gid, name)
    VALUES (1, 1, '7610b0e9-40c1-48b3-b06c-2c1d30d9dc3e', 'Attribute'),
           (2, 2, '6c0b9280-dc7c-11e3-9c1a-0800200c9a66', 'Another attribute'),
           (3, 3, 'e4e7d1a0-dc7c-11e3-9c1a-0800200c9a66', 'And a random text attribute'),
           (14, 14, '0abd7f04-5e28-425b-956f-94789d9bcbe2', 'instrument'),
           (229, 14, '63021302-86cd-4aee-80df-2270d54f4978', 'guitar');

INSERT INTO link_text_attribute_type (attribute_type) VALUES (3);
INSERT INTO link_creditable_attribute_type (attribute_type) VALUES (229);
INSERT INTO link (id, link_type, attribute_count) VALUES (1, 1, 1);
INSERT INTO link (id, link_type, attribute_count) VALUES (2, 1, 1);
INSERT INTO link (id, link_type, attribute_count) VALUES (3, 3, 0);
INSERT INTO link_type_attribute_type (attribute_type, link_type, min, max) VALUES (1, 1, 0, NULL);
INSERT INTO link_type_attribute_type (attribute_type, link_type, min, max) VALUES (1, 2, 0, NULL);
INSERT INTO link_type_attribute_type (attribute_type, link_type, min, max) VALUES (2, 1, 0, NULL);
INSERT INTO link_type_attribute_type (attribute_type, link_type, min, max) VALUES (3, 1, 0, NULL);
INSERT INTO link_type_attribute_type (attribute_type, link_type, min, max) VALUES (14, 1, 0, NULL);
INSERT INTO link_attribute (link, attribute_type) VALUES (1, 1);
INSERT INTO link_attribute (link, attribute_type) VALUES (2, 3);
INSERT INTO link_attribute_text_value (link, attribute_type, text_value) VALUES (2, 3, 'tv1');

INSERT INTO l_artist_artist (id, link, entity0, entity1) VALUES (1, 1, 3, 4);
INSERT INTO l_artist_artist (id, link, entity0, entity1) VALUES (2, 2, 3, 4);
INSERT INTO l_artist_artist (id, link, entity0, entity1) VALUES (3, 3, 3, 4);

INSERT INTO release_group (id, gid, name, artist_credit)
    VALUES (1, '3b4faa80-72d9-11de-8a39-0800200c9a66', 'Arrival', 1);

INSERT INTO release (id, gid, name, artist_credit, release_group)
    VALUES (1, '7a906020-72db-11de-8a39-0800200c9a66', 'Arrival', 1, 1),
           (2, '7a906020-72db-11de-8a39-0800200c9a67', 'Arrival', 1, 1);
