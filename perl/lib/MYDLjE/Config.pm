package MYDLjE::Config;

#Model for configuration files
use MYDLjE::Base -base;
use YAML::Any();
use Hash::Merge::Simple;
use Data::Dumper;
use Mojo::Log;
has log     => sub { Mojo::Log->new };
has files   => sub { [] };
has configs => sub { [] };
has merger  => 'Hash::Merge::Simple';

#Singleton
my $CONFIG;

#Environment
my ($HOME) = ($ENV{MOJO_HOME} || Cwd::cwd());
my ($MODE) = ($ENV{MOJO_MODE} || 'development');
my ($APP)  = ($ENV{MOJO_APP}  || 'MYDLjE');

sub new {
  my $self = shift->SUPER::new(@_);


  $self->read_config_files;
  return $self;
}

sub stash {
  my $self = shift;
  if ($_[1]) {
    return $self->{config}{$_[0]} = $_[1];
  }
  elsif ($_[0]) {
    return $self->{config}{$_[0]};
  }
  return $self->{config};
}

sub read_config_files {
  my $self = shift;
  my $args = $self->{files} || [@_];

  if (!$self->{files}) {
    {
      no strict 'refs';
      $args = [@{"${APP}::ISA"}] if (@{"${APP}::ISA"} && !@$args);
    }
    push @$args, $APP;
    $self->log->debug('read_config @$args: ' . "@$args");
    for my $i (0 .. @$args - 1) {
      my $filename = $args->[$i];
      $filename =~ s|::|-|g;
      $args->[$i] = "$HOME/conf/" . lc($filename) . ".$MODE.yaml";
    }
    if ($args->[-1] !~ /local\./) {
      my $filename = $APP;
      $filename =~ s|::|-|g;
      push @$args, "$HOME/conf/local." . lc($filename) . ".$MODE.yaml";
    }
    $self->{files} = $args;
  }    # end if (!$self->{files})
  my $config = {};

  foreach my $filename (@$args) {
    my $conf;
    $self->log->debug('will try: ' . $filename);
    if (-r $filename) {
      $self->log->debug('reading: ' . $filename);
      $conf = YAML::Any::LoadFile($filename);
      push @{$self->configs}, $conf;
    }
  }

  #if($self->log->is_debug) {$self->log->debug(Dumper($self->{configs}));}
  $config = $self->merger->dclone_merge(@{$self->configs});

  return $self->{config} = $config;
}

sub write_config_file {
  my ($self, $filename) = @_;
  $filename ||= lc('local.' . $APP);
  $filename =~ s|::|-|g;
  YAML::Any::DumpFile("$HOME/conf/$filename" . ".$MODE.yaml",
    $self->{config});
}

sub singleton { $CONFIG ||= shift->new(@_) }
1;


__END__

=head1 NAME

MYDLjE::Config - use and manipulate system configuration files.

=head1 DESCRIPTION

This clas provides access to MYDLjE settings. They are available in all controllers as 
C<$c-E<gt>app-E<gt>config> attribute and in all aplications like C<$app-E<gt>config> attribute.
It is used also separately to manipulate the local configuration files. 
MYDLjE configuration files are in YAML format.

=head1 ATTRIBUTES

L<MYDLjE::Config> inherits all attributes from L<MYDLjE::Base> and implements/overrides the following ones.

=head2 merger

A singleton instance of L<Hash::Merge> instantiated with 
'RIGHT_PRECEDENT' as behavior. You can change it for a while but be sure 
to turn it back as it was so no strange things happen troughout the application.

=head2 files

Getter for the list of files which were read during initialization.

=head2 log

A L<Mojo::Log> instance.

=head2 singleton

Always returns the same  C<MYDLjE::Config> instance.

=head1 METHODS

=head2 new

Constructor. Calls C<SUPER::new>, and 
L<read_config_files> to read the config files.

=head2 read_config_files

Called in constructor.

  # guess filenames from @ISA
  my $config = $self->new;
  
  #read specific files
  my $config = $self->new(files=>[$ENV{HOME}.'/.top/.secret.yml']);


Reads the list of config files in specifyed order in the C<files> attribute.
If there is no list of files to read, tries C<@ISA> + C<"$app.$MODE.yaml">
+ C<"local.$app.$MODE.yaml">. Foreach element 
converts C<::> to C<->, lowercases it, prepends C<$ENV{MOJO_HOME}/conf/> 
and appends C<.$ENV{MOJO_MODE}> to it. So for example while you develop, 
the list of files I<which could be potentially> read and merged for L<cpanel> is:

  $ENV{MOJO_HOME}/conf/mydlge.development.yaml
  $ENV{MOJO_HOME}/conf/mydlge-controlpanel.development.yaml
  $ENV{MOJO_HOME}/conf/local.mydlge-controlpanel.development.yaml

Settings in next file overrides settings in previous file.
L<Hash::Merge> is used for merging configuration structures.

=head2 stash

Getter and setter for config values. Returns the value. Used internally in L<MYDLjE/config>. 

  $value = $config->stash('one', 1);
  $value = $config->stash('one')
  $all   = $config->stash

=head2 write_config_file

Writes a config file to the given filename.

  #write to local config
  $config->write_config_file();
  
  #write seomwhere else
  $config->write_config_file($ENV{HOME}.'/.top/.secret.yml');


=head2 SEE ALSO

L<MYDLjE> L<Hash::Merge>, L<YAML::Any> L<YAML::Tiny>


