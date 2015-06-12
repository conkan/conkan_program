use utf8;
package conkan::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-04-05 21:14:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EqhK2kDFm87rVTN02bi4/g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.0012';
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('./sql');
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
