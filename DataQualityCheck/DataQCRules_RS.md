# Data quality check for **Rocky Shores**

The excel workbook contains three sheets

1. Abundance
2. Cover
3. Site details


## SHEET #3 SITE details

Index | Variable | Type      | Rules
------|----------|-----------|-------------------
1     | Year     | numeric   | in yyyy format
2     | Months   | numeric   | in mm format
3     | Sampling Date | text  | ISO 8601 standard: yyyy-mm-dd
4     | Country   | text      | valid ISO 3166 country name
5     | State (or Province) | text | no check
6     | Locality  | text    | no check
7     | Site      | text    | no check
8     | Strata    | text    | only "HIGHTIDE", "MIDTIDE", "LOWTIDE"
9     | Picture site | text  | no check
10    | Criteria used to define strata | text | no check
11    | Latitude  | numeric  | decimal degrees, negative western hemisphere
11    | Longitude | numeric  | decimal degrees, negative southern hemisphere
12    | GPS error (m) | numeric | reasonable value, less than 20
13    | Datum     | text | only "WGS84"
14    | Composition of substrate | text | no check
15    | MPA       | text     | "YES"or "NO"
16    | Urban Area       | text     | "YES"or "NO"
17    | Likelihood of a given rocky shore to be affected by sand       | text     | "YES"or "NO"
18    | Is there a sand strip in between the rocky shore and dry land?       | text     | "YES"or "NO"
19    | Rugosity (ratio) | numeric | [0,1]


## SHEET #2 COVER


## SHEET #1 ABUNDANCE
