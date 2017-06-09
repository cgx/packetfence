package captiveportal::PacketFence::DynamicRouting::Module::Authentication::OAuth::OpenID;

=head1 NAME

captiveportal::DynamicRouting::Module::Authentication::OAuth::OpenID

=head1 DESCRIPTION

OpenID OAuth module

=cut

use WWW::Curl::Easy;
use Moose;
use JSON::MaybeXS;
use pf::log;
use pf::error qw(is_success is_error);
use Data::Dumper;
extends 'captiveportal::DynamicRouting::Module::Authentication::OAuth';

has '+source' => (isa => 'pf::Authentication::Source::OpenIDSource');

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2017 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
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

__PACKAGE__->meta->make_immutable;

1;

