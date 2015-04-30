use utf8;
package conkan::Schema::Result::PgRegCast;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegCast - cast registration data

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

=head1 TABLE: C<pg_reg_cast>

=cut

__PACKAGE__->table("pg_reg_cast");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pgid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 namef

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 entrantregno

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 needreq

  data_type: 'enum'
  default_value: 'accepted'
  extra: {list => ["req","accepted","innego","yetnego"]}
  is_nullable: 1

=head2 needguest

  data_type: 'enum'
  default_value: 'N'
  extra: {list => ["Y","N"]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pgid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "namef",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "entrantregno",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "needreq",
  {
    data_type => "enum",
    default_value => "accepted",
    extra => { list => ["req", "accepted", "innego", "yetnego"] },
    is_nullable => 1,
  },
  "needguest",
  {
    data_type => "enum",
    default_value => "N",
    extra => { list => ["Y", "N"] },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 pgid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgRegProgram>

=cut

__PACKAGE__->belongs_to(
  "pgid",
  "conkan::Schema::Result::PgRegProgram",
  { pgid => "pgid" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-11 15:59:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:W9xsbhZ8EiDI82Ki/ZtEMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
