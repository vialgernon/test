#!/usr/bin/perl
use DBI;

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

sub _query_bookmark_folder_id {
	my ($opt, $user_id, $opt_query_value) = @_;
	my $opt_query;
	my $handle_null;
	
	# $opt == 1, qeury by bookmark_folder_name; $opt == 2, query by parent_id
	if ($opt == 1) {
		$opt_query = "bookmark_folder_name";
	}elsif ($opt == 2) {
		$opt_query = "parent_id";
	}else {
		print "Unkown opt\n";
		exit;
	}
	chomp ($user_id, $opt_query_value);
	
	if ($opt_query_value eq "") {
		$handle_null = 'is';
		$opt_query_value = undef;
	}else {
		$handle_null = '=';
	}

	my $dbh = _db_connect();
	my $sth = $dbh->prepare("SELECT bookmark_folder_id 
							FROM bookmark_folder 
							WHERE user_id = ? AND $opt_query $handle_null ?");
	$sth->execute($user_id, $opt_query_value) or die $DBI::errstr;
	my @result;
	while (my @bookmark_folder_id = $sth->fetchrow_array()) {
		push (@result, @bookmark_folder_id);
	}

	return @result;
}

sub create {
	print "Input user id = ";
	my $user_id = <>;
	print "Input bookmark folder name = ";
	my $bookmark_folder_name = <>;
	print "Input parent id = ";
	my $parent_id = <>;
	print "How many folders you want to create = ";
	my $number = <>;
	chomp ($user_id, $bookmark_folder_name, $parent_id, $number); 
	my @parameters;
	for (my $i = 1; $i <= $number; $i++){
		@parameters = ('--create', $user_id, $bookmark_folder_name."_".$i, $parent_id );
		system($^X, "DBoperation.pl", @parameters );
		my @parent_ids = _query_bookmark_folder_id(1, $user_id, $bookmark_folder_name."_".$i);
		for (my $j = 1; $j <= $number; $j++) {
			@parameters = ('--create', $user_id, $bookmark_folder_name."_".$i."_".$j, $parent_ids[0] );
			system($^X, "DBoperation.pl", @parameters );
		}
	}
}

sub mult_delete{
	print "Input user id = ";
	my $user_id = <>;
	print "Input parent id = ";
	my $parent_id = <>;
	chomp ($user_id, $parent_id);
	my @bookmark_folder_ids = _query_bookmark_folder_id(2, $user_id, $parent_id);
	my @parameters = ('--mult_delete', $user_id, $parent_id );
	system($^X, "DBoperation.pl", @parameters );
	for (my $i = 0; $i < @bookmark_folder_ids; $i++) {
		my @parameters = ('--mult_delete', $user_id, $bookmark_folder_ids[$i] );
		system($^X, "DBoperation.pl", @parameters );
	}
}

sub reset_auto_increment {
	my $dbh = _db_connect();
	my $sth = $dbh->prepare("ALTER TABLE bookmark_folder AUTO_INCREMENT = 1");
	$sth->execute() or die $DBI::errstr;
	print "Reset auto_increment success!\n"
}

my %option = (
	"create" 		=> \&create,
	"mult_delete" 	=> \&mult_delete,
	"reset" 		=> \&reset_auto_increment
);

print "Actions: create, mult_delete, reset\n";
print "Input action: ";
my $action = <>;
chomp $action;

=haed another way to execute dispatch table
my $option = $option{$action};
$option->() if defined $option;
=cut

if (exists $option{$action}) {
	$option{$action}->();
}else {
	print "Not support!!"
}
