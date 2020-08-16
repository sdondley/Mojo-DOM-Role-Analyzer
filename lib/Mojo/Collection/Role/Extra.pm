package Mojo::Collection::Role::Extra ;

use Role::Tiny;

sub common {
  my $c = shift;
  my $size = $c->size;
  my $current_node = $c->first;
  my $parent_node;
  my $enclosed;
  do  {
    $parent_node = $current_node->parent;
    $enclosed = $c->grep(sub { $parent_node->is_ancestor_to($_) } );
    $current_node = $parent_node;
  } while ($size > $enclosed->size);

  return $parent_node;
}

1; # Magic true value
# ABSTRACT: provides methods for use with Mojo::DOM::Role::Analyzer


__END__

=head1 OVERVIEW

A role for extending Mojo::Collection with methods for use with L<Mojo::DOM::Role::Analyzer>

=head1 DESCRIPTION

=head2 METHODS

=head3 common

  $dom->find('p')->common;
  $dom->at('div.foo')->find('p');

Returns the lowest common ancestor for all nodes in a collection.

=head1 SEE ALSO

L<Mojo::DOM::Role::Analyzer>
