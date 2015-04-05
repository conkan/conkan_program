use utf8;
package conkan::Schema::Result::PgRegProgram;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgRegProgram - ä¼ç»åä»ãã¼ãã«

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

  data_type: 'integer'
  is_nullable: 0

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

  data_type: 'enum'
  extra: {list => ["\344\270\215\346\230\216","20\344\272\272\343\201\276\343\201\247","50\344\272\272\343\201\276\343\201\247","100\344\272\272\343\201\276\343\201\247","200\344\272\272\343\201\276\343\201\247","200\344\272\272\350\266\205"]}
  is_nullable: 0

=head2 content

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 contentpub

  data_type: 'enum'
  extra: {list => ["\344\272\213\345\211\215\345\205\254\351\226\213\345\217\257","\344\272\213\345\211\215\345\205\254\351\226\213\344\270\215\345\217\257"]}
  is_nullable: 0

=head2 realpub

  data_type: 'enum'
  extra: {list => ["UST\347\255\211\345\213\225\347\224\273\343\202\222\345\220\253\343\202\200\345\205\250\343\201\246\350\250\261\345\217\257","twitter\347\255\211\343\203\206\343\202\255\343\202\271\343\203\210\343\201\250\351\235\231\346\255\242\347\224\273\345\205\254\351\226\213\345\217\257","\343\203\206\343\202\255\343\202\271\343\203\210\343\201\256\343\201\277\345\205\254\351\226\213\345\217\257","\345\205\254\351\226\213\344\270\215\345\217\257","\343\201\235\343\201\256\344\273\226"]}
  is_nullable: 0

=head2 afterpub

  data_type: 'enum'
  extra: {list => ["UST\347\255\211\345\213\225\347\224\273\343\202\222\345\220\253\343\202\200\345\205\250\343\201\246\350\250\261\345\217\257","blog\347\255\211\343\203\206\343\202\255\343\202\271\343\203\210\343\201\250\351\235\231\346\255\242\347\224\273\345\205\254\351\226\213\345\217\257","\343\203\206\343\202\255\343\202\271\343\203\210\343\201\256\343\201\277\345\205\254\351\226\213\345\217\257","\345\205\254\351\226\213\344\270\215\345\217\257","\343\201\235\343\201\256\344\273\226"]}
  is_nullable: 0

=head2 avoiddup

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 experience

  data_type: 'enum'
  extra: {list => ["\345\210\235\343\202\201\343\201\246","\346\230\250\345\271\264\343\201\253\347\266\232\343\201\204\343\201\2462\345\233\236\347\233\256","\347\266\231\347\266\232\343\201\227\343\201\2463\357\275\2365\345\233\236\347\233\256","\343\201\262\343\201\225\343\201\227\343\201\266\343\202\212","6\345\233\236\347\233\256\344\273\245\344\270\212"]}
  is_nullable: 0

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 128

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
  { data_type => "integer", is_nullable => 0 },
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
  {
    data_type => "enum",
    extra => {
      list => [
        "\xE4\xB8\x8D\xE6\x98\x8E",
        "20\xE4\xBA\xBA\xE3\x81\xBE\xE3\x81\xA7",
        "50\xE4\xBA\xBA\xE3\x81\xBE\xE3\x81\xA7",
        pack("H*","313030e4babae381bee381a7"),
        pack("H*","323030e4babae381bee381a7"),
        "200\xE4\xBA\xBA\xE8\xB6\x85",
      ],
    },
    is_nullable => 0,
  },
  "content",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "contentpub",
  {
    data_type => "enum",
    extra => {
      list => [
        pack("H*","e4ba8be5898de585ace9968be58faf"),
        pack("H*","e4ba8be5898de585ace9968be4b88de58faf"),
      ],
    },
    is_nullable => 0,
  },
  "realpub",
  {
    data_type => "enum",
    extra => {
      list => [
        pack("H*","555354e7ad89e58b95e794bbe38292e590abe38280e585a8e381a6e8a8b1e58faf"),
        pack("H*","74776974746572e7ad89e38386e382ade382b9e38388e381a8e99d99e6ada2e794bbe585ace9968be58faf"),
        pack("H*","e38386e382ade382b9e38388e381aee381bfe585ace9968be58faf"),
        pack("H*","e585ace9968be4b88de58faf"),
        "\xE3\x81\x9D\xE3\x81\xAE\xE4\xBB\x96",
      ],
    },
    is_nullable => 0,
  },
  "afterpub",
  {
    data_type => "enum",
    extra => {
      list => [
        pack("H*","555354e7ad89e58b95e794bbe38292e590abe38280e585a8e381a6e8a8b1e58faf"),
        pack("H*","626c6f67e7ad89e38386e382ade382b9e38388e381a8e99d99e6ada2e794bbe585ace9968be58faf"),
        pack("H*","e38386e382ade382b9e38388e381aee381bfe585ace9968be58faf"),
        pack("H*","e585ace9968be4b88de58faf"),
        "\xE3\x81\x9D\xE3\x81\xAE\xE4\xBB\x96",
      ],
    },
    is_nullable => 0,
  },
  "avoiddup",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "experience",
  {
    data_type => "enum",
    extra => {
      list => [
        "\xE5\x88\x9D\xE3\x82\x81\xE3\x81\xA6",
        pack("H*","e698a8e5b9b4e381abe7b69ae38184e381a632e59b9ee79bae"),
        pack("H*","e7b699e7b69ae38197e381a633efbd9e35e59b9ee79bae"),
        pack("H*","e381b2e38195e38197e381b6e3828a"),
        pack("H*","36e59b9ee79baee4bba5e4b88a"),
      ],
    },
    is_nullable => 0,
  },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 128 },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-05 21:21:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ibSS8SL7QAfrIxI9UO+SIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
