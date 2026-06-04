# OpenILS::Application::BatchUpdate provides CRUD operations for batch.schedule records.
#
# Copyright (c) 2014-2015  International Institute of Social History
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Author: Lucien van Wouw <lwo@iisg.nl>


package OpenILS::Application::BatchUpdate;

use strict;
use warnings;

# All OpenSRF applications must be based on OpenSRF::Application or
# a subclass thereof.  Makes sense, eh?
use OpenILS::Application;
use base qw/OpenILS::Application/;

# This is the client class, used for connecting to open-ils.storage
use OpenSRF::AppSession;

# This is an extension of Error.pm that supplies some error types to throw
use OpenSRF::EX qw(:try);

# This is a helper class for querying the OpenSRF Settings application ...
#use OpenSRF::Utils::SettingsClient;

use OpenILS::Utils::CStoreEditor q/:funcs/;

# ... and here we have the built in logging helper ...
use OpenSRF::Utils::Logger qw($logger);

my $BATCH_SCHEDULE = 'BATCH_SCHEDULE' ;
my $UPDATE_MARC = 'UPDATE_MARC' ;

sub child_init {

   # my $app_settings = OpenSRF::Utils::SettingsClient->new->config_value(apps => 'open-ils.handle')->{'app_settings'};
}


sub schedule_list {
    my $self = shift;
    my $client = shift;
    my $auth = shift;
    my $query = shift;
    my $order_by = shift;
    my $offset = shift ;
    my $limit = shift ;

    my $e = new_editor(authtoken=>$auth);
    return $e->event unless $e->checkauth;
    return $e->die_event unless $e->allowed($BATCH_SCHEDULE);
    return $e->die_event unless $e->allowed($UPDATE_MARC);

    $query->{'id'} = {'>' => 0} unless ($query) ;
    $order_by->{'bs'} = 'id ASC' unless ($order_by) ;

    my $_storage = OpenSRF::AppSession->create( 'open-ils.cstore' );
    return $_storage->request(
        'open-ils.cstore.direct.batch.schedule.search.atomic',
        $query,
        { order_by => $order_by, offset => $offset, limit => $limit} )->gather();
}

__PACKAGE__->register_method(
    method    => 'schedule_list',
    api_name  => 'open-ils.batch-update.schedule.list',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Returns an array of one or more batch records
          DESC
          params   =>
            [   { name => 'auth',
                                               desc => 'Authentication token' ,
                                               type => 'string' },
                             { name => 'query',
                            desc => 'query to select records' ,
                            type => 'array' },
                            { name => 'offset',
                                desc => 'begin list at this index' ,
                                type => 'number' },
                { name => 'limit',
                  desc => 'the maximum number of records to return',
                  type => 'number' }
            ],
          'return' =>
            { desc => 'The batch record identifiers',
              type => 'array' }
        }
);


sub schedule_get {
    my $self = shift;
    my $client = shift;
    my $auth = shift;
    my $id = shift;

    my $e = new_editor(authtoken=>$auth);
    return $e->event unless $e->checkauth;
    return $e->die_event unless $e->allowed($BATCH_SCHEDULE);
    return $e->die_event unless $e->allowed($UPDATE_MARC);
    return $e->retrieve_batch_schedule($id) or return $e->die_event;
}

__PACKAGE__->register_method(
    method    => 'schedule_get',
    api_name  => 'open-ils.batch-update.schedule.get',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Returns an array of one or more batch records
          DESC
          params   =>
            [   { name => 'auth',
                                               desc => 'Authentication token' ,
                                               type => 'string' },
                            { name => 'id',
                                desc => 'record identifier' ,
                                type => 'number' }
            ],
          'return' =>
            { desc => 'Return a single record',
              type => 'string' }
        }
);


sub schedule_insert {
        my $self = shift;
        my $client = shift;
        my $auth = shift;
        my $new_schedule = shift;

    my $e = new_editor(authtoken=>$auth, xact=>1);
    return $e->die_event unless $e->checkauth;
    return $e->die_event unless $e->allowed($BATCH_SCHEDULE);
    return $e->die_event unless $e->allowed($UPDATE_MARC);

    $new_schedule->runner ( $e->requestor->id  ) ;
    my $schedule = $e->create_batch_schedule($new_schedule)
        or return $e->die_event;
    $e->commit;
    return $schedule;
}

__PACKAGE__->register_method(
    method    => 'schedule_insert',
    api_name  => 'open-ils.batch-update.schedule.insert',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Returns an array of one or more batch records
          DESC
          params   =>
            [   { name => 'auth',
                                               desc => 'Authentication token' ,
                                               type => 'string' },

                { name => 'schedule',
                  desc => 'The record to save' }
            ],
          'return' =>
                      { desc => 'self if successful' }
        }
);


sub schedule_update {

    my $self = shift;
    my $client = shift;
    my $auth = shift;
    my $schedule = shift;

    my $e = new_editor(authtoken=>$auth, xact=>1);
    return $e->die_event unless $e->checkauth;
    return $e->die_event unless $e->allowed($BATCH_SCHEDULE);
    return $e->die_event unless $e->allowed($UPDATE_MARC);

    my $s = $e->retrieve_batch_schedule($schedule->id) or return $e->die_event;
    if( $s->runner ne $e->requestor->id ) {
        $e->rollback;
        return 0;
    }

    $e->update_batch_schedule($schedule) or return $e->die_event;
    $e->commit;
    $schedule;

}

__PACKAGE__->register_method(
    method    => 'schedule_update',
    api_name  => 'open-ils.batch-update.schedule.update',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Returns an array of one or more batch records
          DESC
          params   =>
            [   { name => 'auth',
                                               desc => 'Authentication token' ,
                                               type => 'string' },
                { name => 'schedule',
                  desc => 'The record to update' }
            ],
          'return' =>
            { desc => 'self if successful' }
            }
);

sub schedule_delete {
    my $self = shift;
    my $client = shift;
    my $auth = shift;
    my $id = shift;

    my $e = new_editor(authtoken=>$auth, xact=>1);
    return $e->event unless $e->checkauth;
    return $e->die_event unless $e->allowed($BATCH_SCHEDULE);
    return $e->die_event unless $e->allowed($UPDATE_MARC);

    my $s = $e->retrieve_batch_schedule($id) or return $e->die_event;
    $e->delete_batch_schedule($s) or return $e->die_event;
    $e->commit;
    return 1;
}

__PACKAGE__->register_method(
    method    => 'schedule_delete',
    api_name  => 'open-ils.batch-update.schedule.delete',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Returns an array of one or more batch records
          DESC
          params   =>
            [   { name => 'auth',
                                               desc => 'Authentication token' ,
                                               type => 'string' },
                            { name => 'id',
                                desc => 'record identifier' ,
                                type => 'number' }
            ]
        }
);

1;