# Configure field extractions

Extracting fields from data is [advised](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Configureindex-timefieldextraction) to be done at (query) search-time. Alternatively it can be done at index-time.
Extraction at index-time can be done using regular expressions or based on [structured data](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Extractfieldsfromfileswithstructureddata) ([automatic header-based field extraction](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Extractfieldsfromfileswithstructureddata#Use_configuration_files_to_enable_automatic_header-based_field_extraction)).

## Field extraction at search time (using regular expressions)

For this demonstration, so-called [_inline extractions_](https://docs.splunk.com/Documentation/Splunk/8.0.0/Knowledge/Configureinlineextractions) are used.

| file | forwarder2 config | intermediate config | enterprise config |
|---|---|---|---|
| rfc3164_fwd2.log | [index `rfc3164` sourcetype `rfc3164`](../docker-compose.yml#L179) [Field extraction on sourcetype `rfc3164`](../config/splunkforwarder2/system/local/props.conf) fields `splunk_props_fwd2_...`| [Field extraction on sourcetype `rfc3164`](../config/splunkheavyforwarder/system/local/props.conf) fields `splunk_props_Hfwd_...`| [Field extraction on sourcetype `rfc3164`](../config/splunkenterprise/system/local/props.conf) fields `splunk_props_entsrv_...`|

Keep in mind that the file `rfc3164_fwd2.log` is read by `splunkforwarder2` and passed via `splunkheavyforwarder` to `splunkenterprise`.
For demonstration purposes, the field extraction is configured on all of them. For example the same date field is configured as `splunk_props_fwd2_date`, `splunk_props_Hfwd_date` and `splunk_props_entsrv_date`. Also each instance has been configured to define a unique field, respectively `splunk_props_fwd2_host`, `splunk_props_Hfwd_hostport` and `splunk_props_entsrv_message`.

These field definitions are only [supported on the (combined) indexer(s) and search head(s)](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Configureindex-timefieldextraction#Where_to_put_the_configuration_changes_in_a_distributed_environment).

Therefore the only field names which will show up in this test environment are the `splunk_props_entsrv_...` fields.

This can be checked by using the following query: [`index=rfc3164 | stats values(*) AS * | transpose | search column="splunk_props*"| table column  | rename column AS Fieldname`](http://localhost:8000/en-GB/app/search/search?q=search%20index%3Drfc3164%20%7C%20stats%20values(*)%20AS%20*%20%7C%20transpose%20%7C%20search%20column%3D%22splunk_props*%22%7C%20table%20column%20%20%7C%20rename%20column%20AS%20Fieldname&earliest=-24h%40h&latest=now&display.page.search.tab=statistics&display.general.type=statistics&display.page.search.mode=smart)

## Field extraction with structured data

This is commonly used with comma-separated files (`csv`), where the first line contains the field names.
The following format is used in the log files in this setup.

``` csv
CSVHeaderDate,CSVHeaderTime,CSVHeaderCSVFileType,CSVHeaderRandWord1,CSVHeaderRandNum1,CSVHeaderRandWord2,CSVHeaderRandNum2,CSVHeaderLineNum
2019-11-22,21:13:54,classic,Hippurites,51,piacularness,242,Line_1_of_300
2019-11-22,21:13:55,classic,metropolitancy,222,shirtman,159,Line_2_of_300
2019-11-22,21:13:56,classic,dragonnade,139,muscicole,169,Line_3_of_300
```

The extraction is configure using the `INDEXED_EXTRACTIONS` keyword.

### Automatic field extraction with structured data

In a default Splunk configuration, files with extension `.csv` are _automatically_ treated as such:

``` sh
splunk@forwarder:/opt/splunk > cat /opt/splunk/etc/system/default/props.conf | grep csv
[csv]
INDEXED_EXTRACTIONS = csv
[source::....csv]
sourcetype = csv
```

Files (paths) ending in `csv` are assigned to source type `csv`, which in turn is configured with `INDEXED_EXTRACTIONS = csv`

In this environment this is demonstrated by the monitoring of the file `csv_classic_fwd1.csv`. 

To see the automatically extracted fields for `csv_classic_fwd1.csv`:  [`index=* source="/logs/csv_classic_fwd1.csv" | stats values(*) AS * | transpose | search column="CSVHeader*"| table column  | rename column AS Fieldname`](http://localhost:8000/en-GB/app/search/search?q=search%20index%3D*%20source%3D%22%2Flogs%2Fcsv_classic_fwd1.csv%22%20%7C%20stats%20values(*)%20AS%20*%20%7C%20transpose%20%7C%20search%20column%3D%22CSVHeader*%22%7C%20table%20column%20%20%7C%20rename%20column%20AS%20Fieldname&earliest=-24h%40h&latest=now&display.page.search.tab=statistics&display.general.type=statistics&display.page.search.mode=smart)

There's an (obvious) caveat to this; in case a log file _happens_ to be in `csv` format, it may not always contain the field names in the first row. An example of this is demonstrated by the monitoring of the file `csv_noheader_fwd1.csv`, where the first line contains data instead of the field names.

To see the (_incorrectly_) automatically extracted fields for `csv_noheader_fwd1.csv`:  [`index=* source="/logs/csv_noheader_fwd1.csv" | stats values(*) AS * | transpose |  table column  | rename column AS Fieldname`](http://localhost:8000/en-GB/app/search/search?q=search%20index%3D*%20source%3D%22%2Flogs%2Fcsv_noheader_fwd1.csv%22%20%7C%20stats%20values(*)%20AS%20*%20%7C%20transpose%20%7C%20%20table%20column%20%20%7C%20rename%20column%20AS%20Fieldname&earliest=-24h%40h&latest=now&display.page.search.tab=statistics&display.general.type=statistics&display.page.search.mode=smart)

_(Notice field names such as `Line_1_of_300` or having a date format.)_

### Automatic field extraction with structured data and specified field names

For cases where a log file _happens_ to be in `csv` format, but does not contain the field names in the first row, it can be specified:

| splunkforwarder2 file | forwarder config |
|---|---|
| csv_noheader_fwd2.csv | [sourcetype `csv_noheader`](../docker-compose.yml#L182) [`INDEXED_EXTRACTIONS` with `FIELD_NAMES`](../config/splunkforwarder2/apps/custom_config/local/props.conf) |
| csv_noheader_fwd2.log | [sourcetype `csv_noheader`](../docker-compose.yml#L184) [`INDEXED_EXTRACTIONS` with `FIELD_NAMES`](../config/splunkforwarder2/apps/custom_config/local/props.conf) |

The field names from the configuration can be checked using the following query: [`index=* source="/logs/csv_noheader_fwd2.*" | stats values(*) AS * | transpose |  search column="splunk_props*" | table column  | rename column AS Fieldname`](http://localhost:8000/en-GB/app/search/search?q=search%20index%3D*%20source%3D%22%2Flogs%2Fcsv_noheader_fwd2.*%22%20%7C%20stats%20values(*)%20AS%20*%20%7C%20transpose%20%7C%20%20search%20column%3D%22splunk_props*%22%20%7C%20table%20column%20%20%7C%20rename%20column%20AS%20Fieldname&earliest=-24h%40h&latest=now&display.page.search.tab=statistics&display.general.type=statistics&display.page.search.mode=smart)

### Configuration location

Field extractions using regular expressions are only [supported on the (combined) indexer(s) and search head(s)](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Configureindex-timefieldextraction#Where_to_put_the_configuration_changes_in_a_distributed_environment)

While field extraction with structured data seems like an implementation of _regular_ field extractions using regular expressions, [field extraction settings for forwarded structured data must be configured on the forwarder](https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/Extractfieldsfromfileswithstructureddata#Field_extraction_settings_for_forwarded_structured_data_must_be_configured_on_the_forwarder).
