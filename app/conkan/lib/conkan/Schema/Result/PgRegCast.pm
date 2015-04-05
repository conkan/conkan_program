use utf8;
package conkan::Schema::Result::PgRegCast;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegCast - åºæ¼èåä»ãã¼ãã«

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
  extra: {list => ["\344\272\244\346\270\211\343\202\222\345\244\247\344\274\232\343\201\253\344\276\235\351\240\274","\345\207\272\346\274\224\344\272\206\346\211\277\346\270\210","\344\272\244\346\270\211\344\270\255","\346\234\252\344\272\244\346\270\211"]}
  is_nullable: 0

=head2 needguest

  data_type: 'enum'
  extra: {list => ["\343\201\231\343\202\213","\343\201\227\343\201\252\343\201\204"]}
  is_nullable: 0

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
    extra => {
      list => [
        pack("H*","e4baa4e6b889e38292e5a4a7e4bc9ae381abe4be9de9a0bc"),
        pack("H*","e587bae6bc94e4ba86e689bfe6b888"),
        "\xE4\xBA\xA4\xE6\xB8\x89\xE4\xB8\xAD",
        "\xE6\x9C\xAA\xE4\xBA\xA4\xE6\xB8\x89",
      ],
    },
    is_nullable => 0,
  },
  "needguest",
  {
    data_type => "enum",
    extra => {
      list => [
        "\xE3\x81\x99\xE3\x82\x8B",
        "\xE3\x81\x97\xE3\x81\xAA\xE3\x81\x84",
      ],
    },
    is_nullable => 0,
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-05 21:14:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dKztuYpZl8EeCVJGhK0zGg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
