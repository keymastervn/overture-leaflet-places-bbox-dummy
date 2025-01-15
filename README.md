# README

This is an effort to precalculate search_grids to efficiently work with Google Place API based on Overture data.

We will calculate the ideal search grids that may play well with Google Place API

https://places-search-405409.ue.r.appspot.com/

- radius: 500m to 30km
- includedPrimaryTypes: expected industry/category
- nearbySearch: 20 units OR textSearch 60 units (ideally Overture dataset is 1/2 Google Place so let's say 10 vs. 30 accordingly)

```

 ┌┌────┌───┌──────────┐─────┌───┐
 ││    │   │          ┌─────│   │
 ││ ┌──────┐          │     └───┘
 ┌──│──┘   ┌──────┐   └─────┘   │
 │  │      │search│   │         │
 │  │      │ unit │   ┌──────┐  │
 ┌─────────│      │   │      │  │
 │         └──────┘┐──└──────┘─┐│
 │         │       │  │        ││
 │  search │       │  │        ││
 │   unit  │       │  │        ││
 │         │       │  │        ││
 │         │       │  │        ││
 └─────────└───────┘──└────────┘┘
          Bbox of postcodes
```

## Prerequisite
Don't ask why

`bin/rails db:create`

`bin/rails s`

`localhost:3000`

## Getting the overture dataset

DuckDB

```

COPY(
    SELECT
       id,
       names.primary as name,
       CAST(names AS JSON) AS names,
       categories.primary as primary_categories,
       categories.alternate as alternate_categories,
       confidence,
       CAST(websites AS JSON) AS websites,
       CAST(socials AS JSON) AS socials,
       CAST(emails AS JSON) AS emails,
       CAST(phones AS JSON) AS phones,
       CAST(brand AS JSON) AS brand,
       CAST(addresses AS JSON) AS addresses,
       CAST(sources AS JSON) AS sources,
       CAST(SPLIT_PART(REPLACE(REPLACE(geometry, 'POINT (', ''), ')', ''), ' ', 1) AS DOUBLE) AS longitude,
       CAST(SPLIT_PART(REPLACE(REPLACE(geometry, 'POINT (', ''), ')', ''), ' ', 2) AS DOUBLE) AS latitude
    FROM read_parquet('s3://overturemaps-us-west-2/release/2024-10-23.0/theme=places/*/*')
    WHERE bbox.xmin > 135.03 AND bbox.xmax < 153.65
    AND bbox.ymin > -38.92 AND bbox.ymax < -25.05
    AND type = 'place'
    AND addresses[1].country = 'AU'
    AND (addresses[1].region = 'NSW' OR addresses[1].region = 'New South Wales')
  ) TO 'output.csv' (HEADER, DELIMITER ',');
```

Note: Bouding boxes eval support from https://boundingbox.klokantech.com/

NSW => `135.03,-38.92,153.65,-25.05`
AU => `-10.41,153.64,-43.65,112.91`

## Install POSTGIS

https://postgis.net/workshops/postgis-intro/installation.html

https://stackoverflow.com/a/77204579

IMPORTANT NOTE: when deploy production, be sure to use `postgis://` not `postgresql://` in your `DATABASE_URL` [Ref](https://github.com/rgeo/activerecord-postgis-adapter/issues/214#issuecomment-188858728)

```
DATABASE_URL=postgis://overture_test_db_user:******************@xxx.yyy-postgres.render.com/overture_test_db bundle exec rails places:import file=/Users/datle-eh/thinkei/ats/output.csv
```

## Import

### Places

```
$ bundle exec rails places:import file=/Users/datle-eh/output.csv
```

```
irb(main):001> Place.count
  Place Count (41.8ms)  SELECT COUNT(*) FROM "places"
=> 301762
```

### Calculate Grids

eg. 1km shift (area_splitting_threshold)

```
$ bundle exec rake "places:build_grids[-25.05,153.65,-38.92,135.03,1]"
```

### Update postcodes (Post-action)

Note: pls enable index (center_lat, center_lng) + Place.geometry


```
$ bundle exec rake places:populate_postcodes
```

### Divisions
https://docs.overturemaps.org/guides/divisions/

https://docs.overturemaps.org/schema/reference/divisions/division_boundary/

Many grids are miscreated at the ocean because of the way we spawn them.

Creating a division with multiple ![LineString](https://postgis.net/docs/ST_MakeLine.html) can help checking if SearchGrid is within the division or not.

```
COPY (
SELECT *
FROM read_parquet('s3://overturemaps-us-west-2/release/2024-11-13.0/theme=divisions/type=division_area/*', filename=true, hive_partitioning=1)
WHERE
subtype = 'country' AND class = 'land' AND country = 'AU'
) TO 'division_au.csv' (HEADER, DELIMITER ',');
```

```
$ file=./division_au.csv bundle exec rake places:import_division
```

Hint: always look at Example before querying
https://docs.overturemaps.org/schema/reference/divisions/division_area/#examples

#### Check

Good grids within division.
eg. 440460 -> 420592

```
query = <<~SQL
  SELECT count(g.id)
  FROM search_grids g
  JOIN divisions d
  ON ST_Contains(d.geometries::geometry, ST_MakeEnvelope(g.sw_lng, g.sw_lat, g.ne_lng, g.ne_lat, 4326));
SQL
ActiveRecord::Base.connection.execute(query).to_a
```

#### Mark
Not because I do it manually, it is not necessary a rake task, once off is fine.

```
query = <<~SQL
WITH grids_in_land AS (
  SELECT g.id AS grid_id
  FROM search_grids g
  JOIN divisions d
  ON ST_Contains(d.geometries::geometry, ST_MakeEnvelope(g.sw_lng, g.sw_lat, g.ne_lng, g.ne_lat, 4326))
)
UPDATE search_grids
SET is_land = TRUE
WHERE id IN (SELECT grid_id FROM grids_in_land);
SQL
ActiveRecord::Base.connection.execute(query).to_a

irb(main):036> SearchGrid.where(is_land: true).count
  SearchGrid Count (77.4ms)  SELECT COUNT(*) FROM "search_grids" WHERE "search_grids"."is_land" = $1  [["is_land", true]]
=> 420592
```

