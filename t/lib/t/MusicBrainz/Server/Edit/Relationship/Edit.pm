package t::MusicBrainz::Server::Edit::Relationship::Edit;
use Test::Routine;
use Test::More;
use Test::Fatal;

with 't::Edit';
with 't::Context';

BEGIN { use MusicBrainz::Server::Edit::Relationship::Edit }

use MusicBrainz::Server::Context;
use MusicBrainz::Server::Constants qw( $EDIT_RELATIONSHIP_EDIT $AUTO_EDITOR_FLAG $UNTRUSTED_FLAG );
use MusicBrainz::Server::Test qw( accept_edit reject_edit );

test all => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');
    MusicBrainz::Server::Test->prepare_raw_test_database($c);

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    is($rel->edits_pending, 0, "no edit pending on the relationship");
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);
    is($rel->link->type->id, 1, "link type id = 1");
    is($rel->link->begin_date->year, undef, "no begin date");
    is($rel->link->end_date->year, undef, "no end date");

    my $edit = _create_edit($c);
    isa_ok($edit, 'MusicBrainz::Server::Edit::Relationship::Edit');

    my ($edits, $hits) = $c->model('Edit')->find({ artist => 3 }, 10, 0);
    is($hits, 1, "Found 1 edit for artist 1");
    is($edits->[0]->id, $edit->id, "... which has the same id as the edit just created");

    ($edits, $hits) = $c->model('Edit')->find({ artist => 4 }, 10, 0);
    is($hits, 1, "Found 1 edit for artist 2");
    is($edits->[0]->id, $edit->id, "... which has the same id as the edit just created");

    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    is($rel->edits_pending, 1, "The relationship has 1 edit pending.");

    # Test rejecting the edit
    reject_edit($c, $edit);
    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    ok(defined $rel);
    is($rel->edits_pending, 0, "After rejecting the edit, no edit pending on the relationship");

    # Test accepting the edit
    $edit = _create_edit($c);
    accept_edit($c, $edit);
    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    ok(defined $rel, "After accepting the edit, the relationship has...");
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);
    is($rel->link->type->id, 2, "... type id 2");
    is($rel->link->begin_date->year, 1994, "... begin year 1994");
    is($rel->link->end_date->year, 1995, "... end year 1995");
    is($rel->entity0_id, 3, '... entity 0 is artist 3');
    is($rel->entity1_id, 5, '... entity 1 is artist 5');
};

test 'The display data works even if and endpoint or link type is deleted' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit = _create_edit($c);
    $edit->accept;

    $c->sql->do('SET CONSTRAINTS ALL IMMEDIATE');
    $c->sql->do('SET CONSTRAINTS ALL DEFERRED');
    $c->sql->do('TRUNCATE artist CASCADE');
    $c->sql->do('TRUNCATE link_type CASCADE');
    $c->model('Edit')->load_all($edit);

    ok(defined $edit->display_data->{old});
    is($edit->display_data->{old}->entity0->name, 'Artist 1');
    is($edit->display_data->{old}->entity1->name, 'Artist 2');
    is($edit->display_data->{old}->phrase, 'member');
    is($edit->display_data->{new}->entity0->name, 'Artist 1');
    is($edit->display_data->{new}->entity1->name, 'Artist 3');
    is($edit->display_data->{new}->phrase, 'support');
};

test 'Editing a relationship more than once fails subsequent edits' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit_1 = _create_edit($c);
    my $edit_2 = _create_edit($c);

    accept_edit($c, $edit_1);

    isa_ok exception { $edit_2->accept },
        'MusicBrainz::Server::Edit::Exceptions::FailedDependency';
};

test 'Editing a relationship fails if the relationship has been deleted' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit_1 = _create_edit($c);

    $c->model('Relationship')->delete('artist', 'artist', 1);

    isa_ok exception { $edit_1->accept },
        'MusicBrainz::Server::Edit::Exceptions::FailedDependency';
};

test 'Editing a relationship fails if one of the old endpoints has been deleted' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit = _create_edit($c);
    $c->model('Artist')->delete(4);

    isa_ok exception { $edit->accept },
        'MusicBrainz::Server::Edit::Exceptions::FailedDependency';
};

test 'Editing a relationship fails if one of the new endpoints has been deleted' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit = _create_edit($c);
    $c->model('Artist')->delete(5);

    isa_ok exception { $edit->accept },
        'MusicBrainz::Server::Edit::Exceptions::FailedDependency';
};

