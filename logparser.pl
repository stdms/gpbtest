#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use DBI;

use lib './';
use funcs;

my $conf = funcs::_read_conf( $ENV{LOGPARSERCONF} );
my $rt_com = $conf->{commit_after} || funcs::DEFAULT_COMMIT_AFTER;

my $inf = $ARGV[0];
my $infh;

if ( not defined $inf )
{
    $infh = \*STDIN;
}
else
{
    open $infh, $inf or die "Can't open file $inf: $!\n";
}

# Move this line inside of loop to handle possible db connection loss
# Keep this call outside speed up load twise
my ( $dbh, $isth, $lsth ) = funcs::_db_handles($conf);

# in-chunk row counter
my $r = 0;
while ( my $l = <$infh> )
{
    chomp $l;

    # parse in place to speed up

    # 0 - date
    # 1 - time
    # 2 - internal message id
    # 3 - falg
    # 4 - from/to email address
    # 5..N - misc info
    my ( $date, $time, $int_id, @data ) = split ' ', $l;
    my $str      = join( ' ', $int_id, @data );
    my $datetime = join( ' ', $date,   $time );

    my $flag;
    my $email;

    if ( $data[0] =~ m/\<=|=\>|-\>|\*\*|==/ )
    {
        $flag  = $data[0];
        $email = $data[1];
    }

    $str =~ m/id=(\S+)/;
    my $id = $1 || "Undefined <$int_id>";

    if ( defined $flag && $flag eq '<=' )
    {
        $isth->execute( $datetime, $id, $int_id, $str );
    }
    else
    {
        $lsth->execute( $datetime, $int_id, $str, $email );
    }

    # Check if we have to commit chunk
    $r = ( $r + 1 ) % $rt_com;
    $dbh->commit if ( !$r );
}

close $infh;

funcs::_db_disconnect();

