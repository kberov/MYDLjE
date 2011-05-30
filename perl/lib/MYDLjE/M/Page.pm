package MYDLjE::M::Page;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();
use MYDLjE::M::Content;

has TABLE => 'pages';

has COLUMNS => sub {
  [ qw(
      id pid domain_id alias page_type sorting template
      cache expiry permissions user_id group_id
      tstamp start stop published hidden deleted changed_by
      )
  ];
};

my $id_regexp = {regexp => qr/^\d+$/x};

has FIELDS_VALIDATION => sub {
  my $self  = shift;
  my %alias = $self->FIELD_DEF('alias32');
  $alias{alias} = $alias{alias32};
  delete $alias{alias32};
  return {
    ##no critic qw(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    $self->FIELD_DEF('id'),
    $self->FIELD_DEF('pid'),
    $self->FIELD_DEF('domain_id'),
    %alias,
    page_type => {
      required    => 1,
      constraints => [{in => ['regular', 'root', 'folder']},]
    },
    $self->FIELD_DEF('sorting'),
    cache  => {regexp => qr/^[01]$/x,},
    expiry => {regexp => qr/^\d{1,6}$/x,},
    $self->FIELD_DEF('permissions'),
    $self->FIELD_DEF('user_id'),
    $self->FIELD_DEF('group_id'),
    published => {regexp => qr/^[012]$/x},
    $self->FIELD_DEF('cache'),
    $self->FIELD_DEF('deleted'),
    $self->FIELD_DEF('hidden'),
    $self->FIELD_DEF('changed_by'),
  };
};
{
  no warnings qw(once);
  *id          = \&MYDLjE::M::Content::id;
  *pid         = \&MYDLjE::M::Content::pid;
  *user_id     = \&MYDLjE::M::Content::user_id;
  *group_id    = \&MYDLjE::M::Content::group_id;
  *permissions = \&MYDLjE::M::Content::permissions;
  *sorting     = \&MYDLjE::M::Content::sorting;
  *tstamp      = \&MYDLjE::M::Content::tstamp;
  *start       = \&MYDLjE::M::Content::start;
  *stop        = \&MYDLjE::M::Content::stop;
}

sub alias {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{alias} = $self->validate_field(alias => $value);
    return $self;
  }

  unless ($self->{data}{alias}) {
    $self->{data}{alias} = lc(
      $self->id
      ? MYDLjE::Unidecode::unidecode('page_' . $self->id)
      : Mojo::Util::md5_sum(Time::HiRes::time())
    );
    $self->{data}{alias} =~ s/\W+$//x;
    $self->{data}{alias} =~ s/^\W+//x;
  }
  return $self->{data}{alias};
}

#Create a page with dummy page content
sub add {
  my ($class, $args) = MYDLjE::M::get_obj_args(@_);
  ($class eq __PACKAGE__)
    || Carp::croak('Call this method only like: ' . __PACKAGE__ . '->add(%args);');

  #must be a MYDLjE::M::Content::Page instance but we will check later
  my $page_content = delete $args->{page_content};
  my $page         = $class->new($args);
  my $dbix         = $page->dbix;

  my $eval_ok = eval {
    $dbix->begin_work;
    $page->save();
    $page_content->page_id($page->id);
    $page_content->alias('page_' . $page->alias . '_' . $page_content->language);
    $page_content->save();
    $dbix->commit;
  };
  unless ($eval_ok) {
    $dbix->rollback or Carp::confess($dbix->error);
    Carp::croak("ERROR adding page(rolling back):[$@]");
  }
  return $page;
}

1;


__END__

=encoding utf8

=head1 NAME

MYDLjE::M::Page - MYDLjE::M-based Page class

=head1 SYNOPSIS

  my $home_page = MYDLjE::M::Page->select(alias=>'home');

=head1 DESCRIPTION

This class is used to instantiate page objects. 

=head1 ATTRIBUTES

This class inherits all attributes from MYDLjE::M and overrides the ones listed below.

