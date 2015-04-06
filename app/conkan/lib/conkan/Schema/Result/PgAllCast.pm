use utf8;
package conkan::Schema::Result::PgAllCast;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgAllCast - All cast data

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<pg_all_cast>

=cut

__PACKAGE__->table("pg_all_cast");

=head1 ACCESSORS

=head2 castid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 regno

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 namef

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 restdate

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "castid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "regno",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "namef",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "status",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "restdate",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</castid>

=back

=cut

__PACKAGE__->set_primary_key("castid");

=head1 UNIQUE CONSTRAINTS

=head2 C<regno_UNIQUE>

=over 4

=item * L</regno>

=back

=cut

__PACKAGE__->add_unique_constraint("regno_UNIQUE", ["regno"]);

=head1 RELATIONS

=head2 pg_casts

Type: has_many

Related object: L<conkan::Schema::Result::PgCast>

=cut

__PACKAGE__->has_many(
  "pg_casts",
  "conkan::Schema::Result::PgCast",
  { "foreign.castid" => "self.castid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-06 16:49:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NUAjtg+h9eJq4XsR8Jx8Ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
