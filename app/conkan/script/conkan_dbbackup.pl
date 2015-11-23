#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;
use YAML;

sub main {
    my ( $cnf, $dir ) = @_;

    my $mysqlfmt = '/usr/bin/mysqldump --user=%s --password=%s --host=%s ' .
                   '%s --single-transaction --flush-logs -r %s';
    my $gzipfmt  = '/usr/bin/gzip -9 %s';
    my $bkffmt   = '%s/%s.conkan_backup.sql';
    my $datefmt  = '%4d%02d%02d%02d%02d';

    usage() unless ( $cnf && $dir && ( -s $cnf ) && ( -d $dir ) );

    try {
        my $config = YAML::LoadFile( $cnf );
        my $dbinfo = $config->{'Model::ConkanDB'}->{'connect_info'};
        my $user = $dbinfo->{'user'};
        my $pswd = $dbinfo->{'password'};
        my ( $dbname, $host ) = ( split( /:/, $dbinfo->{'dsn'} ) )[2,3];
        my @dt = localtime();
        $dt[5] += 1900;
        $dt[4] += 1;
        my $date = sprintf( $datefmt,  $dt[5], $dt[4], $dt[3], $dt[2], $dt[1] );
        $dir =~ s/\/$//;
        my $bkf  = sprintf( $bkffmt,   $dir, $date );
        my $cmd  = sprintf( $mysqlfmt, $user, $pswd, $host, $dbname, $bkf );
        my $fh;
        open( $fh, '-|', $cmd ) or die $!;
        $cmd = sprintf( $gzipfmt, $bkf );
        open( $fh, '-|', $cmd ) or die $!;
    } catch {
        usage( shift );
    };
    return;
}

sub usage {
    my ( $e ) = @_;
    print "$e\n" if defined($e);
    print "Usage: conkan_dbbackup.pl <conkan.yml> <backup_dir>\n";
    exit;
}

main(@ARGV);

exit;

1;

=encoding utf-8

=head1 NAME

conkan_dbbackup.pl - conkan Database BackupScript

=head1 SYNOPSIS

conkan_dbbackup.pl <conkan.yml> <backup_dir>

    conkan.yml      : conkan config file
    backup_dir      : backup create directory

=head1 DESCRIPTION

Backup conkan Database. (full backup, and compress by gzip)

Backup File Name is YYYMMDDhhmm.conkan_backup.sql.gz.

=head1 AUTHORS

Studio-REM

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