test 'Editing a relationship succeeds despite an entity being merged' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $r = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($r);
    $c->model('LinkType')->load($r->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        link_type => $c->model('LinkType')->get_by_id(2),
        privileges => $UNTRUSTED_FLAG,
        relationship => $r,
    );

    ok($edit->is_open);
    $c->model('Artist')->merge(5, [4]);
    ok !exception { $edit->accept };
};

test q(Editing a relationship fails if one of the entities is merged, and the
       edited relationship already exists on the merge target) => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $r = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($r);
    $c->model('LinkType')->load($r->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        link_type => $c->model('LinkType')->get_by_id(2),
        privileges => $UNTRUSTED_FLAG,
        relationship => $r,
    );

    ok($edit->is_open);
    $c->model('Artist')->merge(5, [4]);
    $c->model('Relationship')->insert('artist', 'artist', {
        entity0_id      => 3,
        entity1_id      => 5,
        link_type_id    => 2,
        attributes      => [{ type => { id => 1 } }],
    });
    isa_ok exception { $edit->accept },
        'MusicBrainz::Server::Edit::Exceptions::FailedDependency';
};

test 'Editing a relationship refreshes existing cover art' => sub {
    my $test = shift;
    my $c = $test->c;

    $c->sql->do(<<'EOSQL');
INSERT INTO artist (id, gid, name, sort_name)
  VALUES (1, '9d0ed9ec-ebd4-40d3-80ec-af70c07c3667', 'Artist', 'Artist');
INSERT INTO artist_credit (id, artist_count, name) VALUES (1, 1, 'Artist');

INSERT INTO release_group (id, name, artist_credit, gid)
  VALUES (1, 'Release', 1, '8265e53b-94d8-4700-bcd2-c3d25dcf104d');
INSERT INTO release (id, gid, artist_credit, name, release_group)
  VALUES (1, 'aa289662-5b07-425c-a3e7-bbb6898ff46d', 1, 'Release', 1),
         (2, '362e3ac2-5afb-4d14-95be-3b808da95121', 1, 'Release', 1);
UPDATE release_coverart
  SET cover_art_url = 'http://www.archive.org/download/CoverArtsForVariousAlbum/karenkong-mulakan.jpg';
INSERT INTO url (id, gid, url)
  VALUES (1, '24332737-b876-4d5e-9c30-e414b4570bda', 'http://www.archive.org/download/CoverArtsForVariousAlbum/karenkong-mulakan.jpg');

INSERT INTO link_type (id, gid, entity_type0, entity_type1, name, link_phrase,
    reverse_link_phrase, long_link_phrase)
  VALUES (1, '46687254-01e8-41a9-833f-183f1f25e487', 'release', 'url',
    'cover art link', 'cover art link', 'cover art link', 'cover art link');
INSERT INTO link (id, link_type) VALUES (1, 1);
INSERT INTO l_release_url (id, entity0, entity1, link) VALUES (1, 1, 1, 1);
EOSQL

    my $rel = $c->model('Relationship')->get_by_id('release', 'url', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        entity0 => $c->model('Release')->get_by_id(2)
    );

    accept_edit($c, $edit);

    my $r1 = $c->model('Release')->get_by_id(1);
    $c->model('Release')->load_meta($r1);
    is($r1->cover_art_url, undef);

    my $r2 = $c->model('Release')->get_by_id(2);
    $c->model('Release')->load_meta($r2);
    is($r2->cover_art_url, 'http://www.archive.org/download/CoverArtsForVariousAlbum/karenkong-mulakan.jpg');
};

test 'Editing relationships fails if the underlying link type changes' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    my $edit1 = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        begin_date => { year => 1994 },
        privileges => $UNTRUSTED_FLAG,
    );

    my $edit2 = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        link_type => $c->model('LinkType')->get_by_id(2),
        privileges => $UNTRUSTED_FLAG,
    );

    is(exception { $edit2->accept }, undef);
    is(exception { $edit1->accept },
        'This relationship has changed type since this edit was entered');
};

test 'Relationship link_order values are ignored' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        attributes => [{ type => { gid => '6c0b9280-dc7c-11e3-9c1a-0800200c9a66' } }],
        link_order => 5,
    );

    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    is($rel->link_order, 0);
};

