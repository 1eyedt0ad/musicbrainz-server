package MusicBrainz::Server::Data::Role::EntityCache;

use DBDefs;
use Moose::Role;
use List::MoreUtils qw( natatime uniq );
use MusicBrainz::Server::Constants qw( %ENTITIES );
use MusicBrainz::Server::Validation qw( is_database_row_id );
use Readonly;

requires '_type';

Readonly our $MAX_CACHE_ENTRIES => 500;

sub _cache_id {
    my ($self) = @_;

    my $type = $self->_type;
    if ($type && (my $entity_properties = $ENTITIES{$type})) {
        if (exists $entity_properties->{cache}) {
            return $entity_properties->{cache}{id};
        }
    }
}

around get_by_ids => sub {
    my ($orig, $self, @ids) = @_;
    return {} unless grep { defined && $_ } @ids;
    my %ids = map { $_ => 1 } @ids;
    my @keys = map { $self->_type . ':' . $_ } keys %ids;
    my $cache = $self->c->cache($self->_type);
    my %data = %{$cache->get_multi(@keys)};
    my %result;
    foreach my $key (keys %data) {
        my @key = split /:/, $key;
        my $id = $key[1];
        $result{$id} = $data{$key};
        delete $ids{$id};
    }
    if (%ids) {
        my $data = $self->$orig(keys %ids) || {};
        foreach my $id (keys %$data) {
            $result{$id} = $data->{$id};
        }
        $self->_add_to_cache($cache, %$data);
    }
    return \%result;
};

after update => sub {
    my ($self, $id) = @_;
    $self->_delete_from_cache($id);
};

after delete => sub {
    my ($self, @ids) = @_;
    $self->_delete_from_cache(@ids);
};

after merge => sub {
    my ($self, @ids) = @_;
    $self->_delete_from_cache(@ids);
};

sub _create_cache_entries {
    my ($self, $data) = @_;

    my $cache_id = $self->_cache_id;
    my $cache_prefix = $self->_type . ':';
    my @entries;
    my @ids = keys %{$data};

    if (scalar(@ids) > $MAX_CACHE_ENTRIES) {
        @ids = @ids[0..$MAX_CACHE_ENTRIES];
    }

    my $ttl = DBDefs->ENTITY_CACHE_TTL;
    my $it = natatime 100, @ids;
    while (my @next_ids = $it->()) {
        # MBS-7241
        my $locks = $self->c->sql->select_list_of_hashes(
            'SELECT id, pg_try_advisory_xact_lock(?, id) AS got_lock ' .
            '  FROM unnest(?::integer[]) AS id',
            $cache_id,
            \@next_ids,
        );
        push @entries, map {
            my $id = $_->{id};
            [$cache_prefix . $id, $data->{$id}, ($ttl ? $ttl : ())]
        } grep { $_->{got_lock} } @$locks;
    }

    @entries;
}

sub _add_to_cache {
    my ($self, $cache, %data) = @_;

    my @entries = $self->_create_cache_entries(\%data);
    $cache->set_multi(@entries) if @entries;
}

sub _delete_from_cache {
    my ($self, @ids) = @_;

    @ids = uniq grep { defined } @ids;
    return unless @ids;

    my $cache_id = $self->_cache_id;

    # MBS-7241
    my @row_ids = grep { is_database_row_id($_) } @ids;
    $self->c->sql->do(
        'SELECT pg_advisory_xact_lock(?, id) ' .
        '  FROM unnest(?::integer[]) AS id',
        $cache_id,
        \@row_ids,
    ) if @row_ids;

    my $cache_prefix = $self->_type . ':';
    my @keys = map { $cache_prefix . $_ } @ids;

    my $cache = $self->c->cache($self->_type);
    my $method = @keys > 1 ? 'delete_multi' : 'delete';
    $cache->$method(@keys);
}

1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky
Copyright (C) 2016 MetaBrainz Foundation

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
