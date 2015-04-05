use utf8;
package conkan::Schema::Result::PgSystemConf;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

conkan::Schema::Result::PgSystemConf - å¤§ä¼ç¬èªå®æ°è¨­å®

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

=head1 TABLE: C<pg_system_conf>

=cut

__PACKAGE__->table("pg_system_conf");

=head1 ACCESSORS

=head2 pg_conf_code

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 pg_conf_name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 pg_conf_value

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "pg_conf_code",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "pg_conf_name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "pg_conf_value",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pg_conf_code>

=back

=cut

__PACKAGE__->set_primary_key("pg_conf_code");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-05 21:14:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cLConDshKPW6/xbbAvkbDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
