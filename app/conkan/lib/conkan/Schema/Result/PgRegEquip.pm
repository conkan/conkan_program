use utf8;
package conkan::Schema::Result::PgRegEquip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegEquip - equipment registration data

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

=head1 TABLE: C<pg_reg_equip>

=cut

__PACKAGE__->table("pg_reg_equip");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 regpgid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 count

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 1

=head2 vif

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 aif

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 eif

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 intende

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "regpgid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "count",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "vif",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "aif",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "eif",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "intende",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 regpgid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgRegProgram>

=cut

__PACKAGE__->belongs_to(
  "regpgid",
  "conkan::Schema::Result::PgRegProgram",
  { regpgid => "regpgid" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-04-24 21:29:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RTxRjFONsEOT0FztEp0Kbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