test 'Text attributes with undef values raise exceptions' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 2);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    like(exception {
        $c->model('Edit')->create(
            edit_type => $EDIT_RELATIONSHIP_EDIT,
            editor_id => 1,
            relationship => $rel,
            attributes => [
                {
                    type => { gid => '6c0b9280-dc7c-11e3-9c1a-0800200c9a66' },
                },
                {
                    type => { gid => 'e4e7d1a0-dc7c-11e3-9c1a-0800200c9a66' },
                    text_value => undef
                }
            ],
        );
    }, qr/Attribute e4e7d1a0-dc7c-11e3-9c1a-0800200c9a66 requires a text value/);
};

test 'Attributes are validated against the new link type, not old one (MBS-7614)' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 3);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        link_type => $c->model('LinkType')->get_by_id(1),
        attributes => [{ type => { gid => '6c0b9280-dc7c-11e3-9c1a-0800200c9a66' } }],
    );

    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 3);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    is($rel->link->type_id, 1);
    is_deeply([ map { $_->type_id } $rel->link->all_attributes ], [2]);

    # Make sure unchanged attributes are also validated against the new link type.
    like exception {
        $c->model('Edit')->create(
            edit_type => $EDIT_RELATIONSHIP_EDIT,
            editor_id => 1,
            relationship => $rel,
            link_type => $c->model('LinkType')->get_by_id(3),
        );
    }, qr/Attribute 2 is unsupported for link type 3/;
};

test 'Instrument credits can be added to an existing relationship' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        link_type => $c->model('LinkType')->get_by_id(1),
        attributes => [
            {
                type => {
                    gid => '63021302-86cd-4aee-80df-2270d54f4978'
                },
                credited_as => 'crazy guitar'
            }
        ],
    );

    $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    is($rel->link->attributes->[0]->credited_as, 'crazy guitar');
};

test 'Edits that change endpoints are auto-editable by auto-editors' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $edit = _create_edit($c, privileges => $AUTO_EDITOR_FLAG);
    ok(!$edit->is_open, 'edit changing an endpoint was applied immediately by an auto-editor');
};

test 'Entity credits can be added to an existing relationship' => sub {
    my $test = shift;
    my $c = $test->c;

    MusicBrainz::Server::Test->prepare_test_database($c, '+edit_relationship_edit');

    my $relationship = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($relationship);
    $c->model('LinkType')->load($relationship->link);

    my $edit = $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $relationship,
        entity0_credit => 'Foo Credit',
        entity1_credit => 'Bar Credit',
    );

    is_deeply($edit->data, {
      edit_version => 2,
      link => {
            attributes => [
                {
                    type => {
                        id => 1,
                        gid => '7610b0e9-40c1-48b3-b06c-2c1d30d9dc3e',
                        name => 'Attribute',
                        root => {
                            gid => '7610b0e9-40c1-48b3-b06c-2c1d30d9dc3e',
                            id => 1,
                            name => 'Attribute'
                        }
                    }
                }
            ],
            begin_date => { month => undef, day => undef, year => undef },
            end_date => { year => undef, month => undef, day => undef },
            ended => '0',
            entity0 => {
               name => 'Artist 1',
               gid => '945c079d-374e-4436-9448-da92dedef3cf',
               id => 3
            },
            entity1 => {
               gid => '75a40343-ff6e-45d6-a5d2-110388d34858',
               id => 4,
               name => 'Artist 2'
            },
           link_type => {
                id => 1,
                link_phrase => 'member',
                long_link_phrase => 'f',
                name => 'member',
                reverse_link_phrase => 'oof',
            },
        },
        new => {
            entity1_credit => 'Bar Credit',
            entity0_credit => 'Foo Credit'
        },
        old => {
            entity1_credit => '',
            entity0_credit => ''
        },
        relationship_id => 1,
        type1 => 'artist',
        type0 => 'artist',
    });
};

sub _create_edit {
    my ($c, %args) = @_;

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    return $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        relationship => $rel,
        link_type => $c->model('LinkType')->get_by_id(2),
        begin_date => { year => 1994 },
        end_date => { year => 1995 },
        entity1 => $c->model('Artist')->get_by_id(5),
        %args
    );
}

sub _create_edit_change_direction {
    my $c = shift;

    my $rel = $c->model('Relationship')->get_by_id('artist', 'artist', 1);
    $c->model('Link')->load($rel);
    $c->model('LinkType')->load($rel->link);

    return $c->model('Edit')->create(
        edit_type => $EDIT_RELATIONSHIP_EDIT,
        editor_id => 1,
        change_direction => 1,
        relationship => $rel,
        link_type => $c->model('LinkType')->get_by_id(1),
        begin_date => undef,
        end_date => undef,
        attributes => [],
    );
}

1;
