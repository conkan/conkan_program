use utf8;
package conkan::Schema::Result::PgAllEquip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgAllEquip - all equipment info

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

=head1 TABLE: C<pg_all_equip>

=cut

__PACKAGE__->table("pg_all_equip");

=head1 ACCESSORS

=head2 equipid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 equipno

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 spec

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 roomid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 suppliers

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 updateflg

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 rmdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "equipid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "equipno",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "spec",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "roomid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "suppliers",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "updateflg",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "rmdate",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</equipid>

=back

=cut

__PACKAGE__->set_primary_key("equipid");

=head1 UNIQUE CONSTRAINTS

=head2 C<equipNo_UNIQUE>

=over 4

=item * L</equipno>

=back

=cut

__PACKAGE__->add_unique_constraint("equipNo_UNIQUE", ["equipno"]);

=head1 RELATIONS

=head2 pgs_equip

Type: has_many

Related object: L<conkan::Schema::Result::PgEquip>

=cut

__PACKAGE__->has_many(
  "pgs_equip",
  "conkan::Schema::Result::PgEquip",
  { "foreign.equipid" => "self.equipid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roomid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgRoom>

=cut

__PACKAGE__->belongs_to(
  "roomid",
  "conkan::Schema::Result::PgRoom",
  { roomid => "roomid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-01-14 14:18:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vXuB6G4C9UhJSjTkfEivNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
