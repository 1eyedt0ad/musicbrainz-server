package MusicBrainz::Server::Controller::Role::Load;
use MooseX::Role::Parameterized -metaclass => 'MusicBrainz::Server::Controller::Role::Meta::Parameterizable';
use MusicBrainz::Server::Data::Utils 'model_to_type';
use MusicBrainz::Server::Validation qw( is_guid );
use MusicBrainz::Server::Constants qw( %ENTITIES );

no if $] >= 5.018, warnings => "experimental::smartmatch";

parameter 'model' => (
    isa => 'Str',
    required => 1
);

parameter 'entity_name' => (
    isa => 'Str',
);

parameter 'arg_count' => (
    isa => 'Int',
    default => 1
);

parameter 'relationships' => (
    isa => 'HashRef',
    required => 0,
    default => sub { {} }
);

role
{
    my $params = shift;
    my %extra = @_;

    my $model = $params->model;
    my $entity_type = model_to_type($model);
    my $entity_name = $params->entity_name || $entity_type;

    requires 'not_found', 'invalid_mbid';

    $extra{consumer}->name->config(
        action => {
            load => { Chained => 'base', PathPart => '', CaptureArgs => $params->arg_count }
        },
        model => $model,
        entity_name => $entity_name,
    );

    method load => sub
    {
        my ($self, $c, @args) = @_;

        # defaulting to something non-undef silences a warning
        my $entity_properties = $ENTITIES{ $entity_type // 0 };
        my $entity = $self->_load($c, $entity_properties, @args);

        $c->detach('not_found') unless defined $entity;


        if (exists $entity_properties->{mbid} && $entity_properties->{mbid}{relatable}) {
            my $action = $c->action->name;
            my $relationships = $params->relationships;

            if ($action ~~ $relationships->{all}) {
                $c->model('Relationship')->load($entity);
            } elsif ($action ~~ $relationships->{cardinal}) {
                $c->model('Relationship')->load_cardinal($entity);
            } else {
                my $types = $relationships->{subset}->{$action} // $relationships->{default};

                if ($types) {
                    $c->model('Relationship')->load_subset($types, $entity);
                }
            }
        }

        # First stash is more convenient for the actual controller
        $c->stash( $entity_name => $entity )
            if $entity_name && !$c->stash->{$entity_name};

        # Second is useful to roles or other places that need introspection
        $c->stash( entity => $entity, entity_type => $entity_type );

        $c->stash( entity_properties => $entity_properties );
    };

    method _load => sub
    {
        my ($self, $c, $entity_properties, $id) = @_;

        if (is_guid($id)) {
            my $entity = $c->model($model)->get_by_gid($id);
            $c->model($model)->load_gid_redirects($entity) if $entity && exists $entity_properties->{mbid} && $entity_properties->{mbid}{multiple};
            return $entity;
        }
        else {
            # This will detach for us
            $self->invalid_mbid($c, $id);
        }
    };
};

1;
