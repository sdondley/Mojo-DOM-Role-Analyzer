package Mojo::DOM::Role::Analyzer ;

use strict;
use warnings;
use Role::Tiny;
use Carp;

around find => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig(@_)->with_roles('+Extra');
};

use overload "cmp" => sub { $_[0]->compare(@_) }, fallback => 1;

sub element_count {
  my $self = shift;
  return $self->descendant_nodes->grep(sub { $_->type eq 'tag' })->size;
}

sub _get_selectors {
  my ($s, $sel1, $sel2);
  if (!$_[2]) {
    $s = shift;
    $sel1 = $s->selector;
    if (ref $_[0]) {
      $sel2 = $_[0]->selector;
    } else {
      $sel2 = $s->root->at($_[0])->selector;
    }
  } else {
    $s = $_[0];
    $sel1 = $_[1]->selector;
    $sel2 = $_[2]->selector;
  }
  return ($s, $sel1, $sel2);
}

sub is_ancestor_to {
  my $s = shift;
  my $arg = shift;
  my $sel1 = $s->selector;
  my $sel2 = $arg->selector;

  return $sel2 =~ /^\Q$sel1\E/ ? 1 : 0;
}

# traverses the DOM upward to find the closest tag node
sub closest_up {
  return _closest(@_, 'up');
}

sub closest_down {
  return _closest(@_, 'down');
}

sub _closest {
  my $s = shift;
  my $sel = $s->selector;
  my $tag = shift;
  my $dir = shift || 'up';
  if ($dir ne 'up') {
    $dir = 'down';
  }

  my $found;
  if ($dir eq 'up') {
    $found = $s->root->find($tag)->grep(sub { ($s cmp $_) > 0  } );
  } else {
    $found = $s->root->find($tag)->grep(sub { ($s cmp $_) < 0  } );
  }

  return 0 unless $found->size;

  my @selectors;
  foreach my $f ($found->each) {
    push @selectors, $f->selector;
  }

  if (@selectors == 1) {
    return $s->root->at($selectors[0]);
  }

  my @sorted = sort { $s->root->at($a) cmp $s->root->at($b) } @selectors;
  if ($dir eq 'up') {
    return $s->root->at($sorted[-1]);  # get furtherest from the top (closest to node of interest)
  } else {
    return $s->root->at($sorted[0]);   # get futherest from the bottom (closest to node of interest)
  }

}

# determine if a tag A comes before or after tag B in the dom
sub compare {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  foreach my $p1 (@t1_path) {
    my $p2 = shift(@t2_path);
    next if $p1 eq $p2;
    my ($p1_tag, $p1_num) = split /:/, $p1;
    my ($p2_tag, $p2_num) = split /:/, $p2;

    next if $p1_num eq $p2_num;
    return $p1_num cmp $p2_num;
  }
}

sub distance {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

  my $common = $s->common($s->root->at($sel1), $s->root->at($sel2));
  my $dist_leg1 = $s->root->at($sel1)->depth - $common->depth;
  my $dist_leg2 = $s->root->at($sel2)->depth - $common->depth;

  return $dist_leg1 + $dist_leg2;
}

sub depth {
  my $s = shift;
  my $sel = $s->selector;
  my @parts = split /\s>\s/, $sel;
  return scalar @parts;
}

sub deepest {
  my $s = shift;
  my $deepest_depth = 0;
  foreach my $c ($s->descendant_nodes->grep(sub { $_->type eq 'tag' })->each) {
    my $depth = $c->depth;
    $deepest_depth = $depth if $depth > $deepest_depth;
  }
  return $deepest_depth;
}

# find the common ancestor between a node and another node or group of nodes
sub common {
# uncomment to debug
# use Log::Log4perl::Shortcuts qw(:all); # for development only
#  if (ref $_[0]) { logd ref $_[0]; } else { logd $_[0]; }
#  if (ref $_[1]) { logd ref $_[1]; } else { logd $_[1]; }
#  if (ref $_[2]) { logd ref $_[2]; } else { logd $_[2]; }

   # The argument handling is a bit confusing. Keep these important notes in mind while reading this code:

   # 1) This method is called on Mojo::DOM objects (obviously)
   # 2) Don't confuse this mthod with its sister method also named "common"
   #    in Mojo::DOM::Collection::Extra which works with Mojo::Collection objects
   # 3) The argument handling below works for the different types of common syntaxes noted
   #    below in the comments.

  my ($s, $sel1, $sel2);

  # function-like use of common: $dom->commont($dom1, $dom2)
  if (ref $_[1] && ref $_[2]) {
    $s = $_[0];
    $sel1 = $_[1]->selector;
    $sel2 = $_[2]->selector;
  # DWIM syntax handling
  } else {
    if (!$_[1] && !$_[2]) {                         # $dom->at('div');
      my $s = shift;
      return $s->root->find($s->selector)->common;
    } elsif ($_[1] && !ref $_[1] && !$_[2]) {       # $dom->at('div.first')->common('p');
      $s = shift;
      $sel1 = $s->selector;
      $sel2 = $s->root->at(shift)->selector;
    }
  }

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  my @common_path;
  foreach my $seg (@t1_path) {
    my $seg2 = shift @t2_path;
    last if !$seg2 || $seg ne $seg2;
    push @common_path, $seg2;
  }

  my $common_selector = join ' > ', @common_path;

  return $s->root->at($common_selector);

}

