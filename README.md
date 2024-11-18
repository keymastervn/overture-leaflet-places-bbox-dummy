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

## Import places

```
bundle exec rails places:import file=/Users/datle-eh/output.csv
```

```
irb(main):001> Place.count
  Place Count (41.8ms)  SELECT COUNT(*) FROM "places"
=> 301762
```

