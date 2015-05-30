use utf8;
package conkan::Schema::Result::PgRegProgram;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegProgram - program registration data

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

=head1 TABLE: C<pg_reg_program>

=cut

__PACKAGE__->table("pg_reg_program");

=head1 ACCESSORS

=head2 pgid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 namef

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 regdate

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 regname

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 regma

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 regno

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 telno

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 faxno

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 celno

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 place

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 layout

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 date

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 classlen

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 expmaxcnt

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 content

  data_type: 'text'
  is_nullable: 0

=head2 contentpub

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 realpub

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 afterpub

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 avoiddup

  data_type: 'text'
  is_nullable: 1

=head2 experience

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 comment

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
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "namef",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "regdate",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "regname",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "regma",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "regno",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "telno",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "faxno",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "celno",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "place",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "layout",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "date",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "classlen",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "expmaxcnt",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "contentpub",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "realpub",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "afterpub",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "avoiddup",
  { data_type => "text", is_nullable => 1 },
  "experience",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "comment",
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

=head2 pg_programs

Type: has_many

Related object: L<conkan::Schema::Result::PgProgram>

=cut

__PACKAGE__->has_many(
  "pg_programs",
  "conkan::Schema::Result::PgProgram",
  { "foreign.pgid" => "self.pgid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pg_progresses

Type: has_many

Related object: L<conkan::Schema::Result::PgProgress>

=cut

__PACKAGE__->has_many(
  "pg_progresses",
  "conkan::Schema::Result::PgProgress",
  { "foreign.pgid" => "self.pgid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pg_reg_casts

Type: has_many

Related object: L<conkan::Schema::Result::PgRegCast>

=cut

__PACKAGE__->has_many(
  "pg_reg_casts",
  "conkan::Schema::Result::PgRegCast",
  { "foreign.pgid" => "self.pgid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pg_regs_equip

Type: has_many

Related object: L<conkan::Schema::Result::PgRegEquip>

=cut

__PACKAGE__->has_many(
  "pg_regs_equip",
  "conkan::Schema::Result::PgRegEquip",
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-05-30 11:20:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2GGrxfNnxvp7gzQlnRLKmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
