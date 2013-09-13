use strict;
use warnings;

use Test::More tests => 9;
use Test::Deep;
use Test::Fatal;

use Test::Requires {
    'Specio::Declare' => '0.08',
};
use Test::Requires {
    'Moose' => '2.1000',
};

BEGIN {
    use_ok('MooseX::Storage');
    use_ok('MooseX::Storage::Engine');
}

use Specio::Declare 'object_isa_type';
my $BAR = object_isa_type('Bar');

=pod

This is just a simple example of defining
a custom type handler to take care of custom
inflate and deflate needs.

=cut

{
    package Bar;
    use Moose;

    has 'baz' => (is => 'rw', isa => 'Str');
    has 'boo' => (is => 'rw', isa => 'Str');

    sub encode {
        my $self = shift;
        $self->baz . '|' . $self->boo;
    }

    sub decode {
        my ($class, $packed) = @_;
        my ($baz, $boo) = split /\|/ => $packed;
        $class->new(
            baz => $baz,
            boo => $boo,
        );
    }

    MooseX::Storage::Engine->add_custom_type_handler(
        $BAR => (
            expand   => sub { Bar->decode(shift) },
            collapse => sub { (shift)->encode    },
        )
    );

    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'bar' => (
        is      => 'ro',
        isa     => $BAR,
        default => sub {
            Bar->new(baz => 'BAZ', boo => 'BOO')
        }
    );
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

isa_ok($foo->bar, 'Bar');

cmp_deeply(
$foo->pack,
{
    __CLASS__ => "Foo",
    bar       => "BAZ|BOO",
},
'... got correct packed structure');

{
    my $foo = Foo->unpack({
        __CLASS__ => "Foo",
        bar       => "BAZ|BOO",
    });
    isa_ok($foo, 'Foo');

    isa_ok($foo->bar, 'Bar');

    is($foo->bar->baz, 'BAZ', '... got the right stuff');
    is($foo->bar->boo, 'BOO', '... got the right stuff');
}





