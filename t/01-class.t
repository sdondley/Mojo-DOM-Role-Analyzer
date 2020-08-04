use Test::Most;
use Mojo::DOM;

use strict;
use warnings;











my $tests = 5; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => 5;
diag( "Running my tests" );

my $html = '<html><head></head><body><p class="first">A paragraph.</p><p class="last">boo<a>blah<span>kdj</span></a></p><h1>hi</h1></body></html>';

my $ex = Mojo::DOM->with_roles('+Analyzer')->new($html);

my $count = $ex->at('body')->element_count;
is $count, 5, 'gets element count';

my $tag = $ex->parent_ptags->tag;
is $tag, 'body', 'gets correct container tag for paragraphs';

my $tag1 = $ex->at('p.first');
my $tag2 = $ex->at('p.last');

my $result = $ex->compare_tags($tag1, $tag2);
is $result, -1, 'can compare tags';

my $depth = $ex->at('p.first')->depth;
is $depth, 3, 'gets depth';

my $deepest = $ex->deepest;
is $deepest, 5, 'gets deepest depth';
