use utf8;
package conkan::Schema::Result::PgRoom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRoom - room info

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

=head1 TABLE: C<pg_room>

=cut

__PACKAGE__->table("pg_room");

=head1 ACCESSORS

=head2 roomid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 roomno

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 max

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 size

  data_type: 'integer'
  is_nullable: 1

=head2 tablecnt

  data_type: 'integer'
  is_nullable: 1

=head2 chaircnt

  data_type: 'integer'
  is_nullable: 1

=head2 equips

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 useabletime

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 net

  data_type: 'enum'
  extra: {list => ["NONE","W","E"]}
  is_nullable: 0

=head2 rmdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "roomid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "roomno",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "max",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "size",
  { data_type => "integer", is_nullable => 1 },
  "tablecnt",
  { data_type => "integer", is_nullable => 1 },
  "chaircnt",
  { data_type => "integer", is_nullable => 1 },
  "equips",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "useabletime",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "net",
  {
    data_type => "enum",
    extra => { list => ["NONE", "W", "E"] },
    is_nullable => 0,
  },
  "rmdate",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</roomid>

=back

=cut

__PACKAGE__->set_primary_key("roomid");

=head1 RELATIONS

=head2 pg_programs

Type: has_many

Related object: L<conkan::Schema::Result::PgProgram>

=cut

__PACKAGE__->has_many(
  "pg_programs",
  "conkan::Schema::Result::PgProgram",
  { "foreign.roomid" => "self.roomid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-09 12:02:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2g5W1t1jmV3g8IHu7BvKtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;