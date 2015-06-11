use utf8;
package conkan::Schema::Result::PgProgram;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgProgram - Program Management Master

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

=head1 TABLE: C<pg_program>

=cut

__PACKAGE__->table("pg_program");

=head1 ACCESSORS

=head2 pgid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 regpgid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 subno

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 staffid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 memo

  data_type: 'text'
  is_nullable: 1

=head2 date1

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 stime1

  data_type: 'time'
  is_nullable: 1

=head2 etime1

  data_type: 'time'
  is_nullable: 1

=head2 date2

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 stime2

  data_type: 'time'
  is_nullable: 1

=head2 etime2

  data_type: 'time'
  is_nullable: 1

=head2 roomid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 layerno

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 progressprp

  data_type: 'text'
  is_nullable: 1

=head2 updateflg

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "pgid",
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
  "subno",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "staffid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "memo",
  { data_type => "text", is_nullable => 1 },
  "date1",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "stime1",
  { data_type => "time", is_nullable => 1 },
  "etime1",
  { data_type => "time", is_nullable => 1 },
  "date2",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "stime2",
  { data_type => "time", is_nullable => 1 },
  "etime2",
  { data_type => "time", is_nullable => 1 },
  "roomid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "layerno",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "progressprp",
  { data_type => "text", is_nullable => 1 },
  "updateflg",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pgid>

=back

=cut

__PACKAGE__->set_primary_key("pgid");

=head1 RELATIONS

=head2 pg_casts

Type: has_many

Related object: L<conkan::Schema::Result::PgCast>

=cut

__PACKAGE__->has_many(
  "pg_casts",
  "conkan::Schema::Result::PgCast",
  { "foreign.pgid" => "self.pgid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pgs_equip

Type: has_many

Related object: L<conkan::Schema::Result::PgEquip>

=cut

__PACKAGE__->has_many(
  "pgs_equip",
  "conkan::Schema::Result::PgEquip",
  { "foreign.pgid" => "self.pgid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 regpgid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgRegProgram>

=cut

__PACKAGE__->belongs_to(
  "regpgid",
  "conkan::Schema::Result::PgRegProgram",
  { regpgid => "regpgid" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
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

=head2 staffid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgStaff>

=cut

__PACKAGE__->belongs_to(
  "staffid",
  "conkan::Schema::Result::PgStaff",
  { staffid => "staffid" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-11 16:41:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zt4jCzck3bqNwlRXTJ0oOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