# get secondary enclosing tags
sub _gsec {
  my $s            = shift;
  my $selector     = shift;
  my $largest      = 0;
  my $node_counter = 0;
  my $largest_node = 0;

  my @sub_enclosing_nodes;
  foreach my $c ($s->children->each) {
    my $size = $c->find($selector)->size;
    next unless $size;

    my $depth_total;
    my $same_depth    = 1;
    my $depth_tracker = undef;

    if ($size > $largest) {
      $largest      = $size;
      $largest_node = $node_counter;
    }

    foreach my $t ($c->find($selector)->each) {
      my $depth = $t->depth;

      if ($depth_tracker && $depth != $depth_tracker) {
        $same_depth = 0;
      }

      $depth_tracker = $depth;
      $depth_total  += $depth;
    }
    push @sub_enclosing_nodes, { selector                 => $c->selector,
                                 size                     => $size,
                                 avg_tag_depth            => ($depth_total / $size),
                                 all_tags_have_same_depth => $same_depth };
  }
  return @sub_enclosing_nodes;
}

sub tag_analysis {
  my $s        = shift;
  my $selector = shift;

  carp "A selector argument must be passed to the tag_analysis method"
    unless $selector;

  my @sub_enclosing_nodes = $s->_tag_analysis_helper($selector);

  foreach my $sn (@sub_enclosing_nodes) {
    next if $sn->{all_tags_have_same_depth};
    my $ec = $s->at($sn->{selector})->common($selector);
    my @enclosing_nodes = $ec->_tag_analysis_helper($selector);
    push @sub_enclosing_nodes, @enclosing_nodes;
  }

  # cleanup any unnecessary nodes at top of the array wrapping the smallest enconpassing dom
  my $total_tags = $s->find($selector)->size;
  my $number_of_tags = grep { $_->{size} == $total_tags } @sub_enclosing_nodes;
  splice @sub_enclosing_nodes, 0, $number_of_tags - 1;

  return @sub_enclosing_nodes;
}

sub _tag_analysis_helper {
  my $s        = shift;
  my $selector = shift;
  my @sub_enclosing_nodes = shift;

  carp "A selector argument must be passed to the tag_analysis method"
    unless $selector;

  return _gsec($s, $selector);
}


1; # Magic true value
# ABSTRACT: miscellaneous methods for analyzing a DOM

__END__

=head1 OVERVIEW

Provides methods for analyzing a DOM.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Mojo::DOM;

  my $html = '<html><head></head><body><p class="first">A paragraph.</p><p class="last">boo<a>blah<span>kdj</span></a></p><h1>hi</h1></body></html>';
  my $analyzer = Mojo::DOM->with_roles('+Analyzer')->new($html);

  # return the number of elements inside a dom object
  my $count = $analyzer->at('body')->element_count;

  # get the smallest containing dom object that contains all the paragraph tags
  my $containing_dom = $analyzer->common_ancestor('p');

  # compare DOM objects to see which comes first in the document
  my $tag1 = $analyzer->at('p.first');
  my $tag2 = $analyzer->at('p.last');
  my $result = $analyzer->compare($tag1, $tag2);

  # ALTERNATIVELY

  $analyzer->at('p.first')->compare('p.last');    # 'p.last' is relative to root

  # get the depth level of a dom object relative to root
  # root node returns '1'
  my $depth = $analyzer->at('p.first')->depth;

  # get the deepest depth of the documented
  my $deepest = $analyzer->deepest;

  # SEE DESCRIPTION BELOW FOR MORE METHODS

=head1 DESCRIPTION

=head2 Operators

=head3 cmp

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to determine which comes first in
the dom. See C<compare> method below for return values.

=head2 Methods

=head3 closest_down

  my $closest_down_dom = $dom->at('h1')->closest_down('p');

