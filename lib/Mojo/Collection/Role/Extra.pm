package Mojo::Collection::Role::Extra ;

use Role::Tiny;

#use Log::Log4perl::Shortcuts qw(:all);

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
# ABSTRACT: this is what the module does


__END__

=head1 OVERVIEW

Provide overview of who the intended audience is for the module and why it's useful.

=head1 SYNOPSIS

  use {{$name}};

=head1 DESCRIPTION

=method method1()



=method method2()



=func function1()



=func function2()



=attr attribute1



=attr attribute2



#=head1 CONFIGURATION AND ENVIRONMENT
#
#{{$name}} requires no configuration files or environment variables.


=head1 DEPENDENCIES

=head1 AUTHOR NOTES

=head2 Development status

This module is currently in the beta stages and is actively supported and maintained. Suggestion for improvement are welcome.

- Note possible future roadmap items.

=head2 Motivation

Provide motivation for writing the module here.

#=head1 SEE ALSO
