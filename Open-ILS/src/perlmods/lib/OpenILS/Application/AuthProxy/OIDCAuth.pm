package OpenILS::Application::AuthProxy::OIDCAuth;
use strict;
use warnings;
use OpenSRF::AppSession;
use OpenSRF::Utils::Logger qw/$logger/;
use OpenILS::Application::AppUtils;
use OpenILS::Event;
my $U = 'OpenILS::Application::AppUtils';

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub authenticate {
    my ($self, $args) = @_;

    # Grab the HTTP_X_REMOTE_SUB value passed out of Apache environment
    my $oidc_sub = $ENV{HTTP_X_REMOTE_SUB};
    my $type     = $args->{'type'} || 'staff';

    $logger->info("Custom OIDC Auth triggered for Subject/Barcode identifier: $oidc_sub");

    if (!$oidc_sub) {
        $logger->info("Custom OIDC Auth failed: No HTTP_X_REMOTE_SUB string provided.");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }

    # 1. Look up the barcode in the actor.card table first
    my $cards = $U->cstorereq(
        "open-ils.cstore.direct.actor.card.search.atomic",
        {
            barcode => $oidc_sub,
            active  => 't'
        }
    );

    if (!$cards || scalar(@$cards) == 0) {
        $logger->info("No active barcode record found matching OIDC identifier: $oidc_sub");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }

    if (scalar(@$cards) > 1) {
        $logger->error("SECURITY CONFLICT: Multiple active library cards found sharing barcode: $oidc_sub");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }

    # Extract the user reference from the verified single card match
    my $matched_card = $cards->[0];
    my $target_usr_id = $matched_card->usr;

    # 2. Query the actual user record to ensure they are allowed to log in
    my $users = $U->cstorereq(
        "open-ils.cstore.direct.actor.user.search.atomic",
        {
            id      => $target_usr_id,
            active  => 't',
            deleted => 'f',
            barred  => 'f'
        }
    );

    # Clean User Validation Match
    if ($users && scalar(@$users) == 1) {
        my $user_obj = $users->[0];
        my $user_id  = $user_obj->id;
        my $username = $user_obj->usrname;

        $logger->info("Found active user ID $user_id with username $username via barcode verification.");

        # Define the payload tracking structure
        my $auth_response = {
            authtime => time(),
            username => $username,
            user_id  => $user_id
        };

        # Inject workstation parameters dynamically if the user is a staff member
        if ($type eq 'staff') {
            my $passed_ws = $args->{workstation};

            if ($passed_ws) {
                $auth_response->{workstation} = $passed_ws;
            } else {
                # DO NOT assign a fallback workstation.
                $logger->info("Staff user logged in without a workstation profile context.");
            }
        }

        return $auth_response;

    } else {
        $logger->info("User account attached to barcode $oidc_sub is inactive, deleted, or barred.");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }
}

1;