Returns the node closest to the tag node of interest by searching downward
through the DOM.

Note that "closest" is defined as the node highest in the DOM that is still
below the tag node of interest (or, in the case of L<closeest_up> lowest in the
DOM but still above the tag node of interest), not by the shortest distance
(number of "hops") to the other node.

For example, in the code below, the C<E<lt>h1E<gt>> tag containing "Heading 1"
is five hops away from the C<E<lt>pE<gt>> tag, while the other
C<E<lt>h1E<gt>> tag is only two hops away. But despite being more hops away,
the C<E<lt>h1E<gt>> tag containing "Header 1" is considered to be closer.

    <p>Paragraph</p>
    <div><div><div><div><h1>Heading 1</h1></div></div></div></div>
    <h1>Heading 2</h2>

=head3 closest_up

  my $closest_up_dom = $dom->at('p')->closest_up('h1');

Returns the node closest to the tag node of interest by searching upward
through the DOM.

See the L<closest_down> method for the meaning of the "closest" node and how it
is calculated.

=head3 common

=head4 C<$dom-E<gt>at($tag1)-E<gt>common($tag2)>

=head4 C<$dom-E<gt>common($dom1, $dom2)>

=head4 C<$dom-E<gt>common($selector_str1, $selector_str2)>

=head4 C<$dom-E<gt>at($tag1)-E<gt>common>

  # Find the common ancestor for two nodes
  my $common $dom->at('div.bar')->common('div.foo');    # 'div.foo' is relative to root

  # OR

  # Pass in two $dom objects
  my $dom1 = $dom->at('div.bar');
  my $dom2 = $dom->at('div.foo');
  my $common = $dom->common($dom1, $dom2);

  # OR

  # Pass in two selectors
  my $common = $dom->common($dom->at('p')->selector, $dom->at('h1')->selector);

  # OR

  # Find the common ancestor for all paragraph nodes with class "foo"
  # This syntax is a wrapper for the Mojo::Collection::Role::Extra->common method
  my $common = $dom->at('p.foo')->common;

Returns the lowest common ancestor node between two nodes or
betwween a node and a group of nodes sharing the same selector.

See L<Mojo::Collection::Role::Extra/common> for a similar method that is on Mojo::Collections.

=head3 compare

=head4 C<$dom-E<gt>at($tag1)-E<gt>compare($tag2)>

=head4 C<compare($dom1, $dom2)>

=head4 C<$dom1 cmp $dom2>

  $dom->at('p.first')->compare('p.last');    # 'p.last' is relative to root

  # OR

  my $dom1 = $dom->at('p.first');
  my $dom2 = $dom->at('p.last');
  my $result = $dom->compare($dom1, $dom2);

  # OR with overloaded 'cmp' operator

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to see which comes first in the DOM.

=over 1

=item * Returns a value of '-1' if the first argument comes before (is less than) the second.

=item * Returns a value of '0' if the first and second arguments are the same.

=item * Returns a value of '1' if the first argument comes after (is greater than) the second.

=back

=head3 deepest

  my $deepest_depth = $dom->deepest;

Finds the deeepest nested level within a node.

=head3 depth

  my $depth = $dom->at('p.first')->depth;

Finds the nested depth level of a node. The root node returns 1.

=head3 distance

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($selector)>

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($dom)>

=head4 C<$dom-E<gt>distance($dom1, $dom2)>

Returns the distance, aka number of "hops," between two nodes.

The value is calculated by first finding the lowest common ancestor node for
the two nodes and then getting the distance between the lowest common ancestor
node and each of the two nodes. The two distances are then added togethr to
determine the total distance between the two nodes.

=head3 element_count

  $count = $dom->element_count;

Returns the number of elements in a dom object, including children of children
of children, etc.

=head3 is_ancestor_to

  $is_ancestor = $s->('h1')->is_ancestor_to('p.foo');

Returns true if a node is an ancestor to another node, false otherwise.

=head3 tag_analysis

  @enclosing_tags = $dom->tag_analysis('p');

Searches through a DOM for tag nodes that enclose tags matching the given
selector (see L<common_ancestor> method) and returns an array of hash references
with the following information for each of the enclosing nodes:

  {
    "all_tags_have_same_depth" => 1,   # whether enclosed tags within the enclosing node have the same depth
    "avg_tag_depth" => 8,              # average depth of the enclosed tags
    "selector" => "body:nth-child(2)", # the selector for the enclosing tag
    "size" => 1                        # total number of tags of interest that are descendants of the enclosing tag
  }

=head1 SEE ALSO

L<Mojo::DOM>
L<Mojo::Collection::Role::Extra>
