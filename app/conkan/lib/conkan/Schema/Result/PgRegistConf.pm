use utf8;
package conkan::Schema::Result::PgRegistConf;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegistConf - Program META structure

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

=head1 TABLE: C<pg_regist_conf>

=cut

__PACKAGE__->table("pg_regist_conf");

=head1 ACCESSORS

=head2 jsonkeyid

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 hashkey

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 db_name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 valtype

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 upperkeyid

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "jsonkeyid",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "hashkey",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "db_name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "valtype",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "upperkeyid",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</jsonkeyid>

=back

=cut

__PACKAGE__->set_primary_key("jsonkeyid");

=head1 RELATIONS

=head2 pg_regist_confs

Type: has_many

Related object: L<conkan::Schema::Result::PgRegistConf>

=cut

__PACKAGE__->has_many(
  "pg_regist_confs",
  "conkan::Schema::Result::PgRegistConf",
  { "foreign.upperkeyid" => "self.jsonkeyid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 upperkeyid

Type: belongs_to

Related object: L<conkan::Schema::Result::PgRegistConf>

=cut

__PACKAGE__->belongs_to(
  "upperkeyid",
  "conkan::Schema::Result::PgRegistConf",
  { jsonkeyid => "upperkeyid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-06 16:49:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:woSe2u8T3U6rc3nyswbzKQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
