package pfappserver::Form::Portal::Common;

=head1 NAME

pfappserver::Form::Portal::Common add documentation

=cut

=head1 DESCRIPTION

pfappserver::Form::Portal::Common

=cut

use strict;
use warnings;

use HTML::FormHandler::Moose::Role;
use List::MoreUtils qw(uniq);

use pf::authentication;
use pf::ConfigStore::Mdm;
use pf::web::constants;
with 'pfappserver::Base::Form::Role::Help';

=head1 Fields

=head2 id

Id of the profile

=cut

has_field 'id' =>
  (
   type => 'Text',
   label => 'Profile Name',
   required => 1,
   apply => [ { check => qr/^[a-zA-Z0-9][a-zA-Z0-9\._-]*$/ } ],
  );

=head2 description

Description of the profile

=cut

has_field 'description' =>
  (
   type => 'Text',
   label => 'Profile Description',
  );

=head2 locale

Accepted languages for the profile

=cut

has_field 'locale' =>
(
    'type' => 'DynamicTable',
    'sortable' => 1,
    'do_label' => 0,
);

has_field 'locale.contains' =>
(
    type => 'Select',
    options_method => \&options_locale,
    widget_wrapper => 'DynamicTableRow',
);

=head2 redirecturl

Redirection URL

=cut

has_field 'redirecturl' =>
  (
   type => 'Text',
   label => 'Redirection URL',
   tags => { after_element => \&help,
             help => 'Default URL to redirect to on registration/mitigation release. This is only used if a per-violation redirect URL is not defined.' },
  );

=head2 always_use_redirecturl

Controls whether or not we always use the redirection URL

=cut

has_field 'always_use_redirecturl' =>
  (
   type => 'Toggle',
   label => 'Force redirection URL',
   checkbox_value => 'enabled',
   unchecked_value => 'disabled',
   tags => { after_element => \&help,
             help => 'Under most circumstances we can redirect the user to the URL he originally intended to visit. However, you may prefer to force the captive portal to redirect the user to the redirection URL.' },
  );

=head2 billing_engine

Controls whether or not the billing engine is enabled

=cut

has_field 'billing_engine' =>
  (
   type => 'Toggle',
   label => 'Enable Billing Engine',
   checkbox_value => 'enabled',
   unchecked_value => 'disabled',
   tags => { after_element => \&help,
             help => 'When enabling the billing engine, all authentication sources bellow are ignored.' },
  );

=head2 sources

Collectiosn Authentication Sources for the profile

=cut

has_field 'sources' =>
  (
    'type' => 'DynamicTable',
    'sortable' => 1,
    'do_label' => 0,
  );

=head2 sources.contains

The definition for Authentication Sources field

=cut

has_field 'sources.contains' =>
  (
    type => 'Select',
    options_method => \&options_sources,
    widget_wrapper => 'DynamicTableRow',
  );

has_field 'mandatory_fields' =>
(
    'type' => 'DynamicTable',
    'sortable' => 1,
    'do_label' => 0,
);

has_field 'mandatory_fields.contains' =>
(
    type => 'Select',
    options_method => \&options_mandatory_fields,
    widget_wrapper => 'DynamicTableRow',
);

=head2 authorizer

=cut

has_field 'authorizer' =>
  (
    type => 'Select',
  );

=head2 allow_ios_devices

=cut

has_field 'allowed_devices' =>
  (
    type => 'Select',
    multiple => 1,
    element_class => ['chzn-select', 'input-xxlarge'],
  );

=head2 allow_android_devices

=cut

has_field 'allow_android_devices' =>
  (
    type => 'Checkbox',
  );

has_block provisioning => (
    render_list => [qw(authorizer allowed_devices)]
);

=head1 METHODS

=head2 options_locale

=cut

sub options_locale {
    return map { { value => $_, label => $_ } } @WEB::LOCALES;
}

=head2 options_authorizer

=cut

sub options_authorizer {
    return { value => '', label => '' }, map { { value => $_, label => $_ } } @{pf::ConfigStore::Mdm->new->readAllIds};
}

sub options_allowed_devices {
    return map { { value => $_, label => $_ } } qw(ios android windows);
}

=head2 options_sources

Returns the list of sources to be displayed

=cut

sub options_sources {
    return map { { value => $_->id, label => $_->id, attributes => { 'data-source-class' => $_->class  } } } @{getAllAuthenticationSources()};
}

=head2 options_mandatory_fields

Returns the list of sources to be displayed

=cut

sub options_mandatory_fields {
    return
      map { { value => $_, label => $_ } }
      qw(firstname lastname organization phone mobileprovider email sponsor_email
      anniversary birthday gender lang nickname organization cell_phone
      work_phone title building_number apartment_number room_number
      custom_field_1 custom_field_2 custom_field_3 custom_field_4 custom_field_5
      custom_field_6 custom_field_7 custom_field_8 custom_field_9);
}

=head2 validate

Remove duplicates and make sure only one external authentication source is selected for each type.

=cut

sub validate {
    my $self = shift;

    my @uniq_locales = uniq @{$self->value->{'locale'}};
    $self->field('locale')->value(\@uniq_locales);

    my @uniq_sources = uniq @{$self->value->{'sources'}};
    $self->field('sources')->value(\@uniq_sources);

    my %external;
    foreach my $source_id (@uniq_sources) {
        my $source = &pf::authentication::getAuthenticationSource($source_id);
        next unless $source && $source->class eq 'external';
        $external{$source->{'type'}} = 0 unless (defined $external{$source->{'type'}});
        $external{$source->{'type'}}++;
        if ($external{$source->{'type'}} > 1) {
            $self->field('sources')->add_error('Only one authentication source of each external type can be selected.');
            last;
        }
    }
}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;

