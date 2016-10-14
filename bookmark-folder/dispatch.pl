 #define the table using one anonymous code-ref and one named code-ref
 my %dispatch = (
   "-h" => sub {  return "hello\n"; },
   "--add" => \&say_goodbye
 );
 
 sub say_goodbye {
   return "goodbye\n";
 }
 
 #fetch the code ref from the table, and invoke it
 my $sub = $dispatch{$ARGV[0]};
 print $sub ? $sub->() : "unknown argument\n";
