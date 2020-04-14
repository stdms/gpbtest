package funcs;

use strict;
use warnings;
use utf8;
use feature 'state';

use DBI;

use constant DEFAULT_CFNAME       => 'logparser.conf';
use constant DEFAULT_COMMIT_AFTER => 1;

sub _read_conf
{
    my ($cfname) = @_;

    $cfname //= DEFAULT_CFNAME;
    open my $cfh, '<', $cfname or die "Can't open configuration file $cfname: $!\n";
    my $rs = $/;
    $/ = undef;
    my $conf = <$cfh>;
    $/ = $rs;
    close $cfh;

    $conf = eval $conf;

    return $conf;
}

sub _db_handles
{
    my ($conf) = @_;

    state( $pg, $isth, $lsth );

    if ( not $pg or not $pg->ping )
    {
        $pg = _db_connect($conf);
        undef $isth;
        undef $lsth;
    }
    die "No database connection\n" unless $pg->ping;

    $isth //= $pg->prepare('INSERT INTO message (created, id, int_id, str) VALUES (?, ?, ?, ?)');
    $lsth //= $pg->prepare('INSERT INTO log (created, int_id, str, address) VALUES (?, ?, ?, ?)');

    return $pg, $isth, $lsth;
}

sub _db_connect
{
    my ($conf) = @_;

    my $opts = $conf->{database}{options} || {};
    my $dbh = DBI->connect( $conf->{database}{dsn}, $conf->{database}{username}, $conf->{database}{password}, $opts );

    return $dbh;
}

sub _db_disconnect
{
    my ( $dbh, $isth, $lsth ) = _db_handles();

    $isth->finish;
    $lsth->finish;

    $dbh->commit;
    $dbh->disconnect;
}

1;
