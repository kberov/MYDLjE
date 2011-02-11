package MYDLjE::M;
use base 'MYDLjE::Base';
use DBIx::Simple;
use SQL::Abstract;
sub dbix {
  my $self = shift;
  return $self->{dbix} if $self->{dbix};
  $self->{dbix} = DBIx::Simple->connect(
            $self->config('db_dsn'),
            $self->config('db_user'),
            $self->config('db_password'),
            {

                #'private_'. $package => $package ,
                RaiseError  => 1,
                HandleError => sub { Carp::confess(shift) },
            }
        );
        $self->{dbix}->lc_columns = 1;
        $self->{dbix}->abstract   = SQL::Abstract->new(

            #debug => $self->{debug}{enabled} ? $self->{debug}{sql} : 0
        );
        my $onconnect_do = $self->config('dbh_onconnect_do');
        if ($onconnect_do
            and reftype($onconnect_do) eq 'ARRAY')
        {
            foreach my $do (@{$onconnect_do}) {
                if ($do) { $self->{dbix}{dbh}->do($do); }
            }
        }
    }

    return $self->{dbix}
}  
1;

__END__

=head1 NAME

MYDLjE::M - base class for MYDLjE models

=head1 DESCRIPTION

Thhis is the base class from which all Models should inherit.

=head1 ATTRIBUTES

=head1 METHODS


=head1 SEE ALSO
