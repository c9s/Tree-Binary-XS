package Tree::Binary::XS;

use 5.018002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tree::Binary ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Tree::Binary::XS', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tree::Binary::XS - Perl extension for manipulating binary tree structure

=head1 SYNOPSIS

  use Tree::Binary::XS;
  my $tree = Tree::Binary::XS->new({ by_key => 'id' });

  $tree->insert({ foo => 'bar', id => 11 });

  # to insert multiple keys one time.
  $tree->insert([{ foo => 'bar', id => 11 }, ... ]);

  $ret->exists(10);
  $ret->exists({ id => 10, 'name' => 'Bob' });

  # Use specified key instead of the key from payload
  $tree->insert(10, { foo => 'bar' });

  # Bulk insert
  @ret = $tree->insert_those([{ id => 10, 'name' => 'Bob' },  { id => 3, 'name' => 'John' }, { id => 2, 'name' => 'Hank' } ]);

  $tree->update(10, { foo => 'bar' })

  $n = $tree->search(10);

  $tree->exists(10);
  $tree->exists({ foo => 'bar' , id => 10 });

=head1 DESCRIPTION

Please note this extension is not compatible with the L<Tree::Binary> package, this module redesigned and simplified 
the interface of manipulating tree structure.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Lin Yo-an, E<lt>c9s@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Lin Yo-an

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
