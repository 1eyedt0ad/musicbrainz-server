package MusicBrainz::Server::WebService::Serializer::JSON::2::Area;
use Moose;
use MusicBrainz::Server::WebService::Serializer::JSON::2::Utils qw( list_of number );

extends 'MusicBrainz::Server::WebService::Serializer::JSON::2';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::Aliases';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::Annotation';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::GID';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::LifeSpan';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::Rating';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::Relationships';
with 'MusicBrainz::Server::WebService::Serializer::JSON::2::Role::Tags';

sub serialize
{
    my ($self, $entity, $inc, $stash, $toplevel) = @_;
    my %body;

    $body{name} = $entity->name;
    $body{"sort-name"} = $entity->sort_name;
    $body{iso_3166_1_codes} = $entity->iso_3166_1 ? [ map { $_ } @{ $entity->iso_3166_1 } ] : JSON::null;
    $body{iso_3166_2_codes} = $entity->iso_3166_2 ? [ map { $_ } @{ $entity->iso_3166_2 } ] : JSON::null;
    $body{iso_3166_3_codes} = $entity->iso_3166_3 ? [ map { $_ } @{ $entity->iso_3166_3 } ] : JSON::null;

    if ($toplevel)
    {
        $body{type} = $entity->type_name;
    }

    return \%body;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2011,2012,2013 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

