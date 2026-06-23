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

# The main method Evergreen's AuthProxy will invoke
sub authenticate {
    my ($self, $args) = @_;

    # Grab the REMOTE_USER value passed out of Apache environment
    my $remote_user = $args->{'username'};
    my $type        = $args->{'type'} || 'staff';

    $logger->info("Custom OIDC Auth triggered for email identifier: $remote_user");

    if (!$remote_user) {
        $logger->info("Custom OIDC Auth failed: No REMOTE_USER string provided.");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }

    # Query cstore while ignoring dead, deleted, or barred staff accounts
    my $users = $U->cstorereq(
        "open-ils.cstore.direct.actor.user.search.atomic",
        {
            email   => $remote_user,
            active  => 't',
            deleted => 'f',
            barred  => 'f'
        }
    );

    # 1. Clean Match Found
    if ($users && scalar(@$users) == 1) {
        my $user_obj = $users->[0];
        my $user_id  = $user_obj->id;
        my $username = $user_obj->usrname;

        $logger->info("Found user ID $user_id with username $username via email lookup.");

        # Define the payload tracking structure
        my $auth_response = {
            authtime => time(),
            username => $username,
            user_id  => $user_id
        };

        # Inject workstation parameters dynamically if the user is a staff member
        if ($type eq 'staff') {
            # Check if a workstation context was passed inside the incoming client args
            my $passed_ws = $args->{workstation};

            if ($passed_ws) {
                $logger->info("OIDC Auth using explicit workstation sent by client: $passed_ws");
                $auth_response->{workstation} = $passed_ws;
            } else {
                # FALLBACK: Provide a unified system-wide workstation anchor
                # Note: Ensure this workstation profile exists in your actor.workstation table so:
                # INSERT INTO actor.workstation (name, owning_lib) VALUES ('OIDC_STAFF_FALLBACK', 4) ;
                my $fallback_ws = "OIDC_STAFF_FALLBACK";
                $logger->info("No workstation sent by client browser. Auto-assigning default context: $fallback_ws");

                $auth_response->{workstation}  = $fallback_ws;
                $auth_response->{workstations} = [ $fallback_ws ];
            }
        }

        return $auth_response;

    # 2. Duplicate Account Match Conflict
    } elsif ($users && scalar(@$users) > 1) {
        $logger->error("OIDC Auth failed: Multiple active accounts (" . scalar(@$users) . ") share the email address: $remote_user");
        return OpenILS::Event->new( 'LOGIN_FAILED' );

    } else {
        $logger->info("No database record found for email: $remote_user");
        return OpenILS::Event->new( 'LOGIN_FAILED' );
    }
}

1;
