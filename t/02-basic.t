use Test::Most;
use Test::NoWarnings;
use Log::Log4perl::Shortcuts qw(:all);
BEGIN {
  use Test::File::ShareDir::Module { "Mojo::DOM::Role::Analyzer" => "share/" };
  use Test::File::ShareDir::Dist { "Mojo-DOM-Role-Analyzer" => "share/" };
}
use Mojo::DOM::Role::Analyzer;








my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;
diag( "Running my tests" );

