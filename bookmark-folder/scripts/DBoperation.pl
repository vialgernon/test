#!/usr/bin/perl
use DBI;
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

sub _db_connect {
  my $driver = "mysql"; 
  my $database = "shard_1";
  my $dsn = "DBI:$driver:database=$database";
  my $db_user_id = "root";
  my $db_user_password = "xxx";
  my $dbh = DBI->connect($dsn, $db_user_id, $db_user_password ) or die $DBI::errstr;

  return $dbh;
}

sub insert_bookmarks {
  if (_check_parameters() < 5) {
    print "please provide complete info! user_id, object_id, object_name, owner_name, owner_id \n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $object_id, $object_name, $owner_name, $owner_id) = @ARGV;
  my $parent_id = undef;

  my $dbh = _db_connect();
  my $sth = $dbh->prepare("INSERT INTO bookmarks
                         (user_id, object_id, owner_name, object_name, owner_id, parent_id )
                          values
                         (?,?,?,?,?,?)");
  $sth->execute($user_id, $object_id, $owner_name, $object_name, $owner_id, $parent_id) 
        or die $DBI::errstr;
  print "Create bookmarks $object_name success!\n";
  $sth->finish();
}

sub delete_bookmarks {
  if (_check_parameters() < 2) {
    print "please provide complete info! user_id, object_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $object_id) = @ARGV;

  my $dbh = _db_connect();
  my $sth = $dbh->prepare("DELETE FROM bookmarks
                         WHERE user_id = ? AND object_id = ?");
  $sth->execute( $user_id, $object_id ) or die $DBI::errstr;
  print "The bookmark deleted\n";
  $sth->finish();
}

sub insert_bookmark_folder {
  if (_check_parameters() < 2) {
    print "please provide complete info! user_id, bookmark_folder_name, parent_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $bookmark_folder_name, $parent_id) = @ARGV;
  if ($parent_id eq "") {
    $parent_id = undef;
  }

  my $dbh = _db_connect();
  my $sql_statement = "INSERT INTO bookmark_folder (user_id, bookmark_folder_name, parent_id ) values (?,?,?)"; 
  my $sth = $dbh->prepare( $sql_statement );
  $sth->execute($user_id, $bookmark_folder_name, $parent_id) 
            or die $DBI::errstr;
  print "Create bookmark_folder $bookmark_folder_name success!\n";
}

sub delete_bookmark_folder {
  if (_check_parameters() < 2) {
    print "please provide complete info! user_id, bookmark_folder_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $bookmark_folder_id) = @ARGV;

  my $dbh = _db_connect();
  my $sth = $dbh->prepare("DELETE FROM bookmark_folder
                          WHERE user_id = ? AND bookmark_folder_id = ?");
  $sth->execute( $user_id, $bookmark_folder_id ) or die $DBI::errstr;
  print "The bookmark_folder deleted\n";
  $sth->finish();
}

sub delete_mult_bookmark_folder {
  if (_check_parameters() < 1) {
    print "please provide complete info! user_id, parent_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $parent_id) = @ARGV;
  my $handle_null;
  if ($parent_id eq "") {
    $handle_null = 'is';
    $parent_id = undef;
  }
  else {
    $handle_null = '=';
  }

  my $dbh = _db_connect();
  my $sth = $dbh->prepare("DELETE FROM bookmark_folder
                          WHERE user_id = ? AND parent_id $handle_null ?");
  $sth->execute( $user_id, $parent_id ) or die $DBI::errstr;
  print "The bookmark_folders deleted\n";
  $sth->finish();
}

sub query_folder {
  if (_check_parameters() < 1) {
    print "please provide complete info! user_id, parent_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $parent_id) = @ARGV;
  my $handle_null;
  if ($parent_id eq "") {
    $handle_null = 'is';
    $parent_id = undef;
  }
  else {
    $handle_null = '=';
  }

  my $dbh = _db_connect();
  my $sth = $dbh->prepare("SELECT *
                          FROM bookmarks 
                          WHERE user_id = ? AND parent_id $handle_null ?");
  $sth->execute( $user_id, $parent_id ) or die $DBI::errstr;

  my $sth2 = $dbh->prepare("SELECT *
                          FROM bookmark_folder 
                          WHERE user_id = ? AND parent_id $handle_null ?");
  $sth2->execute( $user_id, $parent_id ) or die $DBI::errstr;
  
  my $rows = $sth->rows + $sth2->rows;
  print "Number of rows found : $rows\n";

  while (my ($user_id, $object_id, $owner_name, $object_name, $owner_id, $parent_id) = $sth->fetchrow_array()) {
     print "User_id = $user_id, Object_id = $object_id, Owner_name = $owner_name, Object_name = $object_name, Owner_id = $owner_id, Parent_id = $parent_id\n";
  }
  $sth->finish();
  print "Under user $user_id folder\n";
  while (my ($user_id, $bookmark_folder_id, $bookmark_folder_name, $parent_id) = $sth2->fetchrow_array()) {
     print "User_id = $user_id, Bookmark_folder_id = $bookmark_folder_id, Bookmark_folder_name = $bookmark_folder_name, Parent_id = $parent_id\n";
  }
  $sth2->finish();
}

sub update_bookmarks {
  if (_check_parameters() < 2) {
    print "please provide complete info! user_id, object_id, parent_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $object_id, $parent_id) = @ARGV;

  my $dbh = _db_connect();
  my $sth = $dbh->do("UPDATE bookmarks
                      SET parent_id = ?
                      WHERE user_id = ? AND object_id = ?",
                      undef, $parent_id, $user_id, $object_id );
  print "Update bookmarks success!\n"
}

sub update_bookmark_folder {
  if (_check_parameters() < 2) {
    print "please provide complete info! user_id, bookmark_folder_id, parent_id\n";
    exit;
  }
=head  if (_check_user_exist() != 1) {
    print "Unexist user\n";
    exit;
  }
=cut
  my ($user_id, $bookmark_folder_id, $parent_id) = @ARGV;

  my $dbh = _db_connect();
  my $sth = $dbh->do("UPDATE bookmark_folder
                      SET parent_id = ?
                      WHERE user_id = ? AND bookmark_folder_id = ?",
                      undef,  $parent_id, $user_id, $bookmark_folder_id );
  print "Update bookmark_folder success!\n"
}

sub _check_parameters {
  foreach my $input(@ARGV){
    print "$input\n";
  }
  my $count = scalar @ARGV;
  print "$count\n";

  return $count;
}

sub _check_user_exist {
  my ($user_id) = @ARGV;

  #Connect to osdp database
  my $driver = "mysql"; 
  my $database = "osdp";
  my $dsn = "DBI:$driver:database=$database";
  my $db_user_id = "root";
  my $db_user_password = "safesync";
  my $dbh = DBI->connect($dsn, $db_user_id, $db_user_password ) or die $DBI::errstr;

  my $sth = $dbh->prepare("SELECT user_id
                          FROM users 
                          WHERE user_id = ?");
  my $result = $sth->execute( $user_id ) or die $DBI::errstr;
  return $result;
}

GetOptions ( "add"                => \&insert_bookmarks,
             "remove"             => \&delete_bookmarks,
             "create"             => \&insert_bookmark_folder,
             "delete"             => \&delete_bookmark_folder,
             "mult_delete"        => \&delete_mult_bookmark_folder,
             "show"               => \&query_folder,
             "move"               => \&update_bookmarks,
             "move_folder"        => \&update_bookmark_folder) or pod2usage(0);
pod2usage(0) if (@ARGV == 0);

__END__

=head1 SYNOPSIS

sample [options] [parameters]
  
  Options:
    --add                   add a bookmark
    --remove                delete a bookmark
    --create                create a bookmark folder
    --delete                delete a bookmark folder
    --mult_delete           delete all bookmark folder under a specified bookmark folder
    --show                  display the specified bookmarks page content
    --move                  move the bookmark to specified bookmark folder
    --move_folder           move the bookmark folder to specified bookmark folder

  Parameters:
    [user_id, object_id, object_name, owner_name, owner_id, bookmark_folder_id, bookmark_folder_name, parent_id]

=cut