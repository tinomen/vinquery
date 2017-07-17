Vinquery
========

A ruby client for the [VinQuery](http//www.vinquery.com) vin decoding web service.

How to install
--------------

**Bundler**

``` ruby
gem vinquery
```

**Rubygems**

```
gem install vinquery
```

How to use
----------

Vinquery will provide you with a unique url and access_code which is needed for every request. In addition you will need to send the report type you desire. More info is available at the VinQuery [site](http://vinquery.com).

``` ruby
require 'vinquery'
vin = Vinquery.get('1FTWX31R19EB18840', {
                    :url => 'VINQUERY_URL',
                    :access_code => 'ACCESS_CODE',
                    :report_type => 'REPORT_TYPE'})

vin.valid? # true
vin.attributes[:make] # Ford
```

[![Sponsor](https://app.codesponsor.io/embed/gfv4BcbtkMGmAidCd8ReeHRM/tinomen/vinquery.svg)](https://app.codesponsor.io/link/gfv4BcbtkMGmAidCd8ReeHRM/tinomen/vinquery)
