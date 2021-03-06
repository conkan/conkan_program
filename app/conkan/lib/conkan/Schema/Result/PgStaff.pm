use utf8;
package conkan::Schema::Result::PgStaff;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgStaff - staff info

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

=head1 TABLE: C<pg_staff>

=cut

__PACKAGE__->table("pg_staff");

=head1 ACCESSORS

=head2 staffid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 account

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 role

  data_type: 'enum'
  extra: {list => ["NORM","ROOT","PG","ADMIN"]}
  is_nullable: 0

=head2 ma

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 telno

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 regno

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 tname

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 tnamef

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 otheruid

  data_type: 'text'
  is_nullable: 1

=head2 lastlogin

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

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
  "staffid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "account",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "passwd",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "role",
  {
    data_type => "enum",
    extra => { list => ["NORM", "ROOT", "PG", "ADMIN"] },
    is_nullable => 0,
  },
  "ma",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "telno",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "regno",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "tname",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "tnamef",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "otheruid",
  { data_type => "text", is_nullable => 1 },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
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

=item * L</staffid>

=back

=cut

__PACKAGE__->set_primary_key("staffid");

=head1 UNIQUE CONSTRAINTS

=head2 C<account_UNIQUE>

=over 4

=item * L</account>

=back

=cut

__PACKAGE__->add_unique_constraint("account_UNIQUE", ["account"]);

=head1 RELATIONS

=head2 login_logs

Type: has_many

Related object: L<conkan::Schema::Result::LoginLog>

=cut

__PACKAGE__->has_many(
  "login_logs",
  "conkan::Schema::Result::LoginLog",
  { "foreign.staffid" => "self.staffid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pg_programs

Type: has_many

Related object: L<conkan::Schema::Result::PgProgram>

=cut

__PACKAGE__->has_many(
  "pg_programs",
  "conkan::Schema::Result::PgProgram",
  { "foreign.staffid" => "self.staffid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pg_progresses

Type: has_many

Related object: L<conkan::Schema::Result::PgProgress>

=cut

__PACKAGE__->has_many(
  "pg_progresses",
  "conkan::Schema::Result::PgProgress",
  { "foreign.staffid" => "self.staffid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-05-09 14:06:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qeFZvTw2Nhus9W5BUlW4QA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
