use strict;
use Test::More;

use Catalyst::Test 'MusicBrainz::Server';
use MusicBrainz::Server::Test qw( xml_ok );
use Test::WWW::Mechanize::Catalyst;

my $c = MusicBrainz::Server::Test->create_test_context;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'MusicBrainz::Server');

$mech->get_ok('/login');
$mech->submit_form( with_fields => { username => 'new_editor', password => 'password' } );

$mech->get_ok('/label/4b4ccf60-658e-11de-8a39-0800200c9a66/edit_annotation');
$mech->submit_form(
    with_fields => {
        'edit-annotation.text' => 'Test annotation 2. This is my annotation',
        'edit-annotation.changelog' => 'Changelog here',
    });

ok($mech->uri =~ qr{/label/4b4ccf60-658e-11de-8a39-0800200c9a66/?}, 'should redirect to label page via gid');

my $edit = MusicBrainz::Server::Test->get_latest_edit($c);
isa_ok($edit, 'MusicBrainz::Server::Edit::Label::AddAnnotation');
is_deeply($edit->data, {
    entity_id => 3,
    text => 'Test annotation 2. This is my annotation',
    changelog => 'Changelog here',
    editor_id => 1
});

$mech->get_ok('/edit/' . $edit->id, 'Fetch edit page');
$mech->content_contains('Changelog here', '..has changelog entry');
$mech->content_contains('Another Label', '..has label name');
$mech->content_like(qr{label/4b4ccf60-658e-11de-8a39-0800200c9a66/?"}, '..has a link to the label');
$mech->content_contains('label/4b4ccf60-658e-11de-8a39-0800200c9a66/annotation/' . $edit->annotation_id,
                        '..has a link to the annotation');

done_testing;
