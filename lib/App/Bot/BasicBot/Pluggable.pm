package App::Bot::BasicBot::Pluggable;
use Config::Find;
use Bot::BasicBot::Pluggable;
use Moose;
with 'MooseX::Getopt';
with 'MooseX::SimpleConfig';

has server  => ( is => 'ro', isa => 'Str', required => 1 );
has nick    => ( is => 'ro', isa => 'Str', default  => 'basicbot' );
has charset => ( is => 'ro', isa => 'Str', default  => 'utf8' );
has channel => ( is => 'ro', isa => 'ArrayRef' );
has password => ( is => 'ro', isa => 'Str' );
has port => ( is => 'ro', isa => 'Int', default => 6667 );

has settings => ( metaclass => 'NoGetopt', is => 'rw', isa => 'HashRef' );

has configfile => (
    is      => 'ro',
    isa     => 'Str',
    default => Config::Find->find( name => 'bot-basicbot-pluggable.yaml' ),
);

has bot => (
    metaclass => 'NoGetopt',
    is        => 'ro',
    isa       => 'Bot::BasicBot::Pluggable',
    builder   => 'create_bot',
    lazy      => 1,
);

has module => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { return [qw( Auth Loader )] }
);

sub BUILDER {
    my ($self) = @_;
    if ( $self->password() ) {
        my %module = map { $_ => 1 } @{ $self->modules() };
        $module{Auth} = 1;
        $self->modules( [ keys %module ] );
    }

    for my $module_name ( @{ $self->module() } ) {
        my $module = $bot->load($module_name);
        if ( $self->settings ) {
            my %settings = $self->settings;
            if ( exists( $settings{$module_name} ) ) {
                for my $key ( keys %{ $settings{$module_name} } ) {
                    $module->set( $key, $settings{$module_name}->{$key} );
                }
            }
        }
        if ( $module_name eq 'Auth' and $self->password() ) {
            $module->set( 'password_admin', $self->password() );
        }
    }

}

sub create_bot {
    my ($self) = @_;
    my $bot = Bot::BasicBot::Pluggable->new(
        channels => $self->channel(),
        server   => $self->server(),
        nick     => $self->nick(),
        charset  => $self->charset(),
        port     => $self->port(),
    );
}

sub run {
    my ($self) = @_;
    $self->bot->run();
}

1;