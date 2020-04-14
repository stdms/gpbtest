#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib './';
use funcs;

use Mojolicious::Lite;

my $conf = funcs::_read_conf( $ENV{LOGPARSERCONF} );

my $dbh = funcs::_db_connect($conf);
die "No database connection\n" unless $dbh->ping;

# add helper methods for interacting with database
helper db => sub {$dbh};

helper search => sub {
    my $self = shift;
    my ($email) = @_;

    my $sth = $self->db->prepare('SELECT created, str FROM log WHERE address = ? ORDER BY int_id, created LIMIT 100;');
    $sth->execute($email);
    my $rows = $sth->fetchall_arrayref;
    $sth->finish;

    $sth = $self->db->prepare('SELECT created, str FROM log WHERE address = ? ORDER BY int_id, created OFFSET 100 LIMIT 1;');
    $sth->execute($email);
    my $rc = $sth->fetchall_arrayref;
    $sth->finish;

    return $rows, scalar @$rc;
};

# setup base route
any '/' => sub {
    my $self = shift;

    $self->render('form');
};

any '/search' => sub {
    my $self = shift;

    my $email = $self->param('email');
    my ( $data, $over100 ) = $self->search($email);
    $self->stash( rows => $data, over100 => $over100 );

    $self->render('data');
};

app->start;

__DATA__

@@ form.html.ep

<!DOCTYPE html>
<html>
<head><title>maillog test</title></head>
<body>
  <form action="/search" method="post">
    Email: <input type="text" name="email"> 
    <input type="submit" value="Search">
  </form>
</body>
</html>

@@ data.html.ep

<!DOCTYPE html>
<html>
<head><title>maillog test search result</title></head>
<body>
  <form action="/search" method="post">
    Email: <input type="text" name="email"> 
    <input type="submit" value="Search">
  </form>
  Data <%if ($over100) {%>(over 100)<% } %>:<br>
  <table border="1">
    <tr>
      <th>created</th>
      <th>log str</th>
    </tr>
    % foreach my $row (@$rows) {
      <tr>
        % foreach my $text (@$row) {
          <td><%= $text %></td>
        % }
      </tr>
    % }
  </table>
</body>
</html>
