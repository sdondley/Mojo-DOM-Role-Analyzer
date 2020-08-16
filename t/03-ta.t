use Test::Most;
use Mojo::DOM;

use strict;
use warnings;
use Path::Tiny;











my $tests = 2; # keep on line 17 for ,i (increment and ,d (decrement)
my $skip_most = 0;
plan tests => $tests;
diag( "Running my tests" );

my $html = '<div class="one"><div class="two"><div class="three"><p class="booboo">hi</p></div></div></div>';


my $ex = Mojo::DOM->with_roles('+Analyzer')->new($html);



#my @analysis = $ex->tag_analysis('p');
my $result =

        [
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '4',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 1,
    'selector' => 'div:nth-child(1) > div:nth-child(1) > div:nth-child(1)',
    'size' => 1,
    'top_level' => 1
  }
];

#is_deeply (\@analysis, $result, 'gets correct tag analysis result');


$html = '<div class="one"><p>lkj</p><div class="two"><div class="three"><p class="booboo">hi</p></div></div></div>';
$ex = Mojo::DOM->with_roles('+Analyzer')->new($html);
#@analysis = $ex->tag_analysis('p');
$result =
        [
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '3',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 1,
    'selector' => 'div:nth-child(1)',
    'size' => 2,
    'top_level' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '4',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 0,
    'selector' => 'div:nth-child(1) > div:nth-child(2)',
    'size' => 1
  }
];

#is_deeply (\@analysis, $result, 'gets correct tag analysis result');

my $file = path('t/complex.html')->slurp_utf8;
$ex = Mojo::DOM->with_roles('+Analyzer')->new($file);
my @analysis = $ex->tag_analysis('p');