Note also that all table-columns are available as setters and getters for the instantiated object.



=head2 COLUMNS

Retursns an ARRAYREF with all columns from table C<pages>.  These are used to automatically generate getters/setters.

=head2 TABLE

Returns the table name from which rows L<MYDLjE::M::Page> instances are constructed: C<pages>.


=head2 FIELDS_VALIDATION

Returns a HASHREF with column-names as keys and L<MojoX::Validator> constraints used in the getters/setters when retreiving and inserting values. See below.

=head1 DATA ATTRIBUTES

=head2 id

Primary key.

=head2 pid

Parent id - foreing key referencing the page under which this page is found in the site structure.

=head2 alias

Unique seo-friendly alias used to construct the url pointing to this page

=head2 page_type

    $page->page_type('folder');
    $page->save;
    #...

    $page->select(page_type =>'root')

In MYDLjE there are  several types of pages:

=item I<folder> 

Not displayed in the front-end/site neither in menus - used just as container of a list of items possibly stored in other tables.

=item I<regular>

Regular pages are used to construct menus in the site and to display content or front-end modules/widgets implemented as TT/TA Plugins

=item I<root>

A page representing the root of a domain(there can be several domains managed by a MYDLjE system). It may or may not be displayed in the domain depending on... not decided yet...

Other types of pages can be added easily and used depending on the business logic you define.


=head2 sorting

Used to set the order of the pages under the same L</pid>

=head2 template

TT/TA code to display this page. Default template for pages in the site is used 
if this field is empty.

=head2 cache

Should this page be cached by the browser? 1=yes, 0=no

=head2 expiry

After how many seconds this page will expire when C<cache=1>? Default: 86400 = 24 hours. 

=head2 permissions

This field represents permissions for the current page very much like permissions 
of a file on a Unix system. We use i<symbolic notation> to represent permissions. The format is "tuuugggoo" where "t" can be "d","l" or "-". 

"d" is for "directory" - "I<Does this page contains other pages?>" and is set for the first time when a child page is attached to this page. "l" means that the page is a link to another page. 
"-" is for a regular record. 

"u" represents permissions for the owner of the page.
Valid values  for each place are "r" - read, "w" - write and "x" - execute. On eache place  instead of "r", "w" or "x" there can be "-" - none .  The last triple is for the rest of the users.

We will try to follow closely the rules for "Traditional Unix permissions" as much as they are applicable here. We will not use octal notation.
 See L<http://en.wikipedia.org/wiki/File_permissions#Traditional_Unix_permissions>.


=head2 user_id

Id of the owner of the page. Usually the user that creates the page.

=head2 group_id

A user can belong to several groups. This field defines the group id for which the group part of the permissions will apply.

=head2 domain_id

A MYDLjE system can manage multiple domains. This field references the id of the domain to which this page belongs. Default value is C<0>. 

=head2 tstamp

Last time this page was touched.

=head2 start

Time in seconds since the epoch when this page will be considered published.

=head2 stop

Time in seconds since the epoch till this page will be considered published.

=head2 published

0=not published,1=waiting,2=published


=head2 deleted

If set to "1" this page will not be accessible any more trough the system.

=head2 changed_by

User id of the user that touched this page for the last time.

=head1 METHODS

=head2 add

Inserts a new page row in C<pages> and adds basic properties 
(row in content with L<MYDLjE::M::Content/data_type> page)for the new page.

Returns an instance of L<MYDLjE::M::Page> - the newly created page.

In case of database error croaks with C<ERROR adding page(rolling back):[$@]>.

Parameters:

    #All columns can be passed as  key-value pairs like MYDLjE::M::select.

Example:

  require MYDLjE::M::Page;
  my $new_user = MYDLjE::M::Page->add(
  ...
  );

=head1 SEE ALSO

L<MYDLjE::M::Content>, L<MYDLjE::M::User>, L<MYDLjE::M>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров 

This code is licensed under LGPLv3.


