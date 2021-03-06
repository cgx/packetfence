package captiveportal::PacketFence::Controller::Oauth2;
use Moose;
use namespace::autoclean;
use pf::config;
use Net::OAuth2::Client;

BEGIN { extends 'captiveportal::Base::Controller'; }

=head1 NAME

captiveportal::PacketFence::Controller::Oauth2 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.



=head1 METHODS

=cut

our %VALID_OAUTH_PROVIDERS = (
    google   => undef,
    facebook => undef,
    github   => undef,
);

=head2 auth_provider

/oauth2/auth/:provider

=cut

sub auth_provider : Local('auth'): Args(1) {
    my ( $self, $c, $provider ) = @_;
    $c->response->redirect($self->oauth2_client($c,$provider)->authorize);
}

=head2 auth

/oauth2/auth

=cut

sub auth : Local: Args(0) {
    my ( $self, $c ) = @_;
    my $provider = $c->request->query_params->{'provider'};
    $c->forward('auth_provider',[$provider]);
}

=head2 index

/oauth2/auth

=cut

sub index :Path : Args(0) {
    my ( $self, $c ) = @_;
    my $provider = $c->request->query_params->{'request'};
    $c->forward('oauth2Result',[$provider]);
}

=head2 oauth2_client

=cut

sub oauth2_client {
    my ($self,$c,$provider) = @_;
    my $logger = $c->log;
    my $portalSession = $c->portalSession;
    my $type;
    if (lc($provider) eq 'facebook') {
        $type = pf::Authentication::Source::FacebookSource->meta->get_attribute('type')->default;
    } elsif (lc($provider) eq 'github') {
        $type = pf::Authentication::Source::GithubSource->meta->get_attribute('type')->default;
    } elsif (lc($provider) eq 'google') {
        $type = pf::Authentication::Source::GoogleSource->meta->get_attribute('type')->default;
    }
    if ($type) {
        my $source = $portalSession->profile->getSourceByType($type);
        if ($source) {
            return Net::OAuth2::Profile::WebServer->new(
                client_id => $source->{'client_id'},
                client_secret => $source->{'client_secret'},
                site => $source->{'site'},
                authorize_path => $source->{'authorize_path'},
                access_token_path => $source->{'access_token_path'},
                access_token_method => $source->{'access_token_method'},
                #access_token_param => $source->{'access_token_param'},
                scope => $source->{'scope'},
                redirect_uri => $source->{'redirect_url'} 
          );
        }
        else {
            $logger->error(sprintf("No source of type '%s' defined for profile '%s'", $type, $portalSession->profile->getName));
        }
    }
    $self->showError($c,"OAuth2 Error: Error loading provider");
}

=head2 oauth2Result

/oauth2/:provider

Handles the oauth request coming from the providers

=cut

sub oauth2Result : Path : Args(1) {
    my ($self, $c, $provider) = @_;
    my $logger        = $c->log;
    my $portalSession = $c->portalSession;
    my $profile       = $portalSession->profile;
    my $request       = $c->request;
    my %info;
    my $pid;

    # Pull username
    $info{'pid'} = "admin";

    # Pull browser user-agent string
    $info{'user_agent'} = $request->user_agent;

    my $code = $request->query_params->{'code'};

    $logger->debug("API CODE: $code");

    #Get the token
    my $token;

    eval {
        $token = $self->oauth2_client($c,$provider)->get_access_token($code);
    };

    if ($@) {
        $logger->warn(
            "OAuth2: failed to receive the token from the provider: $@");
        $c->stash->{txt_auth_error} = "OAuth2 Error: Failed to get the token";
        $c->detach(Authenticate => 'showLogin');
    }

    my $response;

    my $type;

    # Validate the token
    if (lc($provider) eq 'facebook') {
        $type =
          pf::Authentication::Source::FacebookSource->meta->get_attribute(
            'type')->default;
    } elsif (lc($provider) eq 'github') {
        $type = pf::Authentication::Source::GithubSource->meta->get_attribute(
            'type')->default;
    } elsif (lc($provider) eq 'google') {
        $type = pf::Authentication::Source::GoogleSource->meta->get_attribute(
            'type')->default;
    }
    my $source = $profile->getSourceByType($type);
    if ($source) {
        $response = $token->get($source->{'protected_resource_url'});
        if ($response->is_success) {

            # Grab JSON content
            my $json      = new JSON;
            my $json_text = $json->decode($response->content());
            if ($provider eq 'google' || $provider eq 'github') {
                $logger->info(
                    "OAuth2 successfull, register and release for email $json_text->{email}"
                );
                $pid = $json_text->{email};
            } elsif ($provider eq 'facebook') {
                $logger->info(
                    "OAuth2 successfull, register and release for username $json_text->{username}"
                );
                $pid = $json_text->{username} . '@facebook.com';
            }
        } else {
            $logger->info(
                "OAuth2: failed to validate the token, redireting to login page"
            );
            $c->stash->{txt_auth_error} = i18n("OAuth2 Error: Failed to validate the token, please retry");
            $c->detach(Authentication => 'showLogin');
        }

        # Setting access timeout and role (category) dynamically
        $info{'unregdate'} =
          &pf::authentication::match( $source->{id}, { username => $pid },
            $Actions::SET_ACCESS_DURATION );

        if ( defined $info{'unregdate'} ) {
            $info{'unregdate'} = POSIX::strftime(
                "%Y-%m-%d %H:%M:%S",
                localtime( time + normalize_time( $info{'unregdate'} ) )
            );
        } else {
            $info{'unregdate'} =
              &pf::authentication::match( $source->{id},
                { username => $pid },
                $Actions::SET_UNREG_DATE );
        }

        $info{'category'} =
          &pf::authentication::match( $source->{id}, { username => $pid },
            $Actions::SET_ROLE );
        $c->forward('CaptivePortal' => 'webNodeRegister', [$pid, %info]);
        $c->forward('CaptivePortal' => 'endPortalSession');
    } else {
        $logger->error(
            sprintf(
                "No source of type '%s' defined for profile '%s'",
                $type, $profile->getName
            )
        );
        $c->response->redirect( $Config{'trapping'}{'redirecturl'} );
    }
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
