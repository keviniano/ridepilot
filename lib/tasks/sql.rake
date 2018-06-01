# This is to adjust db schema vis sql script
namespace :sql do

  task create_gps_locations_partition: :environment do
    partition_sql = <<-SQL
      /* Create a view */
      CREATE OR REPLACE VIEW gps_locations_view AS SELECT * FROM gps_locations;

      /* Set default value for primary column */
      ALTER VIEW gps_locations_view
      ALTER COLUMN id
      SET DEFAULT nextval('gps_locations_id_seq'::regclass);

      /* Trigger procedure to determine which table new record goes to */
      CREATE OR REPLACE FUNCTION gps_locations_view_insert_trigger_procedure() RETURNS TRIGGER AS $BODY$
        DECLARE
          partition TEXT;
          partition_provider_id INTEGER;
          partition_date TIMESTAMP;
        BEGIN

          /* Build a name for a new table */

          partition_date     := date_trunc('month', NEW.log_time);
          partition_provider_id  := NEW.provider_id;
          partition          := TG_TABLE_NAME || '_' || partition_provider_id || '_' || to_char(partition_date, 'YYYY_MM');

          /*
          Create a child table, if necessary. Announce it to all interested parties.
          */

          IF NOT EXISTS(SELECT relname FROM pg_class WHERE relname = partition) THEN

            RAISE NOTICE 'A new gps_locations partition will be created: %', partition;

            /*
            Here is what happens below:
            * we inherit a table from a master table;
            * we create CHECK constraints for a resulting table.
              It means, that a record not meeting our requirements
              would not be inserted;
            * we create a necessary index;
            * triple quotes are a feature, not a bug!
            */

          EXECUTE 'CREATE TABLE IF NOT EXISTS ' || partition || ' (CHECK (
            provider_id = ''' || NEW.provider_id || ''' AND
            date_trunc(''minute'', log_time) >= ''' || partition_date || ''' AND
            date_trunc(''minute'', log_time)  < ''' || partition_date + interval '1 month' || '''))
            INHERITS (gps_locations);';

          EXECUTE 'CREATE INDEX ' || partition || '_provider_logtime_idx ON ' || partition || ' (provider_id, log_time);';

          /* Insert partition reference record */
          EXECUTE 'INSERT INTO gps_location_partitions (provider_id, year, month, table_name) 
            VALUES (
              ''' || NEW.provider_id || ''', 
              ''' || date_part('year', NEW.log_time) || ''' , 
              ''' || date_part('month', NEW.log_time) || ''',
              ''' || partition || '''
              )';
        END IF;

        /* And, finally, insert. */

        EXECUTE 'INSERT INTO ' || partition || ' SELECT(gps_locations  ' || quote_literal(NEW) || ').*';

        /*
        Attention: we return new record, not a NULL.
        It allows us to play nicely with ActiveRecord!
        */

        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql;

      /* Apply trigger to view */
      CREATE TRIGGER gps_locations_view_insert_trigger
      INSTEAD OF INSERT ON gps_locations_view
      FOR EACH ROW EXECUTE PROCEDURE gps_locations_view_insert_trigger_procedure();

      SQL
      
      ActiveRecord::Base.connection.execute partition_sql
  end

  task drop_gps_locations_partition: :environment do 
    partition_sql = <<-SQL
      DROP TRIGGER IF EXISTS gps_locations_view_insert_trigger ON gps_locations_view;
      DROP FUNCTION IF EXISTS gps_locations_view_insert_trigger_procedure();
      DROP VIEW IF EXISTS gps_locations_view;
      
      SQL
      
      ActiveRecord::Base.connection.execute partition_sql
  end
end