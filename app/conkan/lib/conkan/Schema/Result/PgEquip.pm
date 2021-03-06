use utf8;
package conkan::Schema::Result::PgEquip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgEquip - Equipment Management master

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

=head1 TABLE: C<pg_equip>

=cut

__PACKAGE__->table("pg_equip");

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

=head2 equipid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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

=head2 updateflg

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
  "pgid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "equipid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
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
  "updateflg",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 equipid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgAllEquip>

=cut

__PACKAGE__->belongs_to(
  "equipid",
  "conkan::Schema::Result::PgAllEquip",
  { equipid => "equipid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pgid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgProgram>

=cut

__PACKAGE__->belongs_to(
  "pgid",
  "conkan::Schema::Result::PgProgram",
  { pgid => "pgid" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-05-29 19:14:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x7FeedvHaUPHHqTmUhgBvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
